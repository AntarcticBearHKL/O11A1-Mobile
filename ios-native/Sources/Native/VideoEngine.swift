import AVFoundation
import AVKit
import UIKit

final class VideoEngine: NSObject {
  let player = AVPlayer()
  let playerLayer: AVPlayerLayer

  var onTime: ((Double, Double) -> Void)?
  var onPlaying: ((Bool) -> Void)?
  var onReady: (() -> Void)?
  var onError: ((String) -> Void)?
  var onPipClose: (() -> Void)?
  var onPipRestore: (() -> Void)?

  private var timeObserver: Any?
  private var statusObservation: NSKeyValueObservation?
  private var rateObservation: NSKeyValueObservation?
  private var endObserver: NSObjectProtocol?
  private var backgroundObserver: NSObjectProtocol?
  private var pipController: AVPictureInPictureController?
  private var pipDelegate: PictureInPictureDelegate?
  private var loadedURL = ""
  private var backupURL = ""
  private var didRetryBackup = false
  private var loop = false
  private var shouldAutoplay = false
  private var startAt: Double = 0
  private var headers: [String: String] = [:]
  private var restoringFromPip = false

  override init() {
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
    rateObservation?.invalidate()
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
    if let observer = endObserver {
      NotificationCenter.default.removeObserver(observer)
      endObserver = nil
    }
    let asset = AVURLAsset(url: mediaURL, options: [
      "AVURLAssetHTTPHeaderFieldsKey": headers,
      "AVURLAssetAllowsExpensiveNetworkAccess": true,
      "AVURLAssetAllowsConstrainedNetworkAccess": true,
    ])
    NSLog("[O11A1] media install %@", mediaURL.host ?? "?")
    let item = AVPlayerItem(asset: asset)
    item.preferredForwardBufferDuration = 8
    statusObservation = item.observe(\.status, options: [.new, .initial]) { [weak self] observed, _ in
      guard let self = self else { return }
      if observed.status == .readyToPlay {
        NSLog("[O11A1] media ready duration=%.1f", observed.duration.seconds)
        DispatchQueue.main.async {
          self.onReady?()
          if self.startAt > 0 {
            self.player.seek(
              to: CMTime(seconds: self.startAt, preferredTimescale: 600),
              toleranceBefore: .zero,
              toleranceAfter: .zero
            )
            self.startAt = 0
          }
          if self.shouldAutoplay {
            self.player.play()
          }
        }
      } else if observed.status == .failed {
        NSLog("[O11A1] media failed %@", observed.error?.localizedDescription ?? "?")
        DispatchQueue.main.async {
          if !self.didRetryBackup, !self.backupURL.isEmpty, self.backupURL != self.loadedURL {
            self.didRetryBackup = true
            self.install(url: self.backupURL)
          } else {
            self.onError?(observed.error?.localizedDescription ?? "播放失败")
          }
        }
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
        self?.onPlaying?(player.timeControlStatus == .playing)
      }
    }
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

  func seek(to seconds: Double, resume: Bool = true) {
    let target = CMTime(seconds: max(0, seconds), preferredTimescale: 600)
    let wasPlaying = isPlaying || player.rate > 0.01
    player.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
      guard let self = self, resume, wasPlaying else { return }
      self.player.play()
    }
  }

  func setRate(_ rate: Float) {
    if player.timeControlStatus == .playing || player.rate > 0.01 {
      player.rate = max(0.1, min(4.0, rate))
    }
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
    guard let controller = pipController else { return }
    guard isPlaying, !controller.isPictureInPictureActive else { return }
    guard controller.isPictureInPicturePossible else { return }
    controller.startPictureInPicture()
  }

  func stopPip() {
    guard let controller = pipController, controller.isPictureInPictureActive else { return }
    controller.stopPictureInPicture()
  }

  func stop() {
    player.pause()
    player.replaceCurrentItem(with: nil)
    shouldAutoplay = false
  }

  fileprivate func pipWillRestore() {
    restoringFromPip = true
    onPipRestore?()
  }

  fileprivate func pipDidStop() {
    let restoring = restoringFromPip
    restoringFromPip = false
    if !restoring {
      onPipClose?()
    }
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
    // The system owns the video window; the app is now in the background.
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
