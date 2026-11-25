import AVFAudio
import Foundation
import MediaPlayer
import Network
import UIKit

final class O11A1LocalServer {
  private let files: [String: String]
  private let client = O11A1BiliClient()
  private var listener: NWListener
  private let queue = DispatchQueue(label: "o11a1.local-server", qos: .userInitiated)
  private let lock = NSLock()
  private let smsLock = NSLock()
  private var smsBusy = false
  private var active: [ObjectIdentifier: NWConnection] = [:]
  private var previewCache: [String: (data: Data, at: Date)] = [:]
  private let previewQueue = DispatchQueue(label: "o11a1.preview", qos: .utility, attributes: .concurrent)
  private var dashCache: [String: (data: Data, at: Date)] = [:]
  private var qualityCache: [String: (data: Data, at: Date)] = [:]
  private var suggestCache: [String: (data: Data, at: Date)] = [:]
  private var danmakuCache: [String: (data: Data, at: Date)] = [:]
  private var savedBrightness: CGFloat?
  private lazy var volumeView: MPVolumeView = {
    let view = MPVolumeView(frame: CGRect(x: -1000, y: -1000, width: 1, height: 1))
    view.showsRouteButton = false
    view.alpha = 0.01
    return view
  }()

  private(set) var port: Int = 0

  init(files: [String: String]) throws {
    self.files = files
    let parameters = NWParameters.tcp
    parameters.allowLocalEndpointReuse = true
    // WKWebView keys localStorage by origin, including the port. A random
    // port reset every app launch and silently wiped all settings. Bind a
    // stable loopback port (with a couple of fallbacks) so the origin is
    // stable across relaunches.
    var selected: NWListener?
    var lastError: Error?
    for candidate: UInt16 in [47821, 47822, 47823, 47824, 0] {
      parameters.requiredLocalEndpoint = NWEndpoint.hostPort(
        host: "127.0.0.1",
        port: candidate == 0 ? .any : NWEndpoint.Port(rawValue: candidate)!
      )
      do {
        selected = try NWListener(using: parameters)
        break
      } catch {
        lastError = error
      }
    }
    guard let listener = selected else {
      throw lastError ?? NSError(
        domain: "O11A1Bridge",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "local server port unavailable"]
      )
    }
    self.listener = listener
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

  private func volumeSlider(in view: UIView) -> UISlider? {
    if let slider = view as? UISlider { return slider }
    for child in view.subviews {
      if let slider = volumeSlider(in: child) { return slider }
    }
    return nil
  }

