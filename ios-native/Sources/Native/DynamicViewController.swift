import UIKit

final class DynamicViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
  var onOpenVideo: ((VideoItem) -> Void)?
  var onLogin: (() -> Void)?

  private let filterButton = UIButton(type: .system)
  private let table = UITableView(frame: .zero, style: .plain)
  private let emptyStack = UIStackView()
  private let emptyTitle = UILabel()
  private let emptyDetail = UILabel()
  private let emptyButton = UIButton(type: .system)
  private var items: [DynamicItem] = []
  private var page = 1
  private var loading = false
  private var hasMore = true
  private var filter = "all"
  private var failed = false
  private var needsLogin = false

  private let filterNames = ["全部", "视频", "图文"]
  private let filterValues = ["all", "video", "image"]

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = NativeTheme.background

    filterButton.setTitle("全部 ⌄", for: .normal)
    filterButton.titleLabel?.font = UIFont.systemFont(ofSize: 10.5, weight: .medium)
    filterButton.setTitleColor(NativeTheme.secondary, for: .normal)
    filterButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
    filterButton.layer.cornerRadius = 12
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
    table.estimatedRowHeight = 280
    table.register(DynamicCardCell.self, forCellReuseIdentifier: DynamicCardCell.reuseID)
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
    emptyButton.layer.cornerRadius = 17
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
                                      bottom: 104 + view.safeAreaInsets.bottom, right: 0)
    filterButton.layer.borderColor = NativeTheme.hairline.cgColor
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
    BiliAPI.shared.dynamicTimeline(page: page, filter: filter) { [weak self] result in
      guard let self = self else { return }
      self.loading = false
      switch result {
      case .failure(let error):
        self.failed = true
        if self.items.isEmpty {
          let message = error.localizedDescription
          self.needsLogin = message.contains("登录") || message.lowercased().contains("login")
          self.showEmpty(title: self.needsLogin ? "登录后查看动态" : "动态加载失败",
                         detail: self.needsLogin ? "登录后同步关注动态。" : message,
                         action: self.needsLogin ? "去登录" : "重试")
        }
      case .success(let value):
        self.failed = false
        self.needsLogin = false
        self.items.append(contentsOf: value.0)
        self.hasMore = value.1
        self.page += 1
        self.table.reloadData()
        self.emptyStack.isHidden = !self.items.isEmpty
        if self.items.isEmpty {
          self.showEmpty(title: "暂无动态", detail: "关注 UP 主后，这里会显示最新动态。",
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
    table.reloadData()
    emptyStack.isHidden = true
    load(reset: true)
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return items.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: DynamicCardCell.reuseID, for: indexPath) as! DynamicCardCell
    let item = items[indexPath.row]
    cell.configure(item)
    cell.onVideo = { [weak self] video in
      self?.onOpenVideo?(video)
    }
    return cell
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    guard scrollView.contentSize.height > 0 else { return }
    if scrollView.contentOffset.y > scrollView.contentSize.height - scrollView.bounds.height * 2 {
      load(reset: false)
    }
  }
}

final class DynamicCardCell: UITableViewCell {
  static let reuseID = "DynamicCardCell"

  var onVideo: ((VideoItem) -> Void)?

  private let avatar = UIImageView()
  private let author = UILabel()
  private let time = UILabel()
  private let text = UILabel()
  private let media = UIStackView()
  private let foot = UIStackView()
  private let likes = UILabel()
  private let comments = UILabel()
  private let videoCard = UIControl()
  private let videoCover = UIImageView()
  private let videoTitle = UILabel()
  private let videoMeta = UILabel()
  private let separator = UIView()
  private var video: VideoItem?

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    selectionStyle = .none

    avatar.contentMode = .scaleAspectFill
    avatar.clipsToBounds = true
    avatar.layer.cornerRadius = 16
    avatar.backgroundColor = NativeTheme.tertiary.withAlphaComponent(0.2)
    avatar.widthAnchor.constraint(equalToConstant: 32).isActive = true
    avatar.heightAnchor.constraint(equalToConstant: 32).isActive = true

    author.font = UIFont.systemFont(ofSize: 12, weight: .bold)
    author.textColor = NativeTheme.foreground
    time.font = NativeTheme.bodyFont(10)
    time.textColor = NativeTheme.tertiary

    let copy = UIStackView(arrangedSubviews: [author, time])
    copy.axis = .vertical
    copy.spacing = 3
    copy.alignment = .leading

    let head = UIStackView(arrangedSubviews: [avatar, copy])
    head.axis = .horizontal
    head.alignment = .center
    head.spacing = 10

    text.font = NativeTheme.bodyFont(13.5)
    text.textColor = NativeTheme.foreground
    text.numberOfLines = 0

    media.axis = .vertical
    media.spacing = 5

    likes.font = NativeTheme.bodyFont(10)
    likes.textColor = NativeTheme.tertiary
    comments.font = NativeTheme.bodyFont(10)
    comments.textColor = NativeTheme.tertiary
    foot.axis = .horizontal
    foot.spacing = 18
    foot.addArrangedSubview(likes)
    foot.addArrangedSubview(comments)

    videoCard.backgroundColor = NativeTheme.background
    videoCard.layer.cornerRadius = 14
    videoCard.layer.cornerCurve = .continuous
    videoCard.layer.borderWidth = 1
    videoCard.layer.borderColor = NativeTheme.hairline.cgColor
    videoCard.heightAnchor.constraint(equalToConstant: 90).isActive = true
    videoCard.addTarget(self, action: #selector(videoTapped), for: .touchUpInside)

    videoCover.contentMode = .scaleAspectFill
    videoCover.clipsToBounds = true
    videoCover.layer.cornerRadius = 10
    videoCover.layer.cornerCurve = .continuous
    videoCover.backgroundColor = NativeTheme.tertiary.withAlphaComponent(0.15)
    videoCover.isUserInteractionEnabled = false
    videoCard.addSubview(videoCover)

    videoTitle.font = UIFont.systemFont(ofSize: 12.5, weight: .semibold)
    videoTitle.textColor = NativeTheme.foreground
    videoTitle.numberOfLines = 2
    videoTitle.isUserInteractionEnabled = false
    videoCard.addSubview(videoTitle)

    videoMeta.font = NativeTheme.bodyFont(10.5)
    videoMeta.textColor = NativeTheme.secondary
    videoMeta.numberOfLines = 1
    videoMeta.isUserInteractionEnabled = false
    videoCard.addSubview(videoMeta)

    [videoCover, videoTitle, videoMeta].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
    NSLayoutConstraint.activate([
      videoCover.leadingAnchor.constraint(equalTo: videoCard.leadingAnchor, constant: 8),
      videoCover.centerYAnchor.constraint(equalTo: videoCard.centerYAnchor),
      videoCover.widthAnchor.constraint(equalToConstant: 132),
      videoCover.heightAnchor.constraint(equalToConstant: 74),
      videoTitle.leadingAnchor.constraint(equalTo: videoCover.trailingAnchor, constant: 12),
      videoTitle.trailingAnchor.constraint(equalTo: videoCard.trailingAnchor, constant: -10),
      videoTitle.topAnchor.constraint(equalTo: videoCard.topAnchor, constant: 14),
      videoMeta.leadingAnchor.constraint(equalTo: videoTitle.leadingAnchor),
      videoMeta.trailingAnchor.constraint(equalTo: videoTitle.trailingAnchor),
      videoMeta.topAnchor.constraint(equalTo: videoTitle.bottomAnchor, constant: 5),
    ])

    let stack = UIStackView(arrangedSubviews: [head, text, media, videoCard, foot])
    stack.axis = .vertical
    stack.spacing = 12
    stack.alignment = .fill
    contentView.addSubview(stack)
    stack.translatesAutoresizingMaskIntoConstraints = false

    separator.backgroundColor = NativeTheme.hairline
    contentView.addSubview(separator)
    separator.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18),
      stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -18),
      stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 18),
      stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -18),

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
    video = nil
    onVideo = nil
    avatar.image = nil
    media.arrangedSubviews.forEach { $0.removeFromSuperview() }
  }

  func configure(_ item: DynamicItem) {
    author.text = item.author
    time.text = NativeTheme.timeAgo(item.time)
    if item.text.isEmpty {
      text.isHidden = true
    } else {
      text.isHidden = false
      let paragraph = NSMutableParagraphStyle()
      paragraph.minimumLineHeight = 22.3
      paragraph.maximumLineHeight = 22.3
      text.attributedText = NSAttributedString(
        string: item.text,
        attributes: [
          .font: NativeTheme.bodyFont(13.5),
          .foregroundColor: NativeTheme.foreground,
          .paragraphStyle: paragraph,
        ])
    }
    ImageLoader.shared.load(item.avatar, into: avatar, placeholder: nil)

    media.arrangedSubviews.forEach { $0.removeFromSuperview() }
    if !item.images.isEmpty {
      media.isHidden = false
      var index = 0
      while index < item.images.count {
        let row = UIStackView()
        row.axis = .horizontal
        row.distribution = .fillEqually
        row.spacing = 5
        for column in 0..<3 {
          if index + column < item.images.count {
            let image = UIImageView()
            image.contentMode = .scaleAspectFill
            image.clipsToBounds = true
            image.layer.cornerRadius = 10
            image.layer.cornerCurve = .continuous
            image.backgroundColor = NativeTheme.tertiary.withAlphaComponent(0.15)
            ImageLoader.shared.load(item.images[index + column], into: image, placeholder: nil)
            image.heightAnchor.constraint(equalTo: image.widthAnchor).isActive = true
            row.addArrangedSubview(image)
          } else {
            let spacer = UIView()
            row.addArrangedSubview(spacer)
          }
        }
        index += 3
        media.addArrangedSubview(row)
      }
    } else {
      media.isHidden = true
    }

    video = item.video
    if let video = item.video {
      videoCard.isHidden = false
      videoCover.image = nil
      ImageLoader.shared.load(video.pic, into: videoCover, placeholder: nil)
      videoTitle.text = video.title
      videoMeta.text = video.meta
    } else {
      videoCard.isHidden = true
    }

    likes.text = "赞 \(item.likes)"
    comments.text = "评论 \(item.comments)"
    foot.isHidden = false
    separator.backgroundColor = NativeTheme.hairline
    videoCard.layer.borderColor = NativeTheme.hairline.cgColor
  }

  @objc private func videoTapped() {
    guard let video = video else { return }
    onVideo?(video)
  }
}
