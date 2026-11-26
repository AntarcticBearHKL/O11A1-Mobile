import Foundation
import CommonCrypto

final class O11A1CookieStore {
  private let defaults = UserDefaults.standard
  private let storageKey = "o11a1_cookies"
  private var values: [String: String] = [:]
  private let lock = NSLock()

  init() {
    if let raw = defaults.string(forKey: storageKey), !raw.isEmpty {
      for piece in raw.split(separator: ";") {
        let parts = piece.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
        if parts.count == 2 {
          let name = String(parts[0]).trimmingCharacters(in: .whitespaces)
          let value = String(parts[1])
          if !name.isEmpty { values[name] = value }
        }
      }
    }
  }

  func header() -> String {
    lock.lock()
    defer { lock.unlock() }
    return values.map { "\($0.key)=\($0.value)" }.joined(separator: "; ")
  }

  func hasSession() -> Bool {
    lock.lock()
    defer { lock.unlock() }
    return !(values["SESSDATA"] ?? "").isEmpty
  }

  func get(_ name: String) -> String? {
    lock.lock()
    defer { lock.unlock() }
    return values[name]
  }

  func set(_ name: String, _ value: String) {
    guard !name.isEmpty else { return }
    lock.lock()
    values[name] = value
    persistLocked()
    lock.unlock()
  }

  func absorb(_ response: HTTPURLResponse) {
    guard let url = response.url else { return }
    var setCookies: [String] = []
    for (key, value) in response.allHeaderFields {
      if let key = key as? String,
         let value = value as? String,
         key.lowercased() == "set-cookie" {
        setCookies.append(value)
      }
    }
    for raw in setCookies {
      let parsed = HTTPCookie.cookies(withResponseHeaderFields: ["Set-Cookie": raw], for: url)
      for cookie in parsed {
        set(cookie.name, cookie.value)
      }
    }
  }

  func clear() {
    lock.lock()
    values.removeAll()
    defaults.removeObject(forKey: storageKey)
    lock.unlock()
  }

  private func persistLocked() {
    let raw = values.map { "\($0.key)=\($0.value)" }.joined(separator: "; ")
    defaults.set(raw, forKey: storageKey)
  }
}

final class O11A1BiliClient {
  static let apiBase = "https://api.bilibili.com"
  private static let wbiMixinKey: [Int] = [
    46, 47, 18, 2, 53, 8, 23, 32, 15, 50, 10, 31, 58, 3, 45, 35,
    27, 43, 5, 49, 33, 9, 42, 19, 29, 28, 14, 39, 12, 38, 41, 13,
    37, 48, 7, 16, 24, 55, 40, 61, 26, 17, 0, 1, 60, 51, 30, 4,
    22, 25, 54, 21, 56, 59, 6, 63, 57, 62, 11, 36, 20, 34, 44, 52
  ]
  static let userAgent = "Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36"
  static let desktopUserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"

  private let cookies = O11A1CookieStore()
  private let apiSession: URLSession
  private let buvidLock = NSLock()
  private var buvidBusy = false
  private let cidLock = NSLock()
  private var cidCache: [String: Int64] = [:]
  private var cachedMid: Int64 = 0
  private var cachedFolderId: Int64 = 0
  private var cachedWbiKey = ""
  private var cachedWbiAt: TimeInterval = 0

  var port: Int = 0

  init() {
    let apiConfig = URLSessionConfiguration.ephemeral
    apiConfig.httpCookieStorage = nil
    apiConfig.httpShouldSetCookies = false
    apiConfig.requestCachePolicy = .reloadIgnoringLocalCacheData
    apiConfig.timeoutIntervalForRequest = 20
    apiConfig.timeoutIntervalForResource = 45
    apiConfig.httpMaximumConnectionsPerHost = 8
    apiConfig.waitsForConnectivity = true
    apiConfig.networkServiceType = .responsiveData
    apiSession = URLSession(configuration: apiConfig)
  }

  /* ---------- transport ---------- */

  private func perform(_ request: URLRequest, session: URLSession) -> (Data, HTTPURLResponse)? {
    let box = O11A1Box<(Data, HTTPURLResponse)>()
    let semaphore = DispatchSemaphore(value: 0)
    let task = session.dataTask(with: request) { data, response, _ in
      if let response = response as? HTTPURLResponse {
        box.value = (data ?? Data(), response)
      }
      semaphore.signal()
    }
    task.resume()
    if semaphore.wait(timeout: .now() + 90) == .timedOut {
      task.cancel()
      return nil
    }
    return box.value
  }

  private func requestData(
    base: String,
    path: String,
    query: [String: String],
    withCookies: Bool,
    session: URLSession
  ) -> (Data, HTTPURLResponse)? {
    var components = URLComponents(string: base + path)
    if !query.isEmpty {
      components?.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
    }
    guard let url = components?.url else { return nil }
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
    request.setValue("https://www.bilibili.com/", forHTTPHeaderField: "Referer")
    request.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
    request.setValue("zh-CN,zh;q=0.9", forHTTPHeaderField: "Accept-Language")
    if withCookies {
      let header = cookies.header()
      if !header.isEmpty { request.setValue(header, forHTTPHeaderField: "Cookie") }
    }
    guard let result = perform(request, session: session) else { return nil }
    cookies.absorb(result.1)
    return result
  }

  private func json(
    base: String,
    path: String,
    query: [String: String] = [:],
    withCookies: Bool = true
  ) -> [String: Any]? {
    guard let result = requestData(
      base: base,
      path: path,
      query: query,
      withCookies: withCookies,
      session: apiSession
    ) else { return nil }
    guard result.1.statusCode < 400 else { return nil }
    return (try? JSONSerialization.jsonObject(with: result.0)) as? [String: Any]
  }

  private func ensureBuvid() {
    if cookies.get("buvid3") != nil { return }
    buvidLock.lock()
    if buvidBusy {
      buvidLock.unlock()
      return
    }
    buvidBusy = true
    buvidLock.unlock()
    defer {
      buvidLock.lock()
      buvidBusy = false
      buvidLock.unlock()
    }
    if let payload = json(base: Self.apiBase, path: "/x/frontend/finger/spi", withCookies: false),
       let data = payload["data"] as? [String: Any] {
      let b3 = o11a1String(data["b_3"])
      let b4 = o11a1String(data["b_4"])
      if !b3.isEmpty { cookies.set("buvid3", b3) }
      if !b4.isEmpty { cookies.set("buvid4", b4) }
      print("[O11A1] buvid ready")
    } else {
      cookies.set("buvid3", UUID().uuidString.replacingOccurrences(of: "-", with: "") + "infoc")
      print("[O11A1] buvid fallback")
    }
  }

  /* ---------- feeds ---------- */

  func popular(page: Int, ps: Int) -> Data {
    ensureBuvid()
    let pageNumber = max(1, page)
    let pageSize = max(1, ps)
    guard let payload = json(
      base: Self.apiBase,
      path: "/x/web-interface/popular",
      query: ["ps": "\(pageSize)", "pn": "\(pageNumber)"]
    ),
      o11a1Int(payload["code"]) == 0,
      let data = payload["data"] as? [String: Any],
      let list = data["list"] as? [[String: Any]] else {
      return o11a1Error("popular unavailable")
    }
    var items: [[String: Any]] = []
    for item in list { items.append(video(item, search: false)) }
    print("[O11A1] popular page=\(pageNumber) items=\(items.count)")
    return o11a1Data(["ok": true, "items": items, "page": pageNumber])
  }

  func recommend(page: Int, ps: Int, fresh: Int) -> Data {
    ensureBuvid()
    let pageNumber = max(1, page)
    let pageSize = max(1, ps)
    let freshIndex = max(1, fresh)
    guard let payload = json(
      base: Self.apiBase,
      path: "/x/web-interface/index/top/feed/rcmd",
      query: [
        "ps": "\(pageSize)",
        "fresh_type": "3",
        "fresh_idx": "\(freshIndex)",
        "fresh_idx_1h": "\(freshIndex)",
        "homepage_ver": "1",
        "brush": "\(max(0, freshIndex - 1))",
        "screen": "1920-1080",
        "platform": "web"
      ]
    ),
      o11a1Int(payload["code"]) == 0,
      let data = payload["data"] as? [String: Any],
      let list = data["item"] as? [[String: Any]] else {
      return popular(page: page, ps: ps)
    }
    var items: [[String: Any]] = []
    for item in list {
      let gotoType = o11a1String(item["goto"])
      if !gotoType.isEmpty && gotoType != "av" { continue }
      if o11a1String(item["bvid"]).isEmpty { continue }
      items.append(video(item, search: false))
    }
    if items.isEmpty { return popular(page: page, ps: ps) }
    print("[O11A1] recommend page=\(pageNumber) fresh=\(freshIndex) items=\(items.count)")
    return o11a1Data(["ok": true, "items": items, "page": pageNumber, "fresh": freshIndex])
  }

  func search(keyword: String, page: Int) -> Data {
    let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty { return popular(page: page, ps: 20) }
    ensureBuvid()
    let pageNumber = max(1, page)
    guard let payload = json(
      base: Self.apiBase,
      path: "/x/web-interface/search/type",
      query: ["search_type": "video", "keyword": trimmed, "page": "\(pageNumber)"]
    ),
      o11a1Int(payload["code"]) == 0,
      let data = payload["data"] as? [String: Any] else {
      return o11a1Error("search unavailable")
    }
    let result = data["result"] as? [[String: Any]] ?? []
    var items: [[String: Any]] = []
    for item in result {
      let type = o11a1String(item["type"])
      if !type.isEmpty && type != "video" { continue }
      items.append(video(item, search: true))
    }
    return o11a1Data(["ok": true, "items": items, "page": pageNumber])
  }

