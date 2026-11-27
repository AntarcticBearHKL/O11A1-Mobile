import UIKit

final class RelatedViewController: UIViewController, UITableViewDataSource,
  UITableViewDelegate, UIGestureRecognizerDelegate {
  var embedded = false
  var onSelect: ((VideoItem) -> Void)?
  var onClose: (() -> Void)?
  var onSwipeRight: (() -> Void)?
  var onSwipeRightBegan: (() -> Void)?
  var onSwipeRightChanged: ((CGFloat) -> Void)?
  var onSwipeRightEnded: ((Bool) -> Void)?
  var onPullDown: ((CGFloat) -> Void)?
  var onPullDownEnded: ((Bool) -> Void)?
  var onScroll: ((CGFloat, CGFloat) -> Void)?

  private let bvid: String
  private let table = UITableView(frame: .zero, style: .plain)
  private let headerTitle = UILabel()
  private let headerBar = UIView()
  private let headerBlur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
  private let status = UILabel()
  private var items: [VideoItem] = []
  private var dismissPan: UIPanGestureRecognizer?
  private var closeSwipePan: UIPanGestureRecognizer?
  private var closeSwipeStarted = false
  private var pullDownPan: UIPanGestureRecognizer?
  private var pullDownArmed = false
  private var lastDockScrollPosition: CGFloat?
  private var loading = false

  init(bvid: String) {
    self.bvid = bvid
    super.init(nibName: nil, bundle: nil)
    modalPresentationStyle = .overFullScreen
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = embedded ? NativeTheme.surface : NativeTheme.background

    if embedded {
      headerTitle.text = "推荐"
      headerTitle.font = UIFont.systemFont(ofSize: 15, weight: .bold)
      headerTitle.textColor = NativeTheme.foreground
      view.addSubview(headerTitle)
      headerTitle.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        headerTitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
        headerTitle.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
      ])
    }

    table.backgroundColor = .clear
    table.separatorStyle = .none
    table.dataSource = self
    table.delegate = self
    table.register(HomeCardCell.self, forCellReuseIdentifier: HomeCardCell.reuseID)
    table.rowHeight = UITableView.automaticDimension
    table.estimatedRowHeight = 320
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

    if embedded {
      headerBar.backgroundColor = .clear
      view.addSubview(headerBar)
      headerBar.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        headerBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        headerBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        headerBar.topAnchor.constraint(equalTo: view.topAnchor),
        headerBar.heightAnchor.constraint(equalToConstant: 48),
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
      view.bringSubviewToFront(headerTitle)
    }

    status.font = NativeTheme.bodyFont(13)
    status.textColor = NativeTheme.secondary
    status.textAlignment = .center
    status.numberOfLines = 0
    status.text = "正在加载相关视频…"
    view.addSubview(status)
    status.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      status.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      status.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      status.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
      status.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32),
    ])

    if embedded {
      let swipe = UIPanGestureRecognizer(target: self, action: #selector(handleCloseSwipe(_:)))
      swipe.delegate = self
      table.panGestureRecognizer.require(toFail: swipe)
      view.addGestureRecognizer(swipe)
      closeSwipePan = swipe

      let pull = UIPanGestureRecognizer(target: self, action: #selector(handlePullDown(_:)))
      pull.delegate = self
      table.panGestureRecognizer.require(toFail: pull)
      view.addGestureRecognizer(pull)
      pullDownPan = pull
    } else {
      let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
      pan.delegate = self
      table.panGestureRecognizer.require(toFail: pan)
      view.addGestureRecognizer(pan)
      dismissPan = pan
    }

    load()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    let top: CGFloat = embedded ? 48 : view.safeAreaInsets.top
    let bottom: CGFloat = embedded ? 96 : 18
    table.contentInset = UIEdgeInsets(top: top, left: 0,
                                      bottom: view.safeAreaInsets.bottom + bottom, right: 0)
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    let position = scrollView.contentOffset.y + scrollView.contentInset.top
    if let last = lastDockScrollPosition {
      let delta = position - last
      if abs(delta) > 0.5 {
        onScroll?(delta, position)
      }
    }
    lastDockScrollPosition = position
  }

  private func load() {
    guard !loading else { return }
    loading = true
    BiliAPI.shared.related(bvid) { [weak self] result in
      guard let self = self else { return }
      self.loading = false
      switch result {
      case .failure(let error):
        self.status.text = error.localizedDescription
        self.status.isHidden = false
      case .success(let values):
        self.items = values.filter { $0.bvid != self.bvid }
        self.table.reloadData()
        self.status.text = self.items.isEmpty ? "暂无相关视频" : nil
        self.status.isHidden = !self.items.isEmpty
      }
    }
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return items.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: HomeCardCell.reuseID, for: indexPath) as! HomeCardCell
    let item = items[indexPath.row]
    cell.configure(item)
    cell.onOpen = { [weak self] in self?.onSelect?(item) }
    cell.onAvatar = nil
    return cell
  }

  @objc private func handleCloseSwipe(_ gesture: UIPanGestureRecognizer) {
    let width = max(1, view.bounds.width)
    let translation = gesture.translation(in: view).x
    switch gesture.state {
    case .began:
      closeSwipeStarted = false
    case .changed:
      if translation > 4, !closeSwipeStarted {
        closeSwipeStarted = true
        onSwipeRightBegan?()
      }
      if closeSwipeStarted {
        onSwipeRightChanged?(max(0, min(1, translation / width)))
      }
    case .ended, .cancelled:
      let velocity = gesture.velocity(in: view).x
      if closeSwipeStarted {
        onSwipeRightEnded?(translation > width * 0.22 || velocity > 380)
      }
      closeSwipeStarted = false
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
      onPullDownEnded?(progress > 0.35 || gesture.velocity(in: reference).y > 450)
    default:
      break
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
        onClose?()
      } else {
        UIView.animate(withDuration: 0.22) { self.view.transform = .identity }
      }
    default:
      break
    }
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
    if pan === closeSwipePan {
      let velocity = pan.velocity(in: view)
      let translation = pan.translation(in: view)
      return abs(translation.x) > abs(translation.y) * 1.2
        || abs(velocity.x) > abs(velocity.y) * 1.2
    }
    guard pan === dismissPan else { return true }
    let velocity = pan.velocity(in: view)
    let translation = pan.translation(in: view)
    return abs(translation.x) > abs(translation.y) * 1.1
      || abs(velocity.x) > abs(velocity.y) * 1.1
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
}
