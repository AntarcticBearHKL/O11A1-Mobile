import UIKit

final class CommentsPanelViewController: UIViewController, UITableViewDataSource,
  UITableViewDelegate, UIGestureRecognizerDelegate {
  var embedded = false
  var onSwipeLeft: (() -> Void)?
  var onSwipeRight: (() -> Void)?
  var onSwipeRightBegan: (() -> Void)?
  var onSwipeRightChanged: ((CGFloat) -> Void)?
  var onSwipeRightEnded: ((Bool) -> Void)?
  var onPullDown: ((CGFloat) -> Void)?
  var onPullDownEnded: ((Bool) -> Void)?
  var onScroll: ((CGFloat, CGFloat) -> Void)?
  private let aid: Int64
  private let card = UIView()
  private let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
  private let tint = UIView()
  private let table = UITableView(frame: .zero, style: .plain)
  private let status = UILabel()
  private let headerTitle = UILabel()
  private let headerBar = UIView()
  private let headerBlur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
  private let sortDock = UIView()
  private let sortBlur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
  private let latestButton = UIButton(type: .custom)
  private let hotButton = UIButton(type: .custom)
  private var items: [CommentItem] = []
  private var page = 1
  private var sort = 2
  private var loading = false
  private var hasMore = true
  private var dismissPan: UIPanGestureRecognizer?
  private var embeddedSwipePan: UIPanGestureRecognizer?
  private var embeddedSwipeStartX: CGFloat = 0
  private var embeddedSwipeStarted = false
  private var pullDownPan: UIPanGestureRecognizer?
  private var pullDownArmed = false
  private var repliesCache: [Int64: [CommentItem]] = [:]
  private var replyVisibleCount: [Int64: Int] = [:]
  private var replyNextPage: [Int64: Int] = [:]
  private var replyHasMore: [Int64: Bool] = [:]
  private var replyServerMore: [Int64: Bool] = [:]
  private var expandedRoots: Set<Int64> = []
  private var loadingReplies: Set<Int64> = []
  private var suppressCommentSelection = false
  private var lastDockScrollPosition: CGFloat?

  init(aid: Int64) {
    self.aid = aid
    super.init(nibName: nil, bundle: nil)
    modalPresentationStyle = .overFullScreen
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear

    card.layer.cornerRadius = NativeTheme.cornerRadius
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

    blur.clipsToBounds = true
    card.addSubview(blur)
    blur.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      blur.leadingAnchor.constraint(equalTo: card.leadingAnchor),
      blur.trailingAnchor.constraint(equalTo: card.trailingAnchor),
      blur.topAnchor.constraint(equalTo: card.topAnchor),
      blur.bottomAnchor.constraint(equalTo: card.bottomAnchor),
    ])
    tint.isUserInteractionEnabled = false
    card.addSubview(tint)
    tint.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      tint.leadingAnchor.constraint(equalTo: card.leadingAnchor),
      tint.trailingAnchor.constraint(equalTo: card.trailingAnchor),
      tint.topAnchor.constraint(equalTo: card.topAnchor),
      tint.bottomAnchor.constraint(equalTo: card.bottomAnchor),
    ])
    applyGlass()

    table.backgroundColor = .clear
    table.separatorStyle = .none
    table.dataSource = self
    table.delegate = self
    table.register(PanelCommentCell.self, forCellReuseIdentifier: PanelCommentCell.reuseID)
    table.estimatedRowHeight = 120
    table.rowHeight = UITableView.automaticDimension
    table.showsVerticalScrollIndicator = false
    table.contentInsetAdjustmentBehavior = .never
    card.addSubview(table)
    table.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      table.leadingAnchor.constraint(equalTo: card.leadingAnchor),
      table.trailingAnchor.constraint(equalTo: card.trailingAnchor),
      table.topAnchor.constraint(equalTo: card.topAnchor),
      table.bottomAnchor.constraint(equalTo: card.bottomAnchor),
    ])

    if embedded {
      headerBar.backgroundColor = .clear
      card.addSubview(headerBar)
      headerBar.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        headerBar.leadingAnchor.constraint(equalTo: card.leadingAnchor),
        headerBar.trailingAnchor.constraint(equalTo: card.trailingAnchor),
        headerBar.topAnchor.constraint(equalTo: card.topAnchor),
        headerBar.heightAnchor.constraint(equalToConstant: 56),
      ])
      headerBlur.isUserInteractionEnabled = false
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
    }

    status.font = NativeTheme.bodyFont(13)
    status.textColor = NativeTheme.secondary
    status.textAlignment = .center
    status.numberOfLines = 0
    status.isHidden = true
    card.addSubview(status)
    status.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      status.centerXAnchor.constraint(equalTo: card.centerXAnchor),
      status.centerYAnchor.constraint(equalTo: card.centerYAnchor),
      status.leadingAnchor.constraint(greaterThanOrEqualTo: card.leadingAnchor, constant: 32),
      status.trailingAnchor.constraint(lessThanOrEqualTo: card.trailingAnchor, constant: -32),
    ])

    sortDock.layer.cornerRadius = NativeTheme.cornerRadius
    sortDock.layer.cornerCurve = .continuous
    sortDock.layer.borderWidth = 1
    sortDock.layer.shadowColor = UIColor.black.cgColor
    sortDock.layer.shadowOpacity = 0.18
    sortDock.layer.shadowRadius = 17
    sortDock.layer.shadowOffset = CGSize(width: 0, height: 7)
    sortDock.clipsToBounds = false
    card.addSubview(sortDock)
    sortDock.translatesAutoresizingMaskIntoConstraints = false
    let sortHeight: CGFloat = embedded ? 36 : 52
    if embedded {
      NSLayoutConstraint.activate([
        sortDock.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
        sortDock.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
        sortDock.heightAnchor.constraint(equalToConstant: sortHeight),
      ])
      headerTitle.text = "评论"
      headerTitle.font = UIFont.systemFont(ofSize: 16, weight: .bold)
      headerTitle.textColor = NativeTheme.foreground
      card.addSubview(headerTitle)
      headerTitle.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        headerTitle.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
        headerTitle.centerYAnchor.constraint(equalTo: sortDock.centerYAnchor),
      ])
    } else {
      NSLayoutConstraint.activate([
        sortDock.centerXAnchor.constraint(equalTo: card.centerXAnchor),
        sortDock.bottomAnchor.constraint(equalTo: card.safeAreaLayoutGuide.bottomAnchor, constant: -16),
        sortDock.heightAnchor.constraint(equalToConstant: sortHeight),
      ])
    }
    sortBlur.isUserInteractionEnabled = false
    sortBlur.layer.cornerRadius = NativeTheme.cornerRadius
    sortBlur.layer.cornerCurve = .continuous
    sortBlur.clipsToBounds = true
    sortDock.addSubview(sortBlur)
    sortBlur.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      sortBlur.leadingAnchor.constraint(equalTo: sortDock.leadingAnchor),
      sortBlur.trailingAnchor.constraint(equalTo: sortDock.trailingAnchor),
      sortBlur.topAnchor.constraint(equalTo: sortDock.topAnchor),
      sortBlur.bottomAnchor.constraint(equalTo: sortDock.bottomAnchor),
    ])
    let sortButtonWidth: CGFloat = embedded ? 46 : 92
    let sortButtonHeight: CGFloat = embedded ? 30 : 42
    let sortFontSize: CGFloat = embedded ? 13 : 13.5
    let sortInset: CGFloat = embedded ? 6 : 22
    for (index, button) in [latestButton, hotButton].enumerated() {
      button.tag = index
      button.titleLabel?.font = UIFont.systemFont(ofSize: sortFontSize, weight: .bold)
      button.layer.cornerRadius = NativeTheme.cornerRadius
      button.layer.cornerCurve = .continuous
      button.contentEdgeInsets = UIEdgeInsets(top: 0, left: sortInset, bottom: 0, right: sortInset)
      button.widthAnchor.constraint(equalToConstant: sortButtonWidth).isActive = true
      button.heightAnchor.constraint(equalToConstant: sortButtonHeight).isActive = true
      button.addTarget(self, action: #selector(sortTapped(_:)), for: .touchUpInside)
      sortDock.addSubview(button)
      button.translatesAutoresizingMaskIntoConstraints = false
      button.centerYAnchor.constraint(equalTo: sortDock.centerYAnchor).isActive = true
      if index == 0 {
        button.leadingAnchor.constraint(equalTo: sortDock.leadingAnchor, constant: 5).isActive = true
      } else {
        button.leadingAnchor.constraint(equalTo: latestButton.trailingAnchor, constant: 3).isActive = true
        button.trailingAnchor.constraint(equalTo: sortDock.trailingAnchor, constant: -5).isActive = true
      }
    }
    latestButton.setTitle("最新", for: .normal)
    hotButton.setTitle("最热", for: .normal)
    updateSort()
    applyGlass()

    if !embedded {
      let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
      pan.delegate = self
      view.addGestureRecognizer(pan)
      dismissPan = pan
    } else {
      let swipe = UIPanGestureRecognizer(target: self, action: #selector(handleEmbeddedSwipe(_:)))
      swipe.delegate = self
      view.addGestureRecognizer(swipe)
      table.panGestureRecognizer.require(toFail: swipe)
      embeddedSwipePan = swipe

      let pull = UIPanGestureRecognizer(target: self, action: #selector(handlePullDown(_:)))
      pull.delegate = self
      view.addGestureRecognizer(pull)
      table.panGestureRecognizer.require(toFail: pull)
      pullDownPan = pull
    }

    load(reset: true)
  }

  private func updateInsets() {
    if embedded {
      table.contentInset = UIEdgeInsets(top: 58, left: 0,
                                        bottom: 96 + view.safeAreaInsets.bottom, right: 0)
    } else {
      table.contentInset = UIEdgeInsets(top: view.safeAreaInsets.top + 16, left: 0,
                                        bottom: 102 + view.safeAreaInsets.bottom, right: 0)
    }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    updateInsets()
    card.layer.cornerRadius = embedded ? 0 : NativeTheme.cornerRadius
    blur.layer.cornerRadius = embedded ? 0 : NativeTheme.cornerRadius
    tint.layer.cornerRadius = embedded ? 0 : NativeTheme.cornerRadius
  }

  override func viewSafeAreaInsetsDidChange() {
    super.viewSafeAreaInsetsDidChange()
    updateInsets()
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    applyGlass()
    updateSort()
  }

  private func applyGlass() {
    let light = traitCollection.userInterfaceStyle == .light
    blur.isHidden = true
    tint.backgroundColor = light
      ? NativeTheme.surface
      : UIColor(white: 0, alpha: 0.93)
    card.layer.borderWidth = 0.5
    card.layer.borderColor = NativeTheme.hairline.cgColor
    sortBlur.isHidden = true
    if embedded {
      sortDock.backgroundColor = .clear
      sortDock.layer.borderWidth = 0
      sortDock.layer.shadowOpacity = 0
    } else {
      sortDock.layer.borderWidth = 1
      sortDock.layer.borderColor = light
        ? UIColor(white: 0, alpha: 0.08).cgColor
        : UIColor(white: 1, alpha: 0.12).cgColor
      sortDock.layer.shadowOpacity = 0.18
      sortDock.backgroundColor = light
        ? NativeTheme.surface
        : UIColor(white: 0, alpha: 0.82)
    }
  }

  private func updateSort() {
    if embedded {
      for (index, button) in [latestButton, hotButton].enumerated() {
        let on = (index == 0 && sort == 0) || (index == 1 && sort == 2)
        button.backgroundColor = .clear
        button.setTitleColor(on ? NativeTheme.foreground : NativeTheme.secondary,
                             for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13,
                                                    weight: on ? .bold : .medium)
      }
      return
    }
    let light = traitCollection.userInterfaceStyle == .light
    for (index, button) in [latestButton, hotButton].enumerated() {
      let on = (index == 0 && sort == 0) || (index == 1 && sort == 2)
      button.backgroundColor = on
        ? (light ? NativeTheme.foreground : NativeTheme.foreground)
        : .clear
      button.setTitleColor(on ? NativeTheme.background : NativeTheme.secondary, for: .normal)
      button.titleLabel?.font = UIFont.systemFont(ofSize: 13.5, weight: .bold)
    }
  }

  @objc private func sortTapped(_ sender: UIButton) {
    let newSort = sender.tag == 0 ? 0 : 2
    guard newSort != sort else { return }
    sort = newSort
    updateSort()
    load(reset: true)
  }

  private func load(reset: Bool) {
    guard !loading else { return }
    if reset {
      page = 1
      items = []
      hasMore = true
      table.reloadData()
      status.text = "正在加载评论…"
      status.isHidden = false
    } else {
      guard hasMore else { return }
      if !items.isEmpty {
        status.isHidden = true
      }
    }
    loading = true
    let pageValue = page
    BiliAPI.shared.comments(aid: aid, page: pageValue, sort: sort) { [weak self] result in
      guard let self = self else { return }
      self.loading = false
      switch result {
      case .failure(let error):
        if self.items.isEmpty {
          self.status.text = error.localizedDescription
          self.status.isHidden = false
        }
      case .success(let values):
        self.items.append(contentsOf: values)
        self.page += 1
        if values.count < 20 {
          self.hasMore = false
        }
        if self.items.isEmpty {
          self.status.text = "还没有评论"
          self.status.isHidden = false
        } else {
          self.status.text = nil
          self.status.isHidden = true
        }
        self.table.reloadData()
      }
    }
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return items.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: PanelCommentCell.reuseID, for: indexPath) as! PanelCommentCell
    let item = items[indexPath.row]
    let expanded = expandedRoots.contains(item.rpid)
    let all = repliesCache[item.rpid] ?? []
    let count = min(max(0, replyVisibleCount[item.rpid] ?? 0), all.count)
    let visible = Array(all.prefix(count))
    let hasMore = replyHasMore[item.rpid] ?? (item.replies > count)
    cell.configure(
      item,
      replies: visible,
      expanded: expanded,
      loading: loadingReplies.contains(item.rpid),
      hasMoreReplies: expanded && hasMore)
    cell.onLoadMoreReplies = { [weak self] in
      guard let self = self else { return }
      self.suppressCommentSelection = true
      self.loadMoreReplies(item)
      DispatchQueue.main.async {
        self.suppressCommentSelection = false
      }
    }
    return cell
  }

  func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
    guard items.indices.contains(indexPath.row) else { return nil }
    let item = items[indexPath.row]
    let hasReplies = item.replies > 0
      || !(repliesCache[item.rpid]?.isEmpty ?? true)
    return hasReplies ? indexPath : nil
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: false)
    guard !suppressCommentSelection, items.indices.contains(indexPath.row) else {
      return
    }
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    toggleReplies(items[indexPath.row])
  }

  private func toggleReplies(_ item: CommentItem) {
    let root = item.rpid
    guard root > 0 else { return }
    let cached = repliesCache[root]
    guard item.replies > 0 || !(cached?.isEmpty ?? true) else { return }
    if expandedRoots.contains(root) {
      expandedRoots.remove(root)
      reloadComment(root)
      return
    }
    expandedRoots.insert(root)
    let all = cached ?? []
    if replyVisibleCount[root] == nil {
      replyVisibleCount[root] = min(5, all.count)
    }
    if let count = replyVisibleCount[root] {
      replyHasMore[root] = count < all.count || replyServerMore[root] == true
        || (all.isEmpty && item.replies > 0)
    }
    if all.isEmpty, item.replies > 0, (replyNextPage[root] ?? 1) == 1,
       !loadingReplies.contains(root) {
      loadingReplies.insert(root)
      reloadComment(root)
      fetchReplyPage(root: root, page: 1)
      return
    }
    reloadComment(root)
  }

  private func loadMoreReplies(_ item: CommentItem) {
    let root = item.rpid
    guard root > 0, expandedRoots.contains(root),
          !loadingReplies.contains(root) else { return }
    let all = repliesCache[root] ?? []
    let count = replyVisibleCount[root] ?? 0
    if count < all.count {
      let next = min(all.count, count + 5)
      replyVisibleCount[root] = next
      replyHasMore[root] = next < all.count || replyServerMore[root] == true
      UIImpactFeedbackGenerator(style: .light).impactOccurred()
      reloadComment(root)
      return
    }
    guard replyHasMore[root] == true else { return }
    loadingReplies.insert(root)
    replyHasMore[root] = true
    reloadComment(root)
    fetchReplyPage(root: root, page: replyNextPage[root] ?? 1)
  }

  private func fetchReplyPage(root: Int64, page: Int) {
    BiliAPI.shared.commentReplies(aid: aid, root: root, page: page) { [weak self] result in
      guard let self = self else { return }
      self.loadingReplies.remove(root)
      switch result {
      case .failure:
        if self.repliesCache[root] == nil {
          self.repliesCache[root] = []
        }
        self.replyHasMore[root] = self.replyHasMore[root] ?? false
        self.reloadComment(root)
      case .success(let values):
        var existing = self.repliesCache[root] ?? []
        var ids = Set(existing.map { $0.rpid })
        for value in values where !ids.contains(value.rpid) {
          existing.append(value)
          ids.insert(value.rpid)
        }
        self.repliesCache[root] = existing
        self.replyNextPage[root] = page + 1
        self.replyServerMore[root] = values.count >= 20
        let previous = self.replyVisibleCount[root] ?? 0
        self.replyVisibleCount[root] = min(existing.count, previous + 5)
        let shown = self.replyVisibleCount[root] ?? 0
        self.replyHasMore[root] = shown < existing.count
          || self.replyServerMore[root] == true
        self.reloadComment(root)
      }
    }
  }

  private func reloadComment(_ root: Int64) {
    guard let index = items.firstIndex(where: { $0.rpid == root }) else { return }
    UIView.performWithoutAnimation {
      self.table.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
    }
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    guard scrollView.contentSize.height > 0 else { return }
    if scrollView.isDragging {
      let position = scrollView.contentOffset.y + scrollView.contentInset.top
      if let last = lastDockScrollPosition {
        let delta = position - last
        if abs(delta) > 2 {
          onScroll?(delta, position)
        }
      }
      lastDockScrollPosition = position
    } else {
      lastDockScrollPosition = nil
    }
    guard hasMore, !loading else { return }
    if scrollView.contentOffset.y > scrollView.contentSize.height - scrollView.bounds.height * 2 {
      load(reset: false)
    }
  }

  @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
    let width = max(1, view.bounds.width)
    let reference = view.superview ?? view
    let translation = max(0, gesture.translation(in: reference).x)
    switch gesture.state {
    case .changed:
      view.transform = CGAffineTransform(translationX: translation, y: 0)
    case .ended, .cancelled:
      let velocity = gesture.velocity(in: view).x
      if translation > width * 0.24 || velocity > 350 {
        dismiss(animated: false)
      } else {
        UIView.animate(withDuration: 0.22) { self.view.transform = .identity }
      }
    default:
      break
    }
  }

  @objc private func handleEmbeddedSwipe(_ gesture: UIPanGestureRecognizer) {
    let width = max(1, view.bounds.width)
    let translation = gesture.translation(in: view).x
    switch gesture.state {
    case .began:
      embeddedSwipeStarted = false
    case .changed:
      if translation > 4, !embeddedSwipeStarted {
        embeddedSwipeStarted = true
        onSwipeRightBegan?()
      }
      if embeddedSwipeStarted {
        onSwipeRightChanged?(max(0, min(1, translation / width)))
      }
    case .ended, .cancelled:
      let velocity = gesture.velocity(in: view).x
      if embeddedSwipeStarted {
        let shouldClose = translation > width * 0.22 || velocity > 380
        onSwipeRightEnded?(shouldClose)
      }
      embeddedSwipeStarted = false
    default:
      break
    }
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
    if gestureRecognizer === embeddedSwipePan {
      embeddedSwipeStartX = touch.location(in: view).x
    }
    return true
  }

  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
    if pan === pullDownPan {
      guard embedded, pullDownArmed else { return false }
      let velocity = pan.velocity(in: view)
      let translation = pan.translation(in: view)
      return (translation.y > 2 && abs(translation.y) > abs(translation.x) * 1.1)
        || (velocity.y > 60 && abs(velocity.y) > abs(velocity.x) * 1.1)
    }
    if pan === embeddedSwipePan {
      let velocity = pan.velocity(in: view)
      let translation = pan.translation(in: view)
      let movingRight = translation.x > 2 || velocity.x > 80
      let horizontal = abs(translation.x) >= 8
        && abs(translation.x) > abs(translation.y) * 1.8
      let flick = abs(velocity.x) > 160
        && abs(velocity.x) > abs(velocity.y) * 2.0
      return movingRight && (horizontal || flick)
    }
    guard pan === dismissPan else { return true }
    let velocity = pan.velocity(in: view)
    let translation = pan.translation(in: view)
    return abs(translation.x) > abs(translation.y) * 1.1
      || abs(velocity.x) > abs(velocity.y) * 1.1
  }

  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                         shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    if gestureRecognizer === embeddedSwipePan || otherGestureRecognizer === embeddedSwipePan {
      return true
    }
    return false
  }
}

