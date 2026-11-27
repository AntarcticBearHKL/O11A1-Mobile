import UIKit

/// The desktop player's block grid progress: 36 heat cells that light up in
/// blue as playback advances, sitting above the precision ruler.
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
    return CGSize(width: UIView.noIntrinsicMetric, height: 14)
  }

  override func draw(_ rect: CGRect) {
    guard bounds.width > 1 else { return }
    let light = traitCollection.userInterfaceStyle == .light
    let blocks = 36
    let gap: CGFloat = 2
    let cellWidth = (bounds.width - gap * CGFloat(blocks - 1)) / CGFloat(blocks)
    guard cellWidth > 0 else { return }
    let cellHeight = min(14, bounds.height)
    let y = (bounds.height - cellHeight) / 2
    let fraction = max(0, min(1, progress))
    let filled = Int(ceil(fraction * Double(blocks) - 1e-6))

    let played = light
      ? UIColor(red: 47.0 / 255.0, green: 124.0 / 255.0, blue: 246.0 / 255.0, alpha: 1)
      : UIColor(red: 84.0 / 255.0, green: 167.0 / 255.0, blue: 1.0, alpha: 1)
    let empty = light
      ? UIColor(white: 0, alpha: 0.12)
      : UIColor(white: 1, alpha: 0.14)

    for index in 0..<blocks {
      let cell = CGRect(
        x: CGFloat(index) * (cellWidth + gap),
        y: y,
        width: cellWidth,
        height: cellHeight
      )
      (index < filled ? played : empty).setFill()
      UIBezierPath(roundedRect: cell, cornerRadius: 2).fill()
    }
  }
}
