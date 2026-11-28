import AVFoundation
import AVKit
import QuartzCore
import UIKit

struct VideoLoadStatus {
  enum Phase {
    case connecting
    case buffering
    case playing
    case idle
  }

  var phase: Phase
  var bytesPerSecond: Double

  var isActive: Bool {
    phase == .connecting || phase == .buffering
  }
}

final class VideoEngine: NSObject {
  let player = AVPlayer()
  let playerLayer: AVPlayerLayer
  private let traceName: String
  private var installStartedAt: TimeInterval = 0
  private var loggedPlaying = false

  var onTime: ((Double, Double) -> Void)?
  var onPlaying: ((Bool) -> Void)?
  var onReady: (() -> Void)?
  var onError: ((String) -> Void)?
  var onLoadStatus: ((VideoLoadStatus) -> Void)?
  var onPipStart: (() -> Void)?
  var onPipClose: (() -> Void)?
  var onPipRestore: (() -> Void)?

  private var timeObserver: Any?
  private var statusObservation: NSKeyValueObservation?
  private var bufferObservation: NSKeyValueObservation?
  private var keepUpObservation: NSKeyValueObservation?
  private var rateObservation: NSKeyValueObservation?
  private var lastBufferEmpty: Bool?
  private var lastKeepUp: Bool?
  private var endObserver: NSObjectProtocol?
  private var backgroundObserver: NSObjectProtocol?
  private var pipController: AVPictureInPictureController?
  private var pipDelegate: PictureInPictureDelegate?
  private var restoringProgrammatically = false
  private var loadedURL = ""
  private var backupURL = ""
  private var didRetryBackup = false
  private var loop = false
  private var shouldAutoplay = false
  private var startAt: Double = 0
  private var headers: [String: String] = [:]
  private var restoringFromPip = false
  private var loadPhase: VideoLoadStatus.Phase = .idle
  private var speedTimer: Timer?
  private var lastBytes: Double = 0
  private var hasBytesSample = false
  private var lastSpeedSample: CFTimeInterval = 0
  private var smoothedSpeed: Double = 0

  init(name: String = "engine") {
    traceName = name
    playerLayer = AVPlayerLayer(player: player)
    playerLayer.videoGravity = .resizeAspect
    super.init()
    player.actionAtItemEnd = .none
    addPeriodicObserver()
    backgroundObserver = NotificationCenter.default.addObserver(
      forName: UIApplication.didEnterBackgroundNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.startPipIfPossible()
    }
  }

  deinit {
    if let observer = timeObserver {
      player.removeTimeObserver(observer)
    }
    if let observer = endObserver {
      NotificationCenter.default.removeObserver(observer)
    }
    if let observer = backgroundObserver {
      NotificationCenter.default.removeObserver(observer)
    }
    statusObservation?.invalidate()
    bufferObservation?.invalidate()
    keepUpObservation?.invalidate()
    rateObservation?.invalidate()
    speedTimer?.invalidate()
  }

  var isPlaying: Bool {
    return player.timeControlStatus == .playing
  }

  var currentTime: Double {
    let value = player.currentTime().seconds
    return value.isFinite ? value : 0
  }

  var duration: Double {
    let value = player.currentItem?.duration.seconds ?? 0
    return value.isFinite ? value : 0
  }

  var videoAspect: CGFloat {
    guard let size = player.currentItem?.presentationSize,
          size.width > 1, size.height > 1 else {
      return 16.0 / 9.0
    }
    return size.width / size.height
  }

  func load(
    url: String,
    backup: String = "",
    headers: [String: String],
    autoplay: Bool,
    muted: Bool,
    loop: Bool,
    startAt: Double = 0
  ) {
    self.headers = headers
    self.loop = loop
    self.shouldAutoplay = autoplay
    self.startAt = max(0, startAt)
    self.loadedURL = url
    self.backupURL = backup
    self.didRetryBackup = false
    player.isMuted = muted
    install(url: url)
  }

