import UIKit

final class FishViewController: UIViewController {
  private let titleLabel = UILabel()
  private let tank = UIView()
  private let fish = UILabel()
  private let subtitle = UILabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = NativeTheme.background

    titleLabel.text = "养鱼"
    titleLabel.font = NativeTheme.titleFont(24)
    titleLabel.textColor = NativeTheme.foreground
    view.addSubview(titleLabel)

    tank.backgroundColor = NativeTheme.foreground.withAlphaComponent(0.05)
    tank.layer.cornerRadius = 24
    tank.layer.cornerCurve = .continuous
    tank.clipsToBounds = true
    view.addSubview(tank)

    fish.text = "🐟"
    fish.font = UIFont.systemFont(ofSize: 58)
    tank.addSubview(fish)

    subtitle.text = "鱼缸还在搭建中\n这里是原生占位页，不再使用网页"
    subtitle.font = NativeTheme.bodyFont(14)
    subtitle.textColor = NativeTheme.secondary
    subtitle.textAlignment = .center
    subtitle.numberOfLines = 0
    view.addSubview(subtitle)

    [titleLabel, tank, fish, subtitle].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
    NSLayoutConstraint.activate([
      titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
      titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 18),

      tank.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
      tank.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
      tank.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
      tank.heightAnchor.constraint(equalToConstant: 220),

      fish.centerXAnchor.constraint(equalTo: tank.centerXAnchor),
      fish.centerYAnchor.constraint(equalTo: tank.centerYAnchor),

      subtitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
      subtitle.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
      subtitle.topAnchor.constraint(equalTo: tank.bottomAnchor, constant: 20),
    ])

    let drift = CABasicAnimation(keyPath: "transform.translation.x")
    drift.fromValue = -60
    drift.toValue = 60
    drift.duration = 4.5
    drift.autoreverses = true
    drift.repeatCount = .infinity
    drift.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    fish.layer.add(drift, forKey: "drift")
  }
}
