import QuartzCore
import UIKit

/// The page under the player: detail, comments and recommendations share one
/// scrolling area, switched by the floating three-item dock at the bottom.
final class PlayerContentViewController: UIViewController, UIGestureRecognizerDelegate {
  enum Tab: Int {
    case detail
    case comments
    case episodes
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
  var onSelectPage: ((VideoPage) -> Void)?

  private let host = UIView()
  private let tabDock = UIView()
  private let tabBlur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
  private var tabButtons: [UIButton] = []
  private var detail: VideoDetailViewController?
  private var comments: CommentsPanelViewController?
  private var episodes: EpisodesViewController?
  private var related: RelatedViewController?
  private var pages: [VideoPage] = []
  private var currentCid: Int64 = 0
  private var pagesToken = 0
  private var tabSwipePan: UIPanGestureRecognizer?
  private var tabSwipeStartX: CGFloat = 0
  private var tabSwipeSuppressedUntil: CFTimeInterval = 0
  private var transitionToken = 0
  private var dockHidden = false
  private var dockScrollAccumulator: CGFloat = 0
  private var dockLastChange: CFTimeInterval = 0

  private var tabs: [(title: String, tab: Tab)] = [
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
    host.clipsToBounds = true
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
    tabBlur.contentView.backgroundColor = NativeTheme.glassWhite
    tabDock.addSubview(tabBlur)
    tabBlur.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      tabBlur.leadingAnchor.constraint(equalTo: tabDock.leadingAnchor),
      tabBlur.trailingAnchor.constraint(equalTo: tabDock.trailingAnchor),
      tabBlur.topAnchor.constraint(equalTo: tabDock.topAnchor),
      tabBlur.bottomAnchor.constraint(equalTo: tabDock.bottomAnchor),
    ])

    currentCid = item.cid
    configureTabButtons()
    show(selected, animated: false)
    loadPages()

    let swipe = UIPanGestureRecognizer(
      target: self, action: #selector(handleTabSwipe(_:)))
    swipe.delegate = self
    swipe.cancelsTouchesInView = true
    view.addGestureRecognizer(swipe)
    tabSwipePan = swipe
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    host.frame = view.bounds
    let safeBottom = view.safeAreaInsets.bottom
    let normalDock = dockFrame(safeBottom: safeBottom)
    tabDock.bounds = CGRect(origin: .zero, size: normalDock.size)
    tabDock.center = CGPoint(x: normalDock.midX, y: normalDock.midY)
    tabDock.layer.shadowPath = UIBezierPath(
      roundedRect: tabDock.bounds,
      cornerRadius: NativeTheme.cornerRadius).cgPath
    let buttonCount = max(1, tabButtons.count)
    let buttonWidth = (tabDock.bounds.width - 10 - 3 * CGFloat(buttonCount - 1))
      / CGFloat(buttonCount)
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
    for child in [detail?.view, comments?.view, episodes?.view, related?.view] {
      child?.frame = host.bounds
    }
  }

  private func dockFrame(safeBottom: CGFloat? = nil) -> CGRect {
    let dockWidth: CGFloat = 304
    let bottom = safeBottom ?? view.safeAreaInsets.bottom
    return CGRect(
      x: (view.bounds.width - dockWidth) / 2,
      y: view.bounds.height - bottom - 28 - 66,
      width: dockWidth,
      height: 66
    )
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
    if view.isHidden, reveal > 0.01 {
      tabSwipeSuppressedUntil = CACurrentMediaTime() + 0.5
    }
    view.alpha = reveal
    view.isHidden = reveal < 0.01
    view.isUserInteractionEnabled = reveal > 0.01
  }

  func update(item: VideoItem, quality: Int, danmaku: Bool, loop: Bool,
              select tab: Tab? = nil) {
    self.item = item
    initialQuality = quality
    initialDanmakuOn = danmaku
    initialLoopOn = loop
    if let tab = tab {
      selected = tab
    }
    clearContent()
    pages = []
    currentCid = item.cid
    if selected == .episodes {
      selected = .comments
    }
    configureTabButtons()
    show(selected, animated: false)
    loadPages()
  }