  private func install(url: String) {
    guard let mediaURL = URL(string: url), !url.isEmpty else {
      onError?("播放地址为空")
      return
    }
    statusObservation?.invalidate()
    bufferObservation?.invalidate()
    keepUpObservation?.invalidate()
    if let observer = endObserver {
      NotificationCenter.default.removeObserver(observer)
      endObserver = nil
    }
    resetSpeed()
    publish(.connecting)
    installStartedAt = O11A1Trace.now
    loggedPlaying = false
    lastBufferEmpty = nil
    lastKeepUp = nil
    O11A1Trace.mark("media", "\(traceName) install host=\(mediaURL.host ?? "?") startAt=\(String(format: "%.1f", startAt))")
    let asset = AVURLAsset(url: mediaURL, options: [
      "AVURLAssetHTTPHeaderFieldsKey": headers,
      "AVURLAssetAllowsExpensiveNetworkAccess": true,
      "AVURLAssetAllowsConstrainedNetworkAccess": true,
    ])
    let item = AVPlayerItem(asset: asset)
    item.preferredForwardBufferDuration = 0.5
    player.automaticallyWaitsToMinimizeStalling = false
    statusObservation = item.observe(\.status, options: [.new, .initial]) { [weak self] observed, _ in
      guard let self = self else { return }
      if observed.status == .readyToPlay {
        O11A1Trace.mark(
          "media",
          "\(self.traceName) ready duration=\(String(format: "%.1f", observed.duration.seconds)) \(O11A1Trace.since(self.installStartedAt))")
        if let event = observed.accessLog()?.events.last {
          O11A1Trace.mark(
            "media",
            "\(self.traceName) accessLog bytes=\(event.numberOfBytesTransferred) bitrate=\(Int(event.observedBitrate)) server=\(event.serverAddress ?? "-")")
        }
        DispatchQueue.main.async {
          self.publish(.buffering)
          var start = self.startAt
          let duration = observed.duration.seconds
          if duration.isFinite, duration > 0 {
            start = min(start, max(0, duration - 0.5))
          }
          self.startAt = 0
          let finish = {
            guard self.player.currentItem === item else { return }
            self.onReady?()
            if self.shouldAutoplay {
              self.player.play()
            }
          }
          if start > 0 {
            self.player.seek(
              to: CMTime(seconds: start, preferredTimescale: 600),
              toleranceBefore: CMTime(seconds: 0.3, preferredTimescale: 600),
              toleranceAfter: CMTime(seconds: 0.3, preferredTimescale: 600)
            ) { _ in
              DispatchQueue.main.async(execute: finish)
            }
          } else {
            finish()
          }
        }
      } else if observed.status == .failed {
        O11A1Trace.mark(
          "media",
          "\(self.traceName) failed \(O11A1Trace.since(self.installStartedAt)) \(observed.error?.localizedDescription ?? "?")")
        DispatchQueue.main.async {
          self.publish(.idle)
          if !self.didRetryBackup, !self.backupURL.isEmpty, self.backupURL != self.loadedURL {
            self.didRetryBackup = true
            self.install(url: self.backupURL)
          } else {
            self.onError?(observed.error?.localizedDescription ?? "播放失败")
          }
        }
      }
    }
    bufferObservation = item.observe(\.isPlaybackBufferEmpty, options: [.new]) {
      [weak self] observed, _ in
      DispatchQueue.main.async {
        guard let self = self, let current = self.player.currentItem,
              current === observed else { return }
        let empty = observed.isPlaybackBufferEmpty
        guard empty != self.lastBufferEmpty else { return }
        self.lastBufferEmpty = empty
        O11A1Trace.mark(
          "media",
          "\(self.traceName) bufferEmpty=\(empty) \(O11A1Trace.since(self.installStartedAt))")
      }
    }
    keepUpObservation = item.observe(\.isPlaybackLikelyToKeepUp, options: [.new]) {
      [weak self] observed, _ in
      DispatchQueue.main.async {
        guard let self = self, let current = self.player.currentItem,
              current === observed else { return }
        let keepUp = observed.isPlaybackLikelyToKeepUp
        guard keepUp != self.lastKeepUp else { return }
        self.lastKeepUp = keepUp
        O11A1Trace.mark(
          "media",
          "\(self.traceName) keepUp=\(keepUp) \(O11A1Trace.since(self.installStartedAt))")
      }
    }
    endObserver = NotificationCenter.default.addObserver(
      forName: .AVPlayerItemDidPlayToEndTime,
      object: item,
      queue: .main
    ) { [weak self] _ in
      guard let self = self, self.loop else { return }
      self.player.seek(to: .zero)
      self.player.play()
    }
    player.replaceCurrentItem(with: item)
    player.playImmediately(atRate: 1)
    player.isMuted = player.isMuted
    if !shouldAutoplay {
      player.pause()
    }
  }

