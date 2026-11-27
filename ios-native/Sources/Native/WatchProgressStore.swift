import Foundation

/// Small local watch-position ledger. Bilibili history only lists the last
/// page a video was opened on; this keeps a resume point for every video,
/// including ones opened from recommendations, related lists and share links.
final class WatchProgressStore {
  static let shared = WatchProgressStore()

  private struct Entry: Codable {
    var seconds: Double
    var duration: Double
    var updated: TimeInterval
  }

  private let lock = NSLock()
  private let storageKey = "o11a1_watch_progress_v1"
  private let maxEntries = 500
  private var entries: [String: Entry] = [:]

  private init() {
    if let data = UserDefaults.standard.data(forKey: storageKey),
       let decoded = try? JSONDecoder().decode([String: Entry].self, from: data) {
      entries = decoded
    }
  }

  func position(for bvid: String) -> Double {
    guard !bvid.isEmpty else { return 0 }
    lock.lock()
    let entry = entries[bvid]
    lock.unlock()
    guard let entry = entry, entry.seconds >= 3 else { return 0 }
    if entry.duration > 0, entry.seconds >= entry.duration - 8 {
      return 0
    }
    return entry.seconds
  }

  func update(bvid: String, seconds: Double, duration: Double) {
    guard !bvid.isEmpty, seconds.isFinite, seconds >= 3 else { return }
    let finished = duration > 0 && seconds >= duration - 8
    lock.lock()
    if finished {
      entries.removeValue(forKey: bvid)
    } else {
      entries[bvid] = Entry(seconds: max(0, seconds),
                            duration: max(0, duration),
                            updated: Date().timeIntervalSince1970)
      if entries.count > maxEntries {
        let overflow = entries.count - maxEntries
        let oldest = entries.sorted { $0.value.updated < $1.value.updated }
          .prefix(overflow)
          .map { $0.key }
        for key in oldest { entries.removeValue(forKey: key) }
      }
    }
    let snapshot = entries
    lock.unlock()
    if let data = try? JSONEncoder().encode(snapshot) {
      UserDefaults.standard.set(data, forKey: storageKey)
    }
  }

  /// Merge server history rows only when this device has no newer local point.
  /// History items carry a server-side progress in seconds.
  func mergeHistory(_ items: [VideoItem]) {
    var changed = false
    lock.lock()
    for item in items {
      guard !item.bvid.isEmpty, item.progress >= 3 else { continue }
      if entries[item.bvid] != nil { continue }
      let duration = Double(item.durationSec)
      if duration > 0, Double(item.progress) >= duration - 8 { continue }
      entries[item.bvid] = Entry(seconds: Double(item.progress),
                                 duration: duration,
                                 updated: Date().timeIntervalSince1970)
      changed = true
    }
    let snapshot = entries
    lock.unlock()
    if changed, let data = try? JSONEncoder().encode(snapshot) {
      UserDefaults.standard.set(data, forKey: storageKey)
    }
  }
}
