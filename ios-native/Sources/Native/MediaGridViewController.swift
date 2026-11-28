import UIKit

/// Immersive live / bangumi browsers. No title bar, no back button and no
/// filter chips: the content itself is the navigation, and the page is closed
/// by pulling in from either edge.
final class MediaGridViewController: UIViewController, UICollectionViewDataSource,
  UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate {

  enum Kind {
    case live
    case bangumi
  }

  var onClose: (() -> Void)?
  var onSelect: ((VideoItem) -> Void)?

  private let kind: Kind
  private let layout = UICollectionViewFlowLayout()
  private var collection: UICollectionView!
  private let status = UILabel()
  private var liveItems: [VideoItem] = []
  private var bangumiSections: [(title: String, items: [VideoItem])] = []
  private var page = 1
  private var loading = false
  private var hasMore = true
  private var lastLayoutWidth: CGFloat = 0
  private var closePan: UIPanGestureRecognizer?
  private var closeStartX: CGFloat = 0
  private var closeDirection: CGFloat = 1
  private var closing = false

  init(kind: Kind) {
    self.kind = kind
    super.init(nibName: nil, bundle: nil)
    modalPresentationStyle = .fullScreen
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = NativeTheme.background

    layout.minimumInteritemSpacing = 10
    layout.minimumLineSpacing = 18
    layout.sectionInset = UIEdgeInsets(top: 10, left: 16, bottom: 20, right: 16)

    let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collection.backgroundColor = .clear
    collection.dataSource = self
    collection.delegate = self
    collection.contentInsetAdjustmentBehavior = .never
    collection.showsVerticalScrollIndicator = false
    collection.register(LiveGridCell.self, forCellWithReuseIdentifier: LiveGridCell.reuseID)
    collection.register(BangumiPosterCell.self, forCellWithReuseIdentifier: BangumiPosterCell.reuseID)
    collection.register(MediaSectionHeader.self,
                        forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                        withReuseIdentifier: MediaSectionHeader.reuseID)
    view.addSubview(collection)
    collection.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      collection.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      collection.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      collection.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      collection.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    collection.contentInset = UIEdgeInsets(top: 4, left: 0, bottom: 16, right: 0)
    self.collection = collection

    status.font = NativeTheme.bodyFont(13)
    status.textColor = NativeTheme.secondary
    status.textAlignment = .center
    status.numberOfLines = 0
    status.isHidden = true
    view.addSubview(status)
    status.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      status.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      status.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      status.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
      status.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32),
    ])

    let pan = UIPanGestureRecognizer(target: self, action: #selector(handleClosePan(_:)))
    pan.delegate = self
    view.addGestureRecognizer(pan)
    closePan = pan
    collection.panGestureRecognizer.require(toFail: pan)

    if kind == .live {
      loadLive()
    } else {
      loadBangumi()
    }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    let width = collection.bounds.width
    if width > 0, abs(width - lastLayoutWidth) > 0.5 {
      lastLayoutWidth = width
      collection.collectionViewLayout.invalidateLayout()
    }
  }

  // MARK: - data

  private func loadLive() {
    guard !loading, hasMore else { return }
    loading = true
    if liveItems.isEmpty { showStatus("正在加载…") }
    BiliAPI.shared.live(page: page) { [weak self] result in
      guard let self = self else { return }
      self.loading = false
      switch result {
      case .failure(let error):
        if self.liveItems.isEmpty { self.showStatus(error.localizedDescription) }
      case .success(let items):
        self.liveItems.append(contentsOf: items)
        self.hasMore = !items.isEmpty
        self.page += 1
        self.collection.reloadData()
        if self.liveItems.isEmpty {
          self.showStatus("暂无直播")
        } else {
          self.hideStatus()
        }
      }
    }
  }

  private func loadBangumi() {
    guard !loading else { return }
    loading = true
    showStatus("正在加载…")
    let types: [(title: String, seasonType: Int)] = [
      ("连载中", 1), ("已完结", 4), ("剧场版", 2),
    ]
    var results: [Int: [VideoItem]] = [:]
    let group = DispatchGroup()
    for (index, type) in types.enumerated() {
      group.enter()
      BiliAPI.shared.bangumi(page: 1, seasonType: type.seasonType) { result in
        if case .success(let items) = result, !items.isEmpty {
          results[index] = items
        }
        group.leave()
      }
    }
    group.notify(queue: .main) { [weak self] in
      guard let self = self else { return }
      self.loading = false
      self.bangumiSections = types.enumerated().compactMap { index, type in
        guard let items = results[index], !items.isEmpty else { return nil }
        return (title: type.title, items: items)
      }
      self.collection.reloadData()
      if self.bangumiSections.isEmpty {
        self.showStatus("暂无番剧")
      } else {
        self.hideStatus()
      }
    }
  }

  private func showStatus(_ text: String) {
    status.text = text
    status.isHidden = false
  }

  private func hideStatus() {
    status.isHidden = true
  }

  // MARK: - collection

  func numberOfSections(in collectionView: UICollectionView) -> Int {
    switch kind {
    case .live: return 1
    case .bangumi: return bangumiSections.count
    }
  }

  func collectionView(_ collectionView: UICollectionView,
                      numberOfItemsInSection section: Int) -> Int {
    switch kind {
    case .live:
      return liveItems.count
    case .bangumi:
      guard bangumiSections.indices.contains(section) else { return 0 }
      return bangumiSections[section].items.count
    }
  }

  func collectionView(_ collectionView: UICollectionView,
                      cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    switch kind {
    case .live:
      let cell = collectionView.dequeueReusableCell(
        withReuseIdentifier: LiveGridCell.reuseID, for: indexPath) as! LiveGridCell
      guard liveItems.indices.contains(indexPath.item) else { return cell }
      cell.configure(liveItems[indexPath.item])
      return cell
    case .bangumi:
      let cell = collectionView.dequeueReusableCell(
        withReuseIdentifier: BangumiPosterCell.reuseID, for: indexPath) as! BangumiPosterCell
      guard bangumiSections.indices.contains(indexPath.section),
            bangumiSections[indexPath.section].items.indices.contains(indexPath.item) else {
        return cell
      }
      cell.configure(bangumiSections[indexPath.section].items[indexPath.item])
      return cell
    }
  }

  func collectionView(_ collectionView: UICollectionView,
                      viewForSupplementaryElementOfKind kind: String,
                      at indexPath: IndexPath) -> UICollectionReusableView {
    let header = collectionView.dequeueReusableSupplementaryView(
      ofKind: kind, withReuseIdentifier: MediaSectionHeader.reuseID,
      for: indexPath) as! MediaSectionHeader
    if self.kind == .bangumi, bangumiSections.indices.contains(indexPath.section) {
      header.configure(bangumiSections[indexPath.section].title)
    } else {
      header.configure("")
    }
    return header
  }

  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      sizeForItemAt indexPath: IndexPath) -> CGSize {
    let available = collectionView.bounds.width - 32 - 10
    let width = floor(max(1, available) / 2)
    switch kind {
    case .live:
      return CGSize(width: width, height: width * 9.0 / 16.0 + 54)
    case .bangumi:
      return CGSize(width: width, height: width * 4.0 / 3.0 + 54)
    }
  }

  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      referenceSizeForHeaderInSection section: Int) -> CGSize {
    guard kind == .bangumi, section < bangumiSections.count else { return .zero }
    return CGSize(width: collectionView.bounds.width, height: 34)
  }

  func collectionView(_ collectionView: UICollectionView,
                      didSelectItemAt indexPath: IndexPath) {
    switch kind {
    case .live:
      guard liveItems.indices.contains(indexPath.item) else { return }
      onSelect?(liveItems[indexPath.item])
    case .bangumi:
      guard bangumiSections.indices.contains(indexPath.section),
            bangumiSections[indexPath.section].items.indices.contains(indexPath.item) else {
        return
      }
      onSelect?(bangumiSections[indexPath.section].items[indexPath.item])
    }
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    guard kind == .live, !loading, hasMore else { return }
    if scrollView.contentOffset.y > scrollView.contentSize.height - scrollView.bounds.height * 2 {
      loadLive()
    }
  }

  // MARK: - edge dismissal

  @objc private func handleClosePan(_ gesture: UIPanGestureRecognizer) {
    guard !closing else { return }
    let width = max(1, view.bounds.width)
    let distance = closeDirection > 0
      ? max(0, gesture.translation(in: view).x)
      : max(0, -gesture.translation(in: view).x)
    switch gesture.state {
    case .changed:
      view.transform = CGAffineTransform(translationX: closeDirection * distance, y: 0)
    case .ended, .cancelled:
      let velocity = gesture.velocity(in: view).x * closeDirection
      if distance > width * 0.24 || velocity > 350 {
        closing = true
        UIView.animate(withDuration: 0.24, delay: 0,
                       options: [.curveEaseIn, .beginFromCurrentState]) {
          self.view.transform = CGAffineTransform(
            translationX: width * self.closeDirection, y: 0)
        } completion: { _ in
          self.view.isHidden = true
          self.onClose?()
        }
      } else {
        UIView.animate(withDuration: 0.24, delay: 0,
                       options: [.curveEaseOut, .beginFromCurrentState]) {
          self.view.transform = .identity
        }
      }
    default:
      break
    }
  }

  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                         shouldReceive touch: UITouch) -> Bool {
    if gestureRecognizer === closePan {
      closeStartX = touch.location(in: view).x
    }
    return true
  }

  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    guard let pan = gestureRecognizer as? UIPanGestureRecognizer,
          pan === closePan else { return true }
    let width = max(1, view.bounds.width)
    let translation = pan.translation(in: view)
    let velocity = pan.velocity(in: view)
    let horizontal = abs(translation.x) > abs(translation.y) * 1.15
      || abs(velocity.x) > abs(velocity.y) * 1.15
    guard horizontal else { return false }
    if closeStartX < width / 6.0 {
      closeDirection = 1
      return translation.x > 1 || velocity.x > 1
    }
    if closeStartX > width * 5.0 / 6.0 {
      closeDirection = -1
      return translation.x < -1 || velocity.x < -1
    }
    return false
  }
}

