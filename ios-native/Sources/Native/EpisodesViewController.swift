import UIKit

/// The multi-part (分P) panel. It mirrors the detail and recommendation pages:
/// a 56 pt frosted title bar over a plain row list.
final class EpisodesViewController: UIViewController, UITableViewDataSource,
  UITableViewDelegate, UIGestureRecognizerDelegate {
  var onSelect: ((VideoPage) -> Void)?
  var onScroll: ((CGFloat, CGFloat) -> Void)?
  var onPullDown: ((CGFloat) -> Void)?
  var onPullDownEnded: ((Bool) -> Void)?

  private let table = UITableView(frame: .zero, style: .plain)
  private let headerTitle = UILabel()
  private let headerBar = UIView()
  private let headerBlur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
  private let status = UILabel()
  private var pages: [VideoPage] = []
  private var currentCid: Int64 = 0
  private var lastDockScrollPosition: CGFloat?
  private var pullDownPan: UIPanGestureRecognizer?
  private var pullDownArmed = false

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
    table.rowHeight = 58
    table.estimatedRowHeight = 58
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

    let pull = UIPanGestureRecognizer(target: self, action: #selector(handlePullDown(_:)))
    pull.delegate = self
    view.addGestureRecognizer(pull)
    table.panGestureRecognizer.require(toFail: pull)
    pullDownPan = pull

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

  @objc private func handlePullDown(_ gesture: UIPanGestureRecognizer) {
    let reference = view.superview ?? view
    let translation = max(0, gesture.translation(in: reference).y)
    let progress = min(1, translation / 240)
    switch gesture.state {
    case .changed:
      onPullDown?(progress)
    case .ended, .cancelled:
      let velocity = gesture.velocity(in: reference).y
      onPullDownEnded?(progress > 0.35 || velocity > 450)
    default:
      break
    }
  }

  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                         shouldReceive touch: UITouch) -> Bool {
    if gestureRecognizer === pullDownPan {
      let x = touch.location(in: view).x
      let width = max(1, view.bounds.width)
      pullDownArmed = x < width / 6.0 || x > width * 5.0 / 6.0
    }
    return true
  }

  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    guard let pan = gestureRecognizer as? UIPanGestureRecognizer,
          pan === pullDownPan else { return true }
    guard pullDownArmed else { return false }
    let velocity = pan.velocity(in: view)
    let translation = pan.translation(in: view)
    return (translation.y > 2 && abs(translation.y) > abs(translation.x) * 1.1)
      || (velocity.y > 60 && abs(velocity.y) > abs(velocity.x) * 1.1)
  }
}

private final class EpisodeRowCell: UITableViewCell {
  static let reuseID = "EpisodeRowCell"

  private let titleLabel = UILabel()
  private let durationLabel = UILabel()
  private let separator = UIView()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    titleLabel.font = UIFont.systemFont(ofSize: 14.5, weight: .medium)
    titleLabel.textColor = NativeTheme.foreground
    titleLabel.numberOfLines = 1
    titleLabel.lineBreakMode = .byTruncatingTail
    contentView.addSubview(titleLabel)

    durationLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)
    durationLabel.textColor = NativeTheme.tertiary
    durationLabel.textAlignment = .right
    durationLabel.setContentHuggingPriority(.required, for: .horizontal)
    durationLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    contentView.addSubview(durationLabel)

    separator.backgroundColor = NativeTheme.hairline
    contentView.addSubview(separator)

    [titleLabel, durationLabel, separator].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
    }
    NSLayoutConstraint.activate([
      titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
      titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: durationLabel.leadingAnchor, constant: -12),

      durationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
      durationLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

      separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
      separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
      separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      separator.heightAnchor.constraint(equalToConstant: 0.5),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(_ page: VideoPage, current: Bool) {
    titleLabel.text = page.title.isEmpty ? "第 \(page.page) P" : page.title
    titleLabel.textColor = current ? NativeTheme.navBlue : NativeTheme.foreground
    durationLabel.text = EpisodeRowCell.timeText(page.duration)
    durationLabel.textColor = current ? NativeTheme.navBlue : NativeTheme.tertiary
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
