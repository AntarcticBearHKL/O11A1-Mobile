import UIKit

enum SettingsSheetRow {
  case value(label: String, value: String)
  case action(label: String, value: String, run: () -> Void)
  case toggle(label: String, detail: String?, isOn: Bool, onChange: (Bool) -> Void)
  case slider(label: String, min: Float, max: Float, value: Float, unit: String,
              format: ((Float) -> String)?, onChange: (Float) -> Void)
  case choices(label: String, options: [String], selected: String, onChange: (String) -> Void)
  case section(String)
  case note(String)
}

final class SettingsSheetViewController: UIViewController, UIGestureRecognizerDelegate {
  private let sheetTitle: String
  private let sheetSubtitle: String
  private let rows: [SettingsSheetRow]
  private let scrim = UIView()
  private let card = UIView()
  private let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
  private let tint = UIView()
  private let scroll = UIScrollView()
  private let body = UIStackView()
  private let closeButton = UIButton(type: .system)
  private var scrollHeight: NSLayoutConstraint?
  private var dismissPan: UIPanGestureRecognizer?
  private var closing = false

  init(title: String, subtitle: String, rows: [SettingsSheetRow]) {
    sheetTitle = title
    sheetSubtitle = subtitle
    self.rows = rows
    super.init(nibName: nil, bundle: nil)
    modalPresentationStyle = .overFullScreen
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear

    scrim.backgroundColor = UIColor.black.withAlphaComponent(0.42)
    scrim.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(close)))
    view.addSubview(scrim)
    scrim.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      scrim.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrim.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrim.topAnchor.constraint(equalTo: view.topAnchor),
      scrim.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    card.layer.cornerRadius = NativeTheme.cornerRadius
    card.layer.cornerCurve = .continuous
    card.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    card.layer.borderWidth = 1
    card.layer.borderColor = NativeTheme.barBorder.cgColor
    card.layer.shadowColor = UIColor.black.cgColor
    card.layer.shadowOpacity = 0.22
    card.layer.shadowRadius = 24
    card.layer.shadowOffset = CGSize(width: 0, height: -10)
    card.clipsToBounds = false
    view.addSubview(card)
    card.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      card.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor),
      card.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor),
      card.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      card.widthAnchor.constraint(lessThanOrEqualToConstant: 560),
      card.widthAnchor.constraint(equalTo: view.widthAnchor).withPriority(999),
      card.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      card.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor,
                                constant: 16),
    ])

    blur.layer.cornerRadius = NativeTheme.cornerRadius
    blur.layer.cornerCurve = .continuous
    blur.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    blur.clipsToBounds = true
    card.addSubview(blur)
    blur.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      blur.leadingAnchor.constraint(equalTo: card.leadingAnchor),
      blur.trailingAnchor.constraint(equalTo: card.trailingAnchor),
      blur.topAnchor.constraint(equalTo: card.topAnchor),
      blur.bottomAnchor.constraint(equalTo: card.bottomAnchor),
    ])
    tint.backgroundColor = NativeTheme.sheetGlass
    tint.layer.cornerRadius = NativeTheme.cornerRadius
    tint.layer.cornerCurve = .continuous
    tint.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    tint.clipsToBounds = true
    tint.isUserInteractionEnabled = false
    card.addSubview(tint)
    tint.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      tint.leadingAnchor.constraint(equalTo: card.leadingAnchor),
      tint.trailingAnchor.constraint(equalTo: card.trailingAnchor),
      tint.topAnchor.constraint(equalTo: card.topAnchor),
      tint.bottomAnchor.constraint(equalTo: card.bottomAnchor),
    ])

    let grab = UIView()
    grab.backgroundColor = NativeTheme.tertiary.withAlphaComponent(0.5)
    grab.layer.cornerRadius = 2
    card.addSubview(grab)
    grab.translatesAutoresizingMaskIntoConstraints = false

    let title = UILabel()
    title.text = sheetTitle
    title.font = UIFont.systemFont(ofSize: 16.5, weight: .bold)
    title.textColor = NativeTheme.foreground
    card.addSubview(title)
    title.translatesAutoresizingMaskIntoConstraints = false

    let subtitle = UILabel()
    subtitle.text = sheetSubtitle
    subtitle.font = NativeTheme.bodyFont(10.5)
    subtitle.textColor = NativeTheme.secondary
    subtitle.numberOfLines = 0
    card.addSubview(subtitle)
    subtitle.translatesAutoresizingMaskIntoConstraints = false

    scroll.alwaysBounceVertical = true
    scroll.showsVerticalScrollIndicator = false
    card.addSubview(scroll)
    scroll.translatesAutoresizingMaskIntoConstraints = false

    body.axis = .vertical
    body.spacing = 0
    body.alignment = .fill
    scroll.addSubview(body)
    body.translatesAutoresizingMaskIntoConstraints = false

    closeButton.setTitle("关闭", for: .normal)
    closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 12.5, weight: .bold)
    closeButton.setTitleColor(NativeTheme.foreground, for: .normal)
    closeButton.backgroundColor = NativeTheme.foreground.withAlphaComponent(0.06)
    closeButton.layer.cornerRadius = NativeTheme.cornerRadius
    closeButton.layer.cornerCurve = .continuous
    closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
    card.addSubview(closeButton)
    closeButton.translatesAutoresizingMaskIntoConstraints = false

    scrollHeight = scroll.heightAnchor.constraint(equalToConstant: 100)
    NSLayoutConstraint.activate([
      grab.centerXAnchor.constraint(equalTo: card.centerXAnchor),
      grab.topAnchor.constraint(equalTo: card.topAnchor, constant: 9),
      grab.widthAnchor.constraint(equalToConstant: 38),
      grab.heightAnchor.constraint(equalToConstant: 4),

      title.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
      title.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
      title.topAnchor.constraint(equalTo: grab.bottomAnchor, constant: 15),

      subtitle.leadingAnchor.constraint(equalTo: title.leadingAnchor),
      subtitle.trailingAnchor.constraint(equalTo: title.trailingAnchor),
      subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 3),

      scroll.leadingAnchor.constraint(equalTo: card.leadingAnchor),
      scroll.trailingAnchor.constraint(equalTo: card.trailingAnchor),
      scroll.topAnchor.constraint(equalTo: subtitle.bottomAnchor, constant: 12),
      scrollHeight!,

      body.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 18),
      body.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -18),
      body.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
      body.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
      body.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -36),

      closeButton.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
      closeButton.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
      closeButton.topAnchor.constraint(equalTo: scroll.bottomAnchor, constant: 12),
      closeButton.heightAnchor.constraint(equalToConstant: 44),
      closeButton.bottomAnchor.constraint(equalTo: card.safeAreaLayoutGuide.bottomAnchor,
                                           constant: -12),
    ])

    for row in rows {
      add(row)
    }

    let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
    pan.delegate = self
    card.addGestureRecognizer(pan)
    dismissPan = pan
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    card.transform = CGAffineTransform(translationX: 0, y: 900)
    scrim.alpha = 0
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    view.layoutIfNeeded()
    card.transform = CGAffineTransform(translationX: 0, y: card.bounds.height)
    scrim.alpha = 0
    UIView.animate(withDuration: 0.34, delay: 0,
                   usingSpringWithDamping: 1, initialSpringVelocity: 0,
                   options: [.curveEaseOut]) {
      self.card.transform = .identity
      self.scrim.alpha = 1
    }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    let width = max(1, card.bounds.width - 36)
    let fitting = body.systemLayoutSizeFitting(
      CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
      withHorizontalFittingPriority: .required,
      verticalFittingPriority: .fittingSizeLevel)
    let maxBody = view.bounds.height * 0.58
    scrollHeight?.constant = min(max(fitting.height, 1), maxBody)
    tint.backgroundColor = NativeTheme.sheetGlass
    card.layer.borderColor = NativeTheme.barBorder.cgColor
    card.layer.shadowPath = UIBezierPath(
      roundedRect: card.bounds,
      byRoundingCorners: [.topLeft, .topRight],
      cornerRadii: CGSize(width: NativeTheme.cornerRadius,
                          height: NativeTheme.cornerRadius)).cgPath
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    tint.backgroundColor = NativeTheme.sheetGlass
    card.layer.borderColor = NativeTheme.barBorder.cgColor
  }

  private func add(_ row: SettingsSheetRow) {
    switch row {
    case .value(let label, let value):
      body.addArrangedSubview(makeValueRow(label, value))
    case .action(let label, let value, let run):
      body.addArrangedSubview(makeActionRow(label, value, run))
    case .toggle(let label, let detail, let isOn, let onChange):
      body.addArrangedSubview(makeToggleRow(label, detail, isOn, onChange))
    case .slider(let label, let min, let max, let value, let unit, let format, let onChange):
      body.addArrangedSubview(makeSliderRow(label, min, max, value, unit, format, onChange))
    case .choices(let label, let options, let selected, let onChange):
      body.addArrangedSubview(makeChoiceRow(label, options, selected, onChange))
    case .section(let text):
      let label = UILabel()
      label.text = text
      label.font = UIFont.systemFont(ofSize: 9, weight: .bold)
      label.textColor = NativeTheme.tertiary
      label.heightAnchor.constraint(equalToConstant: 28).isActive = true
      body.addArrangedSubview(label)
    case .note(let text):
      let label = UILabel()
      label.text = text
      label.font = NativeTheme.bodyFont(11)
      label.textColor = NativeTheme.secondary
      label.numberOfLines = 0
      label.setContentCompressionResistancePriority(.required, for: .vertical)
      let wrap = UIView()
      wrap.addSubview(label)
      label.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        label.leadingAnchor.constraint(equalTo: wrap.leadingAnchor),
        label.trailingAnchor.constraint(equalTo: wrap.trailingAnchor),
        label.topAnchor.constraint(equalTo: wrap.topAnchor, constant: 4),
        label.bottomAnchor.constraint(equalTo: wrap.bottomAnchor, constant: -10),
      ])
      body.addArrangedSubview(wrap)
    }
  }

  private func makeValueRow(_ label: String, _ value: String) -> UIView {
    let row = makeBaseRow(label: label, detail: nil)
    let valueLabel = UILabel()
    valueLabel.text = value
    valueLabel.font = NativeTheme.bodyFont(11.5)
    valueLabel.textColor = NativeTheme.secondary
    valueLabel.textAlignment = .right
    row.content.addArrangedSubview(valueLabel)
    return row.view
  }

  private func makeActionRow(_ label: String, _ value: String, _ run: @escaping () -> Void) -> UIView {
    let row = makeBaseRow(label: label, detail: nil)
    let valueLabel = UILabel()
    valueLabel.text = value.isEmpty ? "›" : value + " ›"
    valueLabel.font = NativeTheme.bodyFont(11.5)
    valueLabel.textColor = NativeTheme.navBlue
    row.content.addArrangedSubview(valueLabel)
    let button = UIButton(type: .custom)
    button.backgroundColor = .clear
    button.addAction(UIAction { _ in run() }, for: .touchUpInside)
    row.view.addSubview(button)
    button.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      button.leadingAnchor.constraint(equalTo: row.view.leadingAnchor),
      button.trailingAnchor.constraint(equalTo: row.view.trailingAnchor),
      button.topAnchor.constraint(equalTo: row.view.topAnchor),
      button.bottomAnchor.constraint(equalTo: row.view.bottomAnchor),
    ])
    return row.view
  }

  private func makeToggleRow(_ label: String, _ detail: String?, _ isOn: Bool,
                             _ onChange: @escaping (Bool) -> Void) -> UIView {
    let row = makeBaseRow(label: label, detail: detail)
    let toggle = UISwitch()
    toggle.isOn = isOn
    toggle.onTintColor = NativeTheme.navBlue
    toggle.transform = CGAffineTransform(scaleX: 0.86, y: 0.86)
    toggle.addAction(UIAction { _ in onChange(toggle.isOn) }, for: .valueChanged)
    row.content.addArrangedSubview(toggle)
    return row.view
  }

  private func makeSliderRow(_ label: String, _ minValue: Float, _ maxValue: Float,
                             _ value: Float, _ unit: String,
                             _ format: ((Float) -> String)?,
                             _ onChange: @escaping (Float) -> Void) -> UIView {
    let wrap = UIView()
    let labelView = UILabel()
    labelView.text = label
    labelView.font = NativeTheme.bodyFont(13)
    labelView.textColor = NativeTheme.foreground
    let valueLabel = UILabel()
    valueLabel.font = NativeTheme.numberFont(11)
    valueLabel.textColor = NativeTheme.secondary
    valueLabel.textAlignment = .right
    let slider = UISlider()
    slider.minimumValue = minValue
    slider.maximumValue = maxValue
    slider.value = value
    slider.minimumTrackTintColor = NativeTheme.navBlue
    slider.maximumTrackTintColor = NativeTheme.foreground.withAlphaComponent(0.12)
    let update: () -> Void = {
      let formatted = format?(slider.value) ?? "\(Int(slider.value.rounded()))\(unit)"
      valueLabel.text = formatted
    }
    update()
    slider.addAction(UIAction { _ in
      update()
      onChange(slider.value)
    }, for: .valueChanged)
    [labelView, valueLabel, slider].forEach {
      wrap.addSubview($0)
      $0.translatesAutoresizingMaskIntoConstraints = false
    }
    NSLayoutConstraint.activate([
      labelView.leadingAnchor.constraint(equalTo: wrap.leadingAnchor),
      labelView.topAnchor.constraint(equalTo: wrap.topAnchor, constant: 12),
      valueLabel.trailingAnchor.constraint(equalTo: wrap.trailingAnchor),
      valueLabel.centerYAnchor.constraint(equalTo: labelView.centerYAnchor),
      valueLabel.leadingAnchor.constraint(greaterThanOrEqualTo: labelView.trailingAnchor, constant: 8),
      slider.leadingAnchor.constraint(equalTo: wrap.leadingAnchor),
      slider.trailingAnchor.constraint(equalTo: wrap.trailingAnchor),
      slider.topAnchor.constraint(equalTo: labelView.bottomAnchor, constant: 3),
      slider.bottomAnchor.constraint(equalTo: wrap.bottomAnchor, constant: -8),
    ])
    return separator(after: wrap)
  }

  private func makeChoiceRow(_ label: String, _ options: [String], _ selected: String,
                             _ onChange: @escaping (String) -> Void) -> UIView {
    let wrap = UIView()
    let labelView = UILabel()
    labelView.text = label
    labelView.font = NativeTheme.bodyFont(13)
    labelView.textColor = NativeTheme.foreground
    let header = UIStackView(arrangedSubviews: [labelView])
    header.axis = .horizontal
    header.alignment = .center
    wrap.addSubview(header)

    let chipRows = UIStackView()
    chipRows.axis = .vertical
    chipRows.spacing = 6
    chipRows.alignment = .fill
    wrap.addSubview(chipRows)

    var buttons: [UIButton] = []
    var index = 0
    while index < options.count {
      let end = min(index + 4, options.count)
      let row = UIStackView()
      row.axis = .horizontal
      row.spacing = 6
      row.alignment = .center
      for option in options[index..<end] {
        let button = UIButton(type: .custom)
        button.setTitle(option, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        button.layer.cornerRadius = NativeTheme.cornerRadius
        button.layer.cornerCurve = .continuous
        button.layer.borderWidth = 1
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 9, bottom: 5, right: 9)
        button.heightAnchor.constraint(equalToConstant: 26).isActive = true
        button.addAction(UIAction { _ in
          for (idx, other) in buttons.enumerated() {
            let active = idx == (options.firstIndex(of: option) ?? 0)
            other.backgroundColor = active ? NativeTheme.navSoft : .clear
            other.setTitleColor(active ? NativeTheme.navBlue : NativeTheme.secondary,
                                for: .normal)
            other.layer.borderColor = active
              ? NativeTheme.navBlue.withAlphaComponent(0.4).cgColor
              : NativeTheme.hairline.cgColor
          }
          onChange(option)
        }, for: .touchUpInside)
        buttons.append(button)
        row.addArrangedSubview(button)
      }
      let spacer = UIView()
      spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
      spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
      row.addArrangedSubview(spacer)
      chipRows.addArrangedSubview(row)
      index = end
    }
    for (idx, button) in buttons.enumerated() {
      let active = options[idx] == selected
      button.backgroundColor = active ? NativeTheme.navSoft : .clear
      button.setTitleColor(active ? NativeTheme.navBlue : NativeTheme.secondary, for: .normal)
      button.layer.borderColor = active
        ? NativeTheme.navBlue.withAlphaComponent(0.4).cgColor
        : NativeTheme.hairline.cgColor
    }

    [header, chipRows].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
    NSLayoutConstraint.activate([
      header.leadingAnchor.constraint(equalTo: wrap.leadingAnchor),
      header.trailingAnchor.constraint(equalTo: wrap.trailingAnchor),
      header.topAnchor.constraint(equalTo: wrap.topAnchor, constant: 10),
      chipRows.leadingAnchor.constraint(equalTo: wrap.leadingAnchor),
      chipRows.trailingAnchor.constraint(equalTo: wrap.trailingAnchor),
      chipRows.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 6),
      chipRows.bottomAnchor.constraint(equalTo: wrap.bottomAnchor, constant: -8),
    ])
    return separator(after: wrap)
  }

  private func makeBaseRow(label: String, detail: String?) -> (view: UIView, content: UIStackView) {
    let wrap = UIView()
    let content = UIStackView()
    content.axis = .horizontal
    content.alignment = .center
    content.spacing = 12
    let copy = UIStackView()
    copy.axis = .vertical
    copy.spacing = 2
    let title = UILabel()
    title.text = label
    title.font = NativeTheme.bodyFont(13)
    title.textColor = NativeTheme.foreground
    title.numberOfLines = 1
    copy.addArrangedSubview(title)
    if let detail = detail, !detail.isEmpty {
      let sub = UILabel()
      sub.text = detail
      sub.font = NativeTheme.bodyFont(10)
      sub.textColor = NativeTheme.secondary
      sub.numberOfLines = 1
      copy.addArrangedSubview(sub)
    }
    content.addArrangedSubview(copy)
    let spacer = UIView()
    spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
    content.addArrangedSubview(spacer)
    wrap.addSubview(content)
    content.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      content.leadingAnchor.constraint(equalTo: wrap.leadingAnchor),
      content.trailingAnchor.constraint(equalTo: wrap.trailingAnchor),
      content.centerYAnchor.constraint(equalTo: wrap.centerYAnchor),
      wrap.heightAnchor.constraint(greaterThanOrEqualToConstant: 52),
      content.topAnchor.constraint(greaterThanOrEqualTo: wrap.topAnchor, constant: 8),
      content.bottomAnchor.constraint(lessThanOrEqualTo: wrap.bottomAnchor, constant: -8),
    ])
    return (separator(after: wrap), content)
  }

  private func separator(after view: UIView) -> UIView {
    let holder = UIView()
    holder.addSubview(view)
    view.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      view.leadingAnchor.constraint(equalTo: holder.leadingAnchor),
      view.trailingAnchor.constraint(equalTo: holder.trailingAnchor),
      view.topAnchor.constraint(equalTo: holder.topAnchor),
    ])
    let line = UIView()
    line.backgroundColor = NativeTheme.hairline
    holder.addSubview(line)
    line.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      line.leadingAnchor.constraint(equalTo: holder.leadingAnchor),
      line.trailingAnchor.constraint(equalTo: holder.trailingAnchor),
      line.topAnchor.constraint(equalTo: view.bottomAnchor),
      line.bottomAnchor.constraint(equalTo: holder.bottomAnchor),
      line.heightAnchor.constraint(equalToConstant: 0.5),
    ])
    return holder
  }

  @objc private func close() {
    guard !closing else { return }
    closing = true
    UIView.animate(withDuration: 0.24, delay: 0, options: [.curveEaseIn]) {
      self.card.transform = CGAffineTransform(translationX: 0, y: self.card.bounds.height)
      self.scrim.alpha = 0
    } completion: { _ in
      self.dismiss(animated: false) { self.onClose?() }
    }
  }

  var onClose: (() -> Void)?

  @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
    let translation = max(0, gesture.translation(in: view).y)
    switch gesture.state {
    case .changed:
      card.transform = CGAffineTransform(translationX: 0, y: translation)
      scrim.alpha = 1 - min(0.6, translation / max(1, view.bounds.height))
    case .ended, .cancelled:
      if translation > 80 || gesture.velocity(in: view).y > 500 {
        close()
      } else {
        UIView.animate(withDuration: 0.22) {
          self.card.transform = .identity
          self.scrim.alpha = 1
        }
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
    return velocity.y > 0 && abs(velocity.y) > abs(velocity.x)
  }

  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                         shouldReceive touch: UITouch) -> Bool {
    if gestureRecognizer === dismissPan,
       touch.view?.isDescendant(of: scroll) == true {
      return false
    }
    return true
  }
}

private extension NSLayoutConstraint {
  func withPriority(_ value: Float) -> NSLayoutConstraint {
    priority = UILayoutPriority(value)
    return self
  }
}
