import Foundation

enum DanmakuSettings {
  static let areaPercentKey = "danmaku_area_percent"
  static let legacyAreaKey = "danmaku_area"
  static let defaultAreaPercent: Float = 80
  static let areaStep: Float = 5
  static let areaMinimum: Float = 5
  static let areaMaximum: Float = 100

  /// Percentage of the usable screen height, measured from the top, that may
  /// carry scrolling danmaku. Values are kept on a 5% grid.
  static func areaPercent(defaults: UserDefaults = .standard) -> Float {
    if defaults.object(forKey: areaPercentKey) != nil {
      return snapArea(defaults.float(forKey: areaPercentKey))
    }
    let legacy = defaults.string(forKey: legacyAreaKey)
    let mapped: Float
    switch legacy {
    case "1/3 屏": mapped = 35
    case "1/2 屏": mapped = 50
    default: mapped = defaultAreaPercent
    }
    return snapArea(mapped)
  }

  static func setAreaPercent(_ value: Float, defaults: UserDefaults = .standard) {
    defaults.set(snapArea(value), forKey: areaPercentKey)
    defaults.removeObject(forKey: legacyAreaKey)
  }

  static func snapArea(_ value: Float) -> Float {
    let clamped = max(areaMinimum, min(areaMaximum, value))
    return (clamped / areaStep).rounded() * areaStep
  }
}
