import UIKit

final class ProgressWheel: UIControl {
  var progress: Double = 0 {
    didSet { setNeedsDisplay() }
  }
  var currentText: String = "00:00" {
    didSet { setNeedsDisplay() }
  }
  var durationText: String = "00:00" {
    didSet { setNeedsDisplay() }
  }
  var onScrub: ((Double, Bool) -> Void)?

  private var dragging = false

  override init(frame: CGRect) {
    super.init(frame: frame)
    isOpaque = false
    backgroundColor = .clear
    isAccessibilityElement = true
    accessibilityLabel = "播放进度"
    accessibilityTraits = .adjustable
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override var intrinsicContentSize: CGSize {
    return CGSize(width: UIView.noIntrinsicMetric, height: 48)
  }

  override func draw(_ rect: CGRect) {
    guard let context = UIGraphicsGetCurrentContext() else { return }
    let tickTop: CGFloat = 7
    let tickBottom: CGFloat = 28
    let left: CGFloat = 2
    let right = bounds.width - 2
    let usable = max(1, right - left)

    context.setLineCap(.round)
    let count = 48
    for index in 0...count {
      let ratio = CGFloat(index) / CGFloat(count)
      let x = left + usable * ratio
      let major = index % 6 == 0
      let height: CGFloat = major ? 11 : 6
      let color = UIColor.white.withAlphaComponent(major ? 0.58 : 0.26)
      context.setStrokeColor(color.cgColor)
      context.setLineWidth(major ? 1.2 : 0.8)
      context.move(to: CGPoint(x: x, y: tickBottom - height))
      context.addLine(to: CGPoint(x: x, y: tickBottom))
      context.strokePath()
    }

    let needleX = left + usable * CGFloat(max(0, min(1, progress)))
    context.setStrokeColor(NativeTheme.accent.cgColor)
    context.setLineWidth(2)
    context.move(to: CGPoint(x: needleX, y: tickTop - 2))
    context.addLine(to: CGPoint(x: needleX, y: tickBottom + 3))
    context.strokePath()

    let labelFont = NativeTheme.numberFont(9)
    let attributes: [NSAttributedString.Key: Any] = [
      .font: labelFont,
      .foregroundColor: UIColor.white.withAlphaComponent(0.62),
    ]
    let current = currentText as NSString
    let duration = durationText as NSString
    let labelY = tickBottom + 8
    current.draw(at: CGPoint(x: left, y: labelY), withAttributes: attributes)
    let size = duration.size(withAttributes: attributes)
    duration.draw(at: CGPoint(x: right - size.width, y: labelY), withAttributes: attributes)
  }

  override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
    dragging = true
    update(touch)
    return true
  }

  override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
    update(touch)
    return true
  }

  override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
    dragging = false
    onScrub?(progress, true)
  }

  override func cancelTracking(with event: UIEvent?) {
    dragging = false
    onScrub?(progress, true)
  }

  private func update(_ touch: UITouch) {
    let x = touch.location(in: self).x
    let ratio = Double(max(0, min(1, (x - 2) / max(1, bounds.width - 4))))
    progress = ratio
    onScrub?(ratio, false)
    sendActions(for: .valueChanged)
  }

  override func accessibilityIncrement() {
    progress = min(1, progress + 0.01)
    onScrub?(progress, true)
  }

  override func accessibilityDecrement() {
    progress = max(0, progress - 0.01)
    onScrub?(progress, true)
  }
}
