import UIKit

final class DanmakuOverlayView: UIView {
  private var items: [DanmakuItem] = []
  private var index = 0
  private var lastTime: Double = -1
  private var lane = 0
  private var cid: Int64 = 0
  private(set) var enabled = true

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
    isUserInteractionEnabled = false
    clipsToBounds = true
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func load(cid: Int64) {
    self.cid = cid
    guard cid > 0 else { return }
    BiliAPI.shared.danmaku(cid: cid) { [weak self] result in
      guard let self = self, case .success(let values) = result else { return }
      self.items = values.sorted { $0.time < $1.time }
      self.index = 0
      self.lastTime = -1
    }
  }

  func setTime(_ seconds: Double) {
    guard enabled else { return }
    if seconds + 1.2 < lastTime {
      index = 0
      lastTime = -1
      layer.removeAllAnimations()
      subviews.forEach { $0.removeFromSuperview() }
    }
    lastTime = seconds
    while index < items.count {
      let item = items[index]
      if item.time > seconds + 0.08 { break }
      index += 1
      if item.time < seconds - 1.0 { continue }
      spawn(item)
    }
  }

  func setEnabled(_ enabled: Bool) {
    self.enabled = enabled
    isHidden = !enabled
    if !enabled {
      subviews.forEach { $0.removeFromSuperview() }
    }
  }

  private func spawn(_ item: DanmakuItem) {
    if subviews.count > 42, let first = subviews.first {
      first.removeFromSuperview()
    }
    let label = UILabel()
    label.text = item.text
    label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
    label.textColor = item.color == 0 ? .white : UIColor(
      red: CGFloat((item.color >> 16) & 0xFF) / 255,
      green: CGFloat((item.color >> 8) & 0xFF) / 255,
      blue: CGFloat(item.color & 0xFF) / 255,
      alpha: 1
    )
    label.layer.shadowColor = UIColor.black.cgColor
    label.layer.shadowOpacity = 0.85
    label.layer.shadowRadius = 2
    label.layer.shadowOffset = CGSize(width: 1, height: 1)
    label.sizeToFit()
    let laneHeight: CGFloat = 24
    let lanes = max(1, Int((bounds.height * 0.45) / laneHeight))
    let y = 120 + CGFloat(lane % lanes) * laneHeight
    lane += 1
    label.frame.origin = CGPoint(x: bounds.width + 8, y: y)
    addSubview(label)
    let distance = bounds.width + label.bounds.width + 24
    let duration = max(5.5, Double(distance / 105.0))
    UIView.animate(withDuration: duration, delay: 0, options: [.curveLinear]) {
      label.transform = CGAffineTransform(translationX: -distance, y: 0)
    } completion: { _ in
      label.removeFromSuperview()
    }
  }
}