private final class LiveGridCell: UICollectionViewCell {
  static let reuseID = "LiveGridCell"

  private let cover = UIImageView()
  private let liveChip = UILabel()
  private let viewers = UILabel()
  private let title = UILabel()
  private let meta = UILabel()

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
    contentView.backgroundColor = .clear

    cover.contentMode = .scaleAspectFill
    cover.clipsToBounds = true
    cover.layer.cornerRadius = NativeTheme.cornerRadius
    cover.layer.cornerCurve = .continuous
    cover.backgroundColor = NativeTheme.tertiary.withAlphaComponent(0.15)
    contentView.addSubview(cover)

    liveChip.text = "直播"
    liveChip.font = UIFont.systemFont(ofSize: 9, weight: .bold)
    liveChip.textColor = .white
    liveChip.backgroundColor = NativeTheme.accent
    liveChip.textAlignment = .center
    liveChip.layer.cornerRadius = 4
    liveChip.clipsToBounds = true
    contentView.addSubview(liveChip)

    viewers.font = NativeTheme.numberFont(9)
    viewers.textColor = .white
    viewers.backgroundColor = UIColor.black.withAlphaComponent(0.62)
    viewers.layer.cornerRadius = 4
    viewers.clipsToBounds = true
    viewers.textAlignment = .center
    contentView.addSubview(viewers)

