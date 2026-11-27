import UIKit

/// The page under the player: detail, comments and recommendations share one
/// scrolling area, switched by the floating three-item dock at the bottom.
final class PlayerContentViewController: UIViewController, UIGestureRecognizerDelegate {
  enum Tab: Int {
    case detail
    case comments
    case related
  }

  private(set) var item: VideoItem
  private(set) var selected: Tab = .comments

  var initialQuality = 80
  var initialDanmakuOn = true
  var initialLoopOn = false

  var onSelectRelated: ((VideoItem) -> Void)?
  var onProfile: ((Int64) -> Void)?
  var onQuality: ((Int) -> Void)?
  var onDanmaku: ((Bool) -> Void)?
  var onDanmakuSettingsChanged: (() -> Void)?
  var onLoop: ((Bool) -> Void)?
  var onPullDown: ((CGFloat) -> Void)?
  var onPullDownEnded: ((Bool) -> Void)?
  var onSwipeRightToClose: (() -> Void)?
  var onSwipeRightBegan: (() -> Void)?
  var onSwipeRightChanged: ((CGFloat) -> Void)?
  var onSwipeRightEnded: ((Bool) -> Void)?

  private let host = UIView()
  private let tabDock = UIView()
  private let tabBlur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
  private var tabButtons: [UIButton] = []
  private var detail: VideoDetailViewController?
  private var comments: CommentsPanelViewController?
  private var related: RelatedViewController?
  private var tabSwipePan: UIPanGestureRecognizer?
  private var tabSwipeStartX: CGFloat = 0

  private let tabs: [(title: String, tab: Tab)] = [
    ("详情", .detail),
    ("评论", .comments),
    ("推荐", .related),
  ]

