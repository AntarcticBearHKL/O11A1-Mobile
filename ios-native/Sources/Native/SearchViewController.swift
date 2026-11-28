import UIKit

final class SearchViewController: UIViewController, UITextFieldDelegate,
  UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate {

  var onClose: (() -> Void)?
  var onOpenVideo: ((VideoItem) -> Void)?
  var onOpenUser: ((Int64) -> Void)?
  var onOpenSeason: ((Int64, String) -> Void)?
  var onInteractiveClose: ((CGFloat, CGFloat) -> Void)?
  var onCloseSettled: ((Bool, CGFloat) -> Void)?

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
  private var items: [SearchEntry] = []
  private var hot: [String] = []
  private var suggestions: [String] = []
  private var mode: Mode = .hot
  private var workItem: DispatchWorkItem?
  private var loading = false
  private var requestToken = 0
  private var page = 1
  private var hasMore = true
  private var term = ""
  private var searchType: SearchType = .all
  private var dismissPan: UIPanGestureRecognizer?
  private var typePan: UIPanGestureRecognizer?
  private var dismissStartX: CGFloat = 0
  private var typeStartX: CGFloat = 0
  private var dismissDirection: CGFloat = 1
  private let typeDock = UIView()
  private let typeBlur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
  private var typeButtons: [UIButton] = []


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
    table.register(SearchEntityCell.self, forCellReuseIdentifier: SearchEntityCell.reuseID)
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

    typeDock.backgroundColor = .clear
    typeDock.layer.cornerRadius = NativeTheme.cornerRadius
    typeDock.layer.cornerCurve = .continuous
    typeDock.layer.borderWidth = 1
    typeDock.layer.borderColor = NativeTheme.hairline.cgColor
    typeDock.layer.shadowColor = UIColor.black.cgColor
    typeDock.layer.shadowOpacity = 0.18
    typeDock.layer.shadowRadius = 17
    typeDock.layer.shadowOffset = CGSize(width: 0, height: 7)
    typeDock.clipsToBounds = false
    typeBlur.layer.cornerRadius = NativeTheme.cornerRadius
    typeBlur.layer.cornerCurve = .continuous
    typeBlur.clipsToBounds = true
    typeBlur.isUserInteractionEnabled = false
    typeBlur.contentView.backgroundColor = NativeTheme.glassWhite
    typeDock.addSubview(typeBlur)
    typeBlur.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      typeBlur.leadingAnchor.constraint(equalTo: typeDock.leadingAnchor),
      typeBlur.trailingAnchor.constraint(equalTo: typeDock.trailingAnchor),
      typeBlur.topAnchor.constraint(equalTo: typeDock.topAnchor),
      typeBlur.bottomAnchor.constraint(equalTo: typeDock.bottomAnchor),
    ])
    let typeStack = UIStackView()
    typeStack.axis = .horizontal
    typeStack.distribution = .fillEqually
    typeStack.spacing = 3
    typeStack.isLayoutMarginsRelativeArrangement = true
    typeStack.layoutMargins = UIEdgeInsets(top: 7, left: 5, bottom: 7, right: 5)
    for (index, type) in SearchType.allCases.enumerated() {
      let button = UIButton(type: .custom)
      button.tag = index
      button.setTitle(type.title, for: .normal)
      button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
      button.layer.cornerRadius = NativeTheme.cornerRadius
      button.layer.cornerCurve = .continuous
      button.addTarget(self, action: #selector(typeTapped(_:)), for: .touchUpInside)
      typeButtons.append(button)
      typeStack.addArrangedSubview(button)
    }
    typeDock.addSubview(typeStack)
    typeStack.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      typeStack.leadingAnchor.constraint(equalTo: typeDock.leadingAnchor),
      typeStack.trailingAnchor.constraint(equalTo: typeDock.trailingAnchor),
      typeStack.topAnchor.constraint(equalTo: typeDock.topAnchor),
      typeStack.bottomAnchor.constraint(equalTo: typeDock.bottomAnchor),
    ])
    view.addSubview(typeDock)
    typeDock.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      typeDock.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      typeDock.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                                       constant: -28),
      typeDock.widthAnchor.constraint(equalToConstant: 304),
      typeDock.heightAnchor.constraint(equalToConstant: 66),
    ])
    updateTypeDock()

    let pan = UIPanGestureRecognizer(target: self, action: #selector(handleDismissPan(_:)))
    pan.delegate = self
    table.panGestureRecognizer.require(toFail: pan)
    view.addGestureRecognizer(pan)
    dismissPan = pan

    let typeSwipe = UIPanGestureRecognizer(target: self, action: #selector(handleTypeSwipe(_:)))
    typeSwipe.delegate = self
    typeSwipe.cancelsTouchesInView = true
    table.panGestureRecognizer.require(toFail: typeSwipe)
    view.addGestureRecognizer(typeSwipe)
    typePan = typeSwipe

    loadHot()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    headMask.frame = head.bounds
    typeDock.layer.shadowPath = UIBezierPath(
      roundedRect: typeDock.bounds,
      cornerRadius: NativeTheme.cornerRadius).cgPath
    CATransaction.commit()
    updateTableInsets()
    fieldWrap.layer.borderColor = fieldWrap.layer.borderWidth > 1
      ? NativeTheme.navBlue.withAlphaComponent(0.5).cgColor
      : NativeTheme.hairline.cgColor
  }

  override func viewSafeAreaInsetsDidChange() {
    super.viewSafeAreaInsetsDidChange()
    updateTableInsets()
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    fieldWrap.layer.borderColor = NativeTheme.hairline.cgColor
    fieldWrap.backgroundColor = .clear
    updateTypeDock()
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

  func testSearch(_ term: String) {
    field.text = term
    performSearch(term)
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
    page = 1
    hasMore = true
    term = ""
    searchType = .all
    updateTypeDock()
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
      updateTypeDock()
      return
    }
    mode = .suggest
    table.reloadData()
    statusLabel.isHidden = true
    table.contentInset.top = 0
    updateTypeDock()
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
    view.endEditing(true)
    self.term = term
    page = 1
    hasMore = true
    mode = .results
    items = []
    table.reloadData()
    table.contentInset.top = 0
    updateTypeDock()
    loadResults(reset: true)
  }

  private func loadResults(reset: Bool) {
    guard !loading else { return }
    guard !term.isEmpty else { return }
    if !reset && !hasMore { return }
    requestToken += 1
    let token = requestToken
    if reset {
      page = 1
      items = []
      table.reloadData()
      statusLabel.text = "搜索中…"
      statusLabel.isHidden = false
    }
    loading = true
    let requestedPage = page
    BiliAPI.shared.searchEntries(term, page: requestedPage, type: searchType) {
      [weak self] result in
      guard let self = self, token == self.requestToken else { return }
      self.loading = false
      switch result {
      case .failure(let error):
        if self.items.isEmpty {
          self.statusLabel.text = error.localizedDescription
          self.statusLabel.isHidden = false
        }
      case .success(let entries):
        self.hasMore = entries.count >= 20
        self.page = requestedPage + 1
        if reset {
          self.items = entries
          self.table.reloadData()
        } else {
          let start = self.items.count
          self.items.append(contentsOf: entries)
          let paths = (start..<self.items.count).map {
            IndexPath(row: $0, section: 0)
          }
          if !paths.isEmpty {
            UIView.performWithoutAnimation {
              self.table.insertRows(at: paths, with: .none)
            }
          }
        }
        if self.items.isEmpty {
          self.statusLabel.text = self.searchType == .all
            ? "没有找到视频 · 换个关键词试试" : "没有找到结果"
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

  private func updateTypeDock() {
    typeDock.isHidden = mode != .results
    typeDock.layer.borderColor = NativeTheme.hairline.cgColor
    for (index, button) in typeButtons.enumerated() {
      let on = index < SearchType.allCases.count
        && SearchType.allCases[index] == searchType
      button.backgroundColor = on ? NativeTheme.foreground : .clear
      button.setTitleColor(on ? NativeTheme.background : NativeTheme.secondary,
                           for: .normal)
      button.layer.borderWidth = 0
    }
    updateTableInsets()
  }

  private func updateTableInsets() {
    let bottom: CGFloat = mode == .results ? 100 : 24
    table.contentInset = UIEdgeInsets(
      top: mode == .hot ? 8 : 0, left: 0,
      bottom: bottom + view.safeAreaInsets.bottom, right: 0)
  }

  @objc private func typeTapped(_ sender: UIButton) {
    let all = SearchType.allCases
    guard all.indices.contains(sender.tag) else { return }
    setSearchType(all[sender.tag])
  }

  private func setSearchType(_ type: SearchType) {
    guard type != searchType else { return }
    searchType = type
    updateTypeDock()
    if !term.isEmpty, mode == .results {
      loadResults(reset: true)
    }
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
  }

  @objc private func handleTypeSwipe(_ gesture: UIPanGestureRecognizer) {
    guard gesture.state == .ended || gesture.state == .cancelled else { return }
    let translation = gesture.translation(in: view).x
    let velocity = gesture.velocity(in: view).x
    let horizontal = abs(translation) > abs(gesture.translation(in: view).y) * 1.4
      || abs(velocity) > abs(gesture.velocity(in: view).y) * 1.5
    guard horizontal,
          abs(translation) > 48 || abs(velocity) > 380 else { return }
    let all = SearchType.allCases
    guard let index = all.firstIndex(of: searchType) else { return }
    let next = translation < 0 ? index + 1 : index - 1
    guard all.indices.contains(next) else { return }
    setSearchType(all[next])
  }

  @objc private func handleDismissPan(_ gesture: UIPanGestureRecognizer) {
    let reference = view.superview ?? view
    let width = max(1, view.bounds.width)
    let distance = dismissDirection > 0
      ? max(0, gesture.translation(in: reference).x)
      : max(0, -gesture.translation(in: reference).x)
    switch gesture.state {
    case .began:
      view.endEditing(true)
    case .changed:
      // Follow the finger: a right swipe from the left edge leaves to the
      // right, a left swipe from the right edge leaves to the left. The page
      // must never reverse direction when the finger is released.
      onInteractiveClose?(max(0, min(1, 1 - distance / width)), dismissDirection)
    case .ended, .cancelled:
      let velocity = gesture.velocity(in: view).x * dismissDirection
      let shouldClose = distance > width * 0.24 || velocity > 350
      if shouldClose { view.endEditing(true) }
      onCloseSettled?(shouldClose, dismissDirection)
    default:
      break
    }
  }

  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    guard let pan = gestureRecognizer as? UIPanGestureRecognizer,
          pan === dismissPan || pan === typePan else {
      return true
    }
    let width = max(1, view.bounds.width)
    let velocity = pan.velocity(in: view)
    let translation = pan.translation(in: view)
    let horizontal = abs(translation.x) > abs(translation.y) * 1.1
      || abs(velocity.x) > abs(velocity.y) * 1.1
    guard horizontal else { return false }
    if pan === dismissPan {
      if dismissStartX < width / 6.0 {
        dismissDirection = 1
        return translation.x > 1 || velocity.x > 1
      }
      if dismissStartX > width * 5.0 / 6.0 {
        dismissDirection = -1
        return translation.x < -1 || velocity.x < -1
      }
      return false
    }
    guard mode == .results else { return false }
    return typeStartX >= width / 6.0 && typeStartX <= width * 5.0 / 6.0
  }

  func gestureRecognizer(
    _ gestureRecognizer: UIGestureRecognizer,
    shouldReceive touch: UITouch
  ) -> Bool {
    if touch.view?.isDescendant(of: typeDock) == true { return false }
    if gestureRecognizer === dismissPan {
      dismissStartX = touch.location(in: view).x
    }
    if gestureRecognizer === typePan {
      typeStartX = touch.location(in: view).x
    }
    return true
  }

  func gestureRecognizer(
    _ gestureRecognizer: UIGestureRecognizer,
    shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
  ) -> Bool {
    return gestureRecognizer === dismissPan || other === dismissPan
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    guard mode == .results, !loading, hasMore else { return }
    if scrollView.contentOffset.y > scrollView.contentSize.height
        - scrollView.bounds.height * 2 {
      loadResults(reset: false)
    }
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
      guard items.indices.contains(indexPath.row) else {
        return UITableViewCell()
      }
      switch items[indexPath.row] {
      case .video(let item):
        let cell = tableView.dequeueReusableCell(
          withIdentifier: VideoRowCell.reuseID, for: indexPath) as! VideoRowCell
        cell.configureSearch(item)
        return cell
      case .user(let user):
        let cell = tableView.dequeueReusableCell(
          withIdentifier: SearchEntityCell.reuseID, for: indexPath) as! SearchEntityCell
        cell.configure(title: user.name, subtitle: user.fans, image: user.face)
        return cell
      case .bangumi(let bangumi):
        let cell = tableView.dequeueReusableCell(
          withIdentifier: SearchEntityCell.reuseID, for: indexPath) as! SearchEntityCell
        cell.configure(title: bangumi.title,
                       subtitle: bangumi.subtitle, image: bangumi.cover)
        return cell
      }
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
      switch items[indexPath.row] {
      case .video(let item):
        onOpenVideo?(item)
      case .user(let user):
        onOpenUser?(user.mid)
      case .bangumi(let bangumi):
        onOpenSeason?(bangumi.seasonId, bangumi.title)
      }
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

final class SearchEntityCell: UITableViewCell {
  static let reuseID = "SearchEntityCell"
  private let cover = UIImageView()
  private let title = UILabel()
  private let subtitle = UILabel()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    backgroundColor = .clear
    selectionStyle = .default
    let selected = UIView()
    selected.backgroundColor = NativeTheme.foreground.withAlphaComponent(0.04)
    selectedBackgroundView = selected

    cover.contentMode = .scaleAspectFill
    cover.clipsToBounds = true
    cover.layer.cornerRadius = 10
    cover.layer.cornerCurve = .continuous
    cover.backgroundColor = NativeTheme.surface
    contentView.addSubview(cover)
    cover.translatesAutoresizingMaskIntoConstraints = false

    title.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
    title.textColor = NativeTheme.foreground
    title.numberOfLines = 2
    contentView.addSubview(title)
    title.translatesAutoresizingMaskIntoConstraints = false

    subtitle.font = UIFont.systemFont(ofSize: 12, weight: .regular)
    subtitle.textColor = NativeTheme.secondary
    subtitle.numberOfLines = 1
    contentView.addSubview(subtitle)
    subtitle.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      cover.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18),
      cover.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
      cover.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
      cover.widthAnchor.constraint(equalToConstant: 64),
      cover.heightAnchor.constraint(equalToConstant: 64),

      title.leadingAnchor.constraint(equalTo: cover.trailingAnchor, constant: 12),
      title.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
      title.topAnchor.constraint(equalTo: cover.topAnchor, constant: 3),

      subtitle.leadingAnchor.constraint(equalTo: title.leadingAnchor),
      subtitle.trailingAnchor.constraint(equalTo: title.trailingAnchor),
      subtitle.bottomAnchor.constraint(equalTo: cover.bottomAnchor, constant: -2),
    ])
    contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 84).isActive = true
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(title: String, subtitle: String, image: String) {
    self.title.text = title
    self.subtitle.text = subtitle
    ImageLoader.shared.load(image, into: cover)
  }
}
