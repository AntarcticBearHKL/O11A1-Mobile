import UIKit

/// A slim, deliberate progress bar for the feed's muted preview playback.
/// The track is quiet; the played span is the app accent with a small glowing
/// head, so it reads clearly over any cover without becoming heavy chrome.
final class PreviewProgressBar: UIControl {
  var progress: CGFloat = 0 {
    didSet { setNeedsDisplay() }
  }
  var onScrub: ((CGFloat, Bool) -> Void)?

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
    isOpaque = false
    isHidden = true
    contentMode = .redraw
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    backgroundColor = .clear
    isOpaque = false
    isHidden = true
    contentMode = .redraw
  }

  override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    return CGRect(x: 0, y: -14, width: bounds.width, height: bounds.height + 18)
      .contains(point)
  }

  override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
    let x = touch.location(in: self).x
    progress = max(0, min(1, x / max(1, bounds.width)))
    onScrub?(progress, false)
    return true
  }

  override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
    let x = touch.location(in: self).x
    progress = max(0, min(1, x / max(1, bounds.width)))
    onScrub?(progress, false)
    return true
  }

  override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
    onScrub?(progress, true)
  }

  override func cancelTracking(with event: UIEvent?) {
    onScrub?(progress, true)
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
  }
}
