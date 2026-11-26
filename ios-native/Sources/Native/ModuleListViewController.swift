import UIKit

final class ModuleListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
  enum Mode {
    case hot, rank, bangumi, movie, live, zone, favorites, history, following, dynamic, messages, season, space
  }

  var onSelect: ((VideoItem) -> Void)?
  var onLogin: (() -> Void)?
  var onClose: (() -> Void)?

  private let mode: Mode
  private let targetId: Int64
  private var titleText: String
  private let titleLabel = UILabel()
  private let backButton = UIButton(type: .system)
  private let filterStack = UIStackView()
  private let table = UITableView(frame: .zero, style: .plain)
  private let status = UILabel()
  private let loginButton = UIButton(type: .system)
  private var items: [VideoItem] = []
  private var page = 1
  private var cursor = ""
  private var loading = false
  private var hasMore = true
  private var filterIndex = 0
  private let filterLabels: [String]
  private let filterValues: [Int]

  init(mode: Mode, targetId: Int64 = 0, title: String) {
    self.mode = mode
    self.targetId = targetId
    self.titleText = title
    switch mode {
    case .bangumi:
      filterLabels = ["番剧", "国创", "电影"]
      filterValues = [1, 4, 2]
    case .movie:
      filterLabels = ["电影", "纪录片", "电视剧"]
      filterValues = [2, 3, 5]
    case .zone:
      filterLabels = ["动画", "音乐", "游戏", "科技"]
      filterValues = [1, 3, 4, 36]
    case .messages:
      filterLabels = ["回复", "@我", "点赞"]
      filterValues = [0, 1, 2]
    default:
      filterLabels = []
      filterValues = []
    }
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = NativeTheme.background

    backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
    backButton.tintColor = NativeTheme.foreground
    backButton.addTarget(self, action: #selector(close), for: .touchUpInside)
    view.addSubview(backButton)

    titleLabel.text = titleText
    titleLabel.font = NativeTheme.titleFont(20)
    titleLabel.textColor = NativeTheme.foreground
    titleLabel.numberOfLines = 1
    view.addSubview(titleLabel)

    filterStack.axis = .horizontal
    filterStack.spacing = 8
    filterStack.alignment = .center
    view.addSubview(filterStack)
    buildFilters()

    table.backgroundColor = .clear
    table.separatorStyle = .none
    table.dataSource = self
    table.delegate = self
    table.register(ModuleMediaCell.self, forCellReuseIdentifier: ModuleMediaCell.reuseID)
    table.register(ModuleMessageCell.self, forCellReuseIdentifier: ModuleMessageCell.reuseID)
    view.addSubview(table)

    status.font = NativeTheme.bodyFont(13)
    status.textColor = NativeTheme.secondary
    status.textAlignment = .center
    status.numberOfLines = 0
    status.isHidden = true
    view.addSubview(status)

    loginButton.setTitle("扫码登录", for: .normal)
    loginButton.setTitleColor(NativeTheme.accent, for: .normal)
    loginButton.titleLabel?.font = NativeTheme.titleFont(14)
    loginButton.isHidden = true
    loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
    view.addSubview(loginButton)

    [backButton, titleLabel, filterStack, table, status, loginButton].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
    }
    NSLayoutConstraint.activate([
      backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
      backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 4),
      backButton.widthAnchor.constraint(equalToConstant: 44),
      backButton.heightAnchor.constraint(equalToConstant: 44),

      titleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 4),
      titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),

      filterStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      filterStack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16),
      filterStack.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 4),
      filterStack.heightAnchor.constraint(equalToConstant: 30),

      table.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      table.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      table.topAnchor.constraint(equalTo: filterStack.bottomAnchor, constant: 4),
      table.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      status.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      status.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      status.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
      status.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32),

      loginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      loginButton.topAnchor.constraint(equalTo: status.bottomAnchor, constant: 10),
    ])
    load(reset: true)
  }

  private func buildFilters() {
    filterStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
    for (index, label) in filterLabels.enumerated() {
      let button = UIButton(type: .system)
      button.setTitle(label, for: .normal)
      button.titleLabel?.font = NativeTheme.bodyFont(12)
      button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
      button.layer.cornerRadius = NativeTheme.cornerRadius
      button.layer.cornerCurve = .continuous
      button.tag = index
      button.addTarget(self, action: #selector(filterTapped(_:)), for: .touchUpInside)
      filterStack.addArrangedSubview(button)
    }
    updateFilters()
  }

  private func updateFilters() {
    for (index, view) in filterStack.arrangedSubviews.enumerated() {
      guard let button = view as? UIButton else { continue }
      let active = index == filterIndex
      button.backgroundColor = active ? NativeTheme.accent : NativeTheme.foreground.withAlphaComponent(0.06)
      button.setTitleColor(active ? .white : NativeTheme.secondary, for: .normal)
    }
  }

  @objc private func filterTapped(_ sender: UIButton) {
    guard sender.tag != filterIndex else { return }
    filterIndex = sender.tag
    updateFilters()
    items = []
    page = 1
    cursor = ""
    hasMore = true
    table.reloadData()
    load(reset: true)
  }

  @objc private func close() {
    onClose?()
  }

  @objc private func loginTapped() {
    onLogin?()
  }

  func reload() {
    items = []
    page = 1
    cursor = ""
    hasMore = true
    table.reloadData()
    load(reset: true)
  }

  private func load(reset: Bool) {
    guard !loading, hasMore || reset else { return }
    loading = true
    if items.isEmpty {
      status.text = "正在加载…"
      status.isHidden = false
    }
    loginButton.isHidden = true
    let pageValue = page
    let cursorValue = cursor
    let filterValue = filterValues.isEmpty ? 0 : filterValues[filterIndex]
    let messageFilter = mode == .messages
      ? (filterIndex == 1 ? "at" : (filterIndex == 2 ? "like" : "reply")) : "all"
    let done: (Result<[VideoItem], Error>) -> Void = { [weak self] result in
      guard let self = self else { return }
      self.loading = false
      switch result {
      case .failure(let error):
        if self.items.isEmpty {
          self.status.text = error.localizedDescription
          self.status.isHidden = false
          self.loginButton.isHidden = !(error.localizedDescription.contains("登录") || error.localizedDescription.contains("login"))
        }
      case .success(let values):
        self.items.append(contentsOf: values)
        self.status.text = values.isEmpty ? "暂无内容" : nil
        self.status.isHidden = !values.isEmpty
        self.page += 1
        self.hasMore = !values.isEmpty
        self.table.reloadData()
      }
    }
    switch mode {
    case .hot:
      BiliAPI.shared.popularItems(page: pageValue, completion: done)
    case .rank:
      BiliAPI.shared.ranking(page: pageValue, completion: done)
    case .bangumi:
      BiliAPI.shared.bangumi(page: pageValue, seasonType: filterValue, completion: done)
    case .movie:
      BiliAPI.shared.bangumi(page: pageValue, seasonType: filterValue, completion: done)
    case .live:
      BiliAPI.shared.live(page: pageValue, completion: done)
    case .zone:
      BiliAPI.shared.zone(rid: filterValue, page: pageValue, completion: done)
    case .favorites:
      BiliAPI.shared.favorites(page: pageValue, completion: done)
    case .history:
      BiliAPI.shared.history(page: pageValue, cursor: cursorValue) { [weak self] result in
        switch result {
        case .failure(let error):
          done(.failure(error))
        case .success(let value):
          self?.cursor = value.1
          self?.hasMore = !value.1.isEmpty
          done(.success(value.0))
        }
      }
    case .following:
      BiliAPI.shared.following(page: pageValue, completion: done)
    case .dynamic:
      BiliAPI.shared.dynamicFeed(page: pageValue, completion: done)
    case .messages:
      BiliAPI.shared.messages(page: pageValue, filter: messageFilter, completion: done)
    case .space:
      BiliAPI.shared.space(mid: targetId, page: pageValue, completion: done)
    case .season:
      BiliAPI.shared.season(targetId) { [weak self] result in
        guard let self = self else { return }
        self.loading = false
        switch result {
        case .failure(let error):
          self.status.text = error.localizedDescription
          self.status.isHidden = false
        case .success(let season):
          self.titleText = season.title
          self.titleLabel.text = season.title
          self.items = season.episodes
          self.hasMore = false
          self.status.text = season.episodes.isEmpty ? "暂无选集" : nil
          self.status.isHidden = !season.episodes.isEmpty
          self.table.reloadData()
        }
      }
    }
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return items.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let item = items[indexPath.row]
    if item.kind == "message" {
      let cell = tableView.dequeueReusableCell(withIdentifier: ModuleMessageCell.reuseID, for: indexPath) as! ModuleMessageCell
      cell.configure(item)
      return cell
    }
    let cell = tableView.dequeueReusableCell(withIdentifier: ModuleMediaCell.reuseID, for: indexPath) as! ModuleMediaCell
    cell.configure(item)
    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let item = items[indexPath.row]
    if item.kind == "message" { return }
    onSelect?(item)
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if scrollView.contentOffset.y > scrollView.contentSize.height - scrollView.bounds.height * 2 {
      load(reset: false)
    }
  }
}

