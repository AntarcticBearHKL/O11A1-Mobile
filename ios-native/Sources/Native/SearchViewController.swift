import UIKit

final class SearchViewController: UIViewController, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate {
  var onClose: (() -> Void)?
  var onOpenVideo: ((VideoItem) -> Void)?

  private enum Mode {
    case hot
    case suggest
    case results
  }

  private let searchBar = UISearchBar()
  private let table = UITableView(frame: .zero, style: .plain)
  private let backButton = UIButton(type: .system)
  private let statusLabel = UILabel()
  private var items: [VideoItem] = []
  private var hot: [String] = []
  private var suggestions: [String] = []
  private var mode: Mode = .hot
  private var workItem: DispatchWorkItem?
  private var loading = false

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = NativeTheme.background

    backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
    backButton.tintColor = NativeTheme.foreground
    backButton.addTarget(self, action: #selector(close), for: .touchUpInside)
    view.addSubview(backButton)
    backButton.translatesAutoresizingMaskIntoConstraints = false

    searchBar.placeholder = "搜索视频、UP 主"
    searchBar.searchBarStyle = .minimal
    searchBar.delegate = self
    searchBar.tintColor = NativeTheme.accent
    if let field = searchBar.value(forKey: "searchField") as? UITextField {
      field.textColor = NativeTheme.foreground
      field.backgroundColor = NativeTheme.foreground.withAlphaComponent(0.06)
      field.layer.cornerRadius = 12
      field.clipsToBounds = true
    }
    view.addSubview(searchBar)
    searchBar.translatesAutoresizingMaskIntoConstraints = false

    table.backgroundColor = .clear
    table.separatorStyle = .none
    table.dataSource = self
    table.delegate = self
    table.keyboardDismissMode = .onDrag
    table.register(SearchResultCell.self, forCellReuseIdentifier: SearchResultCell.reuseID)
    table.register(HomeCardCell.self, forCellReuseIdentifier: HomeCardCell.reuseID)
    table.register(UITableViewCell.self, forCellReuseIdentifier: "SuggestionCell")
    table.rowHeight = UITableView.automaticDimension
    table.estimatedRowHeight = 360
    view.addSubview(table)
    table.translatesAutoresizingMaskIntoConstraints = false

    statusLabel.font = NativeTheme.bodyFont(13)
    statusLabel.textColor = NativeTheme.secondary
    statusLabel.textAlignment = .center
    statusLabel.numberOfLines = 0
    statusLabel.isHidden = true
    view.addSubview(statusLabel)
    statusLabel.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
      backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 4),
      backButton.widthAnchor.constraint(equalToConstant: 40),
      backButton.heightAnchor.constraint(equalToConstant: 44),

