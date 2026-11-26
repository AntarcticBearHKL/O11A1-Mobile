import UIKit

final class FeedViewController: UIViewController,
  UICollectionViewDataSource,
  UICollectionViewDelegateFlowLayout,
  UIScrollViewDelegate,
  UIGestureRecognizerDelegate {

  var onOpen: ((VideoItem, VideoCardCell) -> Void)?
  var onProfile: ((Int64) -> Void)?
  var onToolbar: ((Bool) -> Void)?
  var onSearchOpen: ((VideoItem) -> Void)?

  private(set) var items: [VideoItem] = []
  private let collectionView: UICollectionView
  private let layout = UICollectionViewFlowLayout()
  private let previewEngine = VideoEngine()
  private lazy var previewView = PlayerLayerView(playerLayer: previewEngine.playerLayer)
  private var previewCell: VideoCardCell?
  private var previewIndex = -1
  private var previewToken = 0
  private var previewLoading = false
  private var focusedIndex = 0
  private var nextPage = 1
  private var fresh = 1
  private var loading = false
  private var hasMore = true
  private var lastOffset: CGFloat = 0
  private var toolbarHidden = false
  private var toolbarWasHidden = false
  private let statusLabel = UILabel()
  private var searchController: SearchViewController?
  private var searchPan: UIPanGestureRecognizer?
  private var searchOpen = false

  init() {
    let flow = UICollectionViewFlowLayout()
    flow.scrollDirection = .vertical
    flow.minimumLineSpacing = 0
    flow.minimumInteritemSpacing = 0
    flow.sectionInset = .zero
    layout.scrollDirection = .vertical
    layout.minimumLineSpacing = 0
    layout.minimumInteritemSpacing = 0
    collectionView = UICollectionView(frame: .zero, collectionViewLayout: flow)
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = NativeTheme.background

    collectionView.backgroundColor = .clear
    collectionView.isPagingEnabled = true
    collectionView.showsVerticalScrollIndicator = false
    collectionView.contentInsetAdjustmentBehavior = .never
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.register(VideoCardCell.self, forCellWithReuseIdentifier: VideoCardCell.reuseID)
    view.addSubview(collectionView)
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      collectionView.topAnchor.constraint(equalTo: view.topAnchor),
      collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
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
    search.view.frame = CGRect(x: view.bounds.width, y: 0, width: view.bounds.width, height: view.bounds.height)
    search.view.autoresizingMask = [.flexibleHeight]
    view.addSubview(search.view)
    search.didMove(toParent: self)
    search.view.isHidden = true
    searchController = search

    let pan = UIPanGestureRecognizer(target: self, action: #selector(handleSearchPan(_:)))
    pan.delegate = self
    view.addGestureRecognizer(pan)
    searchPan = pan

    load(reset: true)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    let size = view.bounds.size
    if layout.itemSize != size {
      layout.itemSize = size
      layout.invalidateLayout()
    }
    if let search = searchController {
      if searchOpen {
        search.view.frame = view.bounds
      } else {
        search.view.frame = CGRect(x: view.bounds.width, y: 0, width: view.bounds.width, height: view.bounds.height)
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
        self.collectionView.reloadData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
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

  // MARK: - collection

  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return items.count
  }

  func collectionView(
    _ collectionView: UICollectionView,
    cellForItemAt indexPath: IndexPath
  ) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: VideoCardCell.reuseID,
      for: indexPath
    ) as! VideoCardCell
    let item = items[indexPath.item]
    cell.configure(item)
    cell.onAvatar = { [weak self] item in
      self?.onProfile?(item.mid)
    }
    cell.onOpen = { [weak self, weak cell] item in
      guard let self = self, let cell = cell else { return }
      self.onOpen?(item, cell)
    }
    if indexPath.item == focusedIndex, previewCell === cell {
      cell.attachPreview(previewView)
    }
    return cell
  }

  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAt indexPath: IndexPath
  ) -> CGSize {
    return collectionView.bounds.size
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    let height = max(1, scrollView.bounds.height)
    let index = max(0, min(items.count - 1, Int(round(scrollView.contentOffset.y / height))))
    if index != focusedIndex {
      focusedIndex = index
      previewEngine.pause()
      previewView.alpha = 0
      previewLoading = false
      previewToken += 1
      if toolbarHidden == false && scrollView.contentOffset.y > 10 {
        // keep the toolbar state stable while the page settles
      }
    }

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

    if scrollView.contentOffset.y > scrollView.contentSize.height - height * 2.2 {
      load(reset: false)
    }
  }

  func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    previewEngine.pause()
    previewView.alpha = 0
    previewLoading = false
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
    let index = max(0, min(items.count - 1, Int(round(collectionView.contentOffset.y / max(1, collectionView.bounds.height)))))
    focusedIndex = index
    if previewIndex == index && previewEngine.player.currentItem != nil {
      if let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? VideoCardCell,
         previewView.superview !== cell.mediaHost {
        cell.attachPreview(previewView)
      }
      previewView.alpha = 1
      previewEngine.play()
      return
    }
    guard let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? VideoCardCell else {
      return
    }
    let item = items[index]
    previewIndex = index
    previewCell = cell
    previewView.alpha = 0
    previewLoading = true
    previewToken += 1
    let token = previewToken
    cell.attachPreview(previewView)
    previewEngine.stop()
    BiliAPI.shared.playLow(item) { [weak self] result in
      guard let self = self, token == self.previewToken else { return }
      self.previewLoading = false
      guard case .success(let source) = result else { return }
      guard let current = self.collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? VideoCardCell else { return }
      current.attachPreview(self.previewView)
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
    let index = min(focusedIndex, items.count - 1)
    guard let cell = collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? VideoCardCell else {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
        self?.openFirstForTest()
      }
      return
    }
    onOpen?(items[index], cell)
  }

  // MARK: - search drag

  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    guard let pan = gestureRecognizer as? UIPanGestureRecognizer, pan === searchPan else {
      return true
    }
    guard !searchOpen else { return false }
    let velocity = pan.velocity(in: view)
    return velocity.x < -120 && abs(velocity.x) > abs(velocity.y)
  }

  @objc private func handleSearchPan(_ gesture: UIPanGestureRecognizer) {
    guard let search = searchController else { return }
    let width = max(1, view.bounds.width)
    let translation = max(0, -gesture.translation(in: view).x)
    switch gesture.state {
    case .began:
      suspendPreview()
      toolbarWasHidden = toolbarHidden
      onToolbar?(true)
      search.view.isHidden = false
      view.bringSubviewToFront(search.view)
    case .changed:
      let x = max(0, width - translation)
      search.view.frame = CGRect(x: x, y: 0, width: width, height: view.bounds.height)
      collectionView.transform = CGAffineTransform(translationX: -translation * 0.18, y: 0)
    case .ended, .cancelled:
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
      self.collectionView.transform = CGAffineTransform(translationX: -width * 0.18, y: 0)
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
      self.collectionView.transform = .identity
    }
    let finish = { [weak self] in
      guard let self = self else { return }
      search.view.isHidden = true
      self.collectionView.transform = .identity
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
}
