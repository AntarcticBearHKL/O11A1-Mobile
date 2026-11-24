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
    let audioPlayer = AVPlayer()
    var item: AVPlayerItem?
    var audioItem: AVPlayerItem?
    var dashAudio = false
    var dashViaLoader = false
    var dashRetrying = false
    var dashVideoURL: URL?
    var dashAudioURL: URL?
    var dashStartMs: Double = 0
    var dashDurationMs: Double = 0
    var dashAutoplay = false
    var audioStatusObservation: NSKeyValueObservation?
    var seq: Int64 = 0
    var visible = false
    var preview: Bool { id != "main" }
    var started = false
    var firstFrame = false
    var muted = false
    var volume: Float = 1
    var rate: Float = 1
    var pendingPlay = false
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
      audioPlayer.automaticallyWaitsToMinimizeStalling = true
      audioPlayer.actionAtItemEnd = .none
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

  func evaluateInPage(_ javascript: String) {
    DispatchQueue.main.async {
      guard let web = self.attachIfNeeded() else { return }
      web.evaluateJavaScript(javascript, completionHandler: nil)
    }
  }

  // MARK: - API

  func load(slot id: String, json: [String: Any]) {
    DispatchQueue.main.async {
      guard let web = self.attachIfNeeded() else { return }
      do {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .moviePlayback, options: [])
        try session.setActive(true)
      } catch {}
      let slot = self.slot(id)
      self.ensureParent(slot)
      let urlString = o11a1String(json["videoUrl"])
      guard let url = URL(string: urlString), !urlString.isEmpty else {
        self.emit(slot, "error", ["error": "empty media url"])
        return
      }
      let headers = (json["headers"] as? [String: Any])?.compactMapValues { $0 as? String } ?? [:]
      let audioURL = o11a1String(json["audioUrl"])
      let kind = o11a1String(json["kind"])
      let startMs = max(0, o11a1PlayerDouble(json["startMs"], fallback: 0))
      let durationMs = max(0, o11a1PlayerDouble(json["durationMs"], fallback: 0))
      let autoplay = o11a1Bool(json["autoplay"])
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
      slot.player.automaticallyWaitsToMinimizeStalling = !slot.preview
      slot.pendingPlay = autoplay
      NSLog("[O11A1] load %@ kind=%@ audio=%@ muted=%d preview=%d url=%@%@",
            id, kind, audioURL.isEmpty ? "no" : "yes",
            slot.muted ? 1 : 0, slot.preview ? 1 : 0,
            url.host ?? "?", url.path)
      if slot.preview {
        slot.view.alpha = 0
      }
      slot.view.isHidden = false
      self.clearObservers(slot)
      if id == "main" {
        self.webView = web
      }
      self.emit(slot, "loadstart", [:])
      if audioURL.isEmpty || kind != "dash" {
        self.clearDASH(slot)
      }
      if !audioURL.isEmpty && kind == "dash", let audio = URL(string: audioURL) {
        self.installDASH(
          slot,
          video: url,
          audio: audio,
          headers: headers,
          startMs: startMs,
          durationMs: durationMs,
          autoplay: autoplay
        )
      } else {
        let item = self.playerItem(url: url, headers: headers)
        self.installItem(slot, item: item, startMs: startMs, autoplay: autoplay)
      }
    }
  }

  private func playerItem(url: URL, headers: [String: String]) -> AVPlayerItem {
    let asset = AVURLAsset(url: url, options: [
      "AVURLAssetHTTPHeaderFieldsKey": headers,
      "AVURLAssetAllowsExpensiveNetworkAccess": true,
      "AVURLAssetAllowsConstrainedNetworkAccess": true,
    ])
    return AVPlayerItem(asset: asset)
  }

  private func installItem(_ slot: Slot, item: AVPlayerItem, startMs: Double, autoplay: Bool) {
    item.preferredForwardBufferDuration = slot.preview ? 8 : 120
    slot.item = item
    slot.player.replaceCurrentItem(with: item)
    if startMs > 0 {
      slot.player.seek(
        to: CMTime(seconds: startMs / 1000.0, preferredTimescale: 600),
        toleranceBefore: .zero,
        toleranceAfter: .zero
      )
    }
    observe(slot)
    if autoplay || slot.pendingPlay {
      if slot.preview {
        slot.player.playImmediately(atRate: max(0.1, slot.rate))
      } else {
        slot.player.play()
      }
    }
  }

  private func installDASH(
    _ slot: Slot,
    video: URL,
    audio: URL,
    headers: [String: String],
    startMs: Double,
    durationMs: Double,
    autoplay: Bool
  ) {
    slot.dashVideoURL = video
    slot.dashAudioURL = audio
    slot.dashStartMs = startMs
    slot.dashDurationMs = durationMs
    slot.dashAutoplay = autoplay
    // The DASH URLs are signed with platform=pc; sending the Android API
    // user agent makes the CDN answer 403, while the desktop agent and a
    // bilibili referer are accepted. Cookies are not needed for the signed
    // media URL and are deliberately left out.
    let mediaHeaders = [
      "Referer": "https://www.bilibili.com/",
      "User-Agent": O11A1BiliClient.desktopUserAgent,
      "Accept": "*/*"
    ]
    let options: [String: Any] = [
      "AVURLAssetHTTPHeaderFieldsKey": mediaHeaders,
      "AVURLAssetAllowsExpensiveNetworkAccess": true,
      "AVURLAssetAllowsConstrainedNetworkAccess": true,
    ]
    let videoAsset = AVURLAsset(url: video, options: options)
    let audioAsset = AVURLAsset(url: audio, options: options)
    installDASHItems(
      slot,
      videoAsset: videoAsset,
      audioAsset: audioAsset,
      startMs: startMs,
      durationMs: durationMs,
      autoplay: autoplay,
      viaLoader: false
    )
  }

  private func installDASHLoader(_ slot: Slot) {
    guard let video = slot.dashVideoURL, let audio = slot.dashAudioURL else { return }
    clearObservers(slot)
    slot.player.pause()
    slot.player.replaceCurrentItem(with: nil)
    slot.item = nil
    let mediaHeaders = [
      "Referer": "https://www.bilibili.com/",
      "User-Agent": O11A1BiliClient.desktopUserAgent,
      "Accept": "*/*"
    ]
    let videoAsset = O11A1MediaLoader.shared.asset(
      for: video,
      headers: mediaHeaders,
      contentType: "public.mpeg-4"
    )
    let audioAsset = O11A1MediaLoader.shared.asset(
      for: audio,
      headers: mediaHeaders,
      contentType: "public.mpeg-4-audio"
    )
    installDASHItems(
      slot,
      videoAsset: videoAsset,
      audioAsset: audioAsset,
      startMs: slot.dashStartMs,
      durationMs: slot.dashDurationMs,
      autoplay: slot.dashAutoplay || slot.pendingPlay,
      viaLoader: true
    )
  }

  private func installDASHItems(
    _ slot: Slot,
    videoAsset: AVAsset,
    audioAsset: AVAsset,
    startMs: Double,
    durationMs: Double,
    autoplay: Bool,
    viaLoader: Bool
  ) {
    let videoItem = AVPlayerItem(asset: videoAsset)
    let audioItem = AVPlayerItem(asset: audioAsset)
    videoItem.preferredForwardBufferDuration = slot.preview ? 8 : 30
    audioItem.preferredForwardBufferDuration = slot.preview ? 8 : 30
    clearDASH(slot)
    slot.dashAudio = true
    slot.dashViaLoader = viaLoader
    slot.dashRetrying = false
    slot.durationMs = durationMs
    slot.audioItem = audioItem
    slot.audioPlayer.isMuted = slot.muted
    slot.audioPlayer.volume = slot.volume
    slot.audioPlayer.replaceCurrentItem(with: audioItem)
    slot.audioStatusObservation = audioItem.observe(\.status, options: [.new]) { [weak self, weak slot] item, _ in
      guard let self = self, let slot = slot, item.status == .failed else { return }
      DispatchQueue.main.async {
        NSLog("[O11A1] dash audio failed %@ %@", slot.id,
              item.error?.localizedDescription ?? "unknown")
        if !slot.dashViaLoader, !slot.dashRetrying, slot.dashVideoURL != nil {
          slot.dashRetrying = true
          self.installDASHLoader(slot)
        } else {
          self.emit(slot, "error", ["error": "dash audio failed"])
        }
      }
    }
    if startMs > 0 {
      let cm = CMTime(seconds: startMs / 1000.0, preferredTimescale: 600)
      slot.audioPlayer.seek(to: cm, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    slot.player.isMuted = true
    NSLog("[O11A1] dash %@ via=%@ %.0fs", slot.id,
          viaLoader ? "loader" : "direct", durationMs / 1000)
    installItem(slot, item: videoItem, startMs: startMs, autoplay: autoplay)
    if autoplay || slot.pendingPlay {
      slot.audioPlayer.play()
      slot.audioPlayer.rate = slot.rate
    }
  }

  private func clearDASH(_ slot: Slot) {
    guard slot.dashAudio || slot.audioItem != nil else { return }
    slot.dashAudio = false
    slot.audioStatusObservation?.invalidate()
    slot.audioStatusObservation = nil
    slot.audioItem = nil
    slot.audioPlayer.pause()
    slot.audioPlayer.replaceCurrentItem(with: nil)
  }

  func control(slot id: String, action: String, value: Double) {
    DispatchQueue.main.async {
      guard let slot = self.slots[id] else { return }
      switch action {
      case "play":
        slot.pendingPlay = true
        if slot.item != nil {
          slot.player.play()
          slot.player.rate = slot.rate
        }
        if slot.dashAudio, slot.audioItem != nil {
          slot.audioPlayer.play()
          slot.audioPlayer.rate = slot.rate
        }
      case "pause":
        slot.pendingPlay = false
        slot.player.pause()
        slot.audioPlayer.pause()
      case "seek":
        let cm = CMTime(seconds: max(0, value / 1000.0), preferredTimescale: 600)
        slot.player.seek(to: cm, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
          self.emit(slot, "seeked", self.timePayload(slot))
        }
        if slot.dashAudio {
          slot.audioPlayer.seek(to: cm, toleranceBefore: .zero, toleranceAfter: .zero)
        }
        self.emit(slot, "seeking", self.timePayload(slot))
      case "rate":
        slot.rate = Float(max(0.1, min(4.0, value)))
        if slot.player.rate != 0 { slot.player.rate = slot.rate }
        if slot.dashAudio, slot.audioPlayer.rate != 0 {
          slot.audioPlayer.rate = slot.rate
        }
        self.emit(slot, "ratechange", [:])
      case "mute":
        slot.muted = value > 0.5
        if slot.dashAudio {
          slot.audioPlayer.isMuted = slot.muted
        } else {
          slot.player.isMuted = slot.muted
        }
        self.emit(slot, "volumechange", [:])
      case "volume":
        slot.volume = Float(max(0, min(1, value)))
        if slot.dashAudio {
          slot.audioPlayer.volume = slot.volume
        } else {
          slot.player.volume = slot.volume
        }
        self.emit(slot, "volumechange", [:])
      case "stop":
        slot.player.pause()
        slot.player.replaceCurrentItem(with: nil)
        slot.item = nil
        self.clearDASH(slot)
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
    DispatchQueue.main.async {
      guard let slot = self.slots[id] else { return }
      let parent = background ? self.background : self.overlay
      guard let parent = parent else { return }
      guard slot.view.superview !== parent else { return }
      let frame = slot.view.frame
      slot.view.removeFromSuperview()
      parent.addSubview(slot.view)
      slot.view.frame = frame
      if background {
        parent.bringSubviewToFront(slot.view)
      }
    }
  }

  func release(slot id: String) {
    DispatchQueue.main.async {
      guard let slot = self.slots.removeValue(forKey: id) else { return }
      self.clearObservers(slot)
      slot.player.pause()
      slot.player.replaceCurrentItem(with: nil)
      self.clearDASH(slot)
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
          NSLog("[O11A1] item ready %@ duration=%.1f size=%.0fx%.0f",
                slot.id, item.duration.seconds,
                item.presentationSize.width, item.presentationSize.height)
          self.updateMetadata(slot)
          self.emit(slot, "loadedmetadata", self.metadataPayload(slot))
          self.emit(slot, "canplay", self.metadataPayload(slot))
          if !slot.started {
            slot.started = true
          }
        } else if item.status == .failed {
          NSLog("[O11A1] item failed %@ %@", slot.id,
                item.error?.localizedDescription ?? "unknown")
          if slot.dashAudio, !slot.dashViaLoader, !slot.dashRetrying,
             slot.dashVideoURL != nil {
            slot.dashRetrying = true
            self.installDASHLoader(slot)
            return
          }
          slot.audioPlayer.pause()
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
          NSLog("[O11A1] playing %@", slot.id)
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
      if slot.dashAudio, slot.playing,
         slot.audioPlayer.timeControlStatus == .playing {
        let audioSeconds = slot.audioPlayer.currentTime().seconds
        if audioSeconds.isFinite, abs(audioSeconds - time.seconds) > 0.5 {
          slot.audioPlayer.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
        }
      }
      self.updateMetadata(slot)
      self.emit(slot, "timeupdate", self.timePayload(slot))
    }
    slot.endObserver = NotificationCenter.default.addObserver(
      forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main
    ) { [weak self, weak slot] _ in
      guard let self = self, let slot = slot else { return }
      slot.playing = false
      slot.audioPlayer.pause()
      self.emit(slot, "ended", self.timePayload(slot))
    }
    slot.failObserver = NotificationCenter.default.addObserver(
      forName: .AVPlayerItemFailedToPlayToEndTime, object: item, queue: .main
    ) { [weak self, weak slot] note in
      guard let self = self, let slot = slot else { return }
      let error = note.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
      slot.audioPlayer.pause()
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
    clearDASH(slot)
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
      if !slot.firstFrame {
        NSLog("[O11A1] video size %@ %dx%d ready=%d", slot.id, slot.videoWidth, slot.videoHeight,
              slot.view.playerLayer.isReadyForDisplay ? 1 : 0)
      }
      if slot.view.playerLayer.isReadyForDisplay && !slot.firstFrame {
        onFirstFrame(slot)
      }
    }
    if let range = item.loadedTimeRanges.last?.timeRangeValue {
      slot.bufferedMs = max(0, range.end.seconds * 1000)
    }
  }

  private func onFirstFrame(_ slot: Slot) {
    guard !slot.firstFrame else { return }
    guard slot.videoWidth > 0, slot.videoHeight > 0 else { return }
    slot.firstFrame = true
    slot.view.alpha = 1
    NSLog("[O11A1] firstframe %@ size=%dx%d", slot.id, slot.videoWidth, slot.videoHeight)
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
