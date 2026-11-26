import UIKit

/// The original player's 36-block grid progress, blue for played blocks.
final class GridProgressBar: UIView {
  var progress: Double = 0 {
    didSet { setNeedsDisplay() }
  }

  override var intrinsicContentSize: CGSize {
    return CGSize(width: UIView.noIntrinsicMetric, height: 6)
  }

  override func draw(_ rect: CGRect) {
    let blocks = 36
    let gap: CGFloat = 2
    let width = (bounds.width - gap * CGFloat(blocks - 1)) / CGFloat(blocks)
    let played = Int((progress * Double(blocks)).rounded())
    for index in 0..<blocks {
      let x = CGFloat(index) * (width + gap)
      let block = CGRect(x: x, y: 0, width: width, height: bounds.height)
      let color = index < played
        ? NativeTheme.navBlue
        : UIColor.white.withAlphaComponent(0.24)
      color.setFill()
      UIBezierPath(roundedRect: block, cornerRadius: 1.5).fill()
    }
  }
}