  private func setSystemVolume(_ percent: Int) {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      try? AVAudioSession.sharedInstance().setActive(true)
      if self.volumeView.superview == nil {
        let window = UIApplication.shared.connectedScenes
          .compactMap { $0 as? UIWindowScene }
          .flatMap { $0.windows }
          .first { $0.isKeyWindow }
        window?.addSubview(self.volumeView)
        self.volumeView.layoutIfNeeded()
      }
      guard let slider = self.volumeSlider(in: self.volumeView) else { return }
      slider.value = Float(max(0, min(100, percent))) / 100
      slider.sendActions(for: .valueChanged)
      slider.sendActions(for: .touchUpInside)
    }
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
    case "recommend":
      data = client.recommend(
        page: max(1, o11a1Int(query["page"] ?? "1")),
        ps: max(1, o11a1Int(query["ps"] ?? "20")),
        fresh: max(1, o11a1Int(query["fresh"] ?? "1"))
      )
    case "search":
      data = client.search(
        keyword: query["keyword"] ?? "",
        page: max(1, o11a1Int(query["page"] ?? "1"))
      )
    case "suggest":
      let term = (query["term"] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
      let key = term.lowercased()
      lock.lock()
      let hit = suggestCache[key]
      lock.unlock()
      if let hit = hit, Date().timeIntervalSince(hit.at) < 300 {
        data = hit.data
      } else {
        let fetched = client.suggest(term: term)
        lock.lock()
        suggestCache[key] = (data: fetched, at: Date())
        if suggestCache.count > 80 {
          let cutoff = Date().addingTimeInterval(-300)
          suggestCache = suggestCache.filter { $0.value.at > cutoff }
        }
        lock.unlock()
        data = fetched
      }
    case "play":
      data = client.play(
        bvid: query["bvid"] ?? "",
        cid: o11a1Int64(query["cid"] ?? "0"),
        qns: [64, 32, 16]
      )
    case "prewarm":
      if let raw = query["items"], let encoded = raw.data(using: .utf8),
         let object = try? JSONSerialization.jsonObject(with: encoded),
         let list = object as? [[String: Any]] {
        for row in list {
          let bvid = o11a1String(row["bvid"])
          let cid = o11a1Int64(row["cid"])
          guard !bvid.isEmpty else { continue }
          previewQueue.async { [weak self] in
            guard let self = self else { return }
            let key = "\(bvid):\(cid)"
            self.lock.lock()
            let cached = self.previewCache[key]
            self.lock.unlock()
            if let cached = cached, Date().timeIntervalSince(cached.at) < 600 { return }
            let result = self.client.playLow(bvid: bvid, cid: cid)
            self.lock.lock()
            self.previewCache[key] = (data: result, at: Date())
            if self.previewCache.count > 80 {
              let cutoff = Date().addingTimeInterval(-600)
              self.previewCache = self.previewCache.filter { $0.value.at >= cutoff }
            }
            self.lock.unlock()
          }
        }
      }
      data = o11a1Data(["ok": true])
    case "previewCached":
      let cachedBvid = query["bvid"] ?? ""
      let cachedCid = o11a1Int64(query["cid"] ?? "0")
      let cachedKey = "\(cachedBvid):\(cachedCid)"
      lock.lock()
      let cachedEntry = previewCache[cachedKey]
      lock.unlock()
      if let cachedEntry = cachedEntry, Date().timeIntervalSince(cachedEntry.at) < 600 {
        data = cachedEntry.data
      } else {
        data = o11a1Data(["ok": false, "missing": true])
      }
    case "playLow":
      let lowBvid = query["bvid"] ?? ""
      let lowCid = o11a1Int64(query["cid"] ?? "0")
      let lowKey = "\(lowBvid):\(lowCid)"
      lock.lock()
      let lowCached = previewCache[lowKey]
      lock.unlock()
      if let lowCached = lowCached, Date().timeIntervalSince(lowCached.at) < 600 {
        data = lowCached.data
      } else {
        let fetched = client.playLow(bvid: lowBvid, cid: lowCid)
        lock.lock()
        previewCache[lowKey] = (data: fetched, at: Date())
        lock.unlock()
        data = fetched
      }
    case "playQuality":
      let qualityBvid = query["bvid"] ?? ""
      let qualityCid = o11a1Int64(query["cid"] ?? "0")
      let qualityQn = o11a1Int(query["qn"] ?? "64")
      let qualityKey = "\(qualityBvid):\(qualityCid):\(qualityQn)"
      lock.lock()
      let qualityHit = qualityCache[qualityKey]
      lock.unlock()
      if let qualityHit = qualityHit, Date().timeIntervalSince(qualityHit.at) < 240 {
        data = qualityHit.data
      } else {
        let fetched = client.playQuality(bvid: qualityBvid, cid: qualityCid, qn: qualityQn)
        lock.lock()
        qualityCache[qualityKey] = (data: fetched, at: Date())
        lock.unlock()
        data = fetched
      }
    case "prewarmQuality":
      let warmBvid = query["bvid"] ?? ""
      let warmCid = o11a1Int64(query["cid"] ?? "0")
      let warmQn = o11a1Int(query["qn"] ?? "64")
      let warmKey = "\(warmBvid):\(warmCid):\(warmQn)"
      DispatchQueue.global(qos: .userInitiated).async { [weak self] in
        guard let self = self, !warmBvid.isEmpty else { return }
        self.lock.lock()
        let cached = self.qualityCache[warmKey]
        self.lock.unlock()
        if let cached = cached, Date().timeIntervalSince(cached.at) < 240 { return }
        let fetched = self.client.playQuality(bvid: warmBvid, cid: warmCid, qn: warmQn)
        self.lock.lock()
        self.qualityCache[warmKey] = (data: fetched, at: Date())
        self.lock.unlock()
      }
      data = o11a1Data(["ok": true])
    case "comments":
      data = client.comments(
        aid: o11a1Int64(query["aid"] ?? "0"),
        page: max(1, o11a1Int(query["page"] ?? "1")),
        sort: o11a1Int(query["sort"] ?? "2")
      )
    case "commentsReplies":
      data = client.commentsReplies(
        aid: o11a1Int64(query["aid"] ?? "0"),
        root: o11a1Int64(query["root"] ?? "0"),
        page: max(1, o11a1Int(query["page"] ?? "1"))
      )
    case "memberCenter":
      data = client.memberCenter()
    case "aiChat":
      data = client.aiChat(
        endpoint: query["endpoint"] ?? "",
        apiKey: query["apiKey"] ?? "",
        model: query["model"] ?? "",
        prompt: query["prompt"] ?? ""
      )
    case "dash":
      let dashBvid = query["bvid"] ?? ""
      let dashCid = o11a1Int64(query["cid"] ?? "0")
      let dashQn = o11a1Int(query["qn"] ?? "120")
      let dashKey = "\(dashBvid):\(dashCid):\(dashQn)"
      lock.lock()
      let dashHit = dashCache[dashKey]
      lock.unlock()
      if let dashHit = dashHit, Date().timeIntervalSince(dashHit.at) < 240 {
        data = dashHit.data
      } else {
        let fetched = client.dash(bvid: dashBvid, cid: dashCid, qn: dashQn)
        lock.lock()
        dashCache[dashKey] = (data: fetched, at: Date())
        lock.unlock()
        data = fetched
      }
    case "prewarmDash":
      let warmBvid = query["bvid"] ?? ""
      let warmCid = o11a1Int64(query["cid"] ?? "0")
      let warmQn = o11a1Int(query["qn"] ?? "120")
      let warmKey = "\(warmBvid):\(warmCid):\(warmQn)"
      DispatchQueue.global(qos: .userInitiated).async { [weak self] in
        guard let self = self, !warmBvid.isEmpty else { return }
        self.lock.lock()
        let cached = self.dashCache[warmKey]
        self.lock.unlock()
        if let cached = cached, Date().timeIntervalSince(cached.at) < 240 { return }
        let fetched = self.client.dash(bvid: warmBvid, cid: warmCid, qn: warmQn)
        self.lock.lock()
        self.dashCache[warmKey] = (data: fetched, at: Date())
        self.lock.unlock()
      }
      data = o11a1Data(["ok": true])
    case "mediaStats":
      data = o11a1Data(O11A1PlayerHost.shared.stats(slot: query["slot"] ?? "main"))
    case "displayHz":
      data = o11a1Data([
        "ok": true,
        "hz": O11A1HighRefresh.shared.maxHz(),
        "fps": O11A1HighRefresh.shared.compositorFps()
      ])
    case "danmaku":
      let cid = o11a1Int64(query["cid"] ?? "0")
      let key = String(cid)
      lock.lock()
      let hit = danmakuCache[key]
      lock.unlock()
      if let hit = hit, Date().timeIntervalSince(hit.at) < 600 {
        data = hit.data
      } else {
        let fetched = client.danmaku(cid: cid)
        lock.lock()
        danmakuCache[key] = (data: fetched, at: Date())
        if danmakuCache.count > 80 {
          let cutoff = Date().addingTimeInterval(-600)
          danmakuCache = danmakuCache.filter { $0.value.at > cutoff }
        }
        lock.unlock()
        data = fetched
      }
    case "account":
      data = client.account()
    case "favorites":
      data = client.favorites(page: max(1, o11a1Int(query["page"] ?? "1")))
    case "history":
      data = client.history(
        page: max(1, o11a1Int(query["page"] ?? "1")),
        cursor: query["cursor"] ?? ""
      )
    case "following":
      data = client.following(page: max(1, o11a1Int(query["page"] ?? "1")))
    case "dynamicFeed":
      data = client.dynamicFeed(
        page: max(1, o11a1Int(query["page"] ?? "1")),
        filter: query["filter"] ?? "all"
      )
    case "messages":
      data = client.messages(
        page: max(1, o11a1Int(query["page"] ?? "1")),
        filter: query["filter"] ?? "reply"
      )
    case "ranking":
      data = client.ranking(page: max(1, o11a1Int(query["page"] ?? "1")))
    case "bangumi":
      data = client.bangumi(
        page: max(1, o11a1Int(query["page"] ?? "1")),
        seasonType: o11a1Int(query["type"] ?? "1")
      )
    case "season":
      data = client.season(seasonId: o11a1Int64(query["seasonId"] ?? "0"))
    case "playPgc":
      data = client.playPgc(
        epId: o11a1Int64(query["epId"] ?? "0"),
        bvid: query["bvid"] ?? "",
        cid: o11a1Int64(query["cid"] ?? "0"),
        qn: o11a1Int(query["qn"] ?? "64")
      )
    case "live":
      data = client.live(page: max(1, o11a1Int(query["page"] ?? "1")))
    case "liveRoom":
      data = client.liveRoom(roomId: o11a1Int64(query["roomId"] ?? "0"))
    case "liveDanmuInfo":
      data = client.liveDanmuInfo(roomId: o11a1Int64(query["roomId"] ?? "0"))
    case "zone":
      data = client.zone(
        rid: o11a1Int(query["rid"] ?? "1"),
        page: max(1, o11a1Int(query["page"] ?? "1"))
      )
    case "space":
      data = client.space(
        mid: o11a1Int64(query["mid"] ?? "0"),
        page: max(1, o11a1Int(query["page"] ?? "1")),
        order: query["order"] ?? "pubdate"
      )
    case "videoInfo":
      data = client.videoInfo(bvid: query["bvid"] ?? "")
    case "related":
      data = client.related(bvid: query["bvid"] ?? "")
    case "like":
      data = client.like(
        aid: o11a1Int64(query["aid"] ?? "0"),
        on: (query["on"] ?? "0") == "1"
      )
    case "coin":
      data = client.coin(
        aid: o11a1Int64(query["aid"] ?? "0"),
        count: o11a1Int(query["count"] ?? "2"),
        likeAlso: (query["likeAlso"] ?? "0") == "1"
      )
    case "favorite":
      data = client.favorite(
        aid: o11a1Int64(query["aid"] ?? "0"),
        on: (query["on"] ?? "0") == "1"
      )
    case "follow":
      data = client.follow(
        mid: o11a1Int64(query["mid"] ?? "0"),
        on: (query["on"] ?? "0") == "1"
      )
    case "sendComment":
      data = client.sendComment(
        aid: o11a1Int64(query["aid"] ?? "0"),
        message: query["message"] ?? ""
      )
    case "sendDanmaku":
      data = client.sendDanmaku(
        cid: o11a1Int64(query["cid"] ?? "0"),
        message: query["message"] ?? "",
        progressMs: o11a1Int64(query["progress"] ?? "0")
      )
    case "copy":
      let text = query["text"] ?? ""
      DispatchQueue.main.async {
        UIPasteboard.general.string = text
      }
      data = o11a1Data(["ok": true])
    case "screenshot":
      data = captureScreenshot()
    case "session":
      data = client.session()
    case "logout":
      DispatchQueue.main.async {
        O11A1WebLogin.clearBilibiliCookies()
      }
      data = client.logout()
    case "brightness":
      var percent = 100
      let read = { percent = Int(round(UIScreen.main.brightness * 100)) }
      if Thread.isMainThread { read() } else { DispatchQueue.main.sync(execute: read) }
      data = o11a1Data(["ok": true, "v": percent])
    case "setBrightness":
      let value = Double(query["v"] ?? "50") ?? 50
      DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }
        if self.savedBrightness == nil { self.savedBrightness = UIScreen.main.brightness }
        UIScreen.main.brightness = CGFloat(max(0.02, min(1.0, value / 100.0)))
      }
      data = o11a1Data(["ok": true])
    case "restoreBrightness":
      DispatchQueue.main.async { [weak self] in
        guard let self = self, let value = self.savedBrightness else { return }
        UIScreen.main.brightness = value
        self.savedBrightness = nil
      }
      data = o11a1Data(["ok": true])
    case "volume":
      try? AVAudioSession.sharedInstance().setActive(true)
      data = o11a1Data(["ok": true, "v": Int(round(AVAudioSession.sharedInstance().outputVolume * 100))])
    case "setVolume":
      let value = Int(Double(query["v"] ?? "50") ?? 50)
      setSystemVolume(value)
      data = o11a1Data(["ok": true, "v": value])
    case "webLogin":
      data = o11a1Error("网页登录已停用，请使用短信登录")
    case "smsSendCode":
      let tel = query["tel"] ?? ""
      let cid = query["cid"] ?? "86"
      if tel.range(of: "^\\d{5,20}$", options: .regularExpression) == nil {
        data = o11a1Error("请输入正确的手机号")
        break
      }
      smsLock.lock()
      let busy = smsBusy
      if !busy { smsBusy = true }
      smsLock.unlock()
      if busy {
        data = o11a1Data(["ok": true, "pending": true, "error": "正在验证，请稍候"])
        break
      }
      data = o11a1Data(["ok": true, "pending": true])
      let smsClient = client
      DispatchQueue.global(qos: .userInitiated).async { [weak self] in
        var result: [String: Any] = ["ok": false, "error": "短信发送失败"]
        let captcha = smsClient.loginCaptcha()
        if captcha["ok"] as? Bool != true {
          result = captcha
        } else {
          let challenge = O11A1Geetest.present(
            gt: o11a1String(captcha["gt"]),
            challenge: o11a1String(captcha["challenge"])
          )
          if challenge["ok"] as? Bool != true {
            result = challenge
          } else {
            result = smsClient.smsSend(
              tel: tel,
              cid: cid,
              token: o11a1String(captcha["token"]),
              challenge: o11a1String(captcha["challenge"]),
              validate: o11a1String(challenge["validate"]),
              seccode: o11a1String(challenge["seccode"])
            )
          }
        }
        result["tel"] = tel
        result["cid"] = cid
        guard let self = self else { return }
        self.smsLock.lock()
        self.smsBusy = false
        self.smsLock.unlock()
        self.deliverSmsResult(result)
      }
    case "smsLogin":
      data = client.smsLogin(
        tel: query["tel"] ?? "",
        cid: query["cid"] ?? "86",
        code: query["code"] ?? "",
        captchaKey: query["captchaKey"] ?? ""
      )
    case "nativePlayerLoad":
      let slot = query["slot"] ?? "main"
      let raw = query["json"] ?? "{}"
      var payload = (try? JSONSerialization.jsonObject(with: Data(raw.utf8))) as? [String: Any] ?? [:]
      payload["headers"] = client.mediaHeaders()
      O11A1PlayerHost.shared.load(slot: slot, json: payload)
      data = o11a1Data(["ok": true])
    case "nativePlayerControl":
      O11A1PlayerHost.shared.control(
        slot: query["slot"] ?? "main",
        action: query["action"] ?? "",
        value: Double(query["value"] ?? "0") ?? 0
      )
      data = o11a1Data(["ok": true])
    case "nativePlayerRect":
      O11A1PlayerHost.shared.rect(
        slot: query["slot"] ?? "main",
        x: Double(query["x"] ?? "0") ?? 0,
        y: Double(query["y"] ?? "0") ?? 0,
        width: Double(query["w"] ?? "0") ?? 0,
        height: Double(query["h"] ?? "0") ?? 0,
        visible: (query["visible"] ?? "1") != "0",
        rotation: Double(query["rotation"] ?? "0") ?? 0,
        aspect: query["aspect"] ?? ""
      )
      data = o11a1Data(["ok": true])
    case "nativePlayerRelease":
      O11A1PlayerHost.shared.release(slot: query["slot"] ?? "main")
      data = o11a1Data(["ok": true])
    case "nativePlayerLayer":
      data = o11a1Data(["ok": true])
    case "nativePlayerState":
      data = o11a1Data(O11A1PlayerHost.shared.state(slot: query["slot"] ?? "main"))
    case "playerSnapshot":
      data = o11a1Data([
        "ok": true,
        "image": O11A1PlayerHost.shared.snapshot(slot: query["slot"] ?? "main") ?? ""
      ])
    case "setOrientation":
      let mode = query["mode"] ?? "portrait"
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

  private func deliverSmsResult(_ result: [String: Any]) {
    print("[O11A1] sms result ok=\(o11a1Bool(result["ok"])) "
      + "keyLen=\(o11a1String(result["captchaKey"]).count) "
      + "error=\(o11a1String(result["error"]))")
    let payloadData = (try? JSONSerialization.data(withJSONObject: result)) ?? Data("{}".utf8)
    let payloadString = String(data: payloadData, encoding: .utf8) ?? "{}"
    guard let arrayData = try? JSONSerialization.data(withJSONObject: [payloadString]),
          let array = String(data: arrayData, encoding: .utf8) else { return }
    O11A1PlayerHost.shared.evaluateInPage(
      "window.O11A1Login&&window.O11A1Login.onSmsCode.apply(null,\(array))"
    )
  }

  /* ---------- response helpers ---------- */

  private func captureScreenshot() -> Data {
    var output: [String: Any] = ["ok": false]
    let capture = {
      guard let scene = UIApplication.shared.connectedScenes
        .compactMap({ $0 as? UIWindowScene })
        .first,
        let window = scene.windows.first(where: { $0.isKeyWindow }) else { return }
      let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
      let image = renderer.image { _ in
        window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
      }
      guard let png = image.pngData() else { return }
      let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
      let url = directory.appendingPathComponent("O11A1-\(Int(Date().timeIntervalSince1970)).png")
      do {
        try png.write(to: url)
        output = ["ok": true, "path": url.path]
      } catch {
        print("[O11A1] screenshot failed \(error)")
      }
    }
    if Thread.isMainThread {
      capture()
    } else {
      DispatchQueue.main.sync(execute: capture)
    }
    return o11a1Data(output)
  }

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
    _ connection: NWConnection,
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