  init(item: VideoItem) {
    self.item = item
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = NativeTheme.surface
    view.clipsToBounds = true

    host.backgroundColor = .clear
    view.addSubview(host)

    tabDock.backgroundColor = .clear
    tabDock.layer.cornerRadius = NativeTheme.cornerRadius
    tabDock.layer.cornerCurve = .continuous
    tabDock.layer.borderWidth = 1
    tabDock.layer.borderColor = NativeTheme.hairline.cgColor
    tabDock.layer.shadowColor = UIColor.black.cgColor
    tabDock.layer.shadowOpacity = 0.18
    tabDock.layer.shadowRadius = 17
    tabDock.layer.shadowOffset = CGSize(width: 0, height: 7)
    tabDock.clipsToBounds = false
    view.addSubview(tabDock)

    tabBlur.isUserInteractionEnabled = false
    tabBlur.layer.cornerRadius = NativeTheme.cornerRadius
    tabBlur.layer.cornerCurve = .continuous
    tabBlur.clipsToBounds = true
    tabDock.addSubview(tabBlur)
    tabBlur.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      tabBlur.leadingAnchor.constraint(equalTo: tabDock.leadingAnchor),
      tabBlur.trailingAnchor.constraint(equalTo: tabDock.trailingAnchor),
      tabBlur.topAnchor.constraint(equalTo: tabDock.topAnchor),
      tabBlur.bottomAnchor.constraint(equalTo: tabDock.bottomAnchor),
    ])

    for entry in tabs {
      let button = UIButton(type: .custom)
      button.tag = entry.tab.rawValue
      button.setTitle(entry.title, for: .normal)
      button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
      button.layer.cornerRadius = NativeTheme.cornerRadius
      button.layer.cornerCurve = .continuous
      button.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)
      tabDock.addSubview(button)
      tabButtons.append(button)
    }
    updateTabs()
    show(selected)

    let swipe = UIPanGestureRecognizer(
      target: self, action: #selector(handleTabSwipe(_:)))
    swipe.delegate = self
    swipe.cancelsTouchesInView = false
    view.addGestureRecognizer(swipe)
    tabSwipePan = swipe
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    host.frame = view.bounds
    let safeBottom = view.safeAreaInsets.bottom
    let dockWidth: CGFloat = 304
    tabDock.frame = CGRect(
      x: (view.bounds.width - dockWidth) / 2,
      y: view.bounds.height - safeBottom - 16 - 66,
      width: dockWidth,
      height: 66
    )
    tabDock.layer.shadowPath = UIBezierPath(
      roundedRect: tabDock.bounds,
      cornerRadius: NativeTheme.cornerRadius).cgPath
    let buttonWidth: CGFloat = 96
    let buttonHeight: CGFloat = 52
    for (index, button) in tabButtons.enumerated() {
      button.frame = CGRect(
        x: 5 + CGFloat(index) * (buttonWidth + 3),
        y: (66 - buttonHeight) / 2,
        width: buttonWidth,
        height: buttonHeight
      )
    }
    tabDock.setNeedsLayout()
    tabDock.layoutIfNeeded()
    for child in [detail?.view, comments?.view, related?.view] {
      child?.frame = host.bounds
    }
  }

  override func traitCollectionDidChange(_ previous: UITraitCollection?) {
    super.traitCollectionDidChange(previous)
    tabDock.backgroundColor = .clear
    tabDock.layer.borderColor = NativeTheme.hairline.cgColor
    updateTabs()
  }

  func setReveal(_ value: CGFloat) {
    guard isViewLoaded else { return }
    let reveal = max(0, min(1, value))
    view.alpha = reveal
    view.isHidden = reveal < 0.01
    view.isUserInteractionEnabled = reveal > 0.01
  }

  func update(item: VideoItem, quality: Int, danmaku: Bool, loop: Bool) {
    self.item = item
    initialQuality = quality
    initialDanmakuOn = danmaku
    initialLoopOn = loop
    clearContent()
    show(selected)
  }

  func select(_ tab: Tab) {
    selected = tab
    show(tab)
  }

  func refreshTabColors() {
    updateTabs()
  }

  func testExpandDanmaku() {
    select(.detail)
    detail?.testExpandDanmaku()
  }

  private func show(_ tab: Tab) {
    guard isViewLoaded else {
      selected = tab
      return
    }
    let controller: UIViewController
    switch tab {
    case .detail:
      controller = ensureDetail()
    case .comments:
      controller = ensureComments()
    case .related:
      controller = ensureRelated()
    }
    detail?.view.isHidden = tab != .detail
    comments?.view.isHidden = tab != .comments
    related?.view.isHidden = tab != .related
    controller.view.frame = host.bounds
    host.bringSubviewToFront(controller.view)
    view.bringSubviewToFront(tabDock)
    updateTabs()
  }

  private func ensureDetail() -> VideoDetailViewController {
    if let detail = detail { return detail }
    let controller = VideoDetailViewController(item: item)
    controller.embedded = true
    controller.initialQuality = initialQuality
    controller.initialDanmakuOn = initialDanmakuOn
    controller.initialLoopOn = initialLoopOn
    controller.onProfile = { [weak self] mid in self?.onProfile?(mid) }
    controller.onQuality = { [weak self] qn in self?.onQuality?(qn) }
    controller.onDanmaku = { [weak self] on in self?.onDanmaku?(on) }
    controller.onDanmakuSettingsChanged = { [weak self] in
      self?.onDanmakuSettingsChanged?()
    }
    controller.onLoop = { [weak self] on in self?.onLoop?(on) }
    controller.onSwipeRight = { [weak self] in self?.onSwipeRightToClose?() }
    controller.onSwipeRightBegan = { [weak self] in self?.onSwipeRightBegan?() }
    controller.onSwipeRightChanged = { [weak self] progress in
      self?.onSwipeRightChanged?(progress)
    }
    controller.onSwipeRightEnded = { [weak self] close in
      self?.onSwipeRightEnded?(close)
    }
    addChild(controller)
    controller.view.frame = host.bounds
    controller.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    host.addSubview(controller.view)
    controller.didMove(toParent: self)
    controller.view.isHidden = selected != .detail
    detail = controller
    return controller
  }

  private func ensureComments() -> CommentsPanelViewController {
    if let comments = comments { return comments }
    let controller = CommentsPanelViewController(aid: item.aid)
    controller.embedded = true
    controller.onSwipeRight = { [weak self] in self?.onSwipeRightToClose?() }
    controller.onSwipeRightBegan = { [weak self] in self?.onSwipeRightBegan?() }
    controller.onSwipeRightChanged = { [weak self] progress in
      self?.onSwipeRightChanged?(progress)
    }
    controller.onSwipeRightEnded = { [weak self] close in
      self?.onSwipeRightEnded?(close)
    }
    controller.onPullDown = { [weak self] progress in self?.onPullDown?(progress) }
    controller.onPullDownEnded = { [weak self] complete in
      self?.onPullDownEnded?(complete)
    }
    addChild(controller)
    controller.view.frame = host.bounds
    controller.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    host.addSubview(controller.view)
    controller.didMove(toParent: self)
    controller.view.isHidden = selected != .comments
    comments = controller
    return controller
  }

  private func ensureRelated() -> RelatedViewController {
    if let related = related { return related }
    let controller = RelatedViewController(bvid: item.bvid)
    controller.embedded = true
    controller.onSelect = { [weak self] value in self?.onSelectRelated?(value) }
    controller.onSwipeRight = { [weak self] in self?.onSwipeRightToClose?() }
    controller.onSwipeRightBegan = { [weak self] in self?.onSwipeRightBegan?() }
    controller.onSwipeRightChanged = { [weak self] progress in
      self?.onSwipeRightChanged?(progress)
    }
    controller.onSwipeRightEnded = { [weak self] close in
      self?.onSwipeRightEnded?(close)
    }
    addChild(controller)
    controller.view.frame = host.bounds
    controller.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    host.addSubview(controller.view)
    controller.didMove(toParent: self)
    controller.view.isHidden = selected != .related
    related = controller
    return controller
  }

  private func clearContent() {
    for controller in [detail, comments, related] {
      guard let controller = controller else { continue }
      controller.willMove(toParent: nil)
      controller.view.removeFromSuperview()
      controller.removeFromParent()
    }
    detail = nil
    comments = nil
    related = nil
  }

  private func updateTabs() {
    for (index, button) in tabButtons.enumerated() {
      let on = tabs[index].tab == selected
      button.backgroundColor = on ? NativeTheme.foreground : .clear
      button.setTitleColor(on ? NativeTheme.background : NativeTheme.secondary, for: .normal)
    }
  }

  @objc private func tabTapped(_ sender: UIButton) {
    guard let tab = Tab(rawValue: sender.tag) else { return }
    select(tab)
  }

  @objc private func handleTabSwipe(_ gesture: UIPanGestureRecognizer) {
    guard gesture.state == .ended || gesture.state == .cancelled else { return }
    let translation = gesture.translation(in: view).x
    let velocity = gesture.velocity(in: view).x
    guard abs(translation) > 45 || abs(velocity) > 280 else { return }
    let all: [Tab] = [.detail, .comments, .related]
    guard let index = all.firstIndex(of: selected) else { return }
    let next = translation < 0 ? index + 1 : index - 1
    guard all.indices.contains(next) else { return }
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    select(all[next])
  }

  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                         shouldReceive touch: UITouch) -> Bool {
    if gestureRecognizer === tabSwipePan {
      tabSwipeStartX = touch.location(in: view).x
    }
    return true
  }

  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    guard let pan = gestureRecognizer as? UIPanGestureRecognizer,
          pan === tabSwipePan else { return true }
    guard tabSwipeStartX >= view.bounds.width / 3.0 else { return false }
    let translation = pan.translation(in: view)
    let velocity = pan.velocity(in: view)
    return (abs(translation.x) > 8 && abs(translation.x) > abs(translation.y) * 1.2)
      || (abs(velocity.x) > 90 && abs(velocity.x) > abs(velocity.y) * 1.2)
  }

  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                         shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
    return gestureRecognizer === tabSwipePan || other === tabSwipePan
  }
}