      searchBar.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 0),
      searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
      searchBar.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),

      table.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      table.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      table.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 4),
      table.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      statusLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
      statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32),
    ])

    loadHot()
  }

  private func loadHot() {
    BiliAPI.shared.searchHot { [weak self] result in
      guard let self = self else { return }
      guard case .success(let values) = result else { return }
      self.hot = values
      if self.mode == .hot {
        self.table.reloadData()
      }
    }
  }

  func focus() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
      self.searchBar.becomeFirstResponder()
    }
  }

  @objc private func close() {
    searchBar.resignFirstResponder()
    onClose?()
  }

  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    workItem?.cancel()
    let term = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !term.isEmpty else {
      mode = .hot
      items = []
      suggestions = []
      table.reloadData()
      statusLabel.isHidden = true
      return
    }
    mode = .suggest
    table.reloadData()
    statusLabel.isHidden = true
    let task = DispatchWorkItem { [weak self] in
      self?.loadSuggestions(term)
    }
    workItem = task
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.22, execute: task)
  }

  private func loadSuggestions(_ term: String) {
    BiliAPI.shared.suggest(term) { [weak self] values in
      guard let self = self, self.mode == .suggest else { return }
      let current = (self.searchBar.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
      guard current == term else { return }
      self.suggestions = values
      self.table.reloadData()
    }
  }

  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    searchBar.resignFirstResponder()
    let term = (searchBar.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    guard !term.isEmpty else { return }
    performSearch(term)
  }

  private func performSearch(_ term: String) {
    guard !loading else { return }
    workItem?.cancel()
    mode = .results
    items = []
    table.reloadData()
    loading = true
    statusLabel.text = "搜索中…"
    statusLabel.isHidden = false
    BiliAPI.shared.search(term, page: 1) { [weak self] result in
      guard let self = self else { return }
      self.loading = false
      switch result {
      case .failure(let error):
        self.statusLabel.text = error.localizedDescription
        self.statusLabel.isHidden = false
      case .success(let items):
        self.items = items
        self.statusLabel.text = items.isEmpty ? "没有找到相关视频" : nil
        self.statusLabel.isHidden = !items.isEmpty
        self.table.reloadData()
      }
    }
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    switch mode {
    case .hot: return hot.count
    case .suggest: return suggestions.count
    case .results: return items.count
    }
  }

  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    if mode == .hot && !hot.isEmpty { return "热搜" }
    return nil
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if mode == .results {
      let cell = tableView.dequeueReusableCell(withIdentifier: HomeCardCell.reuseID, for: indexPath) as! HomeCardCell
      let item = items[indexPath.row]
      cell.configure(item)
      cell.onOpen = { [weak self] in self?.onOpenVideo?(item) }
      cell.onAvatar = nil
      return cell
    }
    let cell = tableView.dequeueReusableCell(withIdentifier: "SuggestionCell", for: indexPath)
    let isHot = mode == .hot
    cell.textLabel?.text = isHot ? hot[indexPath.row] : suggestions[indexPath.row]
    cell.textLabel?.font = NativeTheme.bodyFont(15)
    cell.textLabel?.textColor = NativeTheme.foreground
    cell.imageView?.image = UIImage(systemName: isHot ? "flame.fill" : "magnifyingglass")
    cell.imageView?.tintColor = isHot ? NativeTheme.accent : NativeTheme.secondary
    cell.backgroundColor = .clear
    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    if mode == .results {
      searchBar.resignFirstResponder()
      onOpenVideo?(items[indexPath.row])
      return
    }
    let term = mode == .hot ? hot[indexPath.row] : suggestions[indexPath.row]
    searchBar.text = term
    searchBar.resignFirstResponder()
    performSearch(term)
  }
}

private final class SearchResultCell: UITableViewCell {
  static let reuseID = "SearchResultCell"

  private let cover = UIImageView()
  private let title = UILabel()
  private let meta = UILabel()
  private let duration = UILabel()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    backgroundColor = .clear
    selectionStyle = .none
    contentView.backgroundColor = .clear

    cover.contentMode = .scaleAspectFill
    cover.clipsToBounds = true
    cover.layer.cornerRadius = 8
    cover.backgroundColor = UIColor(white: 0.12, alpha: 1)
    contentView.addSubview(cover)
    cover.translatesAutoresizingMaskIntoConstraints = false

    title.font = NativeTheme.titleFont(14)
    title.textColor = NativeTheme.foreground
    title.numberOfLines = 2
    contentView.addSubview(title)
    title.translatesAutoresizingMaskIntoConstraints = false

    meta.font = NativeTheme.bodyFont(12)
    meta.textColor = NativeTheme.secondary
    contentView.addSubview(meta)
    meta.translatesAutoresizingMaskIntoConstraints = false

    duration.font = NativeTheme.numberFont(11)
    duration.textColor = .white
    duration.backgroundColor = UIColor.black.withAlphaComponent(0.58)
    duration.layer.cornerRadius = 4
    duration.clipsToBounds = true
    duration.textAlignment = .center
    contentView.addSubview(duration)
    duration.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      cover.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      cover.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
      cover.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
      cover.widthAnchor.constraint(equalToConstant: 128),
      cover.heightAnchor.constraint(equalToConstant: 76),

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
    contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 92).isActive = true
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
