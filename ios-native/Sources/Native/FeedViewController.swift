import UIKit

final class FeedViewController: UIViewController,
  UITableViewDataSource,
  UITableViewDelegate,
  UIGestureRecognizerDelegate {

  var onOpen: ((VideoItem, UIView) -> Void)?
  var onOpenPreview: ((VideoItem, UIView, PreviewHandoff) -> Void)?
  var onProfile: ((Int64) -> Void)?
  var onToolbar: ((Bool) -> Void)?
  var onSearchOpen: ((VideoItem) -> Void)?
  var onSeason: ((VideoItem) -> Void)?
  var onSidebar: (() -> Void)?
  var onSidebarPanBegan: (() -> Void)?
  var onSidebarPanChanged: ((CGFloat) -> Void)?
  var onSidebarPanEnded: ((CGFloat, CGFloat) -> Void)?
  var initialSource: (source: String, title: String)?

  private(set) var items: [VideoItem] = []
  private let table = UITableView(frame: .zero, style: .plain)
  private let statusLabel = UILabel()
  private let topFade = TopBlurView()
  private let previewEngine = VideoEngine()
  private lazy var previewView = PlayerLayerView(playerLayer: previewEngine.playerLayer)
  private var previewCell: HomeCardCell?
  private var previewIndex = -1
  private var previewToken = 0
  private var previewSuspended = false
  private var previewScrubbing = false
  private var previewSource: PlaySource?
  private var previewItemKey = ""
  private var nextPage = 1
  private var fresh = 1
  private var loading = false
  private var hasMore = true
  private var lastOffset: CGFloat = 0
  private var toolbarHidden = false
  private var toolbarWasHidden = false
  private var searchController: SearchViewController?
  private var searchPan: UIPanGestureRecognizer?
  private var sidebarPan: UIPanGestureRecognizer?
  private var searchOpen = false
  private var searchProgress: CGFloat = 0
  private var searchKeyboardShown = false
  private var searchPanStartX: CGFloat = 0
  private var sidebarPanStartX: CGFloat = 0
  private var feedScrollingAtTouch = false
  private var homeSource = "recommend"
  private var sourceTitle = "推荐"
  private var sourceToken = 0

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = NativeTheme.background

    table.backgroundColor = .clear
    table.separatorStyle = .none
    table.dataSource = self
    table.delegate = self
    table.register(HomeCardCell.self, forCellReuseIdentifier: HomeCardCell.reuseID)
    table.register(HomeGridCell.self, forCellReuseIdentifier: HomeGridCell.reuseID)
    table.rowHeight = UITableView.automaticDimension
    table.estimatedRowHeight = 360
    table.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 138, right: 0)
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

    topFade.isUserInteractionEnabled = false
    view.addSubview(topFade)
    topFade.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      topFade.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      topFade.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      topFade.topAnchor.constraint(equalTo: view.topAnchor),
    ])

    statusLabel.font = NativeTheme.bodyFont(14)
    statusLabel.textColor = NativeTheme.secondary
    statusLabel.textAlignment = .center
    statusLabel.numberOfLines = 0
    statusLabel.isHidden = true
    view.addSubview(statusLabel)
    statusLabel.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      statusLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
      statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32),
    ])

    previewEngine.playerLayer.videoGravity = .resizeAspectFill
    previewEngine.onReady = { [weak self] in
      guard let self = self, !self.previewSuspended else { return }
      self.previewCell?.hidePreviewLoading()
      self.previewView.alpha = 1
      self.previewEngine.play()
    }
    previewEngine.onError = { [weak self] _ in
      self?.previewCell?.hidePreviewLoading()
      self?.previewSource = nil
      self?.previewItemKey = ""
      self?.previewView.alpha = 0
      self?.previewCell?.setPreviewProgress(nil)
    }
    previewEngine.onTime = { [weak self] seconds, duration in
      guard let self = self, !self.previewSuspended, !self.previewScrubbing,
            duration > 0,
            let cell = self.previewCell else { return }
      cell.setPreviewProgress(CGFloat(max(0, min(1, seconds / duration))),
                              current: seconds, total: duration)
    }
    previewView.alpha = 0
    previewView.isUserInteractionEnabled = false

    let search = SearchViewController()
    search.onClose = { [weak self] in self?.closeSearch(animated: true) }
    search.onInteractiveClose = { [weak self] progress in
      self?.updateSearchProgress(progress)
    }
    search.onCloseSettled = { [weak self] shouldClose in
      self?.settleSearch(open: !shouldClose)
    }
    search.onOpenVideo = { [weak self] item in
      self?.onSearchOpen?(item)
    }
    addChild(search)
    search.view.frame = CGRect(x: view.bounds.width, y: 0,
                               width: view.bounds.width, height: view.bounds.height)
    search.view.autoresizingMask = [.flexibleHeight]
    view.addSubview(search.view)
    search.didMove(toParent: self)
    search.view.isHidden = true
    searchController = search

    let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
    pan.delegate = self
    view.addGestureRecognizer(pan)
    searchPan = pan
    table.panGestureRecognizer.require(toFail: pan)

    let sidebar = UIPanGestureRecognizer(target: self, action: #selector(handleSidebarPan(_:)))
    sidebar.delegate = self
    view.addGestureRecognizer(sidebar)
    sidebarPan = sidebar
    table.panGestureRecognizer.require(toFail: sidebar)

    if let initial = initialSource {
      homeSource = initial.source
      sourceTitle = initial.title
    }
    NotificationCenter.default.addObserver(
      self, selector: #selector(feedLayoutChanged),
      name: HomeFeedLayout.changed, object: nil)
    load(reset: true)
  }

  override func viewSafeAreaInsetsDidChange() {
    super.viewSafeAreaInsetsDidChange()
    updateInsets()
  }

  private func updateInsets() {
    let insets = view.safeAreaInsets
    table.contentInset = UIEdgeInsets(top: insets.top, left: 0,
                                      bottom: 122 + insets.bottom, right: 0)
    table.verticalScrollIndicatorInsets.top = insets.top
    topFade.updateHeight(safeAreaTop: insets.top)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    updateInsets()
    if let search = searchController {
      let width = max(1, view.bounds.width)
      let progress = max(0, min(1, searchProgress))
      search.view.frame = CGRect(x: width * (1 - progress), y: 0,
                                 width: width, height: view.bounds.height)
    }
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if !searchOpen {
      startPreviewIfNeeded()
    }
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    previewSuspended = true
    previewEngine.pause()
    previewCell?.setPreviewProgress(nil)
  }

  // MARK: - data

  func setSource(_ source: String, title: String) {
    guard source != homeSource || items.isEmpty else { return }
    homeSource = source
    sourceTitle = title
    sourceToken += 1
    loading = false
    hasMore = source != "none" && source != "dynamic" && source != "fish"
    nextPage = 1
    fresh = 1
    items = []
    previewIndex = -1
    previewCell?.setPreviewProgress(nil)
    previewCell = nil
    previewSuspended = true
    previewEngine.stop()
    statusLabel.isHidden = true
    table.reloadData()
    table.setContentOffset(CGPoint(x: 0, y: -table.contentInset.top), animated: false)
    load(reset: true)
  }

  private func load(reset: Bool) {
    guard !loading else { return }
    if reset {
      nextPage = 1
      fresh = 1
      hasMore = homeSource != "none" && homeSource != "dynamic" && homeSource != "fish"
    }
    if homeSource == "none" {
      showEmpty("暂时没有内容\n下拉刷新试试")
      return
    }
    if homeSource == "dynamic" {
      showEmpty("动态请在底部「动态」查看")
      return
    }
    if homeSource == "fish" {
      showEmpty("养鱼请在底部「养鱼」查看")
      return
    }
    guard hasMore else { return }
    loading = true
    if reset && items.isEmpty {
      statusLabel.text = "正在加载\(sourceTitle)…"
      statusLabel.isHidden = false
    }
    let pageValue = nextPage
    let token = sourceToken
    let done: (Result<[VideoItem], Error>) -> Void = { [weak self] result in
      guard let self = self, token == self.sourceToken else { return }
      self.loading = false
      switch result {
      case .failure(let error):
        if self.items.isEmpty {
          self.statusLabel.text = error.localizedDescription + "\n轻触屏幕重试"
          self.statusLabel.isHidden = false
          let tap = UITapGestureRecognizer(target: self, action: #selector(self.retry))
          self.view.addGestureRecognizer(tap)
        }
      case .success(let values):
        self.finish(values, reset: reset)
      }
    }
    switch homeSource {
    case "hot":
      BiliAPI.shared.popularItems(page: pageValue, completion: done)
    case "rank":
      BiliAPI.shared.ranking(page: pageValue, completion: done)
    case "following":
      BiliAPI.shared.following(page: pageValue, completion: done)
    case "favorites":
      BiliAPI.shared.favorites(page: pageValue, completion: done)
    case "history":
      BiliAPI.shared.history(page: pageValue, completion: done)
    case "zone":
      BiliAPI.shared.zone(rid: 1, page: pageValue, completion: done)
    case "bangumi":
      BiliAPI.shared.bangumi(page: pageValue, seasonType: 1, completion: done)
    case "movie":
      BiliAPI.shared.bangumi(page: pageValue, seasonType: 2, completion: done)
    case "live":
      BiliAPI.shared.live(page: pageValue, completion: done)
    default:
      BiliAPI.shared.recommend(page: pageValue, fresh: fresh) { [weak self] result in
        guard let self = self, token == self.sourceToken else { return }
        self.loading = false
        switch result {
        case .failure(let error):
          if self.items.isEmpty {
            self.statusLabel.text = error.localizedDescription + "\n轻触屏幕重试"
            self.statusLabel.isHidden = false
          }
        case .success(let feed):
          self.finish(feed.items, reset: reset)
          self.fresh += 1
        }
      }
    }
  }

  private func finish(_ values: [VideoItem], reset: Bool) {
    let oldCount = items.count
    if reset {
      items = values
    } else {
      var existing = Set(items.map { "\($0.bvid)-\($0.roomId)" })
      for item in values where !existing.contains("\(item.bvid)-\(item.roomId)") {
        items.append(item)
        existing.insert("\(item.bvid)-\(item.roomId)")
      }
    }
    hasMore = !values.isEmpty
    nextPage += 1
    statusLabel.isHidden = !items.isEmpty
    if items.isEmpty {
      statusLabel.text = "\(sourceTitle)暂时没有内容\n轻触屏幕重试"
      statusLabel.isHidden = false
    }
    if reset {
      table.reloadData()
    } else if items.count != oldCount {
      appendLoadedRows(from: oldCount)
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      self.startPreviewIfNeeded()
      self.loadMoreIfNeeded()
    }
  }

  /// Appending a page keeps every visible cell alive and only touches the rows
  /// the new items belong to, so the grid grows without a table-wide reload.
  private func appendLoadedRows(from oldCount: Int) {
    let newCount = items.count
    guard newCount > oldCount else { return }
    if HomeFeedLayout.isGrid {
      let oldRows = (oldCount + 1) / 2
      let newRows = (newCount + 1) / 2
      guard oldRows > 0 else {
        table.reloadData()
        return
      }
      var reloadPaths: [IndexPath] = []
      if oldCount % 2 == 1 {
        reloadPaths.append(IndexPath(row: oldRows - 1, section: 0))
      }
      var insertPaths: [IndexPath] = []
      if newRows > oldRows {
        for row in oldRows..<newRows {
          insertPaths.append(IndexPath(row: row, section: 0))
        }
      }
      guard !reloadPaths.isEmpty || !insertPaths.isEmpty else { return }
      table.performBatchUpdates {
        if !reloadPaths.isEmpty {
          self.table.reloadRows(at: reloadPaths, with: .none)
        }
        if !insertPaths.isEmpty {
          self.table.insertRows(at: insertPaths, with: .none)
        }
      }
    } else {
      var insertPaths: [IndexPath] = []
      for row in oldCount..<newCount {
        insertPaths.append(IndexPath(row: row, section: 0))
      }
      guard !insertPaths.isEmpty else { return }
      table.performBatchUpdates {
        self.table.insertRows(at: insertPaths, with: .none)
      }
    }
  }

  private func loadMoreIfNeeded() {
    guard !loading, hasMore, !searchOpen, !items.isEmpty else { return }
    let threshold = table.contentSize.height - table.bounds.height * 2.2
    guard table.contentOffset.y > threshold else { return }
    load(reset: false)
  }

  private func showEmpty(_ text: String) {
    loading = false
    hasMore = false
    items = []
    table.reloadData()
    statusLabel.text = text
    statusLabel.isHidden = false
  }

  @objc private func retry() {
    guard items.isEmpty, !loading else { return }
    statusLabel.isHidden = true
    load(reset: true)
  }

  // MARK: - table

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return HomeFeedLayout.isGrid ? (items.count + 1) / 2 : items.count
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    guard HomeFeedLayout.isGrid else { return UITableView.automaticDimension }
    let available = tableView.bounds.width
      - HomeGridCell.sideInset * 2
      - HomeGridCell.columnSpacing
    let cardWidth = max(1, available / 2)
    return HomeGridCell.verticalInset * 2
      + cardWidth * 3.0 / 4.0
      + HomeGridCell.infoHeight
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if HomeFeedLayout.isGrid {
      let cell = tableView.dequeueReusableCell(
        withIdentifier: HomeGridCell.reuseID, for: indexPath) as! HomeGridCell
      let leftIndex = indexPath.row * 2
      guard leftIndex < items.count else { return cell }
      let left = items[leftIndex]
      let right = leftIndex + 1 < items.count ? items[leftIndex + 1] : nil
      cell.configure(left, right)
      cell.onOpen = { [weak self] item, card in
        self?.open(item, source: card)
      }
      return cell
    }
    let cell = tableView.dequeueReusableCell(
      withIdentifier: HomeCardCell.reuseID, for: indexPath) as! HomeCardCell
    let item = items[indexPath.row]
    cell.configure(item)
    cell.onOpen = { [weak self, weak cell] in
      guard let self = self, let cell = cell else { return }
      self.open(item, source: cell)
    }
    cell.onAvatar = { [weak self] in
      self?.onProfile?(item.mid)
    }
    cell.onPreviewScrub = { [weak self, weak cell] ratio, finished in
      guard let self = self, let cell = cell,
            self.previewCell === cell else { return }
      let duration = self.previewEngine.duration
      guard duration > 0 else { return }
      if !finished {
        if !self.previewScrubbing {
          self.previewScrubbing = true
          self.previewEngine.pause()
        }
        cell.setPreviewProgress(ratio,
                                current: duration * Double(ratio),
                                total: duration)
      } else {
        self.previewScrubbing = false
        self.previewEngine.seek(to: duration * Double(ratio), resume: true)
        self.previewEngine.play()
      }
    }
    if indexPath.row == previewIndex, previewCell === cell {
      attachPreview(cell)
    }
    return cell
  }

  private func open(_ item: VideoItem, source: UIView) {
    if item.seasonId > 0 || item.kind == "season" {
      onSeason?(item)
      return
    }
    if let cell = source as? HomeCardCell, previewCell === cell,
       let handoff = previewHandoffFor(item),
       let openPreview = onOpenPreview {
      openPreview(item, source, handoff)
      return
    }
    onOpen?(item, source)
  }

  private func previewHandoffFor(_ item: VideoItem) -> PreviewHandoff? {
    guard let source = previewSource, !source.url.isEmpty,
          previewEngine.player.currentItem != nil,
          previewItemKey == "\(item.bvid)-\(item.cid)" else { return nil }
    return PreviewHandoff(
      url: source.url,
      backup: source.backup,
      seconds: previewEngine.currentTime,
      duration: previewEngine.duration,
      quality: source.quality,
      qualityLabel: source.qualityLabel
    )
  }

  @objc private func feedLayoutChanged() {
    previewEngine.pause()
    previewView.alpha = 0
    previewCell?.setPreviewProgress(nil)
    previewCell = nil
    previewIndex = -1
    table.reloadData()
    table.layoutIfNeeded()
    startPreviewIfNeeded()
    loadMoreIfNeeded()
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    let delta = scrollView.contentOffset.y - lastOffset
    if abs(delta) > 8 && !searchOpen {
      if delta > 0 && !toolbarHidden && scrollView.contentOffset.y > 24 {
        toolbarHidden = true
        onToolbar?(true)
      } else if delta < 0 && toolbarHidden {
        toolbarHidden = false
        onToolbar?(false)
      }
    }
    lastOffset = scrollView.contentOffset.y
    loadMoreIfNeeded()
  }

  func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if !decelerate {
      startPreviewIfNeeded()
    }
  }

  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    startPreviewIfNeeded()
    if scrollView.contentOffset.y <= 4 && toolbarHidden {
      toolbarHidden = false
      onToolbar?(false)
    }
  }

  // MARK: - preview

  private func startPreviewIfNeeded() {
    guard !previewSuspended, !searchOpen, !items.isEmpty else { return }
    if HomeFeedLayout.isGrid {
      previewEngine.pause()
      previewView.alpha = 0
      previewCell?.hidePreviewLoading()
      previewCell?.setPreviewProgress(nil)
      previewCell = nil
      previewIndex = -1
      return
    }
    let center = table.contentOffset.y + table.bounds.height / 2
    var bestRow = 0
    var bestDistance = CGFloat.greatestFiniteMagnitude
    for indexPath in table.indexPathsForVisibleRows ?? [] {
      let rect = table.rectForRow(at: indexPath)
      let distance = abs(rect.midY - center)
      if distance < bestDistance {
        bestDistance = distance
        bestRow = indexPath.row
      }
    }
    guard let cell = table.cellForRow(at: IndexPath(row: bestRow, section: 0)) as? HomeCardCell else {
      return
    }
    if previewCell !== cell {
      previewCell?.hidePreviewLoading()
      previewCell?.setPreviewProgress(nil)
      previewScrubbing = false
    }
    previewIndex = bestRow
    previewCell = cell
    previewSuspended = false
    if previewEngine.player.currentItem != nil, previewView.superview === cell.mediaHost {
      cell.hidePreviewLoading()
      previewView.alpha = 1
      previewEngine.play()
      return
    }
    attachPreview(cell)
    cell.setPreviewProgress(0)
    cell.showPreviewLoading()
    previewView.alpha = 0
    previewToken += 1
    let token = previewToken
    let item = items[bestRow]
    previewSource = nil
    previewItemKey = ""
    previewEngine.stop()
    BiliAPI.shared.playQuality(item, qn: ThemeManager.shared.quality) {
      [weak self] result in
      guard let self = self, token == self.previewToken,
            !self.previewSuspended else { return }
      guard let current = self.table.cellForRow(at: IndexPath(row: bestRow, section: 0)) as? HomeCardCell else {
        return
      }
      guard case .success(let source) = result else {
        current.hidePreviewLoading()
        return
      }
      current.showPreviewLoading()
      self.previewSource = source
      self.previewItemKey = "\(item.bvid)-\(item.cid)"
      self.attachPreview(current)
      self.previewEngine.load(
        url: source.url,
        backup: source.backup,
        headers: BiliAPI.shared.mediaHeaders,
        autoplay: true,
        muted: false,
        loop: true
      )
    }
  }

  private func attachPreview(_ cell: HomeCardCell) {
    guard previewView.superview !== cell.mediaHost else { return }
    previewView.removeFromSuperview()
    previewView.frame = cell.mediaHost.bounds
    previewView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    cell.mediaHost.addSubview(previewView)
  }

  func suspendPreview() {
    previewSuspended = true
    previewScrubbing = false
    previewToken += 1
    previewEngine.stop()
    previewView.removeFromSuperview()
    previewView.alpha = 0
    previewCell?.hidePreviewLoading()
    previewCell?.setPreviewProgress(nil)
    previewCell = nil
    previewIndex = -1
    previewSource = nil
    previewItemKey = ""
  }

  func resumePreview() {
    guard !searchOpen else { return }
    previewSuspended = false
    startPreviewIfNeeded()
  }

  func openFirstForTest() {
    guard !items.isEmpty else {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
        self?.openFirstForTest()
      }
      return
    }
    table.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
    table.layoutIfNeeded()
    let cell = table.cellForRow(at: IndexPath(row: 0, section: 0))
    if let home = cell as? HomeCardCell {
      open(items[0], source: home)
    } else if let grid = cell as? HomeGridCell {
      open(items[0], source: grid.leftCard)
    } else {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
        self?.openFirstForTest()
      }
    }
  }

  // MARK: - gestures

  func isFeedScrolling() -> Bool {
    return table.isDragging || table.isDecelerating
  }

  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                         shouldReceive touch: UITouch) -> Bool {
    if gestureRecognizer === searchPan || gestureRecognizer === sidebarPan {
      feedScrollingAtTouch = isFeedScrolling()
    }
    if gestureRecognizer === searchPan {
      searchPanStartX = touch.location(in: view).x
    }
    if gestureRecognizer === sidebarPan {
      sidebarPanStartX = touch.location(in: view).x
    }
    return true
  }

  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
    if pan === searchPan || pan === sidebarPan {
      guard !feedScrollingAtTouch, !isFeedScrolling() else { return false }
    }
    let width = max(1, view.bounds.width)
    let velocity = pan.velocity(in: view)
    let translation = pan.translation(in: view)
    let horizontal = abs(translation.x) > abs(translation.y) * 1.1
      || abs(velocity.x) > abs(velocity.y) * 1.1
    if pan === searchPan {
      guard !searchOpen else { return false }
      guard searchPanStartX >= width * 2.0 / 3.0 else { return false }
      let movingLeft = translation.x < -1 || velocity.x < -1
      return horizontal && movingLeft
    }
    if pan === sidebarPan {
      guard !searchOpen else { return false }
      guard sidebarPanStartX <= width / 3.0 else { return false }
      let movingRight = translation.x > 1 || velocity.x > 1
      return horizontal && movingRight
    }
    return true
  }

  @objc private func handleSidebarPan(_ gesture: UIPanGestureRecognizer) {
    let width = max(1, view.bounds.width)
    let translation = gesture.translation(in: view).x
    switch gesture.state {
    case .began:
      suspendPreview()
      onSidebarPanBegan?()
    case .changed:
      onSidebarPanChanged?(translation / (width * 0.50))
    case .ended, .cancelled:
      let velocity = gesture.velocity(in: view).x
      onSidebarPanEnded?(translation, velocity)
    default:
      break
    }
  }

  @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
    guard searchController != nil else { return }
    let width = max(1, view.bounds.width)
    let translation = max(0, -gesture.translation(in: view).x)
    switch gesture.state {
    case .began:
      suspendPreview()
      beginSearchInteractive()
    case .changed:
      updateSearchProgress(translation / width)
    case .ended, .cancelled:
      let velocity = -gesture.velocity(in: view).x
      let progress = translation / width
      settleSearch(open: progress > 0.26 || velocity > 350)
    default:
      break
    }
  }

  private func updateSearchProgress(_ value: CGFloat) {
    guard let search = searchController else { return }
    let width = max(1, view.bounds.width)
    let progress = max(0, min(1, value))
    searchProgress = progress
    search.view.frame = CGRect(x: width * (1 - progress), y: 0,
                               width: width, height: view.bounds.height)
    table.transform = CGAffineTransform(translationX: -width * 0.18 * progress, y: 0)
    if searchOpen {
      if progress > 0.28 && !searchKeyboardShown {
        searchKeyboardShown = true
        search.focusNow()
      } else if progress < 0.58 && searchKeyboardShown {
        searchKeyboardShown = false
        search.resignKeyboard()
      }
    }
  }

  private func beginSearchInteractive() {
    guard let search = searchController else { return }
    searchOpen = true
    search.view.isHidden = false
    view.bringSubviewToFront(search.view)
    previewEngine.pause()
    table.transform = .identity
    updateSearchProgress(0)
    toolbarWasHidden = toolbarHidden
    onToolbar?(true)
  }

  private func settleSearch(open: Bool) {
    guard let search = searchController else { return }
    searchOpen = open
    if !open {
      searchKeyboardShown = false
      search.resignKeyboard()
    }
    let changes = {
      self.updateSearchProgress(open ? 1 : 0)
    }
    UIView.animate(withDuration: open ? 0.30 : 0.26, delay: 0,
                   usingSpringWithDamping: open ? 0.9 : 1,
                   initialSpringVelocity: 0,
                   options: [.curveEaseOut, .allowUserInteraction],
                   animations: changes) { [weak self] _ in
      guard let self = self else { return }
      if open {
        search.focusNow()
        self.searchKeyboardShown = true
      } else {
        search.view.isHidden = true
        self.table.transform = .identity
        self.onToolbar?(self.toolbarWasHidden)
        self.startPreviewIfNeeded()
        if !self.searchOpen {
          search.reset()
        }
      }
    }
  }

  private func openSearch(animated: Bool) {
    guard searchController != nil else { return }
    beginSearchInteractive()
    if animated {
      settleSearch(open: true)
    } else {
      updateSearchProgress(1)
      searchOpen = true
      searchController?.focus()
    }
  }

  private func closeSearch(animated: Bool) {
    guard let search = searchController else { return }
    searchOpen = false
    if animated {
      settleSearch(open: false)
    } else {
      updateSearchProgress(0)
      search.view.isHidden = true
      table.transform = .identity
      onToolbar?(toolbarWasHidden)
      startPreviewIfNeeded()
      if !searchOpen {
        search.reset()
      }
    }
  }

  func openSearchFromHost() {
    openSearch(animated: true)
  }

  func isSearchOpen() -> Bool {
    return searchOpen
  }

  func setToolbarHidden(_ hidden: Bool) {
    toolbarHidden = hidden
  }

  func closeSearchFromHost() {
    closeSearch(animated: true)
  }
}
