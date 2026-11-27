import UIKit

/// The soft profile hero surface from the desktop UP page: a content-coloured
/// card with an accent glow in the top-left and a coral glow in the bottom-right.
final class ProfileHeroBackground: UIView {
  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
    isOpaque = false
    clipsToBounds = true
    layer.cornerRadius = NativeTheme.cornerRadius
    layer.cornerCurve = .continuous
    layer.borderWidth = 0.5
    layer.borderColor = NativeTheme.hairline.cgColor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    layer.borderColor = NativeTheme.hairline.cgColor
    setNeedsDisplay()
  }

  override func draw(_ rect: CGRect) {
    guard let context = UIGraphicsGetCurrentContext() else { return }
    let path = UIBezierPath(roundedRect: bounds, cornerRadius: NativeTheme.cornerRadius)
    context.saveGState()
    path.addClip()
    NativeTheme.surface.setFill()
    path.fill()
    let span = max(bounds.width, bounds.height)
    drawGlow(context,
             center: CGPoint(x: bounds.width * 0.08, y: -bounds.height * 0.35),
             radius: span * 0.8,
             color: NativeTheme.accent.withAlphaComponent(0.16))
    drawGlow(context,
             center: CGPoint(x: bounds.width * 1.02, y: bounds.height * 1.15),
             radius: span * 0.65,
             color: NativeTheme.warmOrange.withAlphaComponent(0.12))
    context.restoreGState()
    NativeTheme.hairline.setStroke()
    path.lineWidth = 0.5
    path.stroke()
  }

  private func drawGlow(_ context: CGContext, center: CGPoint, radius: CGFloat,
                        color: UIColor) {
    let colors = [color.cgColor, color.withAlphaComponent(0).cgColor] as CFArray
    guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                    colors: colors, locations: [0, 1]) else { return }
    context.saveGState()
    context.drawRadialGradient(gradient, startCenter: center, startRadius: 0,
                               endCenter: center, endRadius: radius, options: [])
    context.restoreGState()
  }
}

/// The gradient ring around a profile avatar, matching the desktop hero.
final class ProfileAvatarRing: UIView {
  private let gradient = CAGradientLayer()

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
    clipsToBounds = true
    gradient.colors = [NativeTheme.accent.cgColor,
                       NativeTheme.warmOrange.cgColor]
    gradient.startPoint = CGPoint(x: 0, y: 0)
    gradient.endPoint = CGPoint(x: 1, y: 1)
    layer.addSublayer(gradient)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    gradient.frame = bounds
    layer.cornerRadius = bounds.width / 2
    CATransaction.commit()
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    gradient.colors = [NativeTheme.accent.cgColor,
                       NativeTheme.warmOrange.cgColor]
  }
}
