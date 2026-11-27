import UIKit

final class DanmakuOverlayView: UIView {
  private var items: [DanmakuItem] = []
  private var index = 0
  private var lastTime: Double = -1
  private var cid: Int64 = 0
  private(set) var topInset: CGFloat = 76
  private(set) var enabled = true

  private var pending: [DanmakuItem] = []
  private var laneFreeAt: [CFTimeInterval] = []
  private var laneLayoutHeight: CGFloat = 0
  private var laneLayoutStep = 1
  private var nextSpawnAt: CFTimeInterval = 0
  private var pumpTimer: Timer?

  private let laneGap: CGFloat = 18
  private let spawnInterval: CFTimeInterval = 0.075
  private let pendingLifetime: Double = 1.6
  private let maxPending = 80

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
    isUserInteractionEnabled = false
    clipsToBounds = true
    if UserDefaults.standard.object(forKey: "danmaku_enabled") != nil {
      enabled = UserDefaults.standard.bool(forKey: "danmaku_enabled")
      isHidden = !enabled
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    pumpTimer?.invalidate()
  }

  func load(cid: Int64) {
    self.cid = cid
    items.removeAll()
    resetPlayback(clearLabels: true)
    guard cid > 0 else { return }
    BiliAPI.shared.danmaku(cid: cid) { [weak self] result in
      guard let self = self, self.cid == cid,
            case .success(let values) = result else { return }
      self.items = values.sorted { $0.time < $1.time }
      self.index = 0
      self.lastTime = -1
    }
  }

  func setTime(_ seconds: Double) {
    guard enabled else { return }
    if seconds + 1.2 < lastTime {
      resetPlayback(clearLabels: true)
    }
    lastTime = seconds
    while index < items.count {
      let item = items[index]
      if item.time > seconds + 0.08 { break }
      index += 1
      if item.time < seconds - 1.0 { continue }
      if pending.count >= maxPending {
        pending.removeFirst(pending.count - maxPending + 1)
      }
      pending.append(item)
    }
    pump()
  }

  func setEnabled(_ enabled: Bool) {
    self.enabled = enabled
    isHidden = !enabled
    if !enabled {
      pending.removeAll()
      laneFreeAt.removeAll()
      nextSpawnAt = 0
      stopPump()
      subviews.forEach { $0.removeFromSuperview() }
    }
  }

  /// Changes the empty band above the first lane and carries any danmaku that
  /// is already on screen to the new position. Portrait keeps a gap below the
  /// status bar; landscape uses the very top of the screen.
  func setTopInset(_ value: CGFloat, animated: Bool) {
    let old = topInset
    guard abs(value - old) > 0.5 else { return }
    topInset = value
    let delta = value - old
    let labels = subviews.compactMap { $0 as? UILabel }
    guard !labels.isEmpty else { return }
    let move = {
      for label in labels {
        label.transform = label.transform.translatedBy(x: 0, y: delta)
      }
    }
    if animated {
      UIView.animate(withDuration: 0.30, delay: 0,
                     options: [.curveEaseInOut, .allowUserInteraction,
                               .beginFromCurrentState],
                     animations: move)
    } else {
      move()
    }
  }

  func applyStoredSettings() {
    let defaults = UserDefaults.standard
    let isOn = defaults.object(forKey: "danmaku_enabled") == nil
      ? true : defaults.bool(forKey: "danmaku_enabled")
    setEnabled(isOn)
    guard isOn else { return }
    let sizePercent = defaults.object(forKey: "danmaku_size") == nil
      ? 100.0 : Double(defaults.float(forKey: "danmaku_size"))
    let opacityPercent = defaults.object(forKey: "danmaku_opacity") == nil
      ? 88.0 : Double(defaults.float(forKey: "danmaku_opacity"))
    let font = UIFont.systemFont(
      ofSize: max(8, 13 * CGFloat(sizePercent / 100)), weight: .medium)
    let alpha = CGFloat(max(0.1, min(1, opacityPercent / 100)))
    for case let label as UILabel in subviews {
      label.font = font
      label.alpha = alpha
      label.sizeToFit()
    }
  }

  private func resetPlayback(clearLabels: Bool) {
    index = 0
    lastTime = -1
    pending.removeAll()
    laneFreeAt.removeAll()
    nextSpawnAt = 0
    stopPump()
    if clearLabels {
      subviews.forEach { $0.removeFromSuperview() }
    }
  }

