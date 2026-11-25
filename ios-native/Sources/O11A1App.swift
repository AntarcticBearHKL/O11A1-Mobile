import UIKit
import WebKit
import CoreMotion
import AVFoundation

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let window = UIWindow(frame: UIScreen.main.bounds)
    // The WebView is transparent while a native video is on screen. A light
    // window colour showed as a white flash while closing/dragging the player,
    // so keep the layer behind the page dark.
    window.backgroundColor = .black
    window.rootViewController = O11A1RootController()
    self.window = window
    window.makeKeyAndVisible()
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playback, mode: .moviePlayback, options: [])
      try session.setActive(true)
    } catch {
      print("[O11A1] audio session failed \(error)")
    }
    return true
  }

  func application(
    _ application: UIApplication,
    supportedInterfaceOrientationsFor window: UIWindow?
  ) -> UIInterfaceOrientationMask {
    return .portrait
  }
}

final class O11A1RootController: UIViewController, WKScriptMessageHandler, WKNavigationDelegate {
  private var server: O11A1LocalServer?
  private var webView: WKWebView?
  private var loadingView: UIView?
  private let motion = CMMotionManager()
  private var tiltWatching = false
  private var tiltDirection = 0
  private var tiltCandidate = 0
  private var tiltCandidateAt: CFTimeInterval = 0
  private var savedBrightness: CGFloat?
  private var statusBarStyle: UIStatusBarStyle = .default
  private let launchAvatar = UIImageView()
  private let launchName = UILabel()
  private let launchProgress = UIProgressView(progressViewStyle: .bar)
  private var launchTimer: Timer?
  private var launchFaceTask: URLSessionDataTask?
  private var launchFaceImage: UIImage?
  private var launchHasCredential = false
  private var launchReadyTimer: Timer?
  private var launchTheme = ""

