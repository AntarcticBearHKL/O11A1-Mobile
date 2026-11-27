import UIKit

final class VideoDetailViewController: UIViewController, UIGestureRecognizerDelegate {
  var onClose: (() -> Void)?
  var onProfile: ((Int64) -> Void)?
  var onQuality: ((Int) -> Void)?
  var onDanmaku: ((Bool) -> Void)?
  var onDanmakuSettingsChanged: (() -> Void)?
  var onLoop: ((Bool) -> Void)?
  var initialQuality = 80
  var initialDanmakuOn = true
  var initialLoopOn = false

  private let item: VideoItem
  private let scroll = UIScrollView()
  private let card = UIView()
  private let cover = UIImageView()
  private let durationChip = UILabel()
  private let titleLabel = UILabel()
  private let dateLabel = UILabel()
  private let bvidLabel = UILabel()
  private let timeLabel = UILabel()
  private let avatar = UIImageView()
  private let ownerName = UILabel()
  private let ownerMeta = UILabel()
  private let authorButton = UIButton(type: .custom)
  private let viewValue = UILabel()
  private let danmakuValue = UILabel()
  private let likeValue = UILabel()
  private let favoriteValue = UILabel()
  private let descLabel = UILabel()
  private let descToggle = UIButton(type: .system)
  private let qualitySetting = UILabel()
  private let danmakuSetting = UILabel()
  private let loopSetting = UILabel()
  private let qualityChips = UIStackView()
  private var qualityButtons: [UIButton] = []
  private var qualityValue = 80
  private var danmakuOn = true
  private var loopOn = false
  private let danmakuPanel = UIStackView()
  private var danmakuValueLabels: [UILabel] = []
  private var danmakuSliders: [UISlider] = []
  private var danmakuAreaButtons: [UIButton] = []
  private var danmakuArea = "全屏"
  private var danmakuOpacity: Float = 88
  private var danmakuSize: Float = 100
  private var danmakuSpeed: Float = 100
  private var danmakuDensity = true
  private var descExpanded = false
  private var detailMid: Int64 = 0
  private var dismissPan: UIPanGestureRecognizer?

