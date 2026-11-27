import UIKit

final class GlassTabBar: UIView {
  var onSelect: ((Int) -> Void)?
  var onReselect: (() -> Void)?
  var onMenu: ((Int) -> Void)?

  private let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
  private let tint = UIView()
  private let pill = UIView()
  private let stack = UIStackView()
  private let menuClip = UIView()
  private let menuStack = UIStackView()
  private let rowLine = UIView()
  private var buttons: [UIButton] = []
  private var menuButtons: [UIButton] = []
  private let titles = ["推荐", "关注", "动态", "养鱼"]
  private let symbols = ["house", "person.badge.plus", "waveform", "fish"]
  private let menuTitles = ["直播", "番剧", "消息", "历史"]
  private let menuSymbols = ["play.rectangle", "rectangle.split.3x1",
                             "text.bubble", "clock.arrow.circlepath"]
  private(set) var selectedIndex = 0
  private(set) var barHidden = false
  private let selectionFeedback = UISelectionFeedbackGenerator()
  private let barRadius: CGFloat = NativeTheme.cornerRadius
  private var pillAnimating = false
  private let rowHeight: CGFloat = 72
  private let menuRowHeight: CGFloat = 56
  private var barHeight: NSLayoutConstraint?
  private var menuHeight: NSLayoutConstraint?
  private var expansion: CGFloat = 0
  private var dragStartExpansion: CGFloat = 0

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
    layer.cornerRadius = barRadius
    layer.cornerCurve = .continuous
    layer.borderWidth = 1
    layer.borderColor = NativeTheme.barBorder.cgColor
    layer.shadowColor = UIColor.black.cgColor
    layer.shadowOpacity = 0.12
    layer.shadowRadius = 18
    layer.shadowOffset = CGSize(width: 0, height: 8)
    barHeight = heightAnchor.constraint(equalToConstant: rowHeight)
    barHeight?.isActive = true

