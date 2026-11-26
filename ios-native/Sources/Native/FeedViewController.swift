import UIKit

final class FeedViewController: UIViewController,
  UITableViewDataSource,
  UITableViewDelegate,
  UIGestureRecognizerDelegate {

  var onOpen: ((VideoItem, HomeCardCell) -> Void)?
  var onProfile: ((Int64) -> Void)?
  var onToolbar: ((Bool) -> Void)?
  var onSearchOpen: ((VideoItem) -> Void)?
  var onSidebar: (() -> Void)?

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
  private var sidebarEdge: UIScreenEdgePanGestureRecognizer?
  private var searchOpen = false
  private var dragDirection = 0

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
    table.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 108, right: 0)
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

    let edge = UIScreenEdgePanGestureRecognizer(
      target: self, action: #selector(handleSidebarEdge(_:)))
    edge.edges = .left
    view.addGestureRecognizer(edge)
    sidebarEdge = edge

    load(reset: true)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    topFadeHeight?.constant = view.safeAreaInsets.top + 18
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

  private func load(reset: Bool) {
    guard !loading else { return }
    if reset {
      nextPage = 1
      fresh = 1
      hasMore = true
    }
    guard hasMore else { return }
    loading = true
    if reset && items.isEmpty {
      statusLabel.text = "正在加载推荐…"
      statusLabel.isHidden = false
    }
    BiliAPI.shared.recommend(page: nextPage, fresh: fresh) { [weak self] result in
      guard let self = self else { return }
      self.loading = false
      switch result {
      case .failure(let error):
        if self.items.isEmpty {
          self.statusLabel.text = error.localizedDescription + "\n轻触屏幕重试"
          self.statusLabel.isHidden = false
          let tap = UITapGestureRecognizer(target: self, action: #selector(self.retry))
          self.view.addGestureRecognizer(tap)
        }
      case .success(let feed):
        if reset {
          self.items = feed.items
        } else {
          let existing = Set(self.items.map { $0.bvid })
          self.items.append(contentsOf: feed.items.filter { !existing.contains($0.bvid) })
        }
        self.hasMore = !feed.items.isEmpty
        self.nextPage += 1
        self.fresh += 1
        self.statusLabel.isHidden = !self.items.isEmpty
        if self.items.isEmpty {
          self.statusLabel.text = "暂时没有推荐\n轻触屏幕重试"
          self.statusLabel.isHidden = false
        }
        self.table.reloadData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
          self.startPreviewIfNeeded()
        }
      }
    }
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
    guard abs(velocity.x) > abs(velocity.y) else { return false }
    dragDirection = velocity.x > 0 ? 1 : -1
    return abs(velocity.x) > 80
  }

  @objc private func handleSidebarEdge(_ gesture: UIScreenEdgePanGestureRecognizer) {
    guard !searchOpen else { return }
    switch gesture.state {
    case .began:
      suspendPreview()
    case .ended, .cancelled:
      if gesture.translation(in: view).x > 48 {
        onSidebar?()
      }
    default:
      break
    }
  }

  @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
    guard let search = searchController else { return }
    let width = max(1, view.bounds.width)
    let translation = max(0, -gesture.translation(in: view).x)
    switch gesture.state {
    case .began:
      suspendPreview()
      if dragDirection > 0 {
        onSidebar?()
        return
      }
      toolbarWasHidden = toolbarHidden
      onToolbar?(true)
      search.view.isHidden = false
      view.bringSubviewToFront(search.view)
    case .changed:
      guard dragDirection < 0 else { return }
      let x = max(0, width - translation)
      search.view.frame = CGRect(x: x, y: 0, width: width, height: view.bounds.height)
      table.transform = CGAffineTransform(translationX: -translation * 0.18, y: 0)
    case .ended, .cancelled:
      guard dragDirection < 0 else { return }
      let velocity = -gesture.velocity(in: view).x
      let progress = translation / width
      if progress > 0.26 || velocity > 350 {
        openSearch(animated: true)
      } else {
        closeSearch(animated: true)
      }
    default:
      break
    }
  }

  private func openSearch(animated: Bool) {
    guard let search = searchController else { return }
    searchOpen = true
    search.view.isHidden = false
    view.bringSubviewToFront(search.view)
    let width = max(1, view.bounds.width)
    let changes = {
      search.view.frame = CGRect(x: 0, y: 0, width: width, height: self.view.bounds.height)
      self.table.transform = CGAffineTransform(translationX: -width * 0.18, y: 0)
    }
    if animated {
      UIView.animate(withDuration: 0.28, delay: 0, options: [.curveEaseOut], animations: changes) { _ in
        search.focus()
      }
    } else {
      changes()
      search.focus()
    }
    previewEngine.pause()
  }

  private func closeSearch(animated: Bool) {
    guard let search = searchController else { return }
    searchOpen = false
    let width = max(1, view.bounds.width)
    let changes = {
      search.view.frame = CGRect(x: width, y: 0, width: width, height: self.view.bounds.height)
      self.table.transform = .identity
    }
    let finish = { [weak self] in
      guard let self = self else { return }
      search.view.isHidden = true
      self.table.transform = .identity
      self.onToolbar?(self.toolbarWasHidden)
      self.startPreviewIfNeeded()
    }
    if animated {
      UIView.animate(withDuration: 0.26, delay: 0, options: [.curveEaseInOut], animations: changes) { _ in
        finish()
      }
    } else {
      changes()
      finish()
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
