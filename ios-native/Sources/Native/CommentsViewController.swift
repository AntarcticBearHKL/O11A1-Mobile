import UIKit

final class CommentsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
  private let aid: Int64
  private let table = UITableView(frame: .zero, style: .plain)
  private let titleLabel = UILabel()
  private let closeButton = UIButton(type: .system)
  private let status = UILabel()
  private let input = UITextField()
  private let sendButton = UIButton(type: .system)
  private var items: [CommentItem] = []
  private var page = 1
  private var loading = false

  init(aid: Int64) {
    self.aid = aid
    super.init(nibName: nil, bundle: nil)
    modalPresentationStyle = .pageSheet
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if #available(iOS 15.0, *) {
      sheetPresentationController?.detents = [.medium(), .large()]
      sheetPresentationController?.prefersGrabberVisible = true
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = NativeTheme.background

    titleLabel.text = "评论"
    titleLabel.font = NativeTheme.titleFont(16)
    titleLabel.textColor = NativeTheme.foreground
    view.addSubview(titleLabel)

    closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
    closeButton.tintColor = NativeTheme.secondary
    closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
    view.addSubview(closeButton)

    table.backgroundColor = .clear
    table.separatorStyle = .none
    table.dataSource = self
    table.delegate = self
    table.register(CommentCell.self, forCellReuseIdentifier: CommentCell.reuseID)
    view.addSubview(table)

    status.font = NativeTheme.bodyFont(13)
    status.textColor = NativeTheme.secondary
    status.textAlignment = .center
    status.numberOfLines = 0
    status.isHidden = true
    view.addSubview(status)

    input.placeholder = "发一条友善的评论"
    input.font = NativeTheme.bodyFont(13)
    input.textColor = NativeTheme.foreground
    input.backgroundColor = NativeTheme.foreground.withAlphaComponent(0.06)
    input.layer.cornerRadius = 18
    input.layer.cornerCurve = .continuous
    input.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
    input.leftViewMode = .always
    input.returnKeyType = .send
    input.delegate = self
    view.addSubview(input)

    sendButton.setTitle("发送", for: .normal)
    sendButton.setTitleColor(NativeTheme.accent, for: .normal)
    sendButton.titleLabel?.font = NativeTheme.titleFont(13)
    sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
    view.addSubview(sendButton)

    [titleLabel, closeButton, table, status, input, sendButton].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
    }
    NSLayoutConstraint.activate([
      titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 14),

      closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
      closeButton.widthAnchor.constraint(equalToConstant: 36),
      closeButton.heightAnchor.constraint(equalToConstant: 36),

      table.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      table.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      table.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
      table.bottomAnchor.constraint(equalTo: input.topAnchor, constant: -8),

      status.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      status.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      status.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
      status.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),

      input.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      input.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
      input.heightAnchor.constraint(equalToConstant: 38),
      input.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),

      sendButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      sendButton.centerYAnchor.constraint(equalTo: input.centerYAnchor),
      sendButton.widthAnchor.constraint(equalToConstant: 52),
    ])
    load()
  }

  @objc private func close() {
    dismiss(animated: true)
  }

  @objc private func sendTapped() {
    let text = input.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    guard !text.isEmpty else { return }
    input.text = ""
    BiliAPI.shared.sendComment(aid: aid, message: text) { [weak self] ok in
      guard let self = self else { return }
      if ok {
        self.items = []
        self.page = 1
        self.table.reloadData()
        self.load()
      } else {
        self.status.text = "发送失败，请先登录"
        self.status.isHidden = false
      }
    }
  }

  private func load() {
    guard !loading else { return }
    loading = true
    if items.isEmpty {
      status.text = "正在加载评论…"
      status.isHidden = false
    }
    BiliAPI.shared.comments(aid: aid, page: page) { [weak self] result in
      guard let self = self else { return }
      self.loading = false
      switch result {
      case .failure(let error):
        self.status.text = error.localizedDescription
        self.status.isHidden = false
      case .success(let values):
        self.items.append(contentsOf: values)
        self.status.text = values.isEmpty ? "还没有评论" : nil
        self.status.isHidden = !values.isEmpty
        self.page += 1
        self.table.reloadData()
      }
    }
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return items.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: CommentCell.reuseID, for: indexPath) as! CommentCell
    let item = items[indexPath.row]
    cell.onReplies = { [weak self] in self?.showReplies(item) }
    cell.configure(item)
    return cell
  }

  private func showReplies(_ item: CommentItem) {
    guard item.rpid > 0 else { return }
    let replies = CommentRepliesViewController(aid: aid, root: item.rpid)
    replies.modalPresentationStyle = .pageSheet
    present(replies, animated: true)
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if scrollView.contentOffset.y > scrollView.contentSize.height - scrollView.bounds.height * 2 {
      load()
    }
  }
}

extension CommentsViewController: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    sendTapped()
    textField.resignFirstResponder()
    return true
  }
}

private final class CommentCell: UITableViewCell {
  static let reuseID = "CommentCell"

  var onReplies: (() -> Void)?

  private let avatar = UIImageView()
  private let name = UILabel()
  private let message = CommentMessageLabel()
  private let imageStrip = CommentImageStrip()
  private let meta = UILabel()
  private let replies = UIButton(type: .system)
  private var repliesHeight: NSLayoutConstraint?

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    backgroundColor = .clear
    selectionStyle = .none

    avatar.contentMode = .scaleAspectFill
    avatar.clipsToBounds = true
    avatar.layer.cornerRadius = 18
    avatar.backgroundColor = NativeTheme.foreground.withAlphaComponent(0.08)
    contentView.addSubview(avatar)

