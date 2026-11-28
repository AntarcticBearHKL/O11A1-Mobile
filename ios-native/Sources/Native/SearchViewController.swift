import UIKit

final class SearchViewController: UIViewController, UITextFieldDelegate,
  UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate {

  var onClose: (() -> Void)?
  var onOpenVideo: ((VideoItem) -> Void)?
  var onInteractiveClose: ((CGFloat) -> Void)?
  var onCloseSettled: ((Bool) -> Void)?

  private enum Mode {
    case hot
    case suggest
    case results
  }

  private let head = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
  private let headMask = CAGradientLayer()
  private let fieldWrap = UIView()
  private let fieldBlur = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
  private let field = UITextField()
  private let table = UITableView(frame: .zero, style: .plain)
  private let statusLabel = UILabel()
  private var items: [VideoItem] = []
  private var hot: [String] = []
  private var suggestions: [String] = []
  private var mode: Mode = .hot
  private var workItem: DispatchWorkItem?
  private var loading = false
  private var requestToken = 0
  private var dismissPan: UIPanGestureRecognizer?


  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = NativeTheme.background

    let blur = head
    blur.clipsToBounds = true
    view.addSubview(blur)
    blur.translatesAutoresizingMaskIntoConstraints = false
    headMask.colors = [UIColor.black.cgColor,
                       UIColor.black.cgColor,
                       UIColor.clear.cgColor]
    headMask.locations = [0, 0.5, 0.82]
    blur.layer.mask = headMask

    fieldWrap.backgroundColor = .clear
    fieldWrap.layer.cornerRadius = NativeTheme.cornerRadius
    fieldWrap.layer.cornerCurve = .continuous
    fieldWrap.layer.borderWidth = 1
    fieldWrap.layer.borderColor = NativeTheme.hairline.cgColor
    view.addSubview(fieldWrap)
    fieldWrap.translatesAutoresizingMaskIntoConstraints = false

    fieldBlur.layer.cornerRadius = NativeTheme.cornerRadius
    fieldBlur.layer.cornerCurve = .continuous
    fieldBlur.clipsToBounds = true
    fieldBlur.isUserInteractionEnabled = false
    fieldWrap.addSubview(fieldBlur)
    fieldBlur.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      fieldBlur.leadingAnchor.constraint(equalTo: fieldWrap.leadingAnchor),
      fieldBlur.trailingAnchor.constraint(equalTo: fieldWrap.trailingAnchor),
      fieldBlur.topAnchor.constraint(equalTo: fieldWrap.topAnchor),
      fieldBlur.bottomAnchor.constraint(equalTo: fieldWrap.bottomAnchor),
    ])

    let iconWrap = UIView(frame: CGRect(x: 0, y: 0, width: 38, height: 24))
    let icon = UIImageView(image: UIImage(
      systemName: "magnifyingglass",
      withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .regular)))
    icon.tintColor = NativeTheme.tertiary
    icon.contentMode = .scaleAspectFit
    icon.frame = CGRect(x: 4, y: 1, width: 22, height: 22)
    iconWrap.addSubview(icon)

    field.leftView = iconWrap
    field.leftViewMode = .always
    field.font = NativeTheme.bodyFont(13)
    field.textColor = NativeTheme.foreground
    field.tintColor = NativeTheme.navBlue
    field.attributedPlaceholder = NSAttributedString(
      string: "搜索视频 / UP / 番剧",
      attributes: [.foregroundColor: NativeTheme.tertiary,
                   .font: NativeTheme.bodyFont(13)])
    field.returnKeyType = .search
    field.clearButtonMode = .whileEditing
    field.autocorrectionType = .no
    field.delegate = self
    field.addTarget(self, action: #selector(textChanged), for: .editingChanged)
    fieldWrap.addSubview(field)
    field.translatesAutoresizingMaskIntoConstraints = false

    table.backgroundColor = .clear
    table.separatorStyle = .none
    table.dataSource = self
    table.delegate = self
    table.keyboardDismissMode = .onDrag
    table.register(VideoRowCell.self, forCellReuseIdentifier: VideoRowCell.reuseID)
    table.register(HotWordCell.self, forCellReuseIdentifier: HotWordCell.reuseID)
    table.register(SuggestionCell.self, forCellReuseIdentifier: SuggestionCell.reuseID)
    table.rowHeight = UITableView.automaticDimension
    table.estimatedRowHeight = 108
    table.contentInsetAdjustmentBehavior = .never
    table.showsVerticalScrollIndicator = false
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
      blur.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      blur.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      blur.topAnchor.constraint(equalTo: view.topAnchor),
      blur.bottomAnchor.constraint(equalTo: fieldWrap.bottomAnchor, constant: 8),

      fieldWrap.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
      fieldWrap.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18),
      fieldWrap.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
      fieldWrap.heightAnchor.constraint(equalToConstant: 44),

      field.leadingAnchor.constraint(equalTo: fieldWrap.leadingAnchor, constant: 4),
      field.trailingAnchor.constraint(equalTo: fieldWrap.trailingAnchor, constant: -10),
      field.topAnchor.constraint(equalTo: fieldWrap.topAnchor),
      field.bottomAnchor.constraint(equalTo: fieldWrap.bottomAnchor),

      table.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      table.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      table.topAnchor.constraint(equalTo: blur.bottomAnchor),
      table.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      statusLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
      statusLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32),
    ])

    let pan = UIPanGestureRecognizer(target: self, action: #selector(handleDismissPan(_:)))
    pan.delegate = self
    table.panGestureRecognizer.require(toFail: pan)
    view.addGestureRecognizer(pan)
    dismissPan = pan

    loadHot()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    headMask.frame = head.bounds
    CATransaction.commit()
    table.contentInset = UIEdgeInsets(top: mode == .hot ? 8 : 0, left: 0,
                                      bottom: 24 + view.safeAreaInsets.bottom, right: 0)
    fieldWrap.layer.borderColor = fieldWrap.layer.borderWidth > 1
      ? NativeTheme.navBlue.withAlphaComponent(0.5).cgColor
      : NativeTheme.hairline.cgColor
  }

  override func viewSafeAreaInsetsDidChange() {
    super.viewSafeAreaInsetsDidChange()
    table.contentInset = UIEdgeInsets(top: mode == .hot ? 8 : 0, left: 0,
                                      bottom: 24 + view.safeAreaInsets.bottom, right: 0)
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    fieldWrap.layer.borderColor = NativeTheme.hairline.cgColor
    fieldWrap.backgroundColor = .clear
  }

  private func loadHot() {
    BiliAPI.shared.searchHot { [weak self] result in
      guard let self = self else { return }
      guard case .success(let values) = result else { return }
      self.hot = values
      if self.mode == .hot {
        self.table.reloadData()
        self.emptyState()
      }
    }
  }

  func focus() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
      self.field.becomeFirstResponder()
    }
  }

  /// Close-out reset: the next opening starts a fresh search flow.
  func reset() {
    requestToken += 1
    workItem?.cancel()
    workItem = nil
    loading = false
    field.text = ""
    field.resignFirstResponder()
    mode = .hot
    items = []
    suggestions = []
    table.reloadData()
    table.contentInset.top = 8
    table.layoutIfNeeded()
    table.setContentOffset(CGPoint(x: 0, y: -8), animated: false)
    statusLabel.text = nil
    emptyState()
    fieldWrap.layer.borderWidth = 1
    fieldWrap.layer.borderColor = NativeTheme.hairline.cgColor
    fieldWrap.layer.shadowOpacity = 0
    if hot.isEmpty {
      loadHot()
    }
  }

  func focusNow() {
    guard !field.isFirstResponder else { return }
    field.becomeFirstResponder()
  }

  func resignKeyboard() {
    guard field.isFirstResponder else { return }
    field.resignFirstResponder()
  }

  @objc private func textChanged() {
    requestToken += 1
    loading = false
    workItem?.cancel()
    let term = (field.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    guard !term.isEmpty else {
      mode = .hot
      items = []
      suggestions = []
      table.reloadData()
      statusLabel.isHidden = true
      table.contentInset.top = 8
      return
    }
    mode = .suggest
    table.reloadData()
    statusLabel.isHidden = true
    table.contentInset.top = 0
    let task = DispatchWorkItem { [weak self] in
      self?.loadSuggestions(term)
    }
    workItem = task
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.22, execute: task)
  }

  private func loadSuggestions(_ term: String) {
    BiliAPI.shared.suggest(term) { [weak self] values in
      guard let self = self, self.mode == .suggest else { return }
      let current = (self.field.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
      guard current == term else { return }
      self.suggestions = values
      self.table.reloadData()
    }
  }

  func textFieldDidBeginEditing(_ textField: UITextField) {
    fieldWrap.layer.borderWidth = 1.5
    fieldWrap.layer.borderColor = NativeTheme.navBlue.withAlphaComponent(0.5).cgColor
    fieldWrap.layer.shadowColor = NativeTheme.navBlue.cgColor
    fieldWrap.layer.shadowOpacity = 0.12
    fieldWrap.layer.shadowRadius = 3
    fieldWrap.layer.shadowOffset = .zero
  }

  func textFieldDidEndEditing(_ textField: UITextField) {
    fieldWrap.layer.borderWidth = 1
    fieldWrap.layer.borderColor = NativeTheme.hairline.cgColor
    fieldWrap.layer.shadowOpacity = 0
  }

  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    let term = (textField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    guard !term.isEmpty else { return false }
    performSearch(term)
    return true
  }

  private func performSearch(_ term: String) {
    guard !loading else { return }
    requestToken += 1
    let token = requestToken
    workItem?.cancel()
    mode = .results
    items = []
    table.reloadData()
    loading = true
    statusLabel.text = "搜索中…"
    statusLabel.isHidden = false
    table.contentInset.top = 0
    BiliAPI.shared.search(term, page: 1) { [weak self] result in
      guard let self = self, token == self.requestToken else { return }
      self.loading = false
      switch result {
      case .failure(let error):
        self.statusLabel.text = error.localizedDescription
        self.statusLabel.isHidden = false
      case .success(let items):
        self.items = items
        self.table.reloadData()
        if items.isEmpty {
          self.statusLabel.text = "没有找到视频 · 换个关键词试试"
          self.statusLabel.isHidden = false
        } else {
          self.statusLabel.isHidden = true
        }
      }
    }
  }

  private func emptyState() {
    if mode == .hot {
      statusLabel.text = hot.isEmpty ? "暂无热搜" : nil
      statusLabel.isHidden = !hot.isEmpty
    }
  }

  @objc private func handleDismissPan(_ gesture: UIPanGestureRecognizer) {
    let reference = view.superview ?? view
    let translation = max(0, gesture.translation(in: reference).x)
    let width = max(1, view.bounds.width)
    switch gesture.state {
    case .began:
      view.endEditing(true)
    case .changed:
      onInteractiveClose?(max(0, min(1, 1 - translation / width)))
    case .ended, .cancelled:
      let velocity = gesture.velocity(in: view).x
      let shouldClose = translation > width * 0.24 || velocity > 350
      if shouldClose { view.endEditing(true) }
      onCloseSettled?(shouldClose)
    default:
      break
    }
  }

  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    guard let pan = gestureRecognizer as? UIPanGestureRecognizer, pan === dismissPan else {
      return true
    }
    let velocity = pan.velocity(in: view)
    let translation = pan.translation(in: view)
    return abs(translation.x) > abs(translation.y) * 1.1
      || abs(velocity.x) > abs(velocity.y) * 1.1
  }

  func gestureRecognizer(
    _ gestureRecognizer: UIGestureRecognizer,
    shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
  ) -> Bool {
    return gestureRecognizer === dismissPan || other === dismissPan
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    switch mode {
    case .hot: return hot.count
    case .suggest: return suggestions.count
    case .results: return items.count
    }
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    if mode == .results { return UITableView.automaticDimension }
    return 58
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if mode == .results {
      let cell = tableView.dequeueReusableCell(
        withIdentifier: VideoRowCell.reuseID, for: indexPath) as! VideoRowCell
      cell.configureSearch(items[indexPath.row])
      return cell
    }
    if mode == .hot {
      let cell = tableView.dequeueReusableCell(
        withIdentifier: HotWordCell.reuseID, for: indexPath) as! HotWordCell
      cell.configure(hot[indexPath.row], rank: indexPath.row + 1)
      return cell
    }
    let cell = tableView.dequeueReusableCell(
      withIdentifier: SuggestionCell.reuseID, for: indexPath) as! SuggestionCell
    cell.configure(suggestions[indexPath.row])
    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    if mode == .results {
      guard items.indices.contains(indexPath.row) else { return }
      view.endEditing(true)
      onOpenVideo?(items[indexPath.row])
      return
    }
    let term = mode == .hot ? hot[indexPath.row] : suggestions[indexPath.row]
    field.text = term
    field.resignFirstResponder()
    performSearch(term)
  }
}

