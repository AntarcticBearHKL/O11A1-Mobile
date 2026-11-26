import AVKit
import UIKit

final class PlayerViewController: UIViewController, UIGestureRecognizerDelegate {
  var item: VideoItem
  var onClose: (() -> Void)?
  var onProfile: ((Int64) -> Void)?

  private let engine = VideoEngine()
  private lazy var playerView = PlayerLayerView(playerLayer: engine.playerLayer)
  private let speedFeedback = UIImpactFeedbackGenerator(style: .medium)
  private let backdrop = UIImageView()
  private let backdropVideo = UIView()
  private lazy var backdropLayer: AVPlayerLayer = {
    let layer = AVPlayerLayer(player: engine.player)
    layer.videoGravity = .resizeAspectFill
    return layer
  }()
  private let backdropBlur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
  private let backdropDim = UIView()
  private let videoContainer = UIView()
  private let poster = UIImageView()
  private let pausedVeil = UIView()
  private let pausedGradient = CAGradientLayer()
  private let dim = UIView()
  private let topBar = UIView()
  private let backButton = UIButton(type: .system)
  private let titleLabel = UILabel()
  private let playButton = UIButton(type: .system)
  private let longPressHost = UIView()
  private let bottomPanel = UIView()
  private let bottomBlur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
  private let ownerLabel = UILabel()
  private let ownerButton = UIButton(type: .system)
  private let wheel = ProgressWheel()
  private let grid = GridProgressBar()
  private let seekBubble = UILabel()
  private let qualityLabel = UILabel()
  private let speedLabel = UILabel()
  private let commentsButton = UIButton(type: .system)
  private let likeButton = UIButton(type: .system)
  private let coinButton = UIButton(type: .system)
  private let favButton = UIButton(type: .system)
  private let followButton = UIButton(type: .system)
  private let danmakuToggle = UIButton(type: .system)
  private let danmakuSend = UIButton(type: .system)
  private let danmakuOverlay = DanmakuOverlayView()
  private let liveChat = LiveChatView()
  private let liveSocket = LiveChatSocket()
  private let errorLabel = UILabel()
  private var liveMessages: [LiveMessage] = []
  private var activeObserver: NSObjectProtocol?
  private var sourceFrame: CGRect = .zero
  private var panStartFrame: CGRect = .zero
  private var isScrubbing = false
  private var wasPlayingBeforeScrub = false
  private var panProgress: CGFloat = 0
  private var closing = false
  private var currentQuality = 80
  private var loadToken = 0
  private var started = false
  private var speedIndex = 0
  private var relatedSwipe = false
  private var detailSwipe = false
  private var portraitDismissDrag = false
  private var portraitUpDrag = false
  private var portraitRestoreDrag = false
  private var portraitDragActive = false
  private var portraitSettling = false
  private var portraitShrinking = false
  private var portraitTransition: CGFloat = 0
  private var portraitStageIsTop = false
  private var panDirectionDecided = false
  private var detailPanel: VideoDetailViewController?
  private var relatedPanel: RelatedViewController?
  private var settingsPanel: PlayerSettingsViewController?
  private var portraitComments: CommentsPanelViewController?
  private var isLandscapePlayer = false
  private var loopOn = false
  private var controlsVisible = true
  private var controlsTimer: Timer?
  private var lastPlayingState = false