    name.font = NativeTheme.bodyFont(12)
    name.textColor = NativeTheme.secondary
    contentView.addSubview(name)

    message.font = NativeTheme.bodyFont(14)
    message.textColor = NativeTheme.foreground
    message.numberOfLines = 0
    contentView.addSubview(message)

    meta.font = NativeTheme.numberFont(10)
    meta.textColor = NativeTheme.tertiary
    contentView.addSubview(meta)

    replies.titleLabel?.font = NativeTheme.bodyFont(11)
    replies.setTitleColor(NativeTheme.accent, for: .normal)
    replies.contentHorizontalAlignment = .left
    replies.contentEdgeInsets = UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0)
    replies.isHidden = true
    replies.addTarget(self, action: #selector(tapReplies), for: .touchUpInside)
    contentView.addSubview(replies)
    repliesHeight = replies.heightAnchor.constraint(equalToConstant: 0)
    repliesHeight?.isActive = true

    let bodyStack = UIStackView(arrangedSubviews: [message, imageStrip, meta, replies])
    bodyStack.axis = .vertical
    bodyStack.alignment = .fill
    bodyStack.spacing = 6
    contentView.addSubview(bodyStack)

    [avatar, name, bodyStack].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
    NSLayoutConstraint.activate([
      avatar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18),
      avatar.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      avatar.widthAnchor.constraint(equalToConstant: 36),
      avatar.heightAnchor.constraint(equalToConstant: 36),

      name.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 10),
      name.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -18),
      name.topAnchor.constraint(equalTo: avatar.topAnchor),

      bodyStack.leadingAnchor.constraint(equalTo: name.leadingAnchor),
      bodyStack.trailingAnchor.constraint(equalTo: name.trailingAnchor),
      bodyStack.topAnchor.constraint(equalTo: name.bottomAnchor, constant: 4),
      bodyStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    imageStrip.setImages([])
  }

  func configure(_ item: CommentItem) {
    name.text = item.name
    imageStrip.setImages(item.images)
    message.configure(
      text: item.message,
      emotes: item.emotes,
      font: NativeTheme.bodyFont(14),
      color: NativeTheme.foreground,
      lineHeight: 22,
      tracking: 0.1,
      emoteSize: 18,
      paragraphSpacing: 4
    )
    meta.text = "赞 \(item.likes)"
    let hasReplies = item.replies > 0 && onReplies != nil
    replies.setTitle(hasReplies ? "\(item.replies) 条回复" : "", for: .normal)
    replies.isHidden = !hasReplies
    repliesHeight?.constant = hasReplies ? 24 : 0
    ImageLoader.shared.load(item.face, into: avatar)
  }

  @objc private func tapReplies() {
    onReplies?()
  }
}

final class CommentRepliesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
  private let aid: Int64
  private let root: Int64
  private let table = UITableView(frame: .zero, style: .plain)
  private let titleLabel = UILabel()
  private let closeButton = UIButton(type: .system)
  private let status = UILabel()
  private var items: [CommentItem] = []
  private var page = 1
  private var loading = false

  init(aid: Int64, root: Int64) {
    self.aid = aid
    self.root = root
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if #available(iOS 15.0, *) {
      sheetPresentationController?.detents = [.medium(), .large()]
      sheetPresentationController?.prefersGrabberVisible = true
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = NativeTheme.background

    titleLabel.text = "回复"
    titleLabel.font = NativeTheme.titleFont(16)
    titleLabel.textColor = NativeTheme.foreground
    view.addSubview(titleLabel)

    closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
    closeButton.tintColor = NativeTheme.secondary
    closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
    view.addSubview(closeButton)

    table.backgroundColor = .clear
    table.separatorStyle = .none
    table.dataSource = self
    table.delegate = self
    table.register(CommentCell.self, forCellReuseIdentifier: CommentCell.reuseID)
    view.addSubview(table)

    status.font = NativeTheme.bodyFont(13)
    status.textColor = NativeTheme.secondary
    status.textAlignment = .center
    status.numberOfLines = 0
    status.isHidden = true
    view.addSubview(status)

    [titleLabel, closeButton, table, status].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
    NSLayoutConstraint.activate([
      titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 14),

      closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
      closeButton.widthAnchor.constraint(equalToConstant: 36),
      closeButton.heightAnchor.constraint(equalToConstant: 36),

      table.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      table.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      table.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
      table.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      status.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      status.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      status.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
      status.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),
    ])
    load()
  }

  @objc private func close() {
    dismiss(animated: true)
  }

  private func load() {
    guard !loading else { return }
    loading = true
    if items.isEmpty {
      status.text = "正在加载回复…"
      status.isHidden = false
    }
    BiliAPI.shared.commentReplies(aid: aid, root: root, page: page) { [weak self] result in
      guard let self = self else { return }
      self.loading = false
      switch result {
      case .failure(let error):
        self.status.text = error.localizedDescription
        self.status.isHidden = false
      case .success(let values):
        self.items.append(contentsOf: values)
        self.status.text = values.isEmpty ? "还没有回复" : nil
        self.status.isHidden = !values.isEmpty
        self.page += 1
        self.table.reloadData()
      }
    }
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return items.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: CommentCell.reuseID, for: indexPath) as! CommentCell
    cell.onReplies = nil
    cell.configure(items[indexPath.row])
    return cell
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if scrollView.contentOffset.y > scrollView.contentSize.height - scrollView.bounds.height * 2 {
      load()
    }
  }
}
