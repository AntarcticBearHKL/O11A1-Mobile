import UIKit

/// Flat, minimal folder picker used when a video is favorited for the first
/// time. It intentionally avoids the glass/shadow language of the main sheets
/// so it reads as a quick utility drawer.
final class FavoriteFolderSheetViewController: UIViewController,
  UIGestureRecognizerDelegate {
  var onSelect: ((FavoriteFolder) -> Void)?
  var onClose: (() -> Void)?

  private let scrim = UIView()
  private let card = UIView()
  private let titleLabel = UILabel()
  private let closeButton = UIButton(type: .system)
  private let scroll = UIScrollView()
  private let body = UIStackView()
  private let status = UILabel()
  private let createWrap = UIView()
  private let nameField = UITextField()
  private let createButton = UIButton(type: .system)
  private var scrollHeight: NSLayoutConstraint?
  private var createHeight: NSLayoutConstraint?
  private var folders: [FavoriteFolder] = []
  private var loading = false
  private var creating = false
  private var closePan: UIPanGestureRecognizer?

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear

    scrim.backgroundColor = UIColor.black.withAlphaComponent(0.36)
    scrim.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(closeTapped)))
    view.addSubview(scrim)
    scrim.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      scrim.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrim.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrim.topAnchor.constraint(equalTo: view.topAnchor),
      scrim.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    card.backgroundColor = NativeTheme.background
    card.layer.cornerRadius = 16
    card.layer.cornerCurve = .continuous
    card.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    card.layer.borderWidth = 0.5
    card.layer.borderColor = NativeTheme.hairline.cgColor
    card.clipsToBounds = true
    view.addSubview(card)
    card.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      card.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor),
      card.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor),
      card.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      card.widthAnchor.constraint(lessThanOrEqualToConstant: 520),
      card.widthAnchor.constraint(equalTo: view.widthAnchor).withPriority(999),
      card.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      card.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor,
                                constant: 40),
    ])

    titleLabel.text = "收藏到"
    titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .bold)
    titleLabel.textColor = NativeTheme.foreground
    card.addSubview(titleLabel)
    titleLabel.translatesAutoresizingMaskIntoConstraints = false

    closeButton.setTitle("取消", for: .normal)
    closeButton.setTitleColor(NativeTheme.secondary, for: .normal)
    closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .medium)
    closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
    card.addSubview(closeButton)
    closeButton.translatesAutoresizingMaskIntoConstraints = false

    status.font = UIFont.systemFont(ofSize: 12, weight: .regular)
    status.textColor = NativeTheme.tertiary
    status.numberOfLines = 0
    status.text = "正在加载收藏夹…"
    card.addSubview(status)
    status.translatesAutoresizingMaskIntoConstraints = false

    scroll.showsVerticalScrollIndicator = false
    card.addSubview(scroll)
    scroll.translatesAutoresizingMaskIntoConstraints = false

    body.axis = .vertical
    body.spacing = 0
    body.alignment = .fill
    scroll.addSubview(body)
    body.translatesAutoresizingMaskIntoConstraints = false

    createWrap.isHidden = true
    createWrap.backgroundColor = NativeTheme.surface
    card.addSubview(createWrap)
    createWrap.translatesAutoresizingMaskIntoConstraints = false

    nameField.placeholder = "新建收藏夹名称"
    nameField.font = UIFont.systemFont(ofSize: 14, weight: .regular)
    nameField.textColor = NativeTheme.foreground
    nameField.backgroundColor = NativeTheme.background
    nameField.layer.cornerRadius = 8
    nameField.layer.cornerCurve = .continuous
    nameField.layer.borderWidth = 0.5
    nameField.layer.borderColor = NativeTheme.hairline.cgColor
    nameField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
    nameField.leftViewMode = .always
    nameField.returnKeyType = .done
    createWrap.addSubview(nameField)
    nameField.translatesAutoresizingMaskIntoConstraints = false

    createButton.setTitle("创建", for: .normal)
    createButton.setTitleColor(NativeTheme.navBlue, for: .normal)
    createButton.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
    createButton.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
    createWrap.addSubview(createButton)
    createButton.translatesAutoresizingMaskIntoConstraints = false

    scrollHeight = scroll.heightAnchor.constraint(equalToConstant: 120)
    createHeight = createWrap.heightAnchor.constraint(equalToConstant: 0)
    NSLayoutConstraint.activate([
      titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
      titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),

      closeButton.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
      closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
      closeButton.widthAnchor.constraint(equalToConstant: 48),
      closeButton.heightAnchor.constraint(equalToConstant: 30),

      status.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
      status.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
      status.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 14),

      scroll.leadingAnchor.constraint(equalTo: card.leadingAnchor),
      scroll.trailingAnchor.constraint(equalTo: card.trailingAnchor),
      scroll.topAnchor.constraint(equalTo: status.bottomAnchor, constant: 10),
      scrollHeight!,

      body.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor,
                                    constant: 20),
      body.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor,
                                     constant: -20),
      body.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
      body.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
      body.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -40),

      createWrap.leadingAnchor.constraint(equalTo: card.leadingAnchor),
      createWrap.trailingAnchor.constraint(equalTo: card.trailingAnchor),
      createWrap.topAnchor.constraint(equalTo: scroll.bottomAnchor),
      createWrap.bottomAnchor.constraint(equalTo: card.safeAreaLayoutGuide.bottomAnchor),
      createHeight!,

      nameField.leadingAnchor.constraint(equalTo: createWrap.leadingAnchor, constant: 20),
      nameField.centerYAnchor.constraint(equalTo: createWrap.centerYAnchor),
      nameField.heightAnchor.constraint(equalToConstant: 40),
      nameField.trailingAnchor.constraint(equalTo: createButton.leadingAnchor, constant: -10),

      createButton.trailingAnchor.constraint(equalTo: createWrap.trailingAnchor, constant: -20),
      createButton.centerYAnchor.constraint(equalTo: createWrap.centerYAnchor),
      createButton.widthAnchor.constraint(equalToConstant: 44),
      createButton.heightAnchor.constraint(equalToConstant: 40),
    ])

    let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
    pan.delegate = self
    card.addGestureRecognizer(pan)
    closePan = pan

    loadFolders()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    card.transform = CGAffineTransform(translationX: 0, y: 700)
    scrim.alpha = 0
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    UIView.animate(withDuration: 0.28, delay: 0,
                   options: [.curveEaseOut]) {
      self.card.transform = .identity
      self.scrim.alpha = 1
    }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    let width = max(1, card.bounds.width - 40)
    let fitting = body.systemLayoutSizeFitting(
      CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
      withHorizontalFittingPriority: .required,
      verticalFittingPriority: .fittingSizeLevel)
    let maxBody = view.bounds.height * 0.52
    scrollHeight?.constant = min(max(fitting.height, 44), maxBody)
  }

  private func loadFolders() {
    guard !loading else { return }
    loading = true
    BiliAPI.shared.favoriteFolders { [weak self] result in
      guard let self = self else { return }
      self.loading = false
      switch result {
      case .failure(let error):
        self.status.text = error.localizedDescription
      case .success(let folders):
        self.folders = folders
        self.rebuild()
      }
    }
  }

  private func rebuild() {
    body.arrangedSubviews.forEach { $0.removeFromSuperview() }
    status.isHidden = true
    if folders.isEmpty {
      let label = UILabel()
      label.text = "还没有收藏夹，新建一个吧"
      label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
      label.textColor = NativeTheme.tertiary
      label.textAlignment = .center
      label.heightAnchor.constraint(equalToConstant: 56).isActive = true
      body.addArrangedSubview(label)
    } else {
      for folder in folders {
        body.addArrangedSubview(folderRow(folder))
      }
    }
    body.addArrangedSubview(separator())
    body.addArrangedSubview(newFolderRow())
  }

  private func folderRow(_ folder: FavoriteFolder) -> UIView {
    let row = UIButton(type: .custom)
    row.heightAnchor.constraint(equalToConstant: 52).isActive = true
    let title = UILabel()
    title.text = folder.title
    title.font = UIFont.systemFont(ofSize: 14, weight: .medium)
    title.textColor = NativeTheme.foreground
    title.isUserInteractionEnabled = false
    row.addSubview(title)
    title.translatesAutoresizingMaskIntoConstraints = false
    let count = UILabel()
    count.text = "\(folder.count) 个内容"
    count.font = UIFont.systemFont(ofSize: 11.5, weight: .regular)
    count.textColor = NativeTheme.tertiary
    count.isUserInteractionEnabled = false
    row.addSubview(count)
    count.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      title.leadingAnchor.constraint(equalTo: row.leadingAnchor),
      title.centerYAnchor.constraint(equalTo: row.centerYAnchor),
      title.trailingAnchor.constraint(lessThanOrEqualTo: count.leadingAnchor, constant: -10),
      count.trailingAnchor.constraint(equalTo: row.trailingAnchor),
      count.centerYAnchor.constraint(equalTo: row.centerYAnchor),
    ])
    row.addAction(UIAction { [weak self] _ in
      self?.select(folder)
    }, for: .touchUpInside)
    let wrap = UIView()
    wrap.addSubview(row)
    row.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      row.leadingAnchor.constraint(equalTo: wrap.leadingAnchor),
      row.trailingAnchor.constraint(equalTo: wrap.trailingAnchor),
      row.topAnchor.constraint(equalTo: wrap.topAnchor),
      row.bottomAnchor.constraint(equalTo: wrap.bottomAnchor),
    ])
    let line = separator()
    let stack = UIStackView(arrangedSubviews: [wrap, line])
    stack.axis = .vertical
    stack.spacing = 0
    return stack
  }

  private func newFolderRow() -> UIView {
    let row = UIButton(type: .custom)
    row.heightAnchor.constraint(equalToConstant: 52).isActive = true
    let icon = UIImageView(image: UIImage(
      systemName: "plus",
      withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)))
    icon.tintColor = NativeTheme.navBlue
    icon.isUserInteractionEnabled = false
    row.addSubview(icon)
    icon.translatesAutoresizingMaskIntoConstraints = false
    let label = UILabel()
    label.text = "新建收藏夹"
    label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
    label.textColor = NativeTheme.navBlue
    label.isUserInteractionEnabled = false
    row.addSubview(label)
    label.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      icon.leadingAnchor.constraint(equalTo: row.leadingAnchor),
      icon.centerYAnchor.constraint(equalTo: row.centerYAnchor),
      icon.widthAnchor.constraint(equalToConstant: 18),
      label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 8),
      label.centerYAnchor.constraint(equalTo: row.centerYAnchor),
    ])
    row.addAction(UIAction { [weak self] _ in
      self?.showCreate()
    }, for: .touchUpInside)
    return row
  }

  private func separator() -> UIView {
    let line = UIView()
    line.backgroundColor = NativeTheme.hairline
    line.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
    return line
  }

  private func showCreate() {
    createWrap.isHidden = false
    createHeight?.constant = 68
    nameField.becomeFirstResponder()
    UIView.animate(withDuration: 0.18) {
      self.view.layoutIfNeeded()
    }
  }

  private func select(_ folder: FavoriteFolder) {
    onSelect?(folder)
    closeTapped()
  }

  @objc private func createTapped() {
    guard !creating else { return }
    let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    guard !name.isEmpty else {
      nameField.becomeFirstResponder()
      return
    }
    creating = true
    createButton.isEnabled = false
    BiliAPI.shared.createFavoriteFolder(title: name) { [weak self] result in
      guard let self = self else { return }
      self.creating = false
      self.createButton.isEnabled = true
      switch result {
      case .failure(let error):
        self.status.text = error.localizedDescription
        self.status.isHidden = false
      case .success(let folder):
        self.nameField.text = ""
        self.folders.append(folder)
        self.rebuild()
        self.select(folder)
      }
    }
  }

  @objc private func closeTapped() {
    onClose?()
    guard let pan = closePan else {
      dismiss(animated: true)
      return
    }
    pan.isEnabled = false
    UIView.animate(withDuration: 0.22, delay: 0,
                   options: [.curveEaseIn]) {
      self.card.transform = CGAffineTransform(
        translationX: 0, y: max(300, self.card.bounds.height))
      self.scrim.alpha = 0
    } completion: { _ in
      self.dismiss(animated: false)
    }
  }

  @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
    let translation = max(0, gesture.translation(in: view).y)
    switch gesture.state {
    case .changed:
      card.transform = CGAffineTransform(translationX: 0, y: translation)
      scrim.alpha = 1 - min(0.7, translation / max(1, view.bounds.height))
    case .ended, .cancelled:
      if translation > 90 || gesture.velocity(in: view).y > 600 {
        closeTapped()
      } else {
        UIView.animate(withDuration: 0.2) {
          self.card.transform = .identity
          self.scrim.alpha = 1
        }
      }
    default:
      break
    }
  }

  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    guard let pan = gestureRecognizer as? UIPanGestureRecognizer,
          pan === closePan else { return true }
    let velocity = pan.velocity(in: view)
    return velocity.y > abs(velocity.x)
  }
}