  func select(_ tab: Tab) {
    if tab == .episodes && pages.count <= 1 { return }
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

  private func show(_ tab: Tab, animated: Bool = true) {
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
    case .episodes:
      controller = ensureEpisodes()
    case .related:
      controller = ensureRelated()
    }
    let visible = [detail, comments, episodes, related]
      .compactMap { $0 }
      .first { $0.view.superview != nil && !$0.view.isHidden }
    controller.view.frame = host.bounds
    controller.view.isHidden = false
    host.bringSubviewToFront(controller.view)
    view.bringSubviewToFront(tabDock)
    if dockHidden {
      setDockHidden(false, animated: false)
    }
    updateTabs()

    guard animated, let old = visible, old !== controller else {
      for child in [detail, comments, episodes, related] {
        guard let child = child, child !== controller else { continue }
        child.view.isHidden = true
        child.view.alpha = 1
        child.view.transform = .identity
      }
      controller.view.alpha = 1
      controller.view.transform = .identity
      return
    }

    for child in [detail, comments, episodes, related] {
      guard let child = child, child !== controller, child !== old else { continue }
      child.view.isHidden = true
      child.view.alpha = 1
      child.view.transform = .identity
    }
    old.view.isHidden = false
    old.view.alpha = 1
    old.view.transform = .identity
    controller.view.alpha = 0
    controller.view.transform = .identity
    transitionToken += 1
    let token = transitionToken
    UIView.animate(withDuration: 0.22, delay: 0,
                   options: [.curveEaseInOut, .beginFromCurrentState,
                             .allowUserInteraction]) {
      old.view.alpha = 0
      controller.view.alpha = 1
    } completion: { _ in
      guard token == self.transitionToken else { return }
      for child in [self.detail, self.comments, self.episodes, self.related] {
        guard let child = child, child !== controller else { continue }
        child.view.isHidden = true
        child.view.alpha = 1
        child.view.transform = .identity
      }
    }
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
    controller.onPullDown = { [weak self] progress in self?.onPullDown?(progress) }
    controller.onPullDownEnded = { [weak self] complete in
      self?.onPullDownEnded?(complete)
    }
    controller.onScroll = { [weak self] delta, position in
      self?.contentScrolled(delta: delta, position: position)
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
    controller.onScroll = { [weak self] delta, position in
      self?.contentScrolled(delta: delta, position: position)
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

  private func ensureEpisodes() -> EpisodesViewController {
    if let episodes = episodes { return episodes }
    let controller = EpisodesViewController(pages: pages, currentCid: currentCid)
    controller.onSelect = { [weak self] page in
      guard let self = self else { return }
      self.currentCid = page.cid
      self.item.cid = page.cid
      self.episodes?.setCurrentCid(page.cid)
      self.onSelectPage?(page)
    }
    controller.onScroll = { [weak self] delta, position in
      self?.contentScrolled(delta: delta, position: position)
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
    controller.view.isHidden = selected != .episodes
    episodes = controller
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
    controller.onPullDown = { [weak self] progress in self?.onPullDown?(progress) }
    controller.onPullDownEnded = { [weak self] complete in
      self?.onPullDownEnded?(complete)
    }
    controller.onScroll = { [weak self] delta, position in
      self?.contentScrolled(delta: delta, position: position)
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
    for controller in [detail, comments, episodes, related] {
      guard let controller = controller else { continue }
      controller.willMove(toParent: nil)
      controller.view.removeFromSuperview()
      controller.removeFromParent()
    }
    detail = nil
    comments = nil
    episodes = nil
    related = nil
  }

  private func updateTabs() {
    for (index, button) in tabButtons.enumerated() where index < tabs.count {
      let on = tabs[index].tab == selected
      button.backgroundColor = on ? NativeTheme.foreground : .clear
      button.setTitleColor(on ? NativeTheme.background : NativeTheme.secondary, for: .normal)
    }
  }

  private func configureTabButtons() {
    guard isViewLoaded else { return }
    for button in tabButtons {
      button.removeFromSuperview()
    }
    tabButtons.removeAll()
    tabs = [
      ("详情", .detail),
      ("评论", .comments),
    ]
    if pages.count > 1 {
      tabs.append(("分集", .episodes))
    }
    tabs.append(("推荐", .related))
    if selected == .episodes && pages.count <= 1 {
      selected = .comments
    }
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
    tabDock.setNeedsLayout()
    setNeedsLayoutIfLoaded()
  }

  private func setNeedsLayoutIfLoaded() {
    guard isViewLoaded else { return }
    view.setNeedsLayout()
  }

  private func loadPages() {
    guard item.roomId == 0, !item.bvid.isEmpty else { return }
    pagesToken += 1
    let token = pagesToken
    BiliAPI.shared.videoInfo(item.bvid) { [weak self] result in
      guard let self = self, token == self.pagesToken else { return }
      guard case .success(let json) = result else { return }
      let rows = json["pages"] as? [[String: Any]] ?? []
      var parsed: [VideoPage] = []
      for (index, row) in rows.enumerated() {
        let cid = o11a1Int64(row["cid"])
        guard cid > 0 else { continue }
        let number = o11a1Int(row["page"])
        parsed.append(VideoPage(
          cid: cid,
          page: number > 0 ? number : index + 1,
          title: o11a1String(row["title"]),
          duration: o11a1Int(row["duration"])))
      }
      self.setPages(parsed)
    }
  }

  private func setPages(_ values: [VideoPage]) {
    let hadEpisodes = pages.count > 1
    pages = values
    let hasEpisodes = values.count > 1
    if currentCid <= 0, let first = values.first {
      currentCid = first.cid
    }
    if hadEpisodes != hasEpisodes {
      configureTabButtons()
    }
    episodes?.update(pages: values, currentCid: currentCid)
    if selected == .episodes && !hasEpisodes {
      select(.comments)
    }
  }

  func setCurrentPage(_ page: VideoPage) {
    currentCid = page.cid
    item.cid = page.cid
    episodes?.setCurrentCid(page.cid)
  }

  private func contentScrolled(delta: CGFloat, position: CGFloat) {
    guard abs(delta) > 8 else { return }
    let now = CACurrentMediaTime()
    if (delta > 0) != (dockScrollAccumulator > 0) {
      dockScrollAccumulator = 0
    }
    dockScrollAccumulator += delta
    if delta > 0, !dockHidden, position > 24,
       dockScrollAccumulator > 20, now - dockLastChange > 0.24 {
      dockScrollAccumulator = 0
      dockLastChange = now
      setDockHidden(true, animated: true)
    } else if delta < 0, dockHidden,
              dockScrollAccumulator < -26, now - dockLastChange > 0.32 {
      dockScrollAccumulator = 0
      dockLastChange = now
      setDockHidden(false, animated: true)
    }
  }

  private func setDockHidden(_ hidden: Bool, animated: Bool) {
    dockHidden = hidden
    dockScrollAccumulator = 0
    tabDock.isUserInteractionEnabled = false
    tabDock.alpha = 1
    let normal = dockFrame()
    let distance = max(120, view.bounds.height - normal.minY + 16)
    let transform = hidden
      ? CGAffineTransform(translationX: 0, y: distance)
      : .identity
    let changes = {
      self.tabDock.transform = transform
    }
    let finish = {
      self.tabDock.isUserInteractionEnabled = !self.dockHidden
    }
    if animated {
      UIView.animate(withDuration: 0.5, delay: 0,
                     usingSpringWithDamping: 0.92,
                     initialSpringVelocity: 0.15,
                     options: [.allowUserInteraction, .beginFromCurrentState],
                     animations: changes,
                     completion: { _ in finish() })
    } else {
      changes()
      finish()
    }
  }

  @objc private func tabTapped(_ sender: UIButton) {
    guard let tab = Tab(rawValue: sender.tag) else { return }
    guard tab != selected else { return }
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    select(tab)
  }

  @objc private func handleTabSwipe(_ gesture: UIPanGestureRecognizer) {
    guard gesture.state == .ended || gesture.state == .cancelled else { return }
    let translation = gesture.translation(in: view)
    let velocity = gesture.velocity(in: view)
    let horizontal = abs(translation.x) > abs(translation.y) * 1.4
      || abs(velocity.x) > abs(velocity.y) * 1.5
    guard horizontal,
          abs(translation.x) > 55 || abs(velocity.x) > 420 else { return }
    let all = tabs.map { $0.tab }
    guard let index = all.firstIndex(of: selected) else { return }
    let next = translation.x < 0 ? index + 1 : index - 1
    guard all.indices.contains(next) else { return }
    if all[next] == .episodes && pages.count <= 1 { return }
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    select(all[next])
  }

  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                         shouldReceive touch: UITouch) -> Bool {
    if gestureRecognizer === tabSwipePan {
      if touch.view?.isDescendant(of: tabDock) == true {
        return false
      }
      tabSwipeStartX = touch.location(in: view).x
    }
    return true
  }

  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    guard let pan = gestureRecognizer as? UIPanGestureRecognizer,
          pan === tabSwipePan else { return true }
    guard tabSwipeStartX >= view.bounds.width / 6.0,
          tabSwipeStartX < view.bounds.width * 5.0 / 6.0,
          CACurrentMediaTime() >= tabSwipeSuppressedUntil else { return false }
    let translation = pan.translation(in: view)
    let velocity = pan.velocity(in: view)
    let horizontal = abs(translation.x) >= 10
      && abs(translation.x) > abs(translation.y) * 1.6
    let flick = abs(velocity.x) >= 180
      && abs(velocity.x) > abs(velocity.y) * 2.0
    return horizontal || flick
  }

  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                         shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
    return gestureRecognizer === tabSwipePan || other === tabSwipePan
  }
}