final class ModuleMediaCell: UITableViewCell {
  static let reuseID = "ModuleMediaCell"
  let cover = UIImageView()
  private let title = UILabel()
  private let meta = UILabel()
  private let duration = UILabel()
  private let badge = UILabel()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    backgroundColor = .clear
    selectionStyle = .none

    cover.contentMode = .scaleAspectFill
    cover.clipsToBounds = true
    cover.layer.cornerRadius = NativeTheme.cornerRadius
    cover.backgroundColor = UIColor(white: 0.12, alpha: 1)
    contentView.addSubview(cover)

    title.font = NativeTheme.titleFont(14)
    title.textColor = NativeTheme.foreground
    title.numberOfLines = 2
    contentView.addSubview(title)

    meta.font = NativeTheme.bodyFont(12)
    meta.textColor = NativeTheme.secondary
    contentView.addSubview(meta)

    duration.font = NativeTheme.numberFont(10)
    duration.textColor = .white
    duration.backgroundColor = UIColor.black.withAlphaComponent(0.58)
    duration.layer.cornerRadius = NativeTheme.cornerRadius
    duration.clipsToBounds = true
    duration.textAlignment = .center
    contentView.addSubview(duration)

    badge.font = NativeTheme.numberFont(9)
    badge.textColor = .white
    badge.backgroundColor = NativeTheme.accent
    badge.layer.cornerRadius = NativeTheme.cornerRadius
    badge.clipsToBounds = true
    badge.textAlignment = .center
    contentView.addSubview(badge)

