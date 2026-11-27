import UIKit

/// The desktop precision panel's energy/progress track: a rounded chip with a
/// quiet blue wash for the played part, a blue baseline and a playhead.
final class GridProgressBar: UIView {
  var progress: Double = 0 {
    didSet { setNeedsDisplay() }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
    isOpaque = false
    contentMode = .redraw
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    backgroundColor = .clear
    isOpaque = false
    contentMode = .redraw
  }

  override var intrinsicContentSize: CGSize {
    return CGSize(width: UIView.noIntrinsicMetric, height: 30)
  }

  override func draw(_ rect: CGRect) {
    let light = traitCollection.userInterfaceStyle == .light
    let chipColor = light
      ? UIColor(white: 0, alpha: 0.063)
      : UIColor(red: 42.0 / 255.0, green: 42.0 / 255.0, blue: 51.0 / 255.0, alpha: 1)
    let borderColor = light
      ? UIColor(white: 0, alpha: 0.12)
      : UIColor(red: 58.0 / 255.0, green: 58.0 / 255.0, blue: 68.0 / 255.0, alpha: 0.80)
    let accent = light
      ? UIColor(red: 0.0 / 255.0, green: 95.0 / 255.0, blue: 184.0 / 255.0, alpha: 1)
      : UIColor(red: 62.0 / 255.0, green: 166.0 / 255.0, blue: 255.0 / 255.0, alpha: 1)

    let outer = bounds
    let card = UIBezierPath(roundedRect: outer, cornerRadius: 9)
    chipColor.setFill()
    card.fill()
    let border = UIBezierPath(
      roundedRect: outer.insetBy(dx: 0.5, dy: 0.5), cornerRadius: 8.5)
    borderColor.setStroke()
    border.lineWidth = 1
    border.stroke()

    let fraction = max(0, min(1, progress))
    let playX = outer.minX + CGFloat(fraction) * outer.width
    if fraction > 0.002 {
      let playedRect = CGRect(
        x: outer.minX + 1,
        y: outer.minY + 1,
        width: max(1, playX - outer.minX - 1),
        height: max(0, outer.height - 2)
      )
      accent.withAlphaComponent(0.16).setFill()
      UIBezierPath(roundedRect: playedRect, cornerRadius: 8).fill()
    }

    accent.setFill()
    let baseline = CGRect(
      x: outer.minX,
      y: outer.maxY - 4,
      width: max(0, playX - outer.minX),
      height: 2
    )
    UIBezierPath(roundedRect: baseline, cornerRadius: 1).fill()

    let playhead = CGRect(
      x: playX - 0.75,
      y: outer.minY + 3,
      width: 1.5,
      height: max(0, outer.height - 6)
    )
    UIBezierPath(roundedRect: playhead, cornerRadius: 0.75).fill()
  }
}