  func suggest(term: String) -> Data {
    let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return o11a1Data(["ok": true, "items": []]) }
    guard let payload = json(
      base: "https://s.search.bilibili.com",
      path: "/main/suggest",
      query: ["term": trimmed, "main_ver": "v1", "highlight": ""],
      withCookies: false
    ), let result = payload["result"] as? [String: Any] else {
      return o11a1Error("suggest unavailable")
    }
    let tags = result["tag"] as? [[String: Any]] ?? []
    var items: [[String: Any]] = []
    var seen = Set<String>()
    for tag in tags {
      var value = o11a1StripHTML(o11a1String(tag["value"]))
      if value.isEmpty { value = o11a1StripHTML(o11a1String(tag["term"])) }
      if value.isEmpty { value = o11a1StripHTML(o11a1String(tag["name"])) }
      guard !value.isEmpty, seen.insert(value).inserted else { continue }
      var name = o11a1StripHTML(o11a1String(tag["name"]))
      if name.isEmpty { name = value }
      items.append(["value": value, "term": value, "name": name])
      if items.count >= 10 { break }
    }
    return o11a1Data(["ok": true, "items": items])
  }

  private func video(_ item: [String: Any], search: Bool) -> [String: Any] {
    var title = o11a1StripHTML(o11a1String(item["title"]))
    if title.isEmpty { title = "视频" }
    let rawPic = o11a1String(item["pic"]).isEmpty
      ? (o11a1String(item["pic_url"]).isEmpty ? o11a1String(item["cover"]) : o11a1String(item["pic_url"]))
      : o11a1String(item["pic"])
    let pic = o11a1HTTPS(rawPic)
    var owner = "UP 主"
    var ownerMid: Int64 = 0
    var ownerFace = ""
    if let ownerObject = item["owner"] as? [String: Any] {
      let name = o11a1StripHTML(o11a1String(ownerObject["name"]))
      if !name.isEmpty { owner = name }
      ownerMid = o11a1Int64(ownerObject["mid"])
      ownerFace = o11a1HTTPS(o11a1String(ownerObject["face"]))
    } else {
      let name = o11a1StripHTML(o11a1String(item["author"]))
      if !name.isEmpty { owner = name }
      ownerMid = o11a1Int64(item["uid"])
      ownerFace = o11a1HTTPS(o11a1String(item["upic"]))
    }
    let durationSeconds = search
      ? o11a1DurationSeconds(o11a1String(item["duration"]))
      : o11a1Int(item["duration"])
    var duration = search ? o11a1String(item["duration"]) : o11a1Duration(durationSeconds)
    if duration.isEmpty { duration = "00:00" }
    var plays: Int64 = 0
    if search {
      plays = Int64(o11a1String(item["play"])) ?? 0
    } else if let stat = item["stat"] as? [String: Any] {
      plays = o11a1Int64(stat["view"])
    }
    let playText = o11a1Count(plays)
    let aid = o11a1Int64(item["aid"]) != 0 ? o11a1Int64(item["aid"]) : o11a1Int64(item["id"])
    let rawDescription = o11a1String(item["desc"]).isEmpty
      ? o11a1String(item["description"])
      : o11a1String(item["desc"])
    let description = o11a1StripHTML(rawDescription)
    return [
      "bvid": o11a1String(item["bvid"]),
      "aid": aid,
      "cid": o11a1Int64(item["cid"]),
      "mid": ownerMid,
      "title": title,
      "pic": pic,
      "owner": owner,
      "ownerFace": ownerFace,
      "duration": duration,
      "durationSec": durationSeconds,
      "pubdate": o11a1Int64(item["pubdate"]) != 0 ? o11a1Int64(item["pubdate"]) : o11a1Int64(item["ctime"]),
      "progress": o11a1Int64(item["progress"]),
      "play": plays,
      "playText": playText,
      "desc": description,
      "meta": "\(owner) · \(playText) 播放"
    ]
  }

  /* ---------- playback ---------- */

  private func firstCid(_ bvid: String) -> Int64 {
    cidLock.lock()
    if let cached = cidCache[bvid] {
      cidLock.unlock()
      return cached
    }
    cidLock.unlock()
    guard let payload = json(base: Self.apiBase, path: "/x/player/pagelist", query: ["bvid": bvid]),
          let data = payload["data"] as? [[String: Any]],
          let first = data.first else { return 0 }
    let cid = o11a1Int64(first["cid"])
    if cid > 0 {
      cidLock.lock()
      cidCache[bvid] = cid
      cidLock.unlock()
    }
    return cid
  }

  func play(bvid: String, cid: Int64, qns: [Int]) -> Data {
    guard !bvid.isEmpty else { return o11a1Error("bvid missing") }
    ensureBuvid()
    var resolvedCid = cid
    if resolvedCid <= 0 { resolvedCid = firstCid(bvid) }
    guard resolvedCid > 0 else { return o11a1Error("cid not found") }
    print("[O11A1] play \(bvid) cid=\(resolvedCid)")
    var selected: [String: Any]?
    var seen = Set<Int>()
    for qn in qns {
      if seen.contains(qn) { continue }
      seen.insert(qn)
      for platform in ["html5", ""] {
        var query = [
          "bvid": bvid,
          "cid": "\(resolvedCid)",
          "qn": "\(qn)",
          "fnval": "1",
          "fourk": "0"
        ]
        if !platform.isEmpty { query["platform"] = platform }
        guard let payload = json(base: Self.apiBase, path: "/x/player/playurl", query: query),
              o11a1Int(payload["code"]) == 0,
              let data = payload["data"] as? [String: Any],
              let durl = data["durl"] as? [[String: Any]],
              !durl.isEmpty else { continue }
        selected = data
        break
      }
      if selected != nil { break }
    }
    guard let data = selected,
          let durl = data["durl"] as? [[String: Any]],
          let first = durl.first,
          let remote = first["url"] as? String,
          !remote.isEmpty else { return o11a1Error("playurl unavailable") }
    var urls = [remote]
    if let backups = first["backup_url"] as? [String] {
      for url in backups.prefix(2) where !url.isEmpty { urls.append(url) }
    }
    let quality = o11a1Int(data["quality"])
    var output: [String: Any] = [
      "ok": true,
      "cid": resolvedCid,
      "url": remote,
      "remote": remote,
      "quality": quality,
      "qualityLabel": o11a1QualityLabel(quality),
      "format": o11a1String(data["format"])
    ]
    if let accept = data["accept_quality"] as? [Any] {
      let labels = accept.map { o11a1QualityLabel(o11a1Int($0)) }.filter { !$0.isEmpty && $0 != "0P" }
      if !labels.isEmpty { output["available"] = labels }
    }
    if output["available"] == nil { output["available"] = [o11a1QualityLabel(quality)] }
    if urls.count > 1 {
      output["backup"] = urls[1]
      output["backupRemote"] = urls[1]
    }
    return o11a1Data(output)
  }

  func playLow(bvid: String, cid: Int64) -> Data {
    return play(bvid: bvid, cid: cid, qns: [16])
  }

  func playQuality(bvid: String, cid: Int64, qn: Int) -> Data {
    /* Progressive durl tops out at 1080P; 1080P+/4K are DASH-only. Requesting
       120 from the durl endpoint makes Bilibili return only 720P, so cap the
       progressive fallback at 1080P instead. */
    let target = qn <= 0 ? 80 : min(qn, 80)
    return play(bvid: bvid, cid: cid, qns: [target, 80, 74, 64, 32, 16])
  }

  func playRemote(bvid: String, cid: Int64, qn: Int) -> Data {
    guard !bvid.isEmpty else { return o11a1Error("bvid missing") }
    ensureBuvid()
    var resolvedCid = cid
    if resolvedCid <= 0 { resolvedCid = firstCid(bvid) }
    guard resolvedCid > 0 else { return o11a1Error("cid not found") }
    let qns = qn <= 0 ? [80, 64, 32, 16] : [qn, 80, 64, 32, 16]
    var selected: [String: Any]?
    var seen = Set<Int>()
    for candidate in qns {
      if seen.contains(candidate) { continue }
      seen.insert(candidate)
      guard let payload = json(
        base: Self.apiBase,
        path: "/x/player/playurl",
        query: ["bvid": bvid, "cid": "\(resolvedCid)", "qn": "\(candidate)", "fnval": "1", "fourk": "1"]
      ), o11a1Int(payload["code"]) == 0,
        let data = payload["data"] as? [String: Any],
        let durl = data["durl"] as? [[String: Any]], !durl.isEmpty else { continue }
      selected = data
      break
    }
    guard let data = selected,
          let durl = data["durl"] as? [[String: Any]],
          let first = durl.first,
          let remote = first["url"] as? String, !remote.isEmpty else {
      return o11a1Error("playurl unavailable")
    }
    let quality = o11a1Int(data["quality"])
    var output: [String: Any] = [
      "ok": true,
      "cid": resolvedCid,
      "url": remote,
      "quality": quality,
      "qualityLabel": o11a1QualityLabel(quality),
      "format": o11a1String(data["format"])
    ]
    if let backups = first["backup_url"] as? [String], let backup = backups.first, !backup.isEmpty {
      output["backup"] = backup
    }
    return o11a1Data(output)
  }

  func cookieHeader() -> String {
    return cookies.header()
  }

  func importCookieHeader(_ header: String) {
    for piece in header.split(separator: ";") {
      let parts = piece.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
      if parts.count == 2 {
        let name = String(parts[0]).trimmingCharacters(in: .whitespaces)
        let value = String(parts[1]).trimmingCharacters(in: .whitespaces)
        if !name.isEmpty { cookies.set(name, value) }
      }
    }
  }

  /* ---------- comments and danmaku ---------- */

  func comments(aid: Int64, page: Int) -> Data {
    return comments(aid: aid, page: page, sort: 2)
  }

  func comments(aid: Int64, page: Int, sort: Int) -> Data {
    guard aid > 0 else { return o11a1Error("aid missing") }
    ensureBuvid()
    guard let payload = json(
      base: Self.apiBase,
      path: "/x/v2/reply",
      query: ["type": "1", "oid": "\(aid)", "pn": "\(max(1, page))", "sort": "\(sort == 0 ? 0 : 2)"]
    ),
      o11a1Int(payload["code"]) == 0,
      let data = payload["data"] as? [String: Any] else {
      return o11a1Error("comments unavailable")
    }
    let replies = data["replies"] as? [[String: Any]] ?? []
    let items = replies.map { replyRow($0) }
    let pageInfo = data["page"] as? [String: Any]
    let count = pageInfo == nil ? items.count : o11a1Int(pageInfo?["count"])
    return o11a1Data([
      "ok": true, "items": items, "count": count,
      "page": max(1, page), "hasMore": replies.count >= 20
    ])
  }

  func commentsReplies(aid: Int64, root: Int64, page: Int) -> Data {
    guard aid > 0, root > 0 else { return o11a1Error("reply root missing") }
    ensureBuvid()
    guard let payload = json(
      base: Self.apiBase,
      path: "/x/v2/reply/reply",
      query: ["type": "1", "oid": "\(aid)", "root": "\(root)", "pn": "\(max(1, page))", "ps": "20"]
    ), o11a1Int(payload["code"]) == 0,
      let data = payload["data"] as? [String: Any] else {
      return o11a1Error("replies unavailable")
    }
    let replies = data["replies"] as? [[String: Any]] ?? []
    let items = replies.map { replyRow($0) }
    let pageInfo = data["page"] as? [String: Any]
    let count = pageInfo == nil ? items.count : o11a1Int(pageInfo?["count"])
    return o11a1Data([
      "ok": true, "items": items, "count": count,
      "page": max(1, page), "hasMore": replies.count >= 20
    ])
  }

  private func replyRow(_ reply: [String: Any]) -> [String: Any] {
    let member = reply["member"] as? [String: Any]
    let content = reply["content"] as? [String: Any]
    let user = o11a1String(member?["uname"])
    return [
      "rpid": o11a1Int64(reply["rpid"]),
      "root": o11a1Int64(reply["root"]),
      "parent": o11a1Int64(reply["parent"]),
      "rcount": o11a1Int(reply["rcount"]),
      "user": user.isEmpty ? "用户" : user,
      "avatar": o11a1HTTPS(o11a1String(member?["avatar"])),
      "message": o11a1String(content?["message"]),
      "like": o11a1Int(reply["like"]),
      "time": o11a1Int64(reply["ctime"])
    ]
  }

  func danmaku(cid: Int64) -> Data {
    guard cid > 0 else { return o11a1Error("cid missing") }
    ensureBuvid()
    guard let result = requestData(
      base: Self.apiBase,
      path: "/x/v1/dm/list.so",
      query: ["oid": "\(cid)"],
      withCookies: true,
      session: apiSession
    ), result.1.statusCode < 400 else {
      return o11a1Error("danmaku unavailable")
    }
    var data = result.0
    if let encoding = result.1.value(forHTTPHeaderField: "Content-Encoding")?.lowercased(),
       encoding.contains("deflate"),
       !data.starts(with: Data("<?xml".utf8)),
       let inflated = o11a1Inflate(data) {
      data = inflated
    }
    guard let xml = String(data: data, encoding: .utf8), !xml.isEmpty else {
      return o11a1Error("danmaku decode")
    }
    guard let regex = try? NSRegularExpression(
      pattern: "(?s)<d p=\"([^\"]+)\"[^>]*>(.*?)</d>",
      options: []
    ) else { return o11a1Error("danmaku regex") }
    let source = xml as NSString
    let matches = regex.matches(in: xml, options: [], range: NSRange(location: 0, length: source.length))
    var items: [[String: Any]] = []
    for match in matches {
      if items.count >= 1600 { break }
      guard match.numberOfRanges >= 3 else { continue }
      let parameter = source.substring(with: match.range(at: 1))
      let rawText = source.substring(with: match.range(at: 2))
      let parts = parameter.split(separator: ",").map { String($0) }
      guard parts.count >= 4,
            let time = Double(parts[0]),
            let mode = Int(parts[1]),
            let color = Int(parts[3]) else { continue }
      let plain = rawText.replacingOccurrences(
        of: "<[^>]+>",
        with: "",
        options: .regularExpression
      )
      let message = o11a1DecodeEntities(plain)
      items.append(["t": time, "mode": mode, "color": color, "text": message])
    }
    return o11a1Data(["ok": true, "items": items])
  }

  /* ---------- login ---------- */

  func session() -> Data {
    ensureBuvid()
    let payload = json(base: Self.apiBase, path: "/x/web-interface/nav")
    let data = payload?["data"] as? [String: Any]
    let loggedIn = o11a1Bool(data?["isLogin"]) || cookies.hasSession()
    return o11a1Data([
      "ok": true,
      "loggedIn": loggedIn,
      "name": o11a1String(data?["uname"]),
      "mid": o11a1Int64(data?["mid"]),
      "hasSession": cookies.hasSession()
    ])
  }

  func logout() -> Data {
    cookies.clear()
    return o11a1Data(["ok": true])
  }

  func loginCaptcha() -> [String: Any] {
    ensureBuvid()
    guard let payload = json(
      base: "https://passport.bilibili.com",
      path: "/x/passport-login/captcha",
      query: ["source": "main_web"]
    ), o11a1Int(payload["code"]) == 0,
      let data = payload["data"] as? [String: Any],
      let gee = data["geetest"] as? [String: Any] else {
      return ["ok": false, "error": "验证码初始化失败"]
    }
    return [
      "ok": true,
      "type": o11a1String(data["type"]),
      "token": o11a1String(data["token"]),
      "gt": o11a1String(gee["gt"]),
      "challenge": o11a1String(gee["challenge"])
    ]
  }

  func smsSend(tel: String, cid: String, token: String, challenge: String,
               validate: String, seccode: String) -> [String: Any] {
    guard let payload = postPassport(
      path: "/x/passport-login/web/sms/send",
      fields: [
        "cid": cid,
        "tel": tel,
        "source": "main_web",
        "token": token,
        "challenge": challenge,
        "validate": validate,
        "seccode": seccode
      ]
    ) else {
      return ["ok": false, "error": "短信发送失败"]
    }
    let code = o11a1Int(payload["code"])
    let data = payload["data"] as? [String: Any]
    return [
      "ok": code == 0,
      "code": code,
      "message": o11a1String(payload["message"]),
      "captchaKey": data == nil ? "" : o11a1String(data?["captcha_key"])
    ]
  }

  func smsLogin(tel: String, cid: String, code: String, captchaKey: String) -> Data {
    guard let payload = postPassport(
      path: "/x/passport-login/web/login/sms",
      fields: [
        "cid": cid,
        "tel": tel,
        "code": code,
        "source": "main_web",
        "captcha_key": captchaKey
      ]
    ) else {
      return o11a1Error("短信登录失败")
    }
    let result = o11a1Int(payload["code"])
    if result != 0 {
      return o11a1Error(o11a1String(payload["message"]).isEmpty ? "短信登录失败" : o11a1String(payload["message"]))
    }
    var out = session()
    out = out.isEmpty ? o11a1Data(["ok": true, "loggedIn": true]) : out
    return out
  }

  private func postPassport(path: String, fields: [String: String]) -> [String: Any]? {
    guard let url = URL(string: "https://passport.bilibili.com" + path) else { return nil }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.timeoutInterval = 20
    request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
    request.setValue("https://passport.bilibili.com/login", forHTTPHeaderField: "Referer")
    request.setValue("https://passport.bilibili.com", forHTTPHeaderField: "Origin")
    request.setValue("application/x-www-form-urlencoded; charset=UTF-8", forHTTPHeaderField: "Content-Type")
    let cookie = cookies.header()
    if !cookie.isEmpty { request.setValue(cookie, forHTTPHeaderField: "Cookie") }
    request.httpBody = formEncode(fields).data(using: .utf8)
    guard let (data, response) = perform(request, session: apiSession) else { return nil }
    cookies.absorb(response)
    return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
  }

  /* ---------- account / community / discovery ---------- */

  func qrGenerate() -> Data {
    ensureBuvid()
    guard let payload = json(
      base: "https://passport.bilibili.com",
      path: "/x/passport-login/web/qrcode/generate"
    ),
      o11a1Int(payload["code"]) == 0,
      let data = payload["data"] as? [String: Any] else {
      return o11a1Error("二维码生成失败")
    }
    return o11a1Data([
      "ok": true,
      "url": o11a1String(data["url"]),
      "key": o11a1String(data["qrcode_key"])
    ])
  }

  func qrPoll(key: String) -> Data {
    guard !key.isEmpty else { return o11a1Error("二维码已失效") }
    guard let payload = json(
      base: "https://passport.bilibili.com",
      path: "/x/passport-login/web/qrcode/poll",
      query: ["qrcode_key": key]
    ) else { return o11a1Error("登录状态查询失败") }
    let data = payload["data"] as? [String: Any] ?? [:]
    let state = o11a1Int(data["code"])
    if state == 0 {
      if let raw = data["url"] as? String, !raw.isEmpty,
         let components = URLComponents(string: raw),
         let items = components.queryItems {
        let header = items.map { "\($0.name)=\($0.value ?? "")" }.joined(separator: "; ")
        if !header.isEmpty { importCookieHeader(header) }
      }
      return o11a1Data([
        "ok": true,
        "state": 0,
        "loggedIn": true,
        "url": o11a1String(data["url"])
      ])
    }
    return o11a1Data([
      "ok": true,
      "state": state,
      "message": o11a1String(data["message"])
    ])
  }

  func account() -> Data {
    let data = navData()
    let level = data?["level_info"] as? [String: Any]
    let vip = data?["vip"] as? [String: Any]
    let mid = o11a1Int64(data?["mid"])
    var output: [String: Any] = [
      "ok": true,
      "loggedIn": o11a1Bool(data?["isLogin"]) || cookies.hasSession(),
      "hasSession": cookies.hasSession(),
      "name": o11a1String(data?["uname"]),
      "face": o11a1HTTPS(o11a1String(data?["face"])),
      "mid": mid,
      "level": level == nil ? 0 : o11a1Int(level?["current_level"]),
      "vip": vip != nil && o11a1Int(vip?["status"]) == 1,
      "vipLabel": o11a1String(vip?["label"]),
      "coins": data == nil ? 0 : o11a1Int(data?["coins"]),
      "sign": o11a1String(data?["sign"])
    ]
    if mid > 0, let relation = json(base: Self.apiBase, path: "/x/relation/stat", query: ["mid": "\(mid)"]),
       let relationData = relation["data"] as? [String: Any] {
      output["follower"] = o11a1Int64(relationData["follower"])
      output["following"] = o11a1Int64(relationData["following"])
    }
    return o11a1Data(output)
  }

  func favorites(page: Int) -> Data {
    guard cookies.hasSession() else { return needLogin("登录后查看收藏") }
    let folder = defaultFolderId()
    guard folder > 0 else {
      return o11a1Data(["ok": true, "loggedIn": true, "items": [], "count": 0, "page": page, "title": "收藏夹", "note": "收藏夹为空"])
    }
    guard let payload = json(base: Self.apiBase, path: "/x/v3/fav/resource/list", query: [
      "media_id": "\(folder)", "pn": "\(max(1, page))", "ps": "20", "platform": "web"
    ]), let data = payload["data"] as? [String: Any] else {
      return o11a1Error("收藏接口不可用")
    }
    let medias = data["medias"] as? [[String: Any]] ?? []
    var items: [[String: Any]] = []
    for media in medias { items.append(mediaVideo(media)) }
    return o11a1Data([
      "ok": true,
      "loggedIn": true,
      "items": items,
      "count": o11a1Int(data["info"]),
      "page": max(1, page),
      "title": "收藏夹",
      "hasMore": medias.count >= 20,
      "note": items.isEmpty ? "收藏夹为空" : ""
    ])
  }

  func history(page: Int, cursor: String) -> Data {
    guard cookies.hasSession() else { return needLogin("登录后查看历史") }
    var query: [String: String] = ["ps": "20", "type": "archive"]
    if cursor.contains("|") {
      let parts = cursor.split(separator: "|", maxSplits: 1, omittingEmptySubsequences: false)
      if parts.count == 2 {
        query["max"] = String(parts[0])
        query["view_at"] = String(parts[1])
      }
    }
    guard let payload = json(base: Self.apiBase, path: "/x/web-interface/history/cursor", query: query),
          let data = payload["data"] as? [String: Any] else {
      return o11a1Error("历史接口不可用")
    }
    let list = data["list"] as? [[String: Any]] ?? []
    var items: [[String: Any]] = []
    for item in list {
      let history = item["history"] as? [String: Any]
      let durationSec = o11a1Int(item["duration"])
      let progress = o11a1Int(item["progress"])
      let bvid = history == nil ? o11a1String(item["bvid"]) : o11a1String(history?["bvid"])
      let aid = history == nil ? o11a1Int64(item["oid"]) : o11a1Int64(history?["oid"])
      let cid = history == nil ? 0 : o11a1Int64(history?["cid"])
      let mid = history == nil ? 0 : o11a1Int64(history?["mid"])
      let owner = o11a1StripHTML(o11a1String(item["author_name"]))
      let meta: String
      if durationSec > 0 {
        meta = "\(owner) · 看到 \(o11a1Duration(progress)) / \(o11a1Duration(durationSec))"
      } else {
        meta = owner
      }
      items.append([
        "bvid": bvid,
        "aid": aid,
        "cid": cid,
        "mid": mid,
        "title": o11a1StripHTML(o11a1String(item["title"])),
        "pic": o11a1HTTPS(o11a1String(item["cover"])),
        "owner": owner,
        "duration": o11a1Duration(durationSec),
        "durationSec": durationSec,
        "progress": progress,
        "play": 0,
        "playText": "",
        "meta": meta
      ])
    }
    let cursorObject = data["cursor"] as? [String: Any]
    let maxCursor = cursorObject == nil ? 0 : o11a1Int64(cursorObject?["max"])
    let viewAt = cursorObject == nil ? 0 : o11a1Int64(cursorObject?["view_at"])
    return o11a1Data([
      "ok": true,
      "loggedIn": true,
      "items": items,
      "page": max(1, page),
      "next": maxCursor > 0 ? "\(maxCursor)|\(viewAt)" : "",
      "title": "历史",
      "hasMore": !items.isEmpty,
      "note": items.isEmpty ? "暂无历史" : ""
    ])
  }

  func following(page: Int) -> Data {
    guard cookies.hasSession() else { return needLogin("登录后查看关注动态") }
    guard let payload = json(base: Self.apiBase, path: "/x/polymer/web-dynamic/v1/feed/all", query: [
      "type": "video", "page": "\(max(1, page))", "features": "itemOpusStyle"
    ]) else { return o11a1Error("关注接口不可用") }
    let code = o11a1Int(payload["code"])
    if code == -101 { return needLogin("登录后查看关注动态") }
    if code != 0 { return apiFailure(code, o11a1String(payload["message"])) }
    let data = payload["data"] as? [String: Any]
    let list = data?["items"] as? [[String: Any]] ?? []
    var items: [[String: Any]] = []
    for item in list {
      let modules = item["modules"] as? [String: Any]
      let dynamic = modules?["module_dynamic"] as? [String: Any]
      let major = dynamic?["major"] as? [String: Any]
      if let archive = major?["archive"] as? [String: Any] {
        items.append(dynamicVideo(item, archive: archive))
      }
    }
    return o11a1Data(["ok": true, "loggedIn": true, "items": items, "page": max(1, page), "hasMore": list.count >= 20])
  }

  func dynamicFeed(page: Int, filter: String) -> Data {
    guard cookies.hasSession() else { return needLogin("登录后查看动态") }
    guard let payload = json(base: Self.apiBase, path: "/x/polymer/web-dynamic/v1/feed/all", query: [
      "type": "all", "page": "\(max(1, page))", "features": "itemOpusStyle"
    ]) else { return o11a1Error("动态接口不可用") }
    let code = o11a1Int(payload["code"])
    if code == -101 { return needLogin("登录后查看动态") }
    if code != 0 { return apiFailure(code, o11a1String(payload["message"])) }
    let data = payload["data"] as? [String: Any]
    let list = data?["items"] as? [[String: Any]] ?? []
    var items: [[String: Any]] = []
    for item in list {
      guard let row = dynamicRow(item) else { continue }
      let kind = o11a1String(row["kind"])
      if filter == "video" && kind != "video" { continue }
      if filter == "image" && kind == "video" { continue }
      items.append(row)
    }
    return o11a1Data(["ok": true, "loggedIn": true, "items": items, "page": max(1, page), "hasMore": list.count >= 20])
  }

  func messages(page: Int, filter: String) -> Data {
    guard cookies.hasSession() else { return needLogin("登录后查看消息") }
    let kind = filter == "at" ? "at" : (filter == "like" ? "like" : "reply")
    guard let payload = json(base: Self.apiBase, path: "/x/msgfeed/\(kind)", query: [
      "pn": "\(max(1, page))", "ps": "20"
    ]) else { return o11a1Error("消息接口不可用") }
    let code = o11a1Int(payload["code"])
    if code == -101 { return needLogin("登录后查看消息") }
    if code != 0 { return apiFailure(code, o11a1String(payload["message"])) }
    let data = payload["data"] as? [String: Any]
    let list = data?["items"] as? [[String: Any]] ?? []
    var items: [[String: Any]] = []
    for item in list {
      var user = item["user"] as? [String: Any]
      if user == nil, let users = item["users"] as? [[String: Any]], let first = users.first { user = first }
      let source = item["item"] as? [String: Any]
      var text = o11a1String(source?["source_content"])
      if text.isEmpty { text = o11a1String(source?["target_reply_content"]) }
      if text.isEmpty { text = o11a1String(source?["title"]) }
      if kind == "like" {
        let count = o11a1Int(item["count"])
        let name = user == nil ? "有人" : o11a1String(user?["uname"])
        text = "\(name)\(count > 1 ? " 等 \(count) 人" : "") 赞了你的评论"
      }
      let timestamp = o11a1Int64(item["reply_time"]) != 0
        ? o11a1Int64(item["reply_time"])
        : (o11a1Int64(item["at_time"]) != 0 ? o11a1Int64(item["at_time"]) : o11a1Int64(item["like_time"]))
      items.append([
        "user": user == nil ? "用户" : o11a1String(user?["uname"]),
        "avatar": o11a1HTTPS(o11a1String(user?["avatar"])),
        "mid": user == nil ? 0 : o11a1Int64(user?["mid"]),
        "text": o11a1StripHTML(text),
        "kind": kind,
        "unread": o11a1Int(item["is_read"]) == 0,
        "time": timestamp
      ])
    }
    return o11a1Data(["ok": true, "loggedIn": true, "items": items, "page": max(1, page), "kind": kind, "hasMore": list.count >= 20])
  }

  func ranking(page: Int) -> Data {
    guard let payload = json(base: Self.apiBase, path: "/x/web-interface/ranking/v2", query: ["rid": "0", "type": "all"]),
          let data = payload["data"] as? [String: Any] else {
      return o11a1Error("排行榜不可用")
    }
    let list = data["list"] as? [[String: Any]] ?? []
    let start = (max(1, page) - 1) * 20
    var items: [[String: Any]] = []
    if start < list.count {
      for index in start..<min(list.count, start + 20) {
        items.append(video(list[index], search: false))
      }
    }
    return o11a1Data(["ok": true, "items": items, "page": max(1, page), "total": list.count, "hasMore": start + 20 < list.count])
  }

  /* ---------- UP space ---------- */

  func space(mid: Int64, page: Int, order: String) -> Data {
    if mid <= 0 { return o11a1Error("缺少 UP 主 UID") }
    ensureBuvid()
    let pageNumber = max(1, page)
    let pageSize = 20
    let sort = order == "click" ? "click" : "pubdate"
    let referer = "https://space.bilibili.com/\(mid)/video"

    var payload = json(
      base: Self.apiBase,
      path: "/x/space/arc/search",
      query: [
        "mid": "\(mid)", "pn": "\(pageNumber)", "ps": "\(pageSize)",
        "tid": "0", "keyword": "", "order": sort,
        "order_avoided": "true", "jsonp": "jsonp"
      ]
    )
    var data = payload?["data"] as? [String: Any]
    var list = data?["list"] as? [String: Any]
    var videos = list?["vlist"] as? [[String: Any]]
    let oldPageInfo = data?["page"] as? [String: Any]
    let oldTotal = o11a1Int(oldPageInfo?["count"])
    let usable = o11a1Int(payload?["code"]) == 0
      && data != nil
      && (oldTotal == 0 || !(videos?.isEmpty ?? true))

    if !usable {
      let key = wbiKey()
      if !key.isEmpty {
        let params: [String: String] = [
          "mid": "\(mid)", "pn": "\(pageNumber)", "ps": "\(pageSize)",
          "tid": "0", "keyword": "", "order": sort, "platform": "web",
          "web_location": "1550101", "order_avoided": "true",
          "space_login_group": "2", "dm_img_list": "[]",
          "dm_img_str": "V2ViR0wgMS",
          "dm_cover_img_str": "SW50ZWwoUikgSEQgR3JhcGhpY3NJbnRlbA",
          "dm_img_inter": "{\"ds\":[],\"wh\":[0,0,0],\"of\":[0,0,0]}"
        ]
        payload = signedJSON(
          path: "/x/space/wbi/arc/search",
          query: wbiSign(params, key: key),
          referer: referer
        )
        data = payload?["data"] as? [String: Any]
        list = data?["list"] as? [String: Any]
        videos = list?["vlist"] as? [[String: Any]]
      }
    }

    let code = o11a1Int(payload?["code"])
    guard code == 0, let spaceData = data, let rows = videos else {
      let message = o11a1String(payload?["message"])
      return o11a1Error(message.isEmpty ? "UP 主空间加载失败" : message)
    }
    let pageInfo = spaceData["page"] as? [String: Any]
    let total = o11a1Int(pageInfo?["count"])
    var items: [[String: Any]] = []
    for row in rows {
      let owner = o11a1StripHTML(o11a1String(row["author"]))
      let plays = o11a1Int64(row["play"])
      let duration = o11a1String(row["duration"])
      items.append([
        "bvid": o11a1String(row["bvid"]),
        "aid": o11a1Int64(row["aid"]),
        "cid": o11a1Int64(row["cid"]),
        "title": o11a1StripHTML(o11a1String(row["title"])),
        "pic": o11a1HTTPS(o11a1String(row["pic"])),
        "owner": owner,
        "ownerFace": o11a1HTTPS(o11a1String(row["face"])),
        "mid": o11a1Int64(row["mid"]) != 0 ? o11a1Int64(row["mid"]) : mid,
        "duration": duration,
        "durationSec": o11a1DurationSeconds(duration),
        "pubdate": o11a1Int64(row["pubdate"]),
        "play": plays,
        "playText": o11a1Count(plays),
        "desc": o11a1StripHTML(o11a1String(row["description"])),
        "meta": "\(owner) · \(o11a1Count(plays)) 播放"
      ])
    }

    var output: [String: Any] = [
      "ok": true,
      "items": items,
      "total": total,
      "page": pageNumber,
      "hasMore": total > pageNumber * pageSize || (total == 0 && items.count >= pageSize)
    ]

    if let cardPayload = json(
      base: Self.apiBase,
      path: "/x/web-interface/card",
      query: ["mid": "\(mid)", "photo": "true"]
    ), let cardData = cardPayload["data"] as? [String: Any],
       let card = cardData["card"] as? [String: Any] {
      output["name"] = o11a1StripHTML(o11a1String(card["name"]))
      output["face"] = o11a1HTTPS(o11a1String(card["face"]))
      output["sign"] = o11a1StripHTML(o11a1String(card["sign"]))
      output["follower"] = o11a1Int64(card["fans"])
      output["followed"] = o11a1Bool(card["attention"])
    }
    if let relationPayload = json(
      base: Self.apiBase,
      path: "/x/relation/stat",
      query: ["mid": "\(mid)"]
    ), let stats = relationPayload["data"] as? [String: Any] {
      output["follower"] = o11a1Int64(stats["follower"])
      output["following"] = o11a1Int64(stats["following"])
    }
    return o11a1Data(output)
  }

  func bangumi(page: Int, seasonType: Int) -> Data {
    let type = seasonType <= 0 ? 1 : seasonType
    guard let payload = json(base: Self.apiBase, path: "/pgc/season/index/result", query: [
      "season_type": "\(type)", "page": "\(max(1, page))", "pagesize": "20",
      "order": "3", "st": "1", "sort": "0", "type": "1"
    ]), let data = payload["data"] as? [String: Any] else {
      return o11a1Error("番剧索引不可用")
    }
    let list = data["list"] as? [[String: Any]] ?? []
    var items: [[String: Any]] = []
    for item in list {
      var meta = o11a1StripHTML(o11a1String(item["index_show"]))
      let rating = o11a1Int(item["rating"])
      if rating > 0 { meta += (meta.isEmpty ? "" : " · ") + "\(rating) 分" }
      items.append([
        "kind": "season",
        "seasonId": o11a1Int64(item["season_id"]),
        "title": o11a1StripHTML(o11a1String(item["title"])),
        "pic": o11a1HTTPS(o11a1String(item["cover"])),
        "owner": "番剧",
        "duration": "",
        "bvid": "",
        "aid": 0,
        "cid": 0,
        "meta": meta,
        "badge": o11a1String(item["badge"])
      ])
    }
    return o11a1Data(["ok": true, "items": items, "page": max(1, page), "hasMore": list.count >= 20])
  }

  func season(seasonId: Int64) -> Data {
    guard let payload = json(base: Self.apiBase, path: "/pgc/view/web/season", query: ["season_id": "\(seasonId)"]),
          let result = payload["result"] as? [String: Any] else {
      return o11a1Error("番剧详情不可用")
    }
    let episodes = result["episodes"] as? [[String: Any]] ?? []
    var items: [[String: Any]] = []
    for (index, episode) in episodes.enumerated() {
      let epId = o11a1Int64(episode["id"]) != 0 ? o11a1Int64(episode["id"]) : o11a1Int64(episode["ep_id"])
      let title = o11a1String(episode["long_title"]).isEmpty
        ? o11a1String(episode["title"])
        : o11a1String(episode["long_title"])
      items.append([
        "epId": epId,
        "bvid": o11a1String(episode["bvid"]),
        "cid": o11a1Int64(episode["cid"]),
        "aid": o11a1Int64(episode["aid"]),
        "title": o11a1StripHTML(title.isEmpty ? "第 \(index + 1) 集" : title),
        "duration": o11a1String(episode["duration"]),
        "pic": o11a1HTTPS(o11a1String(episode["cover"]))
      ])
    }
    return o11a1Data([
      "ok": true,
      "seasonId": seasonId,
      "title": o11a1StripHTML(o11a1String(result["title"])),
      "cover": o11a1HTTPS(o11a1String(result["cover"])),
      "evaluate": o11a1StripHTML(o11a1String(result["evaluate"])),
      "episodes": items
    ])
  }

  func playPgc(epId: Int64, bvid: String, cid: Int64, qn: Int) -> Data {
    let target = qn <= 0 ? 80 : min(qn, 80)
    if !bvid.isEmpty && cid > 0 {
      let normal = play(bvid: bvid, cid: cid, qns: [target, 80, 74, 64, 32, 16])
      if let object = (try? JSONSerialization.jsonObject(with: normal)) as? [String: Any],
         o11a1Bool(object["ok"]) {
        return normal
      }
    }
    guard let payload = json(base: Self.apiBase, path: "/pgc/player/web/playurl", query: [
      "ep_id": "\(epId)", "qn": "\(target)", "fnval": "1", "fourk": "0"
    ]) else { return o11a1Error("番剧播放不可用") }
    let code = o11a1Int(payload["code"])
    guard code == 0, let result = payload["result"] as? [String: Any],
          let durl = result["durl"] as? [[String: Any]], let first = durl.first,
          let remote = first["url"] as? String, !remote.isEmpty else {
      return apiFailure(code == 0 ? -1 : code, o11a1String(payload["message"]))
    }
    let quality = o11a1Int(result["quality"])
    var mediaUrls = [remote]
    if let backups = first["backup_url"] as? [String], let backup = backups.first, !backup.isEmpty {
      mediaUrls.append(backup)
    }
    var output: [String: Any] = [
      "ok": true,
      "cid": cid,
      "url": remote,
      "remote": remote,
      "quality": quality,
      "qualityLabel": o11a1QualityLabel(quality),
      "format": o11a1String(result["format"]),
      "pgc": true
    ]
    if let accept = result["accept_quality"] as? [Any] {
      let labels = accept.map { o11a1QualityLabel(o11a1Int($0)) }.filter { !$0.isEmpty }
      if !labels.isEmpty { output["available"] = labels }
    }
    if output["available"] == nil { output["available"] = [o11a1QualityLabel(quality)] }
    if let backups = first["backup_url"] as? [String], let backup = backups.first, !backup.isEmpty {
      output["backup"] = backup
      output["backupRemote"] = backup
    }
    return o11a1Data(output)
  }

  func live(page: Int) -> Data {
    guard let payload = json(base: "https://api.live.bilibili.com", path: "/room/v1/room/get_user_recommend",
                             query: ["page": "\(max(1, page))", "page_size": "20"]),
          let list = payload["data"] as? [[String: Any]] else {
      return o11a1Error("直播推荐不可用")
    }
    var items: [[String: Any]] = []
    for item in list {
      let roomId = o11a1Int64(item["roomid"])
      if roomId <= 0 { continue }
      let owner = o11a1StripHTML(o11a1String(item["uname"]))
      let online = o11a1Int64(item["online"])
      items.append([
        "kind": "live",
        "live": true,
        "roomId": roomId,
        "title": o11a1StripHTML(o11a1String(item["title"])),
        "pic": o11a1HTTPS(o11a1String(item["user_cover"]).isEmpty
          ? (o11a1String(item["system_cover"]).isEmpty ? o11a1String(item["keyframe"]) : o11a1String(item["system_cover"]))
          : o11a1String(item["user_cover"])),
        "owner": owner,
        "mid": o11a1Int64(item["uid"]),
        "duration": "LIVE",
        "online": online,
        "meta": "\(owner) · \(o11a1Count(online)) 人气",
        "area": o11a1StripHTML(o11a1String(item["areaName"]))
      ])
    }
    return o11a1Data(["ok": true, "items": items, "page": max(1, page), "hasMore": list.count >= 20])
  }

  func liveDanmuInfo(roomId: Int64) -> Data {
    let params = ["id": "\(roomId)", "type": "0", "web_location": "444.8"]
    let key = wbiKey()
    let query = key.isEmpty
      ? "id=\(roomId)&type=0&web_location=444.8"
      : wbiSign(params, key: key)
    guard roomId > 0,
          let url = URL(string: "https://api.live.bilibili.com/xlive/web-room/v1/index/getDanmuInfo?" + query) else {
      return o11a1Error("直播弹幕信息不可用")
    }
    var request = URLRequest(url: url)
    request.timeoutInterval = 15
    request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
    request.setValue("https://live.bilibili.com/\(roomId)", forHTTPHeaderField: "Referer")
    request.setValue("https://live.bilibili.com", forHTTPHeaderField: "Origin")
    let cookie = cookies.header()
    if !cookie.isEmpty { request.setValue(cookie, forHTTPHeaderField: "Cookie") }
    guard let (data, http) = perform(request, session: apiSession) else {
      return o11a1Error("直播弹幕信息不可用")
    }
    cookies.absorb(http)
    guard let payload = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
      return o11a1Error("直播弹幕信息不可用")
    }
    let code = o11a1Int(payload["code"])
    guard code == 0, let info = payload["data"] as? [String: Any] else {
      return apiFailure(code, o11a1String(payload["message"]))
    }
    let hosts = info["host_list"] as? [[String: Any]] ?? []
    let first = hosts.first
    return o11a1Data([
      "ok": true,
      "token": o11a1String(info["token"]),
      "host": first == nil ? "broadcastlv.chat.bilibili.com" : o11a1String(first?["host"]),
      "wssPort": first == nil ? 443 : o11a1Int(first?["wss_port"])
    ])
  }

  func liveRoom(roomId: Int64) -> Data {
    guard let url = URL(string: "https://api.live.bilibili.com/xlive/web-room/v2/index/getRoomPlayInfo?room_id=\(roomId)&protocol=0,1&format=0,1,2&codec=0,1&qn=10000&platform=web&ptype=8") else {
      return o11a1Error("直播地址错误")
    }
    var request = URLRequest(url: url)
    request.timeoutInterval = 15
    request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
    request.setValue("https://live.bilibili.com/\(roomId)", forHTTPHeaderField: "Referer")
    request.setValue("https://live.bilibili.com", forHTTPHeaderField: "Origin")
    let cookie = cookies.header()
    if !cookie.isEmpty { request.setValue(cookie, forHTTPHeaderField: "Cookie") }
    guard let (data, http) = perform(request, session: apiSession) else { return o11a1Error("直播接口不可用") }
    cookies.absorb(http)
    guard let payload = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
          let result = payload["data"] as? [String: Any] else {
      return o11a1Error("直播接口不可用")
    }
    let playInfo = result["playurl_info"] as? [String: Any]
    let playurl = playInfo?["playurl"] as? [String: Any]
    let streams = playurl?["stream"] as? [[String: Any]] ?? []
    var hls = ""
    var flv = ""
    for stream in streams {
      let protocolName = o11a1String(stream["protocol_name"])
      let formats = stream["format"] as? [[String: Any]] ?? []
      for format in formats {
        let codecs = format["codec"] as? [[String: Any]] ?? []
        for codec in codecs where o11a1String(codec["codec_name"]) == "avc" {
          guard let built = liveURL(codec), !built.isEmpty else { continue }
          if protocolName == "http_hls" { hls = built }
          if protocolName == "http_stream" && o11a1String(format["format_name"]) == "flv" { flv = built }
        }
      }
    }
    return o11a1Data([
      "ok": true,
      "roomId": roomId,
      "liveStatus": o11a1Int(result["live_status"]),
      "url": hls.isEmpty ? flv : hls,
      "format": hls.isEmpty ? "flv" : "hls",
      "title": o11a1StripHTML(o11a1String(result["title"])),
      "owner": o11a1StripHTML(o11a1String(result["uname"]))
    ])
  }

  func liveHistory(roomId: Int64) -> Data {
    guard roomId > 0,
          let url = URL(string: "https://api.live.bilibili.com/xlive/web-room/v1/dM/gethistory?roomid=\(roomId)&room_type=0") else {
      return o11a1Error("直播弹幕不可用")
    }
    var request = URLRequest(url: url)
    request.timeoutInterval = 12
    request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
    request.setValue("https://live.bilibili.com/\(roomId)", forHTTPHeaderField: "Referer")
    request.setValue("https://live.bilibili.com", forHTTPHeaderField: "Origin")
    let cookie = cookies.header()
    if !cookie.isEmpty { request.setValue(cookie, forHTTPHeaderField: "Cookie") }
    guard let (data, http) = perform(request, session: apiSession) else {
      return o11a1Error("直播弹幕不可用")
    }
    cookies.absorb(http)
    guard let payload = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
          let room = (payload["data"] as? [String: Any])?["room"] as? [[String: Any]] else {
      return o11a1Error("直播弹幕不可用")
    }
    let rows: [[String: Any]] = room.suffix(20).compactMap { row in
      let text = o11a1String(row["text"])
      if text.isEmpty { return nil }
      let base = (row["user"] as? [String: Any])?["base"] as? [String: Any]
      var name = o11a1String(row["nickname"])
      if name.isEmpty { name = o11a1String(base?["name"]) }
      return [
        "user": name.isEmpty ? "观众" : name,
        "text": text,
        "time": o11a1String(row["timeline"])
      ]
    }
    return o11a1Data(["ok": true, "items": rows])
  }

  func searchHot() -> Data {
    guard let payload = json(
      base: Self.apiBase,
      path: "/x/web-interface/search/square",
      query: ["limit": "10"]
    ),
      o11a1Int(payload["code"]) == 0,
      let data = payload["data"] as? [String: Any],
      let trending = data["trending"] as? [String: Any],
      let list = trending["list"] as? [[String: Any]] else {
      return o11a1Error("热搜不可用")
    }
    let rows: [[String: Any]] = list.compactMap { row in
      let keyword = o11a1String(row["keyword"])
      if keyword.isEmpty { return nil }
      let show = o11a1String(row["show_name"])
      return ["keyword": keyword, "show": show.isEmpty ? keyword : show]
    }
    return o11a1Data(["ok": true, "items": rows])
  }

  private func liveURL(_ codec: [String: Any]) -> String? {
    let base = o11a1String(codec["base_url"])
    guard !base.isEmpty, let infos = codec["url_info"] as? [[String: Any]], let info = infos.first else { return nil }
    let host = o11a1String(info["host"])
    let extra = o11a1String(info["extra"])
    guard !host.isEmpty else { return nil }
    let separator = (base.hasSuffix("?") || base.hasSuffix("&") || extra.isEmpty) ? "" : "&"
    return "\(host)\(base)\(separator)\(extra)"
  }

  func zone(rid: Int, page: Int) -> Data {
    let area = rid <= 0 ? 1 : rid
    guard let payload = json(base: Self.apiBase, path: "/x/web-interface/newlist", query: [
      "rid": "\(area)", "pn": "\(max(1, page))", "ps": "20"
    ]), let data = payload["data"] as? [String: Any] else {
      return o11a1Error("分区不可用")
    }
    let archives = data["archives"] as? [[String: Any]] ?? []
    return o11a1Data([
      "ok": true,
      "items": archives.map { video($0, search: false) },
      "page": max(1, page),
      "rid": area,
      "title": o11a1StripHTML(o11a1String(data["name"])),
      "hasMore": archives.count >= 20
    ])
  }

  func videoInfo(bvid: String) -> Data {
    guard let payload = json(base: Self.apiBase, path: "/x/web-interface/view", query: ["bvid": bvid]),
          let data = payload["data"] as? [String: Any] else {
      return o11a1Error("视频信息不可用")
    }
    let owner = data["owner"] as? [String: Any]
    let stat = data["stat"] as? [String: Any]
    let pages = data["pages"] as? [[String: Any]] ?? []
    var output: [String: Any] = [
      "ok": true,
      "bvid": o11a1String(data["bvid"]),
      "aid": o11a1Int64(data["aid"]),
      "cid": o11a1Int64(data["cid"]),
      "mid": owner == nil ? 0 : o11a1Int64(owner?["mid"]),
      "owner": o11a1StripHTML(o11a1String(owner?["name"])),
      "ownerFace": o11a1HTTPS(o11a1String(owner?["face"])),
      "title": o11a1StripHTML(o11a1String(data["title"])),
      "desc": o11a1StripHTML(o11a1String(data["desc"])),
      "pic": o11a1HTTPS(o11a1String(data["pic"])),
      "pubdate": o11a1Int64(data["pubdate"]),
      "duration": o11a1Duration(o11a1Int(data["duration"])),
      "durationSec": o11a1Int(data["duration"]),
      "seasonId": o11a1Int64(data["season_id"])
    ]
    if let stat = stat {
      output["stat"] = [
        "view": o11a1Int64(stat["view"]),
        "danmaku": o11a1Int64(stat["danmaku"]),
        "reply": o11a1Int64(stat["reply"]),
        "favorite": o11a1Int64(stat["favorite"]),
        "coin": o11a1Int64(stat["coin"]),
        "share": o11a1Int64(stat["share"]),
        "like": o11a1Int64(stat["like"])
      ]
    }
    output["pages"] = pages.enumerated().map { pair -> [String: Any] in
      let index = pair.offset
      let page = pair.element
      return [
        "cid": o11a1Int64(page["cid"]),
        "page": o11a1Int(page["page"]) == 0 ? index + 1 : o11a1Int(page["page"]),
        "title": o11a1StripHTML(o11a1String(page["part"])),
        "duration": o11a1Int(page["duration"])
      ]
    }
    if cookies.hasSession(),
       let relationPayload = json(base: Self.apiBase, path: "/x/web-interface/archive/relation", query: ["bvid": bvid]),
       var relation = relationPayload["data"] as? [String: Any] {
      if let nested = relation["relation"] as? [String: Any] { relation = nested }
      output["liked"] = o11a1Bool(relation["like"])
      output["coined"] = o11a1Int(relation["coin"])
      output["faved"] = o11a1Bool(relation["favorite"])
      output["followed"] = o11a1Bool(relation["attention"])
    }
    return o11a1Data(output)
  }

  func related(bvid: String) -> Data {
    let id = bvid.trimmingCharacters(in: .whitespacesAndNewlines)
    if id.isEmpty { return o11a1Error("缺少视频编号") }
    ensureBuvid()
    guard let payload = json(
      base: Self.apiBase,
      path: "/x/web-interface/archive/related",
      query: ["bvid": id]
    ),
      o11a1Int(payload["code"]) == 0,
      let list = payload["data"] as? [[String: Any]] else {
      return o11a1Error("相关推荐不可用")
    }
    let items = list.map { video($0, search: false) }
    return o11a1Data(["ok": true, "bvid": id, "items": items])
  }

  func like(aid: Int64, on: Bool) -> Data {
    guard canWrite() else { return needLogin("请先登录") }
    guard let payload = postForm("https://api.bilibili.com/x/web-interface/archive/like", fields: [
      "aid": "\(aid)", "like": on ? "1" : "0", "csrf": csrfToken()
    ]) else { return o11a1Error("点赞失败") }
    return writeResult(payload, key: "liked", value: on)
  }

  func coin(aid: Int64, count: Int, likeAlso: Bool) -> Data {
    guard canWrite() else { return needLogin("请先登录") }
    guard let payload = postForm("https://api.bilibili.com/x/web-interface/coin/add", fields: [
      "aid": "\(aid)", "multiply": "\(min(2, max(1, count)))",
      "select_like": likeAlso ? "1" : "0", "csrf": csrfToken()
    ]) else { return o11a1Error("投币失败") }
    let result = writeResult(payload, key: "coined", value: true)
    return result
  }

  func favorite(aid: Int64, on: Bool) -> Data {
    guard canWrite() else { return needLogin("请先登录") }
    let folder = defaultFolderId()
    guard folder > 0 else { return apiFailure(-1, "没有可用的收藏夹") }
    guard let payload = postForm("https://api.bilibili.com/x/v3/fav/resource/deal", fields: [
      "rid": "\(aid)", "type": "2",
      "add_media_ids": on ? "\(folder)" : "",
      "del_media_ids": on ? "" : "\(folder)",
      "csrf": csrfToken()
    ]) else { return o11a1Error("收藏失败") }
    return writeResult(payload, key: "faved", value: on)
  }

  func follow(mid: Int64, on: Bool) -> Data {
    guard canWrite() else { return needLogin("请先登录") }
    guard let payload = postForm("https://api.bilibili.com/x/relation/modify", fields: [
      "fid": "\(mid)", "act": on ? "1" : "2", "re_src": "11", "csrf": csrfToken()
    ]) else { return o11a1Error("关注失败") }
    return writeResult(payload, key: "followed", value: on)
  }

  func sendComment(aid: Int64, message: String) -> Data {
    guard canWrite() else { return needLogin("请先登录") }
    guard let payload = postForm("https://api.bilibili.com/x/v2/reply/add", fields: [
      "oid": "\(aid)", "type": "1", "message": message, "csrf": csrfToken()
    ]) else { return o11a1Error("评论发送失败") }
    var result = writeResultObject(payload, key: "sent", value: true)
    if o11a1Bool(result["ok"]) {
      let data = payload["data"] as? [String: Any]
      result["rpid"] = data == nil ? 0 : o11a1Int64(data?["rpid"])
    }
    return o11a1Data(result)
  }

  func sendDanmaku(cid: Int64, message: String, progressMs: Int64) -> Data {
    guard canWrite() else { return needLogin("请先登录") }
    guard let payload = postForm("https://api.bilibili.com/x/v2/dm/post", fields: [
      "type": "1", "oid": "\(cid)", "msg": message, "progress": "\(max(0, progressMs))",
      "color": "16777215", "fontsize": "25", "pool": "0", "mode": "1", "plat": "1",
      "csrf": csrfToken()
    ]) else { return o11a1Error("弹幕发送失败") }
    return writeResult(payload, key: "sent", value: true)
  }

  /* ---------- helpers for community APIs ---------- */

  private func wbiKey() -> String {
    let now = Date().timeIntervalSince1970
    if !cachedWbiKey.isEmpty && now - cachedWbiAt < 6 * 60 * 60 {
      return cachedWbiKey
    }
    guard let data = navData(), let wbi = data["wbi_img"] as? [String: Any] else { return "" }
    let img = wbiFileKey(o11a1String(wbi["img_url"]))
    let sub = wbiFileKey(o11a1String(wbi["sub_url"]))
    if img.isEmpty || sub.isEmpty { return "" }
    let raw = Array(img + sub)
    var mixed = ""
    for index in Self.wbiMixinKey where index < raw.count {
      mixed.append(raw[index])
    }
    cachedWbiKey = String(mixed.prefix(32))
    cachedWbiAt = now
    return cachedWbiKey
  }

  private func wbiSign(_ params: [String: String], key: String) -> String {
    let query = params
      .sorted { $0.key < $1.key }
      .map { "\(wbiEncode($0.key))=\(wbiEncode($0.value))" }
      .joined(separator: "&")
    let signed = query + "&wts=\(Int(Date().timeIntervalSince1970))"
    return signed + "&w_rid=" + md5(signed + key)
  }

  private func wbiEncode(_ value: String) -> String {
    var allowed = CharacterSet.alphanumerics
    allowed.insert(charactersIn: "-_.~")
    return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
  }

  private func wbiFileKey(_ url: String) -> String {
    guard let last = url.split(separator: "/").last else { return "" }
    let name = String(last)
    if let dot = name.firstIndex(of: ".") {
      return String(name[..<dot])
    }
    return name
  }

  private func md5(_ text: String) -> String {
    let data = Data(text.utf8)
    var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
    data.withUnsafeBytes { buffer in
      _ = CC_MD5(buffer.baseAddress, CC_LONG(data.count), &digest)
    }
    return digest.map { String(format: "%02x", $0) }.joined()
  }

  private func signedJSON(path: String, query: String, referer: String) -> [String: Any]? {
    guard let url = URL(string: Self.apiBase + path + "?" + query) else { return nil }
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
    request.setValue(referer, forHTTPHeaderField: "Referer")
    request.setValue("https://space.bilibili.com", forHTTPHeaderField: "Origin")
    request.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
    request.setValue("zh-CN,zh;q=0.9,en;q=0.8", forHTTPHeaderField: "Accept-Language")
    let header = cookies.header()
    if !header.isEmpty { request.setValue(header, forHTTPHeaderField: "Cookie") }
    guard let result = perform(request, session: apiSession), result.1.statusCode < 400 else { return nil }
    cookies.absorb(result.1)
    return (try? JSONSerialization.jsonObject(with: result.0)) as? [String: Any]
  }

  private func navData() -> [String: Any]? {
    json(base: Self.apiBase, path: "/x/web-interface/nav")?["data"] as? [String: Any]
  }

  private func accountMid() -> Int64 {
    if cachedMid > 0 { return cachedMid }
    if let data = navData() { cachedMid = o11a1Int64(data["mid"]) }
    if cachedMid <= 0, let value = cookies.get("DedeUserID"), let parsed = Int64(value) { cachedMid = parsed }
    return cachedMid
  }

  private func defaultFolderId() -> Int64 {
    if cachedFolderId > 0 { return cachedFolderId }
    let mid = accountMid()
    guard mid > 0 else { return 0 }
    guard let payload = json(base: Self.apiBase, path: "/x/v3/fav/folder/created/list-all", query: ["up_mid": "\(mid)"]),
          let data = payload["data"] as? [String: Any],
          let list = data["list"] as? [[String: Any]] else { return 0 }
    var first: Int64 = 0
    for folder in list {
      let id = o11a1Int64(folder["id"])
      if id <= 0 { continue }
      if first == 0 { first = id }
      if o11a1Int(folder["media_count"]) > 0 { first = id; break }
    }
    cachedFolderId = first
    return first
  }

  private func csrfToken() -> String {
    cookies.get("bili_jct") ?? ""
  }

  private func canWrite() -> Bool {
    cookies.hasSession() && !csrfToken().isEmpty
  }

  private func needLogin(_ message: String) -> Data {
    o11a1Data(["ok": false, "needLogin": true, "error": message])
  }

  private func apiFailure(_ code: Int, _ message: String) -> Data {
    o11a1Data([
      "ok": false,
      "code": code,
      "error": message.isEmpty ? "操作失败" : message,
      "needLogin": code == -101 || code == -400
    ])
  }

  private func writeResultObject(_ payload: [String: Any], key: String, value: Bool) -> [String: Any] {
    let code = o11a1Int(payload["code"])
    var output: [String: Any] = [
      "ok": code == 0,
      "code": code,
      "error": code == 0 ? "" : o11a1String(payload["message"]),
      key: value
    ]
    if code == -101 || code == -400 { output["needLogin"] = true }
    return output
  }

  private func writeResult(_ payload: [String: Any], key: String, value: Bool) -> Data {
    o11a1Data(writeResultObject(payload, key: key, value: value))
  }

  private func postForm(_ url: String, fields: [String: String]) -> [String: Any]? {
    guard let parsed = URL(string: url) else { return nil }
    var request = URLRequest(url: parsed)
    request.httpMethod = "POST"
    request.timeoutInterval = 20
    request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
    request.setValue("https://www.bilibili.com/", forHTTPHeaderField: "Referer")
    request.setValue("https://www.bilibili.com/", forHTTPHeaderField: "Origin")
    request.setValue("application/x-www-form-urlencoded; charset=UTF-8", forHTTPHeaderField: "Content-Type")
    let cookie = cookies.header()
    if !cookie.isEmpty { request.setValue(cookie, forHTTPHeaderField: "Cookie") }
    request.httpBody = formEncode(fields).data(using: .utf8)
    guard let (data, response) = perform(request, session: apiSession) else { return nil }
    cookies.absorb(response)
    return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
  }

  private func formEncode(_ fields: [String: String]) -> String {
    fields.map { pair -> String in
      let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
      let name = pair.key.addingPercentEncoding(withAllowedCharacters: allowed) ?? pair.key
      let text = pair.value.addingPercentEncoding(withAllowedCharacters: allowed) ?? pair.value
      return "\(name)=\(text)"
    }.joined(separator: "&")
  }

  private func mediaVideo(_ media: [String: Any]) -> [String: Any] {
    let owner = media["upper"] as? [String: Any]
    let stats = media["cnt_info"] as? [String: Any]
    let name = o11a1StripHTML(o11a1String(owner?["name"]))
    let plays = stats == nil ? 0 : o11a1Int64(stats?["play"])
    let durationSec = o11a1Int(media["duration"])
    return [
      "bvid": o11a1String(media["bvid"]),
      "aid": o11a1Int64(media["id"]),
      "cid": o11a1Int64(media["cid"]),
      "mid": owner == nil ? 0 : o11a1Int64(owner?["mid"]),
      "title": o11a1StripHTML(o11a1String(media["title"])),
      "pic": o11a1HTTPS(o11a1String(media["cover"])),
      "owner": name.isEmpty ? "UP 主" : name,
      "duration": o11a1Duration(durationSec),
      "durationSec": durationSec,
      "play": plays,
      "playText": o11a1Count(plays),
      "desc": o11a1StripHTML(o11a1String(media["intro"])),
      "meta": "\(name.isEmpty ? "UP 主" : name) · \(o11a1Count(plays)) 播放"
    ]
  }

  private func dynamicVideo(_ item: [String: Any], archive: [String: Any]) -> [String: Any] {
    let modules = item["modules"] as? [String: Any]
    let author = modules?["module_author"] as? [String: Any]
    let stats = archive["stat"] as? [String: Any]
    let name = author == nil ? "UP 主" : o11a1StripHTML(o11a1String(author?["name"]))
    let plays = stats == nil ? 0 : o11a1Int64(stats?["play"])
    let durationText = o11a1String(archive["duration_text"])
    return [
      "bvid": o11a1String(archive["bvid"]),
      "aid": o11a1Int64(archive["aid"]),
      "cid": o11a1Int64(archive["cid"]),
      "mid": author == nil ? 0 : o11a1Int64(author?["mid"]),
      "title": o11a1StripHTML(o11a1String(archive["title"])),
      "pic": o11a1HTTPS(o11a1String(archive["cover"])),
      "owner": name.isEmpty ? "UP 主" : name,
      "duration": durationText.isEmpty ? "00:00" : durationText,
      "durationSec": o11a1DurationSeconds(durationText),
      "play": plays,
      "playText": o11a1Count(plays),
      "meta": "\(name.isEmpty ? "UP 主" : name) · \(o11a1Count(plays)) 播放"
    ]
  }

  private func dynamicRow(_ item: [String: Any]) -> [String: Any]? {
    let modules = item["modules"] as? [String: Any]
    guard let modules = modules else { return nil }
    let author = modules["module_author"] as? [String: Any]
    let dynamic = modules["module_dynamic"] as? [String: Any]
    let desc = dynamic?["desc"] as? [String: Any]
    let major = dynamic?["major"] as? [String: Any]
    var text = o11a1StripHTML(o11a1String(desc?["text"]))
    var images: [String] = []
    var output: [String: Any] = [
      "id": o11a1String(item["id_str"]),
      "type": o11a1String(item["type"]),
      "author": author == nil ? "用户" : o11a1StripHTML(o11a1String(author?["name"])),
      "avatar": o11a1HTTPS(o11a1String(author?["face"])),
      "mid": author == nil ? 0 : o11a1Int64(author?["mid"]),
      "time": author == nil ? 0 : o11a1Int64(author?["pub_ts"]),
      "text": text,
      "images": images,
      "likes": 0,
      "comments": 0
    ]
    if let archive = major?["archive"] as? [String: Any] {
      output["kind"] = "video"
      output["video"] = dynamicVideo(item, archive: archive)
    } else {
      if let draw = major?["draw"] as? [String: Any], let pictures = draw["items"] as? [[String: Any]] {
        for picture in pictures.prefix(9) { images.append(o11a1HTTPS(o11a1String(picture["src"]))) }
      }
      if let opus = major?["opus"] as? [String: Any] {
        if let pictures = opus["pics"] as? [[String: Any]] {
          for picture in pictures.prefix(9) { images.append(o11a1HTTPS(o11a1String(picture["url"]))) }
        }
        let summary = opus["summary"] as? [String: Any]
        if text.isEmpty, let summary = summary { text = o11a1StripHTML(o11a1String(summary["text"])) }
      }
      output["kind"] = images.isEmpty ? "text" : "image"
      output["images"] = images
      output["text"] = text
    }
    if let stats = modules["module_stat"] as? [String: Any] {
      output["likes"] = o11a1Int((stats["like"] as? [String: Any])?["count"])
      output["comments"] = o11a1Int((stats["comment"] as? [String: Any])?["count"])
    }
    return output
  }

  /* ---------- member center / AI ---------- */

  func memberCenter() -> Data {
    guard cookies.hasSession() else { return needLogin("登录后查看会员中心") }
    guard let payload = json(base: Self.apiBase, path: "/x/member/web/exp/reward"),
          o11a1Int(payload["code"]) == 0,
          let data = payload["data"] as? [String: Any] else {
      return needLogin("登录后查看会员中心")
    }
    let coinExp = o11a1Int(data["coins"])
    let tasks: [[String: Any]] = [
      ["key": "login", "label": "每日登录", "done": o11a1Bool(data["login"]), "reward": 5],
      ["key": "watch", "label": "每日观看", "done": o11a1Bool(data["watch"]), "reward": 5],
      ["key": "share", "label": "每日分享", "done": o11a1Bool(data["share"]), "reward": 5],
      ["key": "coins", "label": "每日投币", "done": coinExp >= 50, "reward": 50, "detail": "已获得 \(coinExp) / 50 经验"]
    ]
    var output: [String: Any] = ["ok": true, "tasks": tasks]
    if let vipPayload = json(base: Self.apiBase, path: "/x/vip/web/user/info"),
       let vip = vipPayload["data"] as? [String: Any] {
      output["vip"] = o11a1Int(vip["vip_status"]) == 1
      output["vipType"] = o11a1Int(vip["vip_type"])
      output["vipDue"] = o11a1Int64(vip["vip_due_date"])
    }
    if let logPayload = json(base: Self.apiBase, path: "/x/member/web/exp/log"),
       let logData = logPayload["data"] as? [String: Any],
       let list = logData["list"] as? [[String: Any]] {
      output["log"] = list.prefix(8).map { row in
        [
          "delta": o11a1Int(row["delta"]),
          "reason": o11a1StripHTML(o11a1String(row["reason"])),
          "time": o11a1String(row["time"])
        ] as [String: Any]
      }
    }
    return o11a1Data(output)
  }

  func aiChat(endpoint: String, apiKey: String, model: String, prompt: String) -> Data {
    if apiKey.isEmpty {
      return o11a1Data(["ok": false, "needKey": true, "error": "需要先填写 API Key"])
    }
    guard let url = URL(string: endpoint), !endpoint.isEmpty else {
      return o11a1Error("API 地址为空")
    }
    let body: [String: Any] = [
      "model": model.isEmpty ? "deepseek-chat" : model,
      "stream": false,
      "messages": [["role": "user", "content": prompt]]
    ]
    guard let payload = try? JSONSerialization.data(withJSONObject: body) else {
      return o11a1Error("请求体编码失败")
    }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.timeoutInterval = 70
    request.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    request.httpBody = payload
    guard let (data, response) = perform(request, session: apiSession) else {
      return o11a1Error("AI 接口无响应")
    }
    let raw = String(data: data, encoding: .utf8) ?? ""
    guard (200..<300).contains(response.statusCode) else {
      return o11a1Error("HTTP \(response.statusCode) · \(String(raw.prefix(240)))")
    }
    guard let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
      return o11a1Error("AI 返回了非 JSON 内容")
    }
    var text = ""
    if let choices = json["choices"] as? [[String: Any]], let first = choices.first {
      if let message = first["message"] as? [String: Any] { text = o11a1String(message["content"]) }
      if text.isEmpty { text = o11a1String(first["text"]) }
    }
    if text.isEmpty, let error = json["error"] as? [String: Any] {
      return o11a1Error(o11a1String(error["message"]))
    }
    return o11a1Data(["ok": true, "text": text, "model": o11a1String(json["model"])])
  }

  func dash(bvid: String, cid: Int64, qn: Int) -> Data {
    guard !bvid.isEmpty else { return o11a1Error("bvid missing") }
    ensureBuvid()
    var resolvedCid = cid
    if resolvedCid <= 0 { resolvedCid = firstCid(bvid) }
    guard resolvedCid > 0 else { return o11a1Error("cid not found") }
    var selected: [String: Any]?
    var seen = Set<Int>()
    let candidates = [qn, 80]
    for candidate in candidates {
      if candidate <= 0 || seen.contains(candidate) { continue }
      seen.insert(candidate)
      guard let payload = json(
        base: Self.apiBase,
        path: "/x/player/playurl",
        query: [
          "bvid": bvid, "cid": "\(resolvedCid)", "qn": "\(candidate)",
          "fnval": "4048", "fourk": "1"
        ]
      ) else { continue }
      let code = o11a1Int(payload["code"])
      guard code == 0, let data = payload["data"] as? [String: Any],
            data["dash"] is [String: Any] else { continue }
      selected = data
      break
    }
    guard let data = selected,
          let dash = data["dash"] as? [String: Any] else {
      return o11a1Error("当前账号没有可用的 DASH 清晰度")
    }
    let videos = dash["video"] as? [[String: Any]] ?? []
    let audios = dash["audio"] as? [[String: Any]] ?? []
    let videoRows: [[String: Any]] = videos.compactMap { track in
      let codecid = o11a1Int(track["codecid"])
      if codecid != 7 && codecid != 12 && codecid != 13 { return nil }
      return dashRow(track, audio: false)
    }
    var audioRows: [[String: Any]] = []
    for track in audios {
      if let row = dashRow(track, audio: true) { audioRows.append(row) }
    }
    guard !videoRows.isEmpty, !audioRows.isEmpty else {
      return o11a1Error("当前清晰度没有可播放的 DASH 轨道")
    }
    let quality = o11a1Int(data["quality"])
    var output: [String: Any] = [
      "ok": true,
      "cid": resolvedCid,
      "quality": quality,
      "qualityLabel": o11a1QualityLabel(quality),
      "video": videoRows,
      "audio": audioRows
    ]
    if let accept = data["accept_quality"] { output["acceptQuality"] = accept }
    if let accept = data["accept_quality"] as? [Any] {
      let labels = accept.map { o11a1QualityLabel(o11a1Int($0)) }.filter { !$0.isEmpty }
      if !labels.isEmpty { output["available"] = labels }
    }
    if output["available"] == nil { output["available"] = [o11a1QualityLabel(quality)] }
    let durationMs = o11a1Int(data["timelength"])
    if durationMs > 0 {
      output["durationMs"] = durationMs
    } else if let seconds = dash["duration"] as? NSNumber, seconds.doubleValue > 0 {
      output["durationMs"] = Int(seconds.doubleValue * 1000)
    }
    return o11a1Data(output)
  }

  private func dashRow(_ track: [String: Any], audio: Bool) -> [String: Any]? {
    let base = o11a1String(track["baseUrl"]).isEmpty
      ? o11a1String(track["base_url"])
      : o11a1String(track["baseUrl"])
    guard !base.isEmpty else { return nil }
    var mediaUrls = [base]
    var backup = ""
    if let backups = track["backupUrl"] as? [String], let value = backups.first, !value.isEmpty {
      backup = value
    } else if let backups = track["backup_url"] as? [String], let value = backups.first, !value.isEmpty {
      backup = value
    }
    if !backup.isEmpty { mediaUrls.append(backup) }
    var row: [String: Any] = [
      "qn": o11a1Int(track["id"]),
      "codecid": o11a1Int(track["codecid"]),
      "bandwidth": o11a1Int64(track["bandwidth"]),
      "mime": o11a1String(track["mimeType"]).isEmpty ? (audio ? "audio/mp4" : "video/mp4") : o11a1String(track["mimeType"]),
      "codecs": o11a1String(track["codecs"]),
      "width": o11a1Int(track["width"]),
      "height": o11a1Int(track["height"]),
      "url": base,
      "remote": base
    ]
    if !backup.isEmpty {
      row["backup"] = backup
      row["backupRemote"] = backup
    }
    return row
  }

  func proxyInfo() -> Data {
    return o11a1Data(["ok": true, "port": 0, "disabled": true])
  }

  func hasSession() -> Bool {
    return cookies.hasSession()
  }

  func mediaHeaders() -> [String: String] {
    var headers: [String: String] = [
      "User-Agent": Self.userAgent,
      "Referer": "https://www.bilibili.com/",
      "Origin": "https://www.bilibili.com",
      "Accept": "*/*",
    ]
    let cookie = cookies.header()
    if !cookie.isEmpty { headers["Cookie"] = cookie }
    return headers
  }
}
