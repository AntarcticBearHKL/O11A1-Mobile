import UIKit

final class CommentsPanelViewController: UIViewController, UITableViewDataSource,
  UITableViewDelegate, UIGestureRecognizerDelegate {
  var embedded = false
  var onSwipeLeft: (() -> Void)?
  var onSwipeRight: (() -> Void)?
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
  private var embeddedSwipePan: UIPanGestureRecognizer?
  private var repliesCache: [Int64: [CommentItem]] = [:]
  private var expandedRoots: Set<Int64> = []
  private var loadingReplies: Set<Int64> = []

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

    if !embedded {
      let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
      pan.delegate = self
      view.addGestureRecognizer(pan)
      dismissPan = pan
    } else {
      let swipe = UIPanGestureRecognizer(target: self, action: #selector(handleEmbeddedSwipe(_:)))
      swipe.delegate = self
      view.addGestureRecognizer(swipe)
      embeddedSwipePan = swipe
    }

    load(reset: true)
  }

  private func updateInsets() {
    if embedded {
      table.contentInset = UIEdgeInsets(top: 12, left: 0,
                                        bottom: 78 + view.safeAreaInsets.bottom, right: 0)
    } else {
      table.contentInset = UIEdgeInsets(top: view.safeAreaInsets.top + 16, left: 0,
                                        bottom: 102 + view.safeAreaInsets.bottom, right: 0)
    }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    updateInsets()
    card.layer.cornerRadius = embedded ? 0 : 28
    blur.layer.cornerRadius = embedded ? 0 : 28
    tint.layer.cornerRadius = embedded ? 0 : 28
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
    let expanded = expandedRoots.contains(item.rpid)
    cell.configure(item,
                   replies: repliesCache[item.rpid] ?? [],
                   expanded: expanded,
                   loading: loadingReplies.contains(item.rpid))
    cell.onReplies = { [weak self] in
      self?.toggleReplies(item)
    }
    return cell
  }

  private func toggleReplies(_ item: CommentItem) {
    let root = item.rpid
    guard root > 0 else { return }
    if expandedRoots.contains(root) {
      expandedRoots.remove(root)
      reloadComment(root)
      return
    }
    expandedRoots.insert(root)
    if repliesCache[root] != nil {
      reloadComment(root)
      return
    }
    loadingReplies.insert(root)
    reloadComment(root)
    BiliAPI.shared.commentReplies(aid: aid, root: root, page: 1) { [weak self] result in
      guard let self = self else { return }
      self.loadingReplies.remove(root)
      if case .success(let values) = result {
        self.repliesCache[root] = values
      }
      self.reloadComment(root)
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
    guard gesture.state == .ended || gesture.state == .cancelled else { return }
    let translation = gesture.translation(in: view).x
    if translation < -60 {
      onSwipeLeft?()
    } else if translation > 60 {
      onSwipeRight?()
    }
  }

  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
    if pan === embeddedSwipePan {
      let velocity = pan.velocity(in: view)
      return abs(velocity.x) > abs(velocity.y) * 1.2
    }
    guard pan === dismissPan else { return true }
    let velocity = pan.velocity(in: view)
    return abs(velocity.x) > abs(velocity.y)
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

  var onReplies: (() -> Void)?

  private let avatar = UIImageView()
  private let name = UILabel()
  private let time = UILabel()
  private let message = UILabel()
  private let likes = UILabel()
  private let replies = UIButton(type: .system)
  private let repliesStack = UIStackView()
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
    avatar.widthAnchor.constraint(equalToConstant: 34).isActive = true
    avatar.heightAnchor.constraint(equalToConstant: 34).isActive = true

    name.font = UIFont.systemFont(ofSize: 12, weight: .bold)
    name.textColor = NativeTheme.foreground

    time.font = NativeTheme.bodyFont(10)
    time.textColor = NativeTheme.tertiary

    let meta = UIStackView(arrangedSubviews: [name, time])
    meta.axis = .horizontal
    meta.alignment = .firstBaseline
    meta.spacing = 7

    message.font = NativeTheme.bodyFont(13.5)
    message.textColor = NativeTheme.foreground
    message.numberOfLines = 0

    likes.font = NativeTheme.bodyFont(10.5)
    likes.textColor = NativeTheme.tertiary

    replies.titleLabel?.font = UIFont.systemFont(ofSize: 10.5, weight: .bold)
    replies.setTitleColor(NativeTheme.secondary, for: .normal)
    replies.contentHorizontalAlignment = .left
    replies.contentEdgeInsets = UIEdgeInsets(top: 2, left: 0, bottom: 2, right: 0)
    replies.isHidden = true
    replies.addTarget(self, action: #selector(tapReplies), for: .touchUpInside)

    let actions = UIStackView(arrangedSubviews: [likes, replies])
    actions.axis = .horizontal
    actions.alignment = .center
    actions.spacing = 16

    repliesStack.axis = .vertical
    repliesStack.spacing = 8
    repliesStack.isHidden = true

    let copy = UIStackView(arrangedSubviews: [meta, message, actions, repliesStack])
    copy.axis = .vertical
    copy.alignment = .fill
    copy.spacing = 4
    copy.setCustomSpacing(7, after: message)

    let header = UIStackView(arrangedSubviews: [avatar, copy])
    header.axis = .horizontal
    header.alignment = .top
    header.spacing = 11
    contentView.addSubview(header)
    header.translatesAutoresizingMaskIntoConstraints = false

    separator.backgroundColor = NativeTheme.hairline
    contentView.addSubview(separator)
    separator.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      header.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
      header.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
      header.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
      header.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),

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
    onReplies = nil
    avatar.image = nil
    repliesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
  }

  func configure(_ item: CommentItem, replies items: [CommentItem],
                 expanded: Bool, loading: Bool) {
    name.text = item.name.isEmpty ? "用户" : item.name
    time.text = NativeTheme.timeAgo(Int64(item.time))
    message.text = item.message
    likes.text = "赞 \(item.likes)"
    let hasReplies = item.replies > 0 || !items.isEmpty
    replies.isHidden = !hasReplies
    replies.setTitle(expanded ? "收起回复" : "\(max(item.replies, items.count)) 条回复",
                     for: .normal)
    separator.backgroundColor = NativeTheme.hairline
    ImageLoader.shared.load(item.face, into: avatar)

    repliesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
    repliesStack.isHidden = !expanded
    guard expanded else { return }
    if loading && items.isEmpty {
      let loadingLabel = UILabel()
      loadingLabel.text = "正在加载回复…"
      loadingLabel.font = NativeTheme.bodyFont(11)
      loadingLabel.textColor = NativeTheme.tertiary
      repliesStack.addArrangedSubview(loadingLabel)
      return
    }
    for reply in items.prefix(3) {
      repliesStack.addArrangedSubview(makeReplyRow(reply))
    }
    if items.count > 3 {
      let more = UILabel()
      more.text = "共 \(items.count) 条回复"
      more.font = NativeTheme.bodyFont(10)
      more.textColor = NativeTheme.tertiary
      repliesStack.addArrangedSubview(more)
    }
  }

  private func makeReplyRow(_ item: CommentItem) -> UIView {
    let replyAvatar = UIImageView()
    replyAvatar.contentMode = .scaleAspectFill
    replyAvatar.clipsToBounds = true
    replyAvatar.layer.cornerRadius = 12
    replyAvatar.backgroundColor = NativeTheme.tertiary.withAlphaComponent(0.2)
    replyAvatar.widthAnchor.constraint(equalToConstant: 24).isActive = true
    replyAvatar.heightAnchor.constraint(equalToConstant: 24).isActive = true
    ImageLoader.shared.load(item.face, into: replyAvatar)

    let replyName = UILabel()
    replyName.text = item.name.isEmpty ? "用户" : item.name
    replyName.font = UIFont.systemFont(ofSize: 10.5, weight: .bold)
    replyName.textColor = NativeTheme.foreground
    let replyMessage = UILabel()
    replyMessage.text = item.message
    replyMessage.font = NativeTheme.bodyFont(12.5)
    replyMessage.textColor = NativeTheme.foreground
    replyMessage.numberOfLines = 0

    let copy = UIStackView(arrangedSubviews: [replyName, replyMessage])
    copy.axis = .vertical
    copy.spacing = 2

    let row = UIStackView(arrangedSubviews: [replyAvatar, copy])
    row.axis = .horizontal
    row.alignment = .top
    row.spacing = 10
    return row
  }

  @objc private func tapReplies() {
    onReplies?()
  }
}
