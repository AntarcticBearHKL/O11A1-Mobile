import Foundation

enum PlaybackLoopMode: String, CaseIterable {
  case off
  case single
  case list

  var title: String {
    switch self {
    case .off: return "不循环"
    case .single: return "单个循环"
    case .list: return "列表循环"
    }
  }

  static var stored: PlaybackLoopMode {
    let raw = UserDefaults.standard.string(forKey: "o11a1.loopMode") ?? ""
    return PlaybackLoopMode(rawValue: raw) ?? .off
  }

  func store() {
    UserDefaults.standard.set(rawValue, forKey: "o11a1.loopMode")
  }

  static func from(title: String) -> PlaybackLoopMode {
    return allCases.first(where: { $0.title == title }) ?? .off
  }
}

enum PlaybackSettings {
  static let qualityOptions = [
    "最高", "4K", "1080P60", "1080P+", "1080P", "720P60", "720P", "480P", "360P",
  ]

  static func qualityName(_ qn: Int) -> String {
    switch qn {
    case 120: return "4K"
    case 116: return "1080P60"
    case 112: return "1080P+"
    case 80: return "1080P"
    case 74: return "720P60"
    case 64: return "720P"
    case 32: return "480P"
    case 16: return "360P"
    default: return "1080P"
    }
  }

  static func qualityValue(_ name: String) -> Int {
    switch name {
    case "4K": return 120
    case "1080P60": return 116
    case "1080P+": return 112
    case "1080P": return 80
    case "720P60": return 74
    case "720P": return 64
    case "480P": return 32
    case "360P": return 16
    default: return ThemeManager.shared.quality
    }
  }

  static func defaultQualityName() -> String {
    if let saved = UserDefaults.standard.string(forKey: "o11a1.defaultQuality"),
       !saved.isEmpty {
      return saved
    }
    return qualityName(ThemeManager.shared.quality)
  }

  static let loopOptions = PlaybackLoopMode.allCases.map { $0.title }
}
