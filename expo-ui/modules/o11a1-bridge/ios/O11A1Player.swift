import Foundation
import AVFoundation
import AVKit
import UIKit
import WebKit
import QuartzCore
import CoreImage

/// AVPlayer overlay for iOS.  Media is fetched directly from Bilibili's CDN with
/// the account's UA/Referer/Cookie headers; no localhost media proxy is used.
final class O11A1PlayerHost: NSObject {
  static let shared = O11A1PlayerHost()

  private final class PlayerSurface: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
  }

  private final class PlayerView: UIView {
    private let backdrop = PlayerSurface()
    private let blur = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private let foreground = PlayerSurface()
    var playerLayer: AVPlayerLayer { foreground.playerLayer }

    override init(frame: CGRect) {
      super.init(frame: frame)
      backgroundColor = .black
      clipsToBounds = true
      layer.cornerRadius = 22
      layer.cornerCurve = .continuous
      backdrop.isUserInteractionEnabled = false
      foreground.isUserInteractionEnabled = false
      blur.isUserInteractionEnabled = false
      /* AVPlayerLayer draws black in the letterbox area when it is opaque;
         that hid the blurred video behind the aspect-fit foreground, which is
         especially obvious in landscape. Keep both surfaces transparent. */
      backdrop.isOpaque = false
      backdrop.backgroundColor = .clear
      backdrop.playerLayer.backgroundColor = UIColor.clear.cgColor
      foreground.isOpaque = false
      foreground.backgroundColor = .clear
      foreground.playerLayer.backgroundColor = UIColor.clear.cgColor
      backdrop.playerLayer.videoGravity = .resizeAspectFill
      foreground.playerLayer.videoGravity = .resizeAspect
      backdrop.alpha = 0.92
      blur.alpha = 0.9
      addSubview(backdrop)
      addSubview(blur)
      addSubview(foreground)
    }

    required init?(coder: NSCoder) {
      super.init(coder: coder)
    }

    func bind(_ player: AVPlayer) {
      backdrop.playerLayer.player = player
      foreground.playerLayer.player = player
    }

    func setForegroundGravity(_ gravity: AVLayerVideoGravity) {
      if foreground.playerLayer.videoGravity != gravity {
        foreground.playerLayer.videoGravity = gravity
      }
    }

    override func layoutSubviews() {
      super.layoutSubviews()
      backdrop.frame = bounds
      blur.frame = bounds
      foreground.frame = bounds
    }
  }

  private final class PipDelegate: NSObject, AVPictureInPictureControllerDelegate {
    weak var host: O11A1PlayerHost?
    let slotId: String
    var restoreRequested = false
    var stoppedByApp = false

    init(host: O11A1PlayerHost, slotId: String) {
      self.host = host
      self.slotId = slotId
      super.init()
    }

    func pictureInPictureControllerDidStartPictureInPicture(
      _ pictureInPictureController: AVPictureInPictureController
    ) {
      host?.pipDidStart(slotId)
    }

    func pictureInPictureController(
      _ pictureInPictureController: AVPictureInPictureController,
      restoreUserInterfaceForPictureInPictureStopWithCompletionHandler
        completionHandler: @escaping (Bool) -> Void
    ) {
      restoreRequested = true
      host?.pipWillRestore(slotId)
      /* Give the web player one frame to reopen behind the system's restore
         animation instead of revealing the feed first. */
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
        completionHandler(true)
      }
    }

    func pictureInPictureControllerDidStopPictureInPicture(
      _ pictureInPictureController: AVPictureInPictureController
    ) {
      host?.pipDidStop(slotId, restore: restoreRequested, byApp: stoppedByApp)
      restoreRequested = false
      stoppedByApp = false
    }

    func pictureInPictureController(
      _ pictureInPictureController: AVPictureInPictureController,
      failedToStartPictureInPictureWithError error: Error
    ) {
      host?.pipDidFail(slotId, error: error)
    }
  }

  private final class Slot {
    let id: String
    let view = PlayerView()
    let player = AVPlayer()
    let audioPlayer = AVPlayer()
    var item: AVPlayerItem?
    var videoOutput: AVPlayerItemVideoOutput?
    var audioItem: AVPlayerItem?
    var dashAudio = false
    var dashViaLoader = false
    var dashRetrying = false
    var dashVideoURL: URL?
    var dashAudioURL: URL?
    var dashStartMs: Double = 0
    var dashDurationMs: Double = 0
    var dashAutoplay = false
    var dashPromoted = false
    var audioStatusObservation: NSKeyValueObservation?
    var seq: Int64 = 0
    var visible = false
    var preview: Bool { id != "main" }
    var targetFrame: CGRect?
    var targetAt: CFTimeInterval = 0
    var rectVelocity: CGFloat = 0
    var seeking = false
    var seekToken = 0
    var started = false
    var firstFrame = false
    var muted = false
    var volume: Float = 1
    var rate: Float = 1
    var loop = false
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
    var pipController: AVPictureInPictureController?
    var pipDelegate: PipDelegate?
    var pipActive = false

    init(_ id: String) {
      self.id = id
      view.backgroundColor = .black
      view.isUserInteractionEnabled = false
      view.bind(player)
      audioPlayer.automaticallyWaitsToMinimizeStalling = true
      audioPlayer.actionAtItemEnd = .none
    }
  }

  private var slots: [String: Slot] = [:]
  private weak var webView: WKWebView?
  private weak var background: UIView?
  private weak var overlay: UIView?
  private var rectLink: CADisplayLink?
  private var rectSamples = 0
  private var rectLogAt = CFAbsoluteTimeGetCurrent()
  private var jsClockOffset: CFTimeInterval?
  private var lastRectTimestamp: Double = 0
  private var statsPrevious: [String: (bytes: Int64, at: CFTimeInterval)] = [:]

  private override init() {
    super.init()
  }

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
      if slot.pipActive {
        slot.pipDelegate?.stoppedByApp = true
        slot.pipController?.stopPictureInPicture()
      }
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
      slot.seeking = false
      slot.seekToken += 1
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
      slot.loop = o11a1Bool(json["loop"])
      slot.dashPromoted = o11a1Bool(json["promoted"])
      slot.player.isMuted = slot.muted
      slot.player.volume = slot.volume
      slot.player.automaticallyWaitsToMinimizeStalling = !slot.preview && !slot.dashAudio
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
        self.ensurePipController(slot)
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
    let output = AVPlayerItemVideoOutput(pixelBufferAttributes: [
      kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
    ])
    item.add(output)
    slot.videoOutput = output
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
    /* DASH has a separate audio item. The JS may already have asked this item
       to play while the load request was still in flight; keep that request
       instead of clearing it here. */
    let wantsPlay = autoplay || slot.pendingPlay
    slot.pendingPlay = wantsPlay
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
      autoplay: wantsPlay,
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
    videoItem.preferredForwardBufferDuration = slot.preview ? 4 : 3
    audioItem.preferredForwardBufferDuration = slot.preview ? 4 : 3
    clearDASH(slot)
    slot.dashAudio = true
    slot.dashViaLoader = viaLoader
    slot.dashRetrying = false
    slot.durationMs = durationMs
    slot.audioItem = audioItem
    slot.audioPlayer.isMuted = true
    slot.audioPlayer.volume = 0
    slot.audioPlayer.automaticallyWaitsToMinimizeStalling = false
    slot.audioPlayer.replaceCurrentItem(with: audioItem)
    /* Nudge the audio item into loading immediately. Waiting for its status
       while both players are paused can deadlock on iOS: the item is never
       asked for data, so it never becomes ready and the video gate never
       opens. Play it muted for now; startDASHAudio restores the real volume
       once the picture is running. */
    if autoplay {
      slot.audioPlayer.play()
    }
    slot.audioStatusObservation = audioItem.observe(\.status, options: [.new]) { [weak self, weak slot] item, _ in
      guard let self = self, let slot = slot else { return }
      DispatchQueue.main.async {
        if item.status == .failed {
          NSLog("[O11A1] dash audio failed %@ %@", slot.id,
                item.error?.localizedDescription ?? "unknown")
          if !slot.dashViaLoader, !slot.dashRetrying, slot.dashVideoURL != nil {
            slot.dashRetrying = true
            self.installDASHLoader(slot)
          } else {
            self.emit(slot, "error", ["error": "dash audio failed"])
          }
        } else if item.status == .readyToPlay {
          if slot.pendingPlay && !slot.playing {
            slot.player.play()
          }
          if slot.playing {
            self.startDASHAudio(slot)
          }
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
    let seq = slot.seq
    /* If the audio item never becomes ready, abandon DASH quickly instead of
       showing a silent video until the long DASH deadline. */
    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { [weak self, weak slot] in
      guard let self = self, let slot = slot, slot.seq == seq, slot.dashAudio,
            slot.dashViaLoader == viaLoader,
            slot.audioItem?.status != .readyToPlay else { return }
      NSLog("[O11A1] dash audio not ready %@ via=%@", slot.id, viaLoader ? "loader" : "direct")
      self.emit(slot, "error", ["error": "dash audio not ready"])
    }
    let dashDeadline = viaLoader ? 10.0 : 2.5
    DispatchQueue.main.asyncAfter(deadline: .now() + dashDeadline) { [weak self, weak slot] in
      guard let self = self, let slot = slot, slot.seq == seq, slot.dashAudio,
            slot.dashViaLoader == viaLoader,
            slot.item?.status != .readyToPlay else { return }
      /* A raw m4s URL often stays in .loading instead of failing. Retry through
         the byte-range loader before giving up on DASH (and before the JS
         falls back to a lower progressive quality). */
      if !slot.dashViaLoader, !slot.dashRetrying, slot.dashVideoURL != nil {
        slot.dashRetrying = true
        self.installDASHLoader(slot)
        return
      }
      NSLog("[O11A1] dash timeout %@ via=%@", slot.id, slot.dashViaLoader ? "loader" : "direct")
      slot.audioPlayer.pause()
      self.emit(slot, "error", ["error": "dash timeout"])
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self, weak slot] in
      guard let self = self, let slot = slot, slot.seq == seq, slot.dashAudio else { return }
      NSLog("[O11A1] audio state %@ muted=%d vol=%.1f item=%d player=%d rate=%.2f time=%.1f",
            slot.id, slot.audioPlayer.isMuted ? 1 : 0, slot.audioPlayer.volume,
            slot.audioItem?.status.rawValue ?? -1,
            slot.audioPlayer.timeControlStatus.rawValue,
            slot.audioPlayer.rate,
            slot.audioPlayer.currentTime().seconds)
      self.startDASHAudio(slot)
    }
  }

  private func startDASHAudio(_ slot: Slot) {
    guard slot.dashAudio, slot.audioItem != nil,
          slot.player.timeControlStatus == .playing else { return }
    let videoTime = slot.player.currentTime()
    if videoTime.isValid && !videoTime.isIndefinite {
      let audioTime = slot.audioPlayer.currentTime()
      let drift = audioTime.isValid ? abs(audioTime.seconds - videoTime.seconds) : .greatestFiniteMagnitude
      if drift > 0.35 {
        /* The audio item often becomes ready a few seconds after the video.
           Seeking it to the live video position makes the sound begin in sync
           instead of staying silent and then starting from the beginning. */
        slot.audioPlayer.seek(to: videoTime, toleranceBefore: .zero, toleranceAfter: .zero)
        NSLog("[O11A1] dash audio sync %@ drift=%.2f -> %.2f", slot.id, drift, videoTime.seconds)
      }
    }
    guard slot.audioItem?.status == .readyToPlay else { return }
    slot.audioPlayer.isMuted = slot.muted
    slot.audioPlayer.volume = slot.volume
    if slot.audioPlayer.timeControlStatus != .playing {
      NSLog("[O11A1] dash audio start %@ muted=%d vol=%.1f",
            slot.id, slot.audioPlayer.isMuted ? 1 : 0, slot.audioPlayer.volume)
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

  func snapshot(slot id: String) -> String? {
    var value: String?
    let capture = {
      guard let slot = self.slots[id], let item = slot.item,
            let output = slot.videoOutput else { return }
      var buffer = output.copyPixelBuffer(
        forItemTime: item.currentTime(),
        itemTimeForDisplay: nil
      )
      if buffer == nil {
        let earlier = CMTimeSubtract(
          item.currentTime(),
          CMTime(seconds: 0.18, preferredTimescale: 600)
        )
        if CMTimeCompare(earlier, .zero) > 0 {
          buffer = output.copyPixelBuffer(forItemTime: earlier, itemTimeForDisplay: nil)
        }
      }
      guard let buffer = buffer else { return }
      let image = CIImage(cvPixelBuffer: buffer)
      let context = CIContext()
      guard let cgImage = context.createCGImage(image, from: image.extent) else { return }
      guard let data = UIImage(cgImage: cgImage).jpegData(compressionQuality: 0.72) else { return }
      value = data.base64EncodedString()
    }
    if Thread.isMainThread {
      capture()
    } else {
      DispatchQueue.main.sync(execute: capture)
    }
    return value
  }

  func control(slot id: String, action: String, value: Double) {
    DispatchQueue.main.async {
      guard let slot = self.slots[id] else { return }
      switch action {
      case "play":
        NSLog("[O11A1] control play %@", slot.id)
        slot.pendingPlay = true
        if slot.item != nil {
          slot.player.play()
          slot.player.rate = slot.rate
        }
        if slot.dashAudio {
          self.startDASHAudio(slot)
        }
      case "pause":
        NSLog("[O11A1] control pause %@", slot.id)
        slot.pendingPlay = false
        slot.player.pause()
        slot.audioPlayer.pause()
      case "seek":
        let cm = CMTime(seconds: max(0, value / 1000.0), preferredTimescale: 600)
        slot.seekToken += 1
        let token = slot.seekToken
        slot.seeking = true
        let resume = slot.pendingPlay || slot.player.timeControlStatus == .playing
        NSLog("[O11A1] seek %@ -> %.2f resume=%d", slot.id, cm.seconds, resume ? 1 : 0)
        slot.player.pause()
        slot.audioPlayer.pause()
        slot.positionMs = cm.seconds * 1000
        self.emit(slot, "seeking", self.timePayload(slot))
        let tolerance = CMTime(seconds: 0.12, preferredTimescale: 600)
        slot.player.seek(to: cm, toleranceBefore: tolerance, toleranceAfter: tolerance) { [weak self, weak slot] _ in
          guard let self = self, let slot = slot, slot.seekToken == token else { return }
          let finish = {
            guard slot.seekToken == token else { return }
            slot.seeking = false
            slot.positionMs = cm.seconds * 1000
            NSLog("[O11A1] seeked %@ -> %.2f", slot.id, cm.seconds)
            self.emit(slot, "seeked", self.timePayload(slot))
            if resume && slot.pendingPlay {
              slot.player.play()
              if slot.dashAudio { slot.audioPlayer.play() }
            }
          }
          if slot.dashAudio, slot.audioItem != nil {
            slot.audioPlayer.seek(to: cm, toleranceBefore: tolerance, toleranceAfter: tolerance) { _ in
              DispatchQueue.main.async(execute: finish)
            }
          } else {
            DispatchQueue.main.async(execute: finish)
          }
        }
      case "rate":
        slot.rate = Float(max(0.1, min(4.0, value)))
        if slot.player.rate != 0 { slot.player.rate = slot.rate }
        if slot.dashAudio, slot.audioPlayer.rate != 0 {
          slot.audioPlayer.rate = slot.rate
        }
        self.emit(slot, "ratechange", [:])
      case "mute":
        slot.muted = value > 0.5
        NSLog("[O11A1] control mute %@ %d", slot.id, slot.muted ? 1 : 0)
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
            visible: Bool, rotation: Double, velocity: Double = 0,
            timestamp: Double = 0, aspect: String = "") {
    let apply = { [weak self] in
      guard let self = self, let slot = self.slots[id] else { return }
      /* The system owns the video during PiP; rect updates from the hidden web
         player must not move or hide the inline layer. */
      if slot.pipActive { return }
      /* The player always shows the whole frame. Landscape no longer forces
         aspect-fill: the blurred video backdrop fills the letterbox instead. */
      let gravity: AVLayerVideoGravity
      if aspect == "拉伸" {
        gravity = .resize
      } else if aspect == "裁切" {
        gravity = .resizeAspectFill
      } else {
        gravity = .resizeAspect
      }
      slot.view.setForegroundGravity(gravity)
      if !visible || width < 2 || height < 2 {
        slot.visible = false
        slot.targetFrame = nil
        slot.rectVelocity = 0
        slot.view.isHidden = true
        return
      }
      if self.webView == nil {
        guard self.attachIfNeeded() != nil else { return }
      }
      if let web = self.webView, let bg = self.background, bg.frame != web.frame {
        self.updateContainerFrames(web)
      }
      if slot.view.superview == nil {
        self.ensureParent(slot)
      }
      var frame = CGRect(x: x, y: y, width: width, height: height)
      /* The rotated layer's bounding box is centred by its frame centre. The
         WebView reports the rotated rect in CSS coordinates; anchoring it to
         the WebView centre also covers layout-viewport rounding differences. */
      if abs(rotation) > 0.5, let web = self.webView {
        frame = CGRect(
          x: web.bounds.midX - CGFloat(width) / 2,
          y: web.bounds.midY - CGFloat(height) / 2,
          width: CGFloat(width),
          height: CGFloat(height)
        )
      }
      let now = CACurrentMediaTime()
      var deliveredAge: CFTimeInterval = 0
      if timestamp > 0 {
        let jsNow = timestamp / 1000.0
        if let offset = self.jsClockOffset {
          self.jsClockOffset = min(offset, now - jsNow)
        } else {
          self.jsClockOffset = now - jsNow
        }
        deliveredAge = max(0, now - jsNow - (self.jsClockOffset ?? 0))
        self.lastRectTimestamp = timestamp
      }
      if velocity != 0, deliveredAge > 0 {
        // The WebView message queue may deliver only 40-60 rects/s. Move the
        // target to where the row is now, not where it was when JS sampled it.
        frame.origin.y += CGFloat(velocity * min(deliveredAge, 0.045))
      }
      if let previous = slot.targetFrame, slot.targetAt > 0 {
        let dt = now - slot.targetAt
        if dt > 0.002 && dt < 0.2 {
          slot.rectVelocity = (frame.origin.y - previous.origin.y) / CGFloat(dt)
        }
      } else if velocity != 0 {
        slot.rectVelocity = CGFloat(velocity)
      }
      slot.targetFrame = frame
      slot.targetAt = now
      slot.visible = true
      slot.view.isHidden = false
      /* Set bounds and center rather than frame: `frame` is undefined on a
         rotated view and applying it after the transform makes UIKit treat the
         size as the rotated bounding box, which collapses the landscape layer
         to a portrait square. */
      slot.view.transform = .identity
      slot.view.bounds = CGRect(origin: .zero, size: frame.size)
      slot.view.center = CGPoint(x: frame.midX, y: frame.midY)
      if abs(rotation) > 0.5 {
        slot.view.transform = CGAffineTransform(rotationAngle: CGFloat(rotation * .pi / 180))
      }
      if slot.preview {
        self.rectSamples += 1
        let now = CFAbsoluteTimeGetCurrent()
        let elapsed = now - self.rectLogAt
        if elapsed >= 2 {
          NSLog("[O11A1] preview rect hz=%.1f y=%.0f",
                Double(self.rectSamples) / elapsed, frame.origin.y)
          self.rectSamples = 0
          self.rectLogAt = now
        }
      }
      self.startRectLinkIfNeeded()
    }
    if Thread.isMainThread {
      apply()
    } else {
      DispatchQueue.main.async(execute: apply)
    }
  }

  private func startRectLinkIfNeeded() {
    guard rectLink == nil else { return }
    let link = CADisplayLink(target: self, selector: #selector(rectTick))
    let hz = Float(UIScreen.main.maximumFramesPerSecond)
    link.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: hz, preferred: hz)
    link.add(to: .main, forMode: .common)
    rectLink = link
  }

  @objc private func rectTick() {
    let now = CACurrentMediaTime()
    for slot in slots.values {
      guard slot.visible, !slot.view.isHidden,
            let target = slot.targetFrame else { continue }
      let age = now - slot.targetAt
      var frame = target
      if age > 0.12 {
        slot.rectVelocity = 0
      } else if age > 0.012, slot.rectVelocity != 0 {
        let step = max(-10.0, min(10.0, slot.rectVelocity * CGFloat(min(age, 0.05))))
        frame.origin.y += step
      } else {
        continue
      }
      /* Keep the rotation while moving the view; assigning `frame` on a
         transformed view would reinterpret its size as the rotated bounding
         box and corrupt the bounds. */
      let transform = slot.view.transform
      slot.view.transform = .identity
      slot.view.bounds = CGRect(origin: .zero, size: frame.size)
      slot.view.center = CGPoint(x: frame.midX, y: frame.midY)
      slot.view.transform = transform
    }
  }

  func layer(slot id: String, background: Bool) {
    DispatchQueue.main.async {
      guard let slot = self.slots[id] else { return }
      let parent = background ? self.background : self.overlay
      guard let parent = parent else { return }
      guard slot.view.superview !== parent else { return }
      /* Both parents share the WebView frame, so the view keeps its own frame
         when it moves. Re-applying `frame` here would corrupt the bounds of a
         rotated view: reading `frame` returns the rotated bounding box, and
         assigning it back resizes the layer to portrait bounds. */
      slot.view.removeFromSuperview()
      parent.addSubview(slot.view)
      if background {
        parent.bringSubviewToFront(slot.view)
      }
    }
  }

  func release(slot id: String) {
    DispatchQueue.main.async {
      guard let slot = self.slots.removeValue(forKey: id) else { return }
      if slot.pipActive || slot.pipController?.isPictureInPictureActive == true {
        slot.pipDelegate?.stoppedByApp = true
        slot.pipController?.stopPictureInPicture()
      }
      self.clearObservers(slot)
      slot.player.pause()
      slot.player.replaceCurrentItem(with: nil)
      self.clearDASH(slot)
      slot.view.removeFromSuperview()
    }
  }

  // MARK: - Picture in picture

  private let pipLock = NSLock()
  private var pipActiveCache = false

  private func setPipActiveCache(_ value: Bool) {
    pipLock.lock()
    pipActiveCache = value
    pipLock.unlock()
  }

  private func ensurePipController(_ slot: Slot) {
    guard slot.id == "main", slot.pipController == nil,
          AVPictureInPictureController.isPictureInPictureSupported() else { return }
    guard let controller = AVPictureInPictureController(playerLayer: slot.view.playerLayer) else { return }
    let delegate = PipDelegate(host: self, slotId: slot.id)
    controller.delegate = delegate
    slot.pipDelegate = delegate
    slot.pipController = controller
  }

  func pipAvailable() -> Bool {
    return AVPictureInPictureController.isPictureInPictureSupported()
  }

  /* The JS bridge calls these over the loopback HTTP server, which runs off the
     main thread while the WebView may be blocked in a synchronous request.
     Dispatch the actual PiP work asynchronously so the reply can never
     deadlock the UI thread; failures are reported through O11A1Pip.onFail. */
  func startPip(slot id: String) -> Bool {
    guard AVPictureInPictureController.isPictureInPictureSupported() else { return false }
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      guard let slot = self.slots[id], id == "main", !slot.pipActive else {
        self.pipDidFail(id, error: NSError(domain: "O11A1PiP", code: 1))
        return
      }
      self.ensurePipController(slot)
      guard let controller = slot.pipController,
            controller.isPictureInPicturePossible,
            slot.player.currentItem != nil,
            slot.playing || slot.player.rate > 0.01 else {
        self.pipDidFail(id, error: NSError(domain: "O11A1PiP", code: 2))
        return
      }
      controller.startPictureInPicture()
    }
    return true
  }

  func stopPip(slot id: String) -> Bool {
    guard AVPictureInPictureController.isPictureInPictureSupported() else { return false }
    DispatchQueue.main.async { [weak self] in
      guard let self = self, let slot = self.slots[id],
            let controller = slot.pipController,
            controller.isPictureInPictureActive || slot.pipActive else { return }
      slot.pipDelegate?.stoppedByApp = true
      controller.stopPictureInPicture()
    }
    return true
  }

  func isPipActive(slot id: String) -> Bool {
    pipLock.lock()
    defer { pipLock.unlock() }
    return pipActiveCache
  }

  fileprivate func pipDidStart(_ id: String) {
    DispatchQueue.main.async {
      guard let slot = self.slots[id] else { return }
      slot.pipActive = true
      self.setPipActiveCache(true)
      /* The system owns the video while PiP is active. Keep the inline layer in
         the hierarchy for a fast restore, but do not paint a second video over
         the feed. */
      slot.view.alpha = 0
      self.evaluateInPage("window.O11A1Pip&&O11A1Pip.onStart&&O11A1Pip.onStart()")
    }
  }

  fileprivate func pipWillRestore(_ id: String) {
    evaluateInPage("window.O11A1Pip&&O11A1Pip.onExit&&O11A1Pip.onExit('expand')")
  }

  fileprivate func pipDidStop(_ id: String, restore: Bool, byApp: Bool) {
    DispatchQueue.main.async {
      if let slot = self.slots[id] {
        slot.pipActive = false
        slot.view.alpha = 1
      }
      self.setPipActiveCache(false)
      if byApp { return }
      if restore { return }
      /* The PiP window's close button is a real stop, not a temporary hide.
         Pause natively as well so audio cannot keep running if the WebView is
         suspended while the app is in the background. */
      if let slot = self.slots[id] {
        slot.player.pause()
        slot.audioPlayer.pause()
      }
      self.evaluateInPage("window.O11A1Pip&&O11A1Pip.onExit&&O11A1Pip.onExit('close')")
    }
  }

  fileprivate func pipDidFail(_ id: String, error: Error) {
    NSLog("[O11A1] PiP failed %@", String(describing: error))
    DispatchQueue.main.async {
      if let slot = self.slots[id] {
        slot.pipActive = false
        slot.view.alpha = 1
      }
      self.setPipActiveCache(false)
      self.evaluateInPage("window.O11A1Pip&&O11A1Pip.onFail&&O11A1Pip.onFail()")
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

  /// Real transfer statistics from the AVPlayer access log. The web debug HUD
  /// samples this once a second to show the stream bitrate and the measured
  /// download speed (the appended `/api/mediaStats` used to return zeros).
  func stats(slot id: String) -> [String: Any] {
    var result: [String: Any] = ["ok": false]
    let read = { [weak self] in
      guard let self = self, let slot = self.slots[id],
            let item = slot.player.currentItem else { return }
      let event = item.accessLog()?.events.last
      let bytes = event?.numberOfBytesTransferred ?? 0
      let indicated = event?.indicatedBitrate ?? 0
      let observed = event?.observedBitrate ?? 0
      let now = CACurrentMediaTime()
      var download = 0.0
      if let previous = self.statsPrevious[id] {
        let delta = now - previous.at
        if delta > 0.08 {
          download = Double(max(0, bytes - previous.bytes)) * 8.0 / delta
        }
      }
      self.statsPrevious[id] = (bytes, now)
      let duration = item.duration.seconds
      result = [
        "ok": true,
        "bytes": bytes,
        "indicatedBitrate": indicated,
        "observedBitrate": observed,
        "downloadBps": download,
        "videoWidth": item.presentationSize.width,
        "videoHeight": item.presentationSize.height,
        "durationMs": duration.isFinite ? duration * 1000.0 : 0.0,
        "positionMs": slot.positionMs,
        "bufferedMs": slot.bufferedMs,
      ]
    }
    if Thread.isMainThread {
      read()
    } else {
      DispatchQueue.main.sync(execute: read)
    }
    return result
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
        guard !slot.seeking else { return }
        switch player.timeControlStatus {
        case .playing:
          if slot.dashAudio {
            self.startDASHAudio(slot)
          }
          if !slot.playing {
            slot.playing = true
            NSLog("[O11A1] playing %@", slot.id)
            self.emit(slot, "playing", self.timePayload(slot))
          }
        case .paused:
          if slot.playing {
            slot.playing = false
            self.emit(slot, "pause", self.timePayload(slot))
          }
          /* The PiP window controls AVPlayer directly; keep the separate DASH
             audio player in lockstep when the system pauses the video. */
          slot.audioPlayer.pause()
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
      guard let self = self, let slot = slot, !slot.seeking else { return }
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
      if slot.loop {
        slot.player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
          if slot.pendingPlay {
            slot.player.play()
            slot.audioPlayer.play()
          }
        }
        return
      }
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
