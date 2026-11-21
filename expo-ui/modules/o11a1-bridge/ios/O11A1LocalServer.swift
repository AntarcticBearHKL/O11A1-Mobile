import Foundation
import Network
import UIKit

final class O11A1LocalServer {
  private static let mediaChunkSize: Int64 = 8 * 1024 * 1024

  private let files: [String: String]
  private let client = O11A1BiliClient()
  private let listener: NWListener
  private let queue = DispatchQueue(label: "o11a1.local-server", qos: .userInitiated)
  private let lock = NSLock()
  private var active: [ObjectIdentifier: NWConnection] = [:]

  private(set) var port: Int = 0

  init(files: [String: String]) throws {
    self.files = files
    let parameters = NWParameters.tcp
    parameters.allowLocalEndpointReuse = true
    parameters.requiredLocalEndpoint = NWEndpoint.hostPort(host: "127.0.0.1", port: .any)
    self.listener = try NWListener(using: parameters)
  }

  func start() throws {
    let semaphore = DispatchSemaphore(value: 0)
    let failure = O11A1Box<Error>()
    listener.stateUpdateHandler = { [weak self] state in
      guard let self = self else { return }
      switch state {
      case .ready:
        self.port = Int(self.listener.port?.rawValue ?? 0)
        self.client.port = self.port
        semaphore.signal()
      case .failed(let error):
        failure.value = error
        semaphore.signal()
      default:
        break
      }
    }
    listener.newConnectionHandler = { [weak self] connection in
      self?.accept(connection)
    }
    listener.start(queue: queue)
    if semaphore.wait(timeout: .now() + 8) == .timedOut {
      listener.cancel()
      throw NSError(
        domain: "O11A1Bridge",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "local server start timed out"]
      )
    }
    if let error = failure.value {
      listener.cancel()
      throw error
    }
    if port <= 0 {
      throw NSError(
        domain: "O11A1Bridge",
        code: 2,
        userInfo: [NSLocalizedDescriptionKey: "local server has no port"]
      )
    }
  }

  /* ---------- connection lifecycle ---------- */

  private func accept(_ connection: NWConnection) {
    lock.lock()
    active[ObjectIdentifier(connection)] = connection
    lock.unlock()
    connection.stateUpdateHandler = { [weak self, weak connection] state in
      guard let connection = connection else { return }
      switch state {
      case .failed, .cancelled:
        self?.forget(connection)
      default:
        break
      }
    }
    connection.start(queue: queue)
    receive(connection, buffer: Data())
  }

  private func forget(_ connection: NWConnection) {
    lock.lock()
    active.removeValue(forKey: ObjectIdentifier(connection))
    lock.unlock()
  }

  private func finish(_ connection: NWConnection) {
    forget(connection)
    connection.cancel()
  }

  private func receive(_ connection: NWConnection, buffer: Data) {
    connection.receive(minimumIncompleteLength: 1, maximumLength: 64 * 1024) { [weak self] data, _, complete, error in
      guard let self = self else {
        connection.cancel()
        return
      }
      var accumulated = buffer
      if let data = data, !data.isEmpty { accumulated.append(data) }
      if let headerRange = accumulated.range(of: Data("\r\n\r\n".utf8)) {
        let header = accumulated.subdata(in: 0..<headerRange.lowerBound)
        self.route(header, connection: connection)
        return
      }
      if error != nil || complete || accumulated.count > 256 * 1024 {
        self.finish(connection)
        return
      }
      self.receive(connection, buffer: accumulated)
    }
  }

  private func route(_ header: Data, connection: NWConnection) {
    guard let text = String(data: header, encoding: .utf8) else {
      finish(connection)
      return
    }
    let lines = text.components(separatedBy: "\r\n")
    guard let first = lines.first else {
      finish(connection)
      return
    }
    let parts = first.split(separator: " ")
    guard parts.count >= 2 else {
      sendText(connection, status: 400, text: "bad request")
      return
    }
    let method = String(parts[0]).uppercased()
    let target = String(parts[1])
    var headers: [String: String] = [:]
    for line in lines.dropFirst() {
      guard let colon = line.firstIndex(of: ":") else { continue }
      let name = String(line[..<colon]).trimmingCharacters(in: .whitespaces).lowercased()
      let value = String(line[line.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
      headers[name] = value
    }
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      guard let self = self else {
        connection.cancel()
        return
      }
      self.handle(method: method, target: target, headers: headers, connection: connection)
    }
  }

  /* ---------- routing ---------- */

  private func handle(
    method: String,
    target: String,
    headers: [String: String],
    connection: NWConnection
  ) {
    if method == "OPTIONS" {
      send(
        connection,
        status: 204,
        headers: [
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Headers": "*",
          "Access-Control-Allow-Methods": "GET, HEAD, OPTIONS"
        ],
        body: Data(),
        headOnly: true
      )
      return
    }
    guard method == "GET" || method == "HEAD" else {
      sendText(connection, status: 405, text: "method not allowed")
      return
    }
    let absolute = target.hasPrefix("http://") || target.hasPrefix("https://")
      ? target
      : "http://127.0.0.1\(target)"
    guard let components = URLComponents(string: absolute) else {
      sendText(connection, status: 400, text: "bad url")
      return
    }
    let path = components.path
    var query: [String: String] = [:]
    for item in components.queryItems ?? [] { query[item.name] = item.value ?? "" }

    if path == "/" || path == "/index.html" {
      serveFile("index.html", method: method, connection: connection)
      return
    }
    if path == "/favicon.ico" {
      send(connection, status: 204, headers: [:], body: Data(), headOnly: true)
      return
    }
    let resource = String(path.dropFirst())
    if files[resource] != nil {
      serveFile(resource, method: method, connection: connection)
      return
    }
    if path == "/media" {
      handleMedia(query: query, headers: headers, method: method, connection: connection)
      return
    }
    if path.hasPrefix("/api/") {
      handleAPI(name: String(path.dropFirst(5)), query: query, method: method, connection: connection)
      return
    }
    sendText(connection, status: 404, text: "not found")
  }

  private func serveFile(_ name: String, method: String, connection: NWConnection) {
    guard let content = files[name] else {
      sendText(connection, status: 404, text: "not found")
      return
    }
    let type: String
    switch (name as NSString).pathExtension.lowercased() {
    case "html": type = "text/html; charset=utf-8"
    case "js": type = "application/javascript; charset=utf-8"
    case "css": type = "text/css; charset=utf-8"
    case "json": type = "application/json; charset=utf-8"
    default: type = "application/octet-stream"
    }
    send(
      connection,
      status: 200,
      headers: ["Content-Type": type, "Cache-Control": "no-store"],
      body: Data(content.utf8),
      headOnly: method == "HEAD"
    )
  }

  private func handleAPI(
    name: String,
    query: [String: String],
    method: String,
    connection: NWConnection
  ) {
    let data: Data
    switch name {
    case "popular":
      data = client.popular(
        page: max(1, o11a1Int(query["page"] ?? "1")),
        ps: max(1, o11a1Int(query["ps"] ?? "20"))
      )
    case "search":
      data = client.search(
        keyword: query["keyword"] ?? "",
        page: max(1, o11a1Int(query["page"] ?? "1"))
      )
    case "play":
      data = client.play(
        bvid: query["bvid"] ?? "",
        cid: o11a1Int64(query["cid"] ?? "0"),
        qns: [64, 32, 16]
      )
    case "playLow":
      data = client.playLow(
        bvid: query["bvid"] ?? "",
        cid: o11a1Int64(query["cid"] ?? "0")
      )
    case "playQuality":
      data = client.playQuality(
        bvid: query["bvid"] ?? "",
        cid: o11a1Int64(query["cid"] ?? "0"),
        qn: o11a1Int(query["qn"] ?? "64")
      )
    case "comments":
      data = client.comments(
        aid: o11a1Int64(query["aid"] ?? "0"),
        page: max(1, o11a1Int(query["page"] ?? "1"))
      )
    case "danmaku":
      data = client.danmaku(cid: o11a1Int64(query["cid"] ?? "0"))
    case "session":
      data = client.session()
    case "logout":
      data = client.logout()
    case "qrGenerate":
      data = client.qrGenerate()
    case "qrPoll":
      data = client.qrPoll(key: query["key"] ?? "")
    case "setBrightness":
      let value = Double(query["v"] ?? "50") ?? 50
      DispatchQueue.main.async {
        UIScreen.main.brightness = CGFloat(max(0.02, min(1.0, value / 100.0)))
      }
      data = o11a1Data(["ok": true])
    case "setOrientation":
      let mode = query["mode"] ?? "sensor"
      DispatchQueue.main.async {
        O11A1Orientation.apply(mode)
      }
      data = o11a1Data(["ok": true])
    case "log":
      print("[O11A1] \(query["message"] ?? "")")
      data = o11a1Data(["ok": true])
    case "proxyInfo":
      data = client.proxyInfo()
    default:
      data = o11a1Error("unknown api")
    }
    send(
      connection,
      status: 200,
      headers: [
        "Content-Type": "application/json; charset=utf-8",
        "Cache-Control": "no-store",
        "Access-Control-Allow-Origin": "*"
      ],
      body: data,
      headOnly: method == "HEAD"
    )
  }

  private func handleMedia(
    query: [String: String],
    headers: [String: String],
    method: String,
    connection: NWConnection
  ) {
    guard let token = query["u"],
          let decoded = o11a1Base64URLDecode(token) else {
      sendText(connection, status: 400, text: "missing media token")
      return
    }
    var urls: [String] = []
    if let object = try? JSONSerialization.jsonObject(with: decoded),
       let list = object as? [String] {
      urls = list
    } else if let single = String(data: decoded, encoding: .utf8) {
      urls = [single]
    }
    urls = urls.filter { $0.hasPrefix("http://") || $0.hasPrefix("https://") }
    guard !urls.isEmpty else {
      sendText(connection, status: 400, text: "bad media url")
      return
    }

    var start: Int64 = 0
    var end = Self.mediaChunkSize - 1
    if let range = headers["range"]?.lowercased(), range.hasPrefix("bytes=") {
      let spec = range.dropFirst("bytes=".count)
      let pieces = spec.split(separator: "-", maxSplits: 1, omittingEmptySubsequences: false)
      let firstPiece = pieces.first.map { String($0) } ?? "0"
      start = Int64(firstPiece) ?? 0
      if pieces.count > 1, let value = Int64(String(pieces[1])) { end = value }
      if end < start { end = start + Self.mediaChunkSize - 1 }
      if end - start + 1 > Self.mediaChunkSize { end = start + Self.mediaChunkSize - 1 }
    }

    for url in urls {
      guard let chunk = client.fetchMedia(urlString: url, start: start, end: end) else { continue }
      let actualEnd = start + Int64(chunk.data.count) - 1
      send(
        connection,
        status: 206,
        headers: [
          "Content-Type": "video/mp4",
          "Accept-Ranges": "bytes",
          "Content-Range": "bytes \(start)-\(actualEnd)/\(chunk.total)",
          "Content-Length": "\(chunk.data.count)",
          "Cache-Control": "no-store",
          "Access-Control-Allow-Origin": "*"
        ],
        body: chunk.data,
        headOnly: method == "HEAD"
      )
      return
    }
    sendText(connection, status: 502, text: "media unavailable")
  }

  /* ---------- response helpers ---------- */

  private func sendText(_ connection: NWConnection, status: Int, text: String) {
    send(
      connection,
      status: status,
      headers: ["Content-Type": "text/plain; charset=utf-8"],
      body: Data(text.utf8),
      headOnly: false
    )
  }

  private func send(
    connection: NWConnection,
    status: Int,
    headers: [String: String],
    body: Data,
    headOnly: Bool
  ) {
    var merged = headers
    if merged["Content-Length"] == nil { merged["Content-Length"] = "\(body.count)" }
    merged["Connection"] = "close"
    var head = "HTTP/1.1 \(status) \(reason(status))\r\n"
    for (name, value) in merged { head += "\(name): \(value)\r\n" }
    head += "\r\n"
    var payload = Data(head.utf8)
    if !headOnly { payload.append(body) }
    connection.send(content: payload, completion: .contentProcessed { [weak self] _ in
      self?.finish(connection)
    })
  }

  private func reason(_ status: Int) -> String {
    switch status {
    case 200: return "OK"
    case 204: return "No Content"
    case 206: return "Partial Content"
    case 400: return "Bad Request"
    case 403: return "Forbidden"
    case 404: return "Not Found"
    case 405: return "Method Not Allowed"
    case 500: return "Internal Server Error"
    case 502: return "Bad Gateway"
    default: return "OK"
    }
  }
}
