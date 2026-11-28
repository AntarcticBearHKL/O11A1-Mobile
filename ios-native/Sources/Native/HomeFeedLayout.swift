import Foundation

enum HomeFeedLayout {
  static let changed = Notification.Name("O11A1HomeFeedLayoutChanged")
  private static let key = "home_feed_grid"
  static var testGrid: Bool?

  static var isGrid: Bool {
    get { testGrid ?? UserDefaults.standard.bool(forKey: key) }
    set { UserDefaults.standard.set(newValue, forKey: key) }
  }
}
