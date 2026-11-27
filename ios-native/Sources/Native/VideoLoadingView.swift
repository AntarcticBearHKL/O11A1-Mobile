import UIKit

final class VideoLoadingView: UIView {
  private let spinner = UIActivityIndicatorView(style: .medium)
  private let label = UILabel()

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = UIColor.black.withAlphaComponent(0.62)
    layer.cornerRadius = 17
    layer.cornerCurve = .continuous
    clipsToBounds = true
    isHidden = true
    isUserInteractionEnabled = false

    spinner.color = .white
    spinner.hidesWhenStopped = true
    label.font = UIFont.systemFont(ofSize: 11.5, weight: .medium)
    label.textColor = .white
    label.numberOfLines = 1

    let row = UIStackView(arrangedSubviews: [spinner, label])
    row.axis = .horizontal
    row.alignment = .center
    row.spacing = 6
    addSubview(row)
    row.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
      row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
      row.topAnchor.constraint(equalTo: topAnchor),
      row.bottomAnchor.constraint(equalTo: bottomAnchor),
      heightAnchor.constraint(equalToConstant: 34),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func apply(_ status: VideoLoadStatus) {
    guard status.isActive else {
      hide()
      return
    }
    let text: String
    switch status.phase {
    case .connecting:
      text = "正在连接"
    case .buffering:
      text = VideoLoadingView.speedText(status.bytesPerSecond)
    case .playing, .idle:
      hide()
      return
    }
    if isHidden {
      show(text)
    } else {
      setText(text)
    }
  }

  static func speedText(_ bytesPerSecond: Double) -> String {
    guard bytesPerSecond >= 1024 else { return "正在加载" }
    let megabytes = bytesPerSecond / 1_048_576
    if megabytes >= 1 {
      return String(format: "%.1f MB/s", megabytes)
    }
    return String(format: "%.0f KB/s", bytesPerSecond / 1024)
  }

  func show(_ text: String = "正在连接") {
    label.text = text
    isHidden = false
    spinner.startAnimating()
  }

  func setText(_ text: String) {
    guard label.text != text else { return }
    label.text = text
  }

  func hide() {
    isHidden = true
    spinner.stopAnimating()
  }
}
