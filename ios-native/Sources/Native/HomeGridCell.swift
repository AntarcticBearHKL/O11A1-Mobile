import UIKit

/// A compact Bilibili-style two-column video card: cover on top, the same
/// information as the large card below with smaller type.
final class MiniVideoCardView: UIView {
  private static let cardSurface = UIColor { trait in
    trait.userInterfaceStyle == .dark
      ? UIColor(red: 28.0 / 255.0, green: 28.0 / 255.0, blue: 30.0 / 255.0, alpha: 1)
      : UIColor(red: 242.0 / 255.0, green: 242.0 / 255.0, blue: 242.0 / 255.0, alpha: 1)
  }

  let mediaHost = UIView()
  private let cover = UIImageView()
  private let duration = UILabel()
  private let live = UILabel()
  private let progressTrack = UIView()
  private let progressFill = UIView()
  private var progressWidth: NSLayoutConstraint?
  private let info = UIView()
  private let title = UILabel()
  private let owner = UILabel()
  private let play = UILabel()
  private let time = UILabel()
  private let stats = UIStackView()
  private let tapButton = UIButton(type: .custom)
  private var item: VideoItem?

  var onOpen: (() -> Void)?

  override init(frame: CGRect) {
    super.init(frame: frame)
    clipsToBounds = true
    layer.cornerRadius = 6
    layer.cornerCurve = .continuous
    layer.borderWidth = 0.5
    layer.borderColor = NativeTheme.hairline.cgColor
    backgroundColor = Self.cardSurface

    mediaHost.clipsToBounds = true
    mediaHost.backgroundColor = UIColor { trait in
      trait.userInterfaceStyle == .dark
        ? .black
        : UIColor(red: 228.0 / 255.0, green: 231.0 / 255.0, blue: 236.0 / 255.0, alpha: 1)
    }
    addSubview(mediaHost)
    mediaHost.translatesAutoresizingMaskIntoConstraints = false

    cover.contentMode = .scaleAspectFill
    cover.clipsToBounds = true
    cover.backgroundColor = mediaHost.backgroundColor
    mediaHost.addSubview(cover)
    cover.translatesAutoresizingMaskIntoConstraints = false

    duration.font = NativeTheme.numberFont(12.5)
    duration.textColor = .white
    duration.textAlignment = .center
    duration.backgroundColor = .clear
    duration.shadowColor = UIColor.black.withAlphaComponent(0.85)
    duration.shadowOffset = CGSize(width: 1, height: 1)
    mediaHost.addSubview(duration)
    duration.translatesAutoresizingMaskIntoConstraints = false

    live.text = "LIVE"
    live.font = NativeTheme.titleFont(10.5)
    live.textColor = .white
    live.textAlignment = .center
    live.backgroundColor = UIColor(red: 0.90, green: 0.24, blue: 0.24, alpha: 1)
    live.layer.cornerRadius = 11
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

    info.backgroundColor = Self.cardSurface
    addSubview(info)
    info.translatesAutoresizingMaskIntoConstraints = false

    title.font = UIFont.systemFont(ofSize: 17.5, weight: .bold)
    title.textColor = NativeTheme.foreground
    title.numberOfLines = 2
    title.lineBreakMode = .byTruncatingTail
    info.addSubview(title)
    title.translatesAutoresizingMaskIntoConstraints = false

    owner.font = UIFont.systemFont(ofSize: 14, weight: .medium)
    owner.textColor = NativeTheme.secondary
    owner.numberOfLines = 1
    owner.lineBreakMode = .byTruncatingTail
    owner.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    info.addSubview(owner)
    owner.translatesAutoresizingMaskIntoConstraints = false

    play.font = UIFont.monospacedDigitSystemFont(ofSize: 12.5, weight: .medium)
    play.textAlignment = .right
    play.numberOfLines = 1
    play.setContentHuggingPriority(.required, for: .horizontal)
    play.setContentCompressionResistancePriority(.required, for: .horizontal)
    time.font = UIFont.monospacedDigitSystemFont(ofSize: 12.5, weight: .medium)
    time.textColor = NativeTheme.tertiary
    time.textAlignment = .right
    time.numberOfLines = 1
    time.setContentHuggingPriority(.required, for: .horizontal)
    time.setContentCompressionResistancePriority(.required, for: .horizontal)

    stats.axis = .vertical
    stats.alignment = .trailing
    stats.distribution = .fill
    stats.spacing = 1.5
    stats.addArrangedSubview(play)
    stats.addArrangedSubview(time)
    info.addSubview(stats)
    stats.translatesAutoresizingMaskIntoConstraints = false

    tapButton.backgroundColor = .clear
    tapButton.addTarget(self, action: #selector(tapped), for: .touchUpInside)
    addSubview(tapButton)
    tapButton.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      mediaHost.leadingAnchor.constraint(equalTo: leadingAnchor),
      mediaHost.trailingAnchor.constraint(equalTo: trailingAnchor),
      mediaHost.topAnchor.constraint(equalTo: topAnchor),
      mediaHost.heightAnchor.constraint(equalTo: mediaHost.widthAnchor, multiplier: 3.0 / 4.0),

      cover.leadingAnchor.constraint(equalTo: mediaHost.leadingAnchor),
      cover.trailingAnchor.constraint(equalTo: mediaHost.trailingAnchor),
      cover.topAnchor.constraint(equalTo: mediaHost.topAnchor),
      cover.bottomAnchor.constraint(equalTo: mediaHost.bottomAnchor),

      duration.trailingAnchor.constraint(equalTo: mediaHost.trailingAnchor, constant: -8),
      duration.bottomAnchor.constraint(equalTo: mediaHost.bottomAnchor, constant: -8),
      duration.widthAnchor.constraint(greaterThanOrEqualToConstant: 42),
      duration.heightAnchor.constraint(equalToConstant: 22),

      live.leadingAnchor.constraint(equalTo: mediaHost.leadingAnchor, constant: 8),
      live.topAnchor.constraint(equalTo: mediaHost.topAnchor, constant: 8),
      live.widthAnchor.constraint(equalToConstant: 40),
      live.heightAnchor.constraint(equalToConstant: 21),

      progressTrack.leadingAnchor.constraint(equalTo: mediaHost.leadingAnchor),
      progressTrack.trailingAnchor.constraint(equalTo: mediaHost.trailingAnchor),
      progressTrack.bottomAnchor.constraint(equalTo: mediaHost.bottomAnchor),
      progressTrack.heightAnchor.constraint(equalToConstant: 3),
      progressFill.leadingAnchor.constraint(equalTo: progressTrack.leadingAnchor),
      progressFill.topAnchor.constraint(equalTo: progressTrack.topAnchor),
      progressFill.bottomAnchor.constraint(equalTo: progressTrack.bottomAnchor),

      info.leadingAnchor.constraint(equalTo: leadingAnchor),
      info.trailingAnchor.constraint(equalTo: trailingAnchor),
      info.topAnchor.constraint(equalTo: mediaHost.bottomAnchor),
      info.bottomAnchor.constraint(equalTo: bottomAnchor),
      info.heightAnchor.constraint(equalToConstant: HomeGridCell.infoHeight),

      title.leadingAnchor.constraint(equalTo: info.leadingAnchor, constant: 12),
      title.trailingAnchor.constraint(equalTo: info.trailingAnchor, constant: -12),
      title.topAnchor.constraint(equalTo: info.topAnchor, constant: 9),

      owner.leadingAnchor.constraint(equalTo: info.leadingAnchor, constant: 12),
      owner.bottomAnchor.constraint(equalTo: info.bottomAnchor, constant: -11),
      owner.trailingAnchor.constraint(lessThanOrEqualTo: stats.leadingAnchor, constant: -10),

      stats.trailingAnchor.constraint(equalTo: info.trailingAnchor, constant: -12),
      stats.bottomAnchor.constraint(equalTo: info.bottomAnchor, constant: -11),

      title.bottomAnchor.constraint(lessThanOrEqualTo: stats.topAnchor, constant: -5),
      title.bottomAnchor.constraint(lessThanOrEqualTo: owner.topAnchor, constant: -5),

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
    backgroundColor = Self.cardSurface
    info.backgroundColor = Self.cardSurface
    cover.backgroundColor = mediaHost.backgroundColor
  }

  func prepareForReuse() {
    item = nil
    cover.image = nil
  }

  func configure(_ item: VideoItem) {
    self.item = item
    let paragraph = NSMutableParagraphStyle()
    paragraph.minimumLineHeight = 22
    paragraph.maximumLineHeight = 22
    paragraph.lineBreakMode = .byTruncatingTail
    title.attributedText = NSAttributedString(
      string: item.title,
      attributes: [
        .font: UIFont.systemFont(ofSize: 17.5, weight: .bold),
        .foregroundColor: NativeTheme.foreground,
        .paragraphStyle: paragraph,
      ])
    let season = item.seasonId > 0 || item.kind == "season"
    let isLive = item.roomId > 0
    owner.text = season && !item.meta.isEmpty ? item.meta : item.owner
    play.isHidden = season || isLive
    time.isHidden = season
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
}

final class HomeGridCell: UITableViewCell {
  static let reuseID = "HomeGridCell"
  static let sideInset: CGFloat = 4
  static let columnSpacing: CGFloat = 4
  static let verticalInset: CGFloat = 2
  static let infoHeight: CGFloat = 76 * 4 / 3

  let leftCard = MiniVideoCardView()
  private let rightCard = MiniVideoCardView()
  private var leftItem: VideoItem?
  private var rightItem: VideoItem?

  var onOpen: ((VideoItem, MiniVideoCardView) -> Void)?

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
    rightCard.onOpen = { [weak self] in
      guard let self = self, let item = self.rightItem else { return }
      self.onOpen?(item, self.rightCard)
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
