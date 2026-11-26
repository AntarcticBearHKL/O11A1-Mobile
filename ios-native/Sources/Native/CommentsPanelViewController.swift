import UIKit

final class CommentsPanelViewController: UIViewController, UITableViewDataSource,
  UITableViewDelegate, UIGestureRecognizerDelegate {
  private let aid: Int64
  private let card = UIView()
  private let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
  private let tint = UIView()
  private let table = UITableView(frame: .zero, style: .plain)
  private let status = UILabel()
  private let sortDock = UIView()
  private let sortBlur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
  private let latestButton = UIButton(type: .custom)
  private let hotButton = UIButton(type: .custom)
  private var items: [CommentItem] = []
  private var page = 1
  private var sort = 2
  private var loading = false
  private var dismissPan: UIPanGestureRecognizer?

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

    card.layer.cornerRadius = 28
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

    sortDock.layer.cornerRadius = 26
    sortDock.layer.cornerCurve = .continuous
    sortDock.layer.borderWidth = 1
    sortDock.layer.shadowColor = UIColor.black.cgColor
    sortDock.layer.shadowOpacity = 0.18
    sortDock.layer.shadowRadius = 17
    sortDock.layer.shadowOffset = CGSize(width: 0, height: 7)
    sortDock.clipsToBounds = false
    card.addSubview(sortDock)
    sortDock.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      sortDock.centerXAnchor.constraint(equalTo: card.centerXAnchor),
      sortDock.bottomAnchor.constraint(equalTo: card.safeAreaLayoutGuide.bottomAnchor, constant: -16),
      sortDock.heightAnchor.constraint(equalToConstant: 52),
    ])
    sortBlur.isUserInteractionEnabled = false
    sortBlur.layer.cornerRadius = 26
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
    for (index, button) in [latestButton, hotButton].enumerated() {
      button.tag = index
      button.titleLabel?.font = UIFont.systemFont(ofSize: 13.5, weight: .bold)
      button.layer.cornerRadius = 21
      button.layer.cornerCurve = .continuous
      button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 22, bottom: 0, right: 22)
      button.widthAnchor.constraint(equalToConstant: 92).isActive = true
      button.heightAnchor.constraint(equalToConstant: 42).isActive = true
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

    let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
    pan.delegate = self
    view.addGestureRecognizer(pan)
    dismissPan = pan

    load(reset: true)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    table.contentInset = UIEdgeInsets(top: view.safeAreaInsets.top + 16, left: 0,
                                      bottom: 102 + view.safeAreaInsets.bottom, right: 0)
  }

  override func viewSafeAreaInsetsDidChange() {
    super.viewSafeAreaInsetsDidChange()
    table.contentInset = UIEdgeInsets(top: view.safeAreaInsets.top + 16, left: 0,
                                      bottom: 102 + view.safeAreaInsets.bottom, right: 0)
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    applyGlass()
    updateSort()
  }

  private func applyGlass() {
    let light = traitCollection.userInterfaceStyle == .light
    tint.backgroundColor = light
      ? UIColor(white: 1, alpha: 0.66)
      : UIColor(red: 10.0 / 255.0, green: 12.0 / 255.0, blue: 18.0 / 255.0, alpha: 0.84)
    sortDock.layer.borderColor = light
      ? UIColor(white: 1, alpha: 0.62).cgColor
      : UIColor(white: 1, alpha: 0.10).cgColor
    sortDock.backgroundColor = light
      ? UIColor(white: 1, alpha: 0.86)
      : UIColor(red: 20.0 / 255.0, green: 24.0 / 255.0, blue: 32.0 / 255.0, alpha: 0.86)
    sortBlur.alpha = light ? 0.7 : 0.5
  }

  private func updateSort() {
    let light = traitCollection.userInterfaceStyle == .light
    for (index, button) in [latestButton, hotButton].enumerated() {
      let on = (index == 0 && sort == 0) || (index == 1 && sort == 2)
      button.backgroundColor = on
        ? (light ? NativeTheme.foreground : NativeTheme.foreground)
        : .clear
      button.setTitleColor(on ? NativeTheme.background : NativeTheme.secondary, for: .normal)
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
      table.reloadData()
      status.text = "正在加载评论…"
      status.isHidden = false
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
        self.status.text = values.isEmpty ? "还没有评论" : nil
        self.status.isHidden = !values.isEmpty
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
    cell.configure(item)
    cell.onReplies = { [weak self] in
      guard let self = self, item.rpid > 0 else { return }
      let replies = CommentRepliesViewController(aid: self.aid, root: item.rpid)
      replies.modalPresentationStyle = .pageSheet
      self.present(replies, animated: true)
    }
    return cell
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    guard scrollView.contentSize.height > 0 else { return }
    if scrollView.contentOffset.y > scrollView.contentSize.height - scrollView.bounds.height * 2 {
      load(reset: false)
    }
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
        dismiss(animated: false)
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

private final class PanelCommentCell: UITableViewCell {
  static let reuseID = "PanelCommentCell"

  var onReplies: (() -> Void)?

  private let avatar = UIImageView()
  private let name = UILabel()
  private let time = UILabel()
  private let message = UILabel()
  private let likes = UILabel()
  private let replies = UIButton(type: .system)
  private let separator = UIView()
  private var repliesHeight: NSLayoutConstraint?

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

    name.font = UIFont.systemFont(ofSize: 12, weight: .bold)
    name.textColor = NativeTheme.foreground
    contentView.addSubview(name)

    time.font = NativeTheme.bodyFont(10)
    time.textColor = NativeTheme.tertiary
    contentView.addSubview(time)

    message.font = NativeTheme.bodyFont(13.5)
    message.textColor = NativeTheme.foreground
    message.numberOfLines = 0
    contentView.addSubview(message)

    likes.font = NativeTheme.bodyFont(10.5)
    likes.textColor = NativeTheme.tertiary
    contentView.addSubview(likes)

    replies.titleLabel?.font = UIFont.systemFont(ofSize: 10.5, weight: .bold)
    replies.setTitleColor(NativeTheme.secondary, for: .normal)
    replies.contentHorizontalAlignment = .left
    replies.contentEdgeInsets = UIEdgeInsets(top: 2, left: 0, bottom: 2, right: 0)
    replies.isHidden = true
    replies.addTarget(self, action: #selector(tapReplies), for: .touchUpInside)
    contentView.addSubview(replies)

    separator.backgroundColor = NativeTheme.hairline
    contentView.addSubview(separator)

    [avatar, name, time, message, likes, replies, separator].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
    }
    repliesHeight = replies.heightAnchor.constraint(equalToConstant: 0)
    repliesHeight?.isActive = true
    NSLayoutConstraint.activate([
      avatar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
      avatar.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
      avatar.widthAnchor.constraint(equalToConstant: 34),
      avatar.heightAnchor.constraint(equalToConstant: 34),

      name.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 11),
      name.topAnchor.constraint(equalTo: avatar.topAnchor),
      time.leadingAnchor.constraint(equalTo: name.trailingAnchor, constant: 7),
      time.centerYAnchor.constraint(equalTo: name.centerYAnchor),
      time.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -20),

      message.leadingAnchor.constraint(equalTo: name.leadingAnchor),
      message.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
      message.topAnchor.constraint(equalTo: name.bottomAnchor, constant: 4),

      likes.leadingAnchor.constraint(equalTo: name.leadingAnchor),
      likes.topAnchor.constraint(equalTo: message.bottomAnchor, constant: 7),

      replies.leadingAnchor.constraint(equalTo: likes.trailingAnchor, constant: 16),
      replies.centerYAnchor.constraint(equalTo: likes.centerYAnchor),
      replies.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -20),

      separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
      separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
      separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      separator.heightAnchor.constraint(equalToConstant: 0.5),
      likes.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(_ item: CommentItem) {
    name.text = item.name.isEmpty ? "用户" : item.name
    let timeText = NativeTheme.timeAgo(Int64(item.time))
    time.text = timeText
    message.text = item.message
    likes.text = "赞 \(item.likes)"
    let hasReplies = item.replies > 0
    replies.setTitle(hasReplies ? "\(item.replies) 条回复" : "", for: .normal)
    replies.isHidden = !hasReplies
    repliesHeight?.constant = hasReplies ? 18 : 0
    separator.backgroundColor = NativeTheme.hairline
    ImageLoader.shared.load(item.face, into: avatar)
  }

  @objc private func tapReplies() {
    onReplies?()
  }
}
