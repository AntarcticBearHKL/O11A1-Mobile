import UIKit

final class VideoDetailViewController: UIViewController, UIGestureRecognizerDelegate {
  var onClose: (() -> Void)?
  var onProfile: ((Int64) -> Void)?

  private let item: VideoItem
  private let scroll = UIScrollView()
  private let card = UIView()
  private let cover = UIImageView()
  private let durationChip = UILabel()
  private let titleLabel = UILabel()
  private let dateLabel = UILabel()
  private let bvidLabel = UILabel()
  private let timeLabel = UILabel()
  private let avatar = UIImageView()
  private let ownerName = UILabel()
  private let ownerMeta = UILabel()
  private let authorButton = UIButton(type: .custom)
  private let viewValue = UILabel()
  private let danmakuValue = UILabel()
  private let likeValue = UILabel()
  private let favoriteValue = UILabel()
  private let descLabel = UILabel()
  private let descToggle = UIButton(type: .system)
  private var descExpanded = false
  private var detailMid: Int64 = 0
  private var dismissPan: UIPanGestureRecognizer?

  init(item: VideoItem) {
    self.item = item
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear

    card.backgroundColor = NativeTheme.background.withAlphaComponent(0.98)
    card.layer.cornerRadius = 28
    card.layer.cornerCurve = .continuous
    card.clipsToBounds = true
    view.addSubview(card)
    card.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      card.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      card.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      card.topAnchor.constraint(equalTo: view.topAnchor),
      card.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    scroll.alwaysBounceVertical = true
    scroll.showsVerticalScrollIndicator = false
    card.addSubview(scroll)
    scroll.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      scroll.leadingAnchor.constraint(equalTo: card.leadingAnchor),
      scroll.trailingAnchor.constraint(equalTo: card.trailingAnchor),
      scroll.topAnchor.constraint(equalTo: card.topAnchor),
      scroll.bottomAnchor.constraint(equalTo: card.bottomAnchor),
    ])

    let stack = UIStackView()
    stack.axis = .vertical
    stack.alignment = .fill
    stack.spacing = 14
    scroll.addSubview(stack)
    stack.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 20),
      stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -20),
      stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor,
                                 constant: view.safeAreaInsets.top + 16),
      stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -32),
      stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -40),
    ])

    cover.contentMode = .scaleAspectFill
    cover.clipsToBounds = true
    cover.layer.cornerRadius = 22
    cover.layer.cornerCurve = .continuous
    cover.backgroundColor = NativeTheme.tertiary.withAlphaComponent(0.18)
    ImageLoader.shared.load(item.pic, into: cover)
    let hero = UIView()
    hero.addSubview(cover)
    cover.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      cover.leadingAnchor.constraint(equalTo: hero.leadingAnchor),
      cover.trailingAnchor.constraint(equalTo: hero.trailingAnchor),
      cover.topAnchor.constraint(equalTo: hero.topAnchor),
      cover.bottomAnchor.constraint(equalTo: hero.bottomAnchor),
      cover.heightAnchor.constraint(equalTo: cover.widthAnchor, multiplier: 9.0 / 16.0),
    ])
    durationChip.text = item.duration
    durationChip.font = NativeTheme.numberFont(11)
    durationChip.textColor = .white
    durationChip.textAlignment = .center
    durationChip.backgroundColor = UIColor.black.withAlphaComponent(0.78)
    durationChip.layer.cornerRadius = 5
    durationChip.clipsToBounds = true
    hero.addSubview(durationChip)
    durationChip.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      durationChip.trailingAnchor.constraint(equalTo: hero.trailingAnchor, constant: -8),
      durationChip.bottomAnchor.constraint(equalTo: hero.bottomAnchor, constant: -8),
      durationChip.widthAnchor.constraint(greaterThanOrEqualToConstant: 40),
      durationChip.heightAnchor.constraint(equalToConstant: 18),
    ])
    stack.addArrangedSubview(hero)

    titleLabel.text = item.title
    titleLabel.font = UIFont.systemFont(ofSize: 19, weight: .bold)
    titleLabel.textColor = NativeTheme.foreground
    titleLabel.numberOfLines = 0
    stack.addArrangedSubview(titleLabel)

    let meta = UIStackView()
    meta.axis = .horizontal
    meta.spacing = 10
    meta.alignment = .center
    [dateLabel, bvidLabel, timeLabel].forEach {
      $0.font = NativeTheme.numberFont(10.5)
      $0.textColor = NativeTheme.tertiary
      meta.addArrangedSubview($0)
    }
    dateLabel.text = Self.dateText(item.pubdate)
    bvidLabel.text = item.bvid.isEmpty ? "" : item.bvid
    timeLabel.text = item.duration
    stack.addArrangedSubview(meta)

    let author = UIView()
    author.backgroundColor = NativeTheme.foreground.withAlphaComponent(0.05)
    author.layer.cornerRadius = 18
    author.layer.cornerCurve = .continuous
    stack.addArrangedSubview(author)

    avatar.contentMode = .scaleAspectFill
    avatar.clipsToBounds = true
    avatar.layer.cornerRadius = 21
    avatar.backgroundColor = NativeTheme.tertiary.withAlphaComponent(0.2)
    ImageLoader.shared.load(item.ownerFace, into: avatar, placeholder: nil)
    author.addSubview(avatar)

    ownerName.text = item.owner
    ownerName.font = UIFont.systemFont(ofSize: 16, weight: .bold)
    ownerName.textColor = NativeTheme.foreground
    ownerName.numberOfLines = 1
    author.addSubview(ownerName)

    ownerMeta.text = item.mid > 0 ? "UID \(item.mid) · 点击进入主页" : "UP 主"
    ownerMeta.font = NativeTheme.bodyFont(10)
    ownerMeta.textColor = NativeTheme.secondary
    author.addSubview(ownerMeta)

    let go = UILabel()
    go.text = "主页 ›"
    go.font = NativeTheme.bodyFont(11)
    go.textColor = NativeTheme.navBlue
    author.addSubview(go)

    authorButton.backgroundColor = .clear
    authorButton.addTarget(self, action: #selector(authorTapped), for: .touchUpInside)
    author.addSubview(authorButton)

    [avatar, ownerName, ownerMeta, go, authorButton].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
    }
    NSLayoutConstraint.activate([
      avatar.leadingAnchor.constraint(equalTo: author.leadingAnchor, constant: 12),
      avatar.topAnchor.constraint(equalTo: author.topAnchor, constant: 10),
      avatar.bottomAnchor.constraint(equalTo: author.bottomAnchor, constant: -10),
      avatar.widthAnchor.constraint(equalToConstant: 42),
      avatar.heightAnchor.constraint(equalToConstant: 42),
      ownerName.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 10),
      ownerName.topAnchor.constraint(equalTo: author.topAnchor, constant: 12),
      ownerName.trailingAnchor.constraint(lessThanOrEqualTo: go.leadingAnchor, constant: -8),
      ownerMeta.leadingAnchor.constraint(equalTo: ownerName.leadingAnchor),
      ownerMeta.topAnchor.constraint(equalTo: ownerName.bottomAnchor, constant: 3),
      ownerMeta.trailingAnchor.constraint(lessThanOrEqualTo: go.leadingAnchor, constant: -8),
      go.trailingAnchor.constraint(equalTo: author.trailingAnchor, constant: -12),
      go.centerYAnchor.constraint(equalTo: author.centerYAnchor),
      authorButton.leadingAnchor.constraint(equalTo: author.leadingAnchor),
      authorButton.trailingAnchor.constraint(equalTo: author.trailingAnchor),
      authorButton.topAnchor.constraint(equalTo: author.topAnchor),
      authorButton.bottomAnchor.constraint(equalTo: author.bottomAnchor),
    ])

    let stats = UIStackView()
    stats.axis = .horizontal
    stats.distribution = .fillEqually
    stats.alignment = .fill
    stats.backgroundColor = NativeTheme.foreground.withAlphaComponent(0.05)
    stats.layer.cornerRadius = 14
    stats.layer.cornerCurve = .continuous
    stats.isLayoutMarginsRelativeArrangement = true
    stats.layoutMargins = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
    stack.addArrangedSubview(stats)
    for (value, label) in [(viewValue, "播放"), (danmakuValue, "弹幕"),
                           (likeValue, "点赞"), (favoriteValue, "收藏")] {
      let column = UIStackView()
      column.axis = .vertical
      column.alignment = .center
      column.spacing = 3
      value.font = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .semibold)
      value.textColor = NativeTheme.foreground
      value.text = "—"
      let caption = UILabel()
      caption.text = label
      caption.font = NativeTheme.bodyFont(9.5)
      caption.textColor = NativeTheme.secondary
      column.addArrangedSubview(value)
      column.addArrangedSubview(caption)
      stats.addArrangedSubview(column)
    }

    descLabel.font = NativeTheme.bodyFont(12)
    descLabel.textColor = NativeTheme.secondary
    descLabel.numberOfLines = 3
    descLabel.text = item.desc.isEmpty ? "暂无简介" : item.desc
    stack.addArrangedSubview(descLabel)

    descToggle.setTitle("展开简介", for: .normal)
    descToggle.titleLabel?.font = NativeTheme.bodyFont(12)
    descToggle.setTitleColor(NativeTheme.navBlue, for: .normal)
    descToggle.contentHorizontalAlignment = .left
    descToggle.addTarget(self, action: #selector(toggleDesc), for: .touchUpInside)
    stack.addArrangedSubview(descToggle)
    descToggle.isHidden = item.desc.count <= 60

    let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
    pan.delegate = self
    view.addGestureRecognizer(pan)
    dismissPan = pan

    loadDetail()
  }

  private func loadDetail() {
    BiliAPI.shared.videoInfo(item.bvid) { [weak self] result in
      guard let self = self, case .success(let json) = result else { return }
      let title = o11a1String(json["title"])
      if !title.isEmpty { self.titleLabel.text = title }
      let desc = o11a1String(json["desc"])
      if !desc.isEmpty {
        self.descLabel.text = desc
        self.descToggle.isHidden = desc.count <= 60
      }
      let pic = o11a1HTTPS(o11a1String(json["pic"]))
      if !pic.isEmpty { ImageLoader.shared.load(pic, into: self.cover) }
      let owner = o11a1String(json["owner"])
      if !owner.isEmpty { self.ownerName.text = owner }
      let face = o11a1HTTPS(o11a1String(json["ownerFace"]))
      if !face.isEmpty { ImageLoader.shared.load(face, into: self.avatar, placeholder: nil) }
      self.detailMid = o11a1Int64(json["mid"])
      if self.detailMid > 0 {
        self.ownerMeta.text = "UID \(self.detailMid) · 点击进入主页"
      }
      let duration = o11a1String(json["duration"])
      if !duration.isEmpty {
        self.timeLabel.text = duration
        self.durationChip.text = duration
      }
      let date = Self.dateText(o11a1Int64(json["pubdate"]))
      if !date.isEmpty { self.dateLabel.text = date }
      if let stat = json["stat"] as? [String: Any] {
        self.viewValue.text = o11a1Count(o11a1Int64(stat["view"]))
        self.danmakuValue.text = o11a1Count(o11a1Int64(stat["danmaku"]))
        self.likeValue.text = o11a1Count(o11a1Int64(stat["like"]))
        self.favoriteValue.text = o11a1Count(o11a1Int64(stat["favorite"]))
      }
    }
  }

  private static func dateText(_ raw: Int64) -> String {
    guard raw > 0 else { return "" }
    let seconds = raw > 100_000_000_000 ? raw / 1000 : raw
    let date = Date(timeIntervalSince1970: TimeInterval(seconds))
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
  }

  @objc private func authorTapped() {
    let mid = detailMid > 0 ? detailMid : item.mid
    guard mid > 0 else { return }
    onProfile?(mid)
  }

  @objc private func toggleDesc() {
    descExpanded.toggle()
    descLabel.numberOfLines = descExpanded ? 0 : 3
    descToggle.setTitle(descExpanded ? "收起简介" : "展开简介", for: .normal)
  }

  @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
    let width = max(1, view.bounds.width)
    let translation = gesture.translation(in: view).x
    switch gesture.state {
    case .changed:
      view.transform = CGAffineTransform(translationX: min(0, translation), y: 0)
    case .ended, .cancelled:
      let velocity = gesture.velocity(in: view).x
      if translation < -width * 0.24 || velocity < -350 {
        close()
      } else {
        UIView.animate(withDuration: 0.22) { self.view.transform = .identity }
      }
    default:
      break
    }
  }

  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    guard let pan = gestureRecognizer as? UIPanGestureRecognizer, pan === dismissPan else {
      return true
    }
    let velocity = pan.velocity(in: view)
    return abs(velocity.x) > abs(velocity.y)
  }

  private func close() {
    onClose?()
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    card.backgroundColor = NativeTheme.background.withAlphaComponent(0.98)
    authorButton.superview?.backgroundColor = NativeTheme.foreground.withAlphaComponent(0.05)
    descLabel.textColor = NativeTheme.secondary
  }
}
