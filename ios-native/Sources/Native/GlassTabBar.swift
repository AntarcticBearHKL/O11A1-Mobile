import UIKit

final class GlassTabBar: UIView {
  var onSelect: ((Int) -> Void)?

  private let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
  private let stack = UIStackView()
  private var buttons: [UIButton] = []
  private let titles = ["推荐", "关注", "动态", "养鱼"]
  private let symbols = ["house", "person.2", "waveform", "fish"]
  private(set) var selectedIndex = 0
  private(set) var barHidden = false

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
    layer.cornerRadius = 26
    layer.cornerCurve = .continuous
    layer.shadowColor = UIColor.black.cgColor
    layer.shadowOpacity = 0.12
    layer.shadowRadius = 18
    layer.shadowOffset = CGSize(width: 0, height: 8)

    blur.layer.cornerRadius = 26
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

    stack.axis = .horizontal
    stack.distribution = .fillEqually
    stack.alignment = .center
    stack.spacing = 0
    addSubview(stack)
    stack.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
      stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
      stack.topAnchor.constraint(equalTo: topAnchor),
      stack.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])

    for index in 0..<titles.count {
      let button = UIButton(type: .custom)
      button.tag = index
      button.titleLabel?.font = UIFont.systemFont(ofSize: 10, weight: .medium)
      button.setTitleColor(NativeTheme.secondary, for: .normal)
      button.setImage(UIImage(systemName: symbols[index]), for: .normal)
      button.tintColor = NativeTheme.secondary
      button.setTitle(titles[index], for: .normal)
      button.alignImageAndTitleVertically(gap: 3)
      button.addTarget(self, action: #selector(tap(_:)), for: .touchUpInside)
      buttons.append(button)
      stack.addArrangedSubview(button)
    }
    select(index: 0, notify: false)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @objc private func tap(_ sender: UIButton) {
    guard sender.tag != selectedIndex else { return }
    select(index: sender.tag, notify: true)
  }

  func select(index: Int, notify: Bool) {
    guard index >= 0 && index < buttons.count else { return }
    selectedIndex = index
    for (i, button) in buttons.enumerated() {
      let active = i == index
      button.tintColor = active ? NativeTheme.navBlue : NativeTheme.secondary
      button.setTitleColor(active ? NativeTheme.navBlue : NativeTheme.secondary, for: .normal)
      button.backgroundColor = active ? NativeTheme.navSoft : .clear
      button.layer.cornerRadius = 22
      button.layer.cornerCurve = .continuous
    }
    if notify { onSelect?(index) }
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
      }
    } else {
      self.transform = transform
      self.alpha = alpha
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
