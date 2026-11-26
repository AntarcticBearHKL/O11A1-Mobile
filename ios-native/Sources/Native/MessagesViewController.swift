import UIKit

final class MessagesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
  var onLogin: (() -> Void)?
  var onClose: (() -> Void)?

  private let filterButton = UIButton(type: .system)
  private let table = UITableView(frame: .zero, style: .plain)
  private let emptyStack = UIStackView()
  private let emptyTitle = UILabel()
  private let emptyDetail = UILabel()
  private let emptyButton = UIButton(type: .system)
  private var items: [VideoItem] = []
  private var page = 1
  private var loading = false
  private var hasMore = true
  private var filter = "reply"
  private var failed = false
  private var needsLogin = false

  private let filterNames = ["回复", "@我", "点赞"]
  private let filterValues = ["reply", "at", "like"]

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = NativeTheme.background

    filterButton.setTitle("回复 ⌄", for: .normal)
    filterButton.titleLabel?.font = UIFont.systemFont(ofSize: 10.5, weight: .medium)
    filterButton.setTitleColor(NativeTheme.secondary, for: .normal)
    filterButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
    filterButton.layer.cornerRadius = NativeTheme.cornerRadius
    filterButton.layer.cornerCurve = .continuous
    filterButton.layer.borderWidth = 1
    filterButton.layer.borderColor = NativeTheme.hairline.cgColor
    filterButton.showsMenuAsPrimaryAction = true
    view.addSubview(filterButton)
    filterButton.translatesAutoresizingMaskIntoConstraints = false

    table.backgroundColor = .clear
    table.separatorStyle = .none
    table.dataSource = self
    table.delegate = self
    table.rowHeight = UITableView.automaticDimension
    table.estimatedRowHeight = 110
    table.register(MessageRowCell.self, forCellReuseIdentifier: MessageRowCell.reuseID)
    table.showsVerticalScrollIndicator = false
    table.contentInsetAdjustmentBehavior = .never
    view.addSubview(table)
    table.translatesAutoresizingMaskIntoConstraints = false

    emptyStack.axis = .vertical
    emptyStack.alignment = .center
    emptyStack.spacing = 4
    emptyStack.isHidden = true
    emptyTitle.font = UIFont.systemFont(ofSize: 15, weight: .bold)
    emptyTitle.textColor = NativeTheme.foreground
    emptyDetail.font = NativeTheme.bodyFont(13)
    emptyDetail.textColor = NativeTheme.secondary
    emptyDetail.numberOfLines = 0
    emptyDetail.textAlignment = .center
    emptyStack.addArrangedSubview(emptyTitle)
    emptyStack.addArrangedSubview(emptyDetail)
    emptyButton.setTitle("去登录", for: .normal)
    emptyButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .bold)
    emptyButton.setTitleColor(NativeTheme.navBlue, for: .normal)
    emptyButton.backgroundColor = NativeTheme.navSoft
    emptyButton.layer.cornerRadius = NativeTheme.cornerRadius
    emptyButton.layer.cornerCurve = .continuous
    emptyButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 18, bottom: 8, right: 18)
    emptyButton.addTarget(self, action: #selector(emptyAction), for: .touchUpInside)
    emptyStack.setCustomSpacing(14, after: emptyDetail)
    emptyStack.addArrangedSubview(emptyButton)
    view.addSubview(emptyStack)
    emptyStack.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      filterButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18),
      filterButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 14),
      filterButton.heightAnchor.constraint(equalToConstant: 24),

      table.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      table.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      table.topAnchor.constraint(equalTo: filterButton.bottomAnchor, constant: 10),
      table.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      emptyStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      emptyStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      emptyStack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
      emptyStack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32),
    ])

    buildFilterMenu()
    load(reset: true)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    table.contentInset = UIEdgeInsets(top: 0, left: 0,
                                      bottom: 112 + view.safeAreaInsets.bottom, right: 0)
    filterButton.layer.borderColor = NativeTheme.hairline.cgColor
  }

  override func viewSafeAreaInsetsDidChange() {
    super.viewSafeAreaInsetsDidChange()
    table.contentInset = UIEdgeInsets(top: 0, left: 0,
                                      bottom: 112 + view.safeAreaInsets.bottom, right: 0)
  }

  private func buildFilterMenu() {
    let actions = filterValues.enumerated().map { index, value -> UIAction in
      UIAction(title: filterNames[index],
               state: value == filter ? .on : .off) { [weak self] _ in
        guard let self = self else { return }
        self.filter = value
        self.filterButton.setTitle(self.filterNames[index] + " ⌄", for: .normal)
        self.buildFilterMenu()
        self.items = []
        self.page = 1
        self.hasMore = true
        self.failed = false
        self.needsLogin = false
        self.table.reloadData()
        self.load(reset: true)
      }
    }
    filterButton.menu = UIMenu(children: actions)
  }

  private func load(reset: Bool) {
    guard !loading else { return }
    if reset {
      page = 1
      hasMore = true
    }
    guard hasMore else { return }
    loading = true
    BiliAPI.shared.messages(page: page, filter: filter) { [weak self] result in
      guard let self = self else { return }
      self.loading = false
      switch result {
      case .failure(let error):
        self.failed = true
        if self.items.isEmpty {
          let message = error.localizedDescription
          self.needsLogin = message.contains("登录") || message.lowercased().contains("login")
          self.showEmpty(title: self.needsLogin ? "登录后查看消息" : "消息加载失败",
                         detail: self.needsLogin ? "登录后同步回复、@ 和点赞。" : message,
                         action: self.needsLogin ? "去登录" : "重试")
        }
      case .success(let values):
        self.failed = false
        self.needsLogin = false
        self.items.append(contentsOf: values)
        self.hasMore = !values.isEmpty
        self.page += 1
        self.table.reloadData()
        self.emptyStack.isHidden = !self.items.isEmpty
        if self.items.isEmpty {
          self.showEmpty(title: "暂无消息", detail: "回复、@ 和收到的赞会出现在这里。",
                         action: nil)
        }
      }
    }
  }

  private func showEmpty(title: String, detail: String, action: String?) {
    emptyTitle.text = title
    emptyDetail.text = detail
    emptyButton.isHidden = action == nil
    emptyButton.setTitle(action, for: .normal)
    emptyStack.isHidden = false
  }

  @objc private func emptyAction() {
    if needsLogin {
      onLogin?()
      return
    }
    if failed {
      failed = false
      items = []
      page = 1
      hasMore = true
      table.reloadData()
      load(reset: true)
    }
  }

  func reload() {
    items = []
    page = 1
    hasMore = true
    failed = false
    needsLogin = false
    table.reloadData()
    emptyStack.isHidden = true
    load(reset: true)
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return items.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: MessageRowCell.reuseID, for: indexPath) as! MessageRowCell
    cell.configure(items[indexPath.row])
    return cell
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    guard scrollView.contentSize.height > 0 else { return }
    if scrollView.contentOffset.y > scrollView.contentSize.height - scrollView.bounds.height * 2 {
      load(reset: false)
    }
  }
}

