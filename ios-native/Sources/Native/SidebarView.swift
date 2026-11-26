import UIKit

final class SidebarView: UIView {
  var onHome: (() -> Void)?
  var onModule: ((ModuleListViewController.Mode, String) -> Void)?
  var onMy: (() -> Void)?
  var onSearch: (() -> Void)?

  private let panel = UIView()
  private let backdrop = UIView()
  private var panelWidth: CGFloat = 200

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
    isHidden = true

    backdrop.backgroundColor = UIColor.black.withAlphaComponent(0.35)
    backdrop.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(close)))
    addSubview(backdrop)
    backdrop.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      backdrop.leadingAnchor.constraint(equalTo: leadingAnchor),
      backdrop.trailingAnchor.constraint(equalTo: trailingAnchor),
      backdrop.topAnchor.constraint(equalTo: topAnchor),
      backdrop.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])

    panel.backgroundColor = .clear
    addSubview(panel)
    panel.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      panel.leadingAnchor.constraint(equalTo: leadingAnchor),
      panel.topAnchor.constraint(equalTo: topAnchor),
      panel.bottomAnchor.constraint(equalTo: bottomAnchor),
      panel.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.50),
    ])

    let bg = UIView()
    bg.backgroundColor = UIColor { trait in
      trait.userInterfaceStyle == .dark
        ? UIColor(white: 0.06, alpha: 0.97)
        : UIColor(white: 0.99, alpha: 0.97)
    }
    bg.layer.cornerRadius = 26
    bg.layer.cornerCurve = .continuous
    bg.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
    bg.layer.shadowColor = UIColor.black.cgColor
    bg.layer.shadowOpacity = 0.18
    bg.layer.shadowRadius = 22
    bg.layer.shadowOffset = CGSize(width: 12, height: 0)
    panel.addSubview(bg)
    bg.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      bg.leadingAnchor.constraint(equalTo: panel.leadingAnchor),
      bg.trailingAnchor.constraint(equalTo: panel.trailingAnchor),
      bg.topAnchor.constraint(equalTo: panel.topAnchor),
      bg.bottomAnchor.constraint(equalTo: panel.bottomAnchor),
    ])

    let stack = UIStackView()
    stack.axis = .vertical
    stack.alignment = .fill
    stack.spacing = 0
    panel.addSubview(stack)
    stack.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 8),
      stack.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -12),
      stack.centerYAnchor.constraint(equalTo: panel.centerYAnchor),
    ])

    addRow(stack, "首页", "house", { [weak self] in self?.onHome?() })
    addRow(stack, "收藏", "star", { [weak self] in self?.onModule?(.favorites, "收藏") })
    addRow(stack, "直播", "dot.radiowaves.left.and.right",
           { [weak self] in self?.onModule?(.live, "直播") })
    addRow(stack, "番剧", "play.rectangle",
           { [weak self] in self?.onModule?(.bangumi, "番剧") })
    addRow(stack, "关注", "person.badge.plus",
           { [weak self] in self?.onModule?(.following, "关注") })
    addRow(stack, "动态", "waveform",
           { [weak self] in self?.onModule?(.dynamic, "动态") })
    addRow(stack, "消息", "envelope",
           { [weak self] in self?.onModule?(.messages, "消息") })
    addRow(stack, "历史", "clock.arrow.circlepath",
           { [weak self] in self?.onModule?(.history, "历史") })
    addRow(stack, "搜索", "magnifyingglass", { [weak self] in self?.onSearch?() })

    let footerLine = UIView()
    footerLine.backgroundColor = NativeTheme.hairline
    panel.addSubview(footerLine)
    footerLine.translatesAutoresizingMaskIntoConstraints = false

    let footer = UIStackView()
    footer.axis = .vertical
    footer.alignment = .fill
    panel.addSubview(footer)
    footer.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      footer.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 8),
      footer.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -12),
      footer.bottomAnchor.constraint(equalTo: panel.safeAreaLayoutGuide.bottomAnchor, constant: -8),
      footerLine.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 26),
      footerLine.trailingAnchor.constraint(equalTo: panel.trailingAnchor),
      footerLine.bottomAnchor.constraint(equalTo: footer.topAnchor, constant: -2),
      footerLine.heightAnchor.constraint(equalToConstant: 0.5),
    ])
    addRow(footer, "我的", "person", { [weak self] in self?.onMy?() })
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func addRow(_ stack: UIStackView, _ label: String, _ symbol: String,
                      _ action: (() -> Void)?) {
    let row = UIButton(type: .custom)
    row.tag = 0
    row.addAction(UIAction { [weak self] _ in
      self?.close()
      action?()
    }, for: .touchUpInside)
    row.heightAnchor.constraint(equalToConstant: 54).isActive = true

    let icon = UIImageView(image: UIImage(systemName: symbol))
    icon.tintColor = NativeTheme.secondary
    icon.contentMode = .scaleAspectFit
    icon.widthAnchor.constraint(equalToConstant: 19).isActive = true
    icon.heightAnchor.constraint(equalToConstant: 19).isActive = true

    let text = UILabel()
    text.text = label
    text.font = NativeTheme.titleFont(14)
    text.textColor = NativeTheme.foreground

    let content = UIStackView(arrangedSubviews: [icon, text])
    content.axis = .horizontal
    content.alignment = .center
    content.spacing = 10
    content.isUserInteractionEnabled = false
    row.addSubview(content)
    content.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      content.centerXAnchor.constraint(equalTo: row.centerXAnchor),
      content.centerYAnchor.constraint(equalTo: row.centerYAnchor),
    ])
    stack.addArrangedSubview(row)
  }

  func present(in host: UIView) {
    guard superview == nil else { return }
    frame = host.bounds
    autoresizingMask = [.flexibleWidth, .flexibleHeight]
    host.addSubview(self)
    isHidden = false
    layoutIfNeeded()
    panel.transform = CGAffineTransform(translationX: -panel.bounds.width, y: 0)
    backdrop.alpha = 0
    UIView.animate(withDuration: 0.28, delay: 0, options: [.curveEaseOut]) {
      self.panel.transform = .identity
      self.backdrop.alpha = 1
    }
  }

  @objc func close() {
    guard superview != nil else { return }
    UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseIn], animations: {
      self.panel.transform = CGAffineTransform(translationX: -self.panel.bounds.width, y: 0)
      self.backdrop.alpha = 0
    }) { _ in
      self.removeFromSuperview()
      self.panel.transform = .identity
    }
  }
}
