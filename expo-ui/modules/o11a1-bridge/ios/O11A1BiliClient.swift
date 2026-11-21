import Foundation

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
  static let passportBase = "https://passport.bilibili.com"
  static let userAgent = "Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36"

  private let cookies = O11A1CookieStore()
  private let apiSession: URLSession
  private let mediaSession: URLSession
  private let buvidLock = NSLock()
  private var buvidBusy = false
  private let cidLock = NSLock()
  private var cidCache: [String: Int64] = [:]

  var port: Int = 0

  init() {
    let apiConfig = URLSessionConfiguration.ephemeral
    apiConfig.httpCookieStorage = nil
    apiConfig.httpShouldSetCookies = false
    apiConfig.requestCachePolicy = .reloadIgnoringLocalCacheData
    apiConfig.timeoutIntervalForRequest = 20
    apiConfig.timeoutIntervalForResource = 45
    apiSession = URLSession(configuration: apiConfig)

    let mediaConfig = URLSessionConfiguration.ephemeral
    mediaConfig.httpCookieStorage = nil
    mediaConfig.httpShouldSetCookies = false
    mediaConfig.requestCachePolicy = .reloadIgnoringLocalCacheData
    mediaConfig.timeoutIntervalForRequest = 60
    mediaConfig.timeoutIntervalForResource = 120
    mediaSession = URLSession(configuration: mediaConfig)
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

  private func video(_ item: [String: Any], search: Bool) -> [String: Any] {
    var title = o11a1StripHTML(o11a1String(item["title"]))
    if title.isEmpty { title = "视频" }
    let rawPic = o11a1String(item["pic"]).isEmpty
      ? o11a1String(item["pic_url"])
      : o11a1String(item["pic"])
    let pic = o11a1HTTPS(rawPic)
    var owner = "UP 主"
    if let ownerObject = item["owner"] as? [String: Any] {
      let name = o11a1StripHTML(o11a1String(ownerObject["name"]))
      if !name.isEmpty { owner = name }
    } else {
      let name = o11a1StripHTML(o11a1String(item["author"]))
      if !name.isEmpty { owner = name }
    }
    var duration = search ? o11a1String(item["duration"]) : o11a1Duration(o11a1Int(item["duration"]))
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
      "title": title,
      "pic": pic,
      "owner": owner,
      "duration": duration,
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
    guard port > 0 else { return o11a1Error("server not ready") }
    ensureBuvid()
    var resolvedCid = firstCid(bvid)
    if resolvedCid <= 0 { resolvedCid = cid }
    guard resolvedCid > 0 else { return o11a1Error("cid not found") }
    print("[O11A1] play \(bvid) cid=\(resolvedCid)")
    var selected: [String: Any]?
    var seen = Set<Int>()
    for qn in qns {
      if seen.contains(qn) { continue }
      seen.insert(qn)
      guard let payload = json(
        base: Self.apiBase,
        path: "/x/player/playurl",
        query: [
          "bvid": bvid,
          "cid": "\(resolvedCid)",
          "qn": "\(qn)",
          "fnval": "1",
          "fourk": "0"
        ]
      ),
        o11a1Int(payload["code"]) == 0,
        let data = payload["data"] as? [String: Any],
        let durl = data["durl"] as? [[String: Any]],
        !durl.isEmpty else { continue }
      selected = data
      break
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
    let primaryToken = token(for: [remote])
    let backupToken = urls.count > 1 ? token(for: [urls[1]]) : ""
    let quality = o11a1Int(data["quality"])
    let base = "http://127.0.0.1:\(port)"
    var output: [String: Any] = [
      "ok": true,
      "cid": resolvedCid,
      "url": "\(base)/media?u=\(primaryToken)",
      "quality": quality,
      "qualityLabel": o11a1QualityLabel(quality),
      "format": o11a1String(data["format"])
    ]
    if !backupToken.isEmpty { output["backup"] = "\(base)/media?u=\(backupToken)" }
    return o11a1Data(output)
  }

  func playLow(bvid: String, cid: Int64) -> Data {
    return play(bvid: bvid, cid: cid, qns: [16])
  }

  func playQuality(bvid: String, cid: Int64, qn: Int) -> Data {
    if qn <= 0 { return play(bvid: bvid, cid: cid, qns: [64, 32, 16]) }
    return play(bvid: bvid, cid: cid, qns: [qn, 32, 16])
  }

  private func token(for urls: [String]) -> String {
    if let data = try? JSONSerialization.data(withJSONObject: urls, options: []) {
      return o11a1Base64URLEncode(data)
    }
    return o11a1Base64URLEncode(Data((urls.first ?? "").utf8))
  }

  struct O11A1MediaChunk {
    let data: Data
    let total: Int64
  }

  func fetchMedia(urlString: String, start: Int64, end: Int64) -> O11A1MediaChunk? {
    guard let url = URL(string: urlString) else { return nil }
    print("[O11A1] media \(start)-\(end) host=\(url.host ?? "?")")
    var total: Int64 = 0
    var headRequest = URLRequest(url: url)
    headRequest.httpMethod = "HEAD"
    headRequest.timeoutInterval = 15
    applyMediaHeaders(&headRequest)
    if let (_, response) = perform(headRequest, session: mediaSession), response.statusCode < 400 {
      if let length = response.value(forHTTPHeaderField: "Content-Length"),
         let value = Int64(length) {
        total = value
      }
    }
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.timeoutInterval = 60
    applyMediaHeaders(&request)
    request.setValue("bytes=\(start)-\(end)", forHTTPHeaderField: "Range")
    guard let (data, response) = perform(request, session: mediaSession),
          response.statusCode < 400 else { return nil }
    if total <= 0,
       let contentRange = response.value(forHTTPHeaderField: "Content-Range"),
       let slash = contentRange.lastIndex(of: "/") {
      total = Int64(String(contentRange[contentRange.index(after: slash)...])) ?? 0
    }
    if total <= 0 { total = start + Int64(data.count) }
    let maximum = Int(max(0, end - start + 1))
    var payload = data
    if response.statusCode == 200 && data.count > maximum {
      payload = Data(data.prefix(maximum))
      total = max(total, Int64(data.count))
    }
    if payload.isEmpty { return nil }
    return O11A1MediaChunk(data: payload, total: max(total, start + Int64(payload.count)))
  }

  private func applyMediaHeaders(_ request: inout URLRequest) {
    request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
    request.setValue("https://www.bilibili.com/", forHTTPHeaderField: "Referer")
    request.setValue("*/*", forHTTPHeaderField: "Accept")
    request.setValue("identity", forHTTPHeaderField: "Accept-Encoding")
  }

  /* ---------- comments and danmaku ---------- */

  func comments(aid: Int64, page: Int) -> Data {
    guard aid > 0 else { return o11a1Error("aid missing") }
    ensureBuvid()
    guard let payload = json(
      base: Self.apiBase,
      path: "/x/v2/reply",
      query: ["type": "1", "oid": "\(aid)", "pn": "\(max(1, page))", "sort": "2"]
    ),
      o11a1Int(payload["code"]) == 0,
      let data = payload["data"] as? [String: Any] else {
      return o11a1Error("comments unavailable")
    }
    let replies = data["replies"] as? [[String: Any]] ?? []
    var items: [[String: Any]] = []
    for reply in replies {
      let member = reply["member"] as? [String: Any]
      let content = reply["content"] as? [String: Any]
      let user = o11a1String(member?["uname"])
      items.append([
        "user": user.isEmpty ? "用户" : user,
        "avatar": o11a1HTTPS(o11a1String(member?["avatar"])),
        "message": o11a1String(content?["message"]),
        "like": o11a1Int(reply["like"]),
        "time": o11a1Int64(reply["ctime"])
      ])
    }
    let pageInfo = data["page"] as? [String: Any]
    let count = pageInfo == nil ? items.count : o11a1Int(pageInfo?["count"])
    return o11a1Data(["ok": true, "items": items, "count": count])
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

  func qrGenerate() -> Data {
    ensureBuvid()
    guard let payload = json(
      base: Self.passportBase,
      path: "/x/passport-login/web/qrcode/generate"
    ),
      o11a1Int(payload["code"]) == 0,
      let data = payload["data"] as? [String: Any] else {
      return o11a1Error("qr unavailable")
    }
    let url = o11a1String(data["url"])
    let key = o11a1String(data["qrcode_key"])
    if url.isEmpty || key.isEmpty { return o11a1Error("qr empty") }
    return o11a1Data([
      "ok": true,
      "key": key,
      "url": url,
      "image": o11a1QRCodePNGBase64(url)
    ])
  }

  func qrPoll(key: String) -> Data {
    guard !key.isEmpty else { return o11a1Error("key missing") }
    ensureBuvid()
    guard let payload = json(
      base: Self.passportBase,
      path: "/x/passport-login/web/qrcode/poll",
      query: ["qrcode_key": key]
    ) else { return o11a1Error("qr poll unavailable") }
    let data = payload["data"] as? [String: Any]
    let code = o11a1Int(data?["code"])
    if code == 0, let loginURL = data?["url"] as? String {
      absorbLoginURL(loginURL)
    }
    return o11a1Data([
      "ok": true,
      "code": code,
      "message": o11a1String(data?["message"]),
      "loggedIn": code == 0 || cookies.hasSession()
    ])
  }

  private func absorbLoginURL(_ raw: String) {
    guard let components = URLComponents(string: raw),
          let query = components.percentEncodedQuery else { return }
    let names: Set<String> = ["SESSDATA", "bili_jct", "DedeUserID", "DedeUserID__ckMd5", "sid"]
    for pair in query.split(separator: "&") {
      let pieces = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
      let name = String(pieces[0])
      if names.contains(name), pieces.count > 1 {
        cookies.set(name, String(pieces[1]))
      }
    }
  }

  func proxyInfo() -> Data {
    return o11a1Data(["ok": true, "port": port])
  }
}
