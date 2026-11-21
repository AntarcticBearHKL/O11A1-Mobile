import Foundation

/// Progressive MP4 offline queue for iOS. Files stay in Documents/offline and are served by the loopback server.
final class O11A1Downloads {
  private let client: O11A1BiliClient
  private let dir: URL
  private let indexURL: URL
  private let lock = NSLock()
  private var items: [[String: Any]] = []
  private var sessions: [String: O11A1DownloadSession] = [:]

  init(client: O11A1BiliClient) {
    self.client = client
    let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    dir = documents.appendingPathComponent("offline", isDirectory: true)
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    indexURL = dir.appendingPathComponent("index.json")
    load()
  }

  func start(bvid: String, cid: Int64, title: String, pic: String, quality: String) -> Data {
    guard !bvid.isEmpty else { return o11a1Error("缺少 BV 号") }
    let play = decode(client.playRemote(bvid: bvid, cid: cid, qn: qn(quality)))
    guard o11a1Bool(play["ok"]), let remote = play["url"] as? String, !remote.isEmpty else {
      return o11a1Error(o11a1String(play["error"]).isEmpty ? "无法获取下载地址" : o11a1String(play["error"]))
    }
    let realCid = o11a1Int64(play["cid"]) != 0 ? o11a1Int64(play["cid"]) : cid
    let id = "\(bvid)-\(realCid)"
    lock.lock()
    var item = items.first(where: { o11a1String($0["id"]) == id }) ?? [:]
    if o11a1String(item["status"]) == "completed",
       FileManager.default.fileExists(atPath: o11a1String(item["path"])) {
      let decorated = decorateLocked(item)
      lock.unlock()
      return o11a1Data(["ok": true, "item": decorated])
    }
    item["id"] = id
    item["bvid"] = bvid
    item["cid"] = realCid
    item["title"] = title.isEmpty ? bvid : title
    item["pic"] = pic
    item["quality"] = o11a1String(play["qualityLabel"]).isEmpty ? quality : o11a1String(play["qualityLabel"])
    item["status"] = "downloading"
    item["downloaded"] = o11a1Int64(item["downloaded"])
    item["total"] = o11a1Int64(item["total"])
    item["created"] = o11a1Int64(item["created"]) != 0 ? o11a1Int64(item["created"]) : Int64(Date().timeIntervalSince1970 * 1000)
    item["error"] = ""
    if !items.contains(where: { o11a1String($0["id"]) == id }) { items.append(item) }
    saveLocked()
    lock.unlock()
    begin(item: item, remote: remote, backup: o11a1String(play["backup"]))
    return o11a1Data(["ok": true, "item": decorate(item)])
  }

  func list() -> Data {
    lock.lock()
    let rows = items.map { decorateLocked($0) }
    let storage = items.reduce(Int64(0)) { $0 + (o11a1String($1["status"]) == "completed" ? o11a1Int64($1["downloaded"]) : 0) }
    lock.unlock()
    return o11a1Data(["ok": true, "items": rows, "storage": storage, "count": rows.count])
  }

  func remove(id: String) -> Data {
    lock.lock()
    sessions[id]?.cancel()
    sessions.removeValue(forKey: id)
    if let item = items.first(where: { o11a1String($0["id"]) == id }) {
      try? FileManager.default.removeItem(atPath: o11a1String(item["path"]))
      try? FileManager.default.removeItem(at: dir.appendingPathComponent("\(id).part"))
      items.removeAll { o11a1String($0["id"]) == id }
      saveLocked()
    }
    lock.unlock()
    return o11a1Data(["ok": true])
  }

  func pause(id: String) -> Data {
    lock.lock()
    sessions[id]?.cancel()
    sessions.removeValue(forKey: id)
    if let index = items.firstIndex(where: { o11a1String($0["id"]) == id }),
       o11a1String(items[index]["status"]) == "downloading" {
      items[index]["status"] = "paused"
      saveLocked()
    }
    lock.unlock()
    return o11a1Data(["ok": true])
  }

