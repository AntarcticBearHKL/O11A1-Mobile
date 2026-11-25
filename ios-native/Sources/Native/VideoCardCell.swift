import UIKit

final class VideoCardCell: UICollectionViewCell {
  static let reuseID = "VideoCardCell"

  let mediaHost = UIView()
  let coverView = UIImageView()
  private let gradient = CAGradientLayer()
  private let panel = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
  private let titleLabel = UILabel()
  private let ownerLabel = UILabel()
  private let playLabel = UILabel()
  private let timeLabel = UILabel()
  private let avatarButton = UIButton(type: .custom)
  private let avatarImage = UIImageView()
  private let footer = UIStackView()
  private let topLine = UIView()
  private var item: VideoItem?

  var onAvatar: ((VideoItem) -> Void)?

  override init(frame: CGRect) {
    super.init(frame: frame)
    contentView.backgroundColor = .black
    contentView.clipsToBounds = true

    coverView.contentMode = .scaleAspectFill
    coverView.clipsToBounds = true
    coverView.backgroundColor = UIColor(white: 0.10, alpha: 1)
    contentView.addSubview(coverView)
    coverView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      coverView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      coverView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      coverView.topAnchor.constraint(equalTo: contentView.topAnchor),
      coverView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])

    mediaHost.backgroundColor = .clear
    mediaHost.isUserInteractionEnabled = false
    contentView.addSubview(mediaHost)
    mediaHost.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      mediaHost.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      mediaHost.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      mediaHost.topAnchor.constraint(equalTo: contentView.topAnchor),
      mediaHost.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])

    gradient.colors = [
      UIColor.clear.cgColor,
      UIColor.black.withAlphaComponent(0.12).cgColor,
      UIColor.black.withAlphaComponent(0.72).cgColor,
    ]
    gradient.locations = [0.42, 0.66, 1.0]
    contentView.layer.addSublayer(gradient)

    panel.layer.cornerRadius = NativeTheme.cardRadius
    panel.layer.cornerCurve = .continuous
    panel.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
    panel.clipsToBounds = true
    contentView.addSubview(panel)
    panel.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      panel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      panel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      panel.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor, constant: -76),
    ])

    let content = panel.contentView
    topLine.backgroundColor = UIColor.white.withAlphaComponent(0.14)
    content.addSubview(topLine)
    topLine.translatesAutoresizingMaskIntoConstraints = false

    avatarButton.backgroundColor = UIColor.white.withAlphaComponent(0.12)
    avatarButton.layer.cornerRadius = NativeTheme.avatarSize / 2
    avatarButton.clipsToBounds = true
    avatarButton.addTarget(self, action: #selector(tapAvatar), for: .touchUpInside)
    content.addSubview(avatarButton)
    avatarButton.translatesAutoresizingMaskIntoConstraints = false

    avatarImage.contentMode = .scaleAspectFill
    avatarImage.clipsToBounds = true
    avatarImage.isUserInteractionEnabled = false
    avatarButton.addSubview(avatarImage)
    avatarImage.translatesAutoresizingMaskIntoConstraints = false

    titleLabel.font = NativeTheme.titleFont(17)
    titleLabel.textColor = .white
    titleLabel.numberOfLines = 2
    titleLabel.lineBreakMode = .byTruncatingTail
    content.addSubview(titleLabel)
    titleLabel.translatesAutoresizingMaskIntoConstraints = false

    ownerLabel.font = NativeTheme.bodyFont(12)
    ownerLabel.textColor = UIColor.white.withAlphaComponent(0.72)
    ownerLabel.numberOfLines = 1
    content.addSubview(ownerLabel)
    ownerLabel.translatesAutoresizingMaskIntoConstraints = false

    footer.axis = .horizontal
    footer.alignment = .center
    footer.distribution = .fillEqually
    footer.spacing = 8
    content.addSubview(footer)
    footer.translatesAutoresizingMaskIntoConstraints = false

    playLabel.font = NativeTheme.numberFont(12)
    playLabel.textAlignment = .center
    timeLabel.font = NativeTheme.numberFont(12)
    timeLabel.textColor = UIColor.white.withAlphaComponent(0.72)
    timeLabel.textAlignment = .right
    ownerLabel.textAlignment = .left
    footer.addArrangedSubview(ownerLabel)
    footer.addArrangedSubview(playLabel)
    footer.addArrangedSubview(timeLabel)

    NSLayoutConstraint.activate([
      topLine.leadingAnchor.constraint(equalTo: content.leadingAnchor),
      topLine.trailingAnchor.constraint(equalTo: content.trailingAnchor),
      topLine.topAnchor.constraint(equalTo: content.topAnchor),
      topLine.heightAnchor.constraint(equalToConstant: 0.5),

      avatarButton.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 16),
      avatarButton.topAnchor.constraint(equalTo: content.topAnchor, constant: 18),
      avatarButton.widthAnchor.constraint(equalToConstant: NativeTheme.avatarSize),
      avatarButton.heightAnchor.constraint(equalToConstant: NativeTheme.avatarSize),

      avatarImage.leadingAnchor.constraint(equalTo: avatarButton.leadingAnchor),
      avatarImage.trailingAnchor.constraint(equalTo: avatarButton.trailingAnchor),
      avatarImage.topAnchor.constraint(equalTo: avatarButton.topAnchor),
      avatarImage.bottomAnchor.constraint(equalTo: avatarButton.bottomAnchor),

      titleLabel.leadingAnchor.constraint(equalTo: avatarButton.trailingAnchor, constant: 12),
      titleLabel.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -16),
      titleLabel.topAnchor.constraint(equalTo: content.topAnchor, constant: 18),

      footer.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 16),
      footer.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -16),
      footer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
      footer.heightAnchor.constraint(equalToConstant: 20),
      footer.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -14),
    ])

    ownerLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    playLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    timeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    gradient.frame = contentView.bounds
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    item = nil
    coverView.image = nil
    coverView.accessibilityIdentifier = ""
    titleLabel.text = nil
    ownerLabel.text = nil
    playLabel.text = nil
    timeLabel.text = nil
    avatarImage.image = nil
    mediaHost.subviews.forEach { $0.removeFromSuperview() }
    mediaHost.isHidden = false
    onAvatar = nil
  }

  func configure(_ item: VideoItem) {
    self.item = item
    titleLabel.text = item.title
    ownerLabel.text = item.owner
    playLabel.text = item.playText
    playLabel.textColor = NativeTheme.playCountColor(item.play)
    timeLabel.text = item.duration
    ImageLoader.shared.load(item.pic, into: coverView)
    ImageLoader.shared.load(item.ownerFace, into: avatarImage, placeholder: nil)
  }

  func attachPreview(_ view: UIView) {
    mediaHost.subviews.forEach { $0.removeFromSuperview() }
    view.frame = mediaHost.bounds
    view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    mediaHost.addSubview(view)
  }

  func setPreviewVisible(_ visible: Bool) {
    mediaHost.isHidden = !visible
  }

  @objc private func tapAvatar() {
    guard let item = item else { return }
    onAvatar?(item)
  }
}
