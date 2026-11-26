import UIKit

/// A slim, deliberate progress bar for the feed's muted preview playback.
/// The track is quiet; the played span is the app accent with a small glowing
/// head, so it reads clearly over any cover without becoming heavy chrome.
final class PreviewProgressBar: UIView {
  var progress: CGFloat = 0 {
    didSet { setNeedsDisplay() }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
    isOpaque = false
    isUserInteractionEnabled = false
    isHidden = true
    contentMode = .redraw
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    backgroundColor = .clear
    isOpaque = false
    isUserInteractionEnabled = false
    isHidden = true
    contentMode = .redraw
  }

  override func draw(_ rect: CGRect) {
    guard bounds.width > 0, bounds.height > 0 else { return }
    let height = bounds.height
    let radius = height / 2
    UIColor.white.withAlphaComponent(0.24).setFill()
    UIBezierPath(roundedRect: bounds, cornerRadius: radius).fill()

    let ratio = max(0, min(1, progress))
    let width = bounds.width * ratio
    guard width > 0.5 else { return }

    let fillRect = CGRect(x: 0, y: 0, width: width, height: height)
    NativeTheme.navBlue.setFill()
    UIBezierPath(roundedRect: fillRect, cornerRadius: radius).fill()

    let headX = min(bounds.width - radius, max(radius, width - radius))
    let center = CGPoint(x: headX, y: height / 2)
    NativeTheme.navBlue.withAlphaComponent(0.30).setFill()
    UIBezierPath(ovalIn: CGRect(x: center.x - 6, y: center.y - 6,
                                width: 12, height: 12)).fill()
    UIColor.white.setFill()
    UIBezierPath(ovalIn: CGRect(x: center.x - 3.5, y: center.y - 3.5,
                                width: 7, height: 7)).fill()
  }
}
