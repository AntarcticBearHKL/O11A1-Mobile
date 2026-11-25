import UIKit

enum AppTheme: String, CaseIterable {
  case system
  case light
  case dark

  var title: String {
    switch self {
    case .system: return "跟随系统"
    case .light: return "浅色"
    case .dark: return "深色"
    }
  }

  var style: UIUserInterfaceStyle {
    switch self {
    case .system: return .unspecified
    case .light: return .light
    case .dark: return .dark
    }
  }
}

final class ThemeManager {
  static let shared = ThemeManager()
  private let themeKey = "o11a1_native_theme"
  private let qualityKey = "o11a1_native_quality"

  var theme: AppTheme {
    get { AppTheme(rawValue: UserDefaults.standard.string(forKey: themeKey) ?? "") ?? .system }
    set {
      UserDefaults.standard.set(newValue.rawValue, forKey: themeKey)
      apply()
    }
  }

  var quality: Int {
    get {
      let value = UserDefaults.standard.integer(forKey: qualityKey)
      return value > 0 ? value : 80
    }
    set {
      UserDefaults.standard.set(newValue, forKey: qualityKey)
    }
  }

  func apply() {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    for scene in scenes {
      for window in scene.windows {
        window.overrideUserInterfaceStyle = theme.style
      }
    }
  }
}
