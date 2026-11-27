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
  private let previewBar = PreviewProgressBar()
  private let glossLayer = CAGradientLayer()
  private let sheenLayer = CAGradientLayer()
  private let avatar = UIImageView()
  private let avatarInitial = UILabel()
  private let avatarButton = UIButton(type: .custom)
  private let title = UILabel()
  private let owner = UILabel()
  private let play = UILabel()
  private let time = UILabel()
  private let dot = UILabel()
  private let metaStack = UIStackView()
  private let copyView = UIView()
  private weak var topHighlight: UIView?
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
    duration.layer.cornerRadius = NativeTheme.cornerRadius
    duration.clipsToBounds = true
    media.addSubview(duration)
    duration.translatesAutoresizingMaskIntoConstraints = false

    live.text = "LIVE"
    live.font = NativeTheme.titleFont(10)
    live.textColor = .white
    live.textAlignment = .center
    live.backgroundColor = UIColor(red: 0.90, green: 0.24, blue: 0.24, alpha: 1)
    live.layer.cornerRadius = NativeTheme.cornerRadius
    live.clipsToBounds = true
    media.addSubview(live)
    live.translatesAutoresizingMaskIntoConstraints = false

    progressTrack.backgroundColor = UIColor.white.withAlphaComponent(0.28)
    media.addSubview(progressTrack)
    progressTrack.translatesAutoresizingMaskIntoConstraints = false
    progressFill.backgroundColor = UIColor(red: 1, green: 45.0 / 255.0, blue: 45.0 / 255.0, alpha: 1)
    progressTrack.addSubview(progressFill)
    progressFill.translatesAutoresizingMaskIntoConstraints = false

    media.addSubview(previewBar)
    previewBar.translatesAutoresizingMaskIntoConstraints = false

    copyView.backgroundColor = .clear
    copyView.layer.cornerRadius = NativeTheme.cornerRadius
    copyView.layer.cornerCurve = .continuous
    copyView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
    copyView.clipsToBounds = true
    copyView.layer.borderWidth = 0.8
    glossLayer.startPoint = CGPoint(x: 0, y: 0)
    glossLayer.endPoint = CGPoint(x: 1, y: 1)
    sheenLayer.startPoint = CGPoint(x: 0.15, y: 0)
    sheenLayer.endPoint = CGPoint(x: 0.85, y: 0.62)
    copyView.layer.insertSublayer(glossLayer, at: 0)
    copyView.layer.insertSublayer(sheenLayer, at: 1)
    contentView.addSubview(copyView)
    copyView.translatesAutoresizingMaskIntoConstraints = false

    let topLine = UIView()
    topLine.backgroundColor = NativeTheme.homeRowLine
    copyView.addSubview(topLine)
    topLine.translatesAutoresizingMaskIntoConstraints = false
    topHighlight = topLine

    avatar.contentMode = .scaleAspectFill
    avatar.clipsToBounds = true
    avatar.layer.cornerRadius = 28
    avatar.backgroundColor = UIColor { trait in
      trait.userInterfaceStyle == .dark
        ? UIColor(red: 20.0 / 255.0, green: 20.0 / 255.0, blue: 22.0 / 255.0, alpha: 1)
        : UIColor(red: 245.0 / 255.0, green: 245.0 / 255.0, blue: 247.0 / 255.0, alpha: 1)
    }
    copyView.addSubview(avatar)
    avatar.translatesAutoresizingMaskIntoConstraints = false

    avatarInitial.font = UIFont.systemFont(ofSize: 15, weight: .bold)
    avatarInitial.textColor = NativeTheme.secondary
    avatarInitial.textAlignment = .center
    avatarInitial.isHidden = true
    avatar.addSubview(avatarInitial)
    avatarInitial.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      avatarInitial.centerXAnchor.constraint(equalTo: avatar.centerXAnchor),
      avatarInitial.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
    ])

    avatarButton.backgroundColor = .clear
    avatarButton.addTarget(self, action: #selector(tapAvatar), for: .touchUpInside)
    copyView.addSubview(avatarButton)
    avatarButton.translatesAutoresizingMaskIntoConstraints = false

    title.font = UIFont.systemFont(ofSize: 17, weight: .bold)
    title.textColor = NativeTheme.foreground
    title.numberOfLines = 2
    title.lineBreakMode = .byTruncatingTail
    copyView.addSubview(title)
    title.translatesAutoresizingMaskIntoConstraints = false

    owner.font = UIFont.systemFont(ofSize: 12, weight: .medium)
    owner.textColor = NativeTheme.secondary
    owner.numberOfLines = 1
    owner.lineBreakMode = .byTruncatingTail
    owner.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    play.font = UIFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
    play.textAlignment = .right
    play.numberOfLines = 1
    play.setContentHuggingPriority(.required, for: .horizontal)
    play.setContentCompressionResistancePriority(.required, for: .horizontal)
    time.font = UIFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
    time.textColor = NativeTheme.tertiary
    time.textAlignment = .right
    time.numberOfLines = 1
    time.setContentHuggingPriority(.required, for: .horizontal)
    time.setContentCompressionResistancePriority(.required, for: .horizontal)
    dot.text = "·"
    dot.font = UIFont.systemFont(ofSize: 12, weight: .medium)
    dot.textColor = NativeTheme.tertiary
    dot.setContentHuggingPriority(.required, for: .horizontal)
    dot.setContentCompressionResistancePriority(.required, for: .horizontal)

    metaStack.axis = .horizontal
    metaStack.distribution = .fill
    metaStack.alignment = .center
    metaStack.spacing = 6
    let metaSpacer = UIView()
    metaSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
    metaStack.addArrangedSubview(owner)
    metaStack.addArrangedSubview(metaSpacer)
    metaStack.addArrangedSubview(play)
    metaStack.addArrangedSubview(dot)
    metaStack.addArrangedSubview(time)
    copyView.addSubview(metaStack)
    metaStack.translatesAutoresizingMaskIntoConstraints = false

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

      previewBar.leadingAnchor.constraint(equalTo: media.leadingAnchor, constant: 14),
      previewBar.trailingAnchor.constraint(equalTo: media.trailingAnchor, constant: -14),
      previewBar.bottomAnchor.constraint(equalTo: media.bottomAnchor),
      previewBar.heightAnchor.constraint(equalToConstant: 4),

      copyView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      copyView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      copyView.topAnchor.constraint(equalTo: media.bottomAnchor),
      copyView.heightAnchor.constraint(equalToConstant: 122),
      copyView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -14),

      topLine.leadingAnchor.constraint(equalTo: copyView.leadingAnchor),
      topLine.trailingAnchor.constraint(equalTo: copyView.trailingAnchor),
      topLine.topAnchor.constraint(equalTo: copyView.topAnchor),
      topLine.heightAnchor.constraint(equalToConstant: 0.5),

      avatar.leadingAnchor.constraint(equalTo: copyView.leadingAnchor, constant: 16),
      avatar.centerYAnchor.constraint(equalTo: copyView.centerYAnchor),
      avatar.widthAnchor.constraint(equalToConstant: 56),
      avatar.heightAnchor.constraint(equalToConstant: 56),

      avatarButton.leadingAnchor.constraint(equalTo: avatar.leadingAnchor),
      avatarButton.trailingAnchor.constraint(equalTo: avatar.trailingAnchor),
      avatarButton.topAnchor.constraint(equalTo: avatar.topAnchor),
      avatarButton.bottomAnchor.constraint(equalTo: avatar.bottomAnchor),

      title.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 14),
      title.trailingAnchor.constraint(equalTo: copyView.trailingAnchor, constant: -16),
      title.topAnchor.constraint(equalTo: copyView.topAnchor, constant: 16),

      metaStack.leadingAnchor.constraint(equalTo: title.leadingAnchor),
      metaStack.trailingAnchor.constraint(equalTo: title.trailingAnchor),
      metaStack.bottomAnchor.constraint(equalTo: copyView.bottomAnchor, constant: -16),
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
    let shadowRect = contentView.bounds
    contentView.layer.shadowPath = UIBezierPath(
      roundedRect: shadowRect,
      byRoundingCorners: [.bottomLeft, .bottomRight],
      cornerRadii: CGSize(width: NativeTheme.cornerRadius, height: NativeTheme.cornerRadius)).cgPath
    contentView.layer.shadowOpacity =
      traitCollection.userInterfaceStyle == .dark ? 0.40 : 0.16
    glossLayer.frame = copyView.bounds
    sheenLayer.frame = copyView.bounds
    applyGlossColors()
    CATransaction.commit()
  }

  private func applyGlossColors() {
    let dark = traitCollection.userInterfaceStyle == .dark
    glossLayer.colors = dark
      ? [
          UIColor(white: 5.0 / 255.0, alpha: 1).cgColor,
          UIColor(white: 17.0 / 255.0, alpha: 1).cgColor,
        ]
      : [
          UIColor.white.cgColor,
          UIColor(white: 242.0 / 255.0, alpha: 1).cgColor,
        ]
    glossLayer.locations = [0, 1]
    sheenLayer.colors = dark
      ? [UIColor(white: 1, alpha: 0.12).cgColor, UIColor(white: 1, alpha: 0).cgColor]
      : [UIColor(white: 1, alpha: 0.62).cgColor, UIColor(white: 1, alpha: 0).cgColor]
    copyView.layer.borderColor = dark
      ? UIColor(white: 1, alpha: 0.16).cgColor
      : UIColor(white: 0, alpha: 0.06).cgColor
    topHighlight?.backgroundColor = dark
      ? UIColor(white: 1, alpha: 0.22)
      : UIColor(white: 1, alpha: 0.95)
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    contentView.layer.shadowOpacity =
      traitCollection.userInterfaceStyle == .dark ? 0.40 : 0.16
    applyGlossColors()
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
    let paragraph = NSMutableParagraphStyle()
    paragraph.minimumLineHeight = 23.5
    paragraph.maximumLineHeight = 23.5
    paragraph.lineBreakMode = .byTruncatingTail
    title.attributedText = NSAttributedString(
      string: item.title,
      attributes: [
        .font: UIFont.systemFont(ofSize: 17, weight: .bold),
        .foregroundColor: NativeTheme.foreground,
        .paragraphStyle: paragraph,
      ])
    let season = item.seasonId > 0 || item.kind == "season"
    let live = item.roomId > 0
    owner.text = season && !item.meta.isEmpty ? item.meta : item.owner
    play.isHidden = season || live
    time.isHidden = season
    dot.isHidden = play.isHidden || time.isHidden
    play.text = item.playText.isEmpty ? "" : item.playText + "播放"
    play.textColor = NativeTheme.playCountColor(item.play)
    if live {
      time.text = "直播中"
      time.textColor = UIColor(red: 217.0 / 255.0, green: 120.0 / 255.0,
                              blue: 98.0 / 255.0, alpha: 1)
    } else {
      time.text = NativeTheme.freshness(item.pubdate)
      time.textColor = NativeTheme.freshnessColor(item.pubdate)
    }
    duration.text = season && (item.duration.isEmpty || item.duration == "00:00")
      ? "番剧" : item.duration
    duration.isHidden = live
    self.live.isHidden = !live
    ImageLoader.shared.load(item.pic, into: cover)
    if item.ownerFace.isEmpty {
      avatar.image = nil
      avatarInitial.text = String(item.owner.prefix(1))
      avatarInitial.isHidden = false
    } else {
      avatarInitial.isHidden = true
      ImageLoader.shared.load(item.ownerFace, into: avatar, placeholder: nil)
    }
    if item.progress > 0, item.durationSec > 0 {
      applyWatchProgress()
    } else {
      progressTrack.isHidden = true
    }
    previewBar.isHidden = true
    previewBar.progress = 0
  }

  func setPreviewProgress(_ ratio: CGFloat?) {
    if let ratio = ratio {
      previewBar.isHidden = false
      previewBar.progress = ratio
      progressTrack.isHidden = true
    } else {
      previewBar.isHidden = true
      previewBar.progress = 0
      guard let item = item, item.progress > 0, item.durationSec > 0 else {
        progressTrack.isHidden = true
        return
      }
      applyWatchProgress()
    }
  }

  private func applyWatchProgress() {
    guard let item = item, item.progress > 0, item.durationSec > 0 else {
      progressTrack.isHidden = true
      return
    }
    progressTrack.isHidden = false
    let ratio = min(1.0, Double(item.progress) / Double(item.durationSec))
    progressWidth?.isActive = false
    progressWidth = progressFill.widthAnchor.constraint(
      equalTo: progressTrack.widthAnchor, multiplier: CGFloat(ratio))
    progressWidth?.isActive = true
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