  @discardableResult
  private func spawn(_ item: DanmakuItem, now: CFTimeInterval) -> Bool {
    guard bounds.width > 1, bounds.height > topInset else { return false }
    let defaults = UserDefaults.standard
    let sizePercent = defaults.object(forKey: "danmaku_size") == nil
      ? 100.0 : Double(defaults.float(forKey: "danmaku_size"))
    let opacityPercent = defaults.object(forKey: "danmaku_opacity") == nil
      ? 88.0 : Double(defaults.float(forKey: "danmaku_opacity"))
    let speedPercent = defaults.object(forKey: "danmaku_speed") == nil
      ? 100.0 : Double(defaults.float(forKey: "danmaku_speed"))
    let area = defaults.string(forKey: "danmaku_area") ?? "全屏"
    let dense = defaults.object(forKey: "danmaku_density") == nil
      ? true : defaults.bool(forKey: "danmaku_density")

    let font = UIFont.systemFont(
      ofSize: max(8, 13 * CGFloat(sizePercent / 100)), weight: .medium)
    let alpha = CGFloat(max(0.1, min(1, opacityPercent / 100)))
    let laneHeight = max(24, ceil(font.lineHeight) + 6)
    let fraction: CGFloat = area == "1/3 屏" ? 0.33 : (area == "1/2 屏" ? 0.5 : 0.78)
    let step = dense ? 1 : 2
    let available = max(0, bounds.height - topInset)
    let lanes = max(1, Int(available * fraction /
      (laneHeight * CGFloat(step))))
    syncLaneCount(lanes, laneHeight: laneHeight, step: step)

    var chosen = -1
    for lane in 0..<lanes where laneFreeAt[lane] <= now {
      chosen = lane
      break
    }
    guard chosen >= 0 else { return false }

    let label = UILabel()
    label.text = item.text
    label.font = font
    label.textColor = item.color == 0 ? .white : UIColor(
      red: CGFloat((item.color >> 16) & 0xFF) / 255,
      green: CGFloat((item.color >> 8) & 0xFF) / 255,
      blue: CGFloat(item.color & 0xFF) / 255,
      alpha: 1
    )
    label.alpha = alpha
    label.layer.shadowColor = UIColor.black.cgColor
    label.layer.shadowOpacity = 0.85
    label.layer.shadowRadius = 2
    label.layer.shadowOffset = CGSize(width: 1, height: 1)
    label.sizeToFit()

    let startX = bounds.width + 8
    let endX = -label.bounds.width - 8
    let y = topInset + CGFloat(chosen * step) * laneHeight
    label.frame = CGRect(x: startX, y: y,
                         width: label.bounds.width, height: label.bounds.height)
    addSubview(label)

    let speedFactor = max(0.5, speedPercent / 100)
    let pointsPerSecond = 105.0 * speedFactor
    let distance = startX - endX
    let duration = max(3.5, Double(distance / 105.0) / speedFactor)
    laneFreeAt[chosen] = now + Double(label.bounds.width + laneGap) /
      pointsPerSecond

    UIView.animate(withDuration: duration, delay: 0,
                   options: [.curveLinear]) {
      label.frame.origin.x = endX
    } completion: { _ in
      label.removeFromSuperview()
    }
    return true
  }

  private func syncLaneCount(_ count: Int, laneHeight: CGFloat, step: Int) {
    if laneHeight != laneLayoutHeight || step != laneLayoutStep {
      laneLayoutHeight = laneHeight
      laneLayoutStep = step
      subviews.forEach { $0.removeFromSuperview() }
      laneFreeAt = Array(repeating: 0, count: count)
      return
    }
    if count > laneFreeAt.count {
      laneFreeAt.append(
        contentsOf: repeatElement(0, count: count - laneFreeAt.count))
    } else if count < laneFreeAt.count {
      let bottom = topInset + CGFloat(count * step) * laneHeight
      for case let label as UILabel in subviews
      where label.frame.minY >= bottom - 1 {
        label.removeFromSuperview()
      }
      laneFreeAt.removeLast(laneFreeAt.count - count)
    }
  }

  private func pump() {
    guard enabled else {
      stopPump()
      return
    }
    guard !pending.isEmpty else {
      stopPump()
      return
    }
    let now = CACurrentMediaTime()
    if lastTime > 0 {
      pending.removeAll { $0.time < lastTime - pendingLifetime }
    }
    guard !pending.isEmpty else {
      stopPump()
      return
    }
    if now >= nextSpawnAt {
      for position in pending.indices {
        if spawn(pending[position], now: now) {
          pending.remove(at: position)
          nextSpawnAt = now + spawnInterval
          break
        }
      }
    }
    if pending.isEmpty {
      stopPump()
    } else {
      startPump()
    }
  }

  private func startPump() {
    guard pumpTimer == nil else { return }
    let timer = Timer(timeInterval: 1.0 / 30.0, repeats: true) {
      [weak self] _ in self?.pump()
    }
    RunLoop.main.add(timer, forMode: .common)
    pumpTimer = timer
  }

  private func stopPump() {
    pumpTimer?.invalidate()
    pumpTimer = nil
  }
}
