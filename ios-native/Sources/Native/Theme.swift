import UIKit

enum NativeTheme {
  static var background: UIColor {
    UIColor { trait in trait.userInterfaceStyle == .dark ? .black : .white }
  }

  static var foreground: UIColor {
    UIColor { trait in trait.userInterfaceStyle == .dark ? .white : .black }
  }

  static var secondary: UIColor {
    UIColor { trait in
      trait.userInterfaceStyle == .dark
        ? UIColor(white: 0.62, alpha: 1)
        : UIColor(white: 0.38, alpha: 1)
    }
  }

  static var tertiary: UIColor {
    UIColor { trait in
      trait.userInterfaceStyle == .dark
        ? UIColor(white: 0.40, alpha: 1)
        : UIColor(white: 0.62, alpha: 1)
    }
  }

  static var hairline: UIColor {
    UIColor { trait in
      trait.userInterfaceStyle == .dark
        ? UIColor(white: 1, alpha: 0.10)
        : UIColor(white: 0, alpha: 0.08)
    }
  }

  static var glass: UIColor {
    UIColor { trait in
      trait.userInterfaceStyle == .dark
        ? UIColor(white: 0.08, alpha: 0.72)
        : UIColor(white: 1, alpha: 0.72)
    }
  }

  static let accent = UIColor(red: 1.0, green: 0.36, blue: 0.46, alpha: 1)
  static let pipRose = UIColor(red: 1.0, green: 0.85, blue: 0.87, alpha: 1)
  static let likeBlue = UIColor(red: 0.30, green: 0.60, blue: 1.0, alpha: 1)
  static let warmOrange = UIColor(red: 1.0, green: 0.62, blue: 0.26, alpha: 1)
  static let hotPink = UIColor(red: 1.0, green: 0.36, blue: 0.54, alpha: 1)

  static let cardRadius: CGFloat = 14
  static let toolbarInset: CGFloat = 12
  static let avatarSize: CGFloat = 50

  static func playCountColor(_ count: Int64) -> UIColor {
    if count >= 1_000_000 { return hotPink }
    if count >= 100_000 { return warmOrange }
    if count >= 10_000 { return likeBlue }
    return secondary
  }

  static func titleFont(_ size: CGFloat = 16) -> UIFont {
    UIFont.systemFont(ofSize: size, weight: .semibold)
  }

  static func bodyFont(_ size: CGFloat = 14) -> UIFont {
    UIFont.systemFont(ofSize: size, weight: .regular)
  }

  static func numberFont(_ size: CGFloat = 12) -> UIFont {
    UIFont.monospacedDigitSystemFont(ofSize: size, weight: .medium)
  }

  static func glassView(cornerRadius: CGFloat) -> UIVisualEffectView {
    let view = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    view.layer.cornerRadius = cornerRadius
    view.layer.cornerCurve = .continuous
    view.clipsToBounds = true
    return view
  }
}
