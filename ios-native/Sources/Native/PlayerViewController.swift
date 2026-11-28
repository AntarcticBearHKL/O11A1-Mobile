import AVKit
import MediaPlayer
import UIKit

final class PlayerViewController: UIViewController, UIGestureRecognizerDelegate {
  private enum LandscapeVerticalControl {
    case none
    case brightness
    case volume
  }

  var item: VideoItem
  var onClose: (() -> Void)?
  var onProfile: ((Int64) -> Void)?
  var onMinimize: (() -> Void)?
  var onExpand: (() -> Void)?
  private(set) var isMiniWindow = false
  private(set) var isSystemPip = false

  private var engine = VideoEngine(name: "player")
  private lazy var playerView = PlayerLayerView(playerLayer: engine.playerLayer)
  private let speedFeedback = UIImpactFeedbackGenerator(style: .medium)
  private let backdrop = UIImageView()
  private let backdropHost = UIView()
  private let backdropVideo = UIView()
  private let loadingView = VideoLoadingView()
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
  private let playButton = UIButton(type: .custom)
  private let playGlyph = FrostedGlyphView()
  private let bottomPanel = UIView()
  private let bottomBlur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
  private let bottomTint = UIView()
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
  private var backgroundWatchObserver: NSObjectProtocol?
  private var lastProgressSave: CFTimeInterval = 0
  private var lastHistoryReport: CFTimeInterval = 0
  private var mediaLoadActive = false
  private var sourceFrame: CGRect = .zero
  private var panStartFrame: CGRect = .zero
  private var isScrubbing = false
  private var wasPlayingBeforeScrub = false
  private var panProgress: CGFloat = 0
  private var closing = false
  private var currentQuality = 80
  private var userPaused = false
  private var lastAppliedPlaying = false
  private var loadToken = 0
  private var started = false
  private var speedIndex = 0
  private var closeSwipe = false
  private var horizontalCloseActive = false
  private var horizontalCloseProgress: CGFloat = 0
  private var horizontalSlideRight = false
  private var horizontalSlideLeft = false
  private var landscapeDrag = false
  private var landscapeControl: LandscapeVerticalControl = .none
  private var landscapeAdjusting = false
  private var landscapeStartValue: Float = 0
  private let volumeView = MPVolumeView()
  private var volumeSlider: UISlider?
  private var progressLink: CADisplayLink?
  private var contentClosePan: UIPanGestureRecognizer?
  private var contentCloseStartX: CGFloat = 0
  private var longPressRecognizer: UILongPressGestureRecognizer?
  private var previewHandoff: PreviewHandoff?
  private var upgradeEngine: VideoEngine?
  private var upgradeView: PlayerLayerView?
  private var upgradePending = false
  private var upgradeAdopted = false
  private var pendingUpgradeLabel = ""
  private var pendingUpgradeSource: PlaySource?
  private var handoffLowReady = true
  private var pendingHandoffStart: Double?
  private var upgradeGeneration = 0
  private var portraitUpDrag = false
  private var portraitRestoreDrag = false
  private var portraitDownClose = false
  private var portraitDragActive = false
  private var portraitSettling = false
  private var portraitShrinking = false
  private var openingTransition = false
  private var backdropCollapsed = false
  var pendingStartSeconds: Double = 0
  private var portraitTransition: CGFloat = 1
  private var portraitStageIsTop = true
  private var portraitSettleToken = 0
  private var portraitDragBase: CGFloat = 1
  private var miniDragStartFrame = CGRect.zero
  private var miniDragTargetFrame = CGRect.zero
  private var miniDragProgress: CGFloat = 0
  private var miniSavedTransition: CGFloat = 0
  private var miniSavedTop = true
  private var miniSavedAlphas: [CGFloat] = []
  private var forcePageStart = false
  private let miniCloseButton = UIButton(type: .system)
  private var contentReady = false
  private var panDirectionDecided = false
  private var contentController: PlayerContentViewController?
  private var settingsPanel: SettingsSheetViewController?
  private var isLandscapePlayer = false
  private var loopMode = PlaybackLoopMode.stored
  private var loopQueue: [VideoItem] = []
  private var loopIndex = 0
  private var loadingNextLoop = false
  private var advancingLoop = false
  private var controlsVisible = true
  private let panelSlideDistance: CGFloat = 28
  private let playerPanelHeight: CGFloat = 100
  private let focusedPanelLift: CGFloat = 60
  private let portraitPanelWidthRatio: CGFloat = 0.9
  private let landscapePanelWidthRatio: CGFloat = 0.5
  private let panelShowDuration: TimeInterval = 0.26
  private let panelHideDuration: TimeInterval = 0.28
  private let panelHideScale: Double =
    ProcessInfo.processInfo.environment["O11A1_SLOW_PANEL"] == "1" ? 20 : 1

