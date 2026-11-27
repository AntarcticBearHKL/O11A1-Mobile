import UIKit

/// Bottom navigation that unfolds into one continuous list. The four tabs are
/// the first four rows; the four utility entries follow. The compact bar and
/// the list share the same views, so nothing is cross-faded or replaced.
final class GlassTabBar: UIView, UIGestureRecognizerDelegate {
  var onSelect: ((Int) -> Void)?
  var onReselect: (() -> Void)?
  var onMenu: ((Int) -> Void)?

  private let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
  private let tint = UIView()
  private let contentClip = UIView()
  private let pill = UIView()
  private var items: [TabItemView] = []
  private var separators: [UIView] = []

  private let tabTitles = ["推荐", "关注", "动态", "养鱼"]
  private let tabSymbols = ["house", "person.badge.plus", "waveform", "fish"]
  private let menuTitles = ["直播", "番剧", "消息", "历史"]
  private let menuSymbols = ["play.rectangle", "rectangle.split.3x1",
                             "text.bubble", "clock.arrow.circlepath"]

  private(set) var selectedIndex = 0
  private(set) var barHidden = false
  private let selectionFeedback = UISelectionFeedbackGenerator()
  private let barRadius: CGFloat = NativeTheme.cornerRadius
  private let compactHeight: CGFloat = 72
  private let listRowHeight: CGFloat = 60
  private let expansionDuration: CFTimeInterval = 0.52
  private var expandedHeight: CGFloat { listRowHeight * CGFloat(items.count) }

  private var heightConstraint: NSLayoutConstraint?
  private var expansion: CGFloat = 0
  private var dragStartExpansion: CGFloat = 0
  private var pillAnimating = false
  private var displayLink: CADisplayLink?
  private var animationStart: CFTimeInterval = 0
  private var animationFrom: CGFloat = 0
  private var animationTo: CGFloat = 0

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
    heightConstraint = heightAnchor.constraint(equalToConstant: compactHeight)
    heightConstraint?.isActive = true

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