    title.font = UIFont.systemFont(ofSize: 13.5, weight: .semibold)
    title.textColor = NativeTheme.foreground
    title.numberOfLines = 2
    title.lineBreakMode = .byTruncatingTail
    contentView.addSubview(title)

    meta.font = NativeTheme.bodyFont(10.5)
    meta.textColor = NativeTheme.secondary
    meta.numberOfLines = 1
    meta.lineBreakMode = .byTruncatingTail
    contentView.addSubview(meta)

    [cover, liveChip, viewers, title, meta].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
    }
    NSLayoutConstraint.activate([
      cover.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      cover.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      cover.topAnchor.constraint(equalTo: contentView.topAnchor),
      cover.heightAnchor.constraint(equalTo: cover.widthAnchor, multiplier: 9.0 / 16.0),

      liveChip.leadingAnchor.constraint(equalTo: cover.leadingAnchor, constant: 6),
      liveChip.topAnchor.constraint(equalTo: cover.topAnchor, constant: 6),
      liveChip.widthAnchor.constraint(equalToConstant: 36),
      liveChip.heightAnchor.constraint(equalToConstant: 18),

      viewers.trailingAnchor.constraint(equalTo: cover.trailingAnchor, constant: -6),
      viewers.bottomAnchor.constraint(equalTo: cover.bottomAnchor, constant: -6),
      viewers.leadingAnchor.constraint(greaterThanOrEqualTo: cover.leadingAnchor, constant: 6),
      viewers.heightAnchor.constraint(equalToConstant: 16),

      title.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      title.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      title.topAnchor.constraint(equalTo: cover.bottomAnchor, constant: 6),

      meta.leadingAnchor.constraint(equalTo: title.leadingAnchor),
      meta.trailingAnchor.constraint(equalTo: title.trailingAnchor),
      meta.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 3),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(_ item: VideoItem) {
    title.text = item.title
    let area = item.area
    meta.text = area.isEmpty ? item.owner : "\(item.owner) · \(area)"
    let watching = item.online > 0 ? "\(o11a1Count(item.online)) 在看" : "直播中"
    viewers.text = "  \(watching)  "
    ImageLoader.shared.load(item.pic, into: cover)
  }
}

