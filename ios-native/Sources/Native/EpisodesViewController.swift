import UIKit

/// The multi-part (分P) panel. It mirrors the detail and recommendation pages:
/// a 56 pt frosted title bar over a plain row list.
final class EpisodesViewController: UIViewController, UITableViewDataSource,
  UITableViewDelegate {
  var onSelect: ((VideoPage) -> Void)?
  var onScroll: ((CGFloat, CGFloat) -> Void)?

  private let table = UITableView(frame: .zero, style: .plain)
  private let headerTitle = UILabel()
  private let headerBar = UIView()
  private let headerBlur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
  private let status = UILabel()
  private var pages: [VideoPage] = []
  private var currentCid: Int64 = 0
  private var lastDockScrollPosition: CGFloat?

  init(pages: [VideoPage], currentCid: Int64) {
    self.pages = pages
    self.currentCid = currentCid
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = NativeTheme.surface

    headerTitle.text = "分集"
    headerTitle.font = UIFont.systemFont(ofSize: 16, weight: .bold)
    headerTitle.textColor = NativeTheme.foreground
    view.addSubview(headerTitle)
    headerTitle.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      headerTitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
      headerTitle.centerYAnchor.constraint(equalTo: view.topAnchor, constant: 28),
    ])

    table.backgroundColor = .clear
    table.separatorStyle = .none
    table.dataSource = self
    table.delegate = self
    table.register(EpisodeRowCell.self, forCellReuseIdentifier: EpisodeRowCell.reuseID)
    table.rowHeight = 64
    table.estimatedRowHeight = 64
    table.contentInsetAdjustmentBehavior = .never
    table.showsVerticalScrollIndicator = false
    view.addSubview(table)
    table.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      table.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      table.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      table.topAnchor.constraint(equalTo: view.topAnchor),
      table.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    headerBar.backgroundColor = .clear
    headerBar.isUserInteractionEnabled = false
    view.addSubview(headerBar)
    headerBar.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      headerBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      headerBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      headerBar.topAnchor.constraint(equalTo: view.topAnchor),
      headerBar.heightAnchor.constraint(equalToConstant: 56),
    ])

    headerBlur.isUserInteractionEnabled = false
    headerBlur.clipsToBounds = true
    headerBlur.contentView.backgroundColor = NativeTheme.glassWhite
    headerBar.addSubview(headerBlur)
    headerBlur.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      headerBlur.leadingAnchor.constraint(equalTo: headerBar.leadingAnchor),
      headerBlur.trailingAnchor.constraint(equalTo: headerBar.trailingAnchor),
      headerBlur.topAnchor.constraint(equalTo: headerBar.topAnchor),
      headerBlur.bottomAnchor.constraint(equalTo: headerBar.bottomAnchor),
    ])

    let headerLine = UIView()
    headerLine.backgroundColor = NativeTheme.hairline
    headerLine.isUserInteractionEnabled = false
    headerBar.addSubview(headerLine)
    headerLine.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      headerLine.leadingAnchor.constraint(equalTo: headerBar.leadingAnchor, constant: 18),
      headerLine.trailingAnchor.constraint(equalTo: headerBar.trailingAnchor, constant: -18),
      headerLine.bottomAnchor.constraint(equalTo: headerBar.bottomAnchor),
      headerLine.heightAnchor.constraint(equalToConstant: 0.5),
    ])

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

    view.bringSubviewToFront(headerBar)
    view.bringSubviewToFront(headerTitle)
    scrollToCurrent(animated: false)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    let top: CGFloat = 56
    let bottom: CGFloat = 96 + view.safeAreaInsets.bottom
    table.contentInset = UIEdgeInsets(top: top, left: 0, bottom: bottom, right: 0)
    table.verticalScrollIndicatorInsets.top = top
    table.verticalScrollIndicatorInsets.bottom = 60
  }

  func update(pages: [VideoPage], currentCid: Int64) {
    self.pages = pages
    self.currentCid = currentCid
    status.text = pages.isEmpty ? "暂无分集" : nil
    status.isHidden = !pages.isEmpty
    table.reloadData()
    scrollToCurrent(animated: false)
  }

  func setCurrentCid(_ cid: Int64) {
    guard currentCid != cid else { return }
    currentCid = cid
    table.reloadData()
  }

  private func scrollToCurrent(animated: Bool) {
    guard isViewLoaded,
          let index = pages.firstIndex(where: { $0.cid == currentCid }) else { return }
    table.layoutIfNeeded()
    let row = IndexPath(row: index, section: 0)
    if table.numberOfRows(inSection: 0) > index {
      table.scrollToRow(at: row, at: .middle, animated: animated)
    }
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return pages.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: EpisodeRowCell.reuseID, for: indexPath) as! EpisodeRowCell
    let page = pages[indexPath.row]
    cell.configure(page, current: page.cid == currentCid)
    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: false)
    guard pages.indices.contains(indexPath.row) else { return }
    let page = pages[indexPath.row]
    guard page.cid != currentCid else { return }
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    currentCid = page.cid
    table.reloadData()
    onSelect?(page)
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    guard scrollView.isDragging else {
      lastDockScrollPosition = nil
      return
    }
    let position = scrollView.contentOffset.y + scrollView.contentInset.top
    if let last = lastDockScrollPosition {
      let delta = position - last
      if abs(delta) > 2 {
        onScroll?(delta, position)
      }
    }
    lastDockScrollPosition = position
  }
}

