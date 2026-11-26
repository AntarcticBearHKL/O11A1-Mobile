import UIKit

final class SidebarView: UIView {
  var onHome: (() -> Void)?
  var onModule: ((ModuleListViewController.Mode, String) -> Void)?
  var onMy: (() -> Void)?
  var onSearch: (() -> Void)?
  var onClose: (() -> Void)?

  private let panel = UIView()
  private let backdrop = UIView()
  private let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
  private let gradient = CAGradientLayer()
  private var panelWidth: CGFloat = 200

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
    isHidden = true

    backdrop.backgroundColor = UIColor { trait in
      UIColor.black.withAlphaComponent(trait.userInterfaceStyle == .dark ? 0.34 : 0.16)
    }
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
    bg.layer.cornerRadius = 26
    bg.layer.cornerCurve = .continuous
    bg.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
    bg.layer.borderWidth = 1
    bg.layer.borderColor = UIColor { trait in
      trait.userInterfaceStyle == .dark
        ? UIColor(white: 1, alpha: 0.08)
        : UIColor(white: 1, alpha: 0.58)
    }.cgColor
    bg.layer.shadowColor = UIColor.black.cgColor
    bg.layer.shadowOpacity = 0.18
    bg.layer.shadowRadius = 22
    bg.layer.shadowOffset = CGSize(width: 12, height: 0)
    bg.clipsToBounds = false
    panel.addSubview(bg)
    bg.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      bg.leadingAnchor.constraint(equalTo: panel.leadingAnchor),
      bg.trailingAnchor.constraint(equalTo: panel.trailingAnchor),
      bg.topAnchor.constraint(equalTo: panel.topAnchor),
      bg.bottomAnchor.constraint(equalTo: panel.bottomAnchor),
    ])

    blur.layer.cornerRadius = 26
    blur.layer.cornerCurve = .continuous
    blur.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
    blur.clipsToBounds = true
    bg.addSubview(blur)
    blur.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      blur.leadingAnchor.constraint(equalTo: bg.leadingAnchor),
      blur.trailingAnchor.constraint(equalTo: bg.trailingAnchor),
      blur.topAnchor.constraint(equalTo: bg.topAnchor),
      blur.bottomAnchor.constraint(equalTo: bg.bottomAnchor),
    ])

    gradient.colors = [NativeTheme.sidebarTop.cgColor, NativeTheme.sidebarBottom.cgColor]
    gradient.startPoint = CGPoint(x: 0.5, y: 0)
    gradient.endPoint = CGPoint(x: 0.5, y: 1)
    blur.contentView.layer.addSublayer(gradient)

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

    addRow(stack, "直播", "play.rectangle",
           { [weak self] in self?.onModule?(.live, "直播") })
    addRow(stack, "番剧", "rectangle.split.3x1",
           { [weak self] in self?.onModule?(.bangumi, "番剧") })
    addRow(stack, "消息", "text.bubble",
           { [weak self] in self?.onModule?(.messages, "消息") })
    addRow(stack, "历史", "clock.arrow.circlepath",
           { [weak self] in self?.onModule?(.history, "历史") })

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
      footerLine.bottomAnchor.constraint(equalTo: footer.topAnchor, constant: -10),
      footerLine.heightAnchor.constraint(equalToConstant: 0.5),
    ])
    addRow(footer, "用户", "person", { [weak self] in self?.onMy?() })
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    gradient.frame = panel.bounds
    CATransaction.commit()
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    gradient.colors = [NativeTheme.sidebarTop.cgColor, NativeTheme.sidebarBottom.cgColor]
    panel.subviews.first?.layer.borderColor = UIColor { trait in
      trait.userInterfaceStyle == .dark
        ? UIColor(white: 1, alpha: 0.08)
        : UIColor(white: 1, alpha: 0.58)
    }.cgColor
  }

  private func addRow(_ stack: UIStackView, _ label: String, _ symbol: String,
                      _ action: (() -> Void)?) {
    let row = UIButton(type: .custom)
    row.addAction(UIAction { [weak self] _ in
      self?.close()
      action?()
    }, for: .touchUpInside)
    row.heightAnchor.constraint(equalToConstant: 56).isActive = true

    let icon = UIImageView(image: UIImage(
      systemName: symbol,
      withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .regular)))
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

  func prepare(in host: UIView) {
    guard superview == nil else { return }
    frame = host.bounds
    autoresizingMask = [.flexibleWidth, .flexibleHeight]
    host.addSubview(self)
    isHidden = false
    layoutIfNeeded()
    setProgress(0)
  }

  func setProgress(_ value: CGFloat) {
    let progress = max(0, min(1, value))
    let offset = -panel.bounds.width - 24
    panel.transform = CGAffineTransform(translationX: offset * (1 - progress), y: 0)
    backdrop.alpha = progress
  }

  func animateOpen() {
    UIView.animate(withDuration: 0.36, delay: 0,
                   usingSpringWithDamping: 1, initialSpringVelocity: 0,
                   options: [.curveEaseOut]) {
      self.setProgress(1)
    }
  }

  func present(in host: UIView) {
    guard superview == nil else { return }
    prepare(in: host)
    animateOpen()
  }

  @objc func close() {
    guard superview != nil else { return }
    onClose?()
    UIView.animate(withDuration: 0.26, delay: 0, options: [.curveEaseIn], animations: {
      self.panel.transform = CGAffineTransform(
        translationX: -self.panel.bounds.width - 24, y: 0)
      self.backdrop.alpha = 0
    }) { _ in
      self.removeFromSuperview()
      self.panel.transform = .identity
    }
  }
}