  init(item: VideoItem, sourceView: UIView?) {
    self.item = item
    super.init(nibName: nil, bundle: nil)
    modalPresentationStyle = .overFullScreen
    if let sourceView = sourceView, let window = sourceView.window {
      sourceFrame = sourceView.convert(sourceView.bounds, to: window)
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    return .allButUpsideDown
  }

  override var prefersStatusBarHidden: Bool { false }
  override var preferredStatusBarStyle: UIStatusBarStyle {
    if relatedPanel != nil || detailPanel != nil || settingsPanel != nil {
      return traitCollection.userInterfaceStyle == .dark ? .lightContent : .darkContent
    }
    return .lightContent
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .black
    view.clipsToBounds = true

    backdrop.contentMode = .scaleAspectFill
    backdrop.clipsToBounds = true
    backdrop.backgroundColor = .black
    ImageLoader.shared.load(item.pic, into: backdrop)
    view.addSubview(backdrop)

    backdropVideo.backgroundColor = .black
    backdropVideo.alpha = 0
    backdropVideo.isUserInteractionEnabled = false
    backdropVideo.layer.addSublayer(backdropLayer)
    view.addSubview(backdropVideo)

    backdropBlur.isUserInteractionEnabled = false
    view.addSubview(backdropBlur)

    backdropDim.backgroundColor = UIColor.black.withAlphaComponent(0.42)
    backdropDim.isUserInteractionEnabled = false
    view.addSubview(backdropDim)

    videoContainer.backgroundColor = .black
    videoContainer.clipsToBounds = true
    view.addSubview(videoContainer)

    poster.contentMode = .scaleAspectFill
    poster.clipsToBounds = true
    poster.backgroundColor = .black
    ImageLoader.shared.load(item.pic, into: poster)
    videoContainer.addSubview(poster)

    playerView.backgroundColor = .clear
    videoContainer.addSubview(playerView)

    pausedVeil.isUserInteractionEnabled = false
    pausedVeil.isHidden = true
    pausedGradient.type = .radial
    pausedGradient.colors = [
      UIColor(red: 1, green: 110.0 / 255.0, blue: 110.0 / 255.0, alpha: 0).cgColor,
      UIColor(red: 1, green: 110.0 / 255.0, blue: 110.0 / 255.0, alpha: 0.045).cgColor,
      UIColor(red: 1, green: 95.0 / 255.0, blue: 95.0 / 255.0, alpha: 0.10).cgColor,
    ]
    pausedGradient.locations = [0.35, 0.78, 1]
    pausedGradient.startPoint = CGPoint(x: 0.5, y: 0.5)
    pausedGradient.endPoint = CGPoint(x: 1, y: 1)
    pausedVeil.layer.addSublayer(pausedGradient)
    videoContainer.addSubview(pausedVeil)

    dim.backgroundColor = UIColor.black.withAlphaComponent(0.18)
    dim.isUserInteractionEnabled = false
    view.addSubview(dim)

    topBar.backgroundColor = .clear
    view.addSubview(topBar)

    backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
    backButton.tintColor = .white
    backButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
    topBar.addSubview(backButton)

    titleLabel.text = item.title
    titleLabel.font = NativeTheme.titleFont(15)
    titleLabel.textColor = .white
    titleLabel.numberOfLines = 1
    titleLabel.lineBreakMode = .byTruncatingTail
    topBar.addSubview(titleLabel)

    followButton.setTitle("关注", for: .normal)
    followButton.setTitleColor(.white, for: .normal)
    followButton.titleLabel?.font = NativeTheme.bodyFont(12)
    followButton.backgroundColor = UIColor.white.withAlphaComponent(0.18)
    followButton.layer.cornerRadius = NativeTheme.cornerRadius
    followButton.layer.cornerCurve = .continuous
    followButton.addTarget(self, action: #selector(followTapped), for: .touchUpInside)
    topBar.addSubview(followButton)

    playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
    playButton.tintColor = .white
    playButton.backgroundColor = UIColor.black.withAlphaComponent(0.30)
    playButton.layer.cornerRadius = 32
    playButton.addTarget(self, action: #selector(togglePlay), for: .touchUpInside)
    view.addSubview(playButton)

    bottomPanel.layer.cornerRadius = NativeTheme.cornerRadius
    bottomPanel.layer.cornerCurve = .continuous
    bottomPanel.clipsToBounds = true
    bottomPanel.layer.borderWidth = 1
    view.addSubview(bottomPanel)

    seekBubble.textAlignment = .center
    seekBubble.font = NativeTheme.numberFont(9)
    seekBubble.textColor = .white
    seekBubble.backgroundColor = UIColor(red: 10.0 / 255.0, green: 13.0 / 255.0,
                                         blue: 19.0 / 255.0, alpha: 0.94)
    seekBubble.layer.cornerRadius = NativeTheme.cornerRadius
    seekBubble.layer.cornerCurve = .continuous
    seekBubble.layer.borderWidth = 1
    seekBubble.layer.borderColor = UIColor(white: 1, alpha: 0.13).cgColor
    seekBubble.clipsToBounds = true
    seekBubble.isHidden = true
    view.addSubview(seekBubble)

    bottomBlur.translatesAutoresizingMaskIntoConstraints = false
    bottomBlur.isUserInteractionEnabled = false
    bottomBlur.alpha = 0.55
    bottomPanel.addSubview(bottomBlur)
    applyPlayerChrome()
    NSLayoutConstraint.activate([
      bottomBlur.leadingAnchor.constraint(equalTo: bottomPanel.leadingAnchor),
      bottomBlur.trailingAnchor.constraint(equalTo: bottomPanel.trailingAnchor),
      bottomBlur.topAnchor.constraint(equalTo: bottomPanel.topAnchor),
      bottomBlur.bottomAnchor.constraint(equalTo: bottomPanel.bottomAnchor),
    ])

    let content = bottomPanel
    ownerLabel.text = item.owner
    ownerLabel.font = NativeTheme.bodyFont(13)
    ownerLabel.textColor = .white
    ownerLabel.numberOfLines = 1
    content.addSubview(ownerLabel)

    ownerButton.setTitle("UP 主页", for: .normal)
    ownerButton.setTitleColor(UIColor.white.withAlphaComponent(0.66), for: .normal)
    ownerButton.titleLabel?.font = NativeTheme.bodyFont(11)
    ownerButton.addTarget(self, action: #selector(openProfile), for: .touchUpInside)
    content.addSubview(ownerButton)

    wheel.onScrub = { [weak self] ratio, finished in
      guard let self = self else { return }
      self.showControls()
      self.scrub(ratio: ratio, finished: finished)
      if finished { self.scheduleControlsHide() }
    }
    content.addSubview(wheel)

    content.addSubview(grid)

    qualityLabel.font = NativeTheme.numberFont(10)
    qualityLabel.textColor = UIColor.white.withAlphaComponent(0.70)
    qualityLabel.textAlignment = .right
    qualityLabel.text = "720P"
    qualityLabel.isUserInteractionEnabled = true
    qualityLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cycleQuality)))
    content.addSubview(qualityLabel)

    speedLabel.font = NativeTheme.numberFont(10)
    speedLabel.textColor = UIColor.white.withAlphaComponent(0.70)
    speedLabel.textAlignment = .right
    speedLabel.text = "1.0x"
    speedLabel.isUserInteractionEnabled = true
    speedLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cycleSpeed)))
    content.addSubview(speedLabel)

    danmakuToggle.setTitle("弹", for: .normal)
    danmakuToggle.setTitleColor(.white, for: .normal)
    danmakuToggle.titleLabel?.font = NativeTheme.numberFont(11)
    danmakuToggle.addTarget(self, action: #selector(toggleDanmaku), for: .touchUpInside)
    topBar.addSubview(danmakuToggle)

    danmakuSend.setTitle("＋弹", for: .normal)
    danmakuSend.setTitleColor(.white, for: .normal)
    danmakuSend.titleLabel?.font = NativeTheme.numberFont(10)
    danmakuSend.addTarget(self, action: #selector(sendDanmakuTapped), for: .touchUpInside)
    topBar.addSubview(danmakuSend)

    commentsButton.setImage(UIImage(systemName: "text.bubble"), for: .normal)
    commentsButton.tintColor = .white
    commentsButton.addTarget(self, action: #selector(openComments), for: .touchUpInside)
    content.addSubview(commentsButton)

    likeButton.setImage(UIImage(systemName: "hand.thumbsup"), for: .normal)
    likeButton.tintColor = .white
    likeButton.addTarget(self, action: #selector(like), for: .touchUpInside)
    content.addSubview(likeButton)

    coinButton.setImage(UIImage(systemName: "circle.grid.2x1"), for: .normal)
    coinButton.tintColor = .white
    coinButton.addTarget(self, action: #selector(coin), for: .touchUpInside)
    content.addSubview(coinButton)

    favButton.setImage(UIImage(systemName: "star"), for: .normal)
    favButton.tintColor = .white
    favButton.addTarget(self, action: #selector(favorite), for: .touchUpInside)
    content.addSubview(favButton)

    danmakuOverlay.backgroundColor = .clear
    danmakuOverlay.isUserInteractionEnabled = false
    view.addSubview(danmakuOverlay)

    liveChat.isHidden = true
    videoContainer.addSubview(liveChat)
    liveChat.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      liveChat.leadingAnchor.constraint(equalTo: videoContainer.leadingAnchor, constant: 14),
      liveChat.widthAnchor.constraint(equalTo: videoContainer.widthAnchor, multiplier: 0.72),
      liveChat.bottomAnchor.constraint(equalTo: videoContainer.bottomAnchor, constant: -190),
      liveChat.heightAnchor.constraint(equalToConstant: 150),
    ])

    errorLabel.font = NativeTheme.bodyFont(13)
    errorLabel.textColor = NativeTheme.pipRose
    errorLabel.numberOfLines = 0
    errorLabel.textAlignment = .center
    errorLabel.isHidden = true
    view.addSubview(errorLabel)

    [backButton, titleLabel, playButton, ownerLabel, ownerButton, wheel, grid,
     qualityLabel, speedLabel, commentsButton, likeButton, coinButton, favButton,
     followButton, danmakuToggle, danmakuSend, errorLabel].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
    }

    NSLayoutConstraint.activate([
      backButton.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 8),
      backButton.topAnchor.constraint(equalTo: topBar.topAnchor, constant: 4),
      backButton.widthAnchor.constraint(equalToConstant: 44),
      backButton.heightAnchor.constraint(equalToConstant: 44),

      titleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 4),
      titleLabel.trailingAnchor.constraint(equalTo: danmakuSend.leadingAnchor, constant: -4),
      titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),

      followButton.trailingAnchor.constraint(equalTo: topBar.trailingAnchor, constant: -12),
      followButton.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
      followButton.widthAnchor.constraint(equalToConstant: 54),
      followButton.heightAnchor.constraint(equalToConstant: 30),

      danmakuToggle.trailingAnchor.constraint(equalTo: followButton.leadingAnchor, constant: -8),
      danmakuToggle.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
      danmakuToggle.widthAnchor.constraint(equalToConstant: 28),
      danmakuToggle.heightAnchor.constraint(equalToConstant: 30),

      danmakuSend.trailingAnchor.constraint(equalTo: danmakuToggle.leadingAnchor, constant: -2),
      danmakuSend.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
      danmakuSend.widthAnchor.constraint(equalToConstant: 34),
      danmakuSend.heightAnchor.constraint(equalToConstant: 30),

      playButton.widthAnchor.constraint(equalToConstant: 64),
      playButton.heightAnchor.constraint(equalToConstant: 64),

      ownerLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 16),
      ownerLabel.topAnchor.constraint(equalTo: content.topAnchor, constant: 12),
      ownerLabel.trailingAnchor.constraint(lessThanOrEqualTo: ownerButton.leadingAnchor, constant: -8),

      ownerButton.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -14),
      ownerButton.centerYAnchor.constraint(equalTo: ownerLabel.centerYAnchor),

      wheel.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 8),
      wheel.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -8),
      wheel.topAnchor.constraint(equalTo: content.topAnchor, constant: 44),
      wheel.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -12),

      grid.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 14),
      grid.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -14),
      grid.topAnchor.constraint(equalTo: content.topAnchor, constant: 12),
      grid.heightAnchor.constraint(equalToConstant: 14),

      qualityLabel.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -16),
      qualityLabel.topAnchor.constraint(equalTo: wheel.bottomAnchor, constant: 2),
      qualityLabel.widthAnchor.constraint(equalToConstant: 56),

      speedLabel.trailingAnchor.constraint(equalTo: qualityLabel.leadingAnchor, constant: -8),
      speedLabel.topAnchor.constraint(equalTo: wheel.bottomAnchor, constant: 2),
      speedLabel.widthAnchor.constraint(equalToConstant: 40),

      commentsButton.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 18),
      commentsButton.topAnchor.constraint(equalTo: wheel.bottomAnchor, constant: 4),
      commentsButton.widthAnchor.constraint(equalToConstant: 34),
      commentsButton.heightAnchor.constraint(equalToConstant: 34),

      likeButton.leadingAnchor.constraint(equalTo: commentsButton.trailingAnchor, constant: 18),
      likeButton.centerYAnchor.constraint(equalTo: commentsButton.centerYAnchor),
      likeButton.widthAnchor.constraint(equalToConstant: 34),
      likeButton.heightAnchor.constraint(equalToConstant: 34),

      coinButton.leadingAnchor.constraint(equalTo: likeButton.trailingAnchor, constant: 18),
      coinButton.centerYAnchor.constraint(equalTo: commentsButton.centerYAnchor),
      coinButton.widthAnchor.constraint(equalToConstant: 34),
      coinButton.heightAnchor.constraint(equalToConstant: 34),

      favButton.leadingAnchor.constraint(equalTo: coinButton.trailingAnchor, constant: 18),
      favButton.centerYAnchor.constraint(equalTo: commentsButton.centerYAnchor),
      favButton.widthAnchor.constraint(equalToConstant: 34),
      favButton.heightAnchor.constraint(equalToConstant: 34),
      favButton.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -10),

      errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
      errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
      errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 80),
    ])

    let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
    pan.delegate = self
    view.addGestureRecognizer(pan)

    longPressHost.backgroundColor = .clear
    view.insertSubview(longPressHost, belowSubview: bottomPanel)
    longPressHost.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      longPressHost.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      longPressHost.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      longPressHost.topAnchor.constraint(equalTo: view.topAnchor),
      longPressHost.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
    longPress.minimumPressDuration = 0.18
    longPress.delegate = self
    longPress.cancelsTouchesInView = false
    longPressHost.addGestureRecognizer(longPress)

    let tap = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap))
    tap.delegate = self
    tap.cancelsTouchesInView = false
    view.addGestureRecognizer(tap)

    engine.onTime = { [weak self] seconds, duration in
      guard let self = self, !self.isScrubbing else { return }
      self.danmakuOverlay.setTime(seconds)
      let safeDuration = duration > 0 ? duration : 1
      self.wheel.durationSeconds = duration
      self.wheel.progress = max(0, min(1, seconds / safeDuration))
      self.grid.progress = max(0, min(1, seconds / safeDuration))
      self.wheel.currentText = self.format(seconds)
      self.wheel.durationText = self.format(duration)
    }
    engine.onPlaying = { [weak self] playing in
      guard let self = self else { return }
      self.playButton.setImage(UIImage(systemName: playing ? "pause.fill" : "play.fill"), for: .normal)
      self.pausedVeil.isHidden = playing
      self.videoContainer.backgroundColor = playing ? .black : NativeTheme.pipRose
      let changed = playing != self.lastPlayingState
      self.lastPlayingState = playing
      if playing && changed && self.controlsVisible {
        self.scheduleControlsHide()
      }
    }
    engine.onReady = { [weak self] in
      guard let self = self else { return }
      self.poster.isHidden = true
      self.errorLabel.isHidden = true
      self.backdropVideo.alpha = 1
      self.engine.play()
    }
    engine.onError = { [weak self] message in
      guard let self = self else { return }
      self.errorLabel.text = message
      self.errorLabel.isHidden = false
    }
    engine.onPipClose = { [weak self] in
      self?.closeFromPip()
    }
    engine.onPipRestore = { [weak self] in
      self?.closing = false
      self?.videoContainer.isHidden = false
    }
    activeObserver = NotificationCenter.default.addObserver(
      forName: UIApplication.didBecomeActiveNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      guard let self = self, self.engine.isPipActive else { return }
      self.engine.stopPipForRestore()
    }

    topBar.isHidden = true
    playButton.isHidden = true
    dim.isHidden = true
    controlsVisible = false
    bottomPanel.alpha = 0
    bottomPanel.transform = CGAffineTransform(translationX: 0, y: 16)
    bottomPanel.isUserInteractionEnabled = false
    [ownerLabel, ownerButton, qualityLabel, speedLabel, commentsButton,
     likeButton, coinButton, favButton].forEach { $0.removeFromSuperview() }
    _ = ensurePortraitComments()
    speedFeedback.prepare()
    loadQuality(ThemeManager.shared.quality)
    if item.roomId == 0, item.cid > 0 {
      danmakuOverlay.load(cid: item.cid)
    } else {
      danmakuOverlay.isHidden = true
    }
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    applyPlayerChrome()
  }

  private func applyPlayerChrome() {
    let light = traitCollection.userInterfaceStyle == .light
    bottomPanel.backgroundColor = light
      ? UIColor(white: 1, alpha: 0.90)
      : UIColor(red: 29.0 / 255.0, green: 35.0 / 255.0, blue: 47.0 / 255.0, alpha: 0.84)
    bottomPanel.layer.borderColor = light
      ? UIColor(white: 0, alpha: 0.08).cgColor
      : UIColor(white: 1, alpha: 0.14).cgColor
    bottomBlur.effect = UIBlurEffect(
      style: light ? .systemUltraThinMaterialLight : .systemUltraThinMaterialDark)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    start()
  }

  func start() {
    guard !started else { return }
    started = true
    view.layoutIfNeeded()
    engine.enablePiP()
    if sourceFrame.width > 0 {
      let target = view.bounds.width > view.bounds.height
        ? view.bounds : portraitVideoRects().center
      videoContainer.frame = view.convert(sourceFrame, from: nil)
      UIView.animate(withDuration: 0.30, delay: 0, options: [.curveEaseOut]) {
        self.videoContainer.frame = target
      }
      sourceFrame = .zero
    }
  }

  private func portraitVideoRects() -> (center: CGRect, top: CGRect) {
    let full = view.bounds
    let height = full.width * 9.0 / 16.0
    let center = CGRect(x: 0, y: full.midY - height / 2 + 2,
                        width: full.width, height: height)
    let top = CGRect(x: 0, y: view.safeAreaInsets.top,
                     width: full.width, height: height)
    return (center, top)
  }

  private func lerpRect(_ a: CGRect, _ b: CGRect, _ t: CGFloat) -> CGRect {
    let p = max(0, min(1, t))
    return CGRect(
      x: a.minX + (b.minX - a.minX) * p,
      y: a.minY + (b.minY - a.minY) * p,
      width: a.width + (b.width - a.width) * p,
      height: a.height + (b.height - a.height) * p
    )
  }

  private func layoutVideoSubviews() {
    playerView.frame = videoContainer.bounds
    poster.frame = videoContainer.bounds
    pausedVeil.frame = videoContainer.bounds
    pausedGradient.frame = pausedVeil.bounds
    playButton.center = CGPoint(x: videoContainer.center.x,
                                y: videoContainer.center.y)
  }

  private func applyPortraitTransition(_ value: CGFloat) {
    guard !isLandscapePlayer else { return }
    let p = max(0, min(1, value))
    portraitTransition = p
    let full = view.bounds
    let rects = portraitVideoRects()
    let videoRect = lerpRect(rects.center, rects.top, p)
    videoContainer.frame = videoRect
    videoContainer.layer.cornerRadius = 0
    layoutVideoSubviews()
    danmakuOverlay.frame = lerpRect(full, videoRect, p)

    let panelHeight: CGFloat = 108
    let panelWidth = max(1, full.width - 24)
    let centerPanelY = full.height - panelHeight - 8
    let topPanelY = max(0, videoRect.maxY - panelHeight - 8)
    bottomPanel.frame = CGRect(
      x: 12,
      y: centerPanelY + (topPanelY - centerPanelY) * p,
      width: panelWidth,
      height: panelHeight
    )
    seekBubble.frame = CGRect(x: full.midX - 40, y: bottomPanel.frame.minY - 27,
                              width: 80, height: 21)

    let comments = ensurePortraitComments()
    comments.view.frame = CGRect(x: 0, y: videoRect.maxY,
                                 width: full.width,
                                 height: max(0, full.height - videoRect.maxY))
    let reveal = p * p * (3 - 2 * p)
    comments.view.alpha = reveal
    comments.view.isHidden = p < 0.01
    comments.view.isUserInteractionEnabled = true
    view.bringSubviewToFront(danmakuOverlay)
    if p > 0.01 && relatedPanel == nil && detailPanel == nil {
      view.bringSubviewToFront(comments.view)
    }
    if relatedPanel == nil && detailPanel == nil {
      view.bringSubviewToFront(bottomPanel)
      view.bringSubviewToFront(seekBubble)
    }
    if let related = relatedPanel { view.bringSubviewToFront(related.view) }
    if let detail = detailPanel { view.bringSubviewToFront(detail.view) }
    bottomPanel.layoutIfNeeded()
    grid.setNeedsDisplay()
  }

  private func settlePortrait(top: Bool, animated: Bool) {
    guard !isLandscapePlayer else { return }
    portraitStageIsTop = top
    portraitDragActive = false
    portraitSettling = animated
    hideControls()
    let target: CGFloat = top ? 1 : 0
    if animated {
      UIView.animate(withDuration: 0.58, delay: 0,
                     usingSpringWithDamping: 0.88, initialSpringVelocity: 0.15,
                     options: [.allowUserInteraction, .beginFromCurrentState]) {
        self.applyPortraitTransition(target)
      } completion: { _ in
        self.portraitSettling = false
        self.portraitTransition = target
        self.applyPortraitTransition(target)
      }
    } else {
      portraitTransition = target
      applyPortraitTransition(target)
    }
  }

  private func commentsPull(_ progress: CGFloat) {
    guard !isLandscapePlayer, portraitStageIsTop else { return }
    portraitDragActive = true
    applyPortraitTransition(1 - max(0, min(1, progress)))
  }

  private func commentsPullEnded(_ complete: Bool) {
    guard !isLandscapePlayer else { return }
    settlePortrait(top: !complete, animated: true)
  }

  private func ensurePortraitComments() -> CommentsPanelViewController {
    if let comments = portraitComments { return comments }
    let comments = CommentsPanelViewController(aid: item.aid)
    comments.embedded = true
    comments.onSwipeLeft = { [weak self] in self?.openRelatedPanel() }
    comments.onSwipeRight = { [weak self] in self?.openDetailPanel() }
    comments.onPullDown = { [weak self] progress in self?.commentsPull(progress) }
    comments.onPullDownEnded = { [weak self] complete in self?.commentsPullEnded(complete) }
    addChild(comments)
    comments.view.frame = .zero
    comments.view.autoresizingMask = []
    comments.view.alpha = 0
    comments.view.isHidden = true
    comments.view.isUserInteractionEnabled = false
    view.addSubview(comments.view)
    comments.didMove(toParent: self)
    portraitComments = comments
    return comments
  }

  override func viewWillTransition(to size: CGSize,
                                   with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    coordinator.animate(alongsideTransition: { _ in
      self.view.setNeedsLayout()
      self.view.layoutIfNeeded()
    })
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    let full = view.bounds
    let landscape = full.width > full.height
    isLandscapePlayer = landscape
    view.backgroundColor = .black
    backdrop.frame = full
    backdropVideo.frame = full
    backdropLayer.frame = backdropVideo.bounds
    backdropBlur.frame = full
    backdropDim.frame = full
    backdrop.isHidden = landscape
    backdropVideo.isHidden = landscape
    backdropBlur.isHidden = landscape
    backdropDim.isHidden = landscape
    dim.frame = full
    topBar.frame = CGRect(x: 0, y: view.safeAreaInsets.top, width: full.width, height: 52)

    if landscape {
      portraitComments?.view.isHidden = true
      portraitComments?.view.alpha = 0
      if panProgress <= 0.001 || closing {
        videoContainer.frame = full
      }
      videoContainer.layer.cornerRadius = 0
      layoutVideoSubviews()
      danmakuOverlay.frame = full
      let panelHeight: CGFloat = 104
      let panelWidth = min(560, full.width - 32)
      bottomPanel.frame = CGRect(
        x: (full.width - panelWidth) / 2,
        y: full.height - view.safeAreaInsets.bottom - panelHeight - 6,
        width: panelWidth,
        height: panelHeight
      )
      seekBubble.frame = CGRect(x: full.midX - 40, y: bottomPanel.frame.minY - 27,
                                width: 80, height: 21)
    } else {
      if !portraitDragActive && !portraitSettling {
        applyPortraitTransition(portraitTransition)
      } else {
        layoutVideoSubviews()
      }
    }
    if let related = relatedPanel {
      view.bringSubviewToFront(related.view)
    }
    if let detail = detailPanel {
      view.bringSubviewToFront(detail.view)
    }

    bottomPanel.layoutIfNeeded()
    grid.setNeedsDisplay()
  }

  private func loadQuality(_ qn: Int) {
    currentQuality = qn
    loadToken += 1
    let token = loadToken
    if item.roomId > 0 {
      qualityLabel.text = "LIVE"
      wheel.isHidden = true
      grid.isHidden = true
      bottomPanel.isHidden = true
      speedLabel.isHidden = true
      danmakuToggle.isHidden = true
      danmakuSend.isHidden = true
      danmakuOverlay.isHidden = true
      liveChat.isHidden = false
      startLiveChat()
      BiliAPI.shared.liveRoom(roomId: item.roomId) { [weak self] result in
        guard let self = self, token == self.loadToken else { return }
        switch result {
        case .success(let source):
          if !source.title.isEmpty { self.titleLabel.text = source.title }
          if !source.owner.isEmpty { self.ownerLabel.text = source.owner }
          self.engine.load(
            url: source.url,
            headers: BiliAPI.shared.mediaHeaders,
            autoplay: true,
            muted: false,
            loop: false
          )
        case .failure(let error):
          self.errorLabel.text = error.localizedDescription
          self.errorLabel.isHidden = false
        }
      }
      return
    }
    let completion: (Result<PlaySource, Error>) -> Void = { [weak self] result in
      guard let self = self, token == self.loadToken else { return }
      switch result {
      case .success(let source):
        self.qualityLabel.text = source.qualityLabel.isEmpty ? "\(qn)P" : source.qualityLabel
        self.engine.load(
          url: source.url,
          backup: source.backup,
          headers: BiliAPI.shared.mediaHeaders,
          autoplay: true,
          muted: false,
          loop: false,
          startAt: Double(max(0, self.item.progress))
        )
      case .failure:
        if qn > 64 {
          self.loadQuality(64)
        } else if qn > 32 {
          self.loadQuality(32)
        } else {
          self.errorLabel.text = "无法获取播放地址"
          self.errorLabel.isHidden = false
        }
      }
    }
    if item.epId > 0 {
      BiliAPI.shared.playPgc(epId: item.epId, bvid: item.bvid, cid: item.cid, qn: qn, completion: completion)
    } else {
      BiliAPI.shared.playQuality(item, qn: qn, completion: completion)
    }
  }

  @objc private func cycleQuality() {
    if item.roomId > 0 { return }
    if currentQuality > 64 { loadQuality(64) }
    else if currentQuality > 32 { loadQuality(32) }
    else { loadQuality(80) }
  }

  private func startLiveChat() {
    guard item.roomId > 0 else { return }
    liveSocket.onMessage = { [weak self] user, text in
      guard let self = self else { return }
      var message = LiveMessage()
      message.user = user
      message.text = text
      self.liveMessages.append(message)
      if self.liveMessages.count > 7 {
        self.liveMessages.removeFirst(self.liveMessages.count - 7)
      }
      self.liveChat.setMessages(self.liveMessages)
    }
    BiliAPI.shared.liveDanmuInfo(roomId: item.roomId) { [weak self] result in
      guard let self = self else { return }
      switch result {
      case .success(let info):
        NSLog("[O11A1] live token ok host=%@ port=%d", info.1, info.2)
        self.liveSocket.connect(roomId: self.item.roomId, token: info.0, host: info.1, port: info.2)
      case .failure(let error):
        NSLog("[O11A1] live token failed %@", error.localizedDescription)
        var message = LiveMessage()
        message.user = "提示"
        message.text = "弹幕暂时不可用"
        self.liveMessages = [message]
        self.liveChat.setMessages(self.liveMessages)
      }
    }
  }

  private func stopLiveChat() {
    liveSocket.close()
    liveMessages.removeAll()
    liveChat.setMessages([])
  }

  deinit {
    if let observer = activeObserver {
      NotificationCenter.default.removeObserver(observer)
    }
  }

  @objc private func cycleSpeed() {
    let values: [Float] = [1, 1.25, 1.5, 2]
    speedIndex = (speedIndex + 1) % values.count
    let value = values[speedIndex]
    engine.setRate(value)
    speedLabel.text = value == 1 ? "1.0x" : "\(value)x"
  }

  @objc private func followTapped() {
    guard item.mid > 0 else { return }
    BiliAPI.shared.follow(mid: item.mid, on: true) { [weak self] ok in
      self?.followButton.setTitle(ok ? "已关注" : "关注失败", for: .normal)
      self?.followButton.alpha = ok ? 0.6 : 1
    }
  }

  @objc private func toggleDanmaku() {
    let enabled = !danmakuOverlay.enabled
    danmakuOverlay.setEnabled(enabled)
    UserDefaults.standard.set(enabled, forKey: "danmaku_enabled")
    danmakuToggle.alpha = enabled ? 1 : 0.45
  }

  @objc private func sendDanmakuTapped() {
    guard item.cid > 0 else { return }
    let alert = UIAlertController(title: "发弹幕", message: nil, preferredStyle: .alert)
    alert.addTextField { field in
      field.placeholder = "发一条弹幕"
      field.clearButtonMode = .whileEditing
    }
    alert.addAction(UIAlertAction(title: "取消", style: .cancel))
    alert.addAction(UIAlertAction(title: "发送", style: .default) { [weak self, weak alert] _ in
      guard let self = self else { return }
      let text = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      guard !text.isEmpty else { return }
      let progress = Int64(max(0, self.engine.currentTime) * 1000)
      BiliAPI.shared.sendDanmaku(cid: self.item.cid, message: text, progressMs: progress)
    })
    present(alert, animated: true)
  }

  @objc private func togglePlay() {
    engine.toggle()
    videoContainer.backgroundColor = engine.isPlaying ? .black : NativeTheme.pipRose
  }

  @objc private func handleSingleTap() {
    let visible = bottomPanel.alpha > 0.5 && !bottomPanel.isHidden
    if visible {
      hideControls()
    } else {
      showControls()
    }
  }

  @objc private func handleDoubleTap() {
    let wasHidden = !controlsVisible
    togglePlay()
    if wasHidden || engine.isPlaying {
      showControls()
    } else {
      controlsTimer?.invalidate()
    }
  }

  private func showControls() {
    controlsTimer?.invalidate()
    controlsVisible = true
    bottomPanel.isUserInteractionEnabled = true
    UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseOut]) {
      self.bottomPanel.alpha = 1
      self.bottomPanel.transform = .identity
    }
    scheduleControlsHide()
  }

  private func hideControls() {
    controlsTimer?.invalidate()
    controlsVisible = false
    seekBubble.isHidden = true
    UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseIn]) {
      self.bottomPanel.alpha = 0
      self.bottomPanel.transform = CGAffineTransform(translationX: 0, y: 16)
    } completion: { _ in
      if !self.controlsVisible {
        self.bottomPanel.isUserInteractionEnabled = false
      }
    }
  }

  private func scheduleControlsHide() {
    controlsTimer?.invalidate()
    guard engine.isPlaying else { return }
    controlsTimer = Timer.scheduledTimer(withTimeInterval: 3.2, repeats: false) { [weak self] _ in
      guard let self = self, self.engine.isPlaying, !self.isScrubbing else { return }
      self.hideControls()
    }
  }

  @objc private func longPress(_ gesture: UILongPressGestureRecognizer) {
    switch gesture.state {
    case .began:
      guard engine.isPlaying else { return }
      engine.setRate(2.0)
      speedFeedback.impactOccurred(intensity: 1.0)
      speedFeedback.prepare()
    case .ended, .cancelled, .failed:
      engine.setRate(1.0)
    default:
      break
    }
  }

  @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
    if portraitShrinking { return }
    let reference = view.superview ?? view
    let translation = gesture.translation(in: reference)
    switch gesture.state {
    case .began:
      relatedSwipe = false
      detailSwipe = false
      portraitDismissDrag = false
      portraitUpDrag = false
      portraitRestoreDrag = false
      panDirectionDecided = false
      portraitDragActive = true
      panStartFrame = videoContainer.frame
      panProgress = 0
      let velocity = gesture.velocity(in: videoContainer)
      if abs(velocity.x) > abs(velocity.y) && abs(velocity.x) > 80 {
        panDirectionDecided = true
        if velocity.x < 0 {
          relatedSwipe = true
        } else {
          detailSwipe = true
        }
      }
    case .changed:
      if !panDirectionDecided {
        let threshold: CGFloat = 12
        if abs(translation.x) > threshold || abs(translation.y) > threshold {
          if abs(translation.x) > abs(translation.y) * 1.15 {
            panDirectionDecided = true
            if translation.x < 0 {
              relatedSwipe = true
            } else {
              detailSwipe = true
            }
          } else if !isLandscapePlayer {
            panDirectionDecided = true
            if portraitStageIsTop {
              if translation.y > 0 {
                portraitRestoreDrag = true
              }
            } else if translation.y > 0 {
              portraitDismissDrag = true
              view.transform = .identity
            } else if translation.y < 0 {
              portraitUpDrag = true
            }
          } else {
            panDirectionDecided = true
          }
        }
      }
      guard !relatedSwipe && !detailSwipe else { return }
      if !isLandscapePlayer {
        let rects = portraitVideoRects()
        let distance = max(120, rects.center.minY - rects.top.minY)
        if portraitUpDrag {
          let p = min(1, max(0, -translation.y / distance))
          applyPortraitTransition(p)
        } else if portraitRestoreDrag {
          let p = 1 - min(1, max(0, translation.y / distance))
          applyPortraitTransition(p)
        } else if portraitDismissDrag {
          let down = max(0, translation.y)
          let scale = max(0.82, 1 - down / 1600)
          let radius = min(1, down / 320)
          view.layer.cornerCurve = .continuous
          view.layer.cornerRadius = NativeTheme.cornerRadius * radius
          view.transform = CGAffineTransform(translationX: 0, y: down * 0.55)
            .scaledBy(x: scale, y: scale)
        }
        return
      }
      let down = max(0, translation.y)
      let maxDistance = max(120, view.bounds.height * 0.52)
      panProgress = min(1, down / maxDistance)
      let full = view.bounds
      let targetW = full.width - 48
      let targetH = targetW * 9.0 / 16.0
      let target = CGRect(
        x: 24,
        y: view.safeAreaInsets.top + 12,
        width: targetW,
        height: targetH
      )
      let p = panProgress
      let rect = CGRect(
        x: full.minX + (target.minX - full.minX) * p,
        y: full.minY + (target.minY - full.minY) * p,
        width: full.width + (target.width - full.width) * p,
        height: full.height + (target.height - full.height) * p
      )
      videoContainer.frame = rect
      topBar.alpha = 1 - p
      bottomPanel.alpha = 1 - p
      playButton.alpha = 0
      dim.alpha = 1 - p * 0.5
    case .ended, .cancelled:
      let endVelocity = gesture.velocity(in: view)
      if relatedSwipe {
        relatedSwipe = false
        panDirectionDecided = false
        portraitDragActive = false
        if translation.x < -50 || endVelocity.x < -420 {
          openRelatedPanel()
        }
        return
      }
      if detailSwipe {
        detailSwipe = false
        panDirectionDecided = false
        portraitDragActive = false
        if translation.x > 50 || endVelocity.x > 420 {
          openDetailPanel()
        }
        return
      }
      if !isLandscapePlayer {
        let rects = portraitVideoRects()
        let distance = max(120, rects.center.minY - rects.top.minY)
        if portraitUpDrag {
          portraitUpDrag = false
          panDirectionDecided = false
          let p = min(1, max(0, -translation.y / distance))
          settlePortrait(top: p > 0.28 || endVelocity.y < -420, animated: true)
          return
        }
        if portraitRestoreDrag {
          portraitRestoreDrag = false
          panDirectionDecided = false
          let p = 1 - min(1, max(0, translation.y / distance))
          settlePortrait(top: !(p < 0.72 || endVelocity.y > 420), animated: true)
          return
        }
        if portraitDismissDrag {
          portraitDismissDrag = false
          panDirectionDecided = false
          if translation.y > 120 || endVelocity.y > 700 {
            closePortraitWithShrink()
          } else {
            UIView.animate(withDuration: 0.32, delay: 0,
                           usingSpringWithDamping: 0.9, initialSpringVelocity: 0.3) {
              self.view.transform = .identity
              self.view.layer.cornerRadius = 0
            }
          }
          portraitDragActive = false
          return
        }
        panDirectionDecided = false
        portraitDragActive = false
        return
      }
      panDirectionDecided = false
      portraitDragActive = false
      let velocity = endVelocity.y
      if panProgress > 0.28 || velocity > 780 {
        closePlayer(animated: true)
      } else {
        UIView.animate(withDuration: 0.30, delay: 0, usingSpringWithDamping: 0.88, initialSpringVelocity: 0.4) {
          self.videoContainer.frame = self.view.bounds
          self.topBar.alpha = 1
          self.bottomPanel.alpha = 1
          self.playButton.alpha = self.engine.isPlaying ? 0 : 1
          self.dim.alpha = 1
          self.panProgress = 0
        }
      }
    default:
      break
    }
  }

  private func closePortraitWithShrink() {
    guard !closing && !portraitShrinking else { return }
    portraitShrinking = true
    portraitDragActive = false
    view.layer.cornerCurve = .continuous
    UIView.animate(withDuration: 0.30, delay: 0,
                   options: [.curveEaseIn, .beginFromCurrentState]) {
      self.view.layer.cornerRadius = NativeTheme.cornerRadius
      self.view.transform = CGAffineTransform(
        translationX: 0, y: self.view.bounds.height * 0.20
      ).scaledBy(x: 0.84, y: 0.84)
      self.view.alpha = 0
    } completion: { _ in
      self.portraitShrinking = false
      self.closePlayer(animated: false)
    }
  }

  private func openRelatedPanel() {
    guard relatedPanel == nil else { return }
    hideControls()
    let panel = RelatedViewController(bvid: item.bvid)
    panel.onSelect = { [weak self] value in
      self?.replace(with: value)
    }
    panel.onClose = { [weak self] in
      self?.closeRelatedPanel()
    }
    relatedPanel = panel
    setNeedsStatusBarAppearanceUpdate()
    addChild(panel)
    panel.view.frame = view.bounds
    panel.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.addSubview(panel.view)
    panel.didMove(toParent: self)
    panel.view.transform = CGAffineTransform(translationX: view.bounds.width, y: 0)
    UIView.animate(withDuration: 0.34, delay: 0, options: [.curveEaseOut]) {
      panel.view.transform = .identity
    }
  }

  private func closeRelatedPanel() {
    guard let panel = relatedPanel else { return }
    panel.willMove(toParent: nil)
    UIView.animate(withDuration: 0.28, delay: 0, options: [.curveEaseIn]) {
      panel.view.transform = CGAffineTransform(translationX: self.view.bounds.width, y: 0)
    } completion: { [weak self] _ in
      panel.view.removeFromSuperview()
      panel.removeFromParent()
      if self?.relatedPanel === panel {
        self?.relatedPanel = nil
        self?.setNeedsStatusBarAppearanceUpdate()
      }
    }
  }

  func play(_ value: VideoItem) {
    replace(with: value)
  }

  private func replace(with value: VideoItem) {
    guard value.bvid != item.bvid || value.roomId != item.roomId else {
      closeRelatedPanel()
      return
    }
    closeDetailPanel()
    closeSettingsPanel()
    closeRelatedPanel()
    stopLiveChat()
    engine.stop()
    controlsTimer?.invalidate()
    controlsVisible = false
    bottomPanel.alpha = 0
    bottomPanel.transform = CGAffineTransform(translationX: 0, y: 16)
    bottomPanel.isUserInteractionEnabled = false
    if let comments = portraitComments {
      comments.willMove(toParent: nil)
      comments.view.removeFromSuperview()
      comments.removeFromParent()
      portraitComments = nil
    }
    item = value
    closing = false
    errorLabel.isHidden = true
    poster.isHidden = false
    ImageLoader.shared.load(value.pic, into: poster)
    ImageLoader.shared.load(value.pic, into: backdrop)
    titleLabel.text = value.title
    ownerLabel.text = value.owner
    wheel.progress = 0
    grid.progress = 0
    wheel.durationSeconds = 0
    liveChat.isHidden = true
    danmakuOverlay.isHidden = value.roomId > 0
    if value.roomId == 0, value.cid > 0 {
      danmakuOverlay.load(cid: value.cid)
    }
    currentQuality = ThemeManager.shared.quality
    view.setNeedsLayout()
    loadQuality(currentQuality)
  }

  private func openCommentsPanel() {
    let comments = CommentsPanelViewController(aid: item.aid)
    present(comments, animated: false)
    comments.view.transform = CGAffineTransform(translationX: view.bounds.width, y: 0)
    UIView.animate(withDuration: 0.34, delay: 0, options: [.curveEaseOut]) {
      comments.view.transform = .identity
    }
  }

  private func openDetailPanel() {
    guard detailPanel == nil else { return }
    hideControls()
    let detail = VideoDetailViewController(item: item)
    detail.initialQuality = currentQuality
    detail.initialDanmakuOn = danmakuOverlay.enabled
    detail.initialLoopOn = loopOn
    detail.onProfile = { [weak self] mid in self?.onProfile?(mid) }
    detail.onClose = { [weak self] in self?.closeDetailPanel() }
    detail.onQuality = { [weak self] qn in
      guard let self = self else { return }
      self.currentQuality = qn
      ThemeManager.shared.quality = qn
      self.loadQuality(qn)
    }
    detail.onDanmaku = { [weak self] on in
      self?.danmakuOverlay.setEnabled(on)
      UserDefaults.standard.set(on, forKey: "danmaku_enabled")
      self?.danmakuToggle.alpha = on ? 1 : 0.45
    }
    detail.onLoop = { [weak self] on in
      guard let self = self else { return }
      self.loopOn = on
      self.engine.setLoop(on)
    }
    detailPanel = detail
    setNeedsStatusBarAppearanceUpdate()
    addChild(detail)
    detail.view.frame = view.bounds
    detail.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.addSubview(detail.view)
    detail.didMove(toParent: self)
    detail.view.transform = CGAffineTransform(translationX: -view.bounds.width, y: 0)
    UIView.animate(withDuration: 0.34, delay: 0, options: [.curveEaseOut]) {
      detail.view.transform = .identity
    }
  }

  private func closeDetailPanel() {
    guard let detail = detailPanel else { return }
    detail.willMove(toParent: nil)
    UIView.animate(withDuration: 0.28, delay: 0, options: [.curveEaseIn]) {
      detail.view.transform = CGAffineTransform(translationX: -self.view.bounds.width, y: 0)
    } completion: { [weak self] _ in
      detail.view.removeFromSuperview()
      detail.removeFromParent()
      if self?.detailPanel === detail {
        self?.detailPanel = nil
        self?.setNeedsStatusBarAppearanceUpdate()
      }
    }
  }

  private func openSettingsPanel() {
    guard settingsPanel == nil else { return }
    hideControls()
    let panel = PlayerSettingsViewController(
      quality: currentQuality,
      danmaku: danmakuOverlay.enabled,
      loop: loopOn)
    panel.onQuality = { [weak self] qn in
      guard let self = self else { return }
      self.currentQuality = qn
      ThemeManager.shared.quality = qn
      self.loadQuality(qn)
    }
    panel.onDanmaku = { [weak self] on in
      self?.danmakuOverlay.setEnabled(on)
      UserDefaults.standard.set(on, forKey: "danmaku_enabled")
      self?.danmakuToggle.alpha = on ? 1 : 0.45
    }
    panel.onLoop = { [weak self] on in
      guard let self = self else { return }
      self.loopOn = on
      self.engine.setLoop(on)
    }
    panel.onClose = { [weak self] in self?.closeSettingsPanel() }
    addChild(panel)
    panel.view.frame = view.bounds
    panel.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.addSubview(panel.view)
    panel.didMove(toParent: self)
    settingsPanel = panel
    setNeedsStatusBarAppearanceUpdate()
    panel.view.alpha = 0
    UIView.animate(withDuration: 0.3) {
      panel.view.alpha = 1
    }
  }

  private func closeSettingsPanel() {
    guard let panel = settingsPanel else { return }
    settingsPanel = nil
    setNeedsStatusBarAppearanceUpdate()
    panel.willMove(toParent: nil)
    UIView.animate(withDuration: 0.24) {
      panel.view.alpha = 0
    } completion: { _ in
      panel.view.removeFromSuperview()
      panel.removeFromParent()
    }
  }

  func testOpenDetail() {
    openDetailPanel()
  }

  func testOpenComments() {
    openCommentsPanel()
  }

  func testOpenSettings() {
    openSettingsPanel()
  }

  func testOpenRelated() {
    openRelatedPanel()
  }

  func testLandscape() {
    if #available(iOS 16.0, *) {
      view.window?.windowScene?.requestGeometryUpdate(
        .iOS(interfaceOrientations: .landscapeRight))
    } else {
      UIDevice.current.setValue(
        UIInterfaceOrientation.landscapeRight.rawValue,
        forKey: "orientation")
      UIViewController.attemptRotationToDeviceOrientation()
    }
  }

  @objc private func closeTapped() {
    closePlayer(animated: true)
  }

  private func closePlayer(animated: Bool) {
    guard !closing else { return }
    closing = true
    if #available(iOS 16.0, *) {
      view.window?.windowScene?.requestGeometryUpdate(
        .iOS(interfaceOrientations: .portrait))
    }
    stopLiveChat()
    engine.stop()
    engine.stopPip()
    if animated {
      UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseIn], animations: {
        self.view.alpha = 0
      }) { _ in
        self.onClose?()
      }
    } else {
      onClose?()
    }
  }

  private func closeFromPip() {
    closing = true
    stopLiveChat()
    engine.stop()
    onClose?()
  }

  private func scrub(ratio: Double, finished: Bool) {
    if !finished {
      if !isScrubbing {
        isScrubbing = true
        wasPlayingBeforeScrub = engine.isPlaying
        engine.pause()
      }
      let duration = engine.duration
      wheel.currentText = format(duration * ratio)
      seekBubble.text = formatMs(duration * ratio)
      seekBubble.isHidden = false
      return
    }
    seekBubble.isHidden = true
    let duration = engine.duration
    engine.seek(to: duration * ratio, resume: wasPlayingBeforeScrub)
    isScrubbing = false
    if wasPlayingBeforeScrub {
      engine.play()
    }
  }

  private func format(_ seconds: Double) -> String {
    guard seconds.isFinite, seconds >= 0 else { return "00:00" }
    let total = Int(seconds.rounded())
    let hours = total / 3600
    let minutes = (total % 3600) / 60
    let secs = total % 60
    if hours > 0 {
      return String(format: "%d:%02d:%02d", hours, minutes, secs)
    }
    return String(format: "%02d:%02d", minutes, secs)
  }

  private func formatMs(_ seconds: Double) -> String {
    guard seconds.isFinite, seconds >= 0 else { return "00:00.000" }
    let total = Int(seconds)
    let minutes = total / 60
    let secs = total % 60
    let millis = Int((seconds - floor(seconds)) * 1000)
    return String(format: "%02d:%02d.%03d", minutes, secs, millis)
  }

  @objc private func openProfile() {
    onProfile?(item.mid)
  }

  @objc private func openComments() {
    let comments = CommentsViewController(aid: item.aid)
    comments.modalPresentationStyle = .pageSheet
    present(comments, animated: true)
  }

  @objc private func like() {
    BiliAPI.shared.like(aid: item.aid, on: true) { [weak self] ok in
      guard let self = self else { return }
      self.likeButton.tintColor = ok ? NativeTheme.accent : .white
      UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
  }

  @objc private func coin() {
    BiliAPI.shared.coin(aid: item.aid) { [weak self] ok in
      self?.coinButton.tintColor = ok ? NativeTheme.warmOrange : .white
      UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
  }

  @objc private func favorite() {
    BiliAPI.shared.favorite(aid: item.aid, on: true) { [weak self] ok in
      self?.favButton.tintColor = ok ? NativeTheme.warmOrange : .white
      UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
  }

  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    if let pan = gestureRecognizer as? UIPanGestureRecognizer {
      let velocity = pan.velocity(in: videoContainer)
      let translation = pan.translation(in: videoContainer)
      return abs(velocity.x) > 20 || abs(velocity.y) > 20
        || abs(translation.x) > 6 || abs(translation.y) > 6
    }
    return true
  }

  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    if touch.view is UIControl { return false }
    if touch.view?.isDescendant(of: bottomPanel) == true { return false }
    if touch.view?.isDescendant(of: topBar) == true { return false }
    if let comments = portraitComments, !comments.view.isHidden,
       touch.view?.isDescendant(of: comments.view) == true { return false }
    if let related = relatedPanel,
       touch.view?.isDescendant(of: related.view) == true { return false }
    if let detail = detailPanel,
       touch.view?.isDescendant(of: detail.view) == true { return false }
    return true
  }
}
