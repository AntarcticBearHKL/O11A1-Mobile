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
        ? UIColor(red: 0.651, green: 0.651, blue: 0.671, alpha: 1)
        : UIColor(red: 0.431, green: 0.431, blue: 0.451, alpha: 1)
    }
  }

  static var tertiary: UIColor {
    UIColor { trait in
      trait.userInterfaceStyle == .dark
        ? UIColor(red: 0.424, green: 0.424, blue: 0.447, alpha: 1)
        : UIColor(red: 0.631, green: 0.631, blue: 0.651, alpha: 1)
    }
  }

  static var hairline: UIColor {
    UIColor { trait in
      trait.userInterfaceStyle == .dark
        ? UIColor(white: 1, alpha: 0.12)
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
        ? UIColor(red: 84.0 / 255.0, green: 167.0 / 255.0, blue: 1.0, alpha: 1)
        : UIColor(red: 0.0, green: 95.0 / 255.0, blue: 184.0 / 255.0, alpha: 1)
    }
  }

  static var navSoft: UIColor {
    UIColor { trait in
      trait.userInterfaceStyle == .dark
        ? UIColor(red: 18.0 / 255.0, green: 37.0 / 255.0, blue: 63.0 / 255.0, alpha: 1)
        : UIColor(red: 220.0 / 255.0, green: 238.0 / 255.0, blue: 1.0, alpha: 1)
    }
  }

  static var navPill: UIColor {
    UIColor(red: 47.0 / 255.0, green: 124.0 / 255.0, blue: 246.0 / 255.0, alpha: 0.10)
  }
  static var barGlass: UIColor {
    UIColor { trait in
      trait.userInterfaceStyle == .dark
        ? UIColor(red: 10.0 / 255.0, green: 10.0 / 255.0, blue: 12.0 / 255.0, alpha: 0.84)
        : UIColor(white: 1.0, alpha: 0.72)
    }
  }

  static var barBorder: UIColor {
    UIColor { trait in
      trait.userInterfaceStyle == .dark
        ? UIColor(white: 1.0, alpha: 0.10)
        : UIColor(white: 1.0, alpha: 0.80)
    }
  }

  static var searchHeadTop: UIColor {
    UIColor { trait in
      trait.userInterfaceStyle == .dark
        ? UIColor(white: 0, alpha: 0.94)
        : UIColor(white: 1, alpha: 0.94)
    }
  }

  static var searchHeadBottom: UIColor {
    UIColor { trait in
      trait.userInterfaceStyle == .dark
        ? UIColor(white: 0, alpha: 0.78)
        : UIColor(white: 1, alpha: 0.78)
    }
  }

  static var sidebarTop: UIColor {
    UIColor { trait in
      trait.userInterfaceStyle == .dark
        ? UIColor(red: 18.0 / 255.0, green: 23.0 / 255.0, blue: 32.0 / 255.0, alpha: 0.74)
        : UIColor(red: 250.0 / 255.0, green: 250.0 / 255.0, blue: 252.0 / 255.0, alpha: 0.74)
    }
  }

  static var sidebarBottom: UIColor {
    UIColor { trait in
      trait.userInterfaceStyle == .dark
        ? UIColor(red: 10.0 / 255.0, green: 13.0 / 255.0, blue: 19.0 / 255.0, alpha: 0.88)
        : UIColor(red: 244.0 / 255.0, green: 245.0 / 255.0, blue: 249.0 / 255.0, alpha: 0.88)
    }
  }

  static var homeRowTop: UIColor {
    UIColor { trait in
      trait.userInterfaceStyle == .dark
        ? UIColor(red: 28.0 / 255.0, green: 30.0 / 255.0, blue: 37.0 / 255.0, alpha: 0.86)
        : UIColor(white: 1.0, alpha: 0.80)
    }
  }

  static var homeRowBottom: UIColor {
    UIColor { trait in
      trait.userInterfaceStyle == .dark
        ? UIColor(red: 17.0 / 255.0, green: 18.0 / 255.0, blue: 23.0 / 255.0, alpha: 0.76)
        : UIColor(white: 1.0, alpha: 0.58)
    }
  }

  static var homeRowLine: UIColor {
    UIColor { trait in
      trait.userInterfaceStyle == .dark
        ? UIColor(white: 1.0, alpha: 0.07)
        : UIColor(white: 1.0, alpha: 0.46)
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
    UIColor { trait in
      let dark = trait.userInterfaceStyle == .dark
      if count >= 10_000_000 {
        return dark
          ? UIColor(red: 1.0, green: 133.0 / 255.0, blue: 120.0 / 255.0, alpha: 1)
          : UIColor(red: 211.0 / 255.0, green: 69.0 / 255.0, blue: 61.0 / 255.0, alpha: 1)
      }
      if count >= 1_000_000 {
        return dark
          ? UIColor(red: 1.0, green: 179.0 / 255.0, blue: 92.0 / 255.0, alpha: 1)
          : UIColor(red: 199.0 / 255.0, green: 119.0 / 255.0, blue: 0.0, alpha: 1)
      }
      if count >= 100_000 {
        return dark
          ? UIColor(red: 127.0 / 255.0, green: 182.0 / 255.0, blue: 1.0, alpha: 1)
          : UIColor(red: 47.0 / 255.0, green: 124.0 / 255.0, blue: 246.0 / 255.0, alpha: 1)
      }
      if count >= 10_000 {
        return dark
          ? UIColor(red: 106.0 / 255.0, green: 211.0 / 255.0, blue: 162.0 / 255.0, alpha: 1)
          : UIColor(red: 47.0 / 255.0, green: 138.0 / 255.0, blue: 90.0 / 255.0, alpha: 1)
      }
      return dark
        ? UIColor(red: 0.651, green: 0.651, blue: 0.671, alpha: 1)
        : UIColor(red: 0.431, green: 0.431, blue: 0.451, alpha: 1)
    }
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

  static func timeAgo(_ raw: Int64) -> String {
    guard raw > 0 else { return "" }
    let seconds = raw > 100_000_000_000 ? raw / 1000 : raw
    let delta = max(0, Int64(Date().timeIntervalSince1970) - seconds)
    if delta < 60 { return "刚刚" }
    if delta < 3600 { return "\(delta / 60) 分钟前" }
    if delta < 86400 { return "\(delta / 3600) 小时前" }
    if delta < 86400 * 30 { return "\(delta / 86400) 天前" }
    let date = Date(timeIntervalSince1970: TimeInterval(seconds))
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
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