final class MessageRowCell: UITableViewCell {
  static let reuseID = "MessageRowCell"

  private let avatar = UIImageView()
  private let user = UILabel()
  private let text = UILabel()
  private let time = UILabel()
  private let unread = UIView()
  private let separator = UIView()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    avatar.contentMode = .scaleAspectFill
    avatar.clipsToBounds = true
    avatar.layer.cornerRadius = 17
    avatar.backgroundColor = NativeTheme.tertiary.withAlphaComponent(0.2)
    contentView.addSubview(avatar)

    user.font = UIFont.systemFont(ofSize: 12, weight: .bold)
    user.textColor = NativeTheme.foreground
    user.numberOfLines = 1
    contentView.addSubview(user)

    text.font = NativeTheme.bodyFont(12.5)
    text.textColor = NativeTheme.foreground
    text.numberOfLines = 0
    contentView.addSubview(text)

    time.font = NativeTheme.bodyFont(10)
    time.textColor = NativeTheme.tertiary
    contentView.addSubview(time)

    unread.backgroundColor = NativeTheme.navBlue
    unread.layer.cornerRadius = 3.5
    contentView.addSubview(unread)

    separator.backgroundColor = NativeTheme.hairline
    contentView.addSubview(separator)

    [avatar, user, text, time, unread, separator].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
    }
    NSLayoutConstraint.activate([
      avatar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
      avatar.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 17),
      avatar.widthAnchor.constraint(equalToConstant: 34),
      avatar.heightAnchor.constraint(equalToConstant: 34),

      user.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 12),
      user.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 17),
      user.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -44),

      text.leadingAnchor.constraint(equalTo: user.leadingAnchor),
      text.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
      text.topAnchor.constraint(equalTo: user.bottomAnchor, constant: 5),

      time.leadingAnchor.constraint(equalTo: user.leadingAnchor),
      time.topAnchor.constraint(equalTo: text.bottomAnchor, constant: 5),
      time.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -17),

      unread.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -21),
      unread.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 27),
      unread.widthAnchor.constraint(equalToConstant: 7),
      unread.heightAnchor.constraint(equalToConstant: 7),

      separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18),
      separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -18),
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
  }

  func configure(_ item: VideoItem) {
    user.text = item.user
    text.text = item.text
    time.text = NativeTheme.timeAgo(item.time)
    unread.isHidden = !item.unread
    ImageLoader.shared.load(item.avatar, into: avatar, placeholder: nil)
    separator.backgroundColor = NativeTheme.hairline
  }
}
