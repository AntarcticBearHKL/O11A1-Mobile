import Foundation

/// Minimal Bilibili live danmaku WebSocket client (JSON protocol).
final class LiveChatSocket {
  var onMessage: ((String, String) -> Void)?

  private var session: URLSession?
  private var task: URLSessionWebSocketTask?
  private var heartbeat: Timer?
  private var closed = false
  private var attempts = 0
  private var roomId: Int64 = 0
  private var token = ""
  private var host = ""
  private var port = 443

  private static let userAgent =
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
    + " (KHTML, like Gecko) Chrome/124.0 Safari/537.36"

  func connect(roomId: Int64, token: String, host: String, port: Int) {
    self.roomId = roomId
    self.token = token
    self.host = host
    self.port = port <= 0 ? 443 : port
    closed = false
    attempts += 1
    open()
  }

  private func open() {
    guard !closed, !host.isEmpty else { return }
    if session == nil {
      let configuration = URLSessionConfiguration.default
      configuration.timeoutIntervalForRequest = 15
      session = URLSession(configuration: configuration)
    }
    var components = URLComponents()
    components.scheme = "wss"
    components.host = host
    components.port = port
    components.path = "/sub"
    guard let url = components.url else { return }
    var request = URLRequest(url: url)
    request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
    request.setValue("https://live.bilibili.com", forHTTPHeaderField: "Origin")
    request.setValue("https://live.bilibili.com/\(roomId)", forHTTPHeaderField: "Referer")
    guard let session = session else { return }
    NSLog("[O11A1] live chat open %@", url.absoluteString)
    let task = session.webSocketTask(with: request)
    self.task = task
    task.resume()
    sendAuth()
    scheduleHeartbeat()
    receive()
  }

  private func sendAuth() {
    let payload: [String: Any] = [
      "uid": 0,
      "roomid": roomId,
      "protover": 2,
      "platform": "web",
      "type": 2,
      "key": token,
    ]
    guard let body = try? JSONSerialization.data(withJSONObject: payload) else { return }
    send(operation: 7, body: body)
  }

  private func scheduleHeartbeat() {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      self.heartbeat?.invalidate()
      self.heartbeat = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
        self?.send(operation: 2, body: Data())
      }
    }
  }

  private func send(operation: Int, body: Data) {
    guard !closed, let task = task else { return }
    var packet = Data()
    appendUInt32(&packet, UInt32(16 + body.count))
    appendUInt16(&packet, 16)
    appendUInt16(&packet, 1)
    appendUInt32(&packet, UInt32(operation))
    appendUInt32(&packet, 1)
    packet.append(body)
    task.send(.data(packet)) { _ in }
  }

  private func appendUInt32(_ data: inout Data, _ value: UInt32) {
    var big = value.bigEndian
    withUnsafeBytes(of: &big) { data.append(contentsOf: $0) }
  }

  private func appendUInt16(_ data: inout Data, _ value: UInt16) {
    var big = value.bigEndian
    withUnsafeBytes(of: &big) { data.append(contentsOf: $0) }
  }

  private func receive() {
    task?.receive { [weak self] result in
      guard let self = self, !self.closed else { return }
      switch result {
      case .failure:
        self.retry()
      case .success(let message):
        switch message {
        case .data(let data):
          self.parse([UInt8](data))
        case .string(let text):
          self.parse([UInt8](text.utf8))
        @unknown default:
          break
        }
        self.receive()
      }
    }
  }

  private func retry() {
    guard !closed, attempts < 4 else {
      DispatchQueue.main.async { [weak self] in self?.heartbeat?.invalidate() }
      return
    }
    attempts += 1
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
      guard let self = self, !self.closed else { return }
      self.open()
    }
  }

  private func parse(_ bytes: [UInt8]) {
    parsePackets(bytes)
  }

  private func parsePackets(_ bytes: [UInt8]) {
    var offset = 0
    while offset + 16 <= bytes.count {
      let total = Int(readUInt32(bytes, offset))
      let headerLength = Int(readUInt16(bytes, offset + 4))
      let version = Int(readUInt16(bytes, offset + 6))
      let operation = Int(readUInt32(bytes, offset + 8))
      guard total > 0, headerLength >= 16, offset + total <= bytes.count else { return }
      let bodyStart = offset + headerLength
      let body = Array(bytes[bodyStart..<(offset + total)])
      if operation == 5 {
        if version == 2 {
          if let inflated = inflate(body) {
            parsePackets(inflated)
          } else {
            NSLog("[O11A1] live chat inflate failed")
          }
        } else if version == 0 || version == 1 {
          handleJSON(body)
        }
      }
      offset += total
    }
  }

  private func readUInt32(_ bytes: [UInt8], _ offset: Int) -> UInt32 {
    guard offset + 4 <= bytes.count else { return 0 }
    return (UInt32(bytes[offset]) << 24)
      | (UInt32(bytes[offset + 1]) << 16)
      | (UInt32(bytes[offset + 2]) << 8)
      | UInt32(bytes[offset + 3])
  }

  private func readUInt16(_ bytes: [UInt8], _ offset: Int) -> UInt16 {
    guard offset + 2 <= bytes.count else { return 0 }
    return (UInt16(bytes[offset]) << 8) | UInt16(bytes[offset + 1])
  }

  private func inflate(_ bytes: [UInt8]) -> [UInt8]? {
    let data = Data(bytes)
    guard let decompressed = try? (data as NSData).decompressed(using: .zlib) else {
      return nil
    }
    return [UInt8](decompressed as Data)
  }

  private func handleJSON(_ bytes: [UInt8]) {
    guard let object = try? JSONSerialization.jsonObject(with: Data(bytes)) as? [String: Any],
          let cmd = object["cmd"] as? String,
          cmd.hasPrefix("DANMU_MSG"),
          let info = object["info"] as? [Any],
          info.count > 2 else {
      return
    }
    let text = (info[1] as? String) ?? ""
    guard !text.isEmpty else { return }
    var user = ""
    if let userInfo = info[2] as? [Any], userInfo.count > 1 {
      user = (userInfo[1] as? String) ?? ""
    }
    if user.isEmpty { user = "观众" }
    let name = user
    NSLog("[O11A1] live dm %@: %@", name, text)
    DispatchQueue.main.async { [weak self] in
      guard let self = self, !self.closed else { return }
      self.onMessage?(name, text)
    }
  }

  func close() {
    closed = true
    DispatchQueue.main.async { [weak self] in
      self?.heartbeat?.invalidate()
      self?.heartbeat = nil
    }
    task?.cancel(with: .goingAway, reason: nil)
    task = nil
    session?.invalidateAndCancel()
    session = nil
    onMessage = nil
  }

  deinit {
    heartbeat?.invalidate()
    task?.cancel(with: .goingAway, reason: nil)
    session?.invalidateAndCancel()
  }
}
