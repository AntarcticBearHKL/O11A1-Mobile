import UIKit

/// Home feed card matching the original web layout: full-width 16:9 cover
/// with a glass information row below it and 4pt bottom corners.
final class HomeCardCell: UITableViewCell {
  static let reuseID = "HomeCardCell"
  private let cardBottomRadius: CGFloat = 4

  let mediaHost = UIView()
  var onOpen: (() -> Void)?
  var onAvatar: (() -> Void)?
  var onTouchDown: (() -> Void)?
  var onPreviewScrub: ((CGFloat, Bool) -> Void)?

  private let cover = UIImageView()
  private let duration = UILabel()
  private let live = UILabel()
  private let progressTrack = UIView()
  private let progressFill = UIView()
  private var progressWidth: NSLayoutConstraint?
  private let previewBar = PreviewProgressBar()
  private let previewLoading = UIView()
  private let previewSpinner = UIActivityIndicatorView(style: .medium)
  private let previewLoadingLabel = UILabel()
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
    duration.backgroundColor = .clear
    duration.shadowColor = UIColor.black.withAlphaComponent(0.85)
    duration.shadowOffset = CGSize(width: 1, height: 1)
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
    previewBar.onScrub = { [weak self] ratio, finished in
      self?.onPreviewScrub?(ratio, finished)
    }

    previewLoading.backgroundColor = UIColor.black.withAlphaComponent(0.58)
    previewLoading.layer.cornerRadius = 16
    previewLoading.layer.cornerCurve = .continuous
    previewLoading.isHidden = true
    previewLoading.isUserInteractionEnabled = false
    media.addSubview(previewLoading)
    previewLoading.translatesAutoresizingMaskIntoConstraints = false