private final class HotWordCell: UITableViewCell {
  static let reuseID = "HotWordCell"
  private let rank = UILabel()
  private let word = UILabel()
  private let separator = UIView()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    backgroundColor = .clear
    selectionStyle = .none
    contentView.backgroundColor = .clear

    rank.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .heavy)
    rank.textColor = NativeTheme.tertiary
    rank.textAlignment = .center
    contentView.addSubview(rank)

    word.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
    word.textColor = NativeTheme.foreground
    word.numberOfLines = 1
    contentView.addSubview(word)

    separator.backgroundColor = NativeTheme.hairline
    contentView.addSubview(separator)

    [rank, word, separator].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
    NSLayoutConstraint.activate([
      rank.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
      rank.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      rank.widthAnchor.constraint(equalToConstant: 22),
      word.leadingAnchor.constraint(equalTo: rank.trailingAnchor, constant: 12),
      word.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
      word.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18),
      separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -18),
      separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      separator.heightAnchor.constraint(equalToConstant: 0.5),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(_ text: String, rank index: Int) {
    rank.text = "\(index)"
    rank.textColor = index <= 3 ? NativeTheme.navBlue : NativeTheme.tertiary
    word.text = text
    separator.backgroundColor = NativeTheme.hairline
  }
}

private final class SuggestionCell: UITableViewCell {
  static let reuseID = "SuggestionCell"
  private let icon = UIImageView()
  private let word = UILabel()
  private let separator = UIView()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    backgroundColor = .clear
    selectionStyle = .none
    contentView.backgroundColor = .clear

    icon.image = UIImage(
      systemName: "magnifyingglass",
      withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .regular))
    icon.tintColor = NativeTheme.tertiary
    icon.contentMode = .scaleAspectFit
    contentView.addSubview(icon)

    word.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
    word.textColor = NativeTheme.foreground
    word.numberOfLines = 1
    contentView.addSubview(word)

    separator.backgroundColor = NativeTheme.hairline
    contentView.addSubview(separator)

    [icon, word, separator].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
    NSLayoutConstraint.activate([
      icon.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
      icon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      icon.widthAnchor.constraint(equalToConstant: 18),
      icon.heightAnchor.constraint(equalToConstant: 18),
      word.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 12),
      word.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
      word.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18),
      separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -18),
      separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      separator.heightAnchor.constraint(equalToConstant: 0.5),
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(_ text: String) {
    word.text = text
    separator.backgroundColor = NativeTheme.hairline
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
    cover.layer.cornerRadius = NativeTheme.cornerRadius
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
    duration.layer.cornerRadius = NativeTheme.cornerRadius
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
