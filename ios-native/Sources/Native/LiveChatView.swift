import UIKit

final class LiveChatView: UIView {
  private let stack = UIStackView()
  private let spacer = UIView()
  private let maxRows = 7

  override init(frame: CGRect) {
    super.init(frame: frame)
    isUserInteractionEnabled = false
    stack.axis = .vertical
    stack.alignment = .leading
    stack.distribution = .fill
    stack.spacing = 3
    spacer.setContentHuggingPriority(.defaultLow, for: .vertical)
    spacer.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
    stack.addArrangedSubview(spacer)
    addSubview(stack)
    stack.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: leadingAnchor),
      stack.trailingAnchor.constraint(equalTo: trailingAnchor),
      stack.topAnchor.constraint(equalTo: topAnchor),
      stack.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func setMessages(_ messages: [LiveMessage]) {
    stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
    stack.addArrangedSubview(spacer)
    for message in messages.suffix(maxRows) {
      let label = UILabel()
      label.numberOfLines = 1
      label.lineBreakMode = .byTruncatingTail
      let text = NSMutableAttributedString(
        string: message.user + "：",
        attributes: [
          .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
          .foregroundColor: UIColor(red: 0.56, green: 0.78, blue: 1, alpha: 1),
        ]
      )
      text.append(NSAttributedString(
        string: message.text,
        attributes: [
          .font: UIFont.systemFont(ofSize: 11, weight: .regular),
          .foregroundColor: UIColor.white,
        ]
      ))
      label.attributedText = text
      label.layer.shadowColor = UIColor.black.cgColor
      label.layer.shadowOpacity = 0.85
      label.layer.shadowRadius = 2
      label.layer.shadowOffset = .zero
      label.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor).isActive = true
      stack.addArrangedSubview(label)
    }
  }
}
