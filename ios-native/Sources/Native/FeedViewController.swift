import UIKit

final class FeedViewController: UIViewController,
  UITableViewDataSource,
  UITableViewDelegate,
  UIGestureRecognizerDelegate {

  var onOpen: ((VideoItem, HomeCardCell) -> Void)?
  var onProfile: ((Int64) -> Void)?
  var onToolbar: ((Bool) -> Void)?
  var onSearchOpen: ((VideoItem) -> Void)?
  var onSeason: ((VideoItem) -> Void)?
  var onSidebar: (() -> Void)?
  var initialSource: (source: String, title: String)?

  private(set) var items: [VideoItem] = []
  private let table = UITableView(frame: .zero, style: .plain)
  private let statusLabel = UILabel()
  private let topFade = UIView()
  private var topFadeHeight: NSLayoutConstraint?
  private let previewEngine = VideoEngine()
  private lazy var previewView = PlayerLayerView(playerLayer: previewEngine.playerLayer)
  private var previewCell: HomeCardCell?
  private var previewIndex = -1
  private var previewToken = 0
  private var nextPage = 1
  private var fresh = 1
  private var loading = false
  private var hasMore = true
  private var lastOffset: CGFloat = 0
  private var toolbarHidden = false
  private var toolbarWasHidden = false
  private var searchController: SearchViewController?
  private var searchPan: UIPanGestureRecognizer?
  private var searchOpen = false
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
    topFadeHeight = topFade.heightAnchor.constraint(equalToConstant: 42)
    NSLayoutConstraint.activate([
      topFade.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      topFade.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      topFade.topAnchor.constraint(equalTo: view.topAnchor),
      topFadeHeight!,
    ])
    let gradient = CAGradientLayer()
    gradient.colors = [NativeTheme.background.cgColor,
                       NativeTheme.background.withAlphaComponent(0).cgColor]
    gradient.locations = [0, 1]
    topFade.layer.addSublayer(gradient)
    topFade.layer.name = "feedTopFade"

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
      guard let self = self else { return }
      self.previewView.alpha = 1
      self.previewEngine.play()
    }
    previewEngine.onError = { [weak self] _ in
      self?.previewView.alpha = 0
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

    if let initial = initialSource {
      homeSource = initial.source
      sourceTitle = initial.title
    }
    load(reset: true)
  }

  override func viewSafeAreaInsetsDidChange() {
    super.viewSafeAreaInsetsDidChange()
    updateInsets()
  }

  private func updateInsets() {
    let insets = view.safeAreaInsets
    table.contentInset = UIEdgeInsets(top: insets.top, left: 0,
                                      bottom: 112 + insets.bottom, right: 0)
    table.verticalScrollIndicatorInsets.top = insets.top
    topFadeHeight?.constant = insets.top + 18
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    updateInsets()
    if let gradient = topFade.layer.sublayers?.first as? CAGradientLayer {
      gradient.frame = topFade.bounds
    }
    if let search = searchController {
      if searchOpen {
        search.view.frame = view.bounds
      } else {
        search.view.frame = CGRect(x: view.bounds.width, y: 0,
                                   width: view.bounds.width, height: view.bounds.height)
      }
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
    previewEngine.pause()
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
    previewCell = nil
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
      showEmpty("所有主页模块已关闭\n在「主页模块」中启用")
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
    table.reloadData()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      self.startPreviewIfNeeded()
    }
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
    return items.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: HomeCardCell.reuseID, for: indexPath) as! HomeCardCell
    let item = items[indexPath.row]
    cell.configure(item)
    cell.onOpen = { [weak self, weak cell] in
      self?.open(item, cell: cell)
    }
    cell.onAvatar = { [weak self] in
      self?.onProfile?(item.mid)
    }
    if indexPath.row == previewIndex, previewCell === cell {
      attachPreview(cell)
    }
    return cell
  }

  private func open(_ item: VideoItem, cell: HomeCardCell?) {
    if item.seasonId > 0 || item.kind == "season" {
      onSeason?(item)
      return
    }
    guard let cell = cell else { return }
    onOpen?(item, cell)
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
    if scrollView.contentOffset.y > scrollView.contentSize.height - scrollView.bounds.height * 2.2 {
      load(reset: false)
    }
  }

  func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    previewEngine.pause()
    previewView.alpha = 0
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
    guard !searchOpen, !items.isEmpty else { return }
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
    previewIndex = bestRow
    previewCell = cell
    if previewEngine.player.currentItem != nil, previewView.superview === cell.mediaHost {
      previewView.alpha = 1
      previewEngine.play()
      return
    }
    attachPreview(cell)
    previewView.alpha = 0
    previewToken += 1
    let token = previewToken
    let item = items[bestRow]
    previewEngine.stop()
    BiliAPI.shared.playLow(item) { [weak self] result in
      guard let self = self, token == self.previewToken else { return }
      guard case .success(let source) = result else { return }
      guard let current = self.table.cellForRow(at: IndexPath(row: bestRow, section: 0)) as? HomeCardCell else {
        return
      }
      self.attachPreview(current)
      self.previewEngine.load(
        url: source.url,
        backup: source.backup,
        headers: BiliAPI.shared.mediaHeaders,
        autoplay: true,
        muted: true,
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
    previewEngine.pause()
    previewView.alpha = 0
  }

  func resumePreview() {
    guard !searchOpen else { return }
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
    guard let cell = table.cellForRow(at: IndexPath(row: 0, section: 0)) as? HomeCardCell else {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
        self?.openFirstForTest()
      }
      return
    }
    onOpen?(items[0], cell)
  }

  // MARK: - gestures

  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    guard let pan = gestureRecognizer as? UIPanGestureRecognizer, pan === searchPan else {
      return true
    }
    guard !searchOpen else { return false }
    let velocity = pan.velocity(in: view)
    return velocity.x < 0 && abs(velocity.x) > abs(velocity.y)
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
    search.view.frame = CGRect(x: width * (1 - progress), y: 0,
                               width: width, height: view.bounds.height)
    table.transform = CGAffineTransform(translationX: -width * 0.18 * progress, y: 0)
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
        search.focus()
      } else {
        search.view.isHidden = true
        self.table.transform = .identity
        self.onToolbar?(self.toolbarWasHidden)
        self.startPreviewIfNeeded()
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
    }
  }

  func openSearchFromHost() {
    openSearch(animated: true)
  }

  func isSearchOpen() -> Bool {
    return searchOpen
  }

  func closeSearchFromHost() {
    closeSearch(animated: true)
  }
}
