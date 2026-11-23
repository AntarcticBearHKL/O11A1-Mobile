import Foundation
import AVFoundation
import UIKit
import WebKit

/// AVPlayer overlay for iOS.  Media is fetched directly from Bilibili's CDN with
/// the account's UA/Referer/Cookie headers; no localhost media proxy is used.
final class O11A1PlayerHost {
  static let shared = O11A1PlayerHost()

  private final class PlayerView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
  }

  private final class Slot {
    let id: String
    let view = PlayerView()
    let player = AVPlayer()
    var item: AVPlayerItem?
    var seq: Int64 = 0
    var visible = false
    var preview: Bool { id != "main" }
    var started = false
    var firstFrame = false
    var muted = false
    var volume: Float = 1
    var rate: Float = 1
    var positionMs: Double = 0
    var durationMs: Double = 0
    var bufferedMs: Double = 0
    var playing = false
    var videoWidth = 0
    var videoHeight = 0
    var statusObservation: NSKeyValueObservation?
    var readyObservation: NSKeyValueObservation?
    var timeObservation: NSKeyValueObservation?
    var timeObserver: Any?
    var endObserver: NSObjectProtocol?
    var failObserver: NSObjectProtocol?

    init(_ id: String) {
      self.id = id
      view.playerLayer.videoGravity = .resizeAspect
      view.backgroundColor = .black
      view.isUserInteractionEnabled = false
      view.playerLayer.player = player
    }
  }

  private var slots: [String: Slot] = [:]
  private weak var webView: WKWebView?
  private weak var background: UIView?
  private weak var overlay: UIView?

  private init() {}

  // MARK: - webview discovery

  @discardableResult
  private func attachIfNeeded() -> WKWebView? {
    if let web = webView, web.window != nil, web.superview != nil {
      updateContainerFrames(web)
      return web
    }
    guard let window = keyWindow() else { return nil }
    var found: [WKWebView] = []
    func walk(_ view: UIView) {
      if let web = view as? WKWebView { found.append(web) }
      for child in view.subviews { walk(child) }
    }
    walk(window)
    let candidates = found.filter { !$0.isHidden && $0.bounds.width > 120 && $0.bounds.height > 120 }
    guard let web = candidates.max(by: {
      ($0.bounds.width * $0.bounds.height) < ($1.bounds.width * $1.bounds.height)
    }), let host = web.superview else { return nil }

    web.isOpaque = false
    web.backgroundColor = .clear
    web.scrollView.backgroundColor = .clear
    web.scrollView.isOpaque = false

    let bg = UIView(frame: web.frame)
    bg.backgroundColor = .clear
    bg.isUserInteractionEnabled = false
    bg.clipsToBounds = false
    host.insertSubview(bg, belowSubview: web)

    let ov = UIView(frame: web.frame)
    ov.backgroundColor = .clear
    ov.isUserInteractionEnabled = false
    ov.clipsToBounds = false
    host.insertSubview(ov, aboveSubview: web)

    background = bg
    overlay = ov
    webView = web
    return web
  }

  private func updateContainerFrames(_ web: WKWebView) {
    guard let host = web.superview else { return }
    if let bg = background, bg.superview === host {
      bg.frame = web.frame
    } else if let old = background {
      old.removeFromSuperview()
      let bg = UIView(frame: web.frame)
      bg.backgroundColor = .clear
      bg.isUserInteractionEnabled = false
      host.insertSubview(bg, belowSubview: web)
      background = bg
    }
    if let ov = overlay, ov.superview === host {
      ov.frame = web.frame
    } else if let old = overlay {
      old.removeFromSuperview()
      let ov = UIView(frame: web.frame)
      ov.backgroundColor = .clear
      ov.isUserInteractionEnabled = false
      host.insertSubview(ov, aboveSubview: web)
      overlay = ov
    }
  }

  private func keyWindow() -> UIWindow? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    for scene in scenes {
      if let window = scene.windows.first(where: { $0.isKeyWindow }) { return window }
    }
    return scenes.flatMap { $0.windows }.first
  }

  // MARK: - API

  func load(slot id: String, json: [String: Any]) {
    DispatchQueue.main.async {
      guard let web = self.attachIfNeeded() else { return }
      let slot = self.slot(id)
      self.ensureParent(slot)
      let urlString = o11a1String(json["videoUrl"])
      guard let url = URL(string: urlString), !urlString.isEmpty else {
        self.emit(slot, "error", ["error": "empty media url"])
        return
      }
      let headers = (json["headers"] as? [String: Any])?.compactMapValues { $0 as? String } ?? [:]
      slot.seq = o11a1Int64(json["seq"])
      slot.started = false
      slot.firstFrame = false
      slot.durationMs = 0
      slot.bufferedMs = 0
      slot.positionMs = 0
      slot.playing = false
      slot.videoWidth = 0
      slot.videoHeight = 0
      slot.muted = o11a1Bool(json["muted"])
      slot.volume = Float(o11a1PlayerDouble(json["volume"], fallback: 1))
      slot.rate = Float(max(0.1, min(4.0, o11a1PlayerDouble(json["rate"], fallback: 1))))
      slot.player.isMuted = slot.muted
      slot.player.volume = slot.volume
      if slot.preview {
        slot.view.alpha = 0
      }
      slot.view.isHidden = false
      self.clearObservers(slot)
      if id == "main" {
        self.webView = web
      }
      let asset = AVURLAsset(url: url, options: [
        "AVURLAssetHTTPHeaderFieldsKey": headers,
      ])
      let item = AVPlayerItem(asset: asset)
      item.preferredForwardBufferDuration = slot.preview ? 4 : 30
      slot.item = item
      slot.player.replaceCurrentItem(with: item)
      self.observe(slot)
      self.emit(slot, "loadstart", [:])
      if o11a1Bool(json["autoplay"]) {
        slot.player.play()
      }
    }
  }

  func control(slot id: String, action: String, value: Double) {
    DispatchQueue.main.async {
      guard let slot = self.slots[id] else { return }
      switch action {
      case "play":
        slot.player.play()
        slot.player.rate = slot.rate
      case "pause":
        slot.player.pause()
      case "seek":
        let cm = CMTime(seconds: max(0, value / 1000.0), preferredTimescale: 600)
        slot.player.seek(to: cm, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
          self.emit(slot, "seeked", self.timePayload(slot))
        }
        self.emit(slot, "seeking", self.timePayload(slot))
      case "rate":
        slot.rate = Float(max(0.1, min(4.0, value)))
        if slot.player.rate != 0 { slot.player.rate = slot.rate }
        self.emit(slot, "ratechange", [:])
      case "mute":
        slot.muted = value > 0.5
        slot.player.isMuted = slot.muted
        self.emit(slot, "volumechange", [:])
      case "volume":
        slot.volume = Float(max(0, min(1, value)))
        slot.player.volume = slot.volume
        self.emit(slot, "volumechange", [:])
      case "stop":
        slot.player.pause()
        slot.player.replaceCurrentItem(with: nil)
        slot.item = nil
        self.emit(slot, "pause", [:])
      default:
        break
      }
    }
  }

  func rect(slot id: String, x: Double, y: Double, width: Double, height: Double,
            visible: Bool, rotation: Double) {
    DispatchQueue.main.async {
      guard let web = self.attachIfNeeded() else { return }
      self.updateContainerFrames(web)
      guard let slot = self.slots[id] else { return }
      if !visible || width < 2 || height < 2 {
        slot.visible = false
        slot.view.isHidden = true
        return
      }
      slot.visible = true
      slot.view.isHidden = false
      slot.view.transform = .identity
      slot.view.frame = CGRect(x: x, y: y, width: width, height: height)
      if abs(rotation) > 0.5 {
        slot.view.transform = CGAffineTransform(rotationAngle: CGFloat(rotation * .pi / 180))
      }
    }
  }

  func layer(slot id: String, background: Bool) {
    // iOS keeps fullscreen below the webview and previews above it.
  }

  func release(slot id: String) {
    DispatchQueue.main.async {
      guard let slot = self.slots.removeValue(forKey: id) else { return }
      self.clearObservers(slot)
      slot.player.pause()
      slot.player.replaceCurrentItem(with: nil)
      slot.view.removeFromSuperview()
    }
  }

  func state(slot id: String) -> [String: Any] {
    guard Thread.isMainThread else {
      var result: [String: Any] = ["ok": false]
      DispatchQueue.main.sync {
        result = self.stateOnMain(id)
      }
      return result
    }
    return stateOnMain(id)
  }

  private func stateOnMain(_ id: String) -> [String: Any] {
    guard let slot = slots[id] else { return ["ok": false] }
    return [
      "ok": true,
      "position": slot.positionMs,
      "duration": slot.durationMs,
      "buffered": slot.bufferedMs,
      "playing": slot.playing,
      "videoWidth": slot.videoWidth,
      "videoHeight": slot.videoHeight,
    ]
  }

  // MARK: - internals

  private func slot(_ id: String) -> Slot {
    if let existing = slots[id] { return existing }
    let slot = Slot(id)
    slots[id] = slot
    ensureParent(slot)
    return slot
  }

  private func ensureParent(_ slot: Slot) {
    guard let web = webView else { return }
    let parent = slot.preview ? overlay : background
    guard let parent = parent else { return }
    parent.frame = web.frame
    if slot.view.superview !== parent {
      slot.view.removeFromSuperview()
      slot.view.frame = parent.bounds
      parent.addSubview(slot.view)
    }
  }

  private func observe(_ slot: Slot) {
    guard let item = slot.item else { return }
    slot.statusObservation = item.observe(\.status, options: [.new, .initial]) { [weak self, weak slot] item, _ in
      guard let self = self, let slot = slot else { return }
      DispatchQueue.main.async {
        if item.status == .readyToPlay {
          self.updateMetadata(slot)
          self.emit(slot, "loadedmetadata", self.metadataPayload(slot))
          self.emit(slot, "canplay", self.metadataPayload(slot))
          if !slot.started {
            slot.started = true
          }
        } else if item.status == .failed {
          self.emit(slot, "error", ["error": item.error?.localizedDescription ?? "playback failed"])
        }
      }
    }
    slot.readyObservation = slot.view.playerLayer.observe(\.isReadyForDisplay, options: [.new]) { [weak self, weak slot] layer, _ in
      guard let self = self, let slot = slot, layer.isReadyForDisplay else { return }
      DispatchQueue.main.async { self.onFirstFrame(slot) }
    }
    slot.timeObservation = slot.player.observe(\.timeControlStatus, options: [.new]) { [weak self, weak slot] player, _ in
      guard let self = self, let slot = slot else { return }
      DispatchQueue.main.async {
        switch player.timeControlStatus {
        case .playing:
          slot.playing = true
          self.emit(slot, "playing", self.timePayload(slot))
        case .paused:
          if slot.playing {
            slot.playing = false
            self.emit(slot, "pause", self.timePayload(slot))
          }
        case .waitingToPlayAtSpecifiedRate:
          self.emit(slot, "waiting", self.timePayload(slot))
        @unknown default:
          break
        }
      }
    }
    slot.timeObserver = slot.player.addPeriodicTimeObserver(
      forInterval: CMTime(seconds: 0.2, preferredTimescale: 600),
      queue: .main
    ) { [weak self, weak slot] time in
      guard let self = self, let slot = slot else { return }
      slot.positionMs = max(0, time.seconds * 1000)
      self.updateMetadata(slot)
      self.emit(slot, "timeupdate", self.timePayload(slot))
    }
    slot.endObserver = NotificationCenter.default.addObserver(
      forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main
    ) { [weak self, weak slot] _ in
      guard let self = self, let slot = slot else { return }
      slot.playing = false
      self.emit(slot, "ended", self.timePayload(slot))
    }
    slot.failObserver = NotificationCenter.default.addObserver(
      forName: .AVPlayerItemFailedToPlayToEndTime, object: item, queue: .main
    ) { [weak self, weak slot] note in
      guard let self = self, let slot = slot else { return }
      let error = note.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
      self.emit(slot, "error", ["error": error?.localizedDescription ?? "playback failed"])
    }
  }

  private func clearObservers(_ slot: Slot) {
    slot.statusObservation?.invalidate()
    slot.readyObservation?.invalidate()
    slot.timeObservation?.invalidate()
    slot.statusObservation = nil
    slot.readyObservation = nil
    slot.timeObservation = nil
    if let observer = slot.timeObserver {
      slot.player.removeTimeObserver(observer)
      slot.timeObserver = nil
    }
    if let observer = slot.endObserver {
      NotificationCenter.default.removeObserver(observer)
      slot.endObserver = nil
    }
    if let observer = slot.failObserver {
      NotificationCenter.default.removeObserver(observer)
      slot.failObserver = nil
    }
  }

  private func updateMetadata(_ slot: Slot) {
    guard let item = slot.item else { return }
    let duration = item.duration.seconds
    if duration.isFinite && duration > 0 {
      slot.durationMs = duration * 1000
    }
    let size = item.presentationSize
    if size.width > 0 && size.height > 0 {
      slot.videoWidth = Int(size.width)
      slot.videoHeight = Int(size.height)
    }
    if let range = item.loadedTimeRanges.last?.timeRangeValue {
      slot.bufferedMs = max(0, range.end.seconds * 1000)
    }
  }

  private func onFirstFrame(_ slot: Slot) {
    guard !slot.firstFrame else { return }
    slot.firstFrame = true
    slot.view.alpha = 1
    updateMetadata(slot)
    emit(slot, "firstframe", metadataPayload(slot))
    emit(slot, "canplay", metadataPayload(slot))
  }

  private func metadataPayload(_ slot: Slot) -> [String: Any] {
    [
      "seq": slot.seq,
      "duration": slot.durationMs,
      "videoWidth": slot.videoWidth,
      "videoHeight": slot.videoHeight,
    ]
  }

  private func timePayload(_ slot: Slot) -> [String: Any] {
    [
      "seq": slot.seq,
      "position": slot.positionMs,
      "duration": slot.durationMs,
      "buffered": slot.bufferedMs,
      "playing": slot.playing,
      "videoWidth": slot.videoWidth,
      "videoHeight": slot.videoHeight,
    ]
  }

  private func emit(_ slot: Slot, _ type: String, _ payload: [String: Any]) {
    if !Thread.isMainThread {
      DispatchQueue.main.async { self.emit(slot, type, payload) }
      return
    }
    guard let web = webView else { return }
    var value = payload
    value["seq"] = slot.seq
    let payloadData = (try? JSONSerialization.data(withJSONObject: value)) ?? Data("{}".utf8)
    let payloadString = String(data: payloadData, encoding: .utf8) ?? "{}"
    guard let arrayData = try? JSONSerialization.data(withJSONObject: [slot.id, type, payloadString]),
          let array = String(data: arrayData, encoding: .utf8) else { return }
    web.evaluateJavaScript(
      "window.O11A1NativeMedia&&window.O11A1NativeMedia.onEvent.apply(null,\(array))",
      completionHandler: nil
    )
  }
}

private func o11a1PlayerDouble(_ value: Any?, fallback: Double) -> Double {
  if let number = value as? NSNumber { return number.doubleValue }
  if let double = value as? Double { return double }
  if let string = value as? String, let double = Double(string) { return double }
  return fallback
}
