import UIKit

/// Precision ruler from the original player. The red needle stays in the
/// centre while the tick strip moves under it.
final class ProgressWheel: UIControl {
  var progress: Double = 0 {
    didSet { setNeedsDisplay() }
  }
  var durationSeconds: Double = 0 {
    didSet { setNeedsDisplay() }
  }
  var currentText: String = "00:00"
  var durationText: String = "00:00"
  var onScrub: ((Double, Bool) -> Void)?

  private var lastX: CGFloat = 0

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
    return CGSize(width: UIView.noIntrinsicMetric, height: 50)
  }

  private var pxPerSecond: CGFloat {
    return max(4.5, min(11, bounds.width / 72))
  }

  private var minorStep: Double {
    let steps: [Double] = [1, 2, 5, 10, 15, 30, 60, 120, 300, 600]
    for step in steps where CGFloat(step) * pxPerSecond >= 11 {
      return step
    }
    return 600
  }

  override func draw(_ rect: CGRect) {
    guard let context = UIGraphicsGetCurrentContext(), bounds.width > 0 else { return }
    let light = traitCollection.userInterfaceStyle == .light
    let centerX = bounds.width / 2
    let total = max(0, durationSeconds)
    let center = max(0, min(total, progress * total))

    // centre band
    let band = CGRect(x: centerX - 26, y: 0, width: 52, height: bounds.height)
    (light ? UIColor(red: 47.0 / 255.0, green: 124.0 / 255.0, blue: 246.0 / 255.0, alpha: 0.1)
          : UIColor(red: 110.0 / 255.0, green: 168.0 / 255.0, blue: 1.0, alpha: 0.1)).setFill()
    UIBezierPath(roundedRect: band, cornerRadius: NativeTheme.cornerRadius).fill()

    if total > 0 {
      let step = minorStep
      let px = pxPerSecond
      let halfSpan = Double(bounds.width / 2) / Double(px)
      let start = center - halfSpan
      let end = center + halfSpan
      let first = Int(ceil(start / step))
      let last = Int(floor(end / step))

      let minorColor = light
        ? UIColor(red: 158.0 / 255.0, green: 162.0 / 255.0, blue: 168.0 / 255.0, alpha: 0.88)
        : UIColor(red: 124.0 / 255.0, green: 130.0 / 255.0, blue: 138.0 / 255.0, alpha: 0.85)
      let midColor = light
        ? UIColor(red: 32.0 / 255.0, green: 34.0 / 255.0, blue: 38.0 / 255.0, alpha: 0.92)
        : UIColor(red: 230.0 / 255.0, green: 233.0 / 255.0, blue: 238.0 / 255.0, alpha: 0.92)
      let majorColor = light
        ? UIColor(red: 103.0 / 255.0, green: 125.0 / 255.0, blue: 154.0 / 255.0, alpha: 1)
        : UIColor(red: 139.0 / 255.0, green: 160.0 / 255.0, blue: 186.0 / 255.0, alpha: 0.95)
      let labelColor = light
        ? UIColor(red: 26.0 / 255.0, green: 26.0 / 255.0, blue: 26.0 / 255.0, alpha: 0.44)
        : UIColor(white: 1, alpha: 0.44)
      let pastLabelColor = light
        ? UIColor(red: 47.0 / 255.0, green: 124.0 / 255.0, blue: 246.0 / 255.0, alpha: 1)
        : UIColor(red: 140.0 / 255.0, green: 188.0 / 255.0, blue: 1.0, alpha: 0.78)

      let labelFont = UIFont.monospacedDigitSystemFont(ofSize: 7, weight: .medium)
      let labelAttributes: [NSAttributedString.Key: Any] = [
        .font: labelFont,
      ]

      if first <= last {
        for index in first...last {
          let seconds = Double(index) * step
          let x = centerX + CGFloat(seconds - center) * px
          let major = index % 5 == 0
          let mid = index % 2 == 0
          let outside = seconds < 0 || seconds > total
          let past = seconds <= center
          let tickColor: UIColor
          if major {
            tickColor = outside ? minorColor : majorColor
          } else if mid {
            tickColor = midColor
          } else {
            tickColor = minorColor
          }
          let width: CGFloat = major ? 1.6 : 1
          let height: CGFloat
          if major {
            height = bounds.height - 19
          } else if mid {
            height = 20
          } else {
            height = 11
          }
          tickColor.setFill()
          let tick = CGRect(x: x - width / 2, y: bounds.height - 5 - height,
                            width: width, height: height)
          UIBezierPath(roundedRect: tick, cornerRadius: 1).fill()

          if major && seconds >= 0 && seconds <= total
            && x > 22 && x < bounds.width - 22 {
            let text = Self.timeText(seconds) as NSString
            var attributes = labelAttributes
            attributes[.foregroundColor] = past ? pastLabelColor : labelColor
            let size = text.size(withAttributes: attributes)
            text.draw(at: CGPoint(x: x - size.width / 2, y: 2.5),
                      withAttributes: attributes)
          }
        }
      }
    }

    // centre needle
    let needleColor = light
      ? UIColor(red: 211.0 / 255.0, green: 69.0 / 255.0, blue: 61.0 / 255.0, alpha: 1)
      : UIColor(red: 1.0, green: 90.0 / 255.0, blue: 95.0 / 255.0, alpha: 1)
    needleColor.setFill()
    UIBezierPath(roundedRect: CGRect(x: centerX - 1, y: 0, width: 2, height: bounds.height),
                 cornerRadius: 1).fill()
  }

  private static func timeText(_ seconds: Double) -> String {
    let value = max(0, Int(seconds.rounded()))
    return String(format: "%02d:%02d", value / 60, value % 60)
  }

  override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
    lastX = touch.location(in: self).x
    return true
  }

  override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
    let x = touch.location(in: self).x
    let delta = x - lastX
    lastX = x
    if durationSeconds > 0 {
      progress = max(0, min(1, progress - Double(delta) / (durationSeconds * Double(pxPerSecond))))
    } else {
      progress = max(0, min(1, Double(x / max(1, bounds.width))))
    }
    onScrub?(progress, false)
    sendActions(for: .valueChanged)
    return true
  }

  override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
    onScrub?(progress, true)
  }

  override func cancelTracking(with event: UIEvent?) {
    onScrub?(progress, true)
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
