import UIKit

final class MyViewController: UIViewController {
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

    let header = UIStackView()
    header.axis = .horizontal
    header.alignment = .center
    header.spacing = 4
    let back = UIButton(type: .system)
    back.setImage(UIImage(systemName: "chevron.left"), for: .normal)
    back.tintColor = NativeTheme.foreground
    back.addTarget(self, action: #selector(close), for: .touchUpInside)
    back.widthAnchor.constraint(equalToConstant: 44).isActive = true
    back.heightAnchor.constraint(equalToConstant: 44).isActive = true
    header.addArrangedSubview(back)
    let title = UILabel()
    title.text = "用户"
    title.font = NativeTheme.titleFont(20)
    title.textColor = NativeTheme.foreground
    header.addArrangedSubview(title)
    header.addArrangedSubview(UIView())
    view.addSubview(header)
    header.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      header.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
      header.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
    ])

    let accountCard = UIView()
    accountCard.backgroundColor = NativeTheme.background
    view.addSubview(accountCard)
    accountCard.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      accountCard.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      accountCard.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      accountCard.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      accountCard.heightAnchor.constraint(equalToConstant: 92),
    ])
    let topLine = UIView()
    topLine.backgroundColor = NativeTheme.hairline
    accountCard.addSubview(topLine)
    topLine.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      topLine.leadingAnchor.constraint(equalTo: accountCard.leadingAnchor),
      topLine.trailingAnchor.constraint(equalTo: accountCard.trailingAnchor),
      topLine.topAnchor.constraint(equalTo: accountCard.topAnchor),
      topLine.heightAnchor.constraint(equalToConstant: 0.5),
    ])

    avatar.contentMode = .scaleAspectFill
    avatar.clipsToBounds = true
    avatar.layer.cornerRadius = 25
    avatar.backgroundColor = UIColor(white: 0.9, alpha: 1)
    accountCard.addSubview(avatar)
    avatar.translatesAutoresizingMaskIntoConstraints = false

    nameLabel.font = NativeTheme.titleFont(16)
    nameLabel.textColor = NativeTheme.foreground
    accountCard.addSubview(nameLabel)
    nameLabel.translatesAutoresizingMaskIntoConstraints = false
    metaLabel.font = NativeTheme.bodyFont(11)
    metaLabel.textColor = NativeTheme.secondary
    accountCard.addSubview(metaLabel)
    metaLabel.translatesAutoresizingMaskIntoConstraints = false

    accountButton.titleLabel?.font = NativeTheme.titleFont(13)
    accountButton.setTitleColor(NativeTheme.navBlue, for: .normal)
    accountButton.addTarget(self, action: #selector(accountTapped), for: .touchUpInside)
    accountCard.addSubview(accountButton)
    accountButton.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      avatar.leadingAnchor.constraint(equalTo: accountCard.leadingAnchor, constant: 18),
      avatar.topAnchor.constraint(equalTo: accountCard.topAnchor, constant: 13),
      avatar.widthAnchor.constraint(equalToConstant: 50),
      avatar.heightAnchor.constraint(equalToConstant: 50),
      nameLabel.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 12),
      nameLabel.topAnchor.constraint(equalTo: avatar.topAnchor),
      nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: accountButton.leadingAnchor, constant: -8),
      metaLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
      metaLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 3),
      metaLabel.trailingAnchor.constraint(lessThanOrEqualTo: accountButton.leadingAnchor, constant: -8),
      accountButton.trailingAnchor.constraint(equalTo: accountCard.trailingAnchor, constant: -18),
      accountButton.centerYAnchor.constraint(equalTo: accountCard.centerYAnchor),
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
      scroll.topAnchor.constraint(equalTo: header.bottomAnchor),
      scroll.bottomAnchor.constraint(equalTo: accountCard.topAnchor),
      list.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
      list.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
      list.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
      list.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
      list.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor),
    ])

    addRow("主页模块", "自定义首页内容", #selector(showHomeModules))
    addRow("内容模块", "热门 / 排行 / 番剧 / 直播…", #selector(showContentModules))
    addRow("播放", "画质 / 默认清晰度", #selector(openSettings))
    addRow("弹幕", "显示 / 字号 / 速度 / 屏蔽", #selector(showDanmaku))
    addRow("外观", "主题 / 透明度 / 模糊", #selector(openSettings))
    addRow("屏蔽", "关键词 / 正则 / 用户", #selector(showBlock))
    addRow("智能云屏蔽", "等级 / 同步", #selector(showCloud))
    addRow("优化", "预加载 / 性能", #selector(showOptimize))
    addRow("会员中心", "任务 / 经验 / 大会员", #selector(openMember))
    addRow("养鱼", "AI 看片 / 试验台", #selector(openFish))

    loadAccount()
  }

  private func addRow(_ label: String, _ detail: String, _ action: Selector) {
    let row = UIButton(type: .custom)
    row.addTarget(self, action: action, for: .touchUpInside)
    row.heightAnchor.constraint(equalToConstant: 56).isActive = true

    let title = UILabel()
    title.text = label
    title.font = NativeTheme.bodyFont(15)
    title.textColor = NativeTheme.foreground
    row.addSubview(title)
    title.translatesAutoresizingMaskIntoConstraints = false

    let hint = UILabel()
    hint.text = detail
    hint.font = NativeTheme.bodyFont(11)
    hint.textColor = NativeTheme.secondary
    hint.textAlignment = .right
    row.addSubview(hint)
    hint.translatesAutoresizingMaskIntoConstraints = false

    let chevron = UILabel()
    chevron.text = "›"
    chevron.font = NativeTheme.bodyFont(20)
    chevron.textColor = NativeTheme.tertiary
    row.addSubview(chevron)
    chevron.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      title.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 18),
      title.centerYAnchor.constraint(equalTo: row.centerYAnchor),
      hint.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -8),
      hint.centerYAnchor.constraint(equalTo: row.centerYAnchor),
      hint.leadingAnchor.constraint(greaterThanOrEqualTo: title.trailingAnchor, constant: 8),
      chevron.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
      chevron.centerYAnchor.constraint(equalTo: row.centerYAnchor),
    ])
    list.addArrangedSubview(row)

    let line = UIView()
    line.backgroundColor = NativeTheme.hairline
    line.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
    line.widthAnchor.constraint(equalTo: list.widthAnchor, constant: -18).isActive = true
    line.leadingAnchor.constraint(equalTo: list.leadingAnchor, constant: 18).isActive = true
    list.addArrangedSubview(line)
  }

  @objc private func close() {
    guard !closing else { return }
    closing = true
    UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseIn], animations: {
      self.view.transform = CGAffineTransform(translationX: -self.view.bounds.width, y: 0)
    }) { _ in
      self.dismiss(animated: false)
    }
  }

  @objc private func accountTapped() {
    if account.loggedIn {
      BiliAPI.shared.logout()
      loadAccount()
    } else {
      let login = LoginViewController()
      login.modalPresentationStyle = .formSheet
      login.onLogin = { [weak self] in self?.loadAccount() }
      present(login, animated: true)
    }
  }

  @objc private func openSettings() {
    onSettings?()
  }

  @objc private func openFish() {
    onFish?()
  }

  @objc private func openMember() {
    let member = MemberCenterViewController()
    member.modalPresentationStyle = .pageSheet
    present(member, animated: true)
  }

  @objc private func showHomeModules() {
    let alert = UIAlertController(
      title: "主页模块",
      message: "首页模块选择会保存在本机；当前首页固定展示推荐。",
      preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "好", style: .default))
    present(alert, animated: true)
  }

  @objc private func showContentModules() {
    let alert = UIAlertController(title: "内容模块", message: nil, preferredStyle: .actionSheet)
    let entries: [(String, ModuleListViewController.Mode)] = [
      ("热门", .hot), ("排行", .rank), ("番剧", .bangumi), ("影视", .movie),
      ("直播", .live), ("分区", .zone), ("收藏", .favorites), ("历史", .history),
      ("关注", .following), ("动态", .dynamic), ("消息", .messages),
    ]
    for (title, mode) in entries {
      alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
        self?.onOpenModule?(mode, 0, title)
      })
    }
    alert.addAction(UIAlertAction(title: "我的主页", style: .default) { [weak self] _ in
      guard let self = self, self.mid > 0 else { return }
      self.onOpenModule?(.space, self.mid, "我的主页")
    })
    alert.addAction(UIAlertAction(title: "取消", style: .cancel))
    if let popover = alert.popoverPresentationController {
      popover.sourceView = view
      popover.sourceRect = view.bounds
    }
    present(alert, animated: true)
  }

  @objc private func showDanmaku() {
    let alert = UIAlertController(title: "弹幕", message: "默认显示弹幕", preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "开启", style: .default) { _ in
      UserDefaults.standard.set(true, forKey: "danmaku_enabled")
    })
    alert.addAction(UIAlertAction(title: "关闭", style: .default) { _ in
      UserDefaults.standard.set(false, forKey: "danmaku_enabled")
    })
    present(alert, animated: true)
  }

  @objc private func showBlock() {
    presentInfo("屏蔽", "关键词、正则和用户屏蔽保存在本机；与网页端使用同一套规则。")
  }

  @objc private func showCloud() {
    presentInfo("智能云屏蔽", "云屏蔽等级跟随 B 站账号；当前使用默认等级。")
  }

  @objc private func showOptimize() {
    presentInfo("优化", "预加载下一段推荐并保留最近两段内容；可在播放设置中调整清晰度。")
  }

  private func presentInfo(_ title: String, _ message: String) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "好", style: .default))
    present(alert, animated: true)
  }

  private func loadAccount() {
    BiliAPI.shared.account { [weak self] info in
      guard let self = self else { return }
      self.account = info
      self.mid = info.mid
      self.nameLabel.text = info.loggedIn ? (info.name.isEmpty ? "已登录" : info.name) : "未登录"
      self.metaLabel.text = info.loggedIn
        ? "UID \(info.mid) · Lv\(info.level)\(info.vip ? " · 大会员" : "")"
        : "登录 B 站账号"
      self.accountButton.setTitle(info.loggedIn ? "退出" : "登录", for: .normal)
      if info.loggedIn, !info.face.isEmpty {
        ImageLoader.shared.load(info.face, into: self.avatar)
      } else {
        self.avatar.image = UIImage(systemName: "person.crop.circle.fill")
      }
    }
  }
}
