import AVKit
import UIKit

final class PlayerViewController: UIViewController, UIGestureRecognizerDelegate {
  let item: VideoItem
  var onClose: (() -> Void)?
  var onProfile: ((Int64) -> Void)?

  private let engine = VideoEngine()
  private lazy var playerView = PlayerLayerView(playerLayer: engine.playerLayer)
  private let videoContainer = UIView()
  private let poster = UIImageView()
  private let dim = UIView()
  private let topBar = UIView()
  private let backButton = UIButton(type: .system)
  private let titleLabel = UILabel()
  private let playButton = UIButton(type: .system)
  private let bottomPanel = UIView()
  private let bottomBlur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
  private let ownerLabel = UILabel()
  private let ownerButton = UIButton(type: .system)
  private let wheel = ProgressWheel()
  private let grid = GridProgressBar()
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
  private var commentsSwipe = false
  private var detailSwipe = false
  private var settingsSwipe = false
  private var detailPanel: VideoDetailViewController?
  private var settingsPanel: PlayerSettingsViewController?
  private var loopOn = false
  private var controlsVisible = true
  private var controlsTimer: Timer?

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

  override var prefersStatusBarHidden: Bool { false }
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return traitCollection.userInterfaceStyle == .dark ? .lightContent : .darkContent
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear
    view.clipsToBounds = true

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
    followButton.layer.cornerRadius = 12
    followButton.layer.cornerCurve = .continuous
    followButton.addTarget(self, action: #selector(followTapped), for: .touchUpInside)
    topBar.addSubview(followButton)

    playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
    playButton.tintColor = .white
    playButton.backgroundColor = UIColor.black.withAlphaComponent(0.30)
    playButton.layer.cornerRadius = 32
    playButton.addTarget(self, action: #selector(togglePlay), for: .touchUpInside)
    view.addSubview(playButton)

    bottomPanel.layer.cornerRadius = 22
    bottomPanel.layer.cornerCurve = .continuous
    bottomPanel.clipsToBounds = true
    bottomPanel.layer.borderWidth = 1
    view.addSubview(bottomPanel)

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
    videoContainer.addSubview(danmakuOverlay)

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
      wheel.topAnchor.constraint(equalTo: content.topAnchor, constant: 38),
      wheel.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -4),

      grid.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 14),
      grid.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -14),
      grid.topAnchor.constraint(equalTo: content.topAnchor, constant: 5),
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

    let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
    doubleTap.numberOfTapsRequired = 2
    doubleTap.delegate = self
    videoContainer.addGestureRecognizer(doubleTap)

    let tap = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap))
    tap.require(toFail: doubleTap)
    tap.delegate = self
    videoContainer.addGestureRecognizer(tap)

    let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
    longPress.minimumPressDuration = 0.18
    longPress.delegate = self
    videoContainer.addGestureRecognizer(longPress)

    let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
    pan.delegate = self
    videoContainer.addGestureRecognizer(pan)

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
      self.videoContainer.backgroundColor = playing ? .black : NativeTheme.pipRose
      if playing {
        if self.controlsVisible { self.scheduleControlsHide() }
      } else {
        self.showControls()
      }
    }
    engine.onReady = { [weak self] in
      guard let self = self else { return }
      self.poster.isHidden = true
      self.errorLabel.isHidden = true
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
    [ownerLabel, ownerButton, qualityLabel, speedLabel, commentsButton,
     likeButton, coinButton, favButton].forEach { $0.removeFromSuperview() }
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
      let target = view.bounds
      videoContainer.frame = view.convert(sourceFrame, from: nil)
      UIView.animate(withDuration: 0.30, delay: 0, options: [.curveEaseOut]) {
        self.videoContainer.frame = target
      }
      sourceFrame = .zero
    }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    let full = view.bounds
    if panProgress <= 0.001 || closing {
      videoContainer.frame = full
    }
    dim.frame = view.bounds
    topBar.frame = CGRect(x: 0, y: view.safeAreaInsets.top, width: full.width, height: 52)
    playerView.frame = videoContainer.bounds
    poster.frame = videoContainer.bounds
    danmakuOverlay.frame = videoContainer.bounds
    playButton.center = CGPoint(x: videoContainer.center.x, y: videoContainer.center.y)
    let panelHeight: CGFloat = 92
    let panelWidth = min(560, full.width - 32)
    bottomPanel.frame = CGRect(
      x: (full.width - panelWidth) / 2,
      y: full.height - view.safeAreaInsets.bottom - panelHeight - 2,
      width: panelWidth,
      height: panelHeight
    )
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
    danmakuOverlay.setEnabled(!danmakuOverlay.enabled)
    danmakuToggle.alpha = danmakuOverlay.enabled ? 1 : 0.45
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
    if controlsVisible {
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
      UIImpactFeedbackGenerator(style: .light).impactOccurred()
    case .ended, .cancelled, .failed:
      engine.setRate(1.0)
    default:
      break
    }
  }

  @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
    let translation = gesture.translation(in: view)
    switch gesture.state {
    case .began:
      let velocity = gesture.velocity(in: videoContainer)
      if abs(velocity.x) > abs(velocity.y) {
        if velocity.x < 0 {
          commentsSwipe = true
          return
        }
        detailSwipe = true
        return
      }
      if velocity.y < -80 {
        settingsSwipe = true
        return
      }
      commentsSwipe = false
      detailSwipe = false
      settingsSwipe = false
      panStartFrame = videoContainer.frame
      panProgress = 0
    case .changed:
      guard !commentsSwipe && !detailSwipe && !settingsSwipe else { return }
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
      if commentsSwipe {
        commentsSwipe = false
        if translation.x < -60 {
          openCommentsPanel()
        }
        return
      }
      if detailSwipe {
        detailSwipe = false
        if translation.x > 60 {
          openDetailPanel()
        }
        return
      }
      if settingsSwipe {
        settingsSwipe = false
        if translation.y < -40 {
          openSettingsPanel()
        }
        return
      }
      let velocity = gesture.velocity(in: view).y
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
    detail.onProfile = { [weak self] mid in self?.onProfile?(mid) }
    detail.onClose = { [weak self] in self?.closeDetailPanel() }
    addChild(detail)
    detail.view.frame = view.bounds
    detail.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.addSubview(detail.view)
    detail.didMove(toParent: self)
    detailPanel = detail
    detail.view.transform = CGAffineTransform(translationX: -view.bounds.width, y: 0)
    UIView.animate(withDuration: 0.34, delay: 0, options: [.curveEaseOut]) {
      detail.view.transform = .identity
    }
  }

  private func closeDetailPanel() {
    guard let detail = detailPanel else { return }
    detailPanel = nil
    detail.willMove(toParent: nil)
    UIView.animate(withDuration: 0.28, delay: 0, options: [.curveEaseIn]) {
      detail.view.transform = CGAffineTransform(translationX: -self.view.bounds.width, y: 0)
    } completion: { _ in
      detail.view.removeFromSuperview()
      detail.removeFromParent()
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
    panel.view.alpha = 0
    UIView.animate(withDuration: 0.3) {
      panel.view.alpha = 1
    }
  }

  private func closeSettingsPanel() {
    guard let panel = settingsPanel else { return }
    settingsPanel = nil
    panel.willMove(toParent: nil)
    UIView.animate(withDuration: 0.24) {
      panel.view.alpha = 0
    } completion: { _ in
      panel.view.removeFromSuperview()
      panel.removeFromParent()
    }
  }

  @objc private func closeTapped() {
    closePlayer(animated: true)
  }

  private func closePlayer(animated: Bool) {
    guard !closing else { return }
    closing = true
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
      return
    }
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
      if abs(velocity.x) > abs(velocity.y) {
        return abs(velocity.x) > 60
      }
      return abs(velocity.y) > 60
    }
    return true
  }

  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    if touch.view is UIControl { return false }
    if touch.view?.isDescendant(of: bottomPanel) == true { return false }
    if touch.view?.isDescendant(of: topBar) == true { return false }
    return true
  }
}