    previewSpinner.color = .white
    previewSpinner.hidesWhenStopped = true
    previewLoadingLabel.text = "正在加载"
    previewLoadingLabel.font = UIFont.systemFont(ofSize: 11.5, weight: .medium)
    previewLoadingLabel.textColor = .white
    let loadingRow = UIStackView(arrangedSubviews: [previewSpinner,
                                                    previewLoadingLabel])
    loadingRow.axis = .horizontal
    loadingRow.alignment = .center
    loadingRow.spacing = 6
    previewLoading.addSubview(loadingRow)
    loadingRow.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      loadingRow.leadingAnchor.constraint(equalTo: previewLoading.leadingAnchor,
                                          constant: 12),
      loadingRow.trailingAnchor.constraint(equalTo: previewLoading.trailingAnchor,
                                           constant: -14),
      loadingRow.topAnchor.constraint(equalTo: previewLoading.topAnchor),
      loadingRow.bottomAnchor.constraint(equalTo: previewLoading.bottomAnchor),
      previewLoading.centerXAnchor.constraint(equalTo: media.centerXAnchor),
      previewLoading.centerYAnchor.constraint(equalTo: media.centerYAnchor),
      previewLoading.heightAnchor.constraint(equalToConstant: 32),
    ])

    copyView.backgroundColor = NativeTheme.surface
    copyView.layer.cornerRadius = cardBottomRadius
    copyView.layer.cornerCurve = .continuous
    copyView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
    copyView.clipsToBounds = true
    contentView.addSubview(copyView)
    copyView.translatesAutoresizingMaskIntoConstraints = false

    let topLine = UIView()
    topLine.backgroundColor = NativeTheme.hairline
    copyView.addSubview(topLine)
    topLine.translatesAutoresizingMaskIntoConstraints = false

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
      duration.bottomAnchor.constraint(equalTo: media.bottomAnchor, constant: -10),
      duration.widthAnchor.constraint(greaterThanOrEqualToConstant: 38),
      duration.heightAnchor.constraint(equalToConstant: 22),

      progressTrack.leadingAnchor.constraint(equalTo: media.leadingAnchor),
      progressTrack.trailingAnchor.constraint(equalTo: media.trailingAnchor),
      progressTrack.bottomAnchor.constraint(equalTo: media.bottomAnchor),
      progressTrack.heightAnchor.constraint(equalToConstant: 3),
      progressFill.leadingAnchor.constraint(equalTo: progressTrack.leadingAnchor),
      progressFill.topAnchor.constraint(equalTo: progressTrack.topAnchor),
      progressFill.bottomAnchor.constraint(equalTo: progressTrack.bottomAnchor),

      previewBar.leadingAnchor.constraint(equalTo: media.leadingAnchor),
      previewBar.trailingAnchor.constraint(equalTo: media.trailingAnchor),
      previewBar.bottomAnchor.constraint(equalTo: media.bottomAnchor),
      previewBar.heightAnchor.constraint(equalToConstant: 4),

      copyView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      copyView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      copyView.topAnchor.constraint(equalTo: media.bottomAnchor),
      copyView.heightAnchor.constraint(equalToConstant: 98),
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

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    onTouchDown?()
    super.touchesBegan(touches, with: event)
  }

  override func layoutSubviews() {
    super.layoutSubviews()    CATransaction.begin()
    CATransaction.setDisableActions(true)
    let shadowRect = contentView.bounds
    contentView.layer.shadowPath = UIBezierPath(
      roundedRect: shadowRect,
      byRoundingCorners: [.bottomLeft, .bottomRight],
      cornerRadii: CGSize(width: cardBottomRadius, height: cardBottomRadius)).cgPath
    contentView.layer.shadowOpacity =
      traitCollection.userInterfaceStyle == .dark ? 0.40 : 0.12
    CATransaction.commit()
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    contentView.layer.shadowOpacity =
      traitCollection.userInterfaceStyle == .dark ? 0.40 : 0.12
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    item = nil
    cover.image = nil
    avatar.image = nil
    mediaHost.subviews.forEach { $0.removeFromSuperview() }
    hidePreviewLoading()
    onOpen = nil
    onAvatar = nil
    onTouchDown = nil
    onPreviewScrub = nil
  }

  func showPreviewLoading() {
    previewLoadingLabel.text = "正在连接"
    previewLoading.isHidden = false
    previewSpinner.startAnimating()
  }

  func applyPreviewLoading(_ status: VideoLoadStatus) {
    guard status.isActive else {
      hidePreviewLoading()
      return
    }
    switch status.phase {
    case .connecting:
      previewLoadingLabel.text = "正在连接"
    case .buffering:
      previewLoadingLabel.text = VideoLoadingView.speedText(status.bytesPerSecond)
    case .playing, .idle:
      hidePreviewLoading()
      return
    }
    previewLoading.isHidden = false
    previewSpinner.startAnimating()
  }

  func hidePreviewLoading() {
    previewLoading.isHidden = true
    previewSpinner.stopAnimating()
  }

  /// Drop the full-resolution cover for a row that has scrolled far away.
  /// The image cache keeps the bytes, so returning to the row is a cheap hit.
  func unloadMedia() {
    cover.image = nil
    hidePreviewLoading()
    previewBar.isHidden = true
  }

  func configure(_ item: VideoItem) {
    self.item = item
    hidePreviewLoading()
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
    if resumeSeconds() > 0, item.durationSec > 0 {
      applyWatchProgress()
    } else {
      progressTrack.isHidden = true
    }
    previewBar.isHidden = true
    previewBar.progress = 0
  }

  func setPreviewProgress(_ ratio: CGFloat?, current: Double = 0, total: Double = 0) {
    if let ratio = ratio {
      previewBar.isHidden = false
      previewBar.progress = ratio
      progressTrack.isHidden = true
      let totalValue = total > 0 ? total : Double(item?.durationSec ?? 0)
      duration.text = " \(previewTime(current)) / \(previewTime(totalValue)) "
    } else {
      hidePreviewLoading()
      previewBar.isHidden = true
      previewBar.progress = 0
      duration.text = item?.duration ?? ""
      guard let item = item, resumeSeconds() > 0, item.durationSec > 0 else {
        progressTrack.isHidden = true
        return
      }
      applyWatchProgress()
    }
  }

  private func resumeSeconds() -> Double {
    guard let item = item else { return 0 }
    if item.progress > 0 { return Double(item.progress) }
    return WatchProgressStore.shared.position(for: item.bvid)
  }

  private func previewTime(_ value: Double) -> String {
    let seconds = max(0, Int(value.rounded()))
    if seconds >= 3600 {
      return String(format: "%d:%02d:%02d", seconds / 3600,
                    (seconds % 3600) / 60, seconds % 60)
    }
    return String(format: "%02d:%02d", seconds / 60, seconds % 60)
  }

  private func applyWatchProgress() {
    guard let item = item, item.durationSec > 0 else {
      progressTrack.isHidden = true
      return
    }
    let seconds = resumeSeconds()
    guard seconds > 0 else {
      progressTrack.isHidden = true
      return
    }
    progressTrack.isHidden = false
    let ratio = min(1.0, seconds / Double(item.durationSec))
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
    if !previewBar.isHidden {
      let barPoint = gesture.location(in: previewBar)
      if previewBar.point(inside: barPoint, with: nil) {
        return
      }
    }
    onOpen?()
  }
}
