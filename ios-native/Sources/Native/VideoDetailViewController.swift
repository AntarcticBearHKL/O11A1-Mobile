import UIKit

final class VideoDetailViewController: UIViewController, UIGestureRecognizerDelegate,
  UIScrollViewDelegate {
  var onClose: (() -> Void)?
  var onProfile: ((Int64) -> Void)?
  var onOpenVideo: ((VideoItem) -> Void)?
  var onQuality: ((Int) -> Void)?
  var onDanmaku: ((Bool) -> Void)?
  var onDanmakuSettingsChanged: (() -> Void)?
  var onLoop: ((Bool) -> Void)?
  var embedded = false
  var onSwipeRight: (() -> Void)?
  var onSwipeRightBegan: (() -> Void)?
  var onSwipeRightChanged: ((CGFloat) -> Void)?
  var onSwipeRightEnded: ((Bool) -> Void)?
  var onPullDown: ((CGFloat) -> Void)?
  var onPullDownEnded: ((Bool) -> Void)?
  var onScroll: ((CGFloat, CGFloat) -> Void)?
  var initialQuality = 80
  var initialDanmakuOn = true
  var initialLoopOn = false

  private let item: VideoItem
  private let detailCardHeight: CGFloat = 80
  private let detailCardRadius: CGFloat = 10
  private let scroll = UIScrollView()
  private let headerTitle = UILabel()
  private let headerBar = UIView()
  private let headerBlur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
  private let card = UIView()
  private let cover = UIImageView()
  private let durationChip = UILabel()
  private let titleLabel = UILabel()
  private let dateLabel = UILabel()
  private let bvidLabel = UILabel()
  private let playLabel = UILabel()
  private let copyButton = UIButton(type: .system)
  private let timeLabel = UILabel()
  private let avatar = UIImageView()
  private let ownerName = UILabel()
  private let ownerMeta = UILabel()
  private let ownerHero = ProfileHeroBackground()
  private let ownerRing = ProfileAvatarRing()
  private let followButton = UIButton(type: .custom)
  private var authorTap: UITapGestureRecognizer?
  private var following = false
  private var followStateLoaded = false
  private var feedMid: Int64 = 0
  private var latestVideos: [VideoItem] = []
  private var popularRaw: [VideoItem] = []
  private var latestSection: UIView?
  private var popularSection: UIView?
  private var latestStack: UIStackView?
  private var popularStack: UIStackView?
  private var latestScroll: UIScrollView?
  private var popularScroll: UIScrollView?
  private let likeValue = UILabel()
  private let favoriteValue = UILabel()
  private let coinValue = UILabel()
  private let likeIcon = UIImageView()
  private let coinIcon = UIImageView()
  private let favoriteIcon = UIImageView()
  private let shareIcon = UIImageView()
  private let shareTitle = UILabel()
  private var likeCount: Int64 = 0
  private var favoriteCount: Int64 = 0
  private var coinCount: Int64 = 0
  private var liked = false
  private var faved = false
  private var coined = false
  private var favoriteFolderId: Int64 = 0
  private var detailAid: Int64 = 0
  private var detailBvid = ""
  private let descLabel = UILabel()
  private let descCard = UIView()
  private let qualitySetting = UILabel()
  private let danmakuSetting = UILabel()
  private let loopSetting = UILabel()
  private let qualityChips = UIStackView()
  private var qualityButtons: [UIButton] = []
  private var qualityValue = 80
  private var danmakuOn = true
  private var loopOn = false
  private let danmakuPanel = UIStackView()
  private var danmakuValueLabels: [UILabel] = []
  private var danmakuSliders: [UISlider] = []
  private var danmakuAreaPercent = DanmakuSettings.defaultAreaPercent
  private var danmakuAreaSlider: UISlider?
  private var danmakuAreaValueLabel: UILabel?
  private var danmakuOpacity: Float = 88
  private var danmakuSize: Float = 100
  private var danmakuSpeed: Float = 100
  private var danmakuDensity = true
  private var detailMid: Int64 = 0
  private var dismissPan: UIPanGestureRecognizer?
  private var closeSwipePan: UIPanGestureRecognizer?
  private var closeSwipeStarted = false
  private var pullDownPan: UIPanGestureRecognizer?
  private var pullDownArmed = false
  private var lastDockScrollPosition: CGFloat?

  init(item: VideoItem) {
    self.item = item
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear
    favoriteFolderId = Int64(
      UserDefaults.standard.integer(forKey: "o11a1.favoriteFolderId"))

    card.backgroundColor = NativeTheme.surface
    card.layer.cornerRadius = embedded ? 0 : NativeTheme.cornerRadius
    card.layer.cornerCurve = .continuous
    card.clipsToBounds = true
    view.addSubview(card)
    card.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      card.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      card.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      card.topAnchor.constraint(equalTo: view.topAnchor),
      card.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    if embedded {
      headerBar.backgroundColor = .clear
      view.addSubview(headerBar)
      headerBar.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        headerBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        headerBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        headerBar.topAnchor.constraint(equalTo: view.topAnchor),
        headerBar.heightAnchor.constraint(equalToConstant: 56),
      ])
      headerBlur.isUserInteractionEnabled = false
      headerBlur.clipsToBounds = true
      headerBlur.contentView.backgroundColor = NativeTheme.glassWhite
      headerBar.addSubview(headerBlur)
      headerBlur.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        headerBlur.leadingAnchor.constraint(equalTo: headerBar.leadingAnchor),
        headerBlur.trailingAnchor.constraint(equalTo: headerBar.trailingAnchor),
        headerBlur.topAnchor.constraint(equalTo: headerBar.topAnchor),
        headerBlur.bottomAnchor.constraint(equalTo: headerBar.bottomAnchor),
      ])
      let headerLine = UIView()
      headerLine.backgroundColor = NativeTheme.hairline
      headerLine.isUserInteractionEnabled = false
      headerBar.addSubview(headerLine)
      headerLine.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        headerLine.leadingAnchor.constraint(equalTo: headerBar.leadingAnchor, constant: 18),
        headerLine.trailingAnchor.constraint(equalTo: headerBar.trailingAnchor, constant: -18),
        headerLine.bottomAnchor.constraint(equalTo: headerBar.bottomAnchor),
        headerLine.heightAnchor.constraint(equalToConstant: 0.5),
      ])
      headerTitle.text = "详情"
      headerTitle.font = UIFont.systemFont(ofSize: 16, weight: .bold)
      headerTitle.textColor = NativeTheme.foreground
      view.addSubview(headerTitle)
      headerTitle.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        headerTitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
        headerTitle.centerYAnchor.constraint(equalTo: view.topAnchor, constant: 28),
      ])
      view.bringSubviewToFront(headerTitle)
    }

    scroll.alwaysBounceVertical = true
    scroll.showsVerticalScrollIndicator = false
    scroll.contentInsetAdjustmentBehavior = .never
    scroll.delegate = self
    card.addSubview(scroll)
    scroll.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      scroll.leadingAnchor.constraint(equalTo: card.leadingAnchor),
      scroll.trailingAnchor.constraint(equalTo: card.trailingAnchor),
      scroll.topAnchor.constraint(equalTo: card.topAnchor),
      scroll.bottomAnchor.constraint(equalTo: card.bottomAnchor),
    ])

    let stack = UIStackView()
    stack.axis = .vertical
    stack.alignment = .fill
    stack.spacing = 14
    scroll.addSubview(stack)
    stack.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 20),
      stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -20),
      stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor,
                                 constant: embedded ? 12 : view.safeAreaInsets.top + 16),
      stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -32),
      stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -40),
    ])

    cover.contentMode = .scaleAspectFill
    cover.clipsToBounds = true
    cover.layer.cornerRadius = NativeTheme.cornerRadius
    cover.layer.cornerCurve = .continuous
    cover.backgroundColor = NativeTheme.tertiary.withAlphaComponent(0.18)
    ImageLoader.shared.load(item.pic, into: cover)
    let hero = UIView()
    hero.addSubview(cover)
    cover.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      cover.leadingAnchor.constraint(equalTo: hero.leadingAnchor),
      cover.trailingAnchor.constraint(equalTo: hero.trailingAnchor),
      cover.topAnchor.constraint(equalTo: hero.topAnchor),
      cover.bottomAnchor.constraint(equalTo: hero.bottomAnchor),
      cover.heightAnchor.constraint(equalTo: cover.widthAnchor, multiplier: 9.0 / 16.0),
    ])
    durationChip.text = item.duration
    durationChip.font = NativeTheme.numberFont(11)
    durationChip.textColor = .white
    durationChip.textAlignment = .center
    durationChip.backgroundColor = UIColor.black.withAlphaComponent(0.78)
    durationChip.layer.cornerRadius = NativeTheme.cornerRadius
    durationChip.clipsToBounds = true
    hero.addSubview(durationChip)
    durationChip.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      durationChip.trailingAnchor.constraint(equalTo: hero.trailingAnchor, constant: -8),
      durationChip.bottomAnchor.constraint(equalTo: hero.bottomAnchor, constant: -8),
      durationChip.widthAnchor.constraint(greaterThanOrEqualToConstant: 40),
      durationChip.heightAnchor.constraint(equalToConstant: 18),
    ])
    stack.addArrangedSubview(hero)
    hero.isHidden = embedded

    titleLabel.text = item.title
    titleLabel.font = UIFont.systemFont(ofSize: 19, weight: .bold)
    titleLabel.textColor = NativeTheme.foreground
    titleLabel.numberOfLines = 0
    stack.addArrangedSubview(titleLabel)

    let meta = UIStackView()
    meta.axis = .horizontal
    meta.spacing = 6
    meta.alignment = .center

    bvidLabel.font = NativeTheme.numberFont(10.5)
    bvidLabel.textColor = NativeTheme.tertiary
    bvidLabel.text = item.bvid
    bvidLabel.lineBreakMode = .byTruncatingTail

    let copyConfig = UIImage.SymbolConfiguration(pointSize: 8, weight: .semibold)
    copyButton.setImage(UIImage(systemName: "doc.on.doc", withConfiguration: copyConfig),
                        for: .normal)
    copyButton.tintColor = NativeTheme.tertiary
    copyButton.addTarget(self, action: #selector(copyBvid), for: .touchUpInside)
    copyButton.translatesAutoresizingMaskIntoConstraints = false
    copyButton.widthAnchor.constraint(equalToConstant: 14).isActive = true
    copyButton.heightAnchor.constraint(equalToConstant: 14).isActive = true

    let bvidRow = UIStackView(arrangedSubviews: [bvidLabel, copyButton])
    bvidRow.axis = .horizontal
    bvidRow.spacing = 4
    bvidRow.alignment = .center

    playLabel.font = NativeTheme.numberFont(10.5)
    playLabel.textColor = NativeTheme.playCountColor(item.play)
    playLabel.text = (item.playText.isEmpty ? o11a1Count(item.play) : item.playText) + "播放"

    dateLabel.font = NativeTheme.numberFont(10.5)
    dateLabel.textColor = NativeTheme.freshnessColor(item.pubdate)
    dateLabel.text = Self.dateText(item.pubdate)

    let metaDot = UILabel()
    metaDot.text = "·"
    metaDot.font = NativeTheme.numberFont(10.5)
    metaDot.textColor = NativeTheme.tertiary

    let metaSpacer = UIView()
    metaSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
    metaSpacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    [bvidRow, metaSpacer, playLabel, metaDot, dateLabel].forEach {
      meta.addArrangedSubview($0)
    }
    stack.addArrangedSubview(meta)

    let author = UIView()
    author.backgroundColor = .clear
    author.layer.cornerRadius = NativeTheme.cornerRadius
    author.layer.cornerCurve = .continuous
    author.layer.shadowColor = UIColor.black.cgColor
    author.layer.shadowOpacity = 0.12
    author.layer.shadowRadius = 18
    author.layer.shadowOffset = CGSize(width: 0, height: 8)
    author.clipsToBounds = false
    stack.addArrangedSubview(author)
    author.heightAnchor.constraint(equalToConstant: 108).isActive = true

    author.addSubview(ownerHero)
    ownerHero.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      ownerHero.leadingAnchor.constraint(equalTo: author.leadingAnchor),
      ownerHero.trailingAnchor.constraint(equalTo: author.trailingAnchor),
      ownerHero.topAnchor.constraint(equalTo: author.topAnchor),
      ownerHero.bottomAnchor.constraint(equalTo: author.bottomAnchor),
    ])

    ownerRing.isUserInteractionEnabled = false
    author.addSubview(ownerRing)
    ownerRing.translatesAutoresizingMaskIntoConstraints = false

    avatar.contentMode = .scaleAspectFill
    avatar.clipsToBounds = true
    avatar.layer.cornerRadius = 27
    avatar.layer.cornerCurve = .continuous
    avatar.backgroundColor = NativeTheme.tertiary.withAlphaComponent(0.2)
    ImageLoader.shared.load(item.ownerFace, into: avatar, placeholder: nil)
    author.addSubview(avatar)
    avatar.translatesAutoresizingMaskIntoConstraints = false

    ownerName.text = item.owner
    ownerName.font = UIFont.systemFont(ofSize: 18, weight: .bold)
    ownerName.textColor = NativeTheme.foreground
    ownerName.numberOfLines = 1
    ownerName.lineBreakMode = .byTruncatingTail

    ownerMeta.font = UIFont.monospacedDigitSystemFont(ofSize: 9.5, weight: .regular)
    ownerMeta.textColor = NativeTheme.secondary
    ownerMeta.numberOfLines = 1
    ownerMeta.lineBreakMode = .byTruncatingTail
    ownerMeta.text = item.mid > 0 ? "UID \(item.mid)" : ""

    let ownerInfo = UIStackView(arrangedSubviews: [ownerName, ownerMeta])
    ownerInfo.axis = .vertical
    ownerInfo.alignment = .leading
    ownerInfo.spacing = 2
    author.addSubview(ownerInfo)
    ownerInfo.translatesAutoresizingMaskIntoConstraints = false

    followButton.titleLabel?.font = UIFont.systemFont(ofSize: 11.5, weight: .bold)
    followButton.layer.cornerRadius = NativeTheme.cornerRadius
    followButton.layer.cornerCurve = .continuous
    followButton.layer.borderWidth = 0.5
    followButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)
    followButton.addTarget(self, action: #selector(followTapped), for: .touchUpInside)
    author.addSubview(followButton)
    followButton.translatesAutoresizingMaskIntoConstraints = false
    updateFollowButton()

    let tap = UITapGestureRecognizer(target: self, action: #selector(authorTapped))
    tap.delegate = self
    author.addGestureRecognizer(tap)
    authorTap = tap

    NSLayoutConstraint.activate([
      ownerRing.leadingAnchor.constraint(equalTo: author.leadingAnchor, constant: 16),
      ownerRing.centerYAnchor.constraint(equalTo: author.centerYAnchor),
      ownerRing.widthAnchor.constraint(equalToConstant: 60),
      ownerRing.heightAnchor.constraint(equalToConstant: 60),

      avatar.centerXAnchor.constraint(equalTo: ownerRing.centerXAnchor),
      avatar.centerYAnchor.constraint(equalTo: ownerRing.centerYAnchor),
      avatar.widthAnchor.constraint(equalToConstant: 54),
      avatar.heightAnchor.constraint(equalToConstant: 54),

      ownerInfo.leadingAnchor.constraint(equalTo: ownerRing.trailingAnchor, constant: 12),
      ownerInfo.trailingAnchor.constraint(lessThanOrEqualTo: followButton.leadingAnchor,
                                          constant: -10),
      ownerInfo.centerYAnchor.constraint(equalTo: author.centerYAnchor),

      followButton.trailingAnchor.constraint(equalTo: author.trailingAnchor, constant: -16),
      followButton.centerYAnchor.constraint(equalTo: author.centerYAnchor),
      followButton.heightAnchor.constraint(equalToConstant: 34),
    ])

    let actions = UIStackView()
    actions.axis = .horizontal
    actions.distribution = .fillEqually
    actions.alignment = .fill
    actions.backgroundColor = NativeTheme.background
    actions.layer.cornerRadius = detailCardRadius
    actions.layer.cornerCurve = .continuous
    actions.isLayoutMarginsRelativeArrangement = true
    actions.layoutMargins = UIEdgeInsets(top: 7, left: 4, bottom: 7, right: 4)
    stack.addArrangedSubview(actions)
    actions.heightAnchor.constraint(equalToConstant: detailCardHeight).isActive = true

    shareTitle.text = "分享"
    shareTitle.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
    shareTitle.textColor = NativeTheme.secondary
    for value in [likeValue, favoriteValue, coinValue] {
      value.font = UIFont.monospacedDigitSystemFont(ofSize: 10, weight: .semibold)
      value.textColor = NativeTheme.secondary
      value.textAlignment = .center
      value.text = "0"
    }
    actions.addArrangedSubview(makeActionGroup(
      icon: likeIcon, symbol: "hand.thumbsup", title: nil,
      count: likeValue, action: #selector(likeTapped)))
    actions.addArrangedSubview(makeActionGroup(
      icon: coinIcon, symbol: "bitcoinsign.circle", title: nil,
      count: coinValue, action: #selector(coinTapped)))
    actions.addArrangedSubview(makeActionGroup(
      icon: favoriteIcon, symbol: "star", title: nil,
      count: favoriteValue, action: #selector(favoriteTapped)))
    actions.addArrangedSubview(makeActionGroup(
      icon: shareIcon, symbol: "square.and.arrow.up", title: shareTitle,
      count: nil, action: #selector(shareTapped)))
    updateActions()

    descCard.backgroundColor = NativeTheme.background
    descCard.layer.cornerRadius = detailCardRadius
    descCard.layer.cornerCurve = .continuous
    descCard.clipsToBounds = true
    stack.addArrangedSubview(descCard)

    descLabel.numberOfLines = 0
    descCard.addSubview(descLabel)
    descLabel.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      descLabel.leadingAnchor.constraint(equalTo: descCard.leadingAnchor, constant: 14),
      descLabel.trailingAnchor.constraint(equalTo: descCard.trailingAnchor, constant: -14),
      descLabel.topAnchor.constraint(equalTo: descCard.topAnchor, constant: 14),
      descLabel.bottomAnchor.constraint(equalTo: descCard.bottomAnchor, constant: -14),
    ])
    setDescription(item.desc)

    let latest = makeMiniSection(title: "最近发布")
    latestSection = latest.container
    latestStack = latest.stack
    latestScroll = latest.scroll
    latest.container.isHidden = true
    stack.addArrangedSubview(latest.container)

    let popular = makeMiniSection(title: "最多播放")
    popularSection = popular.container
    popularStack = popular.stack
    popularScroll = popular.scroll
    popular.container.isHidden = true
    stack.addArrangedSubview(popular.container)

    qualityValue = initialQuality
    danmakuOn = initialDanmakuOn
    loopOn = initialLoopOn
    let defaults = UserDefaults.standard
    danmakuOpacity = defaults.object(forKey: "danmaku_opacity") == nil
      ? 88 : defaults.float(forKey: "danmaku_opacity")
    danmakuSize = defaults.object(forKey: "danmaku_size") == nil
      ? 100 : defaults.float(forKey: "danmaku_size")
    danmakuSpeed = defaults.object(forKey: "danmaku_speed") == nil
      ? 100 : defaults.float(forKey: "danmaku_speed")
    danmakuAreaPercent = DanmakuSettings.areaPercent(defaults: defaults)
    danmakuDensity = defaults.object(forKey: "danmaku_density") == nil
      ? true : defaults.bool(forKey: "danmaku_density")

    if embedded {
      let swipe = UIPanGestureRecognizer(target: self, action: #selector(handleCloseSwipe(_:)))
      swipe.delegate = self
      scroll.panGestureRecognizer.require(toFail: swipe)
      view.addGestureRecognizer(swipe)
      closeSwipePan = swipe

      let pull = UIPanGestureRecognizer(target: self, action: #selector(handlePullDown(_:)))
      pull.delegate = self
      scroll.panGestureRecognizer.require(toFail: pull)
      view.addGestureRecognizer(pull)
      pullDownPan = pull
    } else {
      let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
      pan.delegate = self
      view.addGestureRecognizer(pan)
      dismissPan = pan
    }

    loadDetail()
    if item.mid > 0 {
      loadOwnerFeed(item.mid)
    }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    if embedded {
      scroll.contentInset.top = 56
      scroll.contentInset.bottom = 96 + view.safeAreaInsets.bottom
      scroll.verticalScrollIndicatorInsets.top = 56
      scroll.verticalScrollIndicatorInsets.bottom = 60
    }
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    guard scrollView === scroll else { return }
    if scrollView.isDragging {
      let position = scrollView.contentOffset.y + scrollView.contentInset.top
      if let last = lastDockScrollPosition {
        let delta = position - last
        if abs(delta) > 2 {
          onScroll?(delta, position)
        }
      }
      lastDockScrollPosition = position
    } else {
      lastDockScrollPosition = nil
    }
  }

  @objc private func handleCloseSwipe(_ gesture: UIPanGestureRecognizer) {
    let width = max(1, view.bounds.width)
    let translation = gesture.translation(in: view).x
    switch gesture.state {
    case .began:
      closeSwipeStarted = false
    case .changed:
      if translation > 4, !closeSwipeStarted {
        closeSwipeStarted = true
        onSwipeRightBegan?()
      }
      if closeSwipeStarted {
        onSwipeRightChanged?(max(0, min(1, translation / width)))
      }
    case .ended, .cancelled:
      let velocity = gesture.velocity(in: view).x
      if closeSwipeStarted {
        onSwipeRightEnded?(translation > width * 0.22 || velocity > 380)
      }
      closeSwipeStarted = false
    default:
      break
    }
  }

  @objc private func handlePullDown(_ gesture: UIPanGestureRecognizer) {
    let reference = view.superview ?? view
    let translation = max(0, gesture.translation(in: reference).y)
    let progress = min(1, translation / 240)
    switch gesture.state {
    case .changed:
      onPullDown?(progress)
    case .ended, .cancelled:
      onPullDownEnded?(progress > 0.35 || gesture.velocity(in: reference).y > 450)
    default:
      break
    }
  }

  private func makeSettingsRow(title: String, value: UILabel, chevron: Bool,
                               action: Selector) -> UIView {
    let row = UIButton(type: .custom)
    row.addTarget(self, action: action, for: .touchUpInside)
    row.heightAnchor.constraint(equalToConstant: 52).isActive = true

    let label = UILabel()
    label.text = title
    label.font = UIFont.systemFont(ofSize: 13.5, weight: .semibold)
    label.textColor = NativeTheme.foreground
    label.isUserInteractionEnabled = false
    row.addSubview(label)
    row.addSubview(value)
    label.translatesAutoresizingMaskIntoConstraints = false
    value.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      label.leadingAnchor.constraint(equalTo: row.leadingAnchor),
      label.centerYAnchor.constraint(equalTo: row.centerYAnchor),
      value.trailingAnchor.constraint(equalTo: row.trailingAnchor,
                                      constant: chevron ? -22 : 0),
      value.centerYAnchor.constraint(equalTo: row.centerYAnchor),
      value.leadingAnchor.constraint(greaterThanOrEqualTo: label.trailingAnchor, constant: 8),
    ])
    if chevron {
      let arrow = UILabel()
      arrow.text = "›"
      arrow.font = NativeTheme.bodyFont(18)
      arrow.textColor = NativeTheme.tertiary
      arrow.isUserInteractionEnabled = false
      row.addSubview(arrow)
      arrow.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        arrow.trailingAnchor.constraint(equalTo: row.trailingAnchor),
        arrow.centerYAnchor.constraint(equalTo: row.centerYAnchor),
      ])
    }
    return row
  }

  private func settingsSeparator() -> UIView {
    let line = UIView()
    line.backgroundColor = NativeTheme.hairline
    line.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
    return line
  }

  private func makeDanmakuPanel() -> UIView {
    danmakuPanel.axis = .vertical
    danmakuPanel.alignment = .fill
    danmakuPanel.spacing = 0
    danmakuPanel.isHidden = true
    danmakuPanel.addArrangedSubview(settingsSeparator())
    danmakuPanel.addArrangedSubview(makeDanmakuSwitchRow("弹幕显示", isOn: danmakuOn, tag: 0))
    danmakuPanel.addArrangedSubview(settingsSeparator())
    danmakuPanel.addArrangedSubview(makeDanmakuSliderRow(
      "不透明度", min: 0, max: 100, value: danmakuOpacity, tag: 0))
    danmakuPanel.addArrangedSubview(settingsSeparator())
    danmakuPanel.addArrangedSubview(makeDanmakuSliderRow(
      "字号", min: 50, max: 150, value: danmakuSize, tag: 1))
    danmakuPanel.addArrangedSubview(settingsSeparator())
    danmakuPanel.addArrangedSubview(makeDanmakuSliderRow(
      "速度", min: 50, max: 200, value: danmakuSpeed, tag: 2))
    danmakuPanel.addArrangedSubview(settingsSeparator())
    danmakuPanel.addArrangedSubview(makeDanmakuAreaRow())
    danmakuPanel.addArrangedSubview(settingsSeparator())
    danmakuPanel.addArrangedSubview(makeDanmakuSwitchRow("分布密度", isOn: danmakuDensity, tag: 1))
    let bottom = UIView()
    bottom.heightAnchor.constraint(equalToConstant: 6).isActive = true
    danmakuPanel.addArrangedSubview(bottom)
    return danmakuPanel
  }

  private func makeDanmakuSwitchRow(_ title: String, isOn: Bool, tag: Int) -> UIView {
    let row = UIView()
    row.heightAnchor.constraint(equalToConstant: 48).isActive = true
    let label = UILabel()
    label.text = title
    label.font = UIFont.systemFont(ofSize: 12.5, weight: .medium)
    label.textColor = NativeTheme.foreground
    row.addSubview(label)
    label.translatesAutoresizingMaskIntoConstraints = false
    let toggle = UISwitch()
    toggle.isOn = isOn
    toggle.onTintColor = NativeTheme.navBlue
    toggle.tag = tag
    toggle.addTarget(self, action: #selector(danmakuSwitchChanged(_:)), for: .valueChanged)
    row.addSubview(toggle)
    toggle.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      label.leadingAnchor.constraint(equalTo: row.leadingAnchor),
      label.centerYAnchor.constraint(equalTo: row.centerYAnchor),
      toggle.trailingAnchor.constraint(equalTo: row.trailingAnchor),
      toggle.centerYAnchor.constraint(equalTo: row.centerYAnchor),
    ])
    return row
  }

  private func makeDanmakuSliderRow(_ title: String, min: Float, max: Float,
                                     value: Float, tag: Int) -> UIView {
    let row = UIView()
    row.heightAnchor.constraint(equalToConstant: 64).isActive = true
    let label = UILabel()
    label.text = title
    label.font = UIFont.systemFont(ofSize: 12.5, weight: .medium)
    label.textColor = NativeTheme.foreground
    row.addSubview(label)
    label.translatesAutoresizingMaskIntoConstraints = false
    let valueLabel = UILabel()
    valueLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 10.5, weight: .medium)
    valueLabel.textColor = NativeTheme.secondary
    valueLabel.textAlignment = .right
    row.addSubview(valueLabel)
    valueLabel.translatesAutoresizingMaskIntoConstraints = false
    let slider = UISlider()
    slider.minimumValue = min
    slider.maximumValue = max
    slider.value = value
    slider.tag = tag
    slider.minimumTrackTintColor = NativeTheme.navBlue
    slider.maximumTrackTintColor = NativeTheme.hairline
    slider.addTarget(self, action: #selector(danmakuSliderChanged(_:)), for: .valueChanged)
    row.addSubview(slider)
    slider.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      label.leadingAnchor.constraint(equalTo: row.leadingAnchor),
      label.topAnchor.constraint(equalTo: row.topAnchor, constant: 8),
      valueLabel.trailingAnchor.constraint(equalTo: row.trailingAnchor),
      valueLabel.centerYAnchor.constraint(equalTo: label.centerYAnchor),
      slider.leadingAnchor.constraint(equalTo: row.leadingAnchor),
      slider.trailingAnchor.constraint(equalTo: row.trailingAnchor),
      slider.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 2),
      slider.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -4),
    ])
    danmakuValueLabels.append(valueLabel)
    danmakuSliders.append(slider)
    updateDanmakuSliderLabel(tag: tag, value: value)
    return row
  }

  private func makeDanmakuAreaRow() -> UIView {
    let row = UIView()
    row.heightAnchor.constraint(equalToConstant: 64).isActive = true
    let label = UILabel()
    label.text = "显示区域"
    label.font = UIFont.systemFont(ofSize: 12.5, weight: .medium)
    label.textColor = NativeTheme.foreground
    row.addSubview(label)
    label.translatesAutoresizingMaskIntoConstraints = false
    let valueLabel = UILabel()
    valueLabel.text = "\(Int(danmakuAreaPercent))%"
    valueLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 10.5, weight: .medium)
    valueLabel.textColor = NativeTheme.secondary
    valueLabel.textAlignment = .right
    row.addSubview(valueLabel)
    valueLabel.translatesAutoresizingMaskIntoConstraints = false
    let slider = UISlider()
    slider.minimumValue = DanmakuSettings.areaMinimum
    slider.maximumValue = DanmakuSettings.areaMaximum
    slider.value = danmakuAreaPercent
    slider.minimumTrackTintColor = NativeTheme.navBlue
    slider.maximumTrackTintColor = NativeTheme.hairline
    slider.addTarget(self, action: #selector(danmakuAreaSliderChanged(_:)),
                     for: .valueChanged)
    row.addSubview(slider)
    slider.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      label.leadingAnchor.constraint(equalTo: row.leadingAnchor),
      label.topAnchor.constraint(equalTo: row.topAnchor, constant: 8),
      valueLabel.trailingAnchor.constraint(equalTo: row.trailingAnchor),
      valueLabel.centerYAnchor.constraint(equalTo: label.centerYAnchor),
      slider.leadingAnchor.constraint(equalTo: row.leadingAnchor),
      slider.trailingAnchor.constraint(equalTo: row.trailingAnchor),
      slider.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 2),
      slider.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -4),
    ])
    danmakuAreaSlider = slider
    danmakuAreaValueLabel = valueLabel
    return row
  }

  private func updateDanmakuSliderLabel(tag: Int, value: Float) {
    guard tag < danmakuValueLabels.count else { return }
    switch tag {
    case 0, 1:
      danmakuValueLabels[tag].text = "\(Int(value))%"
    default:
      danmakuValueLabels[tag].text = String(format: "%.1f×", Double(value) / 100.0)
    }
  }

  @objc private func danmakuSwitchChanged(_ sender: UISwitch) {
    if sender.tag == 0 {
      danmakuOn = sender.isOn
      UserDefaults.standard.set(danmakuOn, forKey: "danmaku_enabled")
      updateSettingsLabels()
      onDanmaku?(danmakuOn)
    } else {
      danmakuDensity = sender.isOn
      UserDefaults.standard.set(danmakuDensity, forKey: "danmaku_density")
    }
    onDanmakuSettingsChanged?()
  }

  @objc private func danmakuSliderChanged(_ sender: UISlider) {
    if sender.tag == 2 {
      sender.value = (sender.value / 10).rounded() * 10
    }
    let value = sender.value
    let defaults = UserDefaults.standard
    switch sender.tag {
    case 0:
      danmakuOpacity = value
      defaults.set(value, forKey: "danmaku_opacity")
    case 1:
      danmakuSize = value
      defaults.set(value, forKey: "danmaku_size")
    default:
      danmakuSpeed = value
      defaults.set(value, forKey: "danmaku_speed")
    }
    updateDanmakuSliderLabel(tag: sender.tag, value: value)
    onDanmakuSettingsChanged?()
  }

  @objc private func danmakuAreaSliderChanged(_ sender: UISlider) {
    let snapped = DanmakuSettings.snapArea(sender.value)
    if abs(snapped - sender.value) > 0.01 {
      sender.value = snapped
      UISelectionFeedbackGenerator().selectionChanged()
    }
    guard abs(snapped - danmakuAreaPercent) > 0.01 else { return }
    danmakuAreaPercent = snapped
    DanmakuSettings.setAreaPercent(snapped)
    danmakuAreaValueLabel?.text = "\(Int(snapped))%"
    onDanmakuSettingsChanged?()
  }

  private func makeQualityChips() -> UIView {
    qualityChips.axis = .horizontal
    qualityChips.spacing = 6
    qualityChips.alignment = .center
    qualityChips.isLayoutMarginsRelativeArrangement = true
    qualityChips.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
    qualityChips.isHidden = true
    let options: [(String, Int)] = [("4K", 120), ("1080P", 80), ("720P", 64), ("480P", 32)]
    for entry in options {
      let button = UIButton(type: .custom)
      button.setTitle(entry.0, for: .normal)
      button.titleLabel?.font = UIFont.systemFont(ofSize: 10, weight: .bold)
      button.layer.cornerRadius = NativeTheme.cornerRadius
      button.layer.cornerCurve = .continuous
      button.layer.borderWidth = 1
      button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 9, bottom: 5, right: 9)
      button.heightAnchor.constraint(equalToConstant: 26).isActive = true
      button.tag = entry.1
      button.addTarget(self, action: #selector(qualityChipTapped(_:)), for: .touchUpInside)
      qualityButtons.append(button)
      qualityChips.addArrangedSubview(button)
    }
    let spacer = UIView()
    spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
    qualityChips.addArrangedSubview(spacer)
    updateQualityChips()
    return qualityChips
  }

  @objc private func toggleQualityChips() {
    qualityChips.isHidden.toggle()
    UIView.animate(withDuration: 0.22) {
      self.view.layoutIfNeeded()
    }
  }

  @objc private func qualityChipTapped(_ sender: UIButton) {
    qualityValue = sender.tag
    updateQualityChips()
    updateSettingsLabels()
    onQuality?(sender.tag)
  }

  private func updateQualityChips() {
    for button in qualityButtons {
      let active = button.tag == qualityValue
      button.backgroundColor = active ? NativeTheme.navSoft : .clear
      button.setTitleColor(active ? NativeTheme.navBlue : NativeTheme.secondary,
                           for: .normal)
      button.layer.borderColor = active
        ? NativeTheme.navBlue.withAlphaComponent(0.4).cgColor
        : NativeTheme.hairline.cgColor
    }
  }

  @objc private func toggleDanmakuSetting() {
    danmakuPanel.isHidden.toggle()
    UIView.animate(withDuration: 0.22, animations: {
      self.view.layoutIfNeeded()
    }) { _ in
      guard !self.danmakuPanel.isHidden else { return }
      let rect = self.danmakuPanel.convert(self.danmakuPanel.bounds, to: self.scroll)
      self.scroll.scrollRectToVisible(rect.insetBy(dx: 0, dy: -16), animated: true)
    }
  }

  func testExpandDanmaku() {
    if danmakuPanel.isHidden { toggleDanmakuSetting() }
  }

  @objc private func toggleLoopSetting() {
    loopOn.toggle()
    updateSettingsLabels()
    onLoop?(loopOn)
  }

  private func updateSettingsLabels() {
    let name: String
    switch qualityValue {
    case 120: name = "4K"
    case 116: name = "1080P60"
    case 112: name = "1080P+"
    case 80: name = "1080P"
    case 74: name = "720P60"
    case 64: name = "720P"
    case 32: name = "480P"
    case 16: name = "360P"
    default: name = "1080P"
    }
    qualitySetting.text = name
    danmakuSetting.text = danmakuOn ? "开" : "关"
    loopSetting.text = loopOn ? "循环" : "单个"
  }

  private func makeActionGroup(icon: UIImageView, symbol: String, title: UILabel?,
                               count: UILabel?, action: Selector) -> UIView {
    let container = UIView()
    icon.image = UIImage(systemName: symbol, withConfiguration:
      UIImage.SymbolConfiguration(pointSize: 21, weight: .semibold))
    icon.tintColor = NativeTheme.foreground
    icon.contentMode = .scaleAspectFit
    icon.translatesAutoresizingMaskIntoConstraints = false
    icon.widthAnchor.constraint(equalToConstant: 24).isActive = true
    icon.heightAnchor.constraint(equalToConstant: 24).isActive = true

    let column = UIStackView()
    column.axis = .vertical
    column.alignment = .center
    column.spacing = 5
    column.addArrangedSubview(icon)
    if let title = title {
      column.addArrangedSubview(title)
    }
    if let count = count {
      column.addArrangedSubview(count)
    }
    container.addSubview(column)
    column.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      column.centerXAnchor.constraint(equalTo: container.centerXAnchor),
      column.centerYAnchor.constraint(equalTo: container.centerYAnchor),
      column.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor, constant: 2),
      column.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -2),
    ])
    let button = UIButton(type: .custom)
    button.addTarget(self, action: action, for: .touchUpInside)
    container.addSubview(button)
    button.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      button.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      button.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      button.topAnchor.constraint(equalTo: container.topAnchor),
      button.bottomAnchor.constraint(equalTo: container.bottomAnchor),
    ])
    return container
  }

  private var actionAid: Int64 {
    return detailAid > 0 ? detailAid : item.aid
  }

  private func updateActions() {
    let config = UIImage.SymbolConfiguration(pointSize: 21, weight: .semibold)
    likeIcon.image = UIImage(systemName: liked ? "hand.thumbsup.fill" : "hand.thumbsup",
                             withConfiguration: config)
    likeIcon.tintColor = liked ? NativeTheme.warmOrange : NativeTheme.foreground
    coinIcon.image = UIImage(systemName: coined ? "bitcoinsign.circle.fill" : "bitcoinsign.circle",
                             withConfiguration: config)
    coinIcon.tintColor = coined ? NativeTheme.warmOrange : NativeTheme.foreground
    favoriteIcon.image = UIImage(systemName: faved ? "star.fill" : "star",
                                 withConfiguration: config)
    favoriteIcon.tintColor = faved ? NativeTheme.warmOrange : NativeTheme.foreground
    shareIcon.image = UIImage(systemName: "square.and.arrow.up", withConfiguration: config)
    shareIcon.tintColor = NativeTheme.foreground
    likeValue.text = o11a1Count(likeCount)
    favoriteValue.text = o11a1Count(favoriteCount)
    coinValue.text = o11a1Count(coinCount)
  }

  @objc private func likeTapped() {
    let aid = actionAid
    guard aid > 0 else { return }
    let next = !liked
    BiliAPI.shared.like(aid: aid, on: next) { [weak self] ok in
      guard ok, let self = self else { return }
      self.liked = next
      self.likeCount = max(0, self.likeCount + (next ? 1 : -1))
      self.updateActions()
      UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
  }

  @objc private func coinTapped() {
    let aid = actionAid
    guard aid > 0 else { return }
    BiliAPI.shared.coin(aid: aid) { [weak self] ok in
      guard ok, let self = self else { return }
      if !self.coined {
        self.coinCount += 1
      }
      self.coined = true
      self.updateActions()
      UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
  }

  @objc private func favoriteTapped() {
    let aid = actionAid
    guard aid > 0 else { return }
    if faved {
      BiliAPI.shared.favorite(aid: aid, folderId: favoriteFolderId, on: false) {
        [weak self] ok in
        guard ok, let self = self else { return }
        self.faved = false
        self.favoriteCount = max(0, self.favoriteCount - 1)
        self.updateActions()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
      }
      return
    }
    let sheet = FavoriteFolderSheetViewController()
    sheet.modalPresentationStyle = .overFullScreen
    sheet.onSelect = { [weak self] folder in
      guard let self = self else { return }
      self.favoriteFolderId = folder.id
      UserDefaults.standard.set(folder.id, forKey: "o11a1.favoriteFolderId")
      BiliAPI.shared.favorite(aid: aid, folderId: folder.id, on: true) {
        [weak self] ok in
        guard ok, let self = self else { return }
        self.faved = true
        self.favoriteCount += 1
        self.updateActions()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
      }
    }
    present(sheet, animated: false)
  }

  @objc private func shareTapped() {
    let bvid = detailBvid.isEmpty ? item.bvid : detailBvid
    let link = bvid.isEmpty
      ? "https://www.bilibili.com/video/av\(actionAid)"
      : "https://www.bilibili.com/video/\(bvid)"
    ClipboardShareWatcher.shared.ignore(link)
    UIPasteboard.general.string = link
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    shareTitle.text = "已复制"
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
      self?.shareTitle.text = "分享"
    }
  }

  private func loadDetail() {
    BiliAPI.shared.videoInfo(item.bvid) { [weak self] result in
      guard let self = self, case .success(let json) = result else { return }
      let title = o11a1String(json["title"])
      if !title.isEmpty { self.titleLabel.text = title }
      let desc = o11a1String(json["desc"])
      if !desc.isEmpty {
        self.setDescription(desc)
      }
      let pic = o11a1HTTPS(o11a1String(json["pic"]))
      if !pic.isEmpty { ImageLoader.shared.load(pic, into: self.cover) }
      let owner = o11a1String(json["owner"])
      if !owner.isEmpty { self.ownerName.text = owner }
      let face = o11a1HTTPS(o11a1String(json["ownerFace"]))
      if !face.isEmpty { ImageLoader.shared.load(face, into: self.avatar, placeholder: nil) }
      self.detailMid = o11a1Int64(json["mid"])
      if self.detailMid > 0 {
        self.loadOwnerFeed(self.detailMid)
      }
      self.detailAid = o11a1Int64(json["aid"])
      self.detailBvid = o11a1String(json["bvid"])
      if !self.detailBvid.isEmpty {
        self.bvidLabel.text = self.detailBvid
      }
      let duration = o11a1String(json["duration"])
      if !duration.isEmpty {
        self.timeLabel.text = duration
        self.durationChip.text = duration
      }
      let pubdate = o11a1Int64(json["pubdate"])
      let date = Self.dateText(pubdate)
      if !date.isEmpty {
        self.dateLabel.text = date
        self.dateLabel.textColor = NativeTheme.freshnessColor(pubdate)
      }
      if let stat = json["stat"] as? [String: Any] {
        let views = o11a1Int64(stat["view"])
        if views > 0 {
          self.playLabel.text = o11a1Count(views) + "播放"
          self.playLabel.textColor = NativeTheme.playCountColor(views)
        }
        self.likeCount = o11a1Int64(stat["like"])
        self.favoriteCount = o11a1Int64(stat["favorite"])
        self.coinCount = o11a1Int64(stat["coin"])
        self.liked = o11a1Bool(json["liked"])
        self.faved = o11a1Bool(json["faved"])
        self.coined = o11a1Int(json["coined"]) > 0
        self.updateActions()
      }
    }
  }

  private static func dateText(_ raw: Int64) -> String {
    guard raw > 0 else { return "" }
    let seconds = raw > 100_000_000_000 ? raw / 1000 : raw
    let date = Date(timeIntervalSince1970: TimeInterval(seconds))
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy年M月d日"
    return formatter.string(from: date)
  }

  @objc private func authorTapped() {
    let mid = detailMid > 0 ? detailMid : item.mid
    guard mid > 0 else { return }
    onProfile?(mid)
  }

  @objc private func copyBvid() {
    let bvid = detailBvid.isEmpty ? item.bvid : detailBvid
    guard !bvid.isEmpty else { return }
    UIPasteboard.general.string = bvid
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    let config = UIImage.SymbolConfiguration(pointSize: 8, weight: .semibold)
    copyButton.setImage(UIImage(systemName: "checkmark", withConfiguration: config),
                        for: .normal)
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
      self?.copyButton.setImage(
        UIImage(systemName: "doc.on.doc", withConfiguration: config), for: .normal)
    }
  }

  private func setDescription(_ text: String) {
    let style = NSMutableParagraphStyle()
    style.lineSpacing = 5
    style.lineBreakMode = .byWordWrapping
    descLabel.attributedText = NSAttributedString(
      string: text.isEmpty ? "暂无简介" : text,
      attributes: [
        .font: NativeTheme.bodyFont(13),
        .foregroundColor: NativeTheme.secondary,
        .paragraphStyle: style,
      ])
  }

  private func makeMiniSection(
    title: String
  ) -> (container: UIView, scroll: UIScrollView, stack: UIStackView) {
    let container = UIStackView()
    container.axis = .vertical
    container.alignment = .fill
    container.spacing = 8

    let header = UILabel()
    header.text = title
    header.font = UIFont.systemFont(ofSize: 13, weight: .bold)
    header.textColor = NativeTheme.foreground
    container.addArrangedSubview(header)

    let scroll = UIScrollView()
    scroll.showsHorizontalScrollIndicator = false
    scroll.showsVerticalScrollIndicator = false
    scroll.alwaysBounceHorizontal = true
    scroll.clipsToBounds = true

    let row = UIStackView()
    row.axis = .horizontal
    row.alignment = .top
    row.spacing = 10
    scroll.addSubview(row)
    row.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      row.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
      row.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
      row.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
      row.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
      row.heightAnchor.constraint(equalTo: scroll.frameLayoutGuide.heightAnchor),
      scroll.heightAnchor.constraint(equalToConstant: 146),
    ])
    container.addArrangedSubview(scroll)
    return (container, scroll, row)
  }

  private func loadOwnerFeed(_ mid: Int64) {
    guard mid > 0, feedMid == 0 else { return }
    feedMid = mid
    BiliAPI.shared.upPage(mid: mid, page: 1, order: "pubdate") { [weak self] result in
      guard let self = self, case .success(let up) = result else { return }
      self.applyOwner(up)
      self.latestVideos = Array(up.items.prefix(5))
      self.renderFeed()
    }
    BiliAPI.shared.spaceVideos(mid: mid, page: 1, order: "click") {
      [weak self] result in
      guard let self = self, case .success(let items) = result else { return }
      self.popularRaw = items
      self.renderFeed()
    }
  }

  private func applyOwner(_ up: BiliAPI.UpProfilePage) {
    if !up.name.isEmpty { ownerName.text = up.name }
    if !up.face.isEmpty {
      ImageLoader.shared.load(up.face, into: avatar, placeholder: nil)
    }
    let uid = feedMid > 0 ? feedMid : detailMid
    if up.follower > 0, uid > 0 {
      ownerMeta.text = "UID \(uid) · \(o11a1Count(up.follower)) 粉丝"
    } else if uid > 0 {
      ownerMeta.text = "UID \(uid)"
    }
    if !followStateLoaded {
      followStateLoaded = true
      following = up.followed
      updateFollowButton()
    }
  }

  private func renderFeed() {
    let latest = Array(latestVideos.prefix(5))
    let latestKeys = Set(latest.map { $0.bvid })
    let popular = Array(popularRaw.filter {
      !$0.bvid.isEmpty && !latestKeys.contains($0.bvid)
    }.prefix(5))
    populateFeed(section: latestSection, stack: latestStack, items: latest)
    populateFeed(section: popularSection, stack: popularStack, items: popular)
  }

  private func populateFeed(section: UIView?, stack: UIStackView?, items: [VideoItem]) {
    guard let section = section, let stack = stack else { return }
    for view in stack.arrangedSubviews {
      stack.removeArrangedSubview(view)
      view.removeFromSuperview()
    }
    for item in items {
      let card = MiniUpVideoCard(item: item)
      card.onTap = { [weak self] in self?.onOpenVideo?(item) }
      card.translatesAutoresizingMaskIntoConstraints = false
      stack.addArrangedSubview(card)
      NSLayoutConstraint.activate([
        card.widthAnchor.constraint(equalToConstant: 150),
        card.heightAnchor.constraint(equalToConstant: 146),
      ])
    }
    section.isHidden = items.isEmpty
  }

  private func updateFollowButton() {
    if following {
      followButton.setTitle("已关注", for: .normal)
      followButton.setTitleColor(NativeTheme.navBlue, for: .normal)
      followButton.backgroundColor = NativeTheme.navBlue.withAlphaComponent(0.12)
      followButton.layer.borderColor = NativeTheme.navBlue.withAlphaComponent(0.30).cgColor
    } else {
      followButton.setTitle("关注", for: .normal)
      followButton.setTitleColor(NativeTheme.foreground, for: .normal)
      followButton.backgroundColor = NativeTheme.foreground.withAlphaComponent(0.06)
      followButton.layer.borderColor = NativeTheme.hairline.cgColor
    }
  }

  @objc private func followTapped() {
    let mid = feedMid > 0 ? feedMid : detailMid
    guard mid > 0, followButton.isEnabled else { return }
    followStateLoaded = true
    let next = !following
    followButton.isEnabled = false
    BiliAPI.shared.follow(mid: mid, on: next) { [weak self] ok in
      guard let self = self else { return }
      self.followButton.isEnabled = true
      guard ok else { return }
      self.following = next
      self.updateFollowButton()
      UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
  }

  func containsHorizontalVideoFeed(_ touched: UIView?) -> Bool {
    guard let touched = touched else { return false }
    for scroll in [latestScroll, popularScroll].compactMap({ $0 }) {
      if touched === scroll || touched.isDescendant(of: scroll) { return true }
    }
    return false
  }

  @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
    let width = max(1, view.bounds.width)
    let reference = view.superview ?? view
    let translation = gesture.translation(in: reference).x
    switch gesture.state {
    case .changed:
      view.transform = CGAffineTransform(translationX: min(0, translation), y: 0)
    case .ended, .cancelled:
      let velocity = gesture.velocity(in: view).x
      if translation < -width * 0.24 || velocity < -350 {
        close()
      } else {
        UIView.animate(withDuration: 0.22) { self.view.transform = .identity }
      }
    default:
      break
    }
  }

  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
    if pan === pullDownPan {
      guard embedded, pullDownArmed else { return false }
      let velocity = pan.velocity(in: view)
      let translation = pan.translation(in: view)
      return (translation.y > 2 && abs(translation.y) > abs(translation.x) * 1.1)
        || (velocity.y > 60 && abs(velocity.y) > abs(velocity.x) * 1.1)
    }
    if pan === closeSwipePan {
      let velocity = pan.velocity(in: view)
      let translation = pan.translation(in: view)
      return abs(translation.x) > abs(translation.y) * 1.2
        || abs(velocity.x) > abs(velocity.y) * 1.2
    }
    guard pan === dismissPan else { return true }
    let velocity = pan.velocity(in: view)
    let translation = pan.translation(in: view)
    return abs(translation.x) > abs(translation.y) * 1.1
      || abs(velocity.x) > abs(velocity.y) * 1.1
  }

  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                         shouldReceive touch: UITouch) -> Bool {
    if gestureRecognizer === authorTap {
      if let touched = touch.view, touched.isDescendant(of: followButton) {
        return false
      }
    }
    if gestureRecognizer === closeSwipePan,
       containsHorizontalVideoFeed(touch.view) {
      return false
    }
    if gestureRecognizer === pullDownPan {
      let x = touch.location(in: view).x
      let width = max(1, view.bounds.width)
      pullDownArmed = x < width / 6.0 || x > width * 5.0 / 6.0
    }
    return true
  }

  private func close() {
    onClose?()
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    card.backgroundColor = NativeTheme.surface
    descLabel.textColor = NativeTheme.secondary
    updateFollowButton()
  }
}

