import ExpoModulesCore
import UIKit
import MetalKit
import QuartzCore

/// Native view: MTKView + HUD. The JS side only mounts it and flips a few
/// props; decode, blend and sharpen run entirely on the native side.
final class O11A1PlayerView: ExpoView {
  let onStats = EventDispatcher()

  private let metalView = MTKView()
  private let hud = UILabel()
  private let renderer = MetalRenderer()
  private let engine = PlayerEngine()

  private var configured = false
  private var started = false
  private var statsTimer: Timer?
  private var lastRenderCount = 0
  private var lastDecodeCount = 0
  private var lastTick = CACurrentMediaTime()

  var videoSource: String = ""
  var interpolationEnabled = true {
    didSet {
      renderer.interpolationEnabled = interpolationEnabled
    }
  }
  var enhanceEnabled = true {
    didSet {
      renderer.enhanceEnabled = enhanceEnabled
    }
  }
  var targetFps: Double = 120 {
    didSet {
      let clamped = Int(max(30, min(120, targetFps)))
      metalView.preferredFramesPerSecond = clamped
    }
  }
  var paused = false {
    didSet {
      if paused {
        stopPlayback()
      } else {
        applyConfiguration()
      }
    }
  }

  func applyConfiguration() {
    configureIfNeeded()

    guard !paused else {
      stopPlayback()
      return
    }
    guard window != nil else {
      return
    }

    if !started {
      guard let url = resolveSourceURL() else {
        hud.text = "BV1NS4t6oEXQ.mp4 not found"
        return
      }
      started = true
      engine.start(url: url)
      metalView.isPaused = false
      lastTick = CACurrentMediaTime()
      lastRenderCount = renderer.framesDrawn
      let stats = engine.stats()
      lastDecodeCount = stats.decodedFrames
    }

    renderer.interpolationEnabled = interpolationEnabled
    renderer.enhanceEnabled = enhanceEnabled
  }

  private func configureIfNeeded() {
    guard !configured else {
      return
    }
    configured = true

    backgroundColor = .black
    clipsToBounds = true

    metalView.device = renderer.device
    metalView.colorPixelFormat = .bgra8Unorm
    metalView.framebufferOnly = false
    metalView.isOpaque = true
    metalView.backgroundColor = .black
    metalView.enableSetNeedsDisplay = false
    metalView.isPaused = true
    metalView.preferredFramesPerSecond = 120
    metalView.delegate = renderer
    metalView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(metalView)

    hud.translatesAutoresizingMaskIntoConstraints = false
    hud.numberOfLines = 0
    hud.font = UIFont.monospacedSystemFont(ofSize: 10, weight: .medium)
    hud.textColor = .white
    hud.backgroundColor = UIColor.black.withAlphaComponent(0.45)
    hud.layer.cornerRadius = 6
    hud.layer.masksToBounds = true
    hud.text = "O11A1 · waiting for video"
    hud.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    addSubview(hud)

    NSLayoutConstraint.activate([
      metalView.leadingAnchor.constraint(equalTo: leadingAnchor),
      metalView.trailingAnchor.constraint(equalTo: trailingAnchor),
      metalView.topAnchor.constraint(equalTo: topAnchor),
      metalView.bottomAnchor.constraint(equalTo: bottomAnchor),

      hud.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
      hud.topAnchor.constraint(equalTo: topAnchor, constant: 8),
      hud.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -8)
    ])

    renderer.engine = engine
    startStatsTimer()
  }

  private func startStatsTimer() {
    statsTimer?.invalidate()
    let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
      self?.tickStats()
    }
    RunLoop.main.add(timer, forMode: .common)
    statsTimer = timer
  }

  private func tickStats() {
    let now = CACurrentMediaTime()
    let elapsed = max(0.001, now - lastTick)
    let stats = engine.stats()

    let renderFps = Double(renderer.framesDrawn - lastRenderCount) / elapsed
    let decodeFps = Double(stats.decodedFrames - lastDecodeCount) / elapsed

    lastTick = now
    lastRenderCount = renderer.framesDrawn
    lastDecodeCount = stats.decodedFrames

    let screenHz = window?.screen.maximumFramesPerSecond ?? UIScreen.main.maximumFramesPerSecond
    let lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled ? " · LPM" : ""
    let errorLine = stats.error.isEmpty ? "" : "\n\(stats.error)"
    let renderText = String(format: "%.1f", renderFps)
    let decodeText = String(format: "%.1f", decodeFps)
    let text = """
    \(stats.codec) \(stats.hardware ? "HW" : "SW")
    \(stats.width) x \(stats.height)  |  display \(screenHz) Hz\(lowPower)
    render \(renderText) fps  |  decode \(decodeText) fps  |  target \(metalView.preferredFramesPerSecond)
    blend \(interpolationEnabled ? "on" : "off")  |  CAS \(enhanceEnabled ? "on" : "off")  |  queue \(stats.queueDepth)\(errorLine)
    """

    hud.text = text
    onStats([
      "text": text,
      "renderFps": renderFps,
      "decodeFps": decodeFps,
      "decoder": stats.codec,
      "hardware": stats.hardware,
      "width": stats.width,
      "height": stats.height,
      "queue": stats.queueDepth,
      "error": stats.error
    ])
  }

  private func resolveSourceURL() -> URL? {
    if !videoSource.isEmpty {
      if let url = URL(string: videoSource), let scheme = url.scheme, !scheme.isEmpty {
        return url
      }
      let path = videoSource
      if FileManager.default.fileExists(atPath: path) {
        return URL(fileURLWithPath: path)
      }
    }

    let bundles = [Bundle.main, Bundle(for: O11A1PlayerView.self)]
    for bundle in bundles {
      if let url = bundle.url(forResource: "BV1NS4t6oEXQ", withExtension: "mp4") {
        return url
      }
    }
    return nil
  }

  private func stopPlayback() {
    guard started else {
      return
    }
    started = false
    engine.stop()
    metalView.isPaused = true
  }

  override func didMoveToWindow() {
    super.didMoveToWindow()
    if window == nil {
      stopPlayback()
    } else {
      applyConfiguration()
    }
  }

  deinit {
    statsTimer?.invalidate()
    statsTimer = nil
    engine.stop()
  }
}
