import UIKit

/// The original player's 36-block grid progress, blue for played blocks.
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
    let light = traitCollection.userInterfaceStyle == .light
    let blocks = 36
    let gap: CGFloat = 2
    let width = (bounds.width - gap * CGFloat(blocks - 1)) / CGFloat(blocks)
    let played = Int((progress * Double(blocks)).rounded())
    for index in 0..<blocks {
      let x = CGFloat(index) * (width + gap)
      let block = CGRect(x: x, y: 0, width: width, height: bounds.height)
      let color: UIColor
      if index < played {
        color = light
          ? UIColor(red: 47.0 / 255.0, green: 124.0 / 255.0, blue: 246.0 / 255.0, alpha: 1)
          : UIColor(red: 84.0 / 255.0, green: 167.0 / 255.0, blue: 1.0, alpha: 1)
      } else {
        color = light
          ? UIColor(white: 0, alpha: 0.12)
          : UIColor(white: 1, alpha: 0.14)
      }
      color.setFill()
      UIBezierPath(roundedRect: block, cornerRadius: 2).fill()
    }
  }
}