  override var prefersStatusBarHidden: Bool { false }
  override var preferredStatusBarStyle: UIStatusBarStyle { statusBarStyle }
  override var prefersHomeIndicatorAutoHidden: Bool { true }
  override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }

  override func viewDidLoad() {
    super.viewDidLoad()
    /* The WebView is transparent so native video layers can show through.
       Keep the root behind it on the page colour, not black: every transition
       (closing the player, releasing a preview) would otherwise flash black. */
    view.backgroundColor = launchBackground
    UIApplication.shared.isIdleTimerDisabled = true
    O11A1Orientation.apply("portrait")
    showLoading()
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      do {
        let files = try O11A1RootController.loadWebFiles()
        let server = try O11A1LocalServer(files: files)
        try server.start()
        DispatchQueue.main.async {
          guard let self = self else { return }
          self.server = server
          self.installWebView(port: server.port)
        }
      } catch {
        DispatchQueue.main.async {
          self?.showError(error.localizedDescription)
        }
      }
    }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    webView?.frame = view.bounds
    loadingView?.frame = view.bounds
  }

  deinit {
    motion.stopAccelerometerUpdates()
    UIApplication.shared.isIdleTimerDisabled = false
  }

  private static func loadWebFiles() throws -> [String: String] {
    guard let root = Bundle.main.resourceURL?.appendingPathComponent("Web") else {
      throw NSError(domain: "O11A1", code: 1, userInfo: [
        NSLocalizedDescriptionKey: "Web resources missing",
      ])
    }
    var files: [String: String] = [:]
    let keys: [URLResourceKey] = [.isRegularFileKey]
    guard let enumerator = FileManager.default.enumerator(
      at: root,
      includingPropertiesForKeys: keys,
      options: [.skipsHiddenFiles]
    ) else {
      throw NSError(domain: "O11A1", code: 2, userInfo: [
        NSLocalizedDescriptionKey: "Web resources unreadable",
      ])
    }
    let prefix = root.path + "/"
    for case let url as URL in enumerator {
      guard (try? url.resourceValues(forKeys: Set(keys)))?.isRegularFile == true else { continue }
      let key = url.path.replacingOccurrences(of: prefix, with: "")
      files[key] = try String(contentsOf: url, encoding: .utf8)
    }
    guard files["index.html"] != nil else {
      throw NSError(domain: "O11A1", code: 3, userInfo: [
        NSLocalizedDescriptionKey: "index.html missing",
      ])
    }
    return files
  }

  private func installWebView(port: Int) {
    NSLog("[O11A1] local origin 127.0.0.1:%d", port)
    let config = WKWebViewConfiguration()
    config.websiteDataStore = .default()
    config.allowsInlineMediaPlayback = true
    config.mediaTypesRequiringUserActionForPlayback = []
    config.preferences.javaScriptCanOpenWindowsAutomatically = false

    let controller = WKUserContentController()
    controller.add(self, name: "o11a1")
    controller.add(self, name: "o11a1player")
    let savedPrefs = UserDefaults.standard.string(forKey: "o11a1.webPrefs") ?? ""
    let themeSetting = UserDefaults.standard.string(forKey: "o11a1.theme.setting") ?? ""
    let themeFallback = UserDefaults.standard.string(forKey: "o11a1.theme") ?? ""
    let prefsScript = """
    window.__O11A1_THEME_SETTING__ = \(jsonString(themeSetting));
    window.__O11A1_THEME_FALLBACK__ = \(jsonString(themeFallback));
    (function () {
      try {
        var saved = \(jsonString(savedPrefs));
        if (!saved || saved.length < 2) return;
        window.__O11A1_SAVED_PREFS__ = saved;
        var key = 'o11a1.v2.prototype';
        var current = null;
        try { current = JSON.parse(localStorage.getItem(key) || 'null'); } catch (e) {}
        var next = null;
        try { next = JSON.parse(saved); } catch (e) { return; }
        if (!next) return;
        var nextAt = Number(next.savedAt || 0);
        var currentAt = current ? Number(current.savedAt || 0) : -1;
        if (!current || nextAt >= currentAt) localStorage.setItem(key, saved);
      } catch (e) {}
    })();
    """
    controller.addUserScript(WKUserScript(
      source: prefsScript,
      injectionTime: .atDocumentStart,
      forMainFrameOnly: true
    ))
    let bootstrap = """
    (function () {
      window.ReactNativeWebView = {
        postMessage: function (message) {
          try { window.webkit.messageHandlers.o11a1.postMessage(String(message)); } catch (error) {}
        }
      };
      window.O11A1PlayerNative = {
        rect: function (slot, x, y, w, h, visible, rotation, vy, ts, aspect) {
          try {
            window.webkit.messageHandlers.o11a1player.postMessage({
              type: "rect", slot: String(slot),
              x: Number(x), y: Number(y), w: Number(w), h: Number(h),
              visible: visible ? 1 : 0, rotation: Number(rotation) || 0,
              vy: Number(vy) || 0, ts: Number(ts) || 0,
              aspect: String(aspect || "")
            });
          } catch (error) {}
        },
        layer: function (slot, background) {
          try {
            window.webkit.messageHandlers.o11a1player.postMessage({
              type: "layer", slot: String(slot), background: background ? 1 : 0
            });
          } catch (error) {}
        },
        control: function (slot, action, value) {
          try {
            window.webkit.messageHandlers.o11a1player.postMessage({
              type: "control", slot: String(slot), action: String(action), value: Number(value) || 0
            });
          } catch (error) {}
        }
      };
    })();
    """
    controller.addUserScript(WKUserScript(
      source: bootstrap,
      injectionTime: .atDocumentStart,
      forMainFrameOnly: true
    ))
    if let bridge = bridgeScript(port: port) {
      controller.addUserScript(WKUserScript(
        source: bridge,
        injectionTime: .atDocumentStart,
        forMainFrameOnly: true
      ))
    }
    config.userContentController = controller

    let web = WKWebView(frame: view.bounds, configuration: config)
    web.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    web.isOpaque = false
    web.backgroundColor = .clear
    web.scrollView.backgroundColor = .clear
    web.scrollView.contentInsetAdjustmentBehavior = .never
    web.scrollView.isScrollEnabled = false
    web.scrollView.bounces = false
    if #available(iOS 16.4, *) {
      web.isInspectable = true
    }
    web.navigationDelegate = self
    view.addSubview(web)
    if let loading = loadingView {
      view.bringSubviewToFront(loading)
    }
    webView = web
    guard let url = URL(string: "http://127.0.0.1:\(port)/index.html") else {
      showError("invalid local url")
      return
    }
    web.load(URLRequest(url: url))
    O11A1HighRefresh.shared.enable()
  }

  private func bridgeScript(port: Int) -> String? {
    guard let url = Bundle.main.url(forResource: "bridge", withExtension: "js"),
          var source = try? String(contentsOf: url, encoding: .utf8) else { return nil }
    let flow = ProcessInfo.processInfo.environment["O11A1_TEST_FLOW"] ?? ""
    source = source.replacingOccurrences(of: "__PORT__", with: String(port))
    source = source.replacingOccurrences(of: "__TEST_FLOW__", with: jsonString(flow))
    return source
  }

  private func jsonString(_ value: String) -> String {
    guard let data = try? JSONSerialization.data(withJSONObject: [value]),
          let text = String(data: data, encoding: .utf8),
          text.count >= 2 else { return "\"\"" }
    return String(text.dropFirst().dropLast())
  }

  private func resolvedLaunchTheme() -> String {
    if launchTheme == "dark" || launchTheme == "light" { return launchTheme }
    let saved = UserDefaults.standard.string(forKey: "o11a1.theme") ?? ""
    if saved == "dark" || saved == "light" { return saved }
    return traitCollection.userInterfaceStyle == .dark ? "dark" : "light"
  }

  private var launchBackground: UIColor {
    if resolvedLaunchTheme() == "dark" {
      return UIColor(red: 0.059, green: 0.063, blue: 0.075, alpha: 1)
    }
    return UIColor(red: 0.953, green: 0.937, blue: 0.906, alpha: 1)
  }

  private func applyLaunchChrome() {
    statusBarStyle = resolvedLaunchTheme() == "dark" ? .lightContent : .darkContent
    setNeedsStatusBarAppearanceUpdate()
    loadingView?.backgroundColor = launchBackground
    view.backgroundColor = launchBackground
  }

  private var launchFaceCacheURL: URL {
    let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    return base.appendingPathComponent("o11a1-launch-face.img")
  }

  private func cachedLaunchFace(for face: String) -> UIImage? {
    guard !face.isEmpty else { return nil }
    let cached = UserDefaults.standard.string(forKey: "o11a1.user.face.cached") ?? ""
    if cached == face, let image = UIImage(contentsOfFile: launchFaceCacheURL.path) {
      return image
    }
    if let url = URL(string: face),
       let response = URLCache.shared.cachedResponse(for: URLRequest(url: url)),
       let image = UIImage(data: response.data) {
      storeLaunchFace(image, for: face)
      return image
    }
    return nil
  }

  private func storeLaunchFace(_ image: UIImage, for face: String) {
    guard !face.isEmpty, let data = image.jpegData(compressionQuality: 0.9) else { return }
    try? data.write(to: launchFaceCacheURL, options: .atomic)
    UserDefaults.standard.set(face, forKey: "o11a1.user.face.cached")
  }

  private func clearLaunchFaceCache() {
    try? FileManager.default.removeItem(at: launchFaceCacheURL)
    UserDefaults.standard.removeObject(forKey: "o11a1.user.face.cached")
  }

  private func launchPrefsSnapshot() -> (loggedIn: Bool?, name: String, face: String) {
    let defaults = UserDefaults.standard
    var name = defaults.string(forKey: "o11a1.user.name") ?? ""
    var face = defaults.string(forKey: "o11a1.user.face") ?? ""
    var loggedIn: Bool?
    if let raw = defaults.string(forKey: "o11a1.webPrefs"),
       let data = raw.data(using: .utf8),
       let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] {
      if let flag = object["loggedIn"] as? Bool { loggedIn = flag }
      if name.isEmpty, let value = object["userName"] as? String { name = value }
      if face.isEmpty, let value = object["userFace"] as? String { face = value }
    }
    return (loggedIn, name, face)
  }

  private func loadLaunchIdentity() {
    let snapshot = launchPrefsSnapshot()
    let name = snapshot.name
    launchName.text = name.isEmpty ? "正在进入" : name
    let face = snapshot.face
    let hasCredential = snapshot.loggedIn ?? (!face.isEmpty || !name.isEmpty)
    launchHasCredential = hasCredential
    launchFaceTask?.cancel()
    launchFaceTask = nil
    guard hasCredential else {
      launchFaceImage = nil
      launchAvatar.image = nil
      launchAvatar.tintColor = nil
      launchAvatar.backgroundColor = .clear
      return
    }
    if let cached = cachedLaunchFace(for: face) {
      launchFaceImage = cached
      applyLaunchFace(animated: false)
    } else {
      launchFaceImage = nil
      applyLaunchFace(animated: false)
      if !face.isEmpty { downloadLaunchFace(face) }
    }
  }

  private func downloadLaunchFace(_ face: String) {
    guard let url = URL(string: face) else { return }
    launchFaceTask?.cancel()
    launchFaceTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
      guard let self = self, let data = data, let image = UIImage(data: data) else { return }
      DispatchQueue.main.async {
        self.launchFaceImage = image
        self.storeLaunchFace(image, for: face)
        if self.loadingView != nil { self.applyLaunchFace(animated: true) }
      }
    }
    launchFaceTask?.resume()
  }

  private func precacheLaunchFace(_ face: String) {
    guard !face.isEmpty else {
      clearLaunchFaceCache()
      return
    }
    if cachedLaunchFace(for: face) != nil { return }
    guard let url = URL(string: face) else { return }
    URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
      guard let self = self, let data = data, let image = UIImage(data: data) else { return }
      DispatchQueue.main.async { self.storeLaunchFace(image, for: face) }
    }.resume()
  }

  private func applyLaunchFace(animated: Bool = false) {
    guard launchHasCredential else { return }
    let update = {
      if let image = self.launchFaceImage {
        self.launchAvatar.image = image
        self.launchAvatar.tintColor = nil
        self.launchAvatar.backgroundColor = .secondarySystemBackground
      } else {
        self.launchAvatar.image = UIImage(systemName: "person.fill")
        self.launchAvatar.tintColor = .secondaryLabel
        self.launchAvatar.backgroundColor = .secondarySystemBackground
      }
    }
    if animated, launchAvatar.window != nil {
      UIView.transition(
        with: launchAvatar,
        duration: 0.22,
        options: [.transitionCrossDissolve, .allowUserInteraction],
        animations: update
      )
    } else {
      update()
    }
  }

  private func showLoading() {
    loadLaunchIdentity()
    guard launchHasCredential else { return }

    let holder = UIView(frame: view.bounds)
    holder.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    holder.backgroundColor = launchBackground

    let avatar = launchAvatar
    avatar.removeFromSuperview()
    avatar.translatesAutoresizingMaskIntoConstraints = false
    avatar.contentMode = .scaleAspectFill
    avatar.clipsToBounds = true
    avatar.layer.cornerRadius = 43
    avatar.layer.cornerCurve = .continuous
    avatar.layer.borderWidth = 1
    avatar.layer.borderColor = UIColor.separator.cgColor
    avatar.backgroundColor = .secondarySystemBackground

    let name = launchName
    name.removeFromSuperview()
    name.translatesAutoresizingMaskIntoConstraints = false
    name.font = .systemFont(ofSize: 15, weight: .semibold)
    name.textColor = .label
    name.textAlignment = .center

    let progress = launchProgress
    progress.removeFromSuperview()
    progress.translatesAutoresizingMaskIntoConstraints = false
    progress.progressTintColor = UIColor(red: 0.184, green: 0.486, blue: 0.965, alpha: 1)
    progress.trackTintColor = .separator
    progress.progress = 0.06
    progress.transform = CGAffineTransform(scaleX: 1, y: 1.7)

    holder.addSubview(avatar)
    holder.addSubview(name)
    holder.addSubview(progress)
    NSLayoutConstraint.activate([
      avatar.widthAnchor.constraint(equalToConstant: 86),
      avatar.heightAnchor.constraint(equalToConstant: 86),
      avatar.centerXAnchor.constraint(equalTo: holder.centerXAnchor),
      avatar.centerYAnchor.constraint(equalTo: holder.centerYAnchor, constant: -34),
      name.topAnchor.constraint(equalTo: avatar.bottomAnchor, constant: 16),
      name.centerXAnchor.constraint(equalTo: holder.centerXAnchor),
      name.leadingAnchor.constraint(greaterThanOrEqualTo: holder.leadingAnchor, constant: 32),
      progress.topAnchor.constraint(equalTo: name.bottomAnchor, constant: 18),
      progress.centerXAnchor.constraint(equalTo: holder.centerXAnchor),
      progress.widthAnchor.constraint(equalToConstant: 136),
    ])
    view.addSubview(holder)
    loadingView = holder
    applyLaunchChrome()
    launchTimer?.invalidate()
    launchTimer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { [weak self] _ in
      guard let self = self, self.loadingView != nil else { return }
      self.launchProgress.setProgress(min(0.9, self.launchProgress.progress + 0.045), animated: true)
    }
  }

  private func hideLoading() {
    launchTimer?.invalidate()
    launchTimer = nil
    launchReadyTimer?.invalidate()
    launchReadyTimer = nil
    launchFaceTask?.cancel()
    launchFaceTask = nil
    guard let holder = loadingView else { return }
    loadingView = nil
    launchProgress.setProgress(1, animated: true)
    UIView.animate(withDuration: 0.2, animations: {
      holder.alpha = 0
    }, completion: { _ in
      holder.removeFromSuperview()
    })
  }

  private func showError(_ message: String) {
    hideLoading()
    webView?.removeFromSuperview()
    webView = nil
    let label = UILabel(frame: view.bounds.insetBy(dx: 32, dy: 32))
    label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    label.numberOfLines = 0
    label.textAlignment = .center
    label.textColor = UIColor(red: 0.54, green: 0.23, blue: 0.19, alpha: 1)
    label.font = UIFont.systemFont(ofSize: 13)
    label.text = "O11A1\n\n\(message)"
    view.addSubview(label)
  }

  // MARK: - WKScriptMessageHandler

  func userContentController(
    _ userContentController: WKUserContentController,
    didReceive message: WKScriptMessage
  ) {
    if message.name == "o11a1player" {
      guard let body = message.body as? [String: Any],
            let type = body["type"] as? String else { return }
      let slot = body["slot"] as? String ?? "main"
      switch type {
      case "rect":
        O11A1PlayerHost.shared.rect(
          slot: slot,
          x: (body["x"] as? NSNumber)?.doubleValue ?? 0,
          y: (body["y"] as? NSNumber)?.doubleValue ?? 0,
          width: (body["w"] as? NSNumber)?.doubleValue ?? 0,
          height: (body["h"] as? NSNumber)?.doubleValue ?? 0,
          visible: ((body["visible"] as? NSNumber)?.intValue ?? 0) != 0,
          rotation: (body["rotation"] as? NSNumber)?.doubleValue ?? 0,
          velocity: (body["vy"] as? NSNumber)?.doubleValue ?? 0,
          timestamp: (body["ts"] as? NSNumber)?.doubleValue ?? 0,
          aspect: body["aspect"] as? String ?? ""
        )
      case "layer":
        O11A1PlayerHost.shared.layer(
          slot: slot,
          background: ((body["background"] as? NSNumber)?.intValue ?? 0) != 0
        )
      case "control":
        O11A1PlayerHost.shared.control(
          slot: slot,
          action: body["action"] as? String ?? "",
          value: (body["value"] as? NSNumber)?.doubleValue ?? 0
        )
      default:
        break
      }
      return
    }
    guard message.name == "o11a1", let body = message.body as? String,
          let data = body.data(using: .utf8),
          let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
          let type = object["type"] as? String else { return }
    switch type {
    case "tilt-watch":
      let on: Bool
      if let flag = object["on"] as? Bool { on = flag }
      else if let number = object["on"] as? NSNumber { on = number.boolValue }
      else { on = false }
      setTiltWatching(on)
    case "brightness":
      if savedBrightness == nil { savedBrightness = UIScreen.main.brightness }
      var percent = 100.0
      if let number = object["value"] as? NSNumber { percent = number.doubleValue }
      else if let text = object["value"] as? String, let parsed = Double(text) { percent = parsed }
      UIScreen.main.brightness = CGFloat(max(0.02, min(1, percent / 100)))
    case "brightness-restore":
      if let saved = savedBrightness {
        UIScreen.main.brightness = saved
        savedBrightness = nil
      }
    case "haptic":
      let style = object["style"] as? String ?? "light"
      let feedback: UIImpactFeedbackGenerator.FeedbackStyle
      switch style {
      case "medium": feedback = .medium
      case "heavy": feedback = .heavy
      default: feedback = .light
      }
      let generator = UIImpactFeedbackGenerator(style: feedback)
      generator.prepare()
      generator.impactOccurred()
    case "launchReady":
      hideLoading()
    case "prefs":
      if let data = object["data"] as? String, data.count > 2 {
        UserDefaults.standard.set(data, forKey: "o11a1.webPrefs")
      }
    case "user":
      let defaults = UserDefaults.standard
      let face = object["face"] as? String ?? ""
      defaults.set(face, forKey: "o11a1.user.face")
      defaults.set(object["name"] as? String ?? "", forKey: "o11a1.user.name")
      if loadingView != nil {
        loadLaunchIdentity()
      } else {
        precacheLaunchFace(face)
      }
    case "theme":
      let theme = object["theme"] as? String == "dark" ? "dark" : "light"
      let setting = object["setting"] as? String ?? ""
      launchTheme = theme
      let defaults = UserDefaults.standard
      defaults.set(theme, forKey: "o11a1.theme")
      if setting == "浅色" || setting == "深色" || setting == "跟随系统" {
        defaults.set(setting, forKey: "o11a1.theme.setting")
      }
      if loadingView != nil { applyLaunchChrome() }
    case "statusbar":
      let tone = object["style"] as? String == "light" ? "light" : "dark"
      let next: UIStatusBarStyle = tone == "light" ? .lightContent : .darkContent
      if next != statusBarStyle {
        statusBarStyle = next
        NSLog("[O11A1] statusbar %@", tone)
        setNeedsStatusBarAppearanceUpdate()
      }
    case "orientation":
      O11A1Orientation.apply(object["mode"] as? String ?? "portrait")
    default:
      break
    }
  }

  private func setTiltWatching(_ on: Bool) {
    guard on != tiltWatching else { return }
    tiltWatching = on
    NSLog("[O11A1] tilt watch %@", on ? "on" : "off")
    if on {
      guard motion.isAccelerometerAvailable else { return }
      motion.accelerometerUpdateInterval = 0.12
      motion.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
        guard let self = self, self.tiltWatching,
              let acceleration = data?.acceleration else { return }
        let x = acceleration.x
        let y = acceleration.y
        let planar = sqrt(x * x + y * y)
        // Nearly flat on a table: gravity is mostly on z, so the roll is
        // ambiguous. Keep the current orientation instead of flapping.
        guard planar >= 0.32 else {
          self.tiltCandidate = 0
          return
        }
        // Project gravity onto the screen plane. This measures the roll even
        // when the phone is tilted forward/back, unlike a raw x threshold.
        let angle = atan2(x, abs(y)) * 180 / .pi
        let magnitude = abs(angle)
        var next = self.tiltDirection
        if magnitude >= 48 {
          next = x > 0 ? -1 : 1
        } else if magnitude <= 30 {
          next = 0
        } else {
          // Hysteresis band: do not flip back and forth around 45 degrees.
          self.tiltCandidate = 0
          return
        }
        if next == self.tiltDirection {
          self.tiltCandidate = 0
          return
        }
        let now = CACurrentMediaTime()
        if self.tiltCandidate != next {
          self.tiltCandidate = next
          self.tiltCandidateAt = now
          return
        }
        // Require the new orientation to be stable for ~220ms.
        guard now - self.tiltCandidateAt >= 0.22 else { return }
        self.tiltDirection = next
        self.tiltCandidate = 0
        NSLog("[O11A1] tilt dir %d", next)
        self.webView?.evaluateJavaScript(
          "window.O11A1Host&&window.O11A1Host.setTiltDir(\(next));true;",
          completionHandler: nil
        )
      }
      webView?.evaluateJavaScript("window.__O11A1_NATIVE_TILT=true;true;", completionHandler: nil)
    } else {
      motion.stopAccelerometerUpdates()
      tiltDirection = 0
      tiltCandidate = 0
      webView?.evaluateJavaScript("window.__O11A1_NATIVE_TILT=false;true;", completionHandler: nil)
    }
  }

  // MARK: - WKNavigationDelegate

  func webView(
    _ webView: WKWebView,
    decidePolicyFor navigationAction: WKNavigationAction,
    decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
  ) {
    guard let url = navigationAction.request.url,
          let scheme = url.scheme?.lowercased() else {
      decisionHandler(.allow)
      return
    }
    if scheme == "http" || scheme == "https" {
      decisionHandler(url.host == "127.0.0.1" ? .allow : .cancel)
      return
    }
    decisionHandler(.allow)
  }

  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    print("[O11A1] page finished")
    guard loadingView != nil, launchHasCredential else {
      hideLoading()
      return
    }
    /* The web app reports launchReady once the first feed cards are painted.
       Keep the avatar + progress visible until then so there is only one
       launch surface, with a fallback in case that message never arrives. */
    launchReadyTimer?.invalidate()
    launchReadyTimer = Timer.scheduledTimer(withTimeInterval: 2.8, repeats: false) { [weak self] _ in
      self?.hideLoading()
    }
  }

  func webView(
    _ webView: WKWebView,
    didFail navigation: WKNavigation!,
    withError error: Error
  ) {
    print("[O11A1] navigation failed \(error.localizedDescription)")
    showError("页面加载失败\n\(error.localizedDescription)")
  }

  func webView(
    _ webView: WKWebView,
    didFailProvisionalNavigation navigation: WKNavigation!,
    withError error: Error
  ) {
    print("[O11A1] provisional navigation failed \(error.localizedDescription)")
    showError("页面加载失败\n\(error.localizedDescription)")
  }
}