  private func addPeriodicObserver() {
    let interval = CMTime(seconds: 0.25, preferredTimescale: 600)
    timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
      guard let self = self else { return }
      let seconds = time.seconds.isFinite ? time.seconds : 0
      self.onTime?(seconds, self.duration)
      self.onPlaying?(self.player.timeControlStatus == .playing)
    }
    rateObservation = player.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
      DispatchQueue.main.async {
        guard let self = self else { return }
        if player.timeControlStatus == .playing,
           player.currentItem?.status == .readyToPlay,
           !self.loggedPlaying {
          self.loggedPlaying = true
          O11A1Trace.mark(
            "media",
            "\(self.traceName) playbackStarted \(O11A1Trace.since(self.installStartedAt))")
        }
        self.onPlaying?(player.timeControlStatus == .playing)
        self.refreshLoadPhase()
      }
    }
  }

  func refreshLoadStatus() {
    refreshLoadPhase()
  }

  private func refreshLoadPhase() {
    guard let item = player.currentItem else {
      if loadPhase != .idle { publish(.idle) }
      return
    }
    switch player.timeControlStatus {
    case .playing:
      if loadPhase != .playing { publish(.playing) }
    case .waitingToPlayAtSpecifiedRate:
      publish(item.status == .readyToPlay ? .buffering : .connecting)
    case .paused:
      if item.status != .readyToPlay {
        if loadPhase != .connecting { publish(.connecting) }
      } else if loadPhase == .buffering || loadPhase == .connecting {
        publish(.idle)
      }
    @unknown default:
      break
    }
  }

  private func publish(_ phase: VideoLoadStatus.Phase) {
    loadPhase = phase
    if phase == .buffering {
      startSpeedTimer()
    } else {
      stopSpeedTimer()
    }
    let speed = phase == .buffering ? smoothedSpeed : 0
    onLoadStatus?(VideoLoadStatus(phase: phase, bytesPerSecond: speed))
  }

  private func resetSpeed() {
    stopSpeedTimer()
    lastBytes = 0
    hasBytesSample = false
    lastSpeedSample = 0
    smoothedSpeed = 0
  }

  private func startSpeedTimer() {
    guard speedTimer == nil else { return }
    let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
      self?.sampleSpeed()
    }
    RunLoop.main.add(timer, forMode: .common)
    speedTimer = timer
    sampleSpeed()
  }

  private func stopSpeedTimer() {
    speedTimer?.invalidate()
    speedTimer = nil
  }

  private func sampleSpeed() {
    guard loadPhase == .buffering, let item = player.currentItem else { return }
    let now = CACurrentMediaTime()
    var instant: Double = 0
    if let event = item.accessLog()?.events.last {
      let bytes = Double(event.numberOfBytesTransferred)
      if bytes > 0 {
        if hasBytesSample, now > lastSpeedSample, bytes >= lastBytes {
          instant = (bytes - lastBytes) / (now - lastSpeedSample)
        }
        lastBytes = bytes
        hasBytesSample = true
      }
      if instant <= 0, event.observedBitrate > 0 {
        instant = Double(event.observedBitrate) / 8.0
      }
    }
    lastSpeedSample = now
    if instant > 0 {
      smoothedSpeed = smoothedSpeed > 0
        ? smoothedSpeed * 0.62 + instant * 0.38
        : instant
    }
    onLoadStatus?(VideoLoadStatus(phase: loadPhase, bytesPerSecond: smoothedSpeed))
  }

  func play() {
    player.play()
  }

  func pause() {
    player.pause()
  }

  func toggle() {
    if isPlaying { pause() } else { play() }
  }

  func seek(to seconds: Double, resume: Bool = true, completion: (() -> Void)? = nil) {
    let target = CMTime(seconds: max(0, seconds), preferredTimescale: 600)
    let wasPlaying = isPlaying || player.rate > 0.01
    player.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
      guard let self = self else {
        completion?()
        return
      }
      if resume, wasPlaying {
        self.player.play()
      }
      completion?()
    }
  }

  func setRate(_ rate: Float) {
    if player.timeControlStatus == .playing || player.rate > 0.01 {
      player.rate = max(0.1, min(4.0, rate))
    }
  }

  func setLoop(_ value: Bool) {
    loop = value
  }

  func setMuted(_ muted: Bool) {
    player.isMuted = muted
  }

  func enablePiP() {
    guard AVPictureInPictureController.isPictureInPictureSupported(),
          pipController == nil else { return }
    guard let controller = AVPictureInPictureController(playerLayer: playerLayer) else { return }
    let delegate = PictureInPictureDelegate(engine: self)
    controller.delegate = delegate
    controller.canStartPictureInPictureAutomaticallyFromInline = true
    pipController = controller
    pipDelegate = delegate
  }

  func startPipIfPossible() {
    startPipNow()
  }

  @discardableResult
  func startPipNow(requirePlaying: Bool = true) -> Bool {
    guard let controller = pipController,
          !requirePlaying || isPlaying,
          !controller.isPictureInPictureActive,
          controller.isPictureInPicturePossible else { return false }
    controller.startPictureInPicture()
    return true
  }

  var isPipActive: Bool {
    return pipController?.isPictureInPictureActive ?? false
  }

  func stopPipForRestore() {
    guard let controller = pipController, controller.isPictureInPictureActive else { return }
    restoringProgrammatically = true
    controller.stopPictureInPicture()
  }

  func stopPip() {
    guard let controller = pipController, controller.isPictureInPictureActive else { return }
    controller.stopPictureInPicture()
  }

  func stop() {
    player.pause()
    player.replaceCurrentItem(with: nil)
    shouldAutoplay = false
    resetSpeed()
    publish(.idle)
  }

  fileprivate func pipWillRestore() {
    restoringFromPip = true
    onPipRestore?()
  }

  fileprivate func pipDidStop() {
    if restoringProgrammatically {
      restoringProgrammatically = false
      onPipRestore?()
      return
    }
    let restoring = restoringFromPip
    restoringFromPip = false
    if restoring {
      onPipRestore?()
      return
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
      self?.onPipClose?()
    }
  }

  fileprivate func pipDidStart() {
    onPipStart?()
  }

  fileprivate func pipFailed(_ message: String) {
    onError?(message)
  }
}

private final class PictureInPictureDelegate: NSObject, AVPictureInPictureControllerDelegate {
  weak var engine: VideoEngine?

  init(engine: VideoEngine) {
    self.engine = engine
  }

  func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
    engine?.pipDidStart()
  }

  func pictureInPictureController(
    _ pictureInPictureController: AVPictureInPictureController,
    failedToStartPictureInPictureWithError error: Error
  ) {
    engine?.pipFailed(error.localizedDescription)
  }

  func pictureInPictureController(
    _ pictureInPictureController: AVPictureInPictureController,
    restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
  ) {
    engine?.pipWillRestore()
    completionHandler(true)
  }

  func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
    engine?.pipDidStop()
  }
}
