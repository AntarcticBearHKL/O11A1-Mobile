import UIKit

/// The desktop player's endless precision ruler: half-second notches run at a
/// fixed 12pt per second, every fifth second carries its absolute timestamp
/// and a red needle marks the exact centre. The strip slides under the needle.
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

  private let ridgeGap: CGFloat = 12
  private let tickStep: Double = 0.5
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
    return CGSize(width: UIView.noIntrinsicMetric, height: 48)
  }

  private var pxPerSecond: CGFloat {
    return ridgeGap
  }

  override func draw(_ rect: CGRect) {
    guard let context = UIGraphicsGetCurrentContext(), bounds.width > 1 else { return }
    let light = traitCollection.userInterfaceStyle == .light
    let total = max(0, durationSeconds)
    let centerTime = max(0, min(total, progress * total))

    let chipColor = light
      ? UIColor(white: 0, alpha: 0.063)
      : UIColor(red: 42.0 / 255.0, green: 42.0 / 255.0, blue: 51.0 / 255.0, alpha: 1)
    let borderColor = light
      ? UIColor(white: 0, alpha: 0.12)
      : UIColor(red: 58.0 / 255.0, green: 58.0 / 255.0, blue: 68.0 / 255.0, alpha: 0.80)
    let accentColor = light
      ? UIColor(red: 0.0 / 255.0, green: 95.0 / 255.0, blue: 184.0 / 255.0, alpha: 1)
      : UIColor(red: 62.0 / 255.0, green: 166.0 / 255.0, blue: 255.0 / 255.0, alpha: 1)
    let dimColor = light
      ? UIColor(red: 95.0 / 255.0, green: 95.0 / 255.0, blue: 104.0 / 255.0, alpha: 1)
      : UIColor(red: 154.0 / 255.0, green: 154.0 / 255.0, blue: 162.0 / 255.0, alpha: 0.78)
    let faintColor = light
      ? UIColor(red: 120.0 / 255.0, green: 120.0 / 255.0, blue: 130.0 / 255.0, alpha: 1)
      : UIColor(red: 154.0 / 255.0, green: 154.0 / 255.0, blue: 162.0 / 255.0, alpha: 0.55)
    let aimColor = light
      ? UIColor(red: 198.0 / 255.0, green: 64.0 / 255.0, blue: 58.0 / 255.0, alpha: 1)
      : UIColor(red: 1.0, green: 112.0 / 255.0, blue: 102.0 / 255.0, alpha: 1)

    let outer = bounds
    let card = UIBezierPath(roundedRect: outer, cornerRadius: 10)
    chipColor.setFill()
    card.fill()
    let borderRect = outer.insetBy(dx: 0.5, dy: 0.5)
    let border = UIBezierPath(roundedRect: borderRect, cornerRadius: 9.5)
    borderColor.setStroke()
    border.lineWidth = 1
    border.stroke()

    let centreX = outer.midX
    let band = CGRect(x: centreX - 24, y: 2, width: 48, height: max(0, outer.height - 4))
    accentColor.withAlphaComponent(0.16).setFill()
    UIBezierPath(roundedRect: band, cornerRadius: 7).fill()

    context.saveGState()
    UIBezierPath(rect: outer.insetBy(dx: 1, dy: 1)).addClip()

    let labelTop: CGFloat = 2
    let labelBottom: CGFloat = 15
    let tickTop: CGFloat = 18
    let tickBottom = outer.height - 7
    let tickHeight = max(1, tickBottom - tickTop)
    let halfSpan = (outer.width / 2) / pxPerSecond
    let start = centerTime - Double(halfSpan)
    let end = centerTime + Double(halfSpan)
    let first = Int(ceil(start / tickStep))
    let last = Int(floor(end / tickStep))

    let labelFont = UIFont.monospacedDigitSystemFont(ofSize: 7.5, weight: .medium)
    let labelAttributes: [NSAttributedString.Key: Any] = [
      .font: labelFont,
      .foregroundColor: dimColor,
    ]

    if first <= last {
      for index in first...last {
        let seconds = Double(index) * tickStep
        let x = centreX + CGFloat(seconds - centerTime) * pxPerSecond
        guard x > -30, x < outer.width + 30 else { continue }
        let major = index % 10 == 0
        let second = index % 2 == 0
        let inRange = seconds >= 0 && seconds <= total
        let atAim = abs(x - centreX) < 1

        if !atAim {
          let height: CGFloat
          let width: CGFloat
          let color: UIColor
          if !inRange {
            height = tickHeight
            width = 1
            color = faintColor
          } else if major {
            height = tickHeight
            width = 1.6
            color = accentColor
          } else if second {
            height = tickHeight * 2.0 / 3.0
            width = 1
            color = dimColor
          } else {
            height = tickHeight / 3.0
            width = 1
            color = faintColor
          }
          color.setFill()
          let tick = CGRect(x: x - width / 2, y: tickBottom - height,
                            width: width, height: height)
          UIBezierPath(roundedRect: tick, cornerRadius: 0.5).fill()
        }

        if inRange && major
          && x >= outer.minX + 30 && x <= outer.maxX - 30 {
          let text = Self.timeText(seconds) as NSString
          let size = text.size(withAttributes: labelAttributes)
          text.draw(at: CGPoint(x: x - size.width / 2, y: labelTop + 1),
                    withAttributes: labelAttributes)
        }
      }
    }

    context.restoreGState()

    // One long red needle owns the exact seek point, running past the scale at
    // both ends as on the desktop panel.
    aimColor.setFill()
    let needle = CGRect(x: centreX - 1, y: labelBottom,
                        width: 2, height: max(0, outer.height - 2 - labelBottom))
    UIBezierPath(roundedRect: needle, cornerRadius: 1).fill()
  }

  private static func timeText(_ seconds: Double) -> String {
    let total = max(0, Int(seconds.rounded()))
    if total >= 3600 {
      return String(format: "%d:%02d:%02d",
                    total / 3600, (total % 3600) / 60, total % 60)
    }
    return String(format: "%02d:%02d", total / 60, total % 60)
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
      progress = max(0, min(1, progress - Double(delta) /
        (durationSeconds * Double(pxPerSecond))))
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
