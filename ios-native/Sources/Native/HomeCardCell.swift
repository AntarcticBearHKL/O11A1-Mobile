import UIKit

/// Home feed card matching the original web layout: full-width 16:9 cover
/// with a glass information row below it and 14pt bottom corners.
final class HomeCardCell: UITableViewCell {
  static let reuseID = "HomeCardCell"

  let mediaHost = UIView()
  var onOpen: (() -> Void)?
  var onAvatar: (() -> Void)?

  private let cover = UIImageView()
  private let duration = UILabel()
  private let live = UILabel()
  private let progressTrack = UIView()
  private let progressFill = UIView()
  private var progressWidth: NSLayoutConstraint?
  private let copyGradient = CAGradientLayer()
  private let avatar = UIImageView()
  private let avatarButton = UIButton(type: .custom)
  private let title = UILabel()
  private let owner = UILabel()
  private let play = UILabel()
  private let time = UILabel()
  private let copyView = UIView()
  private var item: VideoItem?

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    contentView.clipsToBounds = false
    clipsToBounds = false
    selectionStyle = .none
    contentView.layer.shadowColor = UIColor.black.cgColor
    contentView.layer.shadowOpacity = 0.10
    contentView.layer.shadowRadius = 15
    contentView.layer.shadowOffset = CGSize(width: 0, height: 12)

    let media = UIView()
    media.clipsToBounds = true
    media.backgroundColor = UIColor { trait in
      trait.userInterfaceStyle == .dark
        ? UIColor(red: 26.0 / 255.0, green: 32.0 / 255.0, blue: 42.0 / 255.0, alpha: 1)
        : UIColor(red: 228.0 / 255.0, green: 231.0 / 255.0, blue: 236.0 / 255.0, alpha: 1)
    }
    contentView.addSubview(media)
    media.translatesAutoresizingMaskIntoConstraints = false

    cover.contentMode = .scaleAspectFill
    cover.clipsToBounds = true
    cover.backgroundColor = UIColor { trait in
      trait.userInterfaceStyle == .dark
        ? UIColor(red: 26.0 / 255.0, green: 32.0 / 255.0, blue: 42.0 / 255.0, alpha: 1)
        : UIColor(red: 228.0 / 255.0, green: 231.0 / 255.0, blue: 236.0 / 255.0, alpha: 1)
    }
    media.addSubview(cover)
    cover.translatesAutoresizingMaskIntoConstraints = false

    mediaHost.backgroundColor = .clear
    mediaHost.isUserInteractionEnabled = false
    media.addSubview(mediaHost)
    mediaHost.translatesAutoresizingMaskIntoConstraints = false

    duration.font = NativeTheme.numberFont(11)
    duration.textColor = .white
    duration.textAlignment = .center
    duration.backgroundColor = UIColor.black.withAlphaComponent(0.78)
    duration.layer.cornerRadius = 5
    duration.clipsToBounds = true
    media.addSubview(duration)
    duration.translatesAutoresizingMaskIntoConstraints = false

    live.text = "LIVE"
    live.font = NativeTheme.titleFont(10)
    live.textColor = .white
    live.textAlignment = .center
    live.backgroundColor = UIColor(red: 0.90, green: 0.24, blue: 0.24, alpha: 1)
    live.layer.cornerRadius = 5
    live.clipsToBounds = true
    media.addSubview(live)
    live.translatesAutoresizingMaskIntoConstraints = false

    progressTrack.backgroundColor = UIColor.white.withAlphaComponent(0.28)
    media.addSubview(progressTrack)
    progressTrack.translatesAutoresizingMaskIntoConstraints = false
    progressFill.backgroundColor = UIColor(red: 1, green: 45.0 / 255.0, blue: 45.0 / 255.0, alpha: 1)
    progressTrack.addSubview(progressFill)
    progressFill.translatesAutoresizingMaskIntoConstraints = false

    copyView.backgroundColor = .clear
    copyView.layer.cornerRadius = 14
    copyView.layer.cornerCurve = .continuous
    copyView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
    copyView.layer.insertSublayer(copyGradient, at: 0)
    copyGradient.colors = [NativeTheme.homeRowTop.cgColor,
                           NativeTheme.homeRowBottom.cgColor]
    copyGradient.locations = [0, 1]
    contentView.addSubview(copyView)
    copyView.translatesAutoresizingMaskIntoConstraints = false

