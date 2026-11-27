import UIKit

/// A compact Bilibili-style two-column video card: cover on top, the same
/// information as the large card below with smaller type.
final class MiniVideoCardView: UIView {
  let mediaHost = UIView()
  private let cover = UIImageView()
  private let duration = UILabel()
  private let live = UILabel()
  private let progressTrack = UIView()
  private let progressFill = UIView()
  private var progressWidth: NSLayoutConstraint?
  private let info = UIView()
  private let avatar = UIImageView()
  private let title = UILabel()
  private let owner = UILabel()
  private let play = UILabel()
  private let time = UILabel()
  private let dot = UILabel()
  private let meta = UIStackView()
  private let tapButton = UIButton(type: .custom)
  private let avatarButton = UIButton(type: .custom)
  private var item: VideoItem?

  var onOpen: (() -> Void)?
  var onAvatar: (() -> Void)?

  override init(frame: CGRect) {
    super.init(frame: frame)
    clipsToBounds = true
    layer.cornerRadius = 6
    layer.cornerCurve = .continuous
    layer.borderWidth = 0.5
    layer.borderColor = NativeTheme.hairline.cgColor
    backgroundColor = NativeTheme.surface

    mediaHost.clipsToBounds = true
    mediaHost.backgroundColor = UIColor { trait in
      trait.userInterfaceStyle == .dark
        ? UIColor(red: 26.0 / 255.0, green: 32.0 / 255.0, blue: 42.0 / 255.0, alpha: 1)
        : UIColor(red: 228.0 / 255.0, green: 231.0 / 255.0, blue: 236.0 / 255.0, alpha: 1)
    }
    addSubview(mediaHost)
    mediaHost.translatesAutoresizingMaskIntoConstraints = false

    cover.contentMode = .scaleAspectFill
    cover.clipsToBounds = true
    cover.backgroundColor = mediaHost.backgroundColor
    mediaHost.addSubview(cover)
    cover.translatesAutoresizingMaskIntoConstraints = false

    duration.font = NativeTheme.numberFont(9.5)
    duration.textColor = .white
    duration.textAlignment = .center
    duration.backgroundColor = .clear
    duration.shadowColor = UIColor.black.withAlphaComponent(0.85)
    duration.shadowOffset = CGSize(width: 1, height: 1)
    mediaHost.addSubview(duration)
    duration.translatesAutoresizingMaskIntoConstraints = false

    live.text = "LIVE"
    live.font = NativeTheme.titleFont(8)
    live.textColor = .white
    live.textAlignment = .center
    live.backgroundColor = UIColor(red: 0.90, green: 0.24, blue: 0.24, alpha: 1)
    live.layer.cornerRadius = 8
    live.clipsToBounds = true
    live.isHidden = true
    mediaHost.addSubview(live)
    live.translatesAutoresizingMaskIntoConstraints = false

    progressTrack.backgroundColor = UIColor.white.withAlphaComponent(0.28)
    mediaHost.addSubview(progressTrack)
    progressTrack.translatesAutoresizingMaskIntoConstraints = false
    progressFill.backgroundColor = UIColor(red: 1, green: 45.0 / 255.0, blue: 45.0 / 255.0, alpha: 1)
    progressTrack.addSubview(progressFill)
    progressFill.translatesAutoresizingMaskIntoConstraints = false

    info.backgroundColor = NativeTheme.surface
    addSubview(info)
    info.translatesAutoresizingMaskIntoConstraints = false

    avatar.contentMode = .scaleAspectFill
    avatar.clipsToBounds = true
    avatar.layer.cornerRadius = 15
    avatar.backgroundColor = NativeTheme.tertiary.withAlphaComponent(0.16)
    info.addSubview(avatar)
    avatar.translatesAutoresizingMaskIntoConstraints = false

    avatarButton.backgroundColor = .clear
    avatarButton.addTarget(self, action: #selector(avatarTapped), for: .touchUpInside)
    avatarButton.translatesAutoresizingMaskIntoConstraints = false

    title.font = UIFont.systemFont(ofSize: 13, weight: .bold)
    title.textColor = NativeTheme.foreground
    title.numberOfLines = 2
    title.lineBreakMode = .byTruncatingTail
    info.addSubview(title)
    title.translatesAutoresizingMaskIntoConstraints = false

    owner.font = UIFont.systemFont(ofSize: 9.5, weight: .medium)
    owner.textColor = NativeTheme.secondary
    owner.numberOfLines = 1
    owner.lineBreakMode = .byTruncatingTail
    owner.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    play.font = UIFont.monospacedDigitSystemFont(ofSize: 9.5, weight: .medium)
    play.textAlignment = .right
    play.numberOfLines = 1
    play.setContentHuggingPriority(.required, for: .horizontal)
    play.setContentCompressionResistancePriority(.required, for: .horizontal)
    time.font = UIFont.monospacedDigitSystemFont(ofSize: 9.5, weight: .medium)
    time.textColor = NativeTheme.tertiary
    time.textAlignment = .right
    time.numberOfLines = 1
    time.setContentHuggingPriority(.required, for: .horizontal)
    time.setContentCompressionResistancePriority(.required, for: .horizontal)
    dot.text = "·"
    dot.font = UIFont.systemFont(ofSize: 9.5, weight: .medium)
    dot.textColor = NativeTheme.tertiary
    dot.setContentHuggingPriority(.required, for: .horizontal)
    meta.axis = .horizontal
    meta.distribution = .fill
    meta.alignment = .center
    meta.spacing = 3
    let metaSpacer = UIView()
    metaSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
    meta.addArrangedSubview(owner)
    meta.addArrangedSubview(metaSpacer)
    meta.addArrangedSubview(play)
    meta.addArrangedSubview(dot)
    meta.addArrangedSubview(time)
    info.addSubview(meta)
    meta.translatesAutoresizingMaskIntoConstraints = false

    tapButton.backgroundColor = .clear
    tapButton.addTarget(self, action: #selector(tapped), for: .touchUpInside)
    addSubview(tapButton)
    tapButton.translatesAutoresizingMaskIntoConstraints = false
    addSubview(avatarButton)

    NSLayoutConstraint.activate([
      mediaHost.leadingAnchor.constraint(equalTo: leadingAnchor),
      mediaHost.trailingAnchor.constraint(equalTo: trailingAnchor),
      mediaHost.topAnchor.constraint(equalTo: topAnchor),
      mediaHost.heightAnchor.constraint(equalTo: mediaHost.widthAnchor, multiplier: 9.0 / 16.0),

      cover.leadingAnchor.constraint(equalTo: mediaHost.leadingAnchor),
      cover.trailingAnchor.constraint(equalTo: mediaHost.trailingAnchor),
      cover.topAnchor.constraint(equalTo: mediaHost.topAnchor),
      cover.bottomAnchor.constraint(equalTo: mediaHost.bottomAnchor),

      duration.trailingAnchor.constraint(equalTo: mediaHost.trailingAnchor, constant: -6),
      duration.bottomAnchor.constraint(equalTo: mediaHost.bottomAnchor, constant: -6),
      duration.widthAnchor.constraint(greaterThanOrEqualToConstant: 32),
      duration.heightAnchor.constraint(equalToConstant: 17),

      live.leadingAnchor.constraint(equalTo: mediaHost.leadingAnchor, constant: 6),
      live.topAnchor.constraint(equalTo: mediaHost.topAnchor, constant: 6),
      live.widthAnchor.constraint(equalToConstant: 30),
      live.heightAnchor.constraint(equalToConstant: 16),

      progressTrack.leadingAnchor.constraint(equalTo: mediaHost.leadingAnchor),
      progressTrack.trailingAnchor.constraint(equalTo: mediaHost.trailingAnchor),
      progressTrack.bottomAnchor.constraint(equalTo: mediaHost.bottomAnchor),
      progressTrack.heightAnchor.constraint(equalToConstant: 2),
      progressFill.leadingAnchor.constraint(equalTo: progressTrack.leadingAnchor),
      progressFill.topAnchor.constraint(equalTo: progressTrack.topAnchor),
      progressFill.bottomAnchor.constraint(equalTo: progressTrack.bottomAnchor),

      info.leadingAnchor.constraint(equalTo: leadingAnchor),
      info.trailingAnchor.constraint(equalTo: trailingAnchor),
      info.topAnchor.constraint(equalTo: mediaHost.bottomAnchor),
      info.bottomAnchor.constraint(equalTo: bottomAnchor),
      info.heightAnchor.constraint(equalToConstant: HomeGridCell.infoHeight),

      avatar.leadingAnchor.constraint(equalTo: info.leadingAnchor, constant: 9),
      avatar.centerYAnchor.constraint(equalTo: info.centerYAnchor),
      avatar.widthAnchor.constraint(equalToConstant: 30),
      avatar.heightAnchor.constraint(equalToConstant: 30),
      avatarButton.leadingAnchor.constraint(equalTo: avatar.leadingAnchor),
      avatarButton.trailingAnchor.constraint(equalTo: avatar.trailingAnchor),
      avatarButton.topAnchor.constraint(equalTo: avatar.topAnchor),
      avatarButton.bottomAnchor.constraint(equalTo: avatar.bottomAnchor),

      title.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 7),
      title.trailingAnchor.constraint(equalTo: info.trailingAnchor, constant: -9),
      title.topAnchor.constraint(equalTo: info.topAnchor, constant: 7),

      meta.leadingAnchor.constraint(equalTo: title.leadingAnchor),
      meta.trailingAnchor.constraint(equalTo: title.trailingAnchor),
      meta.bottomAnchor.constraint(equalTo: info.bottomAnchor, constant: -7),

      tapButton.leadingAnchor.constraint(equalTo: leadingAnchor),
      tapButton.trailingAnchor.constraint(equalTo: trailingAnchor),
      tapButton.topAnchor.constraint(equalTo: topAnchor),
      tapButton.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    layer.borderColor = NativeTheme.hairline.cgColor
    info.backgroundColor = NativeTheme.surface
    cover.backgroundColor = mediaHost.backgroundColor
  }

  func prepareForReuse() {
    item = nil
    cover.image = nil
    avatar.image = nil
  }

  func configure(_ item: VideoItem) {
    self.item = item
    let paragraph = NSMutableParagraphStyle()
    paragraph.minimumLineHeight = 16.5
    paragraph.maximumLineHeight = 16.5
    paragraph.lineBreakMode = .byTruncatingTail
    title.attributedText = NSAttributedString(
      string: item.title,
      attributes: [
        .font: UIFont.systemFont(ofSize: 13, weight: .bold),
        .foregroundColor: NativeTheme.foreground,
        .paragraphStyle: paragraph,
      ])
    let season = item.seasonId > 0 || item.kind == "season"
    let isLive = item.roomId > 0
    owner.text = season && !item.meta.isEmpty ? item.meta : item.owner
    play.isHidden = season || isLive
    time.isHidden = season
    dot.isHidden = play.isHidden || time.isHidden
    play.text = item.playText.isEmpty ? "" : item.playText + "播放"
    play.textColor = NativeTheme.playCountColor(item.play)
    if isLive {
      time.text = "直播中"
      time.textColor = UIColor(red: 217.0 / 255.0, green: 120.0 / 255.0,
                              blue: 98.0 / 255.0, alpha: 1)
    } else {
      time.text = NativeTheme.freshness(item.pubdate)
      time.textColor = NativeTheme.freshnessColor(item.pubdate)
    }
    duration.text = season && (item.duration.isEmpty || item.duration == "00:00")
      ? "全" : item.duration
    duration.isHidden = isLive
    live.isHidden = !isLive
    ImageLoader.shared.load(item.pic, into: cover)
    if item.ownerFace.isEmpty {
      avatar.image = nil
    } else {
      ImageLoader.shared.load(item.ownerFace, into: avatar, placeholder: nil)
    }
    progressWidth?.isActive = false
    if item.progress > 0, item.durationSec > 0 {
      progressTrack.isHidden = false
      let ratio = min(1.0, Double(item.progress) / Double(item.durationSec))
      progressWidth = progressFill.widthAnchor.constraint(
        equalTo: progressTrack.widthAnchor, multiplier: CGFloat(ratio))
      progressWidth?.isActive = true
    } else {
      progressTrack.isHidden = true
    }
  }

  @objc private func tapped() {
    onOpen?()
  }

  @objc private func avatarTapped() {
    onAvatar?()
  }
}

final class HomeGridCell: UITableViewCell {
  static let reuseID = "HomeGridCell"
  static let sideInset: CGFloat = 4
  static let columnSpacing: CGFloat = 4
  static let verticalInset: CGFloat = 2
  static let infoHeight: CGFloat = 76

  let leftCard = MiniVideoCardView()
  private let rightCard = MiniVideoCardView()
  private var leftItem: VideoItem?
  private var rightItem: VideoItem?

  var onOpen: ((VideoItem, MiniVideoCardView) -> Void)?
  var onAvatar: ((Int64) -> Void)?

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    let row = UIStackView(arrangedSubviews: [leftCard, rightCard])
    row.axis = .horizontal
    row.distribution = .fillEqually
    row.alignment = .fill
    row.spacing = HomeGridCell.columnSpacing
    contentView.addSubview(row)
    row.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      row.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: HomeGridCell.sideInset),
      row.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -HomeGridCell.sideInset),
      row.topAnchor.constraint(equalTo: contentView.topAnchor, constant: HomeGridCell.verticalInset),
      row.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -HomeGridCell.verticalInset),
    ])

    leftCard.onOpen = { [weak self] in
      guard let self = self, let item = self.leftItem else { return }
      self.onOpen?(item, self.leftCard)
    }
    leftCard.onAvatar = { [weak self] in
      guard let self = self, let item = self.leftItem else { return }
      self.onAvatar?(item.mid)
    }
    rightCard.onOpen = { [weak self] in
      guard let self = self, let item = self.rightItem else { return }
      self.onOpen?(item, self.rightCard)
    }
    rightCard.onAvatar = { [weak self] in
      guard let self = self, let item = self.rightItem else { return }
      self.onAvatar?(item.mid)
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    leftItem = nil
    rightItem = nil
    leftCard.prepareForReuse()
    rightCard.prepareForReuse()
    onOpen = nil
    onAvatar = nil
  }

  func configure(_ left: VideoItem, _ right: VideoItem?) {
    leftItem = left
    leftCard.configure(left)
    if let right = right {
      rightItem = right
      rightCard.alpha = 1
      rightCard.isUserInteractionEnabled = true
      rightCard.configure(right)
    } else {
      rightItem = nil
      rightCard.alpha = 0
      rightCard.isUserInteractionEnabled = false
    }
  }
}
