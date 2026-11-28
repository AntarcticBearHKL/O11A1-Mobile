import UIKit

final class RootViewController: UIViewController, UIGestureRecognizerDelegate {
  private let mainHost = UIView()
  private let contentView = UIView()
  private let tabBar = GlassTabBar()
  private let searchButton = UIButton(type: .system)
  private let avatarButton = UIButton(type: .system)
  private let topAvatar = UIImageView()
  private var currentChild: UIViewController?
  private var player: PlayerViewController?
  private var upProfile: UpProfileViewController?
  private var profileCoveredByPlayer = false
  private var feed: FeedViewController?
  private var following: VideoListViewController?
  private var dynamic: DynamicViewController?
  private var messages: MessagesViewController?
  private var fish: AIViewController?
  private var sidebar: SidebarView?
  private var sidebarProgress: CGFloat = 0
  private var sidebarDragStartProgress: CGFloat = 0
  private var sidebarEdgePan: UIScreenEdgePanGestureRecognizer?
  private var sidebarClosePan: UIPanGestureRecognizer?
  private var settingsPan: UIPanGestureRecognizer?
  private var settingsPanStartX: CGFloat = 0
  private var myController: MyViewController?
  private var feedScrollingAtEdgeTouch = false
  private var orientationObserver: NSObjectProtocol?
  private var testFlowTriggered = false

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return traitCollection.userInterfaceStyle == .dark ? .lightContent : .darkContent
  }

  override var prefersHomeIndicatorAutoHidden: Bool { true }

  override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    if let player = player, !player.isMiniWindow, !player.isSystemPip {
      return .allButUpsideDown
    }
    return .portrait
  }

  override var prefersStatusBarHidden: Bool {
    return false
  }

  override var childForStatusBarStyle: UIViewController? {
    if let player = player, player.isMiniWindow || player.isSystemPip { return nil }
    if profileCoveredByPlayer, let player = player { return player }
    return upProfile ?? player
  }

  override var childForStatusBarHidden: UIViewController? {
    if let player = player, player.isMiniWindow || player.isSystemPip { return nil }
    if profileCoveredByPlayer, let player = player { return player }
    return upProfile ?? player
  }

  private func setPlayerOrientation(_ landscape: Bool) {
    if #available(iOS 16.0, *) {
      setNeedsUpdateOfSupportedInterfaceOrientations()
      if let scene = view.window?.windowScene {
        scene.requestGeometryUpdate(
          .iOS(interfaceOrientations: landscape ? .landscapeRight : .portrait))
      }
    } else {
      UIViewController.attemptRotationToDeviceOrientation()
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = NativeTheme.background
    ThemeManager.shared.apply()
    UIApplication.shared.isIdleTimerDisabled = true

    mainHost.backgroundColor = NativeTheme.background
    view.addSubview(mainHost)
    mainHost.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      mainHost.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      mainHost.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      mainHost.topAnchor.constraint(equalTo: view.topAnchor),
      mainHost.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    contentView.backgroundColor = NativeTheme.background
    mainHost.addSubview(contentView)
    contentView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      contentView.leadingAnchor.constraint(equalTo: mainHost.leadingAnchor),
      contentView.trailingAnchor.constraint(equalTo: mainHost.trailingAnchor),
      contentView.topAnchor.constraint(equalTo: mainHost.topAnchor),
      contentView.bottomAnchor.constraint(equalTo: mainHost.bottomAnchor),
    ])

    tabBar.onSelect = { [weak self] index in
      self?.selectTab(index)
    }
    tabBar.onReselect = { [weak self] in
      self?.closeMessages()
    }
    tabBar.onMenu = { [weak self] index in
      guard let self = self else { return }
      switch index {
      case 0:
        self.presentModule(from: self, mode: .live, target: 0, title: "直播")
      case 1:
        self.presentModule(from: self, mode: .bangumi, target: 0, title: "番剧")
      case 2:
        self.openMessages()
      default:
        self.presentModule(from: self, mode: .history, target: 0, title: "历史")
      }
    }
    mainHost.addSubview(tabBar)
    tabBar.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      tabBar.leadingAnchor.constraint(equalTo: mainHost.leadingAnchor, constant: 12),
      tabBar.trailingAnchor.constraint(equalTo: mainHost.trailingAnchor, constant: -12),
      tabBar.bottomAnchor.constraint(equalTo: mainHost.bottomAnchor, constant: -24),
    ])

    let topIconConfig = UIImage.SymbolConfiguration(pointSize: 19, weight: .bold)
    searchButton.setImage(
      UIImage(systemName: "magnifyingglass", withConfiguration: topIconConfig),
      for: .normal)
    searchButton.tintColor = NativeTheme.foreground
    searchButton.backgroundColor = NativeTheme.surface
    searchButton.layer.cornerRadius = 12
    searchButton.layer.cornerCurve = .continuous
    searchButton.layer.shadowColor = UIColor.black.cgColor
    searchButton.layer.shadowOpacity = 0.16
    searchButton.layer.shadowRadius = 12
    searchButton.layer.shadowOffset = CGSize(width: 0, height: 4)
    searchButton.addTarget(self, action: #selector(openSearchFromTop), for: .touchUpInside)
    mainHost.addSubview(searchButton)
    searchButton.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      searchButton.trailingAnchor.constraint(equalTo: mainHost.trailingAnchor, constant: -16),
      searchButton.topAnchor.constraint(equalTo: mainHost.safeAreaLayoutGuide.topAnchor, constant: 6),
      searchButton.widthAnchor.constraint(equalToConstant: 48),
      searchButton.heightAnchor.constraint(equalToConstant: 48),
    ])

    avatarButton.setImage(
      UIImage(systemName: "person.crop.circle.fill", withConfiguration: topIconConfig),
      for: .normal)
    avatarButton.tintColor = NativeTheme.foreground
    avatarButton.backgroundColor = NativeTheme.surface
    avatarButton.layer.cornerRadius = 12
    avatarButton.layer.cornerCurve = .continuous
    avatarButton.layer.borderWidth = 0.5
    avatarButton.layer.borderColor = NativeTheme.hairline.cgColor
    avatarButton.layer.shadowColor = UIColor.black.cgColor
    avatarButton.layer.shadowOpacity = 0.16
    avatarButton.layer.shadowRadius = 12
    avatarButton.layer.shadowOffset = CGSize(width: 0, height: 4)
    avatarButton.addTarget(self, action: #selector(openMy), for: .touchUpInside)
    mainHost.addSubview(avatarButton)
    avatarButton.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      avatarButton.leadingAnchor.constraint(equalTo: mainHost.leadingAnchor, constant: 16),
      avatarButton.topAnchor.constraint(equalTo: mainHost.safeAreaLayoutGuide.topAnchor, constant: 6),
      avatarButton.widthAnchor.constraint(equalToConstant: 48),
      avatarButton.heightAnchor.constraint(equalToConstant: 48),
    ])

    topAvatar.contentMode = .scaleAspectFill
    topAvatar.clipsToBounds = true
    topAvatar.layer.cornerRadius = 12
    topAvatar.layer.cornerCurve = .continuous
    topAvatar.isUserInteractionEnabled = false
    avatarButton.addSubview(topAvatar)
    topAvatar.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      topAvatar.leadingAnchor.constraint(equalTo: avatarButton.leadingAnchor),
      topAvatar.trailingAnchor.constraint(equalTo: avatarButton.trailingAnchor),
      topAvatar.topAnchor.constraint(equalTo: avatarButton.topAnchor),
      topAvatar.bottomAnchor.constraint(equalTo: avatarButton.bottomAnchor),
    ])
    topAvatar.isHidden = true

    searchButton.isHidden = false
    avatarButton.isHidden = false

    let edge = UIScreenEdgePanGestureRecognizer(
      target: self, action: #selector(handleSidebarEdge(_:)))
    edge.edges = .left
    edge.delegate = self
    edge.isEnabled = false
    view.addGestureRecognizer(edge)
    sidebarEdgePan = edge

    let closePan = UIPanGestureRecognizer(
      target: self, action: #selector(handleSidebarCloseDrag(_:)))
    closePan.delegate = self
    closePan.cancelsTouchesInView = true
    view.addGestureRecognizer(closePan)
    sidebarClosePan = closePan

    let settings = UIPanGestureRecognizer(
      target: self, action: #selector(handleSettingsPan(_:)))
    settings.delegate = self
    settings.cancelsTouchesInView = true
    view.addGestureRecognizer(settings)
    settingsPan = settings

    BiliAPI.shared.client.prewarm()
    if BiliAPI.shared.isLoggedIn {
      BiliAPI.shared.history(page: 1) { result in
        if case .success(let items) = result {
          WatchProgressStore.shared.mergeHistory(items)
        }
      }
    }
    selectTab(0, force: true)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    ThemeManager.shared.apply()
    loadTopAvatar()
    ClipboardShareWatcher.shared.onOpen = { [weak self] target in
      self?.openShared(target)
    }
    ClipboardShareWatcher.shared.start()
    guard !testFlowTriggered else { return }
    testFlowTriggered = true
    let flow = ProcessInfo.processInfo.environment["O11A1_TEST_FLOW"] ?? ""
    switch flow {
    case "player", "player-detail", "player-comments", "player-settings", "player-related",
         "player-landscape", "player-portrait", "player-controls", "player-panel", "player-up",
         "player-danmaku", "player-stage-comments", "player-mini":
      DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
        self?.feed?.openFirstForTest()
      }
    case "my":
      DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
        self?.openMy()
      }
    case "modules":
      DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
        guard let self = self else { return }
        self.presentModule(from: self, mode: .hot, target: 0, title: "热门")
      }
    case "fish":
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
        self?.selectTab(3)
      }
    case "toolbar":
      DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
        self?.tabBar.setExpanded(true, animated: true)
      }
    case "search":
      DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
        self?.feed?.openSearchFromHost()
      }
    case "login":
      DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
        guard let self = self else { return }
        let login = LoginViewController()
        login.modalPresentationStyle = .formSheet
        self.present(login, animated: true)
      }
    default:
      break
    }
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    setNeedsStatusBarAppearanceUpdate()
    tabBar.setNeedsDisplay()
  }

  private func makeFeed() -> FeedViewController {
    if let feed = feed { return feed }
    let controller = FeedViewController()
    controller.onOpen = { [weak self] item, cell in
      self?.openPlayer(item, from: cell)
    }
    controller.onOpenPreview = { [weak self] item, cell, preview in
      self?.openPlayer(item, from: cell, preview: preview)
    }
    controller.onProfile = { [weak self] mid in
      self?.openProfile(mid)
    }
    controller.onSearchOpen = { [weak self] item in
      self?.openPlayer(item, from: nil)
    }
    controller.onSeason = { [weak self] item in
      guard let self = self else { return }
      let title = item.title.isEmpty ? "番剧" : item.title
      self.presentModule(from: self, mode: .season, target: item.seasonId, title: title)
    }
    controller.onSidebar = { [weak self] in
      self?.openMy()
    }
    controller.onSidebarPanBegan = {}
    controller.onSidebarPanChanged = { _ in }
    controller.onSidebarPanEnded = { [weak self] translation, velocity in
      guard let self = self else { return }
      let width = max(1, self.view.bounds.width)
      if translation > width * 0.22 || velocity > 350 {
        self.openMy()
      } else {
        self.feed?.resumePreview()
      }
    }
    controller.onToolbar = { [weak self] hidden in
      self?.setTopChromeHidden(hidden, animated: true)
    }
    if let module = HomeModules.currentDef, module.source != "recommend" {
      controller.initialSource = (module.source, module.name)
    }
    feed = controller
    return controller
  }

  private func selectTab(_ index: Int, force: Bool = false) {
    closeMessages()
    if index != 0 {
      feed?.suspendPreview()
    }
    feed?.setToolbarHidden(false)
    tabBar.isHidden = false
    searchButton.isHidden = false
    avatarButton.isHidden = false
    setTopChromeHidden(false, animated: true)
    if tabBar.selectedIndex != index {
      tabBar.select(index: index, notify: false)
    }
    let controller: UIViewController
    switch index {
    case 0:
      controller = makeFeed()
    case 1:
      if following == nil {
        let list = VideoListViewController(mode: .following, title: "关注")
        list.onOpen = { [weak self] item, cell in self?.openPlayer(item, from: cell) }
        following = list
      }
      controller = following!
    case 2:
      if dynamic == nil {
        let list = DynamicViewController()
        list.onOpenVideo = { [weak self] item in self?.openPlayer(item, from: nil) }
        list.onLogin = { [weak self, weak list] in
          guard let self = self else { return }
          let login = LoginViewController()
          login.modalPresentationStyle = .formSheet
          login.onLogin = { [weak list] in list?.reload() }
          self.present(login, animated: true)
        }
        dynamic = list
      }
      controller = dynamic!
    default:
      if fish == nil { fish = AIViewController() }
      controller = fish!
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
      guard let self = self, self.tabBar.selectedIndex == index else { return }
      self.showChild(controller)
      if index == 0 {
        self.feed?.resumePreview()
      }
    }
  }

  private func showChild(_ controller: UIViewController) {
    if currentChild === controller {
      return
    }
    currentChild?.willMove(toParent: nil)
    currentChild?.view.removeFromSuperview()
    currentChild?.removeFromParent()
    addChild(controller)
    controller.view.frame = contentView.bounds
    controller.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    contentView.addSubview(controller.view)
    controller.didMove(toParent: self)
    currentChild = controller
    installSettingsPanDependency(in: controller.view)
    mainHost.bringSubviewToFront(tabBar)
    mainHost.bringSubviewToFront(searchButton)
    mainHost.bringSubviewToFront(avatarButton)
  }

  private func installSettingsPanDependency(in root: UIView) {
    guard let settingsPan = settingsPan else { return }
    if let scroll = root as? UIScrollView {
      scroll.panGestureRecognizer.require(toFail: settingsPan)
    }
    for child in root.subviews {
      installSettingsPanDependency(in: child)
    }
  }

  private func openPlayer(_ item: VideoItem, from source: UIView?,
                          startAt: Double = 0,
                          preview: PreviewHandoff? = nil) {
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    if let presented = presentedViewController {
      presented.dismiss(animated: false)
    }
    if let existing = player {
      if existing.isSystemPip {
        existing.restoreFromSystemPiP()
      }
      if existing.isMiniWindow {
        existing.exitMiniWindow()
      }
      existing.play(item, startAt: startAt)
      view.bringSubviewToFront(existing.view)
      if upProfile != nil {
        profileCoveredByPlayer = true
        setNeedsStatusBarAppearanceUpdate()
      }
      return
    }
    guard player == nil else { return }
    feed?.suspendPreview()
    let sourceView = (source as? HomeCardCell)?.mediaHost
      ?? (source as? MiniVideoCardView)?.mediaHost
      ?? source
    let controller = PlayerViewController(
      item: item, sourceView: sourceView, preview: preview)
    controller.pendingStartSeconds = startAt
    controller.onClose = { [weak self] in
      self?.closePlayer()
    }
    controller.onProfile = { [weak self] mid in
      self?.openProfile(mid)
    }
    controller.onMinimize = { [weak self] in
      self?.playerDidMinimize()
    }
    controller.onExpand = { [weak self] in
      self?.playerDidExpand()
    }
    addChild(controller)
    controller.view.frame = view.bounds
    controller.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.addSubview(controller.view)
    controller.didMove(toParent: self)
    player = controller
    tabBar.isHidden = true
    searchButton.isHidden = true
    avatarButton.isHidden = true
    if upProfile != nil {
      profileCoveredByPlayer = true
    }
    controller.start()
    let warmBvid = item.bvid
    if !warmBvid.isEmpty {
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
        BiliAPI.shared.prefetchVideoInfo(bvid: warmBvid)
        BiliAPI.shared.prefetchRelated(warmBvid)
      }
    }
    if #available(iOS 16.0, *) {
      setNeedsUpdateOfSupportedInterfaceOrientations()
    } else {
      UIViewController.attemptRotationToDeviceOrientation()
    }
    beginOrientationTracking()
    setNeedsStatusBarAppearanceUpdate()
    let flow = ProcessInfo.processInfo.environment["O11A1_TEST_FLOW"] ?? ""
    if flow.hasPrefix("player-") {
      DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { [weak controller] in
        switch flow {
        case "player-detail": controller?.testOpenDetail()
        case "player-comments": controller?.testOpenComments()
        case "player-settings": controller?.testOpenSettings()
        case "player-related": controller?.testOpenRelated()
        case "player-landscape": controller?.testLandscape()
        case "player-portrait": controller?.testPortrait()
        case "player-controls": controller?.testShowControls(hold: true)
        case "player-panel": controller?.testShowControls(hold: true)
        case "player-up": controller?.testOpenProfile()
        case "player-danmaku": controller?.testOpenDanmakuSettings()
        case "player-stage-comments": controller?.testCommentsStage()
        case "player-mini": controller?.testMinimize()
        default: break
        }
      }
      if flow == "player-panel" {
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) { [weak controller] in
          controller?.testHideControls()
        }
      }
    }
  }

  private func setTopChromeHidden(_ hidden: Bool, animated: Bool) {
    tabBar.setHidden(hidden, animated: animated)
    let alpha: CGFloat = hidden ? 0 : 1
    if animated {
      UIView.animate(withDuration: 0.35, delay: 0,
                     options: [.allowUserInteraction, .beginFromCurrentState]) {
        self.searchButton.alpha = alpha
        self.avatarButton.alpha = alpha
      }
    } else {
      searchButton.alpha = alpha
      avatarButton.alpha = alpha
    }
  }

  private func playerDidMinimize() {
    tabBar.isHidden = false
    searchButton.isHidden = false
    avatarButton.isHidden = false
    feed?.setToolbarHidden(false)
    setTopChromeHidden(false, animated: true)
    setNeedsStatusBarAppearanceUpdate()
  }

  private func playerDidExpand() {
    tabBar.isHidden = true
    searchButton.isHidden = true
    avatarButton.isHidden = true
    setNeedsStatusBarAppearanceUpdate()
  }

  private func closePlayer() {
    guard let controller = player else { return }
    controller.willMove(toParent: nil)
    controller.view.removeFromSuperview()
    controller.removeFromParent()
    player = nil
    profileCoveredByPlayer = false
    endOrientationTracking()
    tabBar.isHidden = false
    searchButton.isHidden = false
    avatarButton.isHidden = false
    let searchOpen = feed?.isSearchOpen() == true
    feed?.setToolbarHidden(searchOpen)
    setTopChromeHidden(searchOpen, animated: true)
    setPlayerOrientation(false)
    setNeedsStatusBarAppearanceUpdate()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { [weak self] in
      guard let self = self, self.player == nil else { return }
      self.feed?.resumePreview()
    }
  }

  private func beginOrientationTracking() {
    guard orientationObserver == nil else { return }
    UIDevice.current.beginGeneratingDeviceOrientationNotifications()
    orientationObserver = NotificationCenter.default.addObserver(
      forName: UIDevice.orientationDidChangeNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      guard let self = self, self.player != nil else { return }
      self.requestPlayerOrientation(for: UIDevice.current.orientation)
    }
  }

  private func endOrientationTracking() {
    if let observer = orientationObserver {
      NotificationCenter.default.removeObserver(observer)
      orientationObserver = nil
    }
    UIDevice.current.endGeneratingDeviceOrientationNotifications()
  }

  private func requestPlayerOrientation(for device: UIDeviceOrientation) {
    guard device.isPortrait || device.isLandscape else { return }
    if #available(iOS 16.0, *) {
      let mask: UIInterfaceOrientationMask
      switch device {
      case .landscapeLeft:
        mask = .landscapeRight
      case .landscapeRight:
        mask = .landscapeLeft
      default:
        mask = .portrait
      }
      view.window?.windowScene?.requestGeometryUpdate(
        .iOS(interfaceOrientations: mask))
    } else {
      UIViewController.attemptRotationToDeviceOrientation()
    }
  }

  private func openProfile(_ mid: Int64) {
    guard mid > 0, upProfile == nil else { return }
    let page = UpProfileViewController(mid: mid)
    page.onClose = { [weak self] in self?.closeProfile() }
    page.onOpenVideo = { [weak self] item, source in
      self?.openPlayer(item, from: source)
    }
    addChild(page)
    page.view.frame = view.bounds
    page.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.addSubview(page.view)
    page.didMove(toParent: self)
    upProfile = page
    profileCoveredByPlayer = false
    page.view.transform = CGAffineTransform(translationX: view.bounds.width, y: 0)
    UIView.animate(withDuration: 0.38, delay: 0,
                   usingSpringWithDamping: 0.94, initialSpringVelocity: 0.2,
                   options: [.curveEaseOut]) {
      page.view.transform = .identity
    }
    setNeedsStatusBarAppearanceUpdate()
  }

  private func closeProfile() {
    guard let page = upProfile else { return }
    upProfile = nil
    profileCoveredByPlayer = false
    setNeedsStatusBarAppearanceUpdate()
    page.willMove(toParent: nil)
    UIView.animate(withDuration: 0.30, delay: 0,
                   options: [.curveEaseIn, .beginFromCurrentState]) {
      page.view.transform = CGAffineTransform(translationX: self.view.bounds.width, y: 0)
    } completion: { _ in
      page.view.removeFromSuperview()
      page.removeFromParent()
    }
  }

  @discardableResult
  private func ensureSidebar() -> SidebarView {
    if let sidebar = sidebar { return sidebar }
    let view = SidebarView()
    view.onHome = { [weak self] in
      self?.selectTab(0)
    }
    view.onModule = { [weak self] mode, title in
      guard let self = self else { return }
      if mode == .messages {
        self.openMessages()
      } else {
        self.presentModule(from: self, mode: mode, target: 0, title: title)
      }
    }
    view.onMy = { [weak self] in
      self?.openMy()
    }
    view.onSearch = { [weak self] in
      guard let self = self else { return }
      self.selectTab(0)
      self.feed?.openSearchFromHost()
    }
    view.onClose = { [weak self] in
      guard let self = self else { return }
      self.sidebarProgress = 0
      self.animateRecede(to: 0)
    }
    sidebar = view
    return view
  }

  private func setSidebarProgress(_ value: CGFloat) {
    let p = max(0, min(1, value))
    sidebarProgress = p
    sidebar?.setProgress(p)
    setRecedeProgress(p)
  }

  private func setRecedeProgress(_ p: CGFloat) {
    let progress = max(0, min(1, p))
    mainHost.layer.masksToBounds = progress > 0
    mainHost.layer.cornerRadius = NativeTheme.cornerRadius * progress
    let scale = 1 - 0.10 * progress
    let dx = view.bounds.width * 0.10 * progress
    let dy = -view.bounds.height * 0.5 * (1 - scale)
    mainHost.transform = CGAffineTransform(translationX: dx, y: dy)
      .scaledBy(x: scale, y: scale)
  }

  private func animateRecede(to p: CGFloat) {
    UIView.animate(withDuration: 0.34, delay: 0,
                   usingSpringWithDamping: 1, initialSpringVelocity: 0,
                   options: [.curveEaseOut]) {
      self.setRecedeProgress(p)
    }
  }

  private func prepareSidebarForDrag() {
    let sidebar = ensureSidebar()
    sidebar.prepare(in: view)
    view.bringSubviewToFront(sidebar)
    setSidebarProgress(0)
  }

  private func finishSidebarOpen() {
    guard let sidebar = sidebar, sidebar.superview != nil else { return }
    sidebar.animateOpen()
    sidebarProgress = 1
    animateRecede(to: 1)
  }

  private func finishSidebarClose() {
    guard let sidebar = sidebar, sidebar.superview != nil else { return }
    sidebarProgress = 0
    sidebar.close()
  }

  private func openSidebar() {
    if let sidebar = sidebar, sidebar.superview != nil { return }
    prepareSidebarForDrag()
    finishSidebarOpen()
  }

  @objc private func handleSidebarEdge(_ gesture: UIScreenEdgePanGestureRecognizer) {
    let translation = gesture.translation(in: view)
    let width = max(1, view.bounds.width)
    switch gesture.state {
    case .began:
      guard sidebar?.superview == nil,
            feed?.isSearchOpen() != true else { return }
      prepareSidebarForDrag()
    case .changed:
      guard sidebar?.superview != nil else { return }
      setSidebarProgress(max(0, translation.x) / (width * 0.50))
    case .ended, .cancelled:
      guard sidebar?.superview != nil else { return }
      let velocity = gesture.velocity(in: view).x
      let progress = max(0, translation.x) / (width * 0.50)
      if translation.x > 0 && (progress > 0.35 || velocity > 500) {
        finishSidebarOpen()
      } else {
        finishSidebarClose()
      }
    default:
      break
    }
  }

  @objc private func handleSidebarCloseDrag(_ gesture: UIPanGestureRecognizer) {
    let width = max(1, view.bounds.width)
    switch gesture.state {
    case .began:
      guard sidebar?.superview != nil else { return }
      sidebarDragStartProgress = sidebarProgress
    case .changed:
      guard sidebar?.superview != nil else { return }
      let translation = gesture.translation(in: view).x
      setSidebarProgress(sidebarDragStartProgress + translation / (width * 0.50))
    case .ended, .cancelled:
      guard sidebar?.superview != nil else { return }
      let velocity = gesture.velocity(in: view).x
      if sidebarProgress < 0.65 || velocity < -500 {
        finishSidebarClose()
      } else {
        finishSidebarOpen()
      }
    default:
      break
    }
  }

  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                         shouldReceive touch: UITouch) -> Bool {
    if gestureRecognizer === sidebarEdgePan {
      feedScrollingAtEdgeTouch = feed?.isFeedScrolling() ?? false
    }
    if gestureRecognizer === settingsPan {
      if touch.view?.isDescendant(of: tabBar) == true { return false }
      if touch.view?.isDescendant(of: searchButton) == true { return false }
      if touch.view?.isDescendant(of: avatarButton) == true { return false }
      settingsPanStartX = touch.location(in: view).x
    }
    return true
  }

  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    if gestureRecognizer === settingsPan {
      guard player == nil || player?.isMiniWindow == true || player?.isSystemPip == true,
            presentedViewController == nil,
            myController == nil, upProfile == nil,
            sidebar?.superview == nil,
            feed?.isSearchOpen() != true,
            feed?.isFeedScrolling() != true,
            let pan = gestureRecognizer as? UIPanGestureRecognizer else {
        return false
      }
      guard settingsPanStartX <= view.bounds.width / 3.0 else { return false }
      let translation = pan.translation(in: view)
      let velocity = pan.velocity(in: view)
      let movingRight = translation.x > 2 || velocity.x > 80
      let horizontal = abs(translation.x) > abs(translation.y) * 1.6
        || abs(velocity.x) > abs(velocity.y) * 1.6
      return movingRight && horizontal
    }
    if gestureRecognizer === sidebarEdgePan {
      guard player == nil, presentedViewController == nil,
            feed?.isSearchOpen() != true, sidebar?.superview == nil,
            !feedScrollingAtEdgeTouch else { return false }
      return true
    }
    if gestureRecognizer === sidebarClosePan {
      guard sidebar?.superview != nil else { return false }
      let velocity = (gestureRecognizer as? UIPanGestureRecognizer)?.velocity(in: view) ?? .zero
      let translation = (gestureRecognizer as? UIPanGestureRecognizer)?.translation(in: view) ?? .zero
      let movingLeft = velocity.x < -1 || translation.x < -1
      return movingLeft && (abs(translation.x) > abs(translation.y) * 1.1
        || abs(velocity.x) > abs(velocity.y) * 1.1)
    }
    return true
  }

  private func openMessages() {
    guard messages == nil else { return }
    let controller = MessagesViewController()
    controller.onLogin = { [weak self, weak controller] in
      guard let self = self else { return }
      let login = LoginViewController()
      login.modalPresentationStyle = .formSheet
      login.onLogin = { [weak controller] in controller?.reload() }
      self.present(login, animated: true)
    }
    controller.onClose = { [weak self] in self?.closeMessages() }
    addChild(controller)
    controller.view.frame = contentView.bounds
    controller.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    contentView.addSubview(controller.view)
    controller.didMove(toParent: self)
    messages = controller
    mainHost.bringSubviewToFront(tabBar)
    mainHost.bringSubviewToFront(searchButton)
    mainHost.bringSubviewToFront(avatarButton)
  }

  private func closeMessages() {
    guard let controller = messages else { return }
    controller.willMove(toParent: nil)
    controller.view.removeFromSuperview()
    controller.removeFromParent()
    messages = nil
  }

  private func openShared(_ target: BiliShareTarget) {
    if target.part <= 1, !target.bvid.isEmpty,
       let cached = feed?.cachedItem(bvid: target.bvid) {
      openPlayer(cached, from: nil, startAt: target.startSeconds)
      return
    }
    let apply: ([String: Any]) -> Void = { [weak self] json in
      guard let self = self else { return }
      var dict = json
      if let stat = json["stat"] as? [String: Any] {
        dict["play"] = o11a1Int64(stat["view"])
        dict["playText"] = o11a1Count(o11a1Int64(stat["view"]))
      }
      if let pages = json["pages"] as? [[String: Any]],
         target.part > 1, target.part <= pages.count {
        dict["cid"] = pages[target.part - 1]["cid"]
      }
      let item = VideoItem(json: dict)
      guard !item.bvid.isEmpty else { return }
      DispatchQueue.main.async {
        self.openPlayer(item, from: nil, startAt: target.startSeconds)
      }
    }
    let fallback: () -> Void = { [weak self] in
      guard let self = self, !target.bvid.isEmpty else { return }
      var item = VideoItem()
      item.bvid = target.bvid
      item.aid = target.aid
      item.title = target.bvid
      item.owner = "B站视频"
      item.kind = "video"
      DispatchQueue.main.async {
        self.openPlayer(item, from: nil, startAt: target.startSeconds)
      }
    }
    if !target.bvid.isEmpty {
      BiliAPI.shared.videoInfo(target.bvid) { result in
        switch result {
        case .success(let json): apply(json)
        case .failure: fallback()
        }
      }
    } else if target.aid > 0 {
      BiliAPI.shared.videoInfo(aid: target.aid) { result in
        switch result {
        case .success(let json): apply(json)
        case .failure: break
        }
      }
    }
  }

  @objc private func openSearchFromTop() {
    selectTab(0)
    feed?.openSearchFromHost()
  }

  private func loadTopAvatar() {
    BiliAPI.shared.account { [weak self] info in
      guard let self = self, !info.face.isEmpty else { return }
      ImageLoader.shared.load(info.face, into: self.topAvatar)
      self.topAvatar.isHidden = false
      self.avatarButton.setImage(nil, for: .normal)
    }
  }

  @objc private func openMy() {
    guard myController == nil else { return }
    if let feed = feed, currentChild === feed {
      feed.suspendPreview()
    }
    let my = makeMyController()
    addChild(my)
    my.view.frame = view.bounds
    my.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.addSubview(my.view)
    my.didMove(toParent: self)
    myController = my
    my.view.transform = CGAffineTransform(translationX: -view.bounds.width, y: 0)
    setRecedeProgress(0)
    finishMyOpen()
  }

  private func makeMyController() -> MyViewController {
    let my = MyViewController()
    my.onClose = { [weak self] in self?.removeMyController() }
    my.onFish = { [weak self] in
      self?.closeMy { [weak self] in self?.selectTab(3) }
    }
    my.onSettings = { [weak self] in
      self?.closeMy { [weak self] in self?.openSettings() }
    }
    my.onOpenModule = { [weak self, weak my] mode, target, title in
      guard let self = self, let my = my else { return }
      self.presentModule(from: my, mode: mode, target: target, title: title)
    }
    return my
  }

  private func beginMyDrag() {
    guard myController == nil else { return }
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    if let feed = feed, currentChild === feed {
      feed.suspendPreview()
    }
    let my = makeMyController()
    addChild(my)
    my.view.frame = view.bounds
    my.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.addSubview(my.view)
    my.didMove(toParent: self)
    myController = my
    my.view.transform = CGAffineTransform(translationX: -view.bounds.width, y: 0)
    setRecedeProgress(0)
  }

  private func setMyProgress(_ value: CGFloat) {
    guard let my = myController else { return }
    let p = max(0, min(1, value))
    let width = max(1, view.bounds.width)
    my.view.transform = CGAffineTransform(
      translationX: -width * (1 - p), y: 0)
  }

  private func finishMyOpen() {
    guard let my = myController else { return }
    UIView.animate(withDuration: 0.34, delay: 0,
                   usingSpringWithDamping: 0.9,
                   initialSpringVelocity: 0.25,
                   options: [.beginFromCurrentState, .allowUserInteraction]) {
      my.view.transform = .identity
    }
  }

  private func closeMy(then action: @escaping () -> Void) {
    guard let my = myController else {
      action()
      return
    }
    myController = nil
    settingsPan?.isEnabled = false
    UIView.animate(withDuration: 0.24, delay: 0,
                   options: [.curveEaseIn, .beginFromCurrentState]) {
      my.view.transform = CGAffineTransform(
        translationX: -self.view.bounds.width, y: 0)
    } completion: { _ in
      my.willMove(toParent: nil)
      my.view.removeFromSuperview()
      my.removeFromParent()
      self.settingsPan?.isEnabled = true
      if let feed = self.feed, self.currentChild === feed {
        feed.resumePreview()
      }
      action()
    }
  }

  private func removeMyController() {
    guard let my = myController else { return }
    myController = nil
    my.willMove(toParent: nil)
    my.view.removeFromSuperview()
    my.removeFromParent()
    if let feed = feed, currentChild === feed {
      feed.resumePreview()
    }
    animateRecede(to: 0)
  }

  @objc private func handleSettingsPan(_ gesture: UIPanGestureRecognizer) {
    let width = max(1, view.bounds.width)
    switch gesture.state {
    case .began:
      beginMyDrag()
    case .changed:
      guard myController != nil else { return }
      let translation = max(0, gesture.translation(in: view).x)
      setMyProgress(translation / width)
    case .ended, .cancelled:
      guard myController != nil else { return }
      let translation = max(0, gesture.translation(in: view).x)
      let velocity = gesture.velocity(in: view).x
      let progress = translation / width
      let open = (progress > 0.28 && velocity > -450) || velocity > 550
      if open {
        finishMyOpen()
      } else {
        closeMy {}
      }
    default:
      break
    }
  }

  private func presentModule(from host: UIViewController,
                             mode: ModuleListViewController.Mode,
                             target: Int64,
                             title: String) {
    let module = ModuleListViewController(mode: mode, targetId: target, title: title)
    module.modalPresentationStyle = .fullScreen
    module.onClose = { [weak module] in
      module?.dismiss(animated: true)
    }
    module.onLogin = { [weak module] in
      let login = LoginViewController()
      login.modalPresentationStyle = .formSheet
      login.onLogin = { [weak module] in module?.reload() }
      module?.present(login, animated: true)
    }
    module.onSelect = { [weak self, weak module] item in
      guard let self = self, let module = module else { return }
      if item.kind == "season", item.seasonId > 0 {
        self.presentModule(from: module, mode: .season, target: item.seasonId, title: item.title)
        return
      }
      let player = PlayerViewController(item: item, sourceView: nil)
      player.modalPresentationStyle = .overFullScreen
      player.onClose = { [weak player] in player?.dismiss(animated: false) }
      module.present(player, animated: false)
    }
    host.present(module, animated: true)
  }

  @objc private func openSettings() {
    let settings = SettingsViewController()
    let nav = UINavigationController(rootViewController: settings)
    nav.modalPresentationStyle = .pageSheet
    present(nav, animated: true)
  }
}