  func resume(id: String) -> Data {
    lock.lock()
    guard let index = items.firstIndex(where: { o11a1String($0["id"]) == id }) else {
      lock.unlock()
      return o11a1Error("任务不存在")
    }
    if o11a1String(items[index]["status"]) == "completed" {
      let row = decorateLocked(items[index])
      lock.unlock()
      return o11a1Data(["ok": true, "item": row])
    }
    let item = items[index]
    items[index]["status"] = "downloading"
    items[index]["error"] = ""
    saveLocked()
    lock.unlock()
    let play = decode(client.playRemote(bvid: o11a1String(item["bvid"]), cid: o11a1Int64(item["cid"]), qn: qn(o11a1String(item["quality"]))))
    guard o11a1Bool(play["ok"]), let remote = play["url"] as? String else {
      return o11a1Error(o11a1String(play["error"]).isEmpty ? "无法获取下载地址" : o11a1String(play["error"]))
    }
    begin(item: item, remote: remote, backup: o11a1String(play["backup"]))
    return o11a1Data(["ok": true, "item": decorate(item)])
  }

  private func begin(item: [String: Any], remote: String, backup: String) {
    let id = o11a1String(item["id"])
    let part = dir.appendingPathComponent("\(id).part")
    let target = dir.appendingPathComponent("\(id).mp4")
    let existing = ((try? FileManager.default.attributesOfItem(atPath: part.path))?[.size] as? NSNumber)?.int64Value ?? 0
    let urls = [remote, backup].filter { !$0.isEmpty }
    let session = O11A1DownloadSession(
      id: id,
      part: part,
      existing: existing,
      urls: urls,
      cookie: client.cookieHeader(),
      onProgress: { [weak self] downloaded, total in
        guard let self = self else { return }
        self.lock.lock()
        if let index = self.items.firstIndex(where: { o11a1String($0["id"]) == id }) {
          self.items[index]["downloaded"] = downloaded
          if total > 0 { self.items[index]["total"] = total }
          self.saveLocked()
        }
        self.lock.unlock()
      },
      onFinish: { [weak self] error in
        guard let self = self else { return }
        self.lock.lock()
        defer { self.lock.unlock() }
        self.sessions.removeValue(forKey: id)
        guard let index = self.items.firstIndex(where: { o11a1String($0["id"]) == id }) else { return }
        if let error = error {
          if self.items[index]["status"] as? String != "paused" {
            self.items[index]["status"] = "error"
            self.items[index]["error"] = error.localizedDescription
          }
          self.saveLocked()
          return
        }
        do {
          if FileManager.default.fileExists(atPath: target.path) {
            try FileManager.default.removeItem(at: target)
          }
          try FileManager.default.moveItem(at: part, to: target)
          let size = ((try? FileManager.default.attributesOfItem(atPath: target.path))?[.size] as? NSNumber)?.int64Value ?? 0
          self.items[index]["status"] = "completed"
          self.items[index]["path"] = target.path
          self.items[index]["downloaded"] = size
          self.items[index]["total"] = size
          self.items[index]["error"] = ""
          print("[O11A1] download complete \(id) \(size)")
        } catch {
          self.items[index]["status"] = "error"
          self.items[index]["error"] = error.localizedDescription
        }
        self.saveLocked()
      }
    )
    lock.lock()
    sessions[id] = session
    lock.unlock()
    session.start()
  }

  private func decorate(_ item: [String: Any]) -> [String: Any] {
    lock.lock()
    let row = decorateLocked(item)
    lock.unlock()
    return row
  }

  private func decorateLocked(_ item: [String: Any]) -> [String: Any] {
    var row = item
    let path = o11a1String(item["path"])
    if o11a1String(item["status"]) == "completed",
       !FileManager.default.fileExists(atPath: path) {
      row["status"] = "missing"
    }
    let downloaded = o11a1Int64(item["downloaded"])
    let total = o11a1Int64(item["total"])
    row["progress"] = total > 0 ? min(100, Int((Double(downloaded) * 100).rounded() / Double(total))) : 0
    row["downloadedText"] = sizeText(downloaded)
    row["totalText"] = total > 0 ? sizeText(total) : "未知"
    if o11a1String(row["status"]) == "completed", !path.isEmpty {
      row["url"] = "http://127.0.0.1:\(client.port)/file?p=\(path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
    }
    return row
  }