    [cover, title, meta, duration, badge].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
    NSLayoutConstraint.activate([
      cover.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      cover.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
      cover.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
      cover.widthAnchor.constraint(equalToConstant: 142),
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

      badge.leadingAnchor.constraint(equalTo: cover.leadingAnchor, constant: 4),
      badge.topAnchor.constraint(equalTo: cover.topAnchor, constant: 4),
      badge.widthAnchor.constraint(greaterThanOrEqualToConstant: 30),
      badge.heightAnchor.constraint(equalToConstant: 17),
    ])
    contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 102).isActive = true
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(_ item: VideoItem) {
    title.text = item.title.isEmpty ? item.text : item.title
    meta.text = item.meta.isEmpty ? item.owner : item.meta
    duration.text = item.duration
    badge.text = item.badge
    badge.isHidden = item.badge.isEmpty
    ImageLoader.shared.load(item.pic, into: cover)
  }
}

final class ModuleMessageCell: UITableViewCell {
  static let reuseID = "ModuleMessageCell"
  private let avatar = UIImageView()
  private let name = UILabel()
  private let text = UILabel()
  private let time = UILabel()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    backgroundColor = .clear
    selectionStyle = .none

    avatar.contentMode = .scaleAspectFill
    avatar.clipsToBounds = true
    avatar.layer.cornerRadius = 21
    avatar.backgroundColor = UIColor(white: 0.12, alpha: 1)
    contentView.addSubview(avatar)

    name.font = NativeTheme.bodyFont(12)
    name.textColor = NativeTheme.secondary
    contentView.addSubview(name)

    text.font = NativeTheme.bodyFont(14)
    text.textColor = NativeTheme.foreground
    text.numberOfLines = 3
    contentView.addSubview(text)

    time.font = NativeTheme.numberFont(10)
    time.textColor = NativeTheme.tertiary
    contentView.addSubview(time)

    [avatar, name, text, time].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
    NSLayoutConstraint.activate([
      avatar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18),
      avatar.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      avatar.widthAnchor.constraint(equalToConstant: 42),
      avatar.heightAnchor.constraint(equalToConstant: 42),

      name.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 10),
      name.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -18),
      name.topAnchor.constraint(equalTo: avatar.topAnchor),

      text.leadingAnchor.constraint(equalTo: name.leadingAnchor),
      text.trailingAnchor.constraint(equalTo: name.trailingAnchor),
      text.topAnchor.constraint(equalTo: name.bottomAnchor, constant: 4),

      time.leadingAnchor.constraint(equalTo: name.leadingAnchor),
      time.topAnchor.constraint(equalTo: text.bottomAnchor, constant: 5),
      time.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(_ item: VideoItem) {
    name.text = item.user
    text.text = item.text
    if item.time > 0 {
      let seconds = item.time > 100_000_000_000 ? item.time / 1000 : item.time
      let date = Date(timeIntervalSince1970: TimeInterval(seconds))
      let formatter = DateFormatter()
      formatter.dateFormat = "MM-dd HH:mm"
      time.text = formatter.string(from: date)
    } else {
      time.text = ""
    }
    ImageLoader.shared.load(item.avatar, into: avatar)
  }
}
