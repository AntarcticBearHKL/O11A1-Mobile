import UIKit

final class VideoListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
  enum Mode {
    case following
    case dynamic
    case favorites
    case history
    case ranking
    case space(mid: Int64)
  }

  var onOpen: ((VideoItem, UIView?) -> Void)?
  private let mode: Mode
  private let table = UITableView(frame: .zero, style: .plain)
  private let status = UILabel()
  private var items: [VideoItem] = []
  private var page = 1
  private var loading = false
  private var headerTitle: String

  init(mode: Mode, title: String) {
    self.mode = mode
    self.headerTitle = title
    super.init(nibName: nil, bundle: nil)
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
    table.register(VideoRowCell.self, forCellReuseIdentifier: VideoRowCell.reuseID)
    view.addSubview(table)
    table.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      table.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      table.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      table.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      table.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    status.font = NativeTheme.bodyFont(14)
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
    load()
  }

  private func load() {
    guard !loading else { return }
    loading = true
    if items.isEmpty {
      status.text = "正在加载…"
      status.isHidden = false
    }
    let done: (Result<[VideoItem], Error>) -> Void = { [weak self] result in
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
        self.status.text = values.isEmpty ? "暂无内容" : nil
        self.status.isHidden = !values.isEmpty
        self.page += 1
        self.table.reloadData()
      }
    }
    switch mode {
    case .following:
      BiliAPI.shared.following(page: page, completion: done)
    case .dynamic:
      BiliAPI.shared.dynamicFeed(page: page, completion: done)
    case .favorites:
      BiliAPI.shared.favorites(page: page, completion: done)
    case .history:
      BiliAPI.shared.history(page: page, completion: done)
    case .ranking:
      BiliAPI.shared.ranking(page: page, completion: done)
    case .space(let mid):
      BiliAPI.shared.space(mid: mid, page: page, completion: done)
    }
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return items.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: VideoRowCell.reuseID, for: indexPath) as! VideoRowCell
    cell.configure(items[indexPath.row])
    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let cell = tableView.cellForRow(at: indexPath)
    let source = (cell as? VideoRowCell)?.cover ?? cell
    onOpen?(items[indexPath.row], source)
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if scrollView.contentOffset.y > scrollView.contentSize.height - scrollView.bounds.height * 2 {
      load()
    }
  }
}

final class VideoRowCell: UITableViewCell {
  static let reuseID = "VideoRowCell"
  let cover = UIImageView()
  private let title = UILabel()
  private let meta = UILabel()
  private let duration = UILabel()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    backgroundColor = .clear
    selectionStyle = .none

    cover.contentMode = .scaleAspectFill
    cover.clipsToBounds = true
    cover.layer.cornerRadius = 10
    cover.backgroundColor = UIColor(white: 0.12, alpha: 1)
    contentView.addSubview(cover)

    title.font = NativeTheme.titleFont(14)
    title.textColor = NativeTheme.foreground
    title.numberOfLines = 2
    contentView.addSubview(title)

    meta.font = NativeTheme.bodyFont(12)
    meta.textColor = NativeTheme.secondary
    contentView.addSubview(meta)

    duration.font = NativeTheme.numberFont(11)
    duration.textColor = .white
    duration.backgroundColor = UIColor.black.withAlphaComponent(0.58)
    duration.layer.cornerRadius = 4
    duration.clipsToBounds = true
    duration.textAlignment = .center
    contentView.addSubview(duration)

    [cover, title, meta, duration].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
    NSLayoutConstraint.activate([
      cover.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      cover.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
      cover.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
      cover.widthAnchor.constraint(equalToConstant: 146),
      cover.heightAnchor.constraint(equalToConstant: 86),

      title.leadingAnchor.constraint(equalTo: cover.trailingAnchor, constant: 12),
      title.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      title.topAnchor.constraint(equalTo: cover.topAnchor, constant: 2),

      meta.leadingAnchor.constraint(equalTo: title.leadingAnchor),
      meta.trailingAnchor.constraint(equalTo: title.trailingAnchor),
      meta.bottomAnchor.constraint(equalTo: cover.bottomAnchor, constant: -2),

      duration.trailingAnchor.constraint(equalTo: cover.trailingAnchor, constant: -4),
      duration.bottomAnchor.constraint(equalTo: cover.bottomAnchor, constant: -4),
      duration.widthAnchor.constraint(greaterThanOrEqualToConstant: 38),
      duration.heightAnchor.constraint(equalToConstant: 17),
    ])
    contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 102).isActive = true
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(_ item: VideoItem) {
    title.text = item.title
    meta.text = "\(item.owner) · \(item.playText) 播放"
    duration.text = item.duration
    ImageLoader.shared.load(item.pic, into: cover)
  }
}