    contentClip.layer.cornerRadius = barRadius
    contentClip.layer.cornerCurve = .continuous
    contentClip.clipsToBounds = true
    addSubview(contentClip)
    contentClip.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      contentClip.leadingAnchor.constraint(equalTo: leadingAnchor),
      contentClip.trailingAnchor.constraint(equalTo: trailingAnchor),
      contentClip.topAnchor.constraint(equalTo: topAnchor),
      contentClip.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])

    pill.backgroundColor = NativeTheme.navPill
    pill.layer.cornerRadius = barRadius
    pill.layer.cornerCurve = .continuous
    pill.isUserInteractionEnabled = false
    contentClip.addSubview(pill)

    for _ in 0..<7 {
      let line = UIView()
      line.backgroundColor = NativeTheme.hairline
      line.alpha = 0
      line.isUserInteractionEnabled = false
      contentClip.addSubview(line)
      separators.append(line)
    }

    let allTitles = tabTitles + menuTitles
    let allSymbols = tabSymbols + menuSymbols
    for index in 0..<allTitles.count {
      let item = TabItemView()
      item.tag = index
      item.configure(title: allTitles[index], symbol: allSymbols[index],
                     menu: index >= tabTitles.count)
      item.addTarget(self, action: #selector(itemTapped(_:)), for: .touchUpInside)
      contentClip.addSubview(item)
      items.append(item)
    }

    let expandPan = UIPanGestureRecognizer(target: self, action: #selector(handleExpandPan(_:)))
    expandPan.cancelsTouchesInView = true
    expandPan.delegate = self
    addGestureRecognizer(expandPan)

    selectionFeedback.prepare()
    select(index: 0, notify: false)
    applyExpansion(0)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    displayLink?.invalidate()
  }

  override func didMoveToWindow() {
    super.didMoveToWindow()
    if window == nil {
      displayLink?.invalidate()
      displayLink = nil
    }
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    layoutItems(expansion)
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    layer.borderColor = NativeTheme.barBorder.cgColor
    tint.backgroundColor = NativeTheme.barGlass
    pill.backgroundColor = NativeTheme.navPill
    for item in items {
      item.setNeedsLayout()
    }
    setNeedsLayout()
  }

  private func layoutItems(_ value: CGFloat) {
    let p = max(0, min(1, value))
    let width = contentClip.bounds.width > 1 ? contentClip.bounds.width : bounds.width
    guard width > 1 else { return }
    let half = width / CGFloat(tabTitles.count)

    for (index, item) in items.enumerated() {
      let targetRowY = CGFloat(index) * listRowHeight
      let compactX: CGFloat
      let compactY: CGFloat
      let compactW: CGFloat
      let compactH: CGFloat
      if index < tabTitles.count {
        compactX = CGFloat(index) * half
        compactY = 0
        compactW = half
        compactH = compactHeight
      } else {
        compactX = 0
        compactY = compactHeight
        compactW = width
        compactH = compactHeight
      }
      item.frame = CGRect(
        x: compactX + (0 - compactX) * p,
        y: compactY + (targetRowY - compactY) * p,
        width: compactW + (width - compactW) * p,
        height: compactH + (listRowHeight - compactH) * p
      )
      item.morph = p
      if index >= tabTitles.count {
        let reveal = min(1, max(0, (p - 0.02) / 0.55))
        item.alpha = reveal * reveal * (3 - 2 * reveal)
        item.isUserInteractionEnabled = p > 0.16
      } else {
        item.alpha = 1
        item.isUserInteractionEnabled = true
      }
      item.layoutIfNeeded()
    }

    for (index, line) in separators.enumerated() {
      line.frame = CGRect(x: 18, y: CGFloat(index + 1) * listRowHeight,
                          width: max(0, width - 36), height: 0.5)
      line.alpha = p
    }

    if !pillAnimating {
      pill.frame = pillFrame(for: selectedIndex, morph: p, width: width)
      pill.layer.cornerRadius = barRadius + (12 - barRadius) * p
    }
  }

  private func pillFrame(for index: Int, morph: CGFloat, width: CGFloat) -> CGRect {
    let p = max(0, min(1, morph))
    let half = width / CGFloat(tabTitles.count)
    let compact = CGRect(x: CGFloat(index) * half, y: 0,
                         width: half, height: compactHeight)
    let row = CGRect(x: 6, y: CGFloat(index) * listRowHeight + 2,
                     width: max(0, width - 12),
                     height: listRowHeight - 4)
    return CGRect(
      x: compact.minX + (row.minX - compact.minX) * p,
      y: compact.minY + (row.minY - compact.minY) * p,
      width: compact.width + (row.width - compact.width) * p,
      height: compact.height + (row.height - compact.height) * p
    )
  }

  private func applyExpansion(_ value: CGFloat) {
    if pillAnimating {
      pillAnimating = false
      pill.layer.removeAllAnimations()
    }
    expansion = max(0, min(1, value))
    let height = compactHeight + (expandedHeight - compactHeight) * expansion
    if let constraint = heightConstraint, abs(constraint.constant - height) > 0.01 {
      constraint.constant = height
      superview?.layoutIfNeeded()
    }
    layoutItems(expansion)
  }

  private func setExpansion(_ value: CGFloat, animated: Bool = false) {
    let target = max(0, min(1, value))
    displayLink?.invalidate()
    displayLink = nil
    guard animated, abs(target - expansion) > 0.001 else {
      applyExpansion(target)
      return
    }
    animationFrom = expansion
    animationTo = target
    animationStart = CACurrentMediaTime()
    let link = CADisplayLink(target: self, selector: #selector(expansionStep(_:)))
    link.add(to: .main, forMode: .common)
    displayLink = link
  }

  @objc private func expansionStep(_ link: CADisplayLink) {
    let elapsed = CACurrentMediaTime() - animationStart
    let t = max(0, min(1, elapsed / expansionDuration))
    let eased = springCurve(t)
    let value = animationFrom + (animationTo - animationFrom) * eased
    applyExpansion(value)
    if t >= 1 {
      link.invalidate()
      displayLink = nil
      applyExpansion(animationTo)
    }
  }

  private func springCurve(_ t: CGFloat) -> CGFloat {
    let zeta: Double = 0.78
    let omega: Double = 14.0
    let damped = omega * sqrt(1 - zeta * zeta)
    let time = Double(max(0, min(1, t)))
    let decay = exp(-zeta * omega * time)
    let value = 1 - decay * (cos(damped * time)
      + (zeta * omega / damped) * sin(damped * time))
    return CGFloat(value)
  }

  func setExpanded(_ expanded: Bool, animated: Bool) {
    setExpansion(expanded ? 1 : 0, animated: animated)
  }

  func select(index: Int, notify: Bool) {
    guard index >= 0 && index < tabTitles.count else { return }
    let changed = index != selectedIndex
    selectedIndex = index
    updateColors()
    if changed {
      layoutPill(animated: true)
      bounce(items[index])
      selectionFeedback.selectionChanged()
      selectionFeedback.prepare()
    } else {
      layoutItems(expansion)
    }
    if notify { onSelect?(index) }
  }

  private func layoutPill(animated: Bool) {
    let target = pillFrame(for: selectedIndex, morph: expansion,
                           width: contentClip.bounds.width)
    let radius = barRadius + (12 - barRadius) * expansion
    if animated && displayLink == nil {
      pillAnimating = true
      pill.layer.removeAllAnimations()
      UIView.animate(withDuration: 0.38, delay: 0,
                     usingSpringWithDamping: 0.82,
                     initialSpringVelocity: 0.5,
                     options: [.allowUserInteraction, .beginFromCurrentState]) {
        self.pill.frame = target
        self.pill.layer.cornerRadius = radius
      } completion: { _ in
        self.pillAnimating = false
        self.pill.frame = target
        self.pill.layer.cornerRadius = radius
      }
    } else {
      pill.frame = target
      pill.layer.cornerRadius = radius
    }
  }

  private func updateColors() {
    for (index, item) in items.enumerated() {
      item.active = index == selectedIndex && index < tabTitles.count
    }
  }

  @objc private func itemTapped(_ sender: UIControl) {
    guard let item = sender as? TabItemView else { return }
    let index = item.tag
    if index < tabTitles.count {
      if index == selectedIndex {
        bounce(item)
        onReselect?()
      } else {
        select(index: index, notify: true)
      }
      if expansion > 0.01 {
        setExpansion(0, animated: true)
      }
    } else {
      UIImpactFeedbackGenerator(style: .light).impactOccurred()
      onMenu?(index - tabTitles.count)
      if expansion > 0.01 {
        setExpansion(0, animated: true)
      }
    }
  }

  @objc private func handleExpandPan(_ gesture: UIPanGestureRecognizer) {
    let translation = gesture.translation(in: self).y
    switch gesture.state {
    case .began:
      displayLink?.invalidate()
      displayLink = nil
      dragStartExpansion = expansion
    case .changed:
      let travel = max(1, expandedHeight - compactHeight)
      let value = min(1, max(0, dragStartExpansion - translation / travel))
      applyExpansion(value)
    case .ended, .cancelled:
      let velocity = gesture.velocity(in: self).y
      var open = expansion > 0.34 || velocity < -260
      if velocity > 320 { open = false }
      setExpansion(open ? 1 : 0, animated: true)
    default:
      break
    }
  }

  override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
    let velocity = pan.velocity(in: self)
    let translation = pan.translation(in: self)
    let vertical = abs(translation.y)
    let horizontal = abs(translation.x)
    let verticalVelocity = abs(velocity.y)
    let horizontalVelocity = abs(velocity.x)
    guard vertical > 4 || verticalVelocity > 90 else { return false }
    return vertical > horizontal * 1.15 || verticalVelocity > horizontalVelocity * 1.15
  }

  private func bounce(_ item: TabItemView) {
    let icon = item.iconView
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
    if shouldHide {
      displayLink?.invalidate()
      displayLink = nil
      applyExpansion(0)
    }
    let distance = compactHeight + 28
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

/// One icon + label pair shared by the compact bar and the expanded list.
private final class TabItemView: UIControl {
  let iconView = UIImageView()
  let label = UILabel()
  private var menuRow = false
  var morph: CGFloat = 0 {
    didSet { setNeedsLayout() }
  }
  var active = false {
    didSet { setNeedsLayout() }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    clipsToBounds = false
    iconView.contentMode = .scaleAspectFit
    iconView.isUserInteractionEnabled = false
    addSubview(iconView)
    label.textAlignment = .left
    label.isUserInteractionEnabled = false
    addSubview(label)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(title: String, symbol: String, menu: Bool) {
    menuRow = menu
    let config = UIImage.SymbolConfiguration(pointSize: 21, weight: .regular)
    iconView.image = UIImage(systemName: symbol, withConfiguration: config)
    label.text = title
    isAccessibilityElement = true
    accessibilityLabel = title
    accessibilityTraits = .button
    setNeedsLayout()
  }

  override var isHighlighted: Bool {
    didSet { alpha = isHighlighted ? 0.68 : 1 }
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    setNeedsLayout()
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    guard bounds.width > 1, bounds.height > 1 else { return }
    let m = max(0, min(1, morph))
    let iconSize: CGFloat = 24
    let gap: CGFloat = 10
    label.font = UIFont.systemFont(ofSize: 18,
                                   weight: active ? .semibold : .medium)
    let textWidth = max(1, label.intrinsicContentSize.width)
    let groupWidth = iconSize + gap + textWidth
    let groupX = max(0, (bounds.width - groupWidth) / 2)
    let compactIcon = CGPoint(x: bounds.midX, y: bounds.midY)
    let rowIcon = CGPoint(x: groupX + iconSize / 2, y: bounds.midY)
    iconView.bounds = CGRect(x: 0, y: 0, width: iconSize, height: iconSize)
    iconView.center = CGPoint(
      x: compactIcon.x + (rowIcon.x - compactIcon.x) * m,
      y: compactIcon.y + (rowIcon.y - compactIcon.y) * m
    )

    let activeColor = NativeTheme.tabActive
    let labelInactive = menuRow
      ? NativeTheme.foreground
      : blend(NativeTheme.tabInactive, NativeTheme.foreground, m)
    let iconInactive = menuRow
      ? NativeTheme.tabInactive
      : blend(NativeTheme.tabInactive, NativeTheme.secondary, m)
    label.textColor = active ? activeColor : labelInactive
    iconView.tintColor = active ? activeColor : iconInactive

    label.textAlignment = .center
    label.frame = CGRect(x: groupX + iconSize + gap,
                         y: bounds.midY - 11,
                         width: textWidth, height: 22)
    let reveal = max(0, min(1, (m - 0.08) / 0.6))
    label.alpha = reveal * reveal * (3 - 2 * reveal)
    let scale = 0.9 + 0.1 * m
    label.transform = CGAffineTransform(scaleX: scale, y: scale)
    accessibilityTraits = active ? [.button, .selected] : .button
  }

  private func blend(_ from: UIColor, _ to: UIColor, _ amount: CGFloat) -> UIColor {
    let a = from.resolvedColor(with: traitCollection)
    let b = to.resolvedColor(with: traitCollection)
    var ar: CGFloat = 0, ag: CGFloat = 0, ab: CGFloat = 0, aa: CGFloat = 0
    var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
    a.getRed(&ar, green: &ag, blue: &ab, alpha: &aa)
    b.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
    let t = max(0, min(1, amount))
    return UIColor(red: ar + (br - ar) * t,
                   green: ag + (bg - ag) * t,
                   blue: ab + (bb - ab) * t,
                   alpha: aa + (ba - aa) * t)
  }
}
