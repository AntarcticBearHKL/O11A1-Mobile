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
  var onSearchUser: ((Int64) -> Void)?
  var onSearchSeason: ((Int64, String) -> Void)?
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
  private var previewEngine = VideoEngine(name: "preview")
  private lazy var previewView = PlayerLayerView(playerLayer: previewEngine.playerLayer)
  private var previewCell: HomeCardCell?
  private var previewIndex = -1
  private var previewToken = 0
  private var previewSuspended = false
  private var profilePausedPreview = false
  private var previewScrubbing = false
  private var previewHandedOff = false
  private var previewRetryScheduled = false
  private var previewFocusScheduled = false
  private var previewSource: PlaySource?
  private var previewItemKey = ""
  private var previewPendingKey = ""
  private var nextPage = 1
  private var fresh = 1
  private var loading = false
  private var hasMore = true
  private let maxFeedItems = 100
  private var lastOffset: CGFloat = 0
  private var lastGridPrefetchAt: CFTimeInterval = 0

  private struct FeedAnchor {
    let key: String
    let screenY: CGFloat
  }

  private var pendingAppendAnchor: FeedAnchor?
  private var toolbarHidden = false
  private var toolbarWasHidden = false
  private var searchController: SearchViewController?
  private var searchPan: UIPanGestureRecognizer?
  private var sidebarPan: UIPanGestureRecognizer?
  private var searchOpen = false
  private var searchProgress: CGFloat = 0
  private var searchCloseDirection: CGFloat = 1
  private var searchSettleToken = 0
  private var searchAnimating = false
  private var searchKeyboardShown = false
  private var searchPanStartX: CGFloat = 0
  private var sidebarPanStartX: CGFloat = 0
  private var feedScrollingAtTouch = false
  private var homeSource = "recommend"
  private var sourceTitle = "推荐"
  private var sourceToken = 0

  override func viewDidLoad() {
    super.viewDidLoad()
    applyFeedBackground()

    table.backgroundColor = .clear
    table.separatorStyle = .none
    table.dataSource = self
    table.delegate = self
    table.register(HomeCardCell.self, forCellReuseIdentifier: HomeCardCell.reuseID)
    table.register(HomeGridCell.self, forCellReuseIdentifier: HomeGridCell.reuseID)
    table.rowHeight = feedRowHeight()
    table.estimatedRowHeight = 0
    table.estimatedSectionHeaderHeight = 0
    table.estimatedSectionFooterHeight = 0
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

    configurePreviewEngine()
    previewView.alpha = 0
    previewView.isUserInteractionEnabled = false

    let search = SearchViewController()
    search.onClose = { [weak self] in self?.closeSearch(animated: true) }
    search.onInteractiveClose = { [weak self] progress, direction in
      self?.searchCloseDirection = direction
      self?.updateSearchProgress(progress)
    }
    search.onCloseSettled = { [weak self] shouldClose, direction in
      self?.searchCloseDirection = direction
      self?.settleSearch(open: !shouldClose)
    }
    search.onOpenVideo = { [weak self] item in
      self?.onSearchOpen?(item)
    }
    search.onOpenUser = { [weak self] mid in
      self?.onSearchUser?(mid)
    }
    search.onOpenSeason = { [weak self] seasonId, title in
      self?.onSearchSeason?(seasonId, title)
    }
    addChild(search)
    search.view.frame = view.bounds
    search.view.autoresizingMask = [.flexibleHeight]
    search.view.transform = CGAffineTransform(
      translationX: max(1, view.bounds.width), y: 0)
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
    sidebar.isEnabled = false
    sidebarPan = sidebar

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
    let height = feedRowHeight()
    if abs(table.rowHeight - height) > 0.5 {
      let anchor = captureFeedAnchor()
      table.rowHeight = height
      table.reloadData()
      table.layoutIfNeeded()
      restoreFeedAnchor(anchor, reason: "rowheight")
    }
    if let search = searchController, !searchAnimating {
      let width = max(1, view.bounds.width)
      let progress = max(0, min(1, searchProgress))
      search.view.transform = .identity
      search.view.frame = view.bounds
      search.view.transform = CGAffineTransform(
        translationX: width * (1 - progress) * searchCloseDirection, y: 0)
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
    unloadPreviewMedia()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    unloadPreviewMedia()
    ImageLoader.shared.clearMemory()
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
    unloadPreviewMedia()
    items = []
    previewSuspended = true
    statusLabel.isHidden = true
    table.reloadData()
    table.setContentOffset(CGPoint(x: 0, y: -table.contentInset.top), animated: false)
    load(reset: true)
  }

  private func load(reset: Bool) {
    if reset {
      // A refresh replaces the stream instead of piling another page on top of
      // it. Invalidate any request that is still in flight and release the
      // preview decoder before the old rows disappear.
      sourceToken += 1
      loading = false
      nextPage = 1
      fresh = 1
      hasMore = homeSource != "none" && homeSource != "dynamic" && homeSource != "fish"
      unloadPreviewMedia()
      items = []
      statusLabel.text = "正在加载\(sourceTitle)…"
      statusLabel.isHidden = false
      table.reloadData()
      table.setContentOffset(CGPoint(x: 0, y: -table.contentInset.top), animated: false)
    }
    guard !loading else { return }
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
    guard hasMore else {
      return
    }
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
          BiliAPI.shared.prefetchRecommend(page: self.nextPage, fresh: self.fresh)
        }
      }
    }
  }

  private func finish(_ values: [VideoItem], reset: Bool) {
    if reset {
      unloadPreviewMedia()
      items = values
      previewSuspended = false
      completeFinish(values: values, reset: true, appendStart: 0)
      return
    }
    var existing = Set(items.map { "\($0.bvid)-\($0.roomId)" })
    var incoming: [VideoItem] = []
    for item in values where !existing.contains("\(item.bvid)-\(item.roomId)") {
      incoming.append(item)
      existing.insert("\(item.bvid)-\(item.roomId)")
    }
    let appendStart = items.count
    let anchor = captureFeedAnchor()
    pendingAppendAnchor = anchor
    O11A1Trace.mark(
      "feed",
      "append begin old=\(items.count) add=\(incoming.count) offset=\(String(format: "%.0f", table.contentOffset.y)) size=\(String(format: "%.0f", table.contentSize.height)) grid=\(HomeFeedLayout.isGrid)")
    items.append(contentsOf: incoming)
    completeFinish(values: values, reset: false, appendStart: appendStart)
    restoreFeedAnchor(anchor, reason: "append")
  }

  private func completeFinish(values: [VideoItem], reset: Bool,
                              appendStart: Int) {
    hasMore = !values.isEmpty
    nextPage += 1
    WatchProgressStore.shared.mergeHistory(values)
    statusLabel.isHidden = !items.isEmpty
    if items.isEmpty {
      statusLabel.text = "\(sourceTitle)暂时没有内容\n轻触屏幕重试"
      statusLabel.isHidden = false
    }
    if reset {
      table.reloadData()
    } else if items.count != appendStart {
      appendLoadedRows(from: appendStart)
    }
    let warmStart = reset ? 0 : appendStart
    if !reset {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
        self?.prewarmCovers(from: warmStart, count: 6)
      }
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      self.startPreviewIfNeeded()
      self.loadMoreIfNeeded()
      O11A1Trace.mark(
        "feed",
        "post append offset=\(String(format: "%.0f", self.table.contentOffset.y)) size=\(String(format: "%.0f", self.table.contentSize.height)) dragging=\(self.table.isDragging) decel=\(self.table.isDecelerating)")
      if let anchor = self.pendingAppendAnchor {
        if !self.table.isDragging && !self.table.isDecelerating {
          self.restoreFeedAnchor(anchor, reason: "post")
        } else {
          O11A1Trace.mark("feed", "anchor post skipped while scrolling")
        }
        self.pendingAppendAnchor = nil
      }
    }
    if HomeFeedLayout.isGrid {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
        self?.prefetchGridPlayURLs(force: true)
      }
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
      self?.trimIfNeeded()
    }
  }

  private func prewarmCovers(from start: Int, count: Int) {
    guard !items.isEmpty else { return }
    let first = max(0, min(items.count - 1, start))
    let last = min(items.count, first + count)
    guard first < last else { return }
    for item in items[first..<last] {
      guard !item.pic.isEmpty else { continue }
      ImageLoader.shared.loadImage(item.pic) { _ in }
    }
  }

  /// Appending a page keeps every visible cell alive and only touches the rows
  /// the new items belong to, so the grid grows without a table-wide reload.
  /// The content offset is restored afterwards: even an implicit layout pass
  /// must not move the card the user is looking at.
  private func captureFeedAnchor() -> FeedAnchor? {
    guard let visible = table.indexPathsForVisibleRows?
      .sorted(by: { $0.row < $1.row }) else { return nil }
    guard let first = visible.first(where: {
      table.rectForRow(at: $0).maxY > table.contentOffset.y + 2
    }) else { return nil }
    let index = HomeFeedLayout.isGrid ? first.row * 2 : first.row
    guard index >= 0, index < items.count else { return nil }
    let item = items[index]
    let rect = table.rectForRow(at: first)
    return FeedAnchor(
      key: "\(item.bvid)-\(item.roomId)",
      screenY: rect.minY - table.contentOffset.y)
  }

  private func restoreFeedAnchor(_ anchor: FeedAnchor?, reason: String) {
    guard let anchor,
          let index = items.firstIndex(where: {
            "\($0.bvid)-\($0.roomId)" == anchor.key
          }) else { return }
    let row = HomeFeedLayout.isGrid ? index / 2 : index
    guard row >= 0, row < table.numberOfRows(inSection: 0) else { return }
    table.layoutIfNeeded()
    let rect = table.rectForRow(at: IndexPath(row: row, section: 0))
    let target = max(-table.contentInset.top, rect.minY - anchor.screenY)
    let before = table.contentOffset.y
    guard abs(target - before) > 0.5 else { return }
    table.setContentOffset(CGPoint(x: 0, y: target), animated: false)
    O11A1Trace.mark(
      "feed",
      "anchor \(reason) key=\(anchor.key) \(String(format: "%.0f", before))->\(String(format: "%.0f", target)) sy=\(String(format: "%.0f", anchor.screenY))")
  }

  /// Release rows that are far above the viewport once scrolling has settled.
  /// Twenty items above the anchor are kept so a small upward flick still has
  /// content; the anchor item is restored to the same screen y after reload.
  private func trimIfNeeded() {
    guard items.count > maxFeedItems, !loading,
          !table.isDragging, !table.isDecelerating,
          table.window != nil else { return }
    guard let anchor = captureFeedAnchor(),
          let anchorIndex = items.firstIndex(where: {
            "\($0.bvid)-\($0.roomId)" == anchor.key
          }) else { return }
    let keepAbove = max(0, anchorIndex - 20)
    let overflow = items.count - maxFeedItems
    var remove = min(overflow, keepAbove)
    if HomeFeedLayout.isGrid { remove -= remove % 2 }
    guard remove >= 10 else { return }
    let oldOffset = table.contentOffset.y
    unloadPreviewMedia()
    O11A1Trace.mark(
      "feed",
      "trim begin remove=\(remove) items=\(items.count) anchor=\(anchor.key) offset=\(String(format: "%.0f", oldOffset))")
    UIView.performWithoutAnimation {
      items.removeFirst(remove)
      table.reloadData()
      table.layoutIfNeeded()
      restoreFeedAnchor(anchor, reason: "trim")
    }
    O11A1Trace.mark(
      "feed",
      "trim end items=\(items.count) offset=\(String(format: "%.0f", table.contentOffset.y)) size=\(String(format: "%.0f", table.contentSize.height))")
    lastOffset = table.contentOffset.y
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
      self?.startPreviewIfNeeded()
    }
  }

  private func appendLoadedRows(from oldCount: Int) {    let newCount = items.count
    guard newCount > oldCount else { return }
    let offsetBefore = table.contentOffset
    O11A1Trace.mark(
      "feed",
      "rows insert old=\(oldCount) new=\(newCount) rows=\(table.numberOfRows(inSection: 0)) offset=\(String(format: "%.0f", offsetBefore.y)) size=\(String(format: "%.0f", table.contentSize.height)) grid=\(HomeFeedLayout.isGrid)")
    let restoreOffset = {
      guard self.table.contentOffset != offsetBefore else { return }
      O11A1Trace.mark(
        "feed",
        "rows insert shifted \(String(format: "%.0f", offsetBefore.y))->\(String(format: "%.0f", self.table.contentOffset.y))")
      self.table.setContentOffset(offsetBefore, animated: false)
    }
    if HomeFeedLayout.isGrid {
      let oldRows = (oldCount + 1) / 2
      let newRows = (newCount + 1) / 2
      guard oldRows > 0 else {
        table.reloadData()
        return
      }
      if oldCount % 2 == 1, oldRows > 0,
         let cell = table.cellForRow(
           at: IndexPath(row: oldRows - 1, section: 0)) as? HomeGridCell {
        let leftIndex = (oldRows - 1) * 2
        let rightIndex = leftIndex + 1
        if rightIndex < items.count {
          cell.updateRight(items[rightIndex])
        }
      }
      var insertPaths: [IndexPath] = []
      if newRows > oldRows {
        for row in oldRows..<newRows {
          insertPaths.append(IndexPath(row: row, section: 0))
        }
      }
      guard !insertPaths.isEmpty else {
        table.layoutIfNeeded()
        restoreOffset()
        return
      }
      UIView.performWithoutAnimation {
        table.performBatchUpdates({
          self.table.insertRows(at: insertPaths, with: .none)
        }, completion: { _ in
          self.table.layoutIfNeeded()
          O11A1Trace.mark(
            "feed",
            "rows inserted offset=\(String(format: "%.0f", self.table.contentOffset.y)) size=\(String(format: "%.0f", self.table.contentSize.height))")
          restoreOffset()
          self.restoreFeedAnchor(self.pendingAppendAnchor, reason: "rows")
        })
      }
    } else {
      var insertPaths: [IndexPath] = []
      for row in oldCount..<newCount {
        insertPaths.append(IndexPath(row: row, section: 0))
      }
      guard !insertPaths.isEmpty else { return }
      UIView.performWithoutAnimation {
        table.performBatchUpdates({
          self.table.insertRows(at: insertPaths, with: .none)
        }, completion: { _ in
          self.table.layoutIfNeeded()
          O11A1Trace.mark(
            "feed",
            "rows inserted offset=\(String(format: "%.0f", self.table.contentOffset.y)) size=\(String(format: "%.0f", self.table.contentSize.height))")
          restoreOffset()
          self.restoreFeedAnchor(self.pendingAppendAnchor, reason: "rows")
        })
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

  private func feedRowHeight() -> CGFloat {
    let width: CGFloat
    if table.bounds.width > 1 {
      width = table.bounds.width
    } else if view.bounds.width > 1 {
      width = view.bounds.width
    } else {
      width = UIScreen.main.bounds.width
    }
    if HomeFeedLayout.isGrid {
      let available = width - HomeGridCell.sideInset * 2
        - HomeGridCell.columnSpacing
      let cardWidth = max(1, available / 2)
      return HomeGridCell.verticalInset * 2
        + cardWidth * 3.0 / 4.0
        + HomeGridCell.infoHeight
    }
    return max(1, width) * 9.0 / 16.0 + 98 + 14
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
      cell.onTouchDown = { [weak self] item in
        self?.prefetchPlayURL(item)
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
    cell.onTouchDown = { [weak self] in
      self?.prefetchPlayURL(item)
    }
    cell.onAvatar = { [weak self] in
      self?.suspendPreviewForProfile()
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

  func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell,
                 forRowAt indexPath: IndexPath) {
    guard let card = cell as? HomeCardCell else { return }
    if card === previewCell || previewView.superview === card.mediaHost { return }
    // The decoded cover lives in ImageLoader's cache anyway, so clearing the
    // image here only produced grey rows when scrolling back. Keep it.
    card.hidePreviewLoading()
  }

  private func open(_ item: VideoItem, source: UIView) {
    if item.seasonId > 0 || item.kind == "season" {
      onSeason?(item)
      return
    }
    if let cell = source as? HomeCardCell, previewCell === cell,
       let handoff = previewHandoffFor(item),
       let openPreview = onOpenPreview {
      previewHandedOff = true
      openPreview(item, source, handoff)
      return
    }
    onOpen?(item, source)
  }

  private func previewHandoffFor(_ item: VideoItem) -> PreviewHandoff? {
    guard let source = previewSource, !source.url.isEmpty,
          previewEngine.player.currentItem != nil,
          previewItemKey == "\(item.bvid)-\(item.cid)" else { return nil }
    previewEngine.onTime = nil
    previewEngine.onPlaying = nil
    previewEngine.onReady = nil
    previewEngine.onError = nil
    previewEngine.onLoadStatus = nil
    previewEngine.onPipClose = nil
    previewEngine.onPipRestore = nil
    return PreviewHandoff(
      url: source.url,
      backup: source.backup,
      backups: source.backups,
      seconds: previewEngine.currentTime,
      duration: previewEngine.duration,
      quality: source.quality,
      qualityLabel: source.qualityLabel,
      engine: previewEngine
    )
  }

  @objc private func feedLayoutChanged() {
    let anchor = captureFeedAnchor()
    O11A1Trace.mark(
      "feed",
      "layout change begin grid=\(HomeFeedLayout.isGrid) offset=\(String(format: "%.0f", table.contentOffset.y)) items=\(items.count)")
    applyFeedBackground()
    unloadPreviewMedia()
    table.rowHeight = feedRowHeight()
    table.reloadData()
    table.layoutIfNeeded()
    restoreFeedAnchor(anchor, reason: "layout")
    O11A1Trace.mark(
      "feed",
      "layout change end offset=\(String(format: "%.0f", table.contentOffset.y)) size=\(String(format: "%.0f", table.contentSize.height)) rows=\(table.numberOfRows(inSection: 0))")
    startPreviewIfNeeded()
    loadMoreIfNeeded()
    prefetchGridPlayURLs(force: true)
  }

  private func applyFeedBackground() {
    view.backgroundColor = HomeFeedLayout.isGrid
      ? NativeTheme.feedBackground
      : NativeTheme.background
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
    if !HomeFeedLayout.isGrid, !searchOpen {
      schedulePreviewFocus()
    }
    lastOffset = scrollView.contentOffset.y
    loadMoreIfNeeded()
    if abs(delta) > 120, !scrollView.isTracking,
       !scrollView.isDragging, !scrollView.isDecelerating {
      O11A1Trace.mark(
        "feed",
        "unexpected scroll \(String(format: "%.0f", scrollView.contentOffset.y - delta))->\(String(format: "%.0f", scrollView.contentOffset.y)) dragging=false items=\(items.count)")
    }
  }

  func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if !decelerate {
      startPreviewIfNeeded()
      prefetchGridPlayURLs()
      trimIfNeeded()
    }
  }

  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    startPreviewIfNeeded()
    prefetchGridPlayURLs()
    trimIfNeeded()
    if scrollView.contentOffset.y <= 4 && toolbarHidden {
      toolbarHidden = false
      onToolbar?(false)
    }
  }

  // MARK: - preview

  private func configurePreviewEngine() {
    previewEngine.playerLayer.videoGravity = .resizeAspectFill
    previewEngine.onReady = { [weak self] in
      guard let self = self, !self.previewSuspended else { return }
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
    previewEngine.onLoadStatus = { [weak self] status in
      guard let self = self, !self.previewSuspended else { return }
      self.previewCell?.applyPreviewLoading(status)
    }
    previewEngine.onTime = { [weak self] seconds, duration in
      guard let self = self, !self.previewSuspended, !self.previewScrubbing,
            duration > 0,
            let cell = self.previewCell else { return }
      cell.setPreviewProgress(CGFloat(max(0, min(1, seconds / duration))),
                              current: seconds, total: duration)
    }
  }

  private func resetPreviewEngine() {
    previewEngine = VideoEngine(name: "preview")
    previewView = PlayerLayerView(playerLayer: previewEngine.playerLayer)
    previewView.alpha = 0
    previewView.isUserInteractionEnabled = false
    configurePreviewEngine()
  }

  private func schedulePreviewRetry(after delay: TimeInterval) {
    guard !previewRetryScheduled else { return }
    previewRetryScheduled = true
    DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
      guard let self = self else { return }
      self.previewRetryScheduled = false
      guard !self.previewSuspended, !self.searchOpen else { return }
      self.startPreviewIfNeeded()
    }
  }

  /// While a single-column feed is being dragged the centred card should
  /// already play. Debounce a little so a fast fling does not request a new
  /// stream for every row that passes the centre.
  private func schedulePreviewFocus() {
    guard !previewFocusScheduled, !previewSuspended else { return }
    previewFocusScheduled = true
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) { [weak self] in
      guard let self = self else { return }
      self.previewFocusScheduled = false
      guard !self.previewSuspended, !self.searchOpen else { return }
      self.startPreviewIfNeeded()
    }
  }

  private func startPreviewIfNeeded() {
    guard !previewSuspended, !searchOpen, !items.isEmpty else { return }
    if HomeFeedLayout.isGrid {
      unloadPreviewMedia()
      return
    }
    let center = table.contentOffset.y + table.bounds.height / 2
    table.layoutIfNeeded()
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
      schedulePreviewRetry(after: 0.25)
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
    prewarmPreviewURLs(from: bestRow + 1, count: 1)
    if previewEngine.player.currentItem != nil, previewView.superview === cell.mediaHost {
      cell.hidePreviewLoading()
      previewView.alpha = 1
      previewEngine.play()
      return
    }
    let item = items[bestRow]
    let key = "\(item.bvid)-\(item.cid)"
    if previewItemKey == key, previewEngine.player.currentItem != nil {
      attachPreview(cell)
      cell.hidePreviewLoading()
      previewView.alpha = 1
      previewEngine.play()
      return
    }
    // A request for this very item is already in flight; another scroll
    // callback must not cancel it and start over.
    guard previewPendingKey != key else { return }
    attachPreview(cell)
    cell.setPreviewProgress(0)
    cell.showPreviewLoading()
    previewView.alpha = 0
    previewToken += 1
    let token = previewToken
    previewSource = nil
    previewItemKey = ""
    previewPendingKey = key
    previewEngine.stop()
    BiliAPI.shared.playQuality(item, qn: ThemeManager.shared.quality) {
      [weak self] result in
      guard let self = self, token == self.previewToken,
            !self.previewSuspended else { return }
      self.previewPendingKey = ""
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
      let localResume = WatchProgressStore.shared.position(for: item.bvid)
      let resume = localResume > 0 ? localResume : Double(max(0, item.progress))
      self.previewEngine.load(
        url: source.url,
        backup: source.backup,
        backups: source.backups,
        headers: BiliAPI.shared.mediaHeaders,
        autoplay: true,
        muted: false,
        loop: true,
        startAt: resume
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

  /// Drop the visible preview's player item when the feed starts moving or
  /// leaves the screen. Only the live row keeps a decoder; the covered row
  /// stays on its cover image, and the next settle picks up the new centre.
  private func unloadPreviewMedia() {
    guard previewEngine.player.currentItem != nil || previewView.superview != nil else {
      return
    }
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
    previewPendingKey = ""
    previewScrubbing = false
  }

  private func prewarmPreviewURLs(from start: Int, count: Int = 3) {
    guard !HomeFeedLayout.isGrid, !items.isEmpty else { return }
    let first = max(0, min(items.count - 1, start))
    let last = min(items.count, first + count)
    guard first < last else { return }
    let qn = ThemeManager.shared.quality
    for item in items[first..<last] {
      BiliAPI.shared.prefetchPlayQuality(item, qn: qn)
    }
  }

  /// Two-column cards have no autoplay preview, so every tap used to start a
  /// cold playurl round-trip. Warm the URLs for the cards on screen: a tap
  /// then gets the signed media URL from cache and goes straight to AVPlayer.
  private func prefetchGridPlayURLs(force: Bool = false) {
    guard HomeFeedLayout.isGrid, !items.isEmpty else { return }
    let now = ProcessInfo.processInfo.systemUptime
    if !force, now - lastGridPrefetchAt < 0.6 { return }
    lastGridPrefetchAt = now
    var indices = Set<Int>()
    let rows = (table.indexPathsForVisibleRows ?? []).sorted { $0.row < $1.row }
    if rows.isEmpty {
      indices.formUnion(0..<min(8, items.count))
    } else {
      for indexPath in rows {
        let left = indexPath.row * 2
        indices.insert(left)
        if left + 1 < items.count { indices.insert(left + 1) }
      }
      if let last = rows.last {
        for row in (last.row + 1)...(last.row + 2) {
          let left = row * 2
          indices.insert(left)
          if left + 1 < items.count { indices.insert(left + 1) }
        }
      }
    }
    let qn = ThemeManager.shared.quality
    for index in indices.sorted().prefix(4) where index < items.count {
      let item = items[index]
      guard item.roomId == 0, !item.bvid.isEmpty else { continue }
      BiliAPI.shared.prefetchPlayQuality(item, qn: qn)
    }
  }

  private func prefetchPlayURL(_ item: VideoItem) {
    guard item.roomId == 0, !item.bvid.isEmpty else { return }
    BiliAPI.shared.prefetchPlayQuality(item, qn: ThemeManager.shared.quality)
  }

  func suspendPreviewForProfile() {
    profilePausedPreview = true
    suspendPreview()
  }

  func resumePreviewAfterProfile() {
    guard profilePausedPreview else { return }
    profilePausedPreview = false
    resumePreview()
  }

  func suspendPreview() {
    previewSuspended = true
    previewScrubbing = false
    previewToken += 1
    if previewHandedOff {
      previewHandedOff = false
      previewView.removeFromSuperview()
      previewView.alpha = 0
      previewCell?.hidePreviewLoading()
      previewCell?.setPreviewProgress(nil)
      previewCell = nil
      previewIndex = -1
      previewSource = nil
      previewItemKey = ""
      previewPendingKey = ""
      resetPreviewEngine()
      return
    }
    previewEngine.stop()
    previewView.removeFromSuperview()
    previewView.alpha = 0
    previewCell?.hidePreviewLoading()
    previewCell?.setPreviewProgress(nil)
    previewCell = nil
    previewIndex = -1
    previewSource = nil
    previewItemKey = ""
    previewPendingKey = ""
  }

  func resumePreview() {
    guard !searchOpen else { return }
    profilePausedPreview = false
    previewSuspended = false
    startPreviewIfNeeded()
  }

  func runScrollTest(steps: Int) {
    guard steps > 0 else { return }
    guard !items.isEmpty else {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
        self?.runScrollTest(steps: steps)
      }
      return
    }
    let bottom = max(-table.contentInset.top,
                     table.contentSize.height - table.bounds.height
                       + table.contentInset.bottom)
    let from = table.contentOffset.y
    var next = from + table.bounds.height * 0.82
    if next >= bottom - 1 {
      O11A1Trace.mark(
        "feed",
        "scrolltest bottom step=\(steps) offset=\(String(format: "%.0f", from)) items=\(items.count)")
      loadMoreIfNeeded()
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
        self?.runScrollTest(steps: steps - 1)
      }
      return
    }
    next = min(next, bottom)
    O11A1Trace.mark(
      "feed",
      "scrolltest step=\(steps) \(String(format: "%.0f", from))->\(String(format: "%.0f", next)) items=\(items.count) grid=\(HomeFeedLayout.isGrid)")
    table.setContentOffset(CGPoint(x: 0, y: next), animated: true)
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) { [weak self] in
      self?.runScrollTest(steps: steps - 1)
    }
  }

  func openFirstForTest() {
    let requested = Int(ProcessInfo.processInfo.environment["O11A1_TEST_INDEX"] ?? "") ?? 0
    guard items.count > requested else {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
        self?.openFirstForTest()
      }
      return
    }
    let row = HomeFeedLayout.isGrid ? requested / 2 : requested
    table.scrollToRow(at: IndexPath(row: row, section: 0), at: .top, animated: false)
    table.layoutIfNeeded()
    let cell = table.cellForRow(at: IndexPath(row: row, section: 0))
    if let home = cell as? HomeCardCell {
      open(items[requested], source: home)
    } else if let grid = cell as? HomeGridCell {
      open(items[requested], source: grid.sourceView(for: requested % 2))
    } else {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
        self?.openFirstForTest()
      }
    }
  }

  // MARK: - gestures

  func cachedItem(bvid: String) -> VideoItem? {
    guard !bvid.isEmpty else { return nil }
    return items.first { $0.bvid == bvid }
  }

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
      UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
    search.view.transform = CGAffineTransform(
      translationX: width * (1 - progress) * searchCloseDirection, y: 0)
  }

  private func beginSearchInteractive() {
    guard let search = searchController else { return }
    searchSettleToken += 1
    searchAnimating = false
    searchOpen = true
    searchCloseDirection = 1
    search.view.isHidden = false
    search.view.transform = .identity
    search.view.frame = view.bounds
    view.bringSubviewToFront(search.view)
    previewEngine.pause()
    updateSearchProgress(0)
    toolbarWasHidden = toolbarHidden
    onToolbar?(true)
  }

  private func settleSearch(open: Bool) {
    guard let search = searchController else { return }
    searchSettleToken += 1
    let token = searchSettleToken
    searchOpen = open
    searchAnimating = true
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
      guard let self = self, token == self.searchSettleToken else { return }
      self.searchAnimating = false
      if open {
        search.focusNow()
        self.searchKeyboardShown = true
      } else {
        search.view.isHidden = true
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

  func openSearchResultsForTest(term: String) {
    openSearch(animated: false)
    searchController?.testSearch(term)
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
