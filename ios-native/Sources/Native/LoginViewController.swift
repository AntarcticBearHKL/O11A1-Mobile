import CoreImage
import UIKit

final class LoginViewController: UIViewController {
  var onLogin: (() -> Void)?

  private let qrView = UIImageView()
  private let status = UILabel()
  private let titleLabel = UILabel()
  private let hintLabel = UILabel()
  private let cancelButton = UIButton(type: .system)
  private var key = ""
  private var polling = false
  private var stopped = false

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return traitCollection.userInterfaceStyle == .dark ? .lightContent : .darkContent
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = NativeTheme.background
    modalPresentationStyle = .formSheet

    let card = UIView()
    card.backgroundColor = NativeTheme.background
    card.layer.cornerRadius = NativeTheme.cornerRadius
    card.layer.cornerCurve = .continuous
    view.addSubview(card)
    card.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
      card.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
      card.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
    ])

    titleLabel.text = "扫码登录 B 站"
    titleLabel.font = NativeTheme.titleFont(20)
    titleLabel.textColor = NativeTheme.foreground
    titleLabel.textAlignment = .center
    card.addSubview(titleLabel)

    hintLabel.text = "用 B 站手机客户端扫码\n登录后同步关注、收藏和动态"
    hintLabel.font = NativeTheme.bodyFont(12)
    hintLabel.textColor = NativeTheme.secondary
    hintLabel.textAlignment = .center
    hintLabel.numberOfLines = 0
    card.addSubview(hintLabel)

    qrView.backgroundColor = .white
    qrView.contentMode = .scaleAspectFit
    qrView.layer.cornerRadius = NativeTheme.cornerRadius
    qrView.clipsToBounds = true
    card.addSubview(qrView)

    status.text = "正在生成二维码…"
    status.font = NativeTheme.bodyFont(13)
    status.textColor = NativeTheme.secondary
    status.textAlignment = .center
    status.numberOfLines = 0
    card.addSubview(status)

    cancelButton.setTitle("取消", for: .normal)
    cancelButton.setTitleColor(NativeTheme.accent, for: .normal)
    cancelButton.titleLabel?.font = NativeTheme.bodyFont(14)
    cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
    card.addSubview(cancelButton)

    [titleLabel, hintLabel, qrView, status, cancelButton].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
    }
    NSLayoutConstraint.activate([
      titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
      titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
      titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 24),

      hintLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
      hintLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
      hintLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),

      qrView.centerXAnchor.constraint(equalTo: card.centerXAnchor),
      qrView.topAnchor.constraint(equalTo: hintLabel.bottomAnchor, constant: 16),
      qrView.widthAnchor.constraint(equalToConstant: 240),
      qrView.heightAnchor.constraint(equalToConstant: 240),

      status.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
      status.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
      status.topAnchor.constraint(equalTo: qrView.bottomAnchor, constant: 14),

      cancelButton.centerXAnchor.constraint(equalTo: card.centerXAnchor),
      cancelButton.topAnchor.constraint(equalTo: status.bottomAnchor, constant: 8),
      cancelButton.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18),
      cancelButton.heightAnchor.constraint(equalToConstant: 36),
    ])

    generate()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if #available(iOS 15.0, *) {
      sheetPresentationController?.detents = [.medium(), .large()]
      sheetPresentationController?.prefersGrabberVisible = true
    }
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    stopped = true
  }

  deinit {
    stopped = true
  }

  @objc private func cancel() {
    stopped = true
    dismiss(animated: true)
  }

  private func generate() {
    guard !stopped else { return }
    status.text = "正在生成二维码…"
    BiliAPI.shared.qrGenerate { [weak self] result in
      guard let self = self, !self.stopped else { return }
      switch result {
      case .failure:
        self.status.text = "二维码生成失败，请稍后重试"
      case .success(let value):
        self.key = value.1
        if let image = self.makeQR(value.0) {
          self.qrView.image = image
        }
        self.status.text = "等待扫码"
        self.schedulePoll()
      }
    }
  }

  private func schedulePoll() {
    guard !stopped else { return }
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
      self?.poll()
    }
  }

  private func poll() {
    guard !stopped, !polling, !key.isEmpty else { return }
    polling = true
    BiliAPI.shared.qrPoll(key: key) { [weak self] result in
      guard let self = self else { return }
      self.polling = false
      guard !self.stopped else { return }
      switch result {
      case .failure:
        self.schedulePoll()
      case .success(let json):
        let state = o11a1Int(json["state"])
        if state == 0 {
          self.status.text = "登录成功"
          self.onLogin?()
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.dismiss(animated: true)
          }
        } else if state == 86_101 {
          self.status.text = "等待扫码"
          self.schedulePoll()
        } else if state == 86_090 {
          self.status.text = "已扫码，请在手机上确认"
          self.schedulePoll()
        } else if state == 86_038 {
          self.status.text = "二维码已过期，正在刷新"
          self.key = ""
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.generate()
          }
        } else {
          self.status.text = o11a1String(json["message"]).isEmpty ? "等待扫码" : o11a1String(json["message"])
          self.schedulePoll()
        }
      }
    }
  }

  private func makeQR(_ value: String) -> UIImage? {
    let data = Data(value.utf8)
    guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
    filter.setValue(data, forKey: "inputMessage")
    filter.setValue("M", forKey: "inputCorrectionLevel")
    guard let output = filter.outputImage else { return nil }
    let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
    let context = CIContext()
    guard let cg = context.createCGImage(scaled, from: scaled.extent) else { return nil }
    return UIImage(cgImage: cg)
  }
}