private final class PanelCommentCell: UITableViewCell {
  static let reuseID = "PanelCommentCell"

  private let avatar = UIImageView()
  private let name = UILabel()
  private let likes = UILabel()
  private let repliesCount = UILabel()
  private let time = UILabel()
  private let message = CommentMessageLabel()
  private let repliesStack = UIStackView()
  private let separator = UIView()
  var onLoadMoreReplies: (() -> Void)?

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .default
    let selection = UIView()
    selection.backgroundColor = .clear
    selectedBackgroundView = selection

    avatar.contentMode = .scaleAspectFill
    avatar.clipsToBounds = true
    avatar.layer.cornerRadius = 19
    avatar.layer.cornerCurve = .continuous
    avatar.backgroundColor = NativeTheme.tertiary.withAlphaComponent(0.16)
    avatar.widthAnchor.constraint(equalToConstant: 38).isActive = true
    avatar.heightAnchor.constraint(equalToConstant: 38).isActive = true

    name.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
    name.textColor = NativeTheme.foreground
    name.numberOfLines = 1
    name.lineBreakMode = .byTruncatingTail
    name.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    name.setContentHuggingPriority(.defaultLow, for: .horizontal)

    for metric in [likes, repliesCount] {
      metric.font = UIFont.monospacedDigitSystemFont(ofSize: 10.5, weight: .medium)
      metric.textAlignment = .left
      metric.setContentHuggingPriority(.required, for: .horizontal)
      metric.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
    likes.widthAnchor.constraint(equalToConstant: 46).isActive = true
    repliesCount.widthAnchor.constraint(equalToConstant: 40).isActive = true
    repliesCount.isHidden = true

    time.font = UIFont.monospacedDigitSystemFont(ofSize: 10.5, weight: .medium)
    time.textAlignment = .right
    time.numberOfLines = 1
    time.setContentHuggingPriority(.required, for: .horizontal)
    time.setContentCompressionResistancePriority(.required, for: .horizontal)

    let metaRow = UIStackView(arrangedSubviews: [likes, repliesCount, time])
    metaRow.axis = .horizontal
    metaRow.alignment = .center
    metaRow.spacing = 4
    metaRow.setContentHuggingPriority(.required, for: .horizontal)
    metaRow.setContentCompressionResistancePriority(.required, for: .horizontal)

    let metaSpacer = UIView()
    metaSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
    let titleRow = UIStackView(arrangedSubviews: [avatar, name, metaSpacer, metaRow])
    titleRow.axis = .horizontal
    titleRow.alignment = .center
    titleRow.spacing = 12
    contentView.addSubview(titleRow)
    titleRow.translatesAutoresizingMaskIntoConstraints = false

    message.font = UIFont.systemFont(ofSize: 16.5, weight: .regular)
    message.textColor = NativeTheme.foreground.withAlphaComponent(0.9)
    message.numberOfLines = 0
    message.lineBreakMode = .byWordWrapping

    repliesStack.axis = .vertical
    repliesStack.spacing = 18
    repliesStack.isHidden = true

    let bodyStack = UIStackView(arrangedSubviews: [message, repliesStack])
    bodyStack.axis = .vertical
    bodyStack.alignment = .fill
    bodyStack.spacing = 14
    contentView.addSubview(bodyStack)
    bodyStack.translatesAutoresizingMaskIntoConstraints = false

    separator.backgroundColor = NativeTheme.hairline
    contentView.addSubview(separator)
    separator.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      titleRow.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
      titleRow.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
      titleRow.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),

      bodyStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
      bodyStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
      bodyStack.topAnchor.constraint(equalTo: titleRow.bottomAnchor, constant: 10),
      bodyStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),

      separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
      separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
      separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      separator.heightAnchor.constraint(equalToConstant: 0.5),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    avatar.image = nil
    name.attributedText = nil
    likes.attributedText = nil
    repliesCount.attributedText = nil
    repliesCount.isHidden = true
    time.attributedText = nil
    repliesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
    onLoadMoreReplies = nil
  }

  func configure(_ item: CommentItem, replies items: [CommentItem],
                 expanded: Bool, loading: Bool, hasMoreReplies: Bool) {
    let displayName = item.name.isEmpty ? "用户" : item.name
    name.attributedText = NSAttributedString(
      string: displayName,
      attributes: [
        .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
        .foregroundColor: NativeTheme.foreground,
        .kern: 0.3,
      ])
    let timeText = NativeTheme.freshness(Int64(item.time))
    let timeTint = NativeTheme.freshnessColor(Int64(item.time))
    time.attributedText = timeMetric(timeText, tint: timeTint)
    setMessage(item.message, emotes: item.emotes)

    likes.attributedText = metric(icon: "heart.fill",
                                  tint: NativeTheme.accent,
                                  value: item.likes)
    let count = max(item.replies, items.count)
    repliesCount.isHidden = false
    repliesCount.attributedText = metric(icon: "bubble.left.fill",
                                         tint: NativeTheme.navBlue,
                                         value: count)
    separator.backgroundColor = NativeTheme.hairline
    ImageLoader.shared.load(item.face, into: avatar)

    repliesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
    repliesStack.isHidden = !expanded
    guard expanded else { return }
    if loading && items.isEmpty {
      let loadingLabel = UILabel()
      loadingLabel.text = "正在加载回复…"
      loadingLabel.font = UIFont.systemFont(ofSize: 13, weight: .regular)
      loadingLabel.textColor = NativeTheme.tertiary
      repliesStack.addArrangedSubview(loadingLabel)
      return
    }
    for reply in items {
      repliesStack.addArrangedSubview(makeReplyRow(reply))
    }
    if hasMoreReplies {
      let button = UIButton(type: .system)
      button.setTitle(loading ? "加载中…" : "加载更多回复", for: .normal)
      button.setTitleColor(NativeTheme.navBlue, for: .normal)
      button.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .medium)
      button.backgroundColor = NativeTheme.foreground.withAlphaComponent(0.045)
      button.layer.cornerRadius = NativeTheme.cornerRadius
      button.layer.cornerCurve = .continuous
      button.clipsToBounds = true
      button.isEnabled = !loading
      button.addTarget(self, action: #selector(loadMoreRepliesTapped),
                       for: .touchUpInside)
      button.heightAnchor.constraint(equalToConstant: 38).isActive = true
      repliesStack.addArrangedSubview(button)
    }
  }

  @objc private func loadMoreRepliesTapped() {
    onLoadMoreReplies?()
  }

  private func setMessage(_ text: String, emotes: [String: String]) {
    message.configure(
      text: text,
      emotes: emotes,
      font: UIFont.systemFont(ofSize: 16.5, weight: .regular),
      color: NativeTheme.foreground.withAlphaComponent(0.9),
      lineHeight: 28,
      tracking: 0.15,
      emoteSize: 20,
      paragraphSpacing: 6
    )
  }

  private func timeMetric(_ text: String, tint: UIColor) -> NSAttributedString {
    let result = NSMutableAttributedString(string: "")
    let configuration = UIImage.SymbolConfiguration(pointSize: 9.5, weight: .semibold)
    if let base = UIImage(systemName: "clock", withConfiguration: configuration) {
      let symbol = base.withTintColor(tint, renderingMode: .alwaysOriginal)
      let attachment = NSTextAttachment()
      attachment.image = symbol
      attachment.bounds = CGRect(x: 0, y: -1.2,
                                 width: symbol.size.width,
                                 height: symbol.size.height)
      result.append(NSAttributedString(attachment: attachment))
    }
    result.append(NSAttributedString(
      string: " \(text)",
      attributes: [
        .font: UIFont.monospacedDigitSystemFont(ofSize: 10.5, weight: .medium),
        .foregroundColor: tint,
        .kern: 0.2,
      ]))
    return result
  }

  private func metric(icon: String, tint: UIColor, value: Int) -> NSAttributedString {
    let result = NSMutableAttributedString(string: "")
    let configuration = UIImage.SymbolConfiguration(pointSize: 9.5, weight: .semibold)
    if let base = UIImage(systemName: icon, withConfiguration: configuration) {
      let symbol = base.withTintColor(tint, renderingMode: .alwaysOriginal)
      let attachment = NSTextAttachment()
      attachment.image = symbol
      attachment.bounds = CGRect(x: 0, y: -1.2,
                                 width: symbol.size.width,
                                 height: symbol.size.height)
      result.append(NSAttributedString(attachment: attachment))
    }
    result.append(NSAttributedString(
      string: " \(o11a1Count(Int64(value)))",
      attributes: [
        .font: UIFont.monospacedDigitSystemFont(ofSize: 10.5, weight: .medium),
        .foregroundColor: NativeTheme.tertiary,
        .kern: 0.1,
      ]))
    return result
  }

  private func makeReplyRow(_ item: CommentItem) -> UIView {
    let replyAvatar = UIImageView()
    replyAvatar.contentMode = .scaleAspectFill
    replyAvatar.clipsToBounds = true
    replyAvatar.layer.cornerRadius = 14
    replyAvatar.layer.cornerCurve = .continuous
    replyAvatar.backgroundColor = NativeTheme.tertiary.withAlphaComponent(0.16)
    replyAvatar.widthAnchor.constraint(equalToConstant: 28).isActive = true
    replyAvatar.heightAnchor.constraint(equalToConstant: 28).isActive = true
    ImageLoader.shared.load(item.face, into: replyAvatar)

    let replyName = UILabel()
    replyName.attributedText = NSAttributedString(
      string: item.name.isEmpty ? "用户" : item.name,
      attributes: [
        .font: UIFont.systemFont(ofSize: 12.5, weight: .medium),
        .foregroundColor: NativeTheme.secondary,
        .kern: 0.2,
      ])

    let replyMessage = CommentMessageLabel()
    replyMessage.configure(
      text: item.message,
      emotes: item.emotes,
      font: UIFont.systemFont(ofSize: 15.5, weight: .regular),
      color: NativeTheme.foreground.withAlphaComponent(0.86),
      lineHeight: 25,
      tracking: 0.1,
      emoteSize: 19,
      paragraphSpacing: 5
    )

    let copy = UIStackView(arrangedSubviews: [replyName, replyMessage])
    copy.axis = .vertical
    copy.alignment = .fill
    copy.spacing = 6

    let row = UIStackView(arrangedSubviews: [replyAvatar, copy])
    row.axis = .horizontal
    row.alignment = .top
    row.spacing = 10
    return row
  }
}
