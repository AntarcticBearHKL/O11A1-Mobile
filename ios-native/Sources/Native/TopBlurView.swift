import UIKit

/// The shared soft top blur: opaque behind the status bar, melting into the
/// content below. Used by the feed, search header and UP page.
final class TopBlurView: UIView {
  private let blur = UIVisualEffectView(
    effect: UIBlurEffect(style: .systemUltraThinMaterial))
  private let maskLayer = CAGradientLayer()
  private var heightConstraint: NSLayoutConstraint?

  var blurExtraHeight: CGFloat = 22 {
    didSet { updateHeight(safeAreaTop: lastSafeAreaTop) }
  }
  private var lastSafeAreaTop: CGFloat = 0

  override init(frame: CGRect) {
    super.init(frame: frame)
    isUserInteractionEnabled = false
    backgroundColor = .clear
    blur.isUserInteractionEnabled = false
    addSubview(blur)
    blur.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      blur.leadingAnchor.constraint(equalTo: leadingAnchor),
      blur.trailingAnchor.constraint(equalTo: trailingAnchor),
      blur.topAnchor.constraint(equalTo: topAnchor),
      blur.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
    maskLayer.colors = [UIColor.black.cgColor,
                        UIColor.black.cgColor,
                        UIColor.clear.cgColor]
    maskLayer.locations = [0, 0.55, 1]
    layer.mask = maskLayer
    heightConstraint = heightAnchor.constraint(equalToConstant: 60)
    heightConstraint?.isActive = true
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    maskLayer.frame = bounds
    CATransaction.commit()
  }

  func updateHeight(safeAreaTop: CGFloat) {
    lastSafeAreaTop = safeAreaTop
    heightConstraint?.constant = safeAreaTop + blurExtraHeight
    setNeedsLayout()
  }
}