    let topLine = UIView()
    topLine.backgroundColor = NativeTheme.homeRowLine
    copyView.addSubview(topLine)
    topLine.translatesAutoresizingMaskIntoConstraints = false

    avatar.contentMode = .scaleAspectFill
    avatar.clipsToBounds = true
    avatar.layer.cornerRadius = 25
    avatar.backgroundColor = UIColor(white: 0.90, alpha: 1)
    copyView.addSubview(avatar)
    avatar.translatesAutoresizingMaskIntoConstraints = false

    avatarButton.backgroundColor = .clear
    avatarButton.addTarget(self, action: #selector(tapAvatar), for: .touchUpInside)
    copyView.addSubview(avatarButton)
    avatarButton.translatesAutoresizingMaskIntoConstraints = false

    title.font = UIFont.systemFont(ofSize: 16, weight: .bold)
    title.textColor = NativeTheme.foreground
    title.numberOfLines = 2
    title.lineBreakMode = .byTruncatingTail
    copyView.addSubview(title)
    title.translatesAutoresizingMaskIntoConstraints = false

    owner.font = UIFont.systemFont(ofSize: 12, weight: .medium)
    owner.textColor = NativeTheme.secondary
    owner.numberOfLines = 1
    owner.lineBreakMode = .byTruncatingTail
    play.font = UIFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
    play.textAlignment = .center
    play.numberOfLines = 1
    time.font = UIFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
    time.textColor = NativeTheme.tertiary
    time.textAlignment = .right
    time.numberOfLines = 1

    let meta = UIStackView(arrangedSubviews: [owner, play, time])
    meta.axis = .horizontal
    meta.distribution = .fillEqually
    meta.alignment = .center
    meta.spacing = 0
    copyView.addSubview(meta)
    meta.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      media.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      media.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      media.topAnchor.constraint(equalTo: contentView.topAnchor),
      media.heightAnchor.constraint(equalTo: media.widthAnchor, multiplier: 9.0 / 16.0),

      cover.leadingAnchor.constraint(equalTo: media.leadingAnchor),
      cover.trailingAnchor.constraint(equalTo: media.trailingAnchor),
      cover.topAnchor.constraint(equalTo: media.topAnchor),
      cover.bottomAnchor.constraint(equalTo: media.bottomAnchor),

      mediaHost.leadingAnchor.constraint(equalTo: media.leadingAnchor),
      mediaHost.trailingAnchor.constraint(equalTo: media.trailingAnchor),
      mediaHost.topAnchor.constraint(equalTo: media.topAnchor),
      mediaHost.bottomAnchor.constraint(equalTo: media.bottomAnchor),

      live.leadingAnchor.constraint(equalTo: media.leadingAnchor, constant: 8),
      live.topAnchor.constraint(equalTo: media.topAnchor, constant: 8),
      live.widthAnchor.constraint(greaterThanOrEqualToConstant: 36),
      live.heightAnchor.constraint(equalToConstant: 18),

      duration.trailingAnchor.constraint(equalTo: media.trailingAnchor, constant: -8),
      duration.bottomAnchor.constraint(equalTo: media.bottomAnchor, constant: -8),
      duration.widthAnchor.constraint(greaterThanOrEqualToConstant: 38),
      duration.heightAnchor.constraint(equalToConstant: 18),

      progressTrack.leadingAnchor.constraint(equalTo: media.leadingAnchor),
      progressTrack.trailingAnchor.constraint(equalTo: media.trailingAnchor),
      progressTrack.bottomAnchor.constraint(equalTo: media.bottomAnchor),
      progressTrack.heightAnchor.constraint(equalToConstant: 3),
      progressFill.leadingAnchor.constraint(equalTo: progressTrack.leadingAnchor),
      progressFill.topAnchor.constraint(equalTo: progressTrack.topAnchor),
      progressFill.bottomAnchor.constraint(equalTo: progressTrack.bottomAnchor),

      copyView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      copyView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      copyView.topAnchor.constraint(equalTo: media.bottomAnchor),
      copyView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -14),

