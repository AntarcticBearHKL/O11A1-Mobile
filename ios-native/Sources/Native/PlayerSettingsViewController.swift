import UIKit

final class PlayerSettingsViewController: UIViewController, UIGestureRecognizerDelegate {
  var onQuality: ((Int) -> Void)?
  var onDanmaku: ((Bool) -> Void)?
  var onLoop: ((Bool) -> Void)?
  var onClose: (() -> Void)?

  private let scrim = UIView()
  private let card = UIView()
  private let qualityRow = UIButton(type: .custom)
  private let qualityValue = UILabel()
  private let qualityChips = UIStackView()
  private let danmakuRow = UIButton(type: .custom)
  private let danmakuValue = UILabel()
  private let loopRow = UIButton(type: .custom)
  private let loopValue = UILabel()
  private var currentQuality: Int
  private var danmakuOn: Bool
  private var loopOn: Bool
  private var chips: [UIButton] = []
  private var closePan: UIPanGestureRecognizer?

  private let qualities: [(String, Int)] = [
    ("4K", 120), ("1080P", 80), ("720P", 64), ("480P", 32),
  ]

  init(quality: Int, danmaku: Bool, loop: Bool) {
    currentQuality = quality
    danmakuOn = danmaku
    loopOn = loop
    super.init(nibName: nil, bundle: nil)
    modalPresentationStyle = .overFullScreen
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear

    scrim.backgroundColor = UIColor.black.withAlphaComponent(0.38)
    scrim.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(close)))
    view.addSubview(scrim)
    scrim.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      scrim.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrim.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrim.topAnchor.constraint(equalTo: view.topAnchor),
      scrim.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    card.backgroundColor = UIColor { trait in
      trait.userInterfaceStyle == .light
        ? UIColor(red: 247.0 / 255.0, green: 248.0 / 255.0, blue: 250.0 / 255.0, alpha: 1)
        : UIColor(red: 14.0 / 255.0, green: 17.0 / 255.0, blue: 23.0 / 255.0, alpha: 1)
    }
    card.layer.cornerRadius = 30
    card.layer.cornerCurve = .continuous
    card.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    card.clipsToBounds = true
    view.addSubview(card)
    card.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      card.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      card.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      card.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      card.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.74),
    ])

    let title = UILabel()
    title.text = "设置"
    title.font = UIFont.systemFont(ofSize: 19, weight: .bold)
    title.textColor = UIColor { trait in
      trait.userInterfaceStyle == .light
        ? UIColor(red: 24.0 / 255.0, green: 28.0 / 255.0, blue: 36.0 / 255.0, alpha: 0.94)
        : UIColor(white: 0.97, alpha: 0.95)
    }
    card.addSubview(title)
    title.translatesAutoresizingMaskIntoConstraints = false

    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 6
    card.addSubview(stack)
    stack.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      title.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 32),
      title.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
      stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
      stack.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 10),
      stack.bottomAnchor.constraint(lessThanOrEqualTo: card.safeAreaLayoutGuide.bottomAnchor,
                                    constant: -12),
    ])

    let qualityTile = Self.tile()
    let qualityStack = UIStackView()
    qualityStack.axis = .vertical
    qualityStack.spacing = 0
    qualityTile.addSubview(qualityStack)
    qualityStack.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      qualityStack.leadingAnchor.constraint(equalTo: qualityTile.leadingAnchor),
      qualityStack.trailingAnchor.constraint(equalTo: qualityTile.trailingAnchor),
      qualityStack.topAnchor.constraint(equalTo: qualityTile.topAnchor),
      qualityStack.bottomAnchor.constraint(equalTo: qualityTile.bottomAnchor),
    ])

    Self.configureRow(qualityRow, title: "画质")
    qualityRow.addTarget(self, action: #selector(toggleQuality), for: .touchUpInside)
    qualityRow.addSubview(qualityValue)
    configureValue(qualityValue)
    qualityStack.addArrangedSubview(qualityRow)

    qualityChips.axis = .horizontal
    qualityChips.spacing = 6
    qualityChips.distribution = .fillEqually
    qualityChips.isLayoutMarginsRelativeArrangement = true
    qualityChips.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 10, right: 16)
    qualityChips.isHidden = true
    for (index, entry) in qualities.enumerated() {
      let chip = UIButton(type: .custom)
      chip.tag = index
      chip.setTitle(entry.0, for: .normal)
      chip.titleLabel?.font = UIFont.systemFont(ofSize: 11, weight: .bold)
      chip.layer.cornerRadius = 13
      chip.layer.cornerCurve = .continuous
      chip.heightAnchor.constraint(equalToConstant: 26).isActive = true
      chip.addTarget(self, action: #selector(qualityTapped(_:)), for: .touchUpInside)
      chips.append(chip)
      qualityChips.addArrangedSubview(chip)
    }
    qualityStack.addArrangedSubview(qualityChips)
    stack.addArrangedSubview(qualityTile)

    let danmakuTile = Self.tile()
    Self.configureRow(danmakuRow, title: "弹幕设置")
    danmakuRow.addTarget(self, action: #selector(toggleDanmaku), for: .touchUpInside)
    danmakuRow.addSubview(danmakuValue)
    configureValue(danmakuValue)
    danmakuTile.addSubview(danmakuRow)
    danmakuRow.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      danmakuRow.leadingAnchor.constraint(equalTo: danmakuTile.leadingAnchor),
      danmakuRow.trailingAnchor.constraint(equalTo: danmakuTile.trailingAnchor),
      danmakuRow.topAnchor.constraint(equalTo: danmakuTile.topAnchor),
      danmakuRow.bottomAnchor.constraint(equalTo: danmakuTile.bottomAnchor),
    ])
    stack.addArrangedSubview(danmakuTile)

    let loopTile = Self.tile()
    Self.configureRow(loopRow, title: "循环模式")
    loopRow.addTarget(self, action: #selector(toggleLoop), for: .touchUpInside)
    loopRow.addSubview(loopValue)
    configureValue(loopValue)
    loopTile.addSubview(loopRow)
    loopRow.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      loopRow.leadingAnchor.constraint(equalTo: loopTile.leadingAnchor),
      loopRow.trailingAnchor.constraint(equalTo: loopTile.trailingAnchor),
      loopRow.topAnchor.constraint(equalTo: loopTile.topAnchor),
      loopRow.bottomAnchor.constraint(equalTo: loopTile.bottomAnchor),
    ])
    stack.addArrangedSubview(loopTile)

    let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
    pan.delegate = self
    card.addGestureRecognizer(pan)
    closePan = pan

    updateQuality()
    updateDanmaku()
    updateLoop()
  }

  private static func tile() -> UIView {
    let tile = UIView()
    tile.backgroundColor = UIColor { trait in
      trait.userInterfaceStyle == .light
        ? .white
        : UIColor(red: 23.0 / 255.0, green: 28.0 / 255.0, blue: 36.0 / 255.0, alpha: 1)
    }
    tile.layer.cornerRadius = 16
    tile.layer.cornerCurve = .continuous
    tile.layer.borderWidth = 1
    tile.layer.borderColor = UIColor { trait in
      trait.userInterfaceStyle == .light
        ? UIColor(red: 18.0 / 255.0, green: 22.0 / 255.0, blue: 30.0 / 255.0, alpha: 0.07)
        : UIColor(white: 1, alpha: 0.07)
    }.cgColor
    tile.clipsToBounds = true
    return tile
  }

  private static func configureRow(_ row: UIButton, title: String) {
    row.backgroundColor = .clear
    row.contentHorizontalAlignment = .leading
    row.heightAnchor.constraint(equalToConstant: 48).isActive = true
    let label = UILabel()
    label.text = title
    label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
    label.textColor = UIColor { trait in
      trait.userInterfaceStyle == .light
        ? UIColor(red: 24.0 / 255.0, green: 28.0 / 255.0, blue: 36.0 / 255.0, alpha: 0.94)
        : UIColor(white: 0.97, alpha: 0.95)
    }
    label.isUserInteractionEnabled = false
    row.addSubview(label)
    label.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      label.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
      label.centerYAnchor.constraint(equalTo: row.centerYAnchor),
    ])
  }

  private func configureValue(_ value: UILabel) {
    value.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
    value.textColor = UIColor { trait in
      trait.userInterfaceStyle == .light
        ? UIColor(red: 114.0 / 255.0, green: 122.0 / 255.0, blue: 136.0 / 255.0, alpha: 1)
        : UIColor(red: 139.0 / 255.0, green: 149.0 / 255.0, blue: 166.0 / 255.0, alpha: 1)
    }
    value.textAlignment = .center
    value.backgroundColor = UIColor { trait in
      trait.userInterfaceStyle == .light
        ? UIColor(red: 20.0 / 255.0, green: 25.0 / 255.0, blue: 35.0 / 255.0, alpha: 0.045)
        : UIColor(white: 1, alpha: 0.055)
    }
    value.layer.cornerRadius = 10
    value.layer.cornerCurve = .continuous
    value.clipsToBounds = true
    value.isUserInteractionEnabled = false
    value.translatesAutoresizingMaskIntoConstraints = false
    value.widthAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true
    value.heightAnchor.constraint(equalToConstant: 22).isActive = true
    value.trailingAnchor.constraint(equalTo: value.superview!.trailingAnchor, constant: -14).isActive = true
    value.centerYAnchor.constraint(equalTo: value.superview!.centerYAnchor).isActive = true
  }

  private func updateQuality() {
    qualityValue.text = o11a1QualityLabel(currentQuality)
    let light = traitCollection.userInterfaceStyle == .light
    for (index, chip) in chips.enumerated() {
      let on = qualities[index].1 == currentQuality
      chip.backgroundColor = on
        ? (light
            ? UIColor(red: 47.0 / 255.0, green: 124.0 / 255.0, blue: 246.0 / 255.0, alpha: 1)
            : UIColor(red: 76.0 / 255.0, green: 141.0 / 255.0, blue: 1.0, alpha: 1))
        : (light
            ? UIColor(red: 20.0 / 255.0, green: 25.0 / 255.0, blue: 35.0 / 255.0, alpha: 0.045)
            : UIColor(white: 1, alpha: 0.055))
      chip.setTitleColor(on ? .white : UIColor(white: 0.55, alpha: 1), for: .normal)
    }
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    updateQuality()
  }

  private func updateDanmaku() {
    danmakuValue.text = danmakuOn ? "开" : "关"
  }

  private func updateLoop() {
    loopValue.text = loopOn ? "循环" : "单个"
  }

  @objc private func toggleQuality() {
    qualityChips.isHidden.toggle()
  }

  @objc private func qualityTapped(_ sender: UIButton) {
    guard sender.tag < qualities.count else { return }
    currentQuality = qualities[sender.tag].1
    updateQuality()
    onQuality?(currentQuality)
  }

  @objc private func toggleDanmaku() {
    danmakuOn.toggle()
    updateDanmaku()
    onDanmaku?(danmakuOn)
  }

  @objc private func toggleLoop() {
    loopOn.toggle()
    updateLoop()
    onLoop?(loopOn)
  }

  @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
    let translation = max(0, gesture.translation(in: view).y)
    switch gesture.state {
    case .changed:
      card.transform = CGAffineTransform(translationX: 0, y: translation)
    case .ended, .cancelled:
      if translation > 70 || gesture.velocity(in: view).y > 500 {
        close()
      } else {
        UIView.animate(withDuration: 0.22) { self.card.transform = .identity }
      }
    default:
      break
    }
  }

  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    guard let pan = gestureRecognizer as? UIPanGestureRecognizer, pan === closePan else {
      return true
    }
    let velocity = pan.velocity(in: view)
    return velocity.y > 0 && abs(velocity.y) > abs(velocity.x)
  }

  @objc private func close() {
    onClose?()
  }
}
