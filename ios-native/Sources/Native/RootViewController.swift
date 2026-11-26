import UIKit

final class RootViewController: UIViewController {
  private let contentView = UIView()
  private let tabBar = GlassTabBar()
  private let settingsButton = UIButton(type: .system)
  private let myButton = UIButton(type: .system)
  private var currentChild: UIViewController?
  private var player: PlayerViewController?
  private var feed: FeedViewController?
  private var following: VideoListViewController?
  private var dynamic: DynamicViewController?
  private var messages: MessagesViewController?
  private var fish: AIViewController?
  private var sidebar: SidebarView?
  private var testFlowTriggered = false

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return traitCollection.userInterfaceStyle == .dark ? .lightContent : .darkContent
  }

  override var prefersHomeIndicatorAutoHidden: Bool { true }

  override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    return player == nil ? .portrait : .landscape
  }

  override var prefersStatusBarHidden: Bool {
    return player != nil
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

    contentView.backgroundColor = NativeTheme.background
    view.addSubview(contentView)
    contentView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      contentView.topAnchor.constraint(equalTo: view.topAnchor),
      contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    tabBar.onSelect = { [weak self] index in
      self?.selectTab(index)
    }
    tabBar.onReselect = { [weak self] in
      self?.closeMessages()
    }
    view.addSubview(tabBar)
    tabBar.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      tabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
      tabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
      tabBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
      tabBar.heightAnchor.constraint(equalToConstant: 58),
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
    view.addSubview(settingsButton)
    settingsButton.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      settingsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      settingsButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
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
    view.addSubview(myButton)
    myButton.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      myButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      myButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
      myButton.widthAnchor.constraint(equalToConstant: 40),
      myButton.heightAnchor.constraint(equalToConstant: 40),
    ])

    // The original home has no top buttons; My and settings live in the
    // left navigation drawer. Keep these views for compatibility only.
    settingsButton.isHidden = true
    myButton.isHidden = true

    selectTab(0, force: true)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    ThemeManager.shared.apply()
    guard !testFlowTriggered else { return }
    testFlowTriggered = true
    let flow = ProcessInfo.processInfo.environment["O11A1_TEST_FLOW"] ?? ""
    switch flow {
    case "player":
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
    controller.onSidebar = { [weak self] in
      self?.openSidebar()
    }
    controller.onToolbar = { [weak self] hidden in
      guard let self = self else { return }
      self.tabBar.setHidden(hidden, animated: true)
      UIView.animate(withDuration: 0.35) {
        self.settingsButton.alpha = hidden ? 0 : 1
        self.myButton.alpha = hidden ? 0 : 1
      }
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
    view.bringSubviewToFront(tabBar)
    view.bringSubviewToFront(settingsButton)
    view.bringSubviewToFront(myButton)
  }

  private func openPlayer(_ item: VideoItem, from source: UIView?) {
    guard player == nil else { return }
    feed?.suspendPreview()
    let controller = PlayerViewController(item: item, sourceView: source)
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
    controller.start()
    setPlayerOrientation(true)
    setNeedsStatusBarAppearanceUpdate()
  }

  private func closePlayer() {
    guard let controller = player else { return }
    controller.willMove(toParent: nil)
    controller.view.removeFromSuperview()
    controller.removeFromParent()
    player = nil
    tabBar.isHidden = false
    setPlayerOrientation(false)
    setNeedsStatusBarAppearanceUpdate()
    feed?.resumePreview()
  }

  private func openProfile(_ mid: Int64) {
    guard mid > 0 else { return }
    let list = VideoListViewController(mode: .space(mid: mid), title: "UP 主页")
    let nav = UINavigationController(rootViewController: list)
    nav.navigationBar.prefersLargeTitles = false
    nav.navigationBar.tintColor = NativeTheme.accent
    list.onOpen = { [weak nav] item, cell in
      guard let nav = nav else { return }
      let player = PlayerViewController(item: item, sourceView: cell)
      player.onClose = { [weak player] in
        player?.dismiss(animated: false)
      }
      nav.present(player, animated: false)
    }
    present(nav, animated: true)
  }

  private func openSidebar() {
    if sidebar == nil {
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
      sidebar = view
    }
    sidebar?.present(in: view)
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
    view.bringSubviewToFront(tabBar)
    view.bringSubviewToFront(settingsButton)
    view.bringSubviewToFront(myButton)
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