      topLine.leadingAnchor.constraint(equalTo: copyView.leadingAnchor),
      topLine.trailingAnchor.constraint(equalTo: copyView.trailingAnchor),
      topLine.topAnchor.constraint(equalTo: copyView.topAnchor),
      topLine.heightAnchor.constraint(equalToConstant: 0.5),

      avatar.leadingAnchor.constraint(equalTo: copyView.leadingAnchor, constant: 16),
      avatar.centerYAnchor.constraint(equalTo: copyView.centerYAnchor),
      avatar.widthAnchor.constraint(equalToConstant: 50),
      avatar.heightAnchor.constraint(equalToConstant: 50),

      avatarButton.leadingAnchor.constraint(equalTo: avatar.leadingAnchor),
      avatarButton.trailingAnchor.constraint(equalTo: avatar.trailingAnchor),
      avatarButton.topAnchor.constraint(equalTo: avatar.topAnchor),
      avatarButton.bottomAnchor.constraint(equalTo: avatar.bottomAnchor),

      title.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 12),
      title.trailingAnchor.constraint(equalTo: copyView.trailingAnchor, constant: -16),
      title.topAnchor.constraint(equalTo: copyView.topAnchor, constant: 13),

      meta.leadingAnchor.constraint(equalTo: title.leadingAnchor),
      meta.trailingAnchor.constraint(equalTo: title.trailingAnchor),
      meta.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 5),
      meta.bottomAnchor.constraint(equalTo: copyView.bottomAnchor, constant: -16),
    ])
    progressWidth = progressFill.widthAnchor.constraint(equalToConstant: 0)
    progressWidth?.isActive = true

    contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapCard(_:))))
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    copyGradient.frame = copyView.bounds
    let shadowRect = contentView.bounds
    contentView.layer.shadowPath = UIBezierPath(
      roundedRect: shadowRect,
      byRoundingCorners: [.bottomLeft, .bottomRight],
      cornerRadii: CGSize(width: 14, height: 14)).cgPath
    contentView.layer.shadowOpacity =
      traitCollection.userInterfaceStyle == .dark ? 0.38 : 0.10
    CATransaction.commit()
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    copyGradient.colors = [NativeTheme.homeRowTop.cgColor,
                           NativeTheme.homeRowBottom.cgColor]
    contentView.layer.shadowOpacity =
      traitCollection.userInterfaceStyle == .dark ? 0.38 : 0.10
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    item = nil
    cover.image = nil
    avatar.image = nil
    mediaHost.subviews.forEach { $0.removeFromSuperview() }
    onOpen = nil
    onAvatar = nil
  }

  func configure(_ item: VideoItem) {
    self.item = item
    title.text = item.title
    owner.text = item.owner
    play.text = item.playText.isEmpty ? "" : item.playText + "播放"
    play.textColor = NativeTheme.playCountColor(item.play)
    time.text = NativeTheme.freshness(item.pubdate)
    time.textColor = NativeTheme.freshnessColor(item.pubdate)
    duration.text = item.duration
    duration.isHidden = item.roomId > 0
    live.isHidden = item.roomId == 0
    ImageLoader.shared.load(item.pic, into: cover)
    ImageLoader.shared.load(item.ownerFace, into: avatar, placeholder: nil)
    if item.progress > 0, item.durationSec > 0 {
      progressTrack.isHidden = false
      let ratio = min(1.0, Double(item.progress) / Double(item.durationSec))
      progressWidth?.isActive = false
      progressWidth = progressFill.widthAnchor.constraint(
        equalTo: progressTrack.widthAnchor, multiplier: CGFloat(ratio))
      progressWidth?.isActive = true
    } else {
      progressTrack.isHidden = true
    }
  }

  @objc private func tapAvatar() {
    onAvatar?()
  }

  @objc private func tapCard(_ gesture: UITapGestureRecognizer) {
    let point = gesture.location(in: copyView)
    if avatarButton.frame.insetBy(dx: -6, dy: -6).contains(point) {
      return
    }
    onOpen?()
  }
}