  private func load() {
    guard let data = try? Data(contentsOf: indexURL),
          let rows = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return }
    items = rows.map { row in
      var copy = row
      if o11a1String(copy["status"]) == "downloading" { copy["status"] = "paused" }
      return copy
    }
  }

  private func saveLocked() {
    guard let data = try? JSONSerialization.data(withJSONObject: items) else { return }
    try? data.write(to: indexURL)
  }

  private func decode(_ data: Data) -> [String: Any] {
    (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
  }

  private func qn(_ label: String) -> Int {
    switch label {
    case "4K": return 120
    case "1080P60": return 116
    case "1080P+": return 112
    case "1080P": return 80
    case "720P": return 64
    case "480P": return 32
    case "360P", "仅音频": return 16
    default: return 64
    }
  }

  private func sizeText(_ bytes: Int64) -> String {
    if bytes >= 1_073_741_824 { return String(format: "%.2f GB", Double(bytes) / 1_073_741_824) }
    if bytes >= 1_048_576 { return String(format: "%.1f MB", Double(bytes) / 1_048_576) }
    if bytes >= 1024 { return String(format: "%.0f KB", Double(bytes) / 1024) }
    return "\(bytes) B"
  }
}

private final class O11A1DownloadSession: NSObject, URLSessionDataDelegate {
  private let id: String
  private let part: URL
  private let urls: [String]
  private let cookie: String
  private let onProgress: (Int64, Int64) -> Void
  private let onFinish: (Error?) -> Void
  private var session: URLSession?
  private var handle: FileHandle?
  private var downloaded: Int64
  private var total: Int64 = 0
  private var urlIndex = 0
  private var cancelled = false
  private var lastProgress = Date.distantPast

  init(
    id: String,
    part: URL,
    existing: Int64,
    urls: [String],
    cookie: String,
    onProgress: @escaping (Int64, Int64) -> Void,
    onFinish: @escaping (Error?) -> Void
  ) {
    self.id = id
    self.part = part
    self.urls = urls
    self.cookie = cookie
    self.downloaded = existing
    self.onProgress = onProgress
    self.onFinish = onFinish
    super.init()
  }

  func start() {
    guard urlIndex < urls.count, let url = URL(string: urls[urlIndex]) else {
      onFinish(NSError(domain: "O11A1Download", code: 1, userInfo: [NSLocalizedDescriptionKey: "下载地址不可用"]))
      return
    }
    var request = URLRequest(url: url)
    request.timeoutInterval = 60
    request.setValue("Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36", forHTTPHeaderField: "User-Agent")
    request.setValue("https://www.bilibili.com/", forHTTPHeaderField: "Referer")
    request.setValue("*/*", forHTTPHeaderField: "Accept")
    if !cookie.isEmpty { request.setValue(cookie, forHTTPHeaderField: "Cookie") }
    if downloaded > 0 { request.setValue("bytes=\(downloaded)-", forHTTPHeaderField: "Range") }
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 60
    config.timeoutIntervalForResource = 600
    let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    self.session = session
    session.dataTask(with: request).resume()
  }

  func cancel() {
    cancelled = true
    session?.invalidateAndCancel()
    session = nil
    try? handle?.close()
    handle = nil
  }

  func urlSession(
    _ session: URLSession,
    dataTask: URLSessionDataTask,
    didReceive response: URLResponse,
    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
  ) {
    guard let http = response as? HTTPURLResponse else {
      completionHandler(.cancel)
      return
    }
    if http.statusCode == 403 || http.statusCode == 567 || http.statusCode >= 500 {
      completionHandler(.cancel)
      return
    }
    if http.statusCode == 200 && downloaded > 0 {
      downloaded = 0
      try? FileManager.default.removeItem(at: part)
    }
    let expected = http.expectedContentLength
    if expected > 0 {
      total = http.statusCode == 206 ? downloaded + expected : expected
    }
    if !FileManager.default.fileExists(atPath: part.path) {
      FileManager.default.createFile(atPath: part.path, contents: nil)
    }
    handle = try? FileHandle(forWritingTo: part)
    if downloaded > 0 { try? handle?.seekToEnd() }
    onProgress(downloaded, total)
    completionHandler(.allow)
  }

  func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
    if cancelled { return }
    handle?.write(data)
    downloaded += Int64(data.count)
    if Date().timeIntervalSince(lastProgress) > 0.6 {
      lastProgress = Date()
      onProgress(downloaded, total)
    }
  }

  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    try? handle?.close()
    handle = nil
    session.finishTasksAndInvalidate()
    self.session = nil
    if cancelled {
      onFinish(nil)
      return
    }
    if let error = error {
      if urlIndex + 1 < urls.count {
        urlIndex += 1
        start()
        return
      }
      onFinish(error)
      return
    }
    onProgress(downloaded, total)
    onFinish(nil)
  }
}
