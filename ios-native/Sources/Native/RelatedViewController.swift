import UIKit

final class RelatedViewController: UIViewController, UITableViewDataSource,
  UITableViewDelegate, UIGestureRecognizerDelegate {
  var onSelect: ((VideoItem) -> Void)?
  var onClose: (() -> Void)?

  private let bvid: String
  private let table = UITableView(frame: .zero, style: .plain)
  private let status = UILabel()
  private var items: [VideoItem] = []
  private var dismissPan: UIPanGestureRecognizer?
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
    view.backgroundColor = NativeTheme.background

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

    let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
    pan.delegate = self
    table.panGestureRecognizer.require(toFail: pan)
    view.addGestureRecognizer(pan)
    dismissPan = pan

    load()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    table.contentInset = UIEdgeInsets(top: view.safeAreaInsets.top, left: 0,
                                      bottom: view.safeAreaInsets.bottom + 18, right: 0)
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

  @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
    let width = max(1, view.bounds.width)
    let translation = max(0, gesture.translation(in: view).x)
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
    guard let pan = gestureRecognizer as? UIPanGestureRecognizer, pan === dismissPan else {
      return true
    }
    let velocity = pan.velocity(in: view)
    return abs(velocity.x) > abs(velocity.y)
  }
}