  init(item: VideoItem, sourceView: UIView?, preview: PreviewHandoff? = nil) {
    self.item = item
    self.previewHandoff = preview
    if let adopted = preview?.engine {
      self.engine = adopted
    }
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
    return .lightContent
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear
    view.clipsToBounds = true

    backdropHost.backgroundColor = .clear
    view.addSubview(backdropHost)

    backdrop.contentMode = .scaleAspectFill
    backdrop.clipsToBounds = true
    backdrop.backgroundColor = .clear
    ImageLoader.shared.load(item.pic, into: backdrop)
    backdropHost.addSubview(backdrop)

    backdropVideo.backgroundColor = .clear
    backdropVideo.alpha = 0
    backdropVideo.isUserInteractionEnabled = false
    backdropVideo.layer.addSublayer(backdropLayer)
    backdropHost.addSubview(backdropVideo)

    backdropBlur.isUserInteractionEnabled = false
    backdropHost.addSubview(backdropBlur)

    backdropDim.backgroundColor = UIColor.black.withAlphaComponent(0.42)
    backdropDim.isUserInteractionEnabled = false
    backdropHost.addSubview(backdropDim)

    videoContainer.backgroundColor = .clear
    videoContainer.clipsToBounds = true
    view.addSubview(videoContainer)

    poster.contentMode = .scaleAspectFit
    poster.clipsToBounds = true
    poster.backgroundColor = .clear
    ImageLoader.shared.load(item.pic, into: poster)
    videoContainer.addSubview(poster)

    playerView.backgroundColor = .clear
    videoContainer.addSubview(playerView)

    let upgrade = VideoEngine(name: "upgrade")
    let upgradeLayer = PlayerLayerView(playerLayer: upgrade.playerLayer)
    upgradeLayer.backgroundColor = .clear
    upgradeLayer.alpha = 0
    upgradeLayer.isUserInteractionEnabled = false
    videoContainer.addSubview(upgradeLayer)
    upgradeEngine = upgrade
    upgradeView = upgradeLayer
    upgrade.onReady = { [weak self] in self?.attemptUpgradeSwap() }
    upgrade.onTime = { [weak self] seconds, duration in
      guard let self = self, self.engine === self.upgradeEngine else { return }
      self.applyPlaybackTime(seconds: seconds, duration: duration)
    }
    upgrade.onPlaying = { [weak self] playing in
      guard let self = self, self.engine === self.upgradeEngine else { return }
      self.applyPlaying(playing)
    }
    upgrade.onError = { [weak self] message in
      guard let self = self, self.engine === self.upgradeEngine else { return }
      self.errorLabel.text = message
      self.errorLabel.isHidden = false
    }
    upgrade.onPipClose = { [weak self] in self?.closeFromPip() }
    upgrade.onPipRestore = { [weak self] in
      self?.closing = false
      self?.videoContainer.isHidden = false
    }

    pausedVeil.isUserInteractionEnabled = false
    pausedVeil.isHidden = true

    loadingView.translatesAutoresizingMaskIntoConstraints = false
    videoContainer.addSubview(loadingView)
    NSLayoutConstraint.activate([
      loadingView.centerXAnchor.constraint(equalTo: videoContainer.centerXAnchor),
      loadingView.centerYAnchor.constraint(equalTo: videoContainer.centerYAnchor),
    ])

    dim.backgroundColor = UIColor.black.withAlphaComponent(0.18)
    dim.isUserInteractionEnabled = false
    view.addSubview(dim)

    topBar.backgroundColor = .clear
    topBar.isHidden = true
    topBar.isUserInteractionEnabled = false
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

    playButton.backgroundColor = .clear
    playButton.adjustsImageWhenHighlighted = false
    playButton.isUserInteractionEnabled = false
    playGlyph.isUserInteractionEnabled = false
    playGlyph.setSymbol("play.fill", pointSize: 38)
    playButton.addSubview(playGlyph)
    playGlyph.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      playGlyph.leadingAnchor.constraint(equalTo: playButton.leadingAnchor),
      playGlyph.trailingAnchor.constraint(equalTo: playButton.trailingAnchor),
      playGlyph.topAnchor.constraint(equalTo: playButton.topAnchor),
      playGlyph.bottomAnchor.constraint(equalTo: playButton.bottomAnchor),
    ])
    view.addSubview(playButton)

    bottomPanel.layer.cornerRadius = 8
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
    bottomBlur.alpha = 1
    bottomPanel.addSubview(bottomBlur)
    applyPlayerChrome()
    NSLayoutConstraint.activate([
      bottomBlur.leadingAnchor.constraint(equalTo: bottomPanel.leadingAnchor),
      bottomBlur.trailingAnchor.constraint(equalTo: bottomPanel.trailingAnchor),
      bottomBlur.topAnchor.constraint(equalTo: bottomPanel.topAnchor),
      bottomBlur.bottomAnchor.constraint(equalTo: bottomPanel.bottomAnchor),
    ])

    bottomTint.isUserInteractionEnabled = false
    bottomPanel.addSubview(bottomTint)
    bottomTint.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      bottomTint.leadingAnchor.constraint(equalTo: bottomPanel.leadingAnchor),
      bottomTint.trailingAnchor.constraint(equalTo: bottomPanel.trailingAnchor),
      bottomTint.topAnchor.constraint(equalTo: bottomPanel.topAnchor),
      bottomTint.bottomAnchor.constraint(equalTo: bottomPanel.bottomAnchor),
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
    }
    content.addSubview(wheel)

    grid.onScrub = { [weak self] ratio, finished in
      guard let self = self else { return }
      self.showControls()
      self.scrub(ratio: ratio, finished: finished)
    }
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

    volumeView.frame = CGRect(x: -60, y: -60, width: 40, height: 40)
    volumeView.alpha = 0.01
    volumeView.showsRouteButton = false
    view.addSubview(volumeView)
    volumeView.layoutIfNeeded()
    volumeSlider = findVolumeSlider(in: volumeView)

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

      playButton.widthAnchor.constraint(equalToConstant: 68),
      playButton.heightAnchor.constraint(equalToConstant: 68),
      playButton.centerXAnchor.constraint(equalTo: videoContainer.centerXAnchor),
      playButton.centerYAnchor.constraint(equalTo: videoContainer.centerYAnchor),

      ownerLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 16),
      ownerLabel.topAnchor.constraint(equalTo: content.topAnchor, constant: 12),
      ownerLabel.trailingAnchor.constraint(lessThanOrEqualTo: ownerButton.leadingAnchor, constant: -8),

      ownerButton.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -14),
      ownerButton.centerYAnchor.constraint(equalTo: ownerLabel.centerYAnchor),

      wheel.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 6),
      wheel.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -6),
      wheel.topAnchor.constraint(equalTo: content.topAnchor, constant: 38),
      wheel.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -6),

      grid.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 6),
      grid.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -6),
      grid.topAnchor.constraint(equalTo: content.topAnchor, constant: 6),
      grid.heightAnchor.constraint(equalToConstant: 28),

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

    miniCloseButton.setImage(
      UIImage(systemName: "xmark",
              withConfiguration: UIImage.SymbolConfiguration(pointSize: 10, weight: .bold)),
      for: .normal)
    miniCloseButton.tintColor = .white
    miniCloseButton.backgroundColor = UIColor.black.withAlphaComponent(0.52)
    miniCloseButton.layer.cornerRadius = 11
    miniCloseButton.layer.cornerCurve = .continuous
    miniCloseButton.isHidden = true
    miniCloseButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
    view.addSubview(miniCloseButton)

    let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
    pan.delegate = self
    view.addGestureRecognizer(pan)

    let closePan = UIPanGestureRecognizer(
      target: self, action: #selector(handleContentClosePan(_:)))
    closePan.delegate = self
    closePan.cancelsTouchesInView = false
    view.addGestureRecognizer(closePan)
    contentClosePan = closePan

    let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
    longPress.minimumPressDuration = 0.35
    longPress.delegate = self
    longPress.cancelsTouchesInView = false
    view.addGestureRecognizer(longPress)
    longPressRecognizer = longPress

    let tap = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap))
    tap.delegate = self
    tap.cancelsTouchesInView = false
    view.addGestureRecognizer(tap)
    tap.require(toFail: longPress)

    let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
    doubleTap.numberOfTapsRequired = 2
    doubleTap.delegate = self
    doubleTap.cancelsTouchesInView = false
    view.addGestureRecognizer(doubleTap)
    doubleTap.require(toFail: longPress)
    tap.require(toFail: doubleTap)

    engine.onTime = { [weak self] seconds, duration in
      self?.applyPlaybackTime(seconds: seconds, duration: duration)
    }
    engine.onPlaying = { [weak self] playing in
      self?.applyPlaying(playing)
    }
    engine.onReady = { [weak self] in
      guard let self = self else { return }
      O11A1Trace.mark("player", "engine onReady handoff=\(self.pendingHandoffStart != nil)")
      if let start = self.pendingHandoffStart {
        self.pendingHandoffStart = nil
        self.engine.seek(to: start, resume: false) { [weak self] in
          DispatchQueue.main.async {
            guard let self = self else { return }
            self.handoffLowReady = true
            self.poster.isHidden = true
            self.errorLabel.isHidden = true
            self.backdropVideo.alpha = 1
            if !self.userPaused {
              self.engine.play()
            }
            self.view.setNeedsLayout()
            if let source = self.pendingUpgradeSource {
              self.pendingUpgradeSource = nil
              self.prepareQualityUpgrade(source)
            }
          }
        }
        return
      }
      self.handoffLowReady = true
      self.forcePageStart = false
      self.poster.isHidden = true
      self.errorLabel.isHidden = true
      self.backdropVideo.alpha = 1
      if !self.userPaused {
        self.engine.play()
      }
      self.view.setNeedsLayout()
      if self.pendingStartSeconds > 0 {
        let seconds = self.pendingStartSeconds
        self.pendingStartSeconds = 0
        self.engine.seek(to: seconds, resume: true)
      }
      if let source = self.pendingUpgradeSource {
        self.pendingUpgradeSource = nil
        self.prepareQualityUpgrade(source)
      }
    }
    engine.onError = { [weak self] message in
      guard let self = self else { return }
      self.loadingView.hide()
      self.handoffLowReady = true
      self.errorLabel.text = message
      self.errorLabel.isHidden = false
      if let source = self.pendingUpgradeSource {
        self.pendingUpgradeSource = nil
        self.prepareQualityUpgrade(source)
      }
    }
    engine.onLoadStatus = { [weak self] status in
      self?.applyLoadStatus(status)
    }
    engine.refreshLoadStatus()
    applyLoopMode()
    engine.onPipStart = { [weak self] in
      self?.systemPipDidStart()
    }
    engine.onPipClose = { [weak self] in
      self?.closeFromPip()
    }
    engine.onPipRestore = { [weak self] in
      self?.closing = false
      self?.videoContainer.isHidden = false
      self?.restoreFromSystemPiP(stopPip: false)
    }
    activeObserver = NotificationCenter.default.addObserver(
      forName: UIApplication.didBecomeActiveNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      guard let self = self, self.engine.isPipActive else { return }
      self.engine.stopPipForRestore()
    }
    backgroundWatchObserver = NotificationCenter.default.addObserver(
      forName: UIApplication.didEnterBackgroundNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.saveWatchProgress()
    }

    topBar.isHidden = true
    playButton.isHidden = true
    dim.isHidden = true
    controlsVisible = false
    bottomPanel.alpha = 0
    bottomPanel.transform = CGAffineTransform(translationX: 0, y: panelSlideDistance)
    bottomPanel.isUserInteractionEnabled = false
    [ownerLabel, ownerButton, qualityLabel, speedLabel, commentsButton,
     likeButton, coinButton, favButton].forEach { $0.removeFromSuperview() }
    _ = ensurePlayerContent()
    speedFeedback.prepare()
    if let handoff = previewHandoff, let adopted = handoff.engine {
      handoffLowReady = true
      adopted.playerLayer.videoGravity = .resizeAspect
      adopted.setLoop(loopMode == .single)
      adopted.onEnd = { [weak self] in self?.handlePlaybackEnded() }
      if handoff.quality > 0 {
        currentQuality = handoff.quality
      }
      if !handoff.qualityLabel.isEmpty {
        qualityLabel.text = handoff.qualityLabel
      }
      poster.isHidden = true
      pausedVeil.isHidden = true
      errorLabel.isHidden = true
      backdropVideo.alpha = 1
      applyPlaying(true)
      adopted.play()
    } else if let handoff = previewHandoff, !handoff.url.isEmpty, item.roomId == 0 {
      handoffLowReady = false
      let local = WatchProgressStore.shared.position(for: item.bvid)
      let resume = handoff.seconds > 1 ? handoff.seconds : max(local, handoff.seconds)
      let start = handoff.duration > 0
        ? min(resume, max(0, handoff.duration - 0.5))
        : max(0, resume)
      engine.load(
        url: handoff.url,
        backup: handoff.backup,
        headers: BiliAPI.shared.mediaHeaders,
        autoplay: false,
        muted: false,
        loop: loopMode == .single,
        startAt: 0
      )
      if userPaused { engine.pause() }
      pendingHandoffStart = start
      if handoff.quality > 0 {
        currentQuality = handoff.quality
      }
      if !handoff.qualityLabel.isEmpty {
        qualityLabel.text = handoff.qualityLabel
      }
    } else {
      loadQuality(ThemeManager.shared.quality)
    }
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
    bottomPanel.backgroundColor = .clear
    bottomTint.backgroundColor = light
      ? UIColor(white: 1, alpha: 0.55)
      : UIColor(white: 0, alpha: 0.38)
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
    contentReady = true
    engine.enablePiP()
    if sourceFrame.width > 0 {
      let target = view.bounds.width > view.bounds.height
        ? view.bounds : portraitVideoRects().top
      let source = view.convert(sourceFrame, from: nil)
      videoContainer.frame = source
      let full = view.bounds
      let scaleX = max(0.05, source.width / max(1, full.width))
      let scaleY = max(0.05, source.height / max(1, full.height))
      let origin = CGAffineTransform(
        translationX: source.midX - full.midX,
        y: source.midY - full.midY
      ).scaledBy(x: scaleX, y: scaleY)
      applyBackdrop(transform: origin, alpha: 0.35)
      openingTransition = true
      UIView.animate(withDuration: 0.42, delay: 0,
                     usingSpringWithDamping: 0.9, initialSpringVelocity: 0.12,
                     options: [.curveEaseOut, .beginFromCurrentState]) {
        self.videoContainer.frame = target
        self.applyBackdrop(transform: .identity, alpha: 1)
      } completion: { _ in
        self.openingTransition = false
        self.applyBackdrop(transform: .identity, alpha: 1)
        if !self.isLandscapePlayer {
          self.applyPortraitTransition(self.portraitTransition)
        }
      }
      sourceFrame = .zero
    } else if !isLandscapePlayer {
      applyPortraitTransition(portraitTransition)
    }
  }

  private func applyPlaybackTime(seconds: Double, duration: Double) {
    guard !isScrubbing else { return }
    danmakuOverlay.setTime(seconds)
    let safeDuration = duration > 0 ? duration : 1
    wheel.durationSeconds = duration
    wheel.progress = max(0, min(1, seconds / safeDuration))
    grid.progress = max(0, min(1, seconds / safeDuration))
    wheel.currentText = format(seconds)
    wheel.durationText = format(duration)
    guard item.roomId == 0, engine.isPlaying, seconds >= 1, duration > 0 else { return }
    let now = CACurrentMediaTime()
    if now - lastProgressSave >= 5 {
      lastProgressSave = now
      WatchProgressStore.shared.update(bvid: item.bvid, seconds: seconds,
                                       duration: duration)
      if now - lastHistoryReport >= 15 {
        lastHistoryReport = now
        reportWatchHistory(seconds: seconds)
      }
    }
  }

  private func saveWatchProgress() {
    guard item.roomId == 0, !item.bvid.isEmpty else { return }
    let seconds = engine.currentTime
    let duration = engine.duration
    guard seconds >= 1, duration > 0 else { return }
    WatchProgressStore.shared.update(bvid: item.bvid, seconds: seconds,
                                     duration: duration)
    reportWatchHistory(seconds: seconds)
  }

  private func reportWatchHistory(seconds: Double) {
    guard item.roomId == 0, item.aid > 0, item.cid > 0, seconds >= 1 else {
      return
    }
    BiliAPI.shared.reportHistory(
      aid: item.aid, cid: item.cid, progress: Int(seconds))
  }

  private func resumePosition() -> Double {
    if forcePageStart {
      return 0
    }
    if pendingStartSeconds > 0 { return pendingStartSeconds }
    if engine.player.currentItem?.status == .readyToPlay {
      return max(0, engine.currentTime)
    }
    let local = WatchProgressStore.shared.position(for: item.bvid)
    if local > 0 { return local }
    return Double(max(0, item.progress))
  }

  private func applyPlaying(_ playing: Bool) {
    let becamePaused = lastAppliedPlaying && !playing
    lastAppliedPlaying = playing
    let paused = userPaused || !playing
    playGlyph.setSymbol(paused ? "play.fill" : "pause.fill", pointSize: 38)
    pausedVeil.isHidden = true
    videoContainer.backgroundColor = .clear
    if playing {
      startProgressLink()
    } else {
      stopProgressLink()
      progressTick()
    }
    updatePauseButton()
    if becamePaused {
      saveWatchProgress()
    }
  }

  private func updatePauseButton() {
    let show = !mediaLoadActive && !closing
      && !isMiniWindow && !isSystemPip
    let wasHidden = playButton.isHidden
    playButton.isHidden = !show
    playButton.alpha = show ? (userPaused ? 1 : 0.9) : 0
    guard show else {
      playButton.transform = .identity
      return
    }
    view.bringSubviewToFront(playButton)
    if wasHidden {
      playButton.transform = CGAffineTransform(scaleX: 0.86, y: 0.86)
      UIView.animate(
        withDuration: 0.24, delay: 0,
        usingSpringWithDamping: 0.7, initialSpringVelocity: 0.4,
        options: [.allowUserInteraction, .beginFromCurrentState]) {
        self.playButton.transform = .identity
      }
    }
  }

  private func applyLoadStatus(_ status: VideoLoadStatus) {
    mediaLoadActive = status.isActive && !closing
    if mediaLoadActive {
      playButton.isHidden = true
      playButton.alpha = 0
    }
    guard mediaLoadActive else {
      loadingView.hide()
      updatePauseButton()
      return
    }
    loadingView.apply(status)
  }

  private func startProgressLink() {
    guard progressLink == nil else { return }
    let link = CADisplayLink(target: self, selector: #selector(progressTick))
    link.preferredFramesPerSecond = 60
    link.add(to: .main, forMode: .common)
    progressLink = link
  }

  private func stopProgressLink() {
    progressLink?.invalidate()
    progressLink = nil
  }

  @objc private func progressTick() {
    guard !isScrubbing else { return }
    let duration = engine.duration
    let seconds = engine.currentTime
    let safeDuration = duration > 0 ? duration : 1
    wheel.durationSeconds = duration
    wheel.progress = max(0, min(1, seconds / safeDuration))
    grid.progress = max(0, min(1, seconds / safeDuration))
    wheel.currentText = format(seconds)
    wheel.durationText = format(duration)
  }

  private func findVolumeSlider(in view: UIView) -> UISlider? {
    if let slider = view as? UISlider { return slider }
    for subview in view.subviews {
      if let slider = findVolumeSlider(in: subview) { return slider }
    }
    return nil
  }

  private func applyVerticalControl(_ translation: CGPoint,
                                    control: LandscapeVerticalControl,
                                    base: Float) {
    guard control != .none else { return }
    let height = max(1, view.bounds.height)
    let delta = Float(-translation.y / height) * 1.15
    let value = max(0, min(1, base + delta))
    switch control {
    case .brightness:
      UIScreen.main.brightness = CGFloat(value)
    case .volume:
      if volumeSlider == nil {
        volumeView.layoutIfNeeded()
        volumeSlider = findVolumeSlider(in: volumeView)
      }
      volumeSlider?.value = value
    case .none:
      break
    }
  }

  private func applyBackdrop(transform: CGAffineTransform, alpha: CGFloat) {
    backdropHost.transform = transform
    backdropHost.alpha = alpha
    for view in [backdrop, backdropVideo, backdropBlur, backdropDim] {
      view.transform = .identity
    }
    backdrop.alpha = 1
    backdropBlur.alpha = 1
    backdropDim.alpha = 1
    backdropCollapsed = false
  }

  private func collapseBackdrop(animated: Bool = true) {
    guard !backdropCollapsed else { return }
    backdropCollapsed = true
    let full = view.bounds
    let fraction = max(0.05, min(1, videoContainer.bounds.height / max(1, full.height)))
    let delta = videoContainer.center.y - full.midY
    let target = CGAffineTransform(translationX: 0, y: delta)
      .scaledBy(x: 1, y: fraction)
    let changes = {
      for view in [self.backdrop, self.backdropVideo, self.backdropBlur, self.backdropDim] {
        view.transform = target
      }
    }
    if animated {
      UIView.animate(withDuration: 0.45, delay: 0,
                     options: [.curveEaseInOut, .beginFromCurrentState],
                     animations: changes)
    } else {
      changes()
    }
  }

  private func expandBackdrop(animated: Bool = true) {
    guard backdropCollapsed else { return }
    backdropCollapsed = false
    let changes = {
      for view in [self.backdrop, self.backdropVideo, self.backdropBlur, self.backdropDim] {
        view.transform = .identity
      }
    }
    if animated {
      UIView.animate(withDuration: 0.45, delay: 0,
                     options: [.curveEaseInOut, .beginFromCurrentState],
                     animations: changes)
    } else {
      changes()
    }
  }

  private func portraitVideoRects() -> (center: CGRect, top: CGRect) {
    let full = view.bounds
    let width = full.width
    let topHeight = width * 9.0 / 16.0
    let aspect = max(0.4, min(3.0, engine.videoAspect))
    let naturalHeight = width / aspect
    let safeTop = view.safeAreaInsets.top
    let safeBottom = view.safeAreaInsets.bottom
    let maxCenterHeight = max(topHeight, full.height - safeTop - safeBottom - 12)
    let centerHeight = min(naturalHeight, maxCenterHeight)
    let minY = safeTop + 6
    let maxY = full.height - safeBottom - centerHeight - 6
    let centerY = min(max(minY, full.midY - centerHeight / 2 + 2),
                      max(minY, maxY))
    let center = CGRect(x: 0, y: centerY, width: width, height: centerHeight)
    let top = CGRect(x: 0, y: safeTop, width: width, height: topHeight)
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
    upgradeView?.frame = videoContainer.bounds
    poster.frame = videoContainer.bounds
    pausedVeil.frame = videoContainer.bounds
    pausedGradient.frame = pausedVeil.bounds
  }

  private func applyPortraitTransition(_ value: CGFloat) {
    guard !isLandscapePlayer, !isMiniWindow else { return }
    let p = max(0, min(1, value))
    portraitTransition = p
    let full = view.bounds
    let rects = portraitVideoRects()
    let videoRect = lerpRect(rects.center, rects.top, p)
    videoContainer.frame = videoRect
    videoContainer.layer.cornerRadius = 0
    layoutVideoSubviews()
    danmakuOverlay.frame = lerpRect(full, videoRect, p)

    let panelHeight: CGFloat = playerPanelHeight
    let panelWidth = max(1, full.width * portraitPanelWidthRatio)
    let centerPanelY = full.height - view.safeAreaInsets.bottom - panelHeight
      - 18 - focusedPanelLift
    let topPanelY = max(0, videoRect.maxY - panelHeight - 8)
    let panelY = centerPanelY + (topPanelY - centerPanelY) * p
    bottomPanel.bounds = CGRect(x: 0, y: 0, width: panelWidth, height: panelHeight)
    bottomPanel.center = CGPoint(x: full.midX, y: panelY + panelHeight / 2)
    seekBubble.frame = CGRect(x: full.midX - 40, y: panelY - 27,
                              width: 80, height: 21)

    let content = ensurePlayerContent()
    content.view.frame = CGRect(x: 0, y: videoRect.maxY,
                                width: full.width,
                                height: max(0, full.height - videoRect.maxY))
    let reveal = p * p * (3 - 2 * p)
    content.setReveal(contentReady ? reveal : 0)
    view.bringSubviewToFront(danmakuOverlay)
    view.bringSubviewToFront(content.view)
    view.bringSubviewToFront(errorLabel)
    view.bringSubviewToFront(bottomPanel)
    view.bringSubviewToFront(seekBubble)
    bottomPanel.layoutIfNeeded()
    grid.setNeedsDisplay()
  }

  private func settlePortrait(top: Bool, animated: Bool) {
    guard !isLandscapePlayer else { return }
    if top != portraitStageIsTop {
      UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    portraitStageIsTop = top
    portraitDragActive = false
    portraitSettling = animated
    portraitSettleToken += 1
    let token = portraitSettleToken
    hideControls()
    let target: CGFloat = top ? 1 : 0
    if animated {
      UIView.animate(withDuration: 0.46, delay: 0,
                     usingSpringWithDamping: 0.92, initialSpringVelocity: 0.12,
                     options: [.allowUserInteraction, .beginFromCurrentState]) {
        self.applyPortraitTransition(target)
      } completion: { _ in
        guard token == self.portraitSettleToken,
              !self.portraitDragActive else { return }
        self.portraitSettling = false
        self.portraitTransition = target
        self.applyPortraitTransition(target)
      }
    } else {
      portraitSettling = false
      portraitTransition = target
      applyPortraitTransition(target)
    }
  }

  private func startSystemPiPFromGesture() {
    portraitDragActive = false
    if engine.startPipNow(requirePlaying: false) {
      return
    }
    // The system PiP needs a ready, visible player layer. Give it one short
    // retry, then keep the gesture useful with the in-app fallback.
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) { [weak self] in
      guard let self = self, !self.isSystemPip, !self.isMiniWindow else { return }
      if self.engine.startPipNow(requirePlaying: false) {
        return
      }
      self.portraitDragActive = true
      self.beginMiniDrag()
      self.updateMiniDrag(260)
      self.finishMiniDrag(velocity: 900)
    }
  }

  private func systemPipDidStart() {
    guard !isSystemPip else { return }
    isSystemPip = true
    closing = false
    portraitDragActive = false
    portraitSettling = false
    view.isHidden = true
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    onMinimize?()
    setNeedsStatusBarAppearanceUpdate()
  }

  func restoreFromSystemPiP(stopPip: Bool = true) {
    if stopPip, engine.isPipActive {
      engine.stopPipForRestore()
    }
    let wasHidden = view.isHidden || isSystemPip
    isSystemPip = false
    guard wasHidden else { return }
    view.isHidden = false
    view.alpha = 1
    if let parent = view.superview {
      view.frame = parent.bounds
    }
    view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.setNeedsLayout()
    applyPortraitTransition(portraitTransition)
    onExpand?()
    setNeedsStatusBarAppearanceUpdate()
  }

  private func miniFrameInParent() -> CGRect {
    let parent: UIView = view.superview ?? view
    let bounds = parent.bounds
    let width = min(212, max(156, bounds.width * 0.5))
    let height = width * 9.0 / 16.0
    let x = bounds.width - width - 14
    let y = bounds.height - 24 - 66 - 10 - height
    return CGRect(x: x, y: max(60, y), width: width, height: height)
  }

  private func beginMiniDrag() {
    guard !isMiniWindow, onMinimize != nil else { return }
    miniDragStartFrame = videoContainer.frame
    miniDragTargetFrame = miniFrameInParent()
    miniDragProgress = 0
    miniSavedAlphas = [backdropHost.alpha, topBar.alpha, bottomPanel.alpha,
                       dim.alpha, playButton.alpha, danmakuOverlay.alpha,
                       contentController?.view.alpha ?? 0]
    view.bringSubviewToFront(videoContainer)
    view.bringSubviewToFront(miniCloseButton)
    miniCloseButton.isHidden = true
  }

  private func updateMiniDrag(_ distance: CGFloat) {
    let p = max(0, min(1, distance / 220))
    miniDragProgress = p
    videoContainer.frame = lerpRect(miniDragStartFrame, miniDragTargetFrame, p)
    videoContainer.layer.cornerRadius = 12 * p
    videoContainer.clipsToBounds = true
    let fade = max(0, 1 - p * 1.7)
    backdropHost.alpha = fade
    topBar.alpha = fade
    bottomPanel.alpha = fade
    dim.alpha = fade
    danmakuOverlay.alpha = fade
    contentController?.view.alpha = fade
    playButton.alpha = 0
  }

  private func finishMiniDrag(velocity: CGFloat) {
    guard onMinimize != nil, miniDragProgress > 0 || velocity > 0 else {
      portraitDragActive = false
      return
    }
    let commit = miniDragProgress > 0.28 || velocity > 700
    if commit {
      UIView.animate(withDuration: 0.26, delay: 0,
                     options: [.curveEaseOut, .beginFromCurrentState]) {
        self.videoContainer.frame = self.miniDragTargetFrame
        self.videoContainer.layer.cornerRadius = 12
        self.backdropHost.alpha = 0
        self.topBar.alpha = 0
        self.bottomPanel.alpha = 0
        self.dim.alpha = 0
        self.danmakuOverlay.alpha = 0
        self.contentController?.view.alpha = 0
      } completion: { _ in
        self.commitMiniWindow()
      }
    } else {
      UIView.animate(withDuration: 0.34, delay: 0,
                     usingSpringWithDamping: 0.9,
                     initialSpringVelocity: 0.3,
                     options: [.beginFromCurrentState, .allowUserInteraction]) {
        self.videoContainer.frame = self.miniDragStartFrame
        self.videoContainer.layer.cornerRadius = 0
        if self.miniSavedAlphas.count == 7 {
          self.backdropHost.alpha = self.miniSavedAlphas[0]
          self.topBar.alpha = self.miniSavedAlphas[1]
          self.bottomPanel.alpha = self.miniSavedAlphas[2]
          self.dim.alpha = self.miniSavedAlphas[3]
          self.playButton.alpha = self.miniSavedAlphas[4]
          self.danmakuOverlay.alpha = self.miniSavedAlphas[5]
          self.contentController?.view.alpha = self.miniSavedAlphas[6]
        }
      } completion: { _ in
        self.portraitDragActive = false
        self.applyPortraitTransition(self.portraitTransition)
      }
    }
  }

  private func commitMiniWindow() {
    guard !isMiniWindow else { return }
    isMiniWindow = true
    portraitDragActive = false
    portraitSettling = false
    miniSavedTransition = portraitTransition
    miniSavedTop = portraitStageIsTop
    miniDragProgress = 0
    let target = miniDragTargetFrame
    view.transform = .identity
    view.frame = target
    view.autoresizingMask = []
    view.clipsToBounds = false
    view.backgroundColor = .clear
    view.layer.cornerRadius = 12
    view.layer.shadowColor = UIColor.black.cgColor
    view.layer.shadowOpacity = 0.28
    view.layer.shadowRadius = 16
    view.layer.shadowOffset = CGSize(width: 0, height: 6)
    videoContainer.frame = view.bounds
    videoContainer.backgroundColor = .black
    videoContainer.layer.cornerRadius = 12
    videoContainer.clipsToBounds = true
    videoContainer.transform = .identity
    videoContainer.alpha = 1
    backdropHost.isHidden = true
    backdropHost.alpha = 0
    topBar.isHidden = true
    bottomPanel.isHidden = true
    dim.isHidden = true
    contentController?.view.isHidden = true
    danmakuOverlay.isHidden = true
    playButton.isHidden = true
    errorLabel.isHidden = true
    seekBubble.isHidden = true
    miniCloseButton.isHidden = false
    miniCloseButton.frame = CGRect(x: max(4, view.bounds.width - 30), y: 6,
                                   width: 24, height: 24)
    view.bringSubviewToFront(videoContainer)
    view.bringSubviewToFront(miniCloseButton)
    hideControls()
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    onMinimize?()
    setNeedsStatusBarAppearanceUpdate()
  }

  func exitMiniWindow() {
    guard isMiniWindow else { return }
    isMiniWindow = false
    miniCloseButton.isHidden = true
    let parent: UIView = view.superview ?? view
    view.frame = parent.bounds
    view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.layer.cornerRadius = 0
    view.layer.shadowOpacity = 0
    view.clipsToBounds = true
    view.backgroundColor = .clear
    videoContainer.layer.cornerRadius = 0
    videoContainer.backgroundColor = .clear
    backdropHost.isHidden = false
    backdropHost.alpha = 1
    topBar.isHidden = true
    topBar.alpha = 0
    bottomPanel.isHidden = false
    dim.isHidden = false
    dim.alpha = 1
    contentController?.view.isHidden = false
    danmakuOverlay.isHidden = item.roomId > 0
    danmakuOverlay.alpha = 1
    playButton.isHidden = false
    playButton.alpha = engine.isPlaying ? 0 : 1
    miniDragProgress = 0
    portraitStageIsTop = miniSavedTop
    portraitTransition = miniSavedTransition
    applyPortraitTransition(miniSavedTransition)
    if miniSavedTransition < 0.5 {
      hideControls()
    } else {
      hideControls()
    }
    onExpand?()
    setNeedsStatusBarAppearanceUpdate()
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
  }

  private func layoutMiniWindow() {
    view.backgroundColor = .clear
    videoContainer.frame = view.bounds
    videoContainer.backgroundColor = .black
    videoContainer.layer.cornerRadius = 12
    videoContainer.clipsToBounds = true
    layoutVideoSubviews()
    miniCloseButton.frame = CGRect(x: max(4, view.bounds.width - 30), y: 6,
                                   width: 24, height: 24)
    view.bringSubviewToFront(videoContainer)
    view.bringSubviewToFront(miniCloseButton)
  }

  private func commentsPull(_ progress: CGFloat) {
    guard !isLandscapePlayer, !isMiniWindow, portraitStageIsTop else { return }
    if portraitSettling {
      videoContainer.layer.removeAllAnimations()
      bottomPanel.layer.removeAllAnimations()
      contentController?.view.layer.removeAllAnimations()
      danmakuOverlay.layer.removeAllAnimations()
    }
    portraitSettleToken += 1
    portraitSettling = false
    portraitDragActive = true
    applyPortraitTransition(1 - max(0, min(1, progress)))
  }

  private func commentsPullEnded(_ complete: Bool) {
    guard !isLandscapePlayer else { return }
    settlePortrait(top: !complete, animated: true)
  }

  private func ensurePlayerContent() -> PlayerContentViewController {
    if let content = contentController { return content }
    let content = PlayerContentViewController(item: item)
    content.initialQuality = currentQuality
    content.initialDanmakuOn = danmakuOverlay.enabled
    content.initialLoopOn = loopMode == .single
    content.onSelectRelated = { [weak self] value in self?.replace(with: value) }
    content.onSelectPage = { [weak self] page in self?.selectPage(page) }
    content.onProfile = { [weak self] mid in self?.onProfile?(mid) }
    content.onQuality = { [weak self] qn in
      guard let self = self else { return }
      self.currentQuality = qn
      ThemeManager.shared.quality = qn
      self.loadQuality(qn)
    }
    content.onDanmaku = { [weak self] on in
      self?.danmakuOverlay.setEnabled(on)
      UserDefaults.standard.set(on, forKey: "danmaku_enabled")
      self?.danmakuToggle.alpha = on ? 1 : 0.45
    }
    content.onDanmakuSettingsChanged = { [weak self] in
      guard let self = self else { return }
      self.danmakuOverlay.applyStoredSettings()
      self.danmakuToggle.alpha = self.danmakuOverlay.enabled ? 1 : 0.45
    }
    content.onLoop = { [weak self] on in
      self?.setLoopMode(on ? .single : .off)
    }
    content.onPullDown = { [weak self] progress in self?.commentsPull(progress) }
    content.onPullDownEnded = { [weak self] complete in
      self?.commentsPullEnded(complete)
    }
    addChild(content)
    content.view.frame = .zero
    content.view.autoresizingMask = []
    content.setReveal(0)
    view.addSubview(content.view)
    content.didMove(toParent: self)
    contentController = content
    return content
  }

  private var portraitCloseReady: Bool {
    if portraitStageIsTop { return portraitTransition > 0.98 }
    return portraitTransition < 0.02
  }

  private func beginHorizontalClose() {
    guard !closing, !portraitShrinking, !isLandscapePlayer,
          portraitCloseReady, !horizontalCloseActive else { return }
    horizontalCloseActive = true
    horizontalCloseProgress = 0
    portraitDragActive = true
    hideControls()
    if !horizontalSlideRight && !horizontalSlideLeft {
      collapseBackdrop(animated: true)
    }
  }

  private func updateHorizontalClose(_ progress: CGFloat) {
    guard horizontalCloseActive else { return }
    let p = max(0, min(1, progress))
    horizontalCloseProgress = p
    if horizontalSlideRight || horizontalSlideLeft {
      let width = max(1, view.bounds.width)
      let direction: CGFloat = horizontalSlideRight ? 1 : -1
      view.transform = CGAffineTransform(translationX: width * direction * p, y: 0)
      return
    }
    let height = max(1, view.bounds.height)
    let down = height * 0.58 * p
    view.bringSubviewToFront(videoContainer)
    videoContainer.transform = CGAffineTransform(translationX: 0, y: down)
    videoContainer.alpha = max(0, 1 - p * 0.9)
    backdropHost.transform = CGAffineTransform(translationX: 0, y: down)
    backdropHost.alpha = max(0, 1 - p * 0.7)
    contentController?.view.alpha = max(0, 1 - p * 1.5)
    topBar.alpha = 0
    bottomPanel.alpha = 0
    dim.alpha = max(0, 1 - p * 0.9)
    playButton.alpha = 0
  }

  private func finishHorizontalClose(_ shouldClose: Bool) {
    guard horizontalCloseActive else {
      if shouldClose { closeFromRightSwipe() }
      return
    }
    if horizontalSlideRight || horizontalSlideLeft {
      let width = max(1, view.bounds.width)
      let direction: CGFloat = horizontalSlideRight ? 1 : -1
      if shouldClose {
        UIView.animate(withDuration: 0.24, delay: 0,
                       options: [.curveEaseIn, .beginFromCurrentState]) {
          self.view.transform = CGAffineTransform(
            translationX: width * direction, y: 0)
        } completion: { _ in
          self.horizontalCloseActive = false
          self.horizontalSlideRight = false
          self.horizontalSlideLeft = false
          self.closePlayer(animated: false)
        }
      } else {
        UIView.animate(withDuration: 0.36, delay: 0,
                       usingSpringWithDamping: 0.9,
                       initialSpringVelocity: 0.25,
                       options: [.beginFromCurrentState, .allowUserInteraction]) {
          self.view.transform = .identity
        } completion: { _ in
          self.horizontalCloseActive = false
          self.portraitDragActive = false
          self.horizontalSlideRight = false
          self.horizontalSlideLeft = false
          self.expandBackdrop(animated: true)
          self.applyPortraitTransition(self.portraitTransition)
        }
      }
      return
    }
    let height = max(1, view.bounds.height)
    if shouldClose {
      let finalDown = height * 0.58
      UIView.animate(withDuration: 0.30, delay: 0,
                     options: [.curveEaseIn, .beginFromCurrentState]) {
        self.videoContainer.transform = CGAffineTransform(
          translationX: 0, y: finalDown)
        self.videoContainer.alpha = 0
        self.backdropHost.transform = CGAffineTransform(
          translationX: 0, y: finalDown)
        self.backdropHost.alpha = 0
        self.contentController?.view.alpha = 0
        self.dim.alpha = 0
        self.topBar.alpha = 0
        self.bottomPanel.alpha = 0
        self.playButton.alpha = 0
      } completion: { _ in
        self.horizontalCloseActive = false
        self.closePlayer(animated: false)
      }
    } else {
      UIView.animate(withDuration: 0.42, delay: 0,
                     usingSpringWithDamping: 0.88,
                     initialSpringVelocity: 0.3,
                     options: [.beginFromCurrentState, .allowUserInteraction]) {
        self.videoContainer.transform = .identity
        self.videoContainer.alpha = 1
        self.backdropHost.transform = .identity
        self.backdropHost.alpha = 1
        self.contentController?.view.alpha = 1
        self.dim.alpha = 1
      } completion: { _ in
        self.horizontalCloseActive = false
        self.portraitDragActive = false
        self.expandBackdrop(animated: true)
        self.applyPortraitTransition(self.portraitTransition)
      }
    }
  }

  private func closeFromRightSwipe() {
    guard !closing, !portraitShrinking, !isLandscapePlayer,
          portraitCloseReady else { return }
    horizontalSlideRight = true
    horizontalSlideLeft = false
    beginHorizontalClose()
    finishHorizontalClose(true)
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
    if isMiniWindow {
      isLandscapePlayer = false
      layoutMiniWindow()
      return
    }
    let full = view.bounds
    let landscape = full.width > full.height
    let wasLandscape = isLandscapePlayer
    isLandscapePlayer = landscape
    wheel.spacingScale = landscape ? 1.0 : 1.5
    if landscape != wasLandscape {
      hideControls()
    }
    let danmakuInset: CGFloat = landscape
      ? 0 : max(76, view.safeAreaInsets.top + 52)
    danmakuOverlay.setTopInset(danmakuInset, animated: true)
    view.backgroundColor = .clear
    let backdropBusy = openingTransition || portraitDragActive
      || portraitShrinking || horizontalCloseActive
    if !backdropBusy {
      backdropHost.frame = full
      backdrop.frame = backdropHost.bounds
      backdropVideo.frame = backdropHost.bounds
      backdropLayer.frame = backdropVideo.bounds
      backdropBlur.frame = backdropHost.bounds
      backdropDim.frame = backdropHost.bounds
    }
    backdrop.isHidden = false
    backdropVideo.isHidden = false
    backdropBlur.isHidden = false
    backdropDim.isHidden = false
    backdropDim.backgroundColor = UIColor.black.withAlphaComponent(landscape ? 0.30 : 0.42)
    dim.frame = full
    topBar.frame = CGRect(x: 0, y: view.safeAreaInsets.top, width: full.width, height: 52)

    if landscape {
      contentController?.setReveal(0)
      if !openingTransition && (panProgress <= 0.001 || closing) {
        videoContainer.frame = full
      }
      videoContainer.layer.cornerRadius = 0
      layoutVideoSubviews()
      danmakuOverlay.frame = full
      let panelHeight: CGFloat = playerPanelHeight
      let panelWidth = max(1, full.width * landscapePanelWidthRatio)
      let panelY = full.height - view.safeAreaInsets.bottom - panelHeight - 6
      bottomPanel.bounds = CGRect(x: 0, y: 0, width: panelWidth, height: panelHeight)
      bottomPanel.center = CGPoint(x: full.midX, y: panelY + panelHeight / 2)
      seekBubble.frame = CGRect(x: full.midX - 40, y: panelY - 27,
                                width: 80, height: 21)
    } else {
      if !portraitDragActive && !portraitSettling && !openingTransition
        && !portraitShrinking && !horizontalCloseActive {
        applyPortraitTransition(portraitTransition)
      } else {
        layoutVideoSubviews()
      }
    }

    bottomPanel.layoutIfNeeded()
    grid.setNeedsDisplay()
    if volumeSlider == nil {
      volumeSlider = findVolumeSlider(in: volumeView)
    }
  }

  private func loadQuality(_ qn: Int, upgrade: Bool = false) {
    currentQuality = qn
    loadToken += 1
    let token = loadToken
    let requestStarted = O11A1Trace.now
    O11A1Trace.mark(
      "player",
      "loadQuality qn=\(qn) upgrade=\(upgrade) bvid=\(item.bvid) cid=\(item.cid) ep=\(item.epId)")
    if !upgrade && !upgradeAdopted {
      upgradePending = false
      upgradeGeneration += 1
      upgradeEngine?.stop()
    }
    if !upgrade {
      applyLoadStatus(VideoLoadStatus(phase: .connecting, bytesPerSecond: 0))
    }
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
          self.loadingView.hide()
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
        O11A1Trace.mark(
          "player",
          "source qn=\(qn) upgrade=\(upgrade) label=\(source.qualityLabel) host=\(URL(string: source.url)?.host ?? "?") \(O11A1Trace.since(requestStarted))")
        if upgrade {
          self.prepareQualityUpgrade(source)
        } else {
          let startAt = self.resumePosition()
          O11A1Trace.mark("player", "startAt \(String(format: "%.1f", startAt))")
          self.engine.load(
            url: source.url,
            backup: source.backup,
            headers: BiliAPI.shared.mediaHeaders,
            autoplay: !self.userPaused,
            muted: false,
            loop: self.loopMode == .single,
            startAt: startAt
          )
          if self.userPaused { self.engine.pause() }
        }
      case .failure:
        O11A1Trace.mark(
          "player",
          "source FAIL qn=\(qn) upgrade=\(upgrade) \(O11A1Trace.since(requestStarted))")
        if upgrade {
          if qn > 64 {
            self.loadQuality(64, upgrade: true)
          } else if qn > 32 {
            self.loadQuality(32, upgrade: true)
          }
          return
        }
        if qn > 64 {
          self.loadQuality(64)
        } else if qn > 32 {
          self.loadQuality(32)
        } else {
          self.loadingView.hide()
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

  private func prepareQualityUpgrade(_ source: PlaySource) {
    guard !upgradeAdopted, let upgrade = upgradeEngine else { return }
    guard handoffLowReady else {
      pendingUpgradeSource = source
      return
    }
    pendingUpgradeLabel = qualityLabel.text ?? ""
    upgradePending = true
    upgradeGeneration += 1
    upgrade.load(
      url: source.url,
      backup: source.backup,
      headers: BiliAPI.shared.mediaHeaders,
      autoplay: false,
      muted: true,
      loop: false,
      startAt: 0
    )
  }

  private func attemptUpgradeSwap() {
    guard upgradePending, !upgradeAdopted, !closing,
          let upgrade = upgradeEngine,
          upgrade.player.currentItem != nil else { return }
    if portraitDragActive || portraitShrinking || horizontalCloseActive {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
        self?.attemptUpgradeSwap()
      }
      return
    }
    upgradePending = false
    seekUpgrade(upgrade, attempts: 0, generation: upgradeGeneration)
  }

  private func seekUpgrade(_ upgrade: VideoEngine, attempts: Int, generation: Int) {
    guard !closing, !upgradeAdopted, generation == upgradeGeneration else { return }
    let target = engine.currentTime
    upgrade.seek(to: target, resume: false) { [weak self] in
      DispatchQueue.main.async {
        guard let self = self, !self.closing, !self.upgradeAdopted,
              generation == self.upgradeGeneration else { return }
        let live = self.engine.currentTime
        if attempts < 1, abs(live - upgrade.currentTime) > 0.28 {
          self.seekUpgrade(upgrade, attempts: attempts + 1, generation: generation)
          return
        }
        self.adoptUpgrade(upgrade)
      }
    }
  }

  private func adoptUpgrade(_ upgrade: VideoEngine) {
    guard !upgradeAdopted else { return }
    upgradeAdopted = true
    upgradePending = false
    let previous = engine
    let shouldPlay = previous.isPlaying
    previous.onTime = nil
    previous.onPlaying = nil
    previous.onReady = nil
    previous.onError = nil
    previous.onLoadStatus = nil
    previous.onPipStart = nil
    previous.onPipClose = nil
    previous.onPipRestore = nil
    previous.pause()
    previous.stopPip()
    previous.stop()
    engine = upgrade
    upgrade.setLoop(loopMode == .single)
    upgrade.onLoadStatus = { [weak self] status in
      self?.applyLoadStatus(status)
    }
    loadingView.hide()
    backdropLayer.player = upgrade.player
    poster.isHidden = true
    errorLabel.isHidden = true
    backdropVideo.alpha = 1
    upgrade.player.isMuted = false
    playerView.alpha = 0
    upgradeView?.frame = videoContainer.bounds
    upgradeView?.alpha = 1
    if shouldPlay {
      upgrade.play()
      applyPlaying(true)
    } else {
      upgrade.pause()
      applyPlaying(false)
    }
    upgrade.enablePiP()
    upgrade.onPipStart = { [weak self] in self?.systemPipDidStart() }
    upgrade.onPipClose = { [weak self] in self?.closeFromPip() }
    upgrade.onPipRestore = { [weak self] in
      self?.closing = false
      self?.videoContainer.isHidden = false
      self?.restoreFromSystemPiP(stopPip: false)
    }
    qualityLabel.text = pendingUpgradeLabel
    applyLoopMode()
    view.setNeedsLayout()
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
    progressLink?.invalidate()
    if let observer = activeObserver {
      NotificationCenter.default.removeObserver(observer)
    }
    if let observer = backgroundWatchObserver {
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

  @objc private func handleSingleTap() {
    if isMiniWindow {
      exitMiniWindow()
      return
    }
    if !isLandscapePlayer && portraitStageIsTop {
      if bottomPanel.alpha > 0.01 {
        hideControls()
      }
      if !closing, !portraitShrinking, !portraitSettling,
         !portraitDragActive, !openingTransition, !horizontalCloseActive {
        settlePortrait(top: false, animated: true)
      }
      return
    }
    let visible = bottomPanel.alpha > 0.5 && !bottomPanel.isHidden
    if visible {
      hideControls()
    } else {
      showControls()
    }
  }

  @objc private func handleDoubleTap() {
    if userPaused {
      userPaused = false
      engine.play()
      applyPlaying(true)
    } else if engine.isPlaying || mediaLoadActive {
      userPaused = true
      engine.pause()
      applyPlaying(false)
    } else {
      userPaused = false
      engine.play()
      applyPlaying(true)
    }
  }

  private func showControls() {
    guard !isMiniWindow, isLandscapePlayer || !portraitStageIsTop else { return }
    controlsVisible = true
    bottomPanel.isUserInteractionEnabled = true
    UIView.animate(withDuration: panelShowDuration, delay: 0,
                   options: [.curveEaseOut, .beginFromCurrentState, .allowUserInteraction]) {
      self.bottomPanel.alpha = 1
      self.bottomPanel.transform = .identity
    }
  }

  private func hideControls() {
    controlsVisible = false
    seekBubble.isHidden = true
    UIView.animate(withDuration: panelHideDuration * panelHideScale, delay: 0,
                   options: [.curveEaseInOut, .beginFromCurrentState, .allowUserInteraction]) {
      self.bottomPanel.alpha = 0
      self.bottomPanel.transform = CGAffineTransform(
        translationX: 0, y: self.panelSlideDistance)
    } completion: { _ in
      if !self.controlsVisible {
        self.bottomPanel.isUserInteractionEnabled = false
      }
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

  @objc private func handleContentClosePan(_ gesture: UIPanGestureRecognizer) {
    let reference = view.superview ?? view
    let width = max(1, view.bounds.width)
    let translation = gesture.translation(in: reference)
    switch gesture.state {
    case .began:
      horizontalSlideLeft = contentCloseStartX > width * 5.0 / 6.0
      horizontalSlideRight = !horizontalSlideLeft
      view.transform = .identity
      beginHorizontalClose()
    case .changed:
      let direction: CGFloat = horizontalSlideLeft ? -1 : 1
      updateHorizontalClose(max(0, min(1, translation.x * direction / width)))
    case .ended, .cancelled:
      guard horizontalCloseActive else { return }
      let velocity = gesture.velocity(in: reference).x
      let far = horizontalSlideLeft
        ? -translation.x > width * 0.22
        : translation.x > width * 0.22
      let fast = horizontalSlideLeft ? velocity < -380 : velocity > 380
      finishHorizontalClose(far || fast)
    default:
      break
    }
  }

  @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
    if portraitShrinking || isMiniWindow || horizontalCloseActive { return }
    let reference = view.superview ?? view
    let translation = gesture.translation(in: reference)
    switch gesture.state {
    case .began:
      closeSwipe = false
      landscapeDrag = false
      landscapeAdjusting = false
      landscapeControl = .none
      portraitUpDrag = false
      portraitRestoreDrag = false
      portraitDownClose = false
      panDirectionDecided = false
      portraitDragActive = true
      let wasSettling = portraitSettling
      portraitSettleToken += 1
      portraitSettling = false
      if wasSettling {
        videoContainer.layer.removeAllAnimations()
        bottomPanel.layer.removeAllAnimations()
        contentController?.view.layer.removeAllAnimations()
        danmakuOverlay.layer.removeAllAnimations()
        portraitTransition = portraitStageIsTop ? 1 : 0
        applyPortraitTransition(portraitTransition)
      }
      portraitDragBase = portraitTransition
      panStartFrame = videoContainer.frame
      panProgress = 0
      view.transform = .identity
      view.layer.cornerRadius = 0
      if isLandscapePlayer {
        let x = gesture.location(in: view).x
        let width = max(1, view.bounds.width)
        if x < width / 3.0 {
          landscapeControl = .brightness
          landscapeStartValue = Float(UIScreen.main.brightness)
        } else if x > width * 2.0 / 3.0 {
          landscapeControl = .volume
          if volumeSlider == nil {
            volumeSlider = findVolumeSlider(in: volumeView)
          }
          landscapeStartValue = volumeSlider?.value ?? 0.5
        }
      }
      let velocity = gesture.velocity(in: videoContainer)
      if abs(velocity.x) > abs(velocity.y) && abs(velocity.x) > 80 {
        panDirectionDecided = true
      }
    case .changed:
      if !panDirectionDecided {
        let threshold: CGFloat = 12
        if abs(translation.x) > threshold || abs(translation.y) > threshold {
          if abs(translation.x) > abs(translation.y) * 1.15 {
            panDirectionDecided = true
          } else if !isLandscapePlayer {
            panDirectionDecided = true
            if translation.y < 0 {
              portraitUpDrag = true
            } else if portraitDragBase <= 0.02 {
              portraitDownClose = true
            } else {
              portraitRestoreDrag = true
            }
          } else {
            panDirectionDecided = true
            if landscapeControl != .none {
              landscapeAdjusting = true
              hideControls()
            }
            // Landscape middle has no vertical close gesture.
          }
        }
      }
      if closeSwipe {
        if !horizontalCloseActive {
          horizontalSlideRight = true
          beginHorizontalClose()
        }
        let width = max(1, view.bounds.width)
        updateHorizontalClose(max(0, min(1, translation.x / width)))
        return
      }
      if isLandscapePlayer && landscapeAdjusting {
        applyVerticalControl(translation, control: landscapeControl,
                             base: landscapeStartValue)
        return
      }
      if portraitDownClose {
        return
      }
      guard !isLandscapePlayer || landscapeDrag else { return }
      if !isLandscapePlayer {
        let rects = portraitVideoRects()
        let distance = max(120, rects.center.minY - rects.top.minY)
        if portraitUpDrag || portraitRestoreDrag {
          let p = portraitDragBase - translation.y / distance
          applyPortraitTransition(max(0, min(1, p)))
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
      if closeSwipe {
        closeSwipe = false
        panDirectionDecided = false
        portraitDragActive = false
        let width = max(1, view.bounds.width)
        let shouldClose = translation.x > width * 0.22 || endVelocity.x > 380
        finishHorizontalClose(shouldClose)
        return
      }
      if landscapeAdjusting {
        landscapeAdjusting = false
        landscapeControl = .none
        landscapeDrag = false
        panDirectionDecided = false
        portraitDragActive = false
        return
      }
      if portraitDownClose {
        portraitDownClose = false
        panDirectionDecided = false
        portraitDragActive = false
        if translation.y > 80 || endVelocity.y > 500 {
          startSystemPiPFromGesture()
        }
        return
      }
      if isLandscapePlayer && !landscapeDrag {
        landscapeDrag = false
        landscapeControl = .none
        panDirectionDecided = false
        portraitDragActive = false
        return
      }
      landscapeDrag = false
      landscapeControl = .none
      if !isLandscapePlayer {
        let rects = portraitVideoRects()
        let distance = max(120, rects.center.minY - rects.top.minY)
        if portraitUpDrag || portraitRestoreDrag {
          portraitUpDrag = false
          portraitRestoreDrag = false
          panDirectionDecided = false
          let p = max(0, min(1, portraitDragBase - translation.y / distance))
          let targetTop: Bool
          if endVelocity.y < -420 {
            targetTop = true
          } else if endVelocity.y > 420 {
            targetTop = false
          } else {
            targetTop = p > 0.5
          }
          settlePortrait(top: targetTop, animated: true)
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

  private func selectPage(_ page: VideoPage) {
    guard page.cid > 0, page.cid != item.cid else { return }
    saveWatchProgress()
    item.cid = page.cid
    if page.duration > 0 {
      item.durationSec = page.duration
      item.duration = format(Double(page.duration))
    }
    forcePageStart = true
    lastProgressSave = 0
    lastHistoryReport = 0
    userPaused = false
    lastAppliedPlaying = false
    engine.stop()
    danmakuOverlay.load(cid: page.cid)
    contentController?.setCurrentPage(page)
    loadQuality(currentQuality)
  }

  private func openRelatedPanel() {
    hideControls()
    ensurePlayerContent().select(.related)
  }

  func play(_ value: VideoItem, startAt: Double = 0) {
    pendingStartSeconds = max(0, startAt)
    replace(with: value)
  }

  private func replace(with value: VideoItem) {
    guard value.bvid != item.bvid || value.roomId != item.roomId else { return }
    if !advancingLoop {
      loopQueue = []
      loopIndex = 0
      loadingNextLoop = false
    }
    closeSettingsPanel()
    stopLiveChat()
    cancelUpgradePreload()
    saveWatchProgress()
    engine.stop()
    controlsVisible = false
    bottomPanel.alpha = 0
    bottomPanel.transform = CGAffineTransform(translationX: 0, y: panelSlideDistance)
    bottomPanel.isUserInteractionEnabled = false
    item = value
    lastProgressSave = 0
    lastHistoryReport = 0
    userPaused = false
    lastAppliedPlaying = false
    forcePageStart = false
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
    contentController?.update(
      item: value,
      quality: currentQuality,
      danmaku: danmakuOverlay.enabled,
      loop: loopMode == .single,
      select: .comments
    )
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
    hideControls()
    ensurePlayerContent().select(.detail)
  }

  private func openSettingsPanel() {
    guard settingsPanel == nil else { return }
    hideControls()
    let panel = SettingsSheetViewController(
      title: "播放设置", rows: playbackSettingsRows())
    panel.onClose = { [weak self] in
      self?.settingsPanel = nil
      self?.setNeedsStatusBarAppearanceUpdate()
    }
    settingsPanel = panel
    present(panel, animated: false)
    setNeedsStatusBarAppearanceUpdate()
  }

  private func closeSettingsPanel() {
    guard let panel = settingsPanel else { return }
    settingsPanel = nil
    setNeedsStatusBarAppearanceUpdate()
    panel.dismiss(animated: false)
  }

  private func playbackSettingsRows() -> [SettingsSheetRow] {
    var rows: [SettingsSheetRow] = [.section("画质")]
    rows.append(.gridChoices(
      label: "当前画质", options: PlaybackSettings.qualityOptions,
      selected: PlaybackSettings.qualityName(currentQuality), columns: 3) {
      [weak self] name in
      guard let self = self else { return }
      let qn = PlaybackSettings.qualityValue(name)
      self.currentQuality = qn
      ThemeManager.shared.quality = qn
      self.loadQuality(qn)
    })
    rows.append(.gridChoices(
      label: "默认画质", options: PlaybackSettings.qualityOptions,
      selected: PlaybackSettings.defaultQualityName(), columns: 3) { name in
      UserDefaults.standard.set(name, forKey: "o11a1.defaultQuality")
      ThemeManager.shared.quality = PlaybackSettings.qualityValue(name)
    })
    rows.append(.section("播放"))
    rows.append(.gridChoices(
      label: "循环模式", options: PlaybackSettings.loopOptions,
      selected: loopMode.title, columns: 3) { [weak self] name in
      self?.setLoopMode(PlaybackLoopMode.from(title: name))
    })

    let defaults = UserDefaults.standard
    rows.append(.section("弹幕"))
    rows.append(.toggle(
      label: "弹幕显示", detail: nil, isOn: danmakuOverlay.enabled) {
      [weak self] on in
      self?.danmakuOverlay.setEnabled(on)
      UserDefaults.standard.set(on, forKey: "danmaku_enabled")
      self?.danmakuToggle.alpha = on ? 1 : 0.45
    })
    rows.append(.slider(
      label: "不透明度", min: 0, max: 100,
      value: defaults.object(forKey: "danmaku_opacity") == nil
        ? 88 : defaults.float(forKey: "danmaku_opacity"),
      unit: "%", step: 1, format: nil) { [weak self] value in
      UserDefaults.standard.set(value, forKey: "danmaku_opacity")
      self?.danmakuOverlay.applyStoredSettings()
    })
    rows.append(.slider(
      label: "字号", min: 50, max: 150,
      value: defaults.object(forKey: "danmaku_size") == nil
        ? 100 : defaults.float(forKey: "danmaku_size"),
      unit: "%", step: 1, format: nil) { [weak self] value in
      UserDefaults.standard.set(value, forKey: "danmaku_size")
      self?.danmakuOverlay.applyStoredSettings()
    })
    rows.append(.slider(
      label: "速度", min: 50, max: 200,
      value: defaults.object(forKey: "danmaku_speed") == nil
        ? 100 : defaults.float(forKey: "danmaku_speed"),
      unit: "", step: 1,
      format: { String(format: "%.1f×", Double($0) / 100.0) }) {
      [weak self] value in
      UserDefaults.standard.set(value, forKey: "danmaku_speed")
      self?.danmakuOverlay.applyStoredSettings()
    })
    rows.append(.slider(
      label: "显示区域", min: DanmakuSettings.areaMinimum,
      max: DanmakuSettings.areaMaximum,
      value: DanmakuSettings.areaPercent(),
      unit: "%", step: DanmakuSettings.areaStep, format: nil) {
      [weak self] value in
      DanmakuSettings.setAreaPercent(value)
      self?.danmakuOverlay.applyStoredSettings()
    })
    rows.append(.toggle(
      label: "分布密度", detail: nil,
      isOn: defaults.object(forKey: "danmaku_density") == nil
        ? true : defaults.bool(forKey: "danmaku_density")) {
      [weak self] value in
      UserDefaults.standard.set(value, forKey: "danmaku_density")
      self?.danmakuOverlay.applyStoredSettings()
    })
    return rows
  }

  private func setLoopMode(_ mode: PlaybackLoopMode) {
    loopMode = mode
    mode.store()
    applyLoopMode()
  }

  private func applyLoopMode() {
    let single = loopMode == .single
    engine.setLoop(single)
    upgradeEngine?.setLoop(single)
    engine.onEnd = { [weak self] in self?.handlePlaybackEnded() }
    upgradeEngine?.onEnd = { [weak self] in self?.handlePlaybackEnded() }
  }

  private func handlePlaybackEnded() {
    guard loopMode == .list, !closing, !loadingNextLoop else { return }
    loadingNextLoop = true
    if loopQueue.isEmpty {
      BiliAPI.shared.related(item.bvid) { [weak self] result in
        guard let self = self else { return }
        self.loadingNextLoop = false
        guard case .success(let values) = result else { return }
        self.loopQueue = values.filter {
          $0.bvid != self.item.bvid && $0.seasonId == 0 && $0.kind != "season"
        }
        self.loopIndex = 0
        self.playNextLoopItem()
      }
    } else {
      loadingNextLoop = false
      playNextLoopItem()
    }
  }

  private func playNextLoopItem() {
    guard loopMode == .list, !loopQueue.isEmpty else { return }
    if loopIndex >= loopQueue.count { loopIndex = 0 }
    let next = loopQueue[loopIndex]
    loopIndex = (loopIndex + 1) % loopQueue.count
    guard next.bvid != item.bvid else { return }
    advancingLoop = true
    replace(with: next)
    advancingLoop = false
  }

  func testOpenDetail() {
    openDetailPanel()
  }

  func testOpenDanmakuSettings() {
    ensurePlayerContent().testExpandDanmaku()
  }

  func testOpenComments() {
    ensurePlayerContent().select(.comments)
  }

  func testOpenSettings() {
    openSettingsPanel()
  }

  func testOpenRelated() {
    openRelatedPanel()
  }

  func testShowControls(hold: Bool) {
    showControls()
  }

  func testHideControls() {
    hideControls()
  }

  func testPause() {
    handleDoubleTap()
    hideControls()
  }

  func testOpenProfile() {
    openProfile()
  }

  func testCommentsStage() {
    settlePortrait(top: true, animated: false)
  }

  func testMinimize() {
    guard !isMiniWindow, !isSystemPip else { return }
    portraitStageIsTop = false
    portraitTransition = 0
    applyPortraitTransition(0)
    startSystemPiPFromGesture()
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

  func testPortrait() {
    if #available(iOS 16.0, *) {
      view.window?.windowScene?.requestGeometryUpdate(
        .iOS(interfaceOrientations: .portrait))
    } else {
      UIDevice.current.setValue(
        UIInterfaceOrientation.portrait.rawValue,
        forKey: "orientation")
      UIViewController.attemptRotationToDeviceOrientation()
    }
  }

  @objc private func closeTapped() {
    closePlayer(animated: true)
  }

  private func cancelUpgradePreload() {
    upgradePending = false
    upgradeGeneration += 1
    if let upgrade = upgradeEngine, upgrade !== engine {
      upgrade.stop()
    }
  }

  private func closePlayer(animated: Bool) {
    guard !closing else { return }
    closing = true
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    if #available(iOS 16.0, *) {
      view.window?.windowScene?.requestGeometryUpdate(
        .iOS(interfaceOrientations: .portrait))
    }
    stopLiveChat()
    stopProgressLink()
    cancelUpgradePreload()
    loadingView.hide()
    saveWatchProgress()
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
    isSystemPip = false
    stopLiveChat()
    stopProgressLink()
    cancelUpgradePreload()
    saveWatchProgress()
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
    if gestureRecognizer === contentClosePan {
      guard !closing, !isLandscapePlayer, !isMiniWindow, portraitCloseReady,
            !portraitShrinking, !horizontalCloseActive,
            let pan = gestureRecognizer as? UIPanGestureRecognizer else {
        return false
      }
      let width = max(1, view.bounds.width)
      let translation = pan.translation(in: view)
      let velocity = pan.velocity(in: view)
      let leftZone = contentCloseStartX > width * 5.0 / 6.0
      let rightZone = contentCloseStartX < width / 6.0
      let movingLeft = translation.x < -2 || velocity.x < -80
      let movingRight = translation.x > 2 || velocity.x > 80
      guard (leftZone && movingLeft) || (rightZone && movingRight) else {
        return false
      }
      return abs(translation.x) > abs(translation.y) * 1.15
        || abs(velocity.x) > abs(velocity.y) * 1.15
    }
    if let pan = gestureRecognizer as? UIPanGestureRecognizer {
      let velocity = pan.velocity(in: videoContainer)
      let translation = pan.translation(in: videoContainer)
      return abs(velocity.x) > 20 || abs(velocity.y) > 20
        || abs(translation.x) > 6 || abs(translation.y) > 6
    }
    return true
  }

  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                         shouldReceive touch: UITouch) -> Bool {
    if gestureRecognizer === contentClosePan {
      contentCloseStartX = touch.location(in: view).x
    }
    if touch.view is UIControl { return false }
    if touch.view?.isDescendant(of: bottomPanel) == true { return false }
    if touch.view?.isDescendant(of: topBar) == true { return false }
    if gestureRecognizer !== contentClosePan,
       gestureRecognizer !== longPressRecognizer,
       let content = contentController,
       touch.view?.isDescendant(of: content.view) == true { return false }
    return true
  }

  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                         shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
    return gestureRecognizer === contentClosePan || other === contentClosePan
  }
}

/// A bare SF Symbol rendered as frosted glass: the blur is masked to the glyph
/// itself, so there is no circle or panel behind it, only the frosted shape.
final class FrostedGlyphView: UIView {
  private let blur = UIVisualEffectView(
    effect: UIBlurEffect(style: .systemThinMaterialLight))
  private let glyphMask = UIImageView()
  private let glyph = UIImageView()

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
    isUserInteractionEnabled = false
    blur.isUserInteractionEnabled = false
    blur.contentView.backgroundColor = UIColor.white.withAlphaComponent(0.14)
    addSubview(blur)

    glyphMask.contentMode = .scaleAspectFit
    blur.mask = glyphMask

    glyph.contentMode = .scaleAspectFit
    glyph.tintColor = .white
    glyph.alpha = 0.5
    glyph.layer.shadowColor = UIColor.black.cgColor
    glyph.layer.shadowOpacity = 0.55
    glyph.layer.shadowRadius = 11
    glyph.layer.shadowOffset = CGSize(width: 0, height: 2)
    addSubview(glyph)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func setSymbol(_ name: String, pointSize: CGFloat) {
    let configuration = UIImage.SymbolConfiguration(
      pointSize: pointSize, weight: .semibold)
    guard let image = UIImage(
      systemName: name, withConfiguration: configuration) else { return }
    glyphMask.image = image.withTintColor(.white, renderingMode: .alwaysOriginal)
    glyph.image = image
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    blur.frame = bounds
    glyphMask.frame = blur.bounds
    glyph.frame = bounds
  }
}
