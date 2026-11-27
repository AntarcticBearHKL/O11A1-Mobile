import UIKit

final class MyViewController: UIViewController, UIGestureRecognizerDelegate {
  var onOpenModule: ((ModuleListViewController.Mode, Int64, String) -> Void)?
  var onFish: (() -> Void)?
  var onSettings: (() -> Void)?

  private let scroll = UIScrollView()
  private let list = UIStackView()
  private let avatar = UIImageView()
  private let nameLabel = UILabel()
  private let metaLabel = UILabel()
  private let accountButton = UIButton(type: .system)
  private var account = AccountInfo()
  private var mid: Int64 = 0
  private var closing = false

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = NativeTheme.background

    let dismissPan = UIPanGestureRecognizer(
      target: self, action: #selector(handleDismissPan(_:)))
    dismissPan.delegate = self
    dismissPan.cancelsTouchesInView = false
    view.addGestureRecognizer(dismissPan)

    let accountCard = UIView()
    accountCard.backgroundColor = .clear
    accountCard.layer.cornerRadius = NativeTheme.cornerRadius
    accountCard.layer.cornerCurve = .continuous
    accountCard.clipsToBounds = false
    accountCard.layer.shadowColor = UIColor.black.cgColor
    accountCard.layer.shadowOpacity = 0.12
    accountCard.layer.shadowRadius = 18
    accountCard.layer.shadowOffset = CGSize(width: 0, height: 8)
    view.addSubview(accountCard)
    accountCard.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      accountCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
      accountCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
      accountCard.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                       constant: 8),
      accountCard.heightAnchor.constraint(equalToConstant: 104),
    ])

    let heroBackground = ProfileHeroBackground()
    accountCard.addSubview(heroBackground)
    heroBackground.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      heroBackground.leadingAnchor.constraint(equalTo: accountCard.leadingAnchor),
      heroBackground.trailingAnchor.constraint(equalTo: accountCard.trailingAnchor),
      heroBackground.topAnchor.constraint(equalTo: accountCard.topAnchor),
      heroBackground.bottomAnchor.constraint(equalTo: accountCard.bottomAnchor),
    ])

    let avatarRing = ProfileAvatarRing()
    avatarRing.isUserInteractionEnabled = false
    accountCard.addSubview(avatarRing)
    avatarRing.translatesAutoresizingMaskIntoConstraints = false

    avatar.contentMode = .scaleAspectFill
    avatar.clipsToBounds = true
    avatar.layer.cornerRadius = 27
    avatar.backgroundColor = UIColor(white: 0.9, alpha: 1)
    accountCard.addSubview(avatar)
    avatar.translatesAutoresizingMaskIntoConstraints = false

    nameLabel.font = UIFont.systemFont(ofSize: 17, weight: .bold)
    nameLabel.textColor = NativeTheme.foreground
    nameLabel.numberOfLines = 1
    nameLabel.lineBreakMode = .byTruncatingTail
    nameLabel.translatesAutoresizingMaskIntoConstraints = false
    metaLabel.font = NativeTheme.bodyFont(10.5)
    metaLabel.textColor = NativeTheme.secondary
    metaLabel.numberOfLines = 1
    metaLabel.lineBreakMode = .byTruncatingTail
    metaLabel.translatesAutoresizingMaskIntoConstraints = false

    let identity = UIStackView(arrangedSubviews: [nameLabel, metaLabel])
    identity.axis = .vertical
    identity.alignment = .fill
    identity.spacing = 3
    accountCard.addSubview(identity)
    identity.translatesAutoresizingMaskIntoConstraints = false

    accountButton.titleLabel?.font = UIFont.systemFont(ofSize: 11.5, weight: .bold)
    accountButton.setTitleColor(NativeTheme.navBlue, for: .normal)
    accountButton.layer.cornerRadius = NativeTheme.cornerRadius
    accountButton.layer.cornerCurve = .continuous
    accountButton.layer.borderWidth = 1
    accountButton.layer.borderColor = NativeTheme.hairline.cgColor
    accountButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
    accountButton.addTarget(self, action: #selector(accountTapped), for: .touchUpInside)
    accountCard.addSubview(accountButton)
    accountButton.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      avatarRing.leadingAnchor.constraint(equalTo: accountCard.leadingAnchor, constant: 16),
      avatarRing.centerYAnchor.constraint(equalTo: accountCard.centerYAnchor),
      avatarRing.widthAnchor.constraint(equalToConstant: 60),
      avatarRing.heightAnchor.constraint(equalToConstant: 60),
      avatar.centerXAnchor.constraint(equalTo: avatarRing.centerXAnchor),
      avatar.centerYAnchor.constraint(equalTo: avatarRing.centerYAnchor),
      avatar.widthAnchor.constraint(equalToConstant: 54),
      avatar.heightAnchor.constraint(equalToConstant: 54),
      identity.leadingAnchor.constraint(equalTo: avatarRing.trailingAnchor, constant: 12),
      identity.trailingAnchor.constraint(equalTo: accountButton.leadingAnchor, constant: -8),
      identity.centerYAnchor.constraint(equalTo: accountCard.centerYAnchor),
      accountButton.trailingAnchor.constraint(equalTo: accountCard.trailingAnchor, constant: -16),
      accountButton.centerYAnchor.constraint(equalTo: accountCard.centerYAnchor),
      accountButton.heightAnchor.constraint(equalToConstant: 34),
    ])

    view.addSubview(scroll)
    scroll.addSubview(list)
    scroll.translatesAutoresizingMaskIntoConstraints = false
    list.translatesAutoresizingMaskIntoConstraints = false
    list.axis = .vertical
    list.alignment = .fill
    list.spacing = 0
    NSLayoutConstraint.activate([
      scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scroll.topAnchor.constraint(equalTo: accountCard.bottomAnchor, constant: 8),
      scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      list.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 18),
      list.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -18),
      list.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
      list.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
      list.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -36),
    ])

    addRow("首页布局", "单列大卡 / 双列瀑布", #selector(showFeedLayout))
    addRow("播放", "默认画质 / 当前画质", #selector(showPlayback))
    addRow("弹幕", "显示 / 字号 / 速度 / 屏蔽", #selector(showDanmaku))
    addRow("外观", "主题 / 透明度 / 模糊", #selector(showAppearance))
    addRow("屏蔽", "关键词 / 正则 / 用户", #selector(showBlock))
    addRow("智能云屏蔽", "等级 / 同步", #selector(showCloud))
    addRow("优化", "预加载 / 性能", #selector(showOptimize))
    if let last = list.arrangedSubviews.last {
      last.removeFromSuperview()
    }

    if ProfileCache.loadAccount() == nil {
      nameLabel.text = "加载中…"
      metaLabel.text = "正在读取账号"
      accountButton.setTitle("账户", for: .normal)
      avatar.image = UIImage(systemName: "person.crop.circle.fill")
    }
    applyCachedAccount()
    loadAccount()
  }

  private func addRow(_ label: String, _ detail: String, _ action: Selector) {
    let row = UIButton(type: .custom)
    row.addTarget(self, action: action, for: .touchUpInside)
    row.heightAnchor.constraint(equalToConstant: 58).isActive = true

    let title = UILabel()
    title.text = label
    title.font = NativeTheme.bodyFont(15)
    title.textColor = NativeTheme.foreground
    row.addSubview(title)
    title.translatesAutoresizingMaskIntoConstraints = false

    let hint = UILabel()
    hint.text = detail
    hint.font = NativeTheme.bodyFont(11)
    hint.textColor = NativeTheme.tertiary
    hint.textAlignment = .right
    row.addSubview(hint)
    hint.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      title.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 2),
      title.centerYAnchor.constraint(equalTo: row.centerYAnchor),
      hint.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -2),
      hint.centerYAnchor.constraint(equalTo: row.centerYAnchor),
      hint.leadingAnchor.constraint(greaterThanOrEqualTo: title.trailingAnchor, constant: 8),
    ])
    list.addArrangedSubview(row)

    let lineWrap = UIView()
    let line = UIView()
    line.backgroundColor = NativeTheme.hairline
    lineWrap.addSubview(line)
    line.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      line.leadingAnchor.constraint(equalTo: lineWrap.leadingAnchor),
      line.trailingAnchor.constraint(equalTo: lineWrap.trailingAnchor),
      line.topAnchor.constraint(equalTo: lineWrap.topAnchor),
      line.bottomAnchor.constraint(equalTo: lineWrap.bottomAnchor),
      line.heightAnchor.constraint(equalToConstant: 0.5),
    ])
    list.addArrangedSubview(lineWrap)
  }

  @objc private func handleDismissPan(_ gesture: UIPanGestureRecognizer) {
    let reference = view.superview ?? view
    let width = max(1, view.bounds.width)
    let translation = min(0, gesture.translation(in: reference).x)
    switch gesture.state {
    case .changed:
      view.transform = CGAffineTransform(translationX: translation, y: 0)
    case .ended, .cancelled:
      let velocity = gesture.velocity(in: reference).x
      if translation < -width * 0.22 || velocity < -350 {
        close()
      } else {
        UIView.animate(withDuration: 0.24, delay: 0,
                       options: [.curveEaseOut, .beginFromCurrentState]) {
          self.view.transform = .identity
        }
      }
    default:
      break
    }
  }

  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
    let velocity = pan.velocity(in: view)
    let translation = pan.translation(in: view)
    let movingLeft = translation.x < -1 || velocity.x < -1
    return movingLeft && (abs(translation.x) > abs(translation.y) * 1.1
      || abs(velocity.x) > abs(velocity.y) * 1.1)
  }

  @objc private func close() {
    guard !closing else { return }
    closing = true
    UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseIn]) {
      self.view.transform = CGAffineTransform(translationX: -self.view.bounds.width, y: 0)
    } completion: { _ in
      self.dismiss(animated: false)
    }
  }

  @objc private func accountTapped() {
    if account.loggedIn {
      let vip = account.vip ? "大会员" : "未开通"
      let alert = UIAlertController(
        title: "账户",
        message: "昵称  \(account.name)\nUID  \(account.mid)\n等级  Lv\(account.level)\n大会员  \(vip)",
        preferredStyle: .actionSheet)
      alert.addAction(UIAlertAction(title: "退出登录", style: .destructive) { [weak self] _ in
        BiliAPI.shared.logout()
        ProfileCache.clearAccount()
        self?.showAccount(AccountInfo())
        self?.loadAccount()
      })
      alert.addAction(UIAlertAction(title: "取消", style: .cancel))
      if let popover = alert.popoverPresentationController {
        popover.sourceView = accountButton
        popover.sourceRect = accountButton.bounds
      }
      present(alert, animated: true)
    } else {
      let login = LoginViewController()
      login.modalPresentationStyle = .formSheet
      login.onLogin = { [weak self] in self?.loadAccount() }
      present(login, animated: true)
    }
  }

  @objc private func showFeedLayout() {
    let options = ["单列大卡", "双列瀑布"]
    let selected = HomeFeedLayout.isGrid ? options[1] : options[0]
    var rows: [SettingsSheetRow] = []
    rows.append(.choices(label: "布局", options: options, selected: selected) { value in
      HomeFeedLayout.isGrid = (value == options[1])
      NotificationCenter.default.post(name: HomeFeedLayout.changed, object: nil)
    })
    rows.append(.note("双列瀑布每行显示两个视频卡，标题和信息的字号会自动缩小。"))
    presentSheet(SettingsSheetViewController(
      title: "首页布局", subtitle: "选择主页信息流的排列方式", rows: rows))
  }

  @objc private func showPlayback() {
    let defaults = UserDefaults.standard
    let options = ["最高", "4K", "1080P60", "1080P+", "1080P", "720P60", "720P", "480P", "360P"]
    var rows: [SettingsSheetRow] = []
    rows.append(.gridChoices(label: "默认画质", options: options,
                             selected: defaultQualityName()) {
      [weak self] name in
      defaults.set(name, forKey: "o11a1.defaultQuality")
      if let self = self {
        ThemeManager.shared.quality = self.qualityValue(name)
      }
    })
    rows.append(.gridChoices(label: "当前画质", options: options,
                             selected: qualityName(ThemeManager.shared.quality)) {
      [weak self] name in
      guard let self = self else { return }
      ThemeManager.shared.quality = self.qualityValue(name)
    })
    presentSheet(SettingsSheetViewController(
      title: "播放",
      subtitle: "默认画质用于新播放，当前画质立即应用；高画质需大会员",
      rows: rows))
  }

  @objc private func showDanmaku() {
    let defaults = UserDefaults.standard
    var rows: [SettingsSheetRow] = []
    rows.append(.toggle(label: "弹幕显示", detail: nil,
                        isOn: storedBool("danmaku_enabled", true)) { value in
      defaults.set(value, forKey: "danmaku_enabled")
    })
    rows.append(.slider(label: "不透明度", min: 0, max: 100,
                        value: storedFloat("danmaku_opacity", 88),
                        unit: "%", step: 1, format: nil) { value in
      defaults.set(value, forKey: "danmaku_opacity")
    })
    rows.append(.slider(label: "字号", min: 50, max: 150,
                        value: storedFloat("danmaku_size", 100),
                        unit: "%", step: 1, format: nil) { value in
      defaults.set(value, forKey: "danmaku_size")
    })
    rows.append(.slider(label: "速度", min: 50, max: 200,
                        value: storedFloat("danmaku_speed", 100),
                        unit: "", step: 1, format: { String(format: "%.1f×", Double($0) / 100.0) }) { value in
      defaults.set(value, forKey: "danmaku_speed")
    })
    rows.append(.slider(label: "显示区域", min: DanmakuSettings.areaMinimum,
                        max: DanmakuSettings.areaMaximum,
                        value: DanmakuSettings.areaPercent(),
                        unit: "%", step: DanmakuSettings.areaStep,
                        format: nil) { value in
      DanmakuSettings.setAreaPercent(value)
    })
    rows.append(.toggle(label: "分布密度", detail: nil,
                        isOn: storedBool("danmaku_density", true)) { value in
      defaults.set(value, forKey: "danmaku_density")
    })
    presentSheet(SettingsSheetViewController(
      title: "弹幕",
      subtitle: "实时生效，现有弹幕不清空；屏蔽规则在「我的 → 屏蔽」",
      rows: rows))
  }

  @objc private func showAppearance() {
    var rows: [SettingsSheetRow] = []
    rows.append(.choices(label: "主题", options: AppTheme.allCases.map { $0.title },
                         selected: ThemeManager.shared.theme.title) { value in
      if let theme = AppTheme.allCases.first(where: { $0.title == value }) {
        ThemeManager.shared.theme = theme
      }
    })
    rows.append(.slider(label: "玻璃模糊", min: 0, max: 100,
                        value: storedFloat("o11a1.glassBlur", 100),
                        unit: "%", step: 1, format: nil) { value in
      UserDefaults.standard.set(value, forKey: "o11a1.glassBlur")
    })
    rows.append(.value(label: "圆角", value: "18 / 24 / 27"))
    presentSheet(SettingsSheetViewController(
      title: "外观",
      subtitle: "浅色为纯白，深色为纯黑；玻璃模糊控制悬浮层质感",
      rows: rows))
  }

  @objc private func showBlock() {
    let keywords = UserDefaults.standard.stringArray(forKey: "o11a1.block.keywords") ?? []
    var rows: [SettingsSheetRow] = []
    rows.append(.value(label: "关键词",
                       value: keywords.isEmpty ? "未设置" : keywords.joined(separator: "、")))
    rows.append(.value(label: "正则", value: "无"))
    rows.append(.value(label: "用户", value: "未设置"))
    rows.append(.action(label: "添加规则", value: "", run: { [weak self] in
      self?.addBlockRule()
    }))
    rows.append(.action(label: "清空规则", value: "", run: { [weak self] in
      UserDefaults.standard.removeObject(forKey: "o11a1.block.keywords")
      self?.showSheetInfo("屏蔽", "已清空本机关键词规则。")
    }))
    presentSheet(SettingsSheetViewController(
      title: "屏蔽", subtitle: "关键词 / 正则 / 用户；弹幕与评论共用规则", rows: rows))
  }

  @objc private func showCloud() {
    let defaults = UserDefaults.standard
    var rows: [SettingsSheetRow] = []
    rows.append(.toggle(label: "智能云屏蔽", detail: nil,
                        isOn: storedBool("o11a1.cloudBlock", true)) { value in
      defaults.set(value, forKey: "o11a1.cloudBlock")
    })
    rows.append(.slider(label: "AI 等级", min: 0, max: 10,
                        value: storedFloat("o11a1.cloudLevel", 5),
                        unit: "", step: 1, format: nil) { value in
      defaults.set(value, forKey: "o11a1.cloudLevel")
    })
    rows.append(.action(label: "立即同步", value: "", run: { [weak self] in
      self?.showSheetInfo("智能云屏蔽", "已保存本地设置。")
    }))
    presentSheet(SettingsSheetViewController(
      title: "智能云屏蔽", subtitle: "服务端同步的 AI 屏蔽等级", rows: rows))
  }

  @objc private func showOptimize() {
    let defaults = UserDefaults.standard
    var rows: [SettingsSheetRow] = []
    rows.append(.toggle(label: "后台预加载", detail: nil,
                        isOn: storedBool("o11a1.preloadNext", true)) { value in
      defaults.set(value, forKey: "o11a1.preloadNext")
    })
    rows.append(.toggle(label: "缓存下一批推荐", detail: nil,
                        isOn: storedBool("o11a1.warmPages", true)) { value in
      defaults.set(value, forKey: "o11a1.warmPages")
    })
    rows.append(.value(label: "硬件解码", value: "强制开启"))
    rows.append(.value(label: "插帧管线", value: "原生媒体层"))
    presentSheet(SettingsSheetViewController(
      title: "优化", subtitle: "预加载与页面预热；硬件解码在移动端强制开启", rows: rows))
  }

  private func presentSheet(_ sheet: SettingsSheetViewController) {
    present(sheet, animated: false)
  }

  private func qualityName(_ qn: Int) -> String {
    switch qn {
    case 120: return "4K"
    case 116: return "1080P60"
    case 112: return "1080P+"
    case 80: return "1080P"
    case 74: return "720P60"
    case 64: return "720P"
    case 32: return "480P"
    case 16: return "360P"
    default: return "1080P"
    }
  }

  private func qualityValue(_ name: String) -> Int {
    switch name {
    case "4K": return 120
    case "1080P60": return 116
    case "1080P+": return 112
    case "1080P": return 80
    case "720P60": return 74
    case "720P": return 64
    case "480P": return 32
    case "360P": return 16
    default: return 80
    }
  }

  private func defaultQualityName() -> String {
    if let saved = UserDefaults.standard.string(forKey: "o11a1.defaultQuality"),
       !saved.isEmpty {
      return saved
    }
    return qualityName(ThemeManager.shared.quality)
  }

  private func storedFloat(_ key: String, _ fallback: Float) -> Float {
    let defaults = UserDefaults.standard
    if defaults.object(forKey: key) == nil { return fallback }
    return defaults.float(forKey: key)
  }

  private func storedBool(_ key: String, _ fallback: Bool) -> Bool {
    let defaults = UserDefaults.standard
    if defaults.object(forKey: key) == nil { return fallback }
    return defaults.bool(forKey: key)
  }

  private func addBlockRule() {
    guard let host = presentedViewController else { return }
    let alert = UIAlertController(title: "添加屏蔽关键词", message: nil, preferredStyle: .alert)
    alert.addTextField { field in
      field.placeholder = "关键词或正则"
      field.clearButtonMode = .whileEditing
    }
    alert.addAction(UIAlertAction(title: "取消", style: .cancel))
    alert.addAction(UIAlertAction(title: "添加", style: .default) { [weak alert] _ in
      let text = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      guard !text.isEmpty else { return }
      var list = UserDefaults.standard.stringArray(forKey: "o11a1.block.keywords") ?? []
      if !list.contains(text) { list.append(text) }
      UserDefaults.standard.set(list, forKey: "o11a1.block.keywords")
    })
    host.present(alert, animated: true)
  }

  private func showSheetInfo(_ title: String, _ message: String) {
    guard let host = presentedViewController else { return }
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "好", style: .default))
    host.present(alert, animated: true)
  }

  private func applyCachedAccount() {
    guard let cached = ProfileCache.loadAccount() else { return }
    var info = AccountInfo()
    info.loggedIn = cached.loggedIn
    info.name = cached.name
    info.face = cached.face
    info.mid = cached.mid
    info.level = cached.level
    info.vip = cached.vip
    info.sign = cached.sign
    showAccount(info)
  }

  private func showAccount(_ info: AccountInfo) {
    account = info
    mid = info.mid
    nameLabel.text = info.loggedIn ? (info.name.isEmpty ? "已登录" : info.name) : "未登录"
    metaLabel.text = info.loggedIn
      ? "UID \(info.mid) · Lv\(info.level)\(info.vip ? " · 大会员" : "")"
      : "登录 B 站账号"
    accountButton.setTitle(info.loggedIn ? (info.vip ? "大会员" : "账户") : "登录",
                            for: .normal)
    accountButton.backgroundColor = info.vip ? NativeTheme.navSoft : .clear
    accountButton.layer.borderColor = info.vip
      ? NativeTheme.navBlue.withAlphaComponent(0.35).cgColor
      : NativeTheme.hairline.cgColor
    if info.loggedIn, !info.face.isEmpty {
      ImageLoader.shared.load(info.face, into: avatar)
    } else {
      avatar.image = UIImage(systemName: "person.crop.circle.fill")
    }
  }

  private func loadAccount() {
    BiliAPI.shared.account { [weak self] info in
      guard let self = self else { return }
      let cached = CachedAccount(
        loggedIn: info.loggedIn,
        name: info.name,
        face: info.face,
        mid: info.mid,
        level: info.level,
        vip: info.vip,
        sign: info.sign,
        updatedAt: Date().timeIntervalSince1970
      )
      ProfileCache.saveAccount(cached)
      self.showAccount(info)
    }
  }
}
