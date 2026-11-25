import UIKit

final class RootViewController: UIViewController {
  private let contentView = UIView()
  private let tabBar = GlassTabBar()
  private let settingsButton = UIButton(type: .system)
  private var currentChild: UIViewController?
  private var player: PlayerViewController?
  private var feed: FeedViewController?
  private var following: VideoListViewController?
  private var dynamic: VideoListViewController?
  private var fish: FishViewController?

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return traitCollection.userInterfaceStyle == .dark ? .lightContent : .darkContent
  }

  override var prefersHomeIndicatorAutoHidden: Bool { true }

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
    view.addSubview(tabBar)
    tabBar.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      tabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
      tabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
      tabBar.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -NativeTheme.toolbarInset),
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

    selectTab(0, force: true)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    ThemeManager.shared.apply()
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
    controller.onToolbar = { [weak self] hidden in
      guard let self = self else { return }
      self.tabBar.setHidden(hidden, animated: true)
      UIView.animate(withDuration: 0.35) {
        self.settingsButton.alpha = hidden ? 0 : 1
      }
    }
    feed = controller
    return controller
  }

  private func selectTab(_ index: Int, force: Bool = false) {
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
        let list = VideoListViewController(mode: .dynamic, title: "动态")
        list.onOpen = { [weak self] item, cell in self?.openPlayer(item, from: cell) }
        dynamic = list
      }
      controller = dynamic!
    default:
      if fish == nil { fish = FishViewController() }
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
    controller.start()
  }

  private func closePlayer() {
    guard let controller = player else { return }
    controller.willMove(toParent: nil)
    controller.view.removeFromSuperview()
    controller.removeFromParent()
    player = nil
    tabBar.isHidden = false
    settingsButton.isHidden = false
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

  @objc private func openSettings() {
    let settings = SettingsViewController()
    let nav = UINavigationController(rootViewController: settings)
    nav.modalPresentationStyle = .pageSheet
    present(nav, animated: true)
  }
}