    blur.layer.cornerRadius = barRadius
    blur.layer.cornerCurve = .continuous
    blur.clipsToBounds = true
    addSubview(blur)
    blur.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      blur.leadingAnchor.constraint(equalTo: leadingAnchor),
      blur.trailingAnchor.constraint(equalTo: trailingAnchor),
      blur.topAnchor.constraint(equalTo: topAnchor),
      blur.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])

    tint.backgroundColor = NativeTheme.barGlass
    tint.layer.cornerRadius = barRadius
    tint.layer.cornerCurve = .continuous
    tint.clipsToBounds = true
    tint.isUserInteractionEnabled = false
    addSubview(tint)
    tint.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      tint.leadingAnchor.constraint(equalTo: leadingAnchor),
      tint.trailingAnchor.constraint(equalTo: trailingAnchor),
      tint.topAnchor.constraint(equalTo: topAnchor),
      tint.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])

    pill.backgroundColor = NativeTheme.navPill
    pill.layer.cornerRadius = barRadius
    pill.layer.cornerCurve = .continuous
    pill.isUserInteractionEnabled = false
    addSubview(pill)

    stack.axis = .horizontal
    stack.distribution = .fillEqually
    stack.alignment = .fill
    stack.spacing = 0
    addSubview(stack)
    stack.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: leadingAnchor),
      stack.trailingAnchor.constraint(equalTo: trailingAnchor),
      stack.bottomAnchor.constraint(equalTo: bottomAnchor),
      stack.heightAnchor.constraint(equalToConstant: rowHeight),
    ])

    menuClip.clipsToBounds = true
    addSubview(menuClip)
    menuClip.translatesAutoresizingMaskIntoConstraints = false
    menuHeight = menuClip.heightAnchor.constraint(equalToConstant: 0)
    NSLayoutConstraint.activate([
      menuClip.leadingAnchor.constraint(equalTo: leadingAnchor),
      menuClip.trailingAnchor.constraint(equalTo: trailingAnchor),
      menuClip.bottomAnchor.constraint(equalTo: stack.topAnchor),
      menuHeight!,
    ])

    menuStack.axis = .horizontal
    menuStack.distribution = .fillEqually
    menuStack.alignment = .fill
    menuStack.spacing = 0
    menuClip.addSubview(menuStack)
    menuStack.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      menuStack.leadingAnchor.constraint(equalTo: menuClip.leadingAnchor),
      menuStack.trailingAnchor.constraint(equalTo: menuClip.trailingAnchor),
      menuStack.topAnchor.constraint(equalTo: menuClip.topAnchor),
      menuStack.heightAnchor.constraint(equalToConstant: menuRowHeight),
    ])

    rowLine.backgroundColor = NativeTheme.hairline
    rowLine.alpha = 0
    addSubview(rowLine)
    rowLine.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      rowLine.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
      rowLine.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
      rowLine.bottomAnchor.constraint(equalTo: stack.topAnchor),
      rowLine.heightAnchor.constraint(equalToConstant: 0.5),
    ])

    for index in 0..<titles.count {
      let button = UIButton(type: .custom)
      button.tag = index
      button.titleLabel?.font = UIFont.systemFont(ofSize: 10, weight: .medium)
      button.setTitleColor(NativeTheme.tertiary, for: .normal)
      let config = UIImage.SymbolConfiguration(pointSize: 19, weight: .regular)
      button.setImage(UIImage(systemName: symbols[index], withConfiguration: config), for: .normal)
      button.tintColor = NativeTheme.tertiary
      button.setTitle(titles[index], for: .normal)
      button.alignImageAndTitleVertically(gap: 2)
      button.addTarget(self, action: #selector(tap(_:)), for: .touchUpInside)
      buttons.append(button)
      stack.addArrangedSubview(button)
    }

    for index in 0..<menuTitles.count {
      let button = UIButton(type: .custom)
      button.tag = index
      button.titleLabel?.font = UIFont.systemFont(ofSize: 10, weight: .medium)
      button.setTitleColor(NativeTheme.tabInactive, for: .normal)
      let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
      button.setImage(UIImage(systemName: menuSymbols[index], withConfiguration: config),
                      for: .normal)
      button.tintColor = NativeTheme.tabInactive
      button.setTitle(menuTitles[index], for: .normal)
      button.alignImageAndTitleVertically(gap: 2)
      button.addTarget(self, action: #selector(menuTap(_:)), for: .touchUpInside)
      menuButtons.append(button)
      menuStack.addArrangedSubview(button)
    }

    let expandPan = UIPanGestureRecognizer(target: self, action: #selector(handleExpandPan(_:)))
    expandPan.cancelsTouchesInView = false
    addGestureRecognizer(expandPan)

    selectionFeedback.prepare()
    select(index: 0, notify: false)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    stack.layoutIfNeeded()
    guard !pillAnimating else { return }
    updateColors()
    layoutPill(animated: false)
  }

  private func layoutPill(animated: Bool) {
    guard selectedIndex >= 0 && selectedIndex < buttons.count else { return }
    let button = buttons[selectedIndex]
    let target = button.convert(button.bounds, to: self)
    if animated {
      pillAnimating = true
      pill.layer.removeAllAnimations()
      UIView.animate(withDuration: 0.42, delay: 0,
                     usingSpringWithDamping: 0.68,
                     initialSpringVelocity: 0.65,
                     options: [.allowUserInteraction, .beginFromCurrentState]) {
        self.pill.frame = target
      } completion: { _ in
        self.pillAnimating = false
        self.pill.frame = target
      }
    } else {
      pill.frame = target
    }
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    layer.borderColor = NativeTheme.barBorder.cgColor
    tint.backgroundColor = NativeTheme.barGlass
    pill.backgroundColor = NativeTheme.navPill
    updateColors()
  }

  @objc private func tap(_ sender: UIButton) {
    guard sender.tag != selectedIndex else {
      bounce(sender)
      onReselect?()
      return
    }
    select(index: sender.tag, notify: true)
  }

  @objc private func menuTap(_ sender: UIButton) {
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    onMenu?(sender.tag)
  }

  @objc private func handleExpandPan(_ gesture: UIPanGestureRecognizer) {
    let translation = gesture.translation(in: self).y
    switch gesture.state {
    case .began:
      dragStartExpansion = expansion
    case .changed:
      let value = min(1, max(0, dragStartExpansion - translation / menuRowHeight))
      setExpansion(value)
    case .ended, .cancelled:
      let velocity = gesture.velocity(in: self).y
      var open = expansion > 0.38 || velocity < -260
      if velocity > 340 { open = false }
      setExpansion(open ? 1 : 0, animated: true)
    default:
      break
    }
  }

  func setExpanded(_ expanded: Bool, animated: Bool) {
    setExpansion(expanded ? 1 : 0, animated: animated)
  }

  private func setExpansion(_ value: CGFloat, animated: Bool = false) {
    expansion = value
    let update = {
      self.barHeight?.constant = self.rowHeight + self.menuRowHeight * value
      self.menuHeight?.constant = self.menuRowHeight * value
      self.menuStack.alpha = min(1, value * 1.6)
      self.rowLine.alpha = value
      self.superview?.layoutIfNeeded()
      self.layoutIfNeeded()
    }
    if animated {
      UIView.animate(withDuration: 0.38, delay: 0,
                     usingSpringWithDamping: 0.82, initialSpringVelocity: 0.4,
                     options: [.allowUserInteraction, .beginFromCurrentState],
                     animations: update)
    } else {
      update()
    }
  }

  func select(index: Int, notify: Bool) {
    guard index >= 0 && index < buttons.count else { return }
    let changed = index != selectedIndex
    selectedIndex = index
    if changed {
      UIView.transition(with: self, duration: 0.24, options: [.transitionCrossDissolve, .allowUserInteraction]) {
        self.updateColors()
      }
      layoutPill(animated: true)
      bounce(buttons[index])
      selectionFeedback.selectionChanged()
      selectionFeedback.prepare()
    } else {
      updateColors()
      stack.layoutIfNeeded()
      layoutPill(animated: false)
    }
    if notify { onSelect?(index) }
  }

  private func updateColors() {
    for (i, button) in buttons.enumerated() {
      let active = i == selectedIndex
      let color = active ? NativeTheme.tabActive : NativeTheme.tabInactive
      button.tintColor = color
      button.setTitleColor(color, for: .normal)
      button.titleLabel?.font = UIFont.systemFont(ofSize: 10, weight: active ? .bold : .medium)
      button.backgroundColor = .clear
      button.alpha = 1
    }
  }

  private func bounce(_ button: UIButton) {
    guard let icon = button.imageView else { return }
    UIView.animate(withDuration: 0.11, delay: 0, options: [.curveEaseOut]) {
      icon.transform = CGAffineTransform(scaleX: 0.82, y: 0.82)
    } completion: { _ in
      UIView.animate(withDuration: 0.34, delay: 0,
                     usingSpringWithDamping: 0.55,
                     initialSpringVelocity: 0.8,
                     options: [.allowUserInteraction]) {
        icon.transform = .identity
      }
    }
  }

  func setHidden(_ shouldHide: Bool, animated: Bool) {
    guard shouldHide != barHidden else { return }
    barHidden = shouldHide
    let distance = bounds.height + 28
    let transform = shouldHide ? CGAffineTransform(translationX: 0, y: distance) : .identity
    let alpha: CGFloat = shouldHide ? 0 : 1
    if animated {
      UIView.animate(
        withDuration: 0.75,
        delay: 0,
        usingSpringWithDamping: 0.9,
        initialSpringVelocity: 0.2,
        options: [.allowUserInteraction, .beginFromCurrentState]
      ) {
        self.transform = transform
        self.alpha = alpha
      } completion: { _ in
        if !shouldHide {
          self.setNeedsLayout()
          self.layoutIfNeeded()
        }
      }
    } else {
      self.transform = transform
      self.alpha = alpha
      if !shouldHide {
        setNeedsLayout()
        layoutIfNeeded()
      }
    }
  }
}

private extension UIButton {
  func alignImageAndTitleVertically(gap: CGFloat) {
    guard let image = imageView?.image, let title = titleLabel?.text else { return }
    let imageSize = image.size
    let titleSize = (title as NSString).size(withAttributes: [.font: titleLabel?.font ?? UIFont.systemFont(ofSize: 10)])
    let totalHeight = imageSize.height + gap + titleSize.height
    imageEdgeInsets = UIEdgeInsets(
      top: -(totalHeight - imageSize.height),
      left: 0,
      bottom: 0,
      right: -titleSize.width
    )
    titleEdgeInsets = UIEdgeInsets(
      top: 0,
      left: -imageSize.width,
      bottom: -(totalHeight - titleSize.height),
      right: 0
    )
  }
}