private final class MiniUpVideoCard: UIControl {
  private let cover = UIImageView()
  private let duration = UILabel()
  private let title = UILabel()
  private let meta = UILabel()
  var onTap: (() -> Void)?

  init(item: VideoItem) {
    super.init(frame: .zero)
    backgroundColor = NativeTheme.background
    layer.cornerRadius = NativeTheme.cornerRadius
    layer.cornerCurve = .continuous
    clipsToBounds = true

    cover.contentMode = .scaleAspectFill
    cover.clipsToBounds = true
    cover.layer.cornerRadius = 10
    cover.layer.cornerCurve = .continuous
    cover.backgroundColor = NativeTheme.tertiary.withAlphaComponent(0.15)
    ImageLoader.shared.load(item.pic, into: cover)
    addSubview(cover)

    duration.text = item.duration
    duration.font = NativeTheme.numberFont(9)
    duration.textColor = .white
    duration.textAlignment = .center
    duration.backgroundColor = UIColor.black.withAlphaComponent(0.72)
    duration.layer.cornerRadius = 4
    duration.clipsToBounds = true
    addSubview(duration)

    title.text = item.title
    title.font = UIFont.systemFont(ofSize: 12.5, weight: .semibold)
    title.textColor = NativeTheme.foreground
    title.numberOfLines = 2
    title.lineBreakMode = .byTruncatingTail
    addSubview(title)

    meta.text = (item.playText.isEmpty ? o11a1Count(item.play) : item.playText) + " 播放"
    meta.font = NativeTheme.numberFont(9.5)
    meta.textColor = NativeTheme.secondary
    meta.numberOfLines = 1
    addSubview(meta)

    [cover, duration, title, meta].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
    }
    NSLayoutConstraint.activate([
      cover.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
      cover.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
      cover.topAnchor.constraint(equalTo: topAnchor, constant: 6),
      cover.heightAnchor.constraint(equalToConstant: 78),

      duration.trailingAnchor.constraint(equalTo: cover.trailingAnchor, constant: -4),
      duration.bottomAnchor.constraint(equalTo: cover.bottomAnchor, constant: -4),
      duration.heightAnchor.constraint(equalToConstant: 15),
      duration.widthAnchor.constraint(greaterThanOrEqualToConstant: 32),

      title.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 9),
      title.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -9),
      title.topAnchor.constraint(equalTo: cover.bottomAnchor, constant: 7),

      meta.leadingAnchor.constraint(equalTo: title.leadingAnchor),
      meta.trailingAnchor.constraint(equalTo: title.trailingAnchor),
      meta.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 3),
    ])
    title.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
    addTarget(self, action: #selector(tapped), for: .touchUpInside)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @objc private func tapped() {
    onTap?()
  }
}
