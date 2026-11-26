import UIKit

final class MemberCenterViewController: UIViewController {
  private let scroll = UIScrollView()
  private let root = UIStackView()
  private let status = UILabel()
  private let vipCard = UIView()
  private var loaded = false

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = NativeTheme.background

    let header = UIStackView()
    header.axis = .horizontal
    header.alignment = .center
    header.spacing = 8
    let title = UILabel()
    title.text = "会员中心"
    title.font = NativeTheme.titleFont(24)
    title.textColor = NativeTheme.foreground
    header.addArrangedSubview(title)
    header.addArrangedSubview(UIView())
    let close = UIButton(type: .system)
    close.setImage(UIImage(systemName: "xmark"), for: .normal)
    close.tintColor = NativeTheme.secondary
    close.widthAnchor.constraint(equalToConstant: 40).isActive = true
    close.heightAnchor.constraint(equalToConstant: 40).isActive = true
    close.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
    header.addArrangedSubview(close)

    view.addSubview(header)
    view.addSubview(scroll)
    scroll.addSubview(root)
    view.addSubview(status)
    [header, scroll, root, status].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

    root.axis = .vertical
    root.alignment = .fill
    root.spacing = 14

    NSLayoutConstraint.activate([
      header.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      header.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),

      scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scroll.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 10),
      scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      root.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 20),
      root.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -20),
      root.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 6),
      root.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -28),
      root.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -40),

      status.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      status.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      status.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
      status.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32),
    ])

    status.font = NativeTheme.bodyFont(13)
    status.textColor = NativeTheme.secondary
    status.textAlignment = .center
    status.numberOfLines = 0
    status.text = "正在加载会员信息…"
    status.isHidden = false

    load()
  }

  @objc private func closeTapped() {
    dismiss(animated: true)
  }

  private func load() {
    status.text = "正在加载会员信息…"
    status.isHidden = false
    BiliAPI.shared.memberCenter { [weak self] result in
      guard let self = self else { return }
      switch result {
      case .failure(let error):
        self.status.text = error.localizedDescription
        self.status.isHidden = false
        self.root.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if error.localizedDescription.contains("登录") {
          let login = UIButton(type: .system)
          login.setTitle("扫码登录", for: .normal)
          login.setTitleColor(.white, for: .normal)
          login.titleLabel?.font = NativeTheme.titleFont(15)
          login.backgroundColor = NativeTheme.accent
          login.layer.cornerRadius = 16
          login.layer.cornerCurve = .continuous
          login.heightAnchor.constraint(equalToConstant: 48).isActive = true
          login.addAction(UIAction { [weak self] _ in self?.showLogin() }, for: .touchUpInside)
          self.root.addArrangedSubview(login)
        }
      case .success(let info):
        self.status.isHidden = true
        self.render(info)
      }
    }
  }

  private func showLogin() {
    let login = LoginViewController()
    login.modalPresentationStyle = .formSheet
    login.onLogin = { [weak self] in self?.load() }
    present(login, animated: true)
  }

  private func render(_ info: MemberInfo) {
    root.arrangedSubviews.forEach { $0.removeFromSuperview() }

    let card = UIView()
    card.backgroundColor = NativeTheme.foreground.withAlphaComponent(0.05)
    card.layer.cornerRadius = 16
    card.layer.cornerCurve = .continuous
    let cardStack = UIStackView()
    cardStack.axis = .vertical
    cardStack.spacing = 4
    cardStack.translatesAutoresizingMaskIntoConstraints = false
    card.addSubview(cardStack)
    NSLayoutConstraint.activate([
      cardStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
      cardStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
      cardStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
      cardStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
    ])

    let vipTitle = UILabel()
    vipTitle.text = info.vip ? "大会员" : "普通用户"
    vipTitle.font = NativeTheme.titleFont(22)
    vipTitle.textColor = info.vip ? NativeTheme.warmOrange : NativeTheme.foreground
    cardStack.addArrangedSubview(vipTitle)

    let vipMeta = UILabel()
    if info.vip {
      let type = info.vipType == 2 ? "年度大会员" : (info.vipType == 1 ? "月度大会员" : "大会员")
      vipMeta.text = type + " · 有效期至 " + formatDate(info.vipDue)
    } else {
      vipMeta.text = "完成每日任务可积累经验，开通大会员享高清画质。"
    }
    vipMeta.font = NativeTheme.bodyFont(12)
    vipMeta.textColor = NativeTheme.secondary
    vipMeta.numberOfLines = 0
    cardStack.addArrangedSubview(vipMeta)
    root.addArrangedSubview(card)

    if !info.tasks.isEmpty {
      root.addArrangedSubview(sectionTitle("每日经验"))
      let tasksCard = cardView(info.tasks.map { task in
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 10
        let label = UILabel()
        label.text = task.label
        label.font = NativeTheme.bodyFont(14)
        label.textColor = NativeTheme.foreground
        row.addArrangedSubview(label)
        row.addArrangedSubview(UIView())
        let detail = UILabel()
        detail.text = task.detail.isEmpty ? "+\(task.reward) 经验" : task.detail
        detail.font = NativeTheme.bodyFont(11)
        detail.textColor = NativeTheme.secondary
        row.addArrangedSubview(detail)
        let check = UIImageView(image: UIImage(systemName: task.done ? "checkmark.circle.fill" : "circle"))
        check.tintColor = task.done ? UIColor.systemGreen : NativeTheme.tertiary
        check.widthAnchor.constraint(equalToConstant: 20).isActive = true
        check.heightAnchor.constraint(equalToConstant: 20).isActive = true
        row.addArrangedSubview(check)
        return row
      })
      root.addArrangedSubview(tasksCard)
    }

    if !info.log.isEmpty {
      root.addArrangedSubview(sectionTitle("最近经验"))
      let logCard = cardView(info.log.map { entry in
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 10
        let delta = UILabel()
        delta.text = (entry.delta > 0 ? "+" : "") + "\(entry.delta) 经验"
        delta.font = NativeTheme.numberFont(12)
        delta.textColor = entry.delta >= 0 ? UIColor.systemGreen : NativeTheme.secondary
        delta.widthAnchor.constraint(equalToConstant: 70).isActive = true
        row.addArrangedSubview(delta)
        let reason = UILabel()
        reason.text = entry.reason
        reason.font = NativeTheme.bodyFont(12)
        reason.textColor = NativeTheme.foreground
        reason.numberOfLines = 1
        row.addArrangedSubview(reason)
        row.addArrangedSubview(UIView())
        let time = UILabel()
        time.text = entry.time
        time.font = NativeTheme.numberFont(10)
        time.textColor = NativeTheme.tertiary
        row.addArrangedSubview(time)
        return row
      })
      root.addArrangedSubview(logCard)
    }
  }

  private func sectionTitle(_ text: String) -> UILabel {
    let label = UILabel()
    label.text = text
    label.font = NativeTheme.titleFont(15)
    label.textColor = NativeTheme.foreground
    return label
  }

  private func cardView(_ rows: [UIView]) -> UIView {
    let card = UIView()
    card.backgroundColor = NativeTheme.foreground.withAlphaComponent(0.05)
    card.layer.cornerRadius = 16
    card.layer.cornerCurve = .continuous
    let stack = UIStackView(arrangedSubviews: rows)
    stack.axis = .vertical
    stack.spacing = 12
    stack.translatesAutoresizingMaskIntoConstraints = false
    card.addSubview(stack)
    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
      stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
      stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
    ])
    return card
  }

  private func formatDate(_ seconds: Int64) -> String {
    guard seconds > 0 else { return "—" }
    let date = Date(timeIntervalSince1970: TimeInterval(seconds))
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
  }
}