  init(item: VideoItem) {
    self.item = item
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear

    card.backgroundColor = NativeTheme.background.withAlphaComponent(0.98)
    card.layer.cornerRadius = NativeTheme.cornerRadius
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

    scroll.alwaysBounceVertical = true
    scroll.showsVerticalScrollIndicator = false
    card.addSubview(scroll)
    scroll.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      scroll.leadingAnchor.constraint(equalTo: card.leadingAnchor),
      scroll.trailingAnchor.constraint(equalTo: card.trailingAnchor),
      scroll.topAnchor.constraint(equalTo: card.topAnchor),
      scroll.bottomAnchor.constraint(equalTo: card.bottomAnchor),
    ])

    let stack = UIStackView()
    stack.axis = .vertical
    stack.alignment = .fill
    stack.spacing = 14
    scroll.addSubview(stack)
    stack.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 20),
      stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -20),
      stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor,
                                 constant: view.safeAreaInsets.top + 16),
      stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -32),
      stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -40),
    ])

    cover.contentMode = .scaleAspectFill
    cover.clipsToBounds = true
    cover.layer.cornerRadius = NativeTheme.cornerRadius
    cover.layer.cornerCurve = .continuous
    cover.backgroundColor = NativeTheme.tertiary.withAlphaComponent(0.18)
    ImageLoader.shared.load(item.pic, into: cover)
    let hero = UIView()
    hero.addSubview(cover)
    cover.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      cover.leadingAnchor.constraint(equalTo: hero.leadingAnchor),
      cover.trailingAnchor.constraint(equalTo: hero.trailingAnchor),
      cover.topAnchor.constraint(equalTo: hero.topAnchor),
      cover.bottomAnchor.constraint(equalTo: hero.bottomAnchor),
      cover.heightAnchor.constraint(equalTo: cover.widthAnchor, multiplier: 9.0 / 16.0),
    ])
    durationChip.text = item.duration
    durationChip.font = NativeTheme.numberFont(11)
    durationChip.textColor = .white
    durationChip.textAlignment = .center
    durationChip.backgroundColor = UIColor.black.withAlphaComponent(0.78)
    durationChip.layer.cornerRadius = NativeTheme.cornerRadius
    durationChip.clipsToBounds = true
    hero.addSubview(durationChip)
    durationChip.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      durationChip.trailingAnchor.constraint(equalTo: hero.trailingAnchor, constant: -8),
      durationChip.bottomAnchor.constraint(equalTo: hero.bottomAnchor, constant: -8),
      durationChip.widthAnchor.constraint(greaterThanOrEqualToConstant: 40),
      durationChip.heightAnchor.constraint(equalToConstant: 18),
    ])
    stack.addArrangedSubview(hero)

    titleLabel.text = item.title
    titleLabel.font = UIFont.systemFont(ofSize: 19, weight: .bold)
    titleLabel.textColor = NativeTheme.foreground
    titleLabel.numberOfLines = 0
    stack.addArrangedSubview(titleLabel)

    let meta = UIStackView()
    meta.axis = .horizontal
    meta.spacing = 10
    meta.alignment = .center
    [dateLabel, bvidLabel, timeLabel].forEach {
      $0.font = NativeTheme.numberFont(10.5)
      $0.textColor = NativeTheme.tertiary
      meta.addArrangedSubview($0)
    }
    dateLabel.text = Self.dateText(item.pubdate)
    bvidLabel.text = item.bvid.isEmpty ? "" : item.bvid
    timeLabel.text = item.duration
    stack.addArrangedSubview(meta)

    let author = UIView()
    author.backgroundColor = NativeTheme.foreground.withAlphaComponent(0.05)
    author.layer.cornerRadius = NativeTheme.cornerRadius
    author.layer.cornerCurve = .continuous
    stack.addArrangedSubview(author)

    avatar.contentMode = .scaleAspectFill
    avatar.clipsToBounds = true
    avatar.layer.cornerRadius = 21
    avatar.backgroundColor = NativeTheme.tertiary.withAlphaComponent(0.2)
    ImageLoader.shared.load(item.ownerFace, into: avatar, placeholder: nil)
    author.addSubview(avatar)

    ownerName.text = item.owner
    ownerName.font = UIFont.systemFont(ofSize: 16, weight: .bold)
    ownerName.textColor = NativeTheme.foreground
    ownerName.numberOfLines = 1
    author.addSubview(ownerName)

    ownerMeta.text = item.mid > 0 ? "UID \(item.mid) · 点击进入主页" : "UP 主"
    ownerMeta.font = NativeTheme.bodyFont(10)
    ownerMeta.textColor = NativeTheme.secondary
    author.addSubview(ownerMeta)

    let go = UILabel()
    go.text = "主页 ›"
    go.font = NativeTheme.bodyFont(11)
    go.textColor = NativeTheme.navBlue
    author.addSubview(go)

    authorButton.backgroundColor = .clear
    authorButton.addTarget(self, action: #selector(authorTapped), for: .touchUpInside)
    author.addSubview(authorButton)

    [avatar, ownerName, ownerMeta, go, authorButton].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
    }
    NSLayoutConstraint.activate([
      avatar.leadingAnchor.constraint(equalTo: author.leadingAnchor, constant: 12),
      avatar.topAnchor.constraint(equalTo: author.topAnchor, constant: 10),
      avatar.bottomAnchor.constraint(equalTo: author.bottomAnchor, constant: -10),
      avatar.widthAnchor.constraint(equalToConstant: 42),
      avatar.heightAnchor.constraint(equalToConstant: 42),
      ownerName.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 10),
      ownerName.topAnchor.constraint(equalTo: author.topAnchor, constant: 12),
      ownerName.trailingAnchor.constraint(lessThanOrEqualTo: go.leadingAnchor, constant: -8),
      ownerMeta.leadingAnchor.constraint(equalTo: ownerName.leadingAnchor),
      ownerMeta.topAnchor.constraint(equalTo: ownerName.bottomAnchor, constant: 3),
      ownerMeta.trailingAnchor.constraint(lessThanOrEqualTo: go.leadingAnchor, constant: -8),
      go.trailingAnchor.constraint(equalTo: author.trailingAnchor, constant: -12),
      go.centerYAnchor.constraint(equalTo: author.centerYAnchor),
      authorButton.leadingAnchor.constraint(equalTo: author.leadingAnchor),
      authorButton.trailingAnchor.constraint(equalTo: author.trailingAnchor),
      authorButton.topAnchor.constraint(equalTo: author.topAnchor),
      authorButton.bottomAnchor.constraint(equalTo: author.bottomAnchor),
    ])

    let stats = UIStackView()
    stats.axis = .horizontal
    stats.distribution = .fillEqually
    stats.alignment = .fill
    stats.backgroundColor = NativeTheme.foreground.withAlphaComponent(0.05)
    stats.layer.cornerRadius = NativeTheme.cornerRadius
    stats.layer.cornerCurve = .continuous
    stats.isLayoutMarginsRelativeArrangement = true
    stats.layoutMargins = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
    stack.addArrangedSubview(stats)
    for (value, label) in [(viewValue, "播放"), (danmakuValue, "弹幕"),
                           (likeValue, "点赞"), (favoriteValue, "收藏")] {
      let column = UIStackView()
      column.axis = .vertical
      column.alignment = .center
      column.spacing = 3
      value.font = UIFont.monospacedDigitSystemFont(ofSize: 13, weight: .semibold)
      value.textColor = NativeTheme.foreground
      value.text = "—"
      let caption = UILabel()
      caption.text = label
      caption.font = NativeTheme.bodyFont(9.5)
      caption.textColor = NativeTheme.secondary
      column.addArrangedSubview(value)
      column.addArrangedSubview(caption)
      stats.addArrangedSubview(column)
    }

    descLabel.font = NativeTheme.bodyFont(12)
    descLabel.textColor = NativeTheme.secondary
    descLabel.numberOfLines = 3
    descLabel.text = item.desc.isEmpty ? "暂无简介" : item.desc
    stack.addArrangedSubview(descLabel)

    descToggle.setTitle("展开简介", for: .normal)
    descToggle.titleLabel?.font = NativeTheme.bodyFont(12)
    descToggle.setTitleColor(NativeTheme.navBlue, for: .normal)
    descToggle.contentHorizontalAlignment = .left
    descToggle.addTarget(self, action: #selector(toggleDesc), for: .touchUpInside)
    stack.addArrangedSubview(descToggle)
    descToggle.isHidden = item.desc.count <= 60

    qualityValue = initialQuality
    danmakuOn = initialDanmakuOn
    loopOn = initialLoopOn
    let defaults = UserDefaults.standard
    danmakuOpacity = defaults.object(forKey: "danmaku_opacity") == nil
      ? 88 : defaults.float(forKey: "danmaku_opacity")
    danmakuSize = defaults.object(forKey: "danmaku_size") == nil
      ? 100 : defaults.float(forKey: "danmaku_size")
    danmakuSpeed = defaults.object(forKey: "danmaku_speed") == nil
      ? 100 : defaults.float(forKey: "danmaku_speed")
    danmakuArea = defaults.string(forKey: "danmaku_area") ?? "全屏"
    danmakuDensity = defaults.object(forKey: "danmaku_density") == nil
      ? true : defaults.bool(forKey: "danmaku_density")

    let settingsTitle = UILabel()
    settingsTitle.text = "播放设置"
    settingsTitle.font = UIFont.systemFont(ofSize: 13, weight: .bold)
    settingsTitle.textColor = NativeTheme.secondary
    stack.addArrangedSubview(settingsTitle)

    let settingsTile = UIView()
    settingsTile.backgroundColor = NativeTheme.foreground.withAlphaComponent(0.05)
    settingsTile.layer.cornerRadius = NativeTheme.cornerRadius
    settingsTile.layer.cornerCurve = .continuous
    stack.addArrangedSubview(settingsTile)

    let settingsStack = UIStackView()
    settingsStack.axis = .vertical
    settingsStack.alignment = .fill
    settingsStack.spacing = 0
    settingsTile.addSubview(settingsStack)
    settingsStack.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      settingsStack.leadingAnchor.constraint(equalTo: settingsTile.leadingAnchor, constant: 14),
      settingsStack.trailingAnchor.constraint(equalTo: settingsTile.trailingAnchor, constant: -14),
      settingsStack.topAnchor.constraint(equalTo: settingsTile.topAnchor),
      settingsStack.bottomAnchor.constraint(equalTo: settingsTile.bottomAnchor),
    ])

    qualitySetting.font = NativeTheme.bodyFont(11)
    qualitySetting.textColor = NativeTheme.secondary
    qualitySetting.textAlignment = .right
    danmakuSetting.font = NativeTheme.bodyFont(11)
    danmakuSetting.textColor = NativeTheme.secondary
    danmakuSetting.textAlignment = .right
    loopSetting.font = NativeTheme.bodyFont(11)
    loopSetting.textColor = NativeTheme.secondary
    loopSetting.textAlignment = .right

    settingsStack.addArrangedSubview(makeSettingsRow(
      title: "画质", value: qualitySetting, chevron: true,
      action: #selector(toggleQualityChips)))
    settingsStack.addArrangedSubview(settingsSeparator())
    settingsStack.addArrangedSubview(makeQualityChips())
    settingsStack.addArrangedSubview(makeSettingsRow(
      title: "弹幕设置", value: danmakuSetting, chevron: true,
      action: #selector(toggleDanmakuSetting)))
    settingsStack.addArrangedSubview(makeDanmakuPanel())
    settingsStack.addArrangedSubview(settingsSeparator())
    settingsStack.addArrangedSubview(makeSettingsRow(
      title: "循环模式", value: loopSetting, chevron: false,
      action: #selector(toggleLoopSetting)))

    updateSettingsLabels()

    let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
    pan.delegate = self
    view.addGestureRecognizer(pan)
    dismissPan = pan

    loadDetail()
  }

  private func makeSettingsRow(title: String, value: UILabel, chevron: Bool,
                               action: Selector) -> UIView {
    let row = UIButton(type: .custom)
    row.addTarget(self, action: action, for: .touchUpInside)
    row.heightAnchor.constraint(equalToConstant: 52).isActive = true

    let label = UILabel()
    label.text = title
    label.font = UIFont.systemFont(ofSize: 13.5, weight: .semibold)
    label.textColor = NativeTheme.foreground
    label.isUserInteractionEnabled = false
    row.addSubview(label)
    row.addSubview(value)
    label.translatesAutoresizingMaskIntoConstraints = false
    value.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      label.leadingAnchor.constraint(equalTo: row.leadingAnchor),
      label.centerYAnchor.constraint(equalTo: row.centerYAnchor),
      value.trailingAnchor.constraint(equalTo: row.trailingAnchor,
                                      constant: chevron ? -22 : 0),
      value.centerYAnchor.constraint(equalTo: row.centerYAnchor),
      value.leadingAnchor.constraint(greaterThanOrEqualTo: label.trailingAnchor, constant: 8),
    ])
    if chevron {
      let arrow = UILabel()
      arrow.text = "›"
      arrow.font = NativeTheme.bodyFont(18)
      arrow.textColor = NativeTheme.tertiary
      arrow.isUserInteractionEnabled = false
      row.addSubview(arrow)
      arrow.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        arrow.trailingAnchor.constraint(equalTo: row.trailingAnchor),
        arrow.centerYAnchor.constraint(equalTo: row.centerYAnchor),
      ])
    }
    return row
  }

  private func settingsSeparator() -> UIView {
    let line = UIView()
    line.backgroundColor = NativeTheme.hairline
    line.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
    return line
  }

  private func makeDanmakuPanel() -> UIView {
    danmakuPanel.axis = .vertical
    danmakuPanel.alignment = .fill
    danmakuPanel.spacing = 0
    danmakuPanel.isHidden = true
    danmakuPanel.addArrangedSubview(settingsSeparator())
    danmakuPanel.addArrangedSubview(makeDanmakuSwitchRow("弹幕显示", isOn: danmakuOn, tag: 0))
    danmakuPanel.addArrangedSubview(settingsSeparator())
    danmakuPanel.addArrangedSubview(makeDanmakuSliderRow(
      "不透明度", min: 0, max: 100, value: danmakuOpacity, tag: 0))
    danmakuPanel.addArrangedSubview(settingsSeparator())
    danmakuPanel.addArrangedSubview(makeDanmakuSliderRow(
      "字号", min: 50, max: 150, value: danmakuSize, tag: 1))
    danmakuPanel.addArrangedSubview(settingsSeparator())
    danmakuPanel.addArrangedSubview(makeDanmakuSliderRow(
      "速度", min: 50, max: 200, value: danmakuSpeed, tag: 2))
    danmakuPanel.addArrangedSubview(settingsSeparator())
    danmakuPanel.addArrangedSubview(makeDanmakuAreaRow())
    danmakuPanel.addArrangedSubview(settingsSeparator())
    danmakuPanel.addArrangedSubview(makeDanmakuSwitchRow("分布密度", isOn: danmakuDensity, tag: 1))
    let bottom = UIView()
    bottom.heightAnchor.constraint(equalToConstant: 6).isActive = true
    danmakuPanel.addArrangedSubview(bottom)
    return danmakuPanel
  }

  private func makeDanmakuSwitchRow(_ title: String, isOn: Bool, tag: Int) -> UIView {
    let row = UIView()
    row.heightAnchor.constraint(equalToConstant: 48).isActive = true
    let label = UILabel()
    label.text = title
    label.font = UIFont.systemFont(ofSize: 12.5, weight: .medium)
    label.textColor = NativeTheme.foreground
    row.addSubview(label)
    label.translatesAutoresizingMaskIntoConstraints = false
    let toggle = UISwitch()
    toggle.isOn = isOn
    toggle.onTintColor = NativeTheme.navBlue
    toggle.tag = tag
    toggle.addTarget(self, action: #selector(danmakuSwitchChanged(_:)), for: .valueChanged)
    row.addSubview(toggle)
    toggle.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      label.leadingAnchor.constraint(equalTo: row.leadingAnchor),
      label.centerYAnchor.constraint(equalTo: row.centerYAnchor),
      toggle.trailingAnchor.constraint(equalTo: row.trailingAnchor),
      toggle.centerYAnchor.constraint(equalTo: row.centerYAnchor),
    ])
    return row
  }

  private func makeDanmakuSliderRow(_ title: String, min: Float, max: Float,
                                     value: Float, tag: Int) -> UIView {
    let row = UIView()
    row.heightAnchor.constraint(equalToConstant: 64).isActive = true
    let label = UILabel()
    label.text = title
    label.font = UIFont.systemFont(ofSize: 12.5, weight: .medium)
    label.textColor = NativeTheme.foreground
    row.addSubview(label)
    label.translatesAutoresizingMaskIntoConstraints = false
    let valueLabel = UILabel()
    valueLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 10.5, weight: .medium)
    valueLabel.textColor = NativeTheme.secondary
    valueLabel.textAlignment = .right
    row.addSubview(valueLabel)
    valueLabel.translatesAutoresizingMaskIntoConstraints = false
    let slider = UISlider()
    slider.minimumValue = min
    slider.maximumValue = max
    slider.value = value
    slider.tag = tag
    slider.minimumTrackTintColor = NativeTheme.navBlue
    slider.maximumTrackTintColor = NativeTheme.hairline
    slider.addTarget(self, action: #selector(danmakuSliderChanged(_:)), for: .valueChanged)
    row.addSubview(slider)
    slider.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      label.leadingAnchor.constraint(equalTo: row.leadingAnchor),
      label.topAnchor.constraint(equalTo: row.topAnchor, constant: 8),
      valueLabel.trailingAnchor.constraint(equalTo: row.trailingAnchor),
      valueLabel.centerYAnchor.constraint(equalTo: label.centerYAnchor),
      slider.leadingAnchor.constraint(equalTo: row.leadingAnchor),
      slider.trailingAnchor.constraint(equalTo: row.trailingAnchor),
      slider.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 2),
      slider.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -4),
    ])
    danmakuValueLabels.append(valueLabel)
    danmakuSliders.append(slider)
    updateDanmakuSliderLabel(tag: tag, value: value)
    return row
  }

  private func makeDanmakuAreaRow() -> UIView {
    let row = UIView()
    row.heightAnchor.constraint(equalToConstant: 52).isActive = true
    let label = UILabel()
    label.text = "显示区域"
    label.font = UIFont.systemFont(ofSize: 12.5, weight: .medium)
    label.textColor = NativeTheme.foreground
    row.addSubview(label)
    label.translatesAutoresizingMaskIntoConstraints = false
    let chips = UIStackView()
    chips.axis = .horizontal
    chips.alignment = .center
    chips.spacing = 6
    row.addSubview(chips)
    chips.translatesAutoresizingMaskIntoConstraints = false
    for (index, title) in ["全屏", "1/2 屏", "1/3 屏"].enumerated() {
      let button = UIButton(type: .custom)
      button.tag = index
      button.setTitle(title, for: .normal)
      button.titleLabel?.font = UIFont.systemFont(ofSize: 10, weight: .bold)
      button.layer.cornerRadius = NativeTheme.cornerRadius
      button.layer.cornerCurve = .continuous
      button.layer.borderWidth = 1
      button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 9, bottom: 5, right: 9)
      button.heightAnchor.constraint(equalToConstant: 26).isActive = true
      button.addTarget(self, action: #selector(danmakuAreaTapped(_:)), for: .touchUpInside)
      danmakuAreaButtons.append(button)
      chips.addArrangedSubview(button)
    }
    NSLayoutConstraint.activate([
      label.leadingAnchor.constraint(equalTo: row.leadingAnchor),
      label.centerYAnchor.constraint(equalTo: row.centerYAnchor),
      chips.trailingAnchor.constraint(equalTo: row.trailingAnchor),
      chips.centerYAnchor.constraint(equalTo: row.centerYAnchor),
      chips.leadingAnchor.constraint(greaterThanOrEqualTo: label.trailingAnchor, constant: 8),
    ])
    updateDanmakuArea()
    return row
  }

  private func updateDanmakuSliderLabel(tag: Int, value: Float) {
    guard tag < danmakuValueLabels.count else { return }
    switch tag {
    case 0, 1:
      danmakuValueLabels[tag].text = "\(Int(value))%"
    default:
      danmakuValueLabels[tag].text = String(format: "%.1f×", Double(value) / 100.0)
    }
  }

  private func updateDanmakuArea() {
    let titles = ["全屏", "1/2 屏", "1/3 屏"]
    for (index, button) in danmakuAreaButtons.enumerated() {
      let on = titles[index] == danmakuArea
      button.backgroundColor = on ? NativeTheme.navSoft : .clear
      button.setTitleColor(on ? NativeTheme.navBlue : NativeTheme.secondary,
                           for: .normal)
      button.layer.borderColor = on
        ? NativeTheme.navBlue.withAlphaComponent(0.4).cgColor
        : NativeTheme.hairline.cgColor
    }
  }

  @objc private func danmakuSwitchChanged(_ sender: UISwitch) {
    if sender.tag == 0 {
      danmakuOn = sender.isOn
      UserDefaults.standard.set(danmakuOn, forKey: "danmaku_enabled")
      updateSettingsLabels()
      onDanmaku?(danmakuOn)
    } else {
      danmakuDensity = sender.isOn
      UserDefaults.standard.set(danmakuDensity, forKey: "danmaku_density")
    }
    onDanmakuSettingsChanged?()
  }

  @objc private func danmakuSliderChanged(_ sender: UISlider) {
    if sender.tag == 2 {
      sender.value = (sender.value / 10).rounded() * 10
    }
    let value = sender.value
    let defaults = UserDefaults.standard
    switch sender.tag {
    case 0:
      danmakuOpacity = value
      defaults.set(value, forKey: "danmaku_opacity")
    case 1:
      danmakuSize = value
      defaults.set(value, forKey: "danmaku_size")
    default:
      danmakuSpeed = value
      defaults.set(value, forKey: "danmaku_speed")
    }
    updateDanmakuSliderLabel(tag: sender.tag, value: value)
    onDanmakuSettingsChanged?()
  }

  @objc private func danmakuAreaTapped(_ sender: UIButton) {
    let titles = ["全屏", "1/2 屏", "1/3 屏"]
    guard sender.tag < titles.count else { return }
    danmakuArea = titles[sender.tag]
    UserDefaults.standard.set(danmakuArea, forKey: "danmaku_area")
    updateDanmakuArea()
    onDanmakuSettingsChanged?()
  }

  private func makeQualityChips() -> UIView {
    qualityChips.axis = .horizontal
    qualityChips.spacing = 6
    qualityChips.alignment = .center
    qualityChips.isLayoutMarginsRelativeArrangement = true
    qualityChips.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
    qualityChips.isHidden = true
    let options: [(String, Int)] = [("4K", 120), ("1080P", 80), ("720P", 64), ("480P", 32)]
    for entry in options {
      let button = UIButton(type: .custom)
      button.setTitle(entry.0, for: .normal)
      button.titleLabel?.font = UIFont.systemFont(ofSize: 10, weight: .bold)
      button.layer.cornerRadius = NativeTheme.cornerRadius
      button.layer.cornerCurve = .continuous
      button.layer.borderWidth = 1
      button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 9, bottom: 5, right: 9)
      button.heightAnchor.constraint(equalToConstant: 26).isActive = true
      button.tag = entry.1
      button.addTarget(self, action: #selector(qualityChipTapped(_:)), for: .touchUpInside)
      qualityButtons.append(button)
      qualityChips.addArrangedSubview(button)
    }
    let spacer = UIView()
    spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
    qualityChips.addArrangedSubview(spacer)
    updateQualityChips()
    return qualityChips
  }

  @objc private func toggleQualityChips() {
    qualityChips.isHidden.toggle()
    UIView.animate(withDuration: 0.22) {
      self.view.layoutIfNeeded()
    }
  }

  @objc private func qualityChipTapped(_ sender: UIButton) {
    qualityValue = sender.tag
    updateQualityChips()
    updateSettingsLabels()
    onQuality?(sender.tag)
  }

  private func updateQualityChips() {
    for button in qualityButtons {
      let active = button.tag == qualityValue
      button.backgroundColor = active ? NativeTheme.navSoft : .clear
      button.setTitleColor(active ? NativeTheme.navBlue : NativeTheme.secondary,
                           for: .normal)
      button.layer.borderColor = active
        ? NativeTheme.navBlue.withAlphaComponent(0.4).cgColor
        : NativeTheme.hairline.cgColor
    }
  }

  @objc private func toggleDanmakuSetting() {
    danmakuPanel.isHidden.toggle()
    UIView.animate(withDuration: 0.22, animations: {
      self.view.layoutIfNeeded()
    }) { _ in
      guard !self.danmakuPanel.isHidden else { return }
      let rect = self.danmakuPanel.convert(self.danmakuPanel.bounds, to: self.scroll)
      self.scroll.scrollRectToVisible(rect.insetBy(dx: 0, dy: -16), animated: true)
    }
  }

  func testExpandDanmaku() {
    if danmakuPanel.isHidden { toggleDanmakuSetting() }
  }

  @objc private func toggleLoopSetting() {
    loopOn.toggle()
    updateSettingsLabels()
    onLoop?(loopOn)
  }

  private func updateSettingsLabels() {
    let name: String
    switch qualityValue {
    case 120: name = "4K"
    case 116: name = "1080P60"
    case 112: name = "1080P+"
    case 80: name = "1080P"
    case 74: name = "720P60"
    case 64: name = "720P"
    case 32: name = "480P"
    case 16: name = "360P"
    default: name = "1080P"
    }
    qualitySetting.text = name
    danmakuSetting.text = danmakuOn ? "开" : "关"
    loopSetting.text = loopOn ? "循环" : "单个"
  }

  private func loadDetail() {
    BiliAPI.shared.videoInfo(item.bvid) { [weak self] result in
      guard let self = self, case .success(let json) = result else { return }
      let title = o11a1String(json["title"])
      if !title.isEmpty { self.titleLabel.text = title }
      let desc = o11a1String(json["desc"])
      if !desc.isEmpty {
        self.descLabel.text = desc
        self.descToggle.isHidden = desc.count <= 60
      }
      let pic = o11a1HTTPS(o11a1String(json["pic"]))
      if !pic.isEmpty { ImageLoader.shared.load(pic, into: self.cover) }
      let owner = o11a1String(json["owner"])
      if !owner.isEmpty { self.ownerName.text = owner }
      let face = o11a1HTTPS(o11a1String(json["ownerFace"]))
      if !face.isEmpty { ImageLoader.shared.load(face, into: self.avatar, placeholder: nil) }
      self.detailMid = o11a1Int64(json["mid"])
      if self.detailMid > 0 {
        self.ownerMeta.text = "UID \(self.detailMid) · 点击进入主页"
      }
      let duration = o11a1String(json["duration"])
      if !duration.isEmpty {
        self.timeLabel.text = duration
        self.durationChip.text = duration
      }
      let date = Self.dateText(o11a1Int64(json["pubdate"]))
      if !date.isEmpty { self.dateLabel.text = date }
      if let stat = json["stat"] as? [String: Any] {
        self.viewValue.text = o11a1Count(o11a1Int64(stat["view"]))
        self.danmakuValue.text = o11a1Count(o11a1Int64(stat["danmaku"]))
        self.likeValue.text = o11a1Count(o11a1Int64(stat["like"]))
        self.favoriteValue.text = o11a1Count(o11a1Int64(stat["favorite"]))
      }
    }
  }

  private static func dateText(_ raw: Int64) -> String {
    guard raw > 0 else { return "" }
    let seconds = raw > 100_000_000_000 ? raw / 1000 : raw
    let date = Date(timeIntervalSince1970: TimeInterval(seconds))
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
  }

  @objc private func authorTapped() {
    let mid = detailMid > 0 ? detailMid : item.mid
    guard mid > 0 else { return }
    onProfile?(mid)
  }

  @objc private func toggleDesc() {
    descExpanded.toggle()
    descLabel.numberOfLines = descExpanded ? 0 : 3
    descToggle.setTitle(descExpanded ? "收起简介" : "展开简介", for: .normal)
  }

  @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
    let width = max(1, view.bounds.width)
    let reference = view.superview ?? view
    let translation = gesture.translation(in: reference).x
    switch gesture.state {
    case .changed:
      view.transform = CGAffineTransform(translationX: min(0, translation), y: 0)
    case .ended, .cancelled:
      let velocity = gesture.velocity(in: view).x
      if translation < -width * 0.24 || velocity < -350 {
        close()
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
    let translation = pan.translation(in: view)
    return abs(translation.x) > abs(translation.y) * 1.1
      || abs(velocity.x) > abs(velocity.y) * 1.1
  }

  private func close() {
    onClose?()
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    card.backgroundColor = NativeTheme.background.withAlphaComponent(0.98)
    authorButton.superview?.backgroundColor = NativeTheme.foreground.withAlphaComponent(0.05)
    descLabel.textColor = NativeTheme.secondary
  }
}
