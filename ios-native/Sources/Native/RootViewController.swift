import UIKit

final class RootViewController: UIViewController, UIGestureRecognizerDelegate {
  private let mainHost = UIView()
  private let contentView = UIView()
  private let tabBar = GlassTabBar()
  private let settingsButton = UIButton(type: .system)
  private let myButton = UIButton(type: .system)
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
  private var feedScrollingAtEdgeTouch = false
  private var orientationObserver: NSObjectProtocol?
  private var testFlowTriggered = false

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return traitCollection.userInterfaceStyle == .dark ? .lightContent : .darkContent
  }

  override var prefersHomeIndicatorAutoHidden: Bool { true }

  override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    return player == nil ? .portrait : .allButUpsideDown
  }

  override var prefersStatusBarHidden: Bool {
    return false
  }

  override var childForStatusBarStyle: UIViewController? {
    if profileCoveredByPlayer, let player = player { return player }
    return upProfile ?? player
  }

  override var childForStatusBarHidden: UIViewController? {
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
    mainHost.addSubview(tabBar)
    tabBar.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      tabBar.leadingAnchor.constraint(equalTo: mainHost.leadingAnchor, constant: 12),
      tabBar.trailingAnchor.constraint(equalTo: mainHost.trailingAnchor, constant: -12),
      tabBar.bottomAnchor.constraint(equalTo: mainHost.bottomAnchor, constant: -24),
      tabBar.heightAnchor.constraint(equalToConstant: 72),
    ])

    settingsButton.setImage(UIImage(systemName: "gearshape.fill"), for: .normal)
    settingsButton.tintColor = NativeTheme.foreground
    settingsButton.backgroundColor = NativeTheme.glass
    settingsButton.layer.cornerRadius = 20
    settingsButton.layer.shadowColor = UIColor.black.cgColor
    settingsButton.layer.shadowOpacity = 0.16
    settingsButton.layer.shadowRadius = 12
    settingsButton.layer.shadowOffset = CGSize(width: 0, height: 4)
    settingsButton.addTarget(self, action: #selector(openSettings), for: .touchUpInside)
    mainHost.addSubview(settingsButton)
    settingsButton.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      settingsButton.trailingAnchor.constraint(equalTo: mainHost.trailingAnchor, constant: -16),
      settingsButton.topAnchor.constraint(equalTo: mainHost.safeAreaLayoutGuide.topAnchor, constant: 6),
      settingsButton.widthAnchor.constraint(equalToConstant: 40),
      settingsButton.heightAnchor.constraint(equalToConstant: 40),
    ])

    myButton.setImage(UIImage(systemName: "person.crop.circle"), for: .normal)
    myButton.tintColor = NativeTheme.foreground
    myButton.backgroundColor = NativeTheme.glass
    myButton.layer.cornerRadius = 20
    myButton.layer.shadowColor = UIColor.black.cgColor
    myButton.layer.shadowOpacity = 0.16
    myButton.layer.shadowRadius = 12
    myButton.layer.shadowOffset = CGSize(width: 0, height: 4)
    myButton.addTarget(self, action: #selector(openMy), for: .touchUpInside)
    mainHost.addSubview(myButton)
    myButton.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      myButton.leadingAnchor.constraint(equalTo: mainHost.leadingAnchor, constant: 16),
      myButton.topAnchor.constraint(equalTo: mainHost.safeAreaLayoutGuide.topAnchor, constant: 6),
      myButton.widthAnchor.constraint(equalToConstant: 40),
      myButton.heightAnchor.constraint(equalToConstant: 40),
    ])

    // The original home has no top buttons; My and settings live in the
    // left navigation drawer. Keep these views for compatibility only.
    settingsButton.isHidden = true
    myButton.isHidden = true

    let edge = UIScreenEdgePanGestureRecognizer(
      target: self, action: #selector(handleSidebarEdge(_:)))
    edge.edges = .left
    edge.delegate = self
    view.addGestureRecognizer(edge)
    sidebarEdgePan = edge

    let closePan = UIPanGestureRecognizer(
      target: self, action: #selector(handleSidebarCloseDrag(_:)))
    closePan.delegate = self
    closePan.cancelsTouchesInView = true
    view.addGestureRecognizer(closePan)
    sidebarClosePan = closePan

    selectTab(0, force: true)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    ThemeManager.shared.apply()
    guard !testFlowTriggered else { return }
    testFlowTriggered = true
    let flow = ProcessInfo.processInfo.environment["O11A1_TEST_FLOW"] ?? ""
    switch flow {
    case "player", "player-detail", "player-comments", "player-settings", "player-related",
         "player-landscape", "player-controls", "player-panel", "player-up", "player-danmaku",
         "player-stage-comments":
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
      self?.openSidebar()
    }
    controller.onSidebarPanBegan = { [weak self] in
      guard let self = self, self.sidebar?.superview == nil else { return }
      self.prepareSidebarForDrag()
    }
    controller.onSidebarPanChanged = { [weak self] progress in
      guard let self = self, self.sidebar?.superview != nil else { return }
      self.setSidebarProgress(progress)
    }
    controller.onSidebarPanEnded = { [weak self] translation, velocity in
      guard let self = self, self.sidebar?.superview != nil else { return }
      let width = max(1, self.view.bounds.width)
      if translation > width * 0.22 || velocity > 350 {
        self.finishSidebarOpen()
      } else {
        self.finishSidebarClose()
      }
      self.feed?.resumePreview()
    }
    controller.onToolbar = { [weak self] hidden in
      guard let self = self else { return }
      self.tabBar.setHidden(hidden, animated: true)
      UIView.animate(withDuration: 0.35) {
        self.settingsButton.alpha = hidden ? 0 : 1
        self.myButton.alpha = hidden ? 0 : 1
      }
    }
    if let module = HomeModules.currentDef, module.source != "recommend" {
      controller.initialSource = (module.source, module.name)
    } else if HomeModules.enabledCount == 0 {
      controller.initialSource = ("none", "主页模块")
    }
    feed = controller
    return controller
  }

  private func selectTab(_ index: Int, force: Bool = false) {
    closeMessages()
    tabBar.select(index: index, notify: false)
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
    showChild(controller)
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
    mainHost.bringSubviewToFront(tabBar)
    mainHost.bringSubviewToFront(settingsButton)
    mainHost.bringSubviewToFront(myButton)
  }

  private func openPlayer(_ item: VideoItem, from source: UIView?) {
    if let existing = player {
      existing.play(item)
      view.bringSubviewToFront(existing.view)
      if upProfile != nil {
        profileCoveredByPlayer = true
        setNeedsStatusBarAppearanceUpdate()
      }
      return
    }
    guard player == nil else { return }
    feed?.suspendPreview()
    let sourceView = (source as? HomeCardCell)?.mediaHost ?? source
    let controller = PlayerViewController(item: item, sourceView: sourceView)
    controller.onClose = { [weak self] in
      self?.closePlayer()
    }
    controller.onProfile = { [weak self] mid in
      self?.openProfile(mid)
    }
    addChild(controller)
    controller.view.frame = view.bounds
    controller.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.addSubview(controller.view)
    controller.didMove(toParent: self)
    player = controller
    tabBar.isHidden = true
    settingsButton.isHidden = true
    myButton.isHidden = true
    if upProfile != nil {
      profileCoveredByPlayer = true
    }
    controller.start()
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
        case "player-controls": controller?.testShowControls(hold: true)
        case "player-panel": controller?.testShowControls(hold: true)
        case "player-up": controller?.testOpenProfile()
        case "player-danmaku": controller?.testOpenDanmakuSettings()
        case "player-stage-comments": controller?.testCommentsStage()
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

  private func closePlayer() {
    guard let controller = player else { return }
    controller.willMove(toParent: nil)
    controller.view.removeFromSuperview()
    controller.removeFromParent()
    player = nil
    profileCoveredByPlayer = false
    endOrientationTracking()
    tabBar.isHidden = false
    setPlayerOrientation(false)
    setNeedsStatusBarAppearanceUpdate()
    feed?.resumePreview()
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
    return true
  }

  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
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
    mainHost.bringSubviewToFront(settingsButton)
    mainHost.bringSubviewToFront(myButton)
  }

  private func closeMessages() {
    guard let controller = messages else { return }
    controller.willMove(toParent: nil)
    controller.view.removeFromSuperview()
    controller.removeFromParent()
    messages = nil
  }

  @objc private func openMy() {
    let my = MyViewController()
    my.modalPresentationStyle = .overFullScreen
    my.onFish = { [weak self, weak my] in
      my?.dismiss(animated: false) { self?.selectTab(3) }
    }
    my.onSettings = { [weak self, weak my] in
      my?.dismiss(animated: false) { self?.openSettings() }
    }
    my.onOpenModule = { [weak self, weak my] mode, target, title in
      guard let self = self, let host = my else { return }
      self.presentModule(from: host, mode: mode, target: target, title: title)
    }
    my.onHomeModule = { [weak self] source, title in
      self?.feed?.setSource(source, title: title)
    }
    present(my, animated: false)
    my.view.transform = CGAffineTransform(translationX: -view.bounds.width, y: 0)
    UIView.animate(withDuration: 0.24, delay: 0, options: [.curveEaseOut]) {
      my.view.transform = .identity
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
