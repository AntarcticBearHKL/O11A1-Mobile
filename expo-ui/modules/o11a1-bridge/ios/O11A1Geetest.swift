import Foundation
import UIKit
import WebKit

/// Presents only the Geetest challenge, not Bilibili's login page.
final class O11A1Geetest: NSObject, WKScriptMessageHandler {
  private static var active: O11A1Geetest?
  private let controller: UIViewController
  private var webView: WKWebView!
  private let onFinish: ([String: Any]) -> Void
  private var finished = false

  private init(gt: String, challenge: String, onFinish: @escaping ([String: Any]) -> Void) {
    self.onFinish = onFinish
    controller = UIViewController()
    controller.modalPresentationStyle = .fullScreen
    controller.view.backgroundColor = UIColor(red: 0.043, green: 0.051, blue: 0.071, alpha: 1)
    super.init()

    let config = WKWebViewConfiguration()
    config.websiteDataStore = .default()
    let content = WKUserContentController()
    content.add(self, name: "o11a1Geetest")
    config.userContentController = content
    webView = WKWebView(frame: .zero, configuration: config)

    webView.translatesAutoresizingMaskIntoConstraints = false
    webView.isOpaque = false
    webView.backgroundColor = controller.view.backgroundColor
    webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
    controller.view.addSubview(webView)
    NSLayoutConstraint.activate([
      webView.topAnchor.constraint(equalTo: controller.view.topAnchor),
      webView.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor),
      webView.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor),
      webView.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor)
    ])
    let html = O11A1Geetest.html(gt: gt, challenge: challenge)
    webView.loadHTMLString(html, baseURL: URL(string: "https://passport.bilibili.com/login"))
  }

  static func present(gt: String, challenge: String) -> [String: Any] {
    let semaphore = DispatchSemaphore(value: 0)
    var result: [String: Any] = ["ok": false, "cancelled": true, "error": "验证已取消"]
    DispatchQueue.main.async {
      guard let top = topViewController() else {
        result = ["ok": false, "error": "无法打开验证页面"]
        semaphore.signal()
        return
      }
      let geetest = O11A1Geetest(gt: gt, challenge: challenge) { value in
        result = value
        semaphore.signal()
      }
      active = geetest
      top.present(geetest.controller, animated: true)
    }
    if semaphore.wait(timeout: .now() + 900) == .timedOut {
      result = ["ok": false, "cancelled": true, "error": "验证超时"]
      DispatchQueue.main.async {
        active?.controller.dismiss(animated: true)
        active = nil
      }
    }
    return result
  }

  private func finish(_ value: [String: Any]) {
    guard !finished else { return }
    finished = true
    onFinish(value)
    controller.dismiss(animated: true)
    O11A1Geetest.active = nil
  }

  func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
    guard message.name == "o11a1Geetest" else { return }
    let body = message.body as? [String: Any] ?? [:]
    let kind = o11a1String(body["kind"])
    if kind == "complete" {
      finish([
        "ok": true,
        "challenge": o11a1String(body["challenge"]),
        "validate": o11a1String(body["validate"]),
        "seccode": o11a1String(body["seccode"])
      ])
    } else {
      finish(["ok": false, "cancelled": true, "error": "已取消验证"])
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

  private static func html(gt: String, challenge: String) -> String {
    let safeGt = gt.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
    let safeChallenge = challenge.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
    return """
    <!doctype html><html lang="zh-CN"><head><meta charset="utf-8">
    <meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
    <style>
    html,body{margin:0;height:100%;background:#0b0d12;color:#eef3fa;font-family:-apple-system,"Noto Sans SC",sans-serif}
    body{display:flex;align-items:center;justify-content:center;padding:24px;box-sizing:border-box}
    .card{width:100%;max-width:420px;background:#151a22;border:1px solid #2a3342;border-radius:20px;padding:22px 18px 18px;box-sizing:border-box}
    .head{display:flex;align-items:center;justify-content:space-between;gap:12px;margin-bottom:8px}
    h1{font-size:18px;margin:0}.close{width:34px;height:34px;border-radius:50%;border:0;background:#232b38;color:#c8d4e5;font-size:20px}
    p{color:#91a1b8;font-size:13px;line-height:1.6;margin:0 0 14px}
    #captcha{min-height:44px;display:flex;justify-content:center}
    .status{min-height:20px;color:#8ea3bf;font-size:12px;text-align:center;margin-top:10px}
    .status.error{color:#ff8d8d}
    .verify{display:none;width:100%;margin:14px 0 0;border:0;border-radius:12px;background:#00aeec;color:#06131c;font-size:15px;font-weight:700;padding:13px 16px}
    </style></head><body><div class="card">
    <div class="head"><h1>B 站安全验证</h1><button class="close" onclick="cancel()">×</button></div>
    <p>请完成下方验证，验证通过后会发送短信验证码。</p>
    <div id="captcha"></div>
    <button class="verify" id="verify" onclick="verifyCaptcha()">开始安全验证</button>
    <div class="status" id="status">正在加载验证组件…</div>
    </div>
    <script>
    var gt="\(safeGt)";var challenge="\(safeChallenge)";var captcha=null;var finished=false;
    function status(t,e){var n=document.getElementById('status');n.textContent=t||'';n.className='status'+(e?' error':'');}
    function cancel(){if(finished)return;finished=true;window.webkit.messageHandlers.o11a1Geetest.postMessage({kind:'cancel'});}
    function verifyCaptcha(){if(captcha)try{captcha.verify();}catch(e){status(String(e),true);}}
    function complete(r){if(finished)return;if(!r||!r.geetest_validate||!r.geetest_seccode){status('验证结果不完整，请重试',true);return;}finished=true;window.webkit.messageHandlers.o11a1Geetest.postMessage({kind:'complete',challenge:r.geetest_challenge||challenge,validate:r.geetest_validate,seccode:r.geetest_seccode});}
    function boot(){if(!window.initGeetest){status('验证组件加载失败，请检查网络后重试',true);return;}
      initGeetest({gt:gt,challenge:challenge,offline:false,new_captcha:true,product:'bind',lang:'zh-cn',width:'100%'},function(obj){captcha=obj;obj.appendTo('#captcha');obj.onReady(function(){status('请完成滑块验证');document.getElementById('verify').style.display='block';});obj.onSuccess(function(){complete(obj.getValidate());});obj.onError(function(){status('验证失败，请关闭后重新发送',true);});});
    }
    </script>
    <script src="https://static.geetest.com/static/js/gt.0.4.9.js" onload="boot()" onerror="status('验证组件加载失败，请检查网络后重试',true)"></script>
    </body></html>
    """
  }
}
