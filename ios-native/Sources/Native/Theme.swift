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

  static var navBlue: UIColor {
    UIColor { trait in
      trait.userInterfaceStyle == .dark
        ? UIColor(red: 0.50, green: 0.71, blue: 1.0, alpha: 1)
        : UIColor(red: 0.0, green: 0.37, blue: 0.72, alpha: 1)
    }
  }

  static var navSoft: UIColor {
    UIColor { trait in
      trait.userInterfaceStyle == .dark
        ? UIColor(red: 0.18, green: 0.49, blue: 0.96, alpha: 0.20)
        : UIColor(red: 0.86, green: 0.93, blue: 1.0, alpha: 1)
    }
  }
  static let pipRose = UIColor(red: 1.0, green: 0.85, blue: 0.87, alpha: 1)
  static let likeBlue = UIColor(red: 0.30, green: 0.60, blue: 1.0, alpha: 1)
  static let warmOrange = UIColor(red: 1.0, green: 0.62, blue: 0.26, alpha: 1)
  static let hotPink = UIColor(red: 1.0, green: 0.36, blue: 0.54, alpha: 1)

  static let cardRadius: CGFloat = 14
  static let toolbarInset: CGFloat = 12
  static let avatarSize: CGFloat = 50

  static func playCountColor(_ count: Int64) -> UIColor {
    if count >= 10_000_000 { return UIColor(red: 0.83, green: 0.27, blue: 0.24, alpha: 1) }
    if count >= 1_000_000 { return UIColor(red: 0.78, green: 0.47, blue: 0.0, alpha: 1) }
    if count >= 100_000 { return UIColor(red: 0.18, green: 0.49, blue: 0.96, alpha: 1) }
    if count >= 10_000 { return UIColor(red: 0.18, green: 0.54, blue: 0.35, alpha: 1) }
    return UIColor(red: 0.54, green: 0.56, blue: 0.61, alpha: 1)
  }

  static func freshness(_ raw: Int64) -> String {
    guard raw > 0 else { return "" }
    let seconds = raw > 100_000_000_000 ? raw / 1000 : raw
    let age = max(0, Int64(Date().timeIntervalSince1970) - seconds)
    let hour: Int64 = 3600
    let day: Int64 = 86400
    if age < hour { return "刚刚" }
    if age < day { return "\(age / hour)小时前" }
    if age < day * 7 { return "\(age / day)天前" }
    if age < day * 30 { return "\(age / (7 * day))周前" }
    if age < day * 90 { return "\(age / (30 * day))个月前" }
    if age < day * 365 { return "\(age / (90 * day))季度前" }
    return "\(age / (365 * day))年前"
  }

  static func freshnessColor(_ raw: Int64) -> UIColor {
    guard raw > 0 else { return UIColor(red: 0.54, green: 0.56, blue: 0.61, alpha: 1) }
    let seconds = raw > 100_000_000_000 ? raw / 1000 : raw
    let age = max(0, Int64(Date().timeIntervalSince1970) - seconds)
    let day: Int64 = 86400
    if age < day { return UIColor(red: 0.85, green: 0.47, blue: 0.38, alpha: 1) }
    if age < day * 7 { return UIColor(red: 0.79, green: 0.60, blue: 0.31, alpha: 1) }
    if age < day * 30 { return UIColor(red: 0.31, green: 0.60, blue: 0.51, alpha: 1) }
    if age < day * 90 { return UIColor(red: 0.36, green: 0.52, blue: 0.78, alpha: 1) }
    if age < day * 365 { return UIColor(red: 0.54, green: 0.47, blue: 0.72, alpha: 1) }
    return UIColor(red: 0.54, green: 0.56, blue: 0.61, alpha: 1)
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
