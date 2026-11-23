import Foundation
import UIKit
import WebKit

/// Presents Bilibili's official login page and imports the resulting cookies.
final class O11A1WebLogin: NSObject, WKNavigationDelegate {
  private static var active: O11A1WebLogin?
  private static let loginURL = "https://passport.bilibili.com/login"
  private let controller: UIViewController
  private let webView: WKWebView
  private let onImport: (String) -> Void
  private var timer: Timer?
  private var finished = false

  private init(onImport: @escaping (String) -> Void) {
    self.onImport = onImport
    controller = UIViewController()
    let config = WKWebViewConfiguration()
    config.websiteDataStore = .default()
    webView = WKWebView(frame: .zero, configuration: config)
    super.init()

    controller.view.backgroundColor = UIColor(red: 0.043, green: 0.051, blue: 0.071, alpha: 1)
    controller.modalPresentationStyle = .fullScreen

    let bar = UIView()
    bar.translatesAutoresizingMaskIntoConstraints = false
    bar.backgroundColor = UIColor(red: 0.078, green: 0.094, blue: 0.125, alpha: 1)

    let title = UILabel()
    title.translatesAutoresizingMaskIntoConstraints = false
    title.text = "B 站登录"
    title.textColor = UIColor(red: 0.949, green: 0.961, blue: 0.980, alpha: 1)
    title.font = .systemFont(ofSize: 16, weight: .semibold)

    let close = UIButton(type: .system)
    close.translatesAutoresizingMaskIntoConstraints = false
    close.setTitle("关闭", for: .normal)
    close.setTitleColor(UIColor(red: 0.624, green: 0.702, blue: 0.800, alpha: 1), for: .normal)
    close.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
    close.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

    webView.translatesAutoresizingMaskIntoConstraints = false
    webView.navigationDelegate = self
    webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 16_4 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.4 Mobile/15E148 Safari/604.1"
    webView.isOpaque = false
    webView.backgroundColor = controller.view.backgroundColor

    controller.view.addSubview(bar)
    bar.addSubview(title)
    bar.addSubview(close)
    controller.view.addSubview(webView)

    NSLayoutConstraint.activate([
      bar.topAnchor.constraint(equalTo: controller.view.safeAreaLayoutGuide.topAnchor),
      bar.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor),
      bar.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor),
      bar.heightAnchor.constraint(equalToConstant: 48),
      title.leadingAnchor.constraint(equalTo: bar.leadingAnchor, constant: 18),
      title.centerYAnchor.constraint(equalTo: bar.centerYAnchor),
      close.trailingAnchor.constraint(equalTo: bar.trailingAnchor, constant: -14),
      close.centerYAnchor.constraint(equalTo: bar.centerYAnchor),
      webView.topAnchor.constraint(equalTo: bar.bottomAnchor),
      webView.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor),
      webView.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor),
      webView.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor)
    ])

    O11A1WebLogin.clearBilibiliCookies { [weak self] in
      guard let self = self, !self.finished, let url = URL(string: O11A1WebLogin.loginURL) else { return }
      self.webView.load(URLRequest(url: url))
      self.timer?.invalidate()
      self.timer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { [weak self] _ in
        self?.checkCookies()
      }
      self.checkCookies()
    }
  }

  static func present(onImport: @escaping (String) -> Void) {
    guard let top = topViewController() else { return }
    if top.presentedViewController != nil { return }
    let login = O11A1WebLogin(onImport: onImport)
    active = login
    top.present(login.controller, animated: true)
  }

  static func clearBilibiliCookies(completion: (() -> Void)? = nil) {
    let store = WKWebsiteDataStore.default().httpCookieStore
    store.getAllCookies { cookies in
      let relevant = cookies.filter { $0.domain.contains("bilibili.com") }
      guard !relevant.isEmpty else {
        DispatchQueue.main.async { completion?() }
        return
      }
      let group = DispatchGroup()
      for cookie in relevant {
        group.enter()
        store.delete(cookie) { group.leave() }
      }
      group.notify(queue: .main) { completion?() }
    }
  }

  private static func topViewController(_ base: UIViewController? = nil) -> UIViewController? {
    let root: UIViewController?
    if let base = base {
      root = base
    } else {
      root = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap { $0.windows }
        .first { $0.isKeyWindow }?
        .rootViewController
    }
    if let nav = root as? UINavigationController { return topViewController(nav.visibleViewController) }
    if let tab = root as? UITabBarController { return topViewController(tab.selectedViewController) }
    if let presented = root?.presentedViewController { return topViewController(presented) }
    return root
  }

  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    checkCookies()
  }

  private func checkCookies() {
    guard !finished else { return }
    WKWebsiteDataStore.default().httpCookieStore.getAllCookies { [weak self] cookies in
      guard let self = self, !self.finished else { return }
      let relevant = cookies.filter { $0.domain.contains("bilibili.com") }
      let sess = relevant.first { $0.name == "SESSDATA" }?.value ?? ""
      guard !sess.isEmpty,
            relevant.contains(where: { $0.name == "bili_jct" && !$0.value.isEmpty }) else { return }
      let header = relevant.map { "\($0.name)=\($0.value)" }.joined(separator: "; ")
      DispatchQueue.main.async { self.finish(header) }
    }
  }

  private func finish(_ header: String) {
    guard !finished else { return }
    finished = true
    timer?.invalidate()
    timer = nil
    onImport(header)
    O11A1WebLogin.active = nil
    controller.dismiss(animated: true)
  }

  @objc private func closeTapped() {
    finished = true
    timer?.invalidate()
    timer = nil
    O11A1WebLogin.active = nil
    controller.dismiss(animated: true)
  }
}
