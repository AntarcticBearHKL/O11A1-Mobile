import UIKit

/// The dedicated UP page from the original design: a right-slide page with the
/// uploader's video list, a floating sort dock and a fixed glass account card.
final class UpProfileViewController: UIViewController, UITableViewDataSource,
  UITableViewDelegate, UIGestureRecognizerDelegate {

  var onClose: (() -> Void)?
  var onOpenVideo: ((VideoItem, UIView?) -> Void)?

  private let mid: Int64
  private let table = UITableView(frame: .zero, style: .plain)
  private let statusLabel = UILabel()
  private let topBlur = TopBlurView()
  private let bottomCard = UIView()
  private let heroBackground = ProfileHeroBackground()
  private let avatarRing = ProfileAvatarRing()
  private let avatar = UIImageView()
  private let nameLabel = UILabel()
  private let signLabel = UILabel()
  private let uidLabel = UILabel()
  private let fansLabel = UILabel()
  private let followButton = UIButton(type: .custom)
  private let sortDock = UIView()
  private let sortBlur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
  private let latestButton = UIButton(type: .custom)
  private let playButton = UIButton(type: .custom)
  private var items: [VideoItem] = []
  private var page = 1
  private var order = "pubdate"
  private var loading = false
  private var hasMore = true
  private var following = false
  private var profile: BiliAPI.UpProfilePage?
  private var cachedProfile: CachedUpProfile?
  private var dismissPan: UIPanGestureRecognizer?
  private var sortPan: UIPanGestureRecognizer?
  private var dismissStartX: CGFloat = 0
  private var sortStartX: CGFloat = 0

  init(mid: Int64) {
    self.mid = mid
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return traitCollection.userInterfaceStyle == .dark ? .lightContent : .darkContent
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = NativeTheme.background
    view.layer.cornerRadius = NativeTheme.cornerRadius
    view.layer.cornerCurve = .continuous
    view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    view.clipsToBounds = true

    table.backgroundColor = .clear
    table.separatorStyle = .none
    table.dataSource = self
    table.delegate = self
    table.register(VideoRowCell.self, forCellReuseIdentifier: VideoRowCell.reuseID)
    table.estimatedRowHeight = 104
    table.rowHeight = UITableView.automaticDimension
    table.contentInsetAdjustmentBehavior = .never
    table.showsVerticalScrollIndicator = false
    view.addSubview(table)
    table.translatesAutoresizingMaskIntoConstraints = false

    topBlur.isUserInteractionEnabled = false
    view.addSubview(topBlur)
    topBlur.translatesAutoresizingMaskIntoConstraints = false

    statusLabel.font = NativeTheme.bodyFont(13)
    statusLabel.textColor = NativeTheme.secondary
    statusLabel.textAlignment = .center
    statusLabel.numberOfLines = 0
    statusLabel.text = "正在加载 UP 主页…"
    view.addSubview(statusLabel)
    statusLabel.translatesAutoresizingMaskIntoConstraints = false

    bottomCard.backgroundColor = .clear
    bottomCard.layer.cornerRadius = NativeTheme.cornerRadius
    bottomCard.layer.cornerCurve = .continuous
    bottomCard.clipsToBounds = false
    bottomCard.layer.shadowColor = UIColor.black.cgColor
    bottomCard.layer.shadowOpacity = 0.12
    bottomCard.layer.shadowRadius = 18
    bottomCard.layer.shadowOffset = CGSize(width: 0, height: 8)
    view.addSubview(bottomCard)
    bottomCard.translatesAutoresizingMaskIntoConstraints = false

    bottomCard.addSubview(heroBackground)
    heroBackground.translatesAutoresizingMaskIntoConstraints = false

    avatarRing.isUserInteractionEnabled = false
    bottomCard.addSubview(avatarRing)
    avatarRing.translatesAutoresizingMaskIntoConstraints = false

    avatar.contentMode = .scaleAspectFill
    avatar.clipsToBounds = true
    avatar.layer.cornerRadius = 27
    avatar.layer.cornerCurve = .continuous
    avatar.backgroundColor = NativeTheme.tertiary.withAlphaComponent(0.16)
    bottomCard.addSubview(avatar)
    avatar.translatesAutoresizingMaskIntoConstraints = false

    nameLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
    nameLabel.textColor = NativeTheme.foreground
    nameLabel.numberOfLines = 1
    nameLabel.lineBreakMode = .byTruncatingTail
    nameLabel.text = "UP 主"
    bottomCard.addSubview(nameLabel)
    nameLabel.translatesAutoresizingMaskIntoConstraints = false

    signLabel.font = NativeTheme.bodyFont(10.5)
    signLabel.textColor = NativeTheme.secondary
    signLabel.numberOfLines = 1
    signLabel.lineBreakMode = .byTruncatingTail
    signLabel.isHidden = true
    bottomCard.addSubview(signLabel)
    signLabel.translatesAutoresizingMaskIntoConstraints = false

    uidLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 9.5, weight: .regular)
    uidLabel.textColor = NativeTheme.secondary
    uidLabel.text = "UID \(mid)"
    bottomCard.addSubview(uidLabel)
    uidLabel.translatesAutoresizingMaskIntoConstraints = false

    fansLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 10, weight: .medium)
    fansLabel.textColor = NativeTheme.secondary
    fansLabel.isHidden = true
    bottomCard.addSubview(fansLabel)
    fansLabel.translatesAutoresizingMaskIntoConstraints = false

    followButton.titleLabel?.font = UIFont.systemFont(ofSize: 11.5, weight: .bold)
    followButton.layer.cornerRadius = NativeTheme.cornerRadius
    followButton.layer.cornerCurve = .continuous
    followButton.layer.borderWidth = 0.5
    followButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
    followButton.addTarget(self, action: #selector(toggleFollow), for: .touchUpInside)
    bottomCard.addSubview(followButton)
    followButton.translatesAutoresizingMaskIntoConstraints = false
    updateFollowButton()

    sortDock.backgroundColor = .clear
    sortDock.layer.cornerRadius = NativeTheme.cornerRadius
    sortDock.layer.cornerCurve = .continuous
    sortDock.layer.borderWidth = 1
    sortDock.layer.borderColor = NativeTheme.hairline.cgColor
    sortDock.layer.shadowColor = UIColor.black.cgColor
    sortDock.layer.shadowOpacity = 0.18
    sortDock.layer.shadowRadius = 17
    sortDock.layer.shadowOffset = CGSize(width: 0, height: 7)
    sortDock.clipsToBounds = false
    view.addSubview(sortDock)
    sortDock.translatesAutoresizingMaskIntoConstraints = false

    sortBlur.isUserInteractionEnabled = false
    sortBlur.layer.cornerRadius = NativeTheme.cornerRadius
    sortBlur.layer.cornerCurve = .continuous
    sortBlur.clipsToBounds = true
    sortBlur.contentView.backgroundColor = UIColor { trait in
      trait.userInterfaceStyle == .dark
        ? UIColor(white: 0, alpha: 0.58)
        : UIColor(white: 1, alpha: 0.88)
    }
    sortDock.addSubview(sortBlur)
    sortBlur.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      sortBlur.leadingAnchor.constraint(equalTo: sortDock.leadingAnchor),
      sortBlur.trailingAnchor.constraint(equalTo: sortDock.trailingAnchor),
      sortBlur.topAnchor.constraint(equalTo: sortDock.topAnchor),
      sortBlur.bottomAnchor.constraint(equalTo: sortDock.bottomAnchor),
    ])

    for (index, button) in [latestButton, playButton].enumerated() {
      button.tag = index
      button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
      button.layer.cornerRadius = NativeTheme.cornerRadius
      button.layer.cornerCurve = .continuous
      button.addTarget(self, action: #selector(sortTapped(_:)), for: .touchUpInside)
      sortDock.addSubview(button)
      button.translatesAutoresizingMaskIntoConstraints = false
      button.centerYAnchor.constraint(equalTo: sortDock.centerYAnchor).isActive = true
      button.widthAnchor.constraint(equalToConstant: 96).isActive = true
      button.heightAnchor.constraint(equalToConstant: 52).isActive = true
      if index == 0 {
        button.leadingAnchor.constraint(equalTo: sortDock.leadingAnchor, constant: 5).isActive = true
      } else {
        button.leadingAnchor.constraint(equalTo: latestButton.trailingAnchor, constant: 3).isActive = true
        button.trailingAnchor.constraint(equalTo: sortDock.trailingAnchor, constant: -5).isActive = true
      }
    }
    latestButton.setTitle("新发布", for: .normal)
    playButton.setTitle("播放量", for: .normal)
    updateSort()

    table.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
    table.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
    table.topAnchor.constraint(equalTo: bottomCard.bottomAnchor, constant: 8).isActive = true
    table.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

    NSLayoutConstraint.activate([
      topBlur.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      topBlur.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      topBlur.topAnchor.constraint(equalTo: view.topAnchor),
    ])

    statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    statusLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32).isActive = true
    statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32).isActive = true

    bottomCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
    bottomCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true
    bottomCard.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                    constant: 8).isActive = true
    bottomCard.heightAnchor.constraint(equalToConstant: 108).isActive = true

    NSLayoutConstraint.activate([
      heroBackground.leadingAnchor.constraint(equalTo: bottomCard.leadingAnchor),
      heroBackground.trailingAnchor.constraint(equalTo: bottomCard.trailingAnchor),
      heroBackground.topAnchor.constraint(equalTo: bottomCard.topAnchor),
      heroBackground.bottomAnchor.constraint(equalTo: bottomCard.bottomAnchor),
    ])

    avatarRing.leadingAnchor.constraint(equalTo: bottomCard.leadingAnchor, constant: 16).isActive = true
    avatarRing.centerYAnchor.constraint(equalTo: bottomCard.centerYAnchor).isActive = true
    avatarRing.widthAnchor.constraint(equalToConstant: 60).isActive = true
    avatarRing.heightAnchor.constraint(equalToConstant: 60).isActive = true

    avatar.centerXAnchor.constraint(equalTo: avatarRing.centerXAnchor).isActive = true
    avatar.centerYAnchor.constraint(equalTo: avatarRing.centerYAnchor).isActive = true
    avatar.widthAnchor.constraint(equalToConstant: 54).isActive = true
    avatar.heightAnchor.constraint(equalToConstant: 54).isActive = true

    nameLabel.leadingAnchor.constraint(equalTo: avatarRing.trailingAnchor, constant: 12).isActive = true
    nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: followButton.leadingAnchor, constant: -10).isActive = true
    nameLabel.topAnchor.constraint(equalTo: bottomCard.topAnchor, constant: 15).isActive = true

    uidLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor).isActive = true
    uidLabel.trailingAnchor.constraint(lessThanOrEqualTo: followButton.leadingAnchor, constant: -10).isActive = true
    uidLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 1).isActive = true

    signLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor).isActive = true
    signLabel.trailingAnchor.constraint(lessThanOrEqualTo: followButton.leadingAnchor, constant: -10).isActive = true
    signLabel.topAnchor.constraint(equalTo: uidLabel.bottomAnchor, constant: 2).isActive = true

    fansLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor).isActive = true
    fansLabel.topAnchor.constraint(equalTo: signLabel.bottomAnchor, constant: 2).isActive = true

    followButton.trailingAnchor.constraint(equalTo: bottomCard.trailingAnchor, constant: -16).isActive = true
    followButton.centerYAnchor.constraint(equalTo: avatarRing.centerYAnchor).isActive = true
    followButton.heightAnchor.constraint(equalToConstant: 34).isActive = true

    sortDock.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    sortDock.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -28).isActive = true
    sortDock.heightAnchor.constraint(equalToConstant: 66).isActive = true

    let closePan = UIPanGestureRecognizer(target: self, action: #selector(handleDismissPan(_:)))
    closePan.delegate = self
    table.panGestureRecognizer.require(toFail: closePan)
    view.addGestureRecognizer(closePan)
    dismissPan = closePan

    let sortPan = UIPanGestureRecognizer(target: self, action: #selector(handleSortSwipe(_:)))
    sortPan.delegate = self
    sortPan.cancelsTouchesInView = true
    table.panGestureRecognizer.require(toFail: sortPan)
    view.addGestureRecognizer(sortPan)
    self.sortPan = sortPan

    applyCachedProfile()
    load(reset: true)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    updateInsets()
  }

  override func viewSafeAreaInsetsDidChange() {
    super.viewSafeAreaInsetsDidChange()
    updateInsets()
  }

  private func updateInsets() {
    table.contentInset = UIEdgeInsets(top: 0, left: 0,
                                      bottom: 112 + view.safeAreaInsets.bottom,
                                      right: 0)
    table.verticalScrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    topBlur.updateHeight(safeAreaTop: view.safeAreaInsets.top)
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    updateFollowButton()
    updateSort()
  }

  private func load(reset: Bool) {
    guard !loading, hasMore || reset else { return }
    loading = true
    if reset {
      page = 1
      items = []
      hasMore = true
      table.reloadData()
      table.setContentOffset(.zero, animated: false)
      statusLabel.text = "正在加载 UP 主页…"
      statusLabel.isHidden = false
    }
    let requestedPage = page
    let requestedOrder = order
    BiliAPI.shared.upPage(mid: mid, page: requestedPage, order: requestedOrder) { [weak self] result in
      guard let self = self else { return }
      self.loading = false
      switch result {
      case .failure(let error):
        if self.items.isEmpty {
          self.statusLabel.text = error.localizedDescription
          self.statusLabel.isHidden = false
        }
      case .success(let up):
        self.profile = up
        self.applyProfile(up)
        if up.items.isEmpty {
          self.hasMore = false
        } else {
          self.items.append(contentsOf: up.items)
          self.page = up.page + 1
          self.hasMore = up.hasMore
        }
        self.statusLabel.text = self.items.isEmpty ? "还没有投稿" : nil
        self.statusLabel.isHidden = !self.items.isEmpty
        self.table.reloadData()
      }
    }
  }

  private func applyCachedProfile() {
    guard let cached = ProfileCache.loadUp(mid: mid) else { return }
    showProfile(cached)
  }

  private func applyProfile(_ up: BiliAPI.UpProfilePage) {
    guard !up.name.isEmpty else { return }
    let cached = CachedUpProfile(
      mid: mid,
      name: up.name,
      face: up.face,
      sign: up.sign,
      follower: up.follower,
      followed: up.followed,
      updatedAt: Date().timeIntervalSince1970
    )
    ProfileCache.saveUp(cached)
    showProfile(cached)
  }

  private func showProfile(_ cached: CachedUpProfile) {
    cachedProfile = cached
    nameLabel.text = cached.name
    if !cached.face.isEmpty {
      ImageLoader.shared.load(cached.face, into: avatar)
    }
    signLabel.text = cached.sign
    signLabel.isHidden = cached.sign.isEmpty
    if cached.follower > 0 {
      fansLabel.text = "\(o11a1Count(cached.follower)) 粉丝"
      fansLabel.isHidden = false
    } else {
      fansLabel.text = nil
      fansLabel.isHidden = true
    }
    following = cached.followed
    updateFollowButton()
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

  private func updateSort() {
    sortDock.layer.borderColor = NativeTheme.hairline.cgColor
    for (index, button) in [latestButton, playButton].enumerated() {
      let on = (index == 0 && order == "pubdate") || (index == 1 && order == "click")
      button.backgroundColor = on ? NativeTheme.foreground : .clear
      button.setTitleColor(on ? NativeTheme.background : NativeTheme.secondary, for: .normal)
      button.layer.borderWidth = 0
    }
  }

  @objc private func sortTapped(_ sender: UIButton) {
    setOrder(sender.tag == 0 ? "pubdate" : "click")
  }

  private func setOrder(_ next: String) {
    guard next != order else { return }
    order = next
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    updateSort()
    load(reset: true)
  }

  @objc private func toggleFollow() {
    let next = !following
    followButton.isEnabled = false
    BiliAPI.shared.follow(mid: mid, on: next) { [weak self] ok in
      guard let self = self else { return }
      self.followButton.isEnabled = true
      if ok {
        self.following = next
        self.updateFollowButton()
        if var cached = self.cachedProfile {
          cached.followed = next
          self.cachedProfile = cached
          ProfileCache.saveUp(cached)
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
      }
    }
  }

  @objc private func handleDismissPan(_ gesture: UIPanGestureRecognizer) {
    let reference = view.superview ?? view
    let width = max(1, view.bounds.width)
    let translation = max(0, gesture.translation(in: reference).x)
    switch gesture.state {
    case .changed:
      view.transform = CGAffineTransform(translationX: translation, y: 0)
    case .ended, .cancelled:
      let velocity = gesture.velocity(in: reference).x
      if translation > width * 0.24 || velocity > 350 {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        onClose?()
      } else {
        UIView.animate(withDuration: 0.24) { self.view.transform = .identity }
      }
    default:
      break
    }
  }

  @objc private func handleSortSwipe(_ gesture: UIPanGestureRecognizer) {
    guard gesture.state == .ended || gesture.state == .cancelled else { return }
    let translation = gesture.translation(in: view).x
    let velocity = gesture.velocity(in: view).x
    let horizontal = abs(translation) > abs(gesture.translation(in: view).y) * 1.4
      || abs(velocity) > abs(gesture.velocity(in: view).y) * 1.5
    guard horizontal,
          abs(translation) > 48 || abs(velocity) > 380 else { return }
    setOrder(translation < 0 ? "click" : "pubdate")
  }

  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                         shouldReceive touch: UITouch) -> Bool {
    if gestureRecognizer === dismissPan {
      dismissStartX = touch.location(in: view).x
    }
    if gestureRecognizer === sortPan {
      sortStartX = touch.location(in: view).x
    }
    return true
  }

  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    guard let pan = gestureRecognizer as? UIPanGestureRecognizer,
          pan === dismissPan || pan === sortPan else {
      return true
    }
    let width = max(1, view.bounds.width)
    let velocity = pan.velocity(in: view)
    let translation = pan.translation(in: view)
    let horizontal = abs(translation.x) > abs(translation.y) * 1.4
      || abs(velocity.x) > abs(velocity.y) * 1.4
    guard horizontal else { return false }
    if pan === dismissPan {
      guard dismissStartX < width / 6.0 else { return false }
      return translation.x > 1 || velocity.x > 1
    }
    guard sortStartX >= width / 6.0 else { return false }
    return abs(translation.x) > 2 || abs(velocity.x) > 80
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return items.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: VideoRowCell.reuseID, for: indexPath) as! VideoRowCell
    cell.configureUp(items[indexPath.row])
    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    guard let cell = tableView.cellForRow(at: indexPath) as? VideoRowCell else { return }
    onOpenVideo?(items[indexPath.row], cell.cover)
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    guard !loading, hasMore, scrollView.contentSize.height > 0 else { return }
    if scrollView.contentOffset.y > scrollView.contentSize.height - scrollView.bounds.height * 2 {
      load(reset: false)
    }
  }
}