private final class BangumiPosterCell: UICollectionViewCell {
  static let reuseID = "BangumiPosterCell"

  private let cover = UIImageView()
  private let badge = UILabel()
  private let title = UILabel()
  private let meta = UILabel()

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
    contentView.backgroundColor = .clear

    cover.contentMode = .scaleAspectFill
    cover.clipsToBounds = true
    cover.layer.cornerRadius = NativeTheme.cornerRadius
    cover.layer.cornerCurve = .continuous
    cover.backgroundColor = NativeTheme.tertiary.withAlphaComponent(0.15)
    contentView.addSubview(cover)

    badge.font = UIFont.systemFont(ofSize: 8.5, weight: .semibold)
    badge.textColor = .white
    badge.backgroundColor = UIColor.black.withAlphaComponent(0.64)
    badge.textAlignment = .center
    badge.layer.cornerRadius = 4
    badge.clipsToBounds = true
    contentView.addSubview(badge)

    title.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
    title.textColor = NativeTheme.foreground
    title.numberOfLines = 2
    title.lineBreakMode = .byTruncatingTail
    contentView.addSubview(title)

    meta.font = NativeTheme.bodyFont(10.5)
    meta.textColor = NativeTheme.secondary
    meta.numberOfLines = 1
    meta.lineBreakMode = .byTruncatingTail
    contentView.addSubview(meta)

    [cover, badge, title, meta].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
    }
    NSLayoutConstraint.activate([
      cover.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      cover.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      cover.topAnchor.constraint(equalTo: contentView.topAnchor),
      cover.heightAnchor.constraint(equalTo: cover.widthAnchor, multiplier: 4.0 / 3.0),

      badge.leadingAnchor.constraint(equalTo: cover.leadingAnchor, constant: 6),
      badge.bottomAnchor.constraint(equalTo: cover.bottomAnchor, constant: -6),
      badge.heightAnchor.constraint(equalToConstant: 17),
      badge.widthAnchor.constraint(greaterThanOrEqualToConstant: 30),

      title.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      title.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      title.topAnchor.constraint(equalTo: cover.bottomAnchor, constant: 6),

      meta.leadingAnchor.constraint(equalTo: title.leadingAnchor),
      meta.trailingAnchor.constraint(equalTo: title.trailingAnchor),
      meta.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 3),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(_ item: VideoItem) {
    title.text = item.title
    meta.text = item.meta
    badge.text = item.badge.isEmpty ? "" : "  \(item.badge)  "
    badge.isHidden = item.badge.isEmpty
    ImageLoader.shared.load(item.pic, into: cover)
  }
}

private final class MediaSectionHeader: UICollectionReusableView {
  static let reuseID = "MediaSectionHeader"

  private let title = UILabel()

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = .clear
    title.font = UIFont.systemFont(ofSize: 13, weight: .bold)
    title.textColor = NativeTheme.foreground
    title.numberOfLines = 1
    addSubview(title)
    title.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      title.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      title.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16),
      title.centerYAnchor.constraint(equalTo: centerYAnchor),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(_ text: String) {
    title.text = text
  }
}
