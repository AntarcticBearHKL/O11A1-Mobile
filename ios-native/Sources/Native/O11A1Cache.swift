import Foundation

/// Small thread-safe TTL cache for API payloads. The desktop shell keeps the
/// same short-lived, memory-only caches so opening a page again does not wait
/// on the network; entries are never persisted across launches.
final class O11A1TTLCache<Key: Hashable, Value> {
  private struct Entry {
    let value: Value
    let at: Date
  }

  private var entries: [Key: Entry] = [:]
  private let lock = NSLock()
  private let ttl: TimeInterval
  private let limit: Int

  init(ttl: TimeInterval, limit: Int) {
    self.ttl = ttl
    self.limit = max(1, limit)
  }

  func get(_ key: Key) -> Value? {
    lock.lock()
    defer { lock.unlock() }
    guard let entry = entries[key] else { return nil }
    if Date().timeIntervalSince(entry.at) > ttl {
      entries.removeValue(forKey: key)
      return nil
    }
    return entry.value
  }

  func set(_ key: Key, _ value: Value) {
    lock.lock()
    defer { lock.unlock() }
    if entries.count >= limit, let first = entries.keys.first {
      entries.removeValue(forKey: first)
    }
    entries[key] = Entry(value: value, at: Date())
  }

  func removeAll() {
    lock.lock()
    entries.removeAll()
    lock.unlock()
  }
}
