import Foundation

/// Tiny persistent cache used by the profile/settings heroes so their text and
/// avatar can render on the first frame instead of waiting for the network.
struct CachedUpProfile: Codable {
  var mid: Int64 = 0
  var name = ""
  var face = ""
  var sign = ""
  var follower: Int64 = 0
  var followed = false
  var updatedAt: TimeInterval = 0
}

struct CachedAccount: Codable {
  var loggedIn = false
  var name = ""
  var face = ""
  var mid: Int64 = 0
  var level = 0
  var vip = false
  var sign = ""
  var updatedAt: TimeInterval = 0
}

enum ProfileCache {
  private static let upPrefix = "o11a1.cache.up."
  private static let accountKey = "o11a1.cache.account"

  static func loadUp(mid: Int64) -> CachedUpProfile? {
    guard mid > 0,
          let data = UserDefaults.standard.data(forKey: upPrefix + "\(mid)"),
          let profile = try? JSONDecoder().decode(CachedUpProfile.self, from: data),
          profile.mid == mid else { return nil }
    return profile
  }

  static func saveUp(_ profile: CachedUpProfile) {
    guard profile.mid > 0,
          let data = try? JSONEncoder().encode(profile) else { return }
    UserDefaults.standard.set(data, forKey: upPrefix + "\(profile.mid)")
  }

  static func loadAccount() -> CachedAccount? {
    guard let data = UserDefaults.standard.data(forKey: accountKey),
          let account = try? JSONDecoder().decode(CachedAccount.self, from: data) else {
      return nil
    }
    return account
  }

  static func saveAccount(_ account: CachedAccount) {
    guard let data = try? JSONEncoder().encode(account) else { return }
    UserDefaults.standard.set(data, forKey: accountKey)
  }

  static func clearAccount() {
    UserDefaults.standard.removeObject(forKey: accountKey)
  }
}