private final class EpisodeRowCell: UITableViewCell {
  static let reuseID = "EpisodeRowCell"

  private let indexLabel = UILabel()
  private let titleLabel = UILabel()
  private let durationLabel = UILabel()
  private let playingLabel = UILabel()
  private let separator = UIView()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    indexLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)
    indexLabel.textColor = NativeTheme.secondary
    indexLabel.textAlignment = .center
    indexLabel.clipsToBounds = true
    indexLabel.layer.cornerRadius = 11
    indexLabel.layer.cornerCurve = .continuous
    indexLabel.backgroundColor = NativeTheme.foreground.withAlphaComponent(0.06)
    indexLabel.widthAnchor.constraint(equalToConstant: 22).isActive = true
    indexLabel.heightAnchor.constraint(equalToConstant: 22).isActive = true
    contentView.addSubview(indexLabel)

    titleLabel.font = UIFont.systemFont(ofSize: 14.5, weight: .medium)
    titleLabel.textColor = NativeTheme.foreground
    titleLabel.numberOfLines = 2
    titleLabel.lineBreakMode = .byTruncatingTail
    contentView.addSubview(titleLabel)

    durationLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)
    durationLabel.textColor = NativeTheme.tertiary
    durationLabel.textAlignment = .right
    durationLabel.setContentHuggingPriority(.required, for: .horizontal)
    durationLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    contentView.addSubview(durationLabel)

    playingLabel.text = "播放中"
    playingLabel.font = UIFont.systemFont(ofSize: 10, weight: .semibold)
    playingLabel.textColor = NativeTheme.navBlue
    playingLabel.textAlignment = .right
    playingLabel.setContentHuggingPriority(.required, for: .horizontal)
    contentView.addSubview(playingLabel)

    separator.backgroundColor = NativeTheme.hairline
    contentView.addSubview(separator)

    [indexLabel, titleLabel, durationLabel, playingLabel, separator].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
    }
    NSLayoutConstraint.activate([
      indexLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
      indexLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

      titleLabel.leadingAnchor.constraint(equalTo: indexLabel.trailingAnchor, constant: 12),
      titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
      titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: durationLabel.leadingAnchor, constant: -10),
      titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -10),

      playingLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
      playingLabel.centerYAnchor.constraint(equalTo: indexLabel.centerYAnchor, constant: -8),
      durationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
      durationLabel.centerYAnchor.constraint(equalTo: indexLabel.centerYAnchor, constant: 8),

      separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 54),
      separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
      separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      separator.heightAnchor.constraint(equalToConstant: 0.5),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(_ page: VideoPage, current: Bool) {
    indexLabel.text = "\(page.page)"
    indexLabel.textColor = current ? NativeTheme.background : NativeTheme.secondary
    indexLabel.backgroundColor = current
      ? NativeTheme.foreground
      : NativeTheme.foreground.withAlphaComponent(0.06)
    titleLabel.text = page.title.isEmpty ? "第 \(page.page) P" : page.title
    titleLabel.textColor = current ? NativeTheme.navBlue : NativeTheme.foreground
    durationLabel.text = EpisodeRowCell.timeText(page.duration)
    playingLabel.isHidden = !current
  }

  private static func timeText(_ seconds: Int) -> String {
    guard seconds > 0 else { return "" }
    let hours = seconds / 3600
    let minutes = (seconds % 3600) / 60
    let secs = seconds % 60
    if hours > 0 {
      return String(format: "%d:%02d:%02d", hours, minutes, secs)
    }
    return String(format: "%02d:%02d", minutes, secs)
  }
}
