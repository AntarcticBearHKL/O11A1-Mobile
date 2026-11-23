import Foundation
import UIKit
import WebKit
import QuartzCore

/// Unlocks the WKWebView compositor above 60 Hz on ProMotion devices and exposes
/// the real compositor cadence. rAF itself stays capped by WebKit; CSS scroll and
/// composited transforms can use the full display refresh rate.
final class O11A1HighRefresh {
  static let shared = O11A1HighRefresh()

  private var link: CADisplayLink?
  private var lastTimestamp: CFTimeInterval = 0
  private var deltas: [CFTimeInterval] = []
  private var webViews: [WKWebView] = []
  private var unlocked = false
  private var attempts = 0

  private init() {}

  func enable() {
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      self.attempts += 1
      self.webViews = self.findWebViews(in: self.keyWindow())
      if self.webViews.isEmpty && self.attempts < 40 {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.enable() }
        return
      }
      if !self.webViews.isEmpty { self.attempts = 0 }
      for webView in self.webViews {
        self.flipPreferences(webView)
        self.callPrivateUpdate(webView)
      }
      self.startDisplayLink()
    }
  }

  func compositorFps() -> Double {
    guard !deltas.isEmpty else { return 0 }
    let sum = deltas.reduce(0, +)
    guard sum > 0 else { return 0 }
    return Double(deltas.count) / sum
  }

  func maxHz() -> Int {
    return UIScreen.main.maximumFramesPerSecond
  }

  private func keyWindow() -> UIWindow? {
    return UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }
  }

  private func findWebViews(in view: UIView?) -> [WKWebView] {
    guard let view = view else { return [] }
    var result: [WKWebView] = []
    if let webView = view as? WKWebView { result.append(webView) }
    for child in view.subviews {
      result.append(contentsOf: findWebViews(in: child))
    }
    return result
  }

  private func flipPreferences(_ webView: WKWebView) {
    let preferences = webView.configuration.preferences
    let prefsClass = WKPreferences.self as AnyObject
    let keySelector = NSSelectorFromString("key")
    let collections: [(Selector, Selector)] = [
      (NSSelectorFromString("_features"), NSSelectorFromString("_setEnabled:forFeature:")),
      (NSSelectorFromString("_experimentalFeatures"), NSSelectorFromString("_setEnabled:forExperimentalFeature:")),
      (NSSelectorFromString("_internalDebugFeatures"), NSSelectorFromString("_setEnabled:forInternalDebugFeature:"))
    ]
    for (classSelector, setterSelector) in collections {
      guard prefsClass.responds(to: classSelector),
            preferences.responds(to: setterSelector) else { continue }
      guard let raw = prefsClass.perform(classSelector)?.takeUnretainedValue(),
            let features = raw as? [NSObject] else { continue }
      for feature in features {
        guard feature.responds(to: keySelector),
              let key = feature.perform(keySelector)?.takeUnretainedValue() as? String else { continue }
        let lower = key.lowercased()
        if key == "PreferPageRenderingUpdatesNear60FPSEnabled"
          || lower.contains("60fps")
          || lower.contains("renderingupdatesnear60") {
          _ = (preferences as NSObject).perform(setterSelector, with: NSNumber(value: false), with: feature)
          unlocked = true
        }
      }
    }
  }

  private func callPrivateUpdate(_ webView: WKWebView) {
    let selector = NSSelectorFromString("_updateVisibleContentRects")
    if webView.responds(to: selector) {
      _ = webView.perform(selector)
    }
  }

  private func startDisplayLink() {
    guard link == nil else { return }
    let screenHz = Float(UIScreen.main.maximumFramesPerSecond)
    let displayLink = CADisplayLink(target: self, selector: #selector(tick))
    displayLink.preferredFrameRateRange = CAFrameRateRange(
      minimum: 60,
      maximum: screenHz,
      preferred: screenHz
    )
    displayLink.add(to: .main, forMode: .common)
    link = displayLink
  }

  @objc private func tick() {
    guard let displayLink = link else { return }
    let timestamp = displayLink.timestamp
    if lastTimestamp > 0 {
      let delta = timestamp - lastTimestamp
      if delta > 0 {
        deltas.append(delta)
        if deltas.count > 120 { deltas.removeFirst() }
      }
    }
    lastTimestamp = timestamp
    for webView in webViews {
      callPrivateUpdate(webView)
    }
  }
}
