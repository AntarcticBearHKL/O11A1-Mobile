import UIKit

final class MyViewController: UIViewController {
  var onOpenModule: ((ModuleListViewController.Mode, Int64, String) -> Void)?
  var onFish: (() -> Void)?
  var onSettings: (() -> Void)?

  private let avatar = UIImageView()
  private let nameLabel = UILabel()
  private let metaLabel = UILabel()
  private let accountButton = UIButton(type: .system)
  private var account = AccountInfo()
  private var mid: Int64 = 0

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = NativeTheme.background

    let scroll = UIScrollView()
    view.addSubview(scroll)
    let root = UIStackView()
    root.axis = .vertical
    root.spacing = 14
    root.alignment = .fill
    scroll.addSubview(root)
    [scroll, root].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
    NSLayoutConstraint.activate([
      scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scroll.topAnchor.constraint(equalTo: view.topAnchor),
      scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      root.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 20),
      root.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -20),
      root.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 58),
      root.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -24),
      root.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -40),
    ])

    let top = UIStackView()
    top.axis = .horizontal
    top.alignment = .center
    top.spacing = 6
    let back = UIButton(type: .system)
    back.setImage(UIImage(systemName: "chevron.left"), for: .normal)
    back.tintColor = NativeTheme.foreground
    back.addTarget(self, action: #selector(close), for: .touchUpInside)
    back.widthAnchor.constraint(equalToConstant: 40).isActive = true
    back.heightAnchor.constraint(equalToConstant: 40).isActive = true
    let title = UILabel()
    title.text = "我的"
    title.font = NativeTheme.titleFont(24)
    title.textColor = NativeTheme.foreground
    top.addArrangedSubview(back)
    top.addArrangedSubview(title)
    top.addArrangedSubview(UIView())
    root.addArrangedSubview(top)

    let accountRow = UIStackView()
    accountRow.axis = .horizontal
    accountRow.alignment = .center
    accountRow.spacing = 12
    avatar.contentMode = .scaleAspectFill
    avatar.clipsToBounds = true
    avatar.layer.cornerRadius = 29
    avatar.backgroundColor = UIColor(white: 0.12, alpha: 1)
    avatar.widthAnchor.constraint(equalToConstant: 58).isActive = true
    avatar.heightAnchor.constraint(equalToConstant: 58).isActive = true
    accountRow.addArrangedSubview(avatar)

    let names = UIStackView()
    names.axis = .vertical
    names.spacing = 4
    nameLabel.font = NativeTheme.titleFont(17)
    nameLabel.textColor = NativeTheme.foreground
    metaLabel.font = NativeTheme.bodyFont(12)
    metaLabel.textColor = NativeTheme.secondary
    names.addArrangedSubview(nameLabel)
    names.addArrangedSubview(metaLabel)
    accountRow.addArrangedSubview(names)
    accountRow.addArrangedSubview(UIView())
    accountButton.titleLabel?.font = NativeTheme.titleFont(13)
    accountButton.setTitleColor(NativeTheme.accent, for: .normal)
    accountButton.addTarget(self, action: #selector(accountTapped), for: .touchUpInside)
    accountRow.addArrangedSubview(accountButton)
    root.addArrangedSubview(accountRow)

    let entries: [(String, () -> Void)] = [
      ("热门", { [weak self] in self?.open(.hot, 0, "热门") }),
      ("排行", { [weak self] in self?.open(.rank, 0, "排行") }),
      ("番剧", { [weak self] in self?.open(.bangumi, 0, "番剧") }),
      ("影视", { [weak self] in self?.open(.movie, 0, "影视") }),
      ("直播", { [weak self] in self?.open(.live, 0, "直播") }),
      ("分区", { [weak self] in self?.open(.zone, 0, "分区") }),
      ("收藏", { [weak self] in self?.open(.favorites, 0, "收藏") }),
      ("历史", { [weak self] in self?.open(.history, 0, "历史") }),
      ("关注", { [weak self] in self?.open(.following, 0, "关注") }),
      ("动态", { [weak self] in self?.open(.dynamic, 0, "动态") }),
      ("消息", { [weak self] in self?.open(.messages, 0, "消息") }),
      ("养鱼", { [weak self] in self?.onFish?() }),
      ("设置", { [weak self] in self?.onSettings?() }),
      ("我的主页", { [weak self] in
        guard let self = self, self.mid > 0 else { return }
        self.open(.space, self.mid, "我的主页")
      }),
    ]
    var index = 0
    while index < entries.count {
      let row = UIStackView()
      row.axis = .horizontal
      row.spacing = 10
      row.distribution = .fillEqually
      for _ in 0..<2 {
        guard index < entries.count else {
          row.addArrangedSubview(UIView())
          continue
        }
        let entry = entries[index]
        index += 1
        let button = UIButton(type: .system)
        button.setTitle(entry.0, for: .normal)
        button.setTitleColor(NativeTheme.foreground, for: .normal)
        button.titleLabel?.font = NativeTheme.titleFont(15)
        button.backgroundColor = NativeTheme.foreground.withAlphaComponent(0.05)
        button.layer.cornerRadius = 16
        button.layer.cornerCurve = .continuous
        button.heightAnchor.constraint(equalToConstant: 54).isActive = true
        button.addAction(UIAction { _ in entry.1() }, for: .touchUpInside)
        row.addArrangedSubview(button)
      }
      root.addArrangedSubview(row)
    }

    loadAccount()
  }

  private func loadAccount() {
    BiliAPI.shared.account { [weak self] info in
      guard let self = self else { return }
      self.account = info
      self.mid = info.mid
      self.nameLabel.text = info.loggedIn ? (info.name.isEmpty ? "已登录" : info.name) : "未登录"
      self.metaLabel.text = info.loggedIn
        ? "UID \(info.mid) · Lv\(info.level)\(info.vip ? " · 大会员" : "")"
        : "登录后同步关注、收藏、历史"
      self.accountButton.setTitle(info.loggedIn ? "退出登录" : "扫码登录", for: .normal)
      if info.loggedIn, !info.face.isEmpty {
        ImageLoader.shared.load(info.face, into: self.avatar)
      } else {
        self.avatar.image = UIImage(systemName: "person.crop.circle.fill")
      }
    }
  }

  @objc private func accountTapped() {
    if account.loggedIn {
      BiliAPI.shared.logout()
      loadAccount()
    } else {
      showLogin()
    }
  }

  private func showLogin() {
    let login = LoginViewController()
    login.modalPresentationStyle = .formSheet
    login.onLogin = { [weak self] in self?.loadAccount() }
    present(login, animated: true)
  }

  private func open(_ mode: ModuleListViewController.Mode, _ target: Int64, _ title: String) {
    onOpenModule?(mode, target, title)
  }

  @objc private func close() {
    dismiss(animated: true)
  }
}
