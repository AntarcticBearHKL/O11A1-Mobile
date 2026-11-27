import UIKit

struct BiliShareTarget {
  var bvid: String = ""
  var aid: Int64 = 0
  var part: Int = 1
  var startSeconds: Double = 0
}

/// Watches the pasteboard for Bilibili share text and reports the video it
/// points at. Full/mobile video links, b23.tv and bili2233.cn short links (with
/// or without https), bvid query links and bare BV/av ids are accepted, wrapped
/// in 【title…】 text or not, with ?p= and ?t= support.
final class ClipboardShareWatcher {
  static let shared = ClipboardShareWatcher()
  var onOpen: ((BiliShareTarget) -> Void)?

  private var started = false
  private var resolving = false
  private var lastText = ""
  private var retryText = ""
  private var retryScheduled = false

  func start() {
    guard !started else { return }
    started = true
    NotificationCenter.default.addObserver(
      self, selector: #selector(check),
      name: UIApplication.didBecomeActiveNotification, object: nil)
    NotificationCenter.default.addObserver(
      self, selector: #selector(check),
      name: UIPasteboard.changedNotification, object: nil)
    check()
  }

  func ignore(_ text: String) {
    lastText = text
  }

  @objc private func check() {
    guard UIApplication.shared.applicationState == .active, !resolving else { return }
    guard let raw = UIPasteboard.general.string?
      .trimmingCharacters(in: .whitespacesAndNewlines),
      !raw.isEmpty, raw != lastText,
      let parsed = Self.parse(raw) else { return }
    if let target = parsed.target {
      lastText = raw
      retryText = ""
      DispatchQueue.main.async { [weak self] in self?.onOpen?(target) }
      return
    }
    guard let short = parsed.shortURL else { return }
    resolving = true
    resolveShort(short, raw: raw, depth: 0) { [weak self] target in
      guard let self = self else { return }
      self.resolving = false
      if let target = target {
        self.lastText = raw
        self.retryText = ""
        DispatchQueue.main.async { self.onOpen?(target) }
      } else {
        self.scheduleRetry(raw)
      }
    }
  }

  private func resolveShort(_ url: URL, raw: String, depth: Int,
                            completion: @escaping (BiliShareTarget?) -> Void) {
    ShortShareResolver.shared.resolve(url) { [weak self] resolved in
      guard let self = self, let resolved = resolved,
            let parsed = Self.parse(resolved) else {
        completion(nil)
        return
      }
      if let target = parsed.target {
        completion(target)
        return
      }
      if depth < 2, let next = parsed.shortURL, next != url {
        self.resolveShort(next, raw: raw, depth: depth + 1, completion: completion)
      } else {
        completion(nil)
      }
    }
  }

  /// A short link occasionally fails on the first wake because the network is
  /// still coming up. Retry the same text once, then stop so the paste prompt
  /// cannot loop forever.
  private func scheduleRetry(_ raw: String) {
    if retryText == raw {
      lastText = raw
      retryText = ""
      return
    }
    guard !retryScheduled else { return }
    retryText = raw
    retryScheduled = true
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
      guard let self = self else { return }
      self.retryScheduled = false
      self.check()
    }
  }

  private struct Parsed {
    var target: BiliShareTarget?
    var shortURL: URL?
  }

  private static let fullPattern = try! NSRegularExpression(
    pattern: "(?:https?://)?(?:www\\.|m\\.)?bilibili\\.com/video/(BV[0-9A-Za-z]{10}|av(\\d+))([^\\s【】]*)",
    options: [.caseInsensitive])
  private static let shortPattern = try! NSRegularExpression(
    pattern: "(?:https?://)?(b23\\.tv|bili2233\\.cn)/([A-Za-z0-9]+)(\\?[^\\s【】]*)?",
    options: [.caseInsensitive])
  private static let bvidQueryPattern = try! NSRegularExpression(
    pattern: "[?&]bvid=(BV[0-9A-Za-z]{10})",
    options: [.caseInsensitive])
  private static let bvPattern = try! NSRegularExpression(
    pattern: "\\bBV[0-9A-Za-z]{10}\\b",
    options: [.caseInsensitive])
  private static let avPattern = try! NSRegularExpression(
    pattern: "\\bav(\\d+)\\b",
    options: [.caseInsensitive])

  private static func parse(_ text: String) -> Parsed? {
    if let target = directTarget(text) {
      return Parsed(target: target, shortURL: nil)
    }
    if let short = shortURL(text) {
      if let direct = targetFromShortPath(short) {
        return Parsed(target: direct, shortURL: nil)
      }
      return Parsed(target: nil, shortURL: short)
    }
    return nil
  }

  private static func directTarget(_ text: String) -> BiliShareTarget? {
    if let groups = groups(fullPattern, text), groups.count >= 4 {
      let tail = groups[3]
      let part = queryInt(tail, "p") ?? 1
      let start = startSeconds(tail)
      if groups[1].lowercased().hasPrefix("bv") {
        return BiliShareTarget(bvid: groups[1], aid: 0, part: part, startSeconds: start)
      }
      if let aid = Int64(groups[2]), aid > 0 {
        return BiliShareTarget(bvid: "", aid: aid, part: part, startSeconds: start)
      }
    }
    if let groups = groups(bvidQueryPattern, text), groups.count > 1,
       !groups[1].isEmpty {
      return BiliShareTarget(bvid: groups[1], aid: 0,
                             part: queryInt(text, "p") ?? 1,
                             startSeconds: startSeconds(text))
    }
    if let groups = groups(bvPattern, text), let bvid = groups.first {
      return BiliShareTarget(bvid: bvid, aid: 0,
                             part: queryInt(text, "p") ?? 1,
                             startSeconds: startSeconds(text))
    }
    if let groups = groups(avPattern, text), groups.count > 1,
       let aid = Int64(groups[1]) {
      return BiliShareTarget(bvid: "", aid: aid,
                             part: queryInt(text, "p") ?? 1,
                             startSeconds: startSeconds(text))
    }
    return nil
  }

  private static func shortURL(_ text: String) -> URL? {
    guard let groups = groups(shortPattern, text), groups.count >= 3 else { return nil }
    let host = groups[1].lowercased()
    let path = groups[2]
    let query = groups.count > 3 ? groups[3] : ""
    return URL(string: "https://\(host)/\(path)\(query)")
  }

  private static func targetFromShortPath(_ url: URL) -> BiliShareTarget? {
    let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    if path.range(of: "^BV[0-9A-Za-z]{10}$", options: .regularExpression) != nil {
      return BiliShareTarget(bvid: path, aid: 0,
                             part: queryInt(url.absoluteString, "p") ?? 1,
                             startSeconds: startSeconds(url.absoluteString))
    }
    if path.lowercased().hasPrefix("av"),
       let aid = Int64(path.dropFirst(2)) {
      return BiliShareTarget(bvid: "", aid: aid,
                             part: queryInt(url.absoluteString, "p") ?? 1,
                             startSeconds: startSeconds(url.absoluteString))
    }
    return nil
  }

  private static func groups(_ regex: NSRegularExpression, _ text: String) -> [String]? {
    let range = NSRange(text.startIndex..<text.endIndex, in: text)
    guard let match = regex.firstMatch(in: text, options: [], range: range) else { return nil }
    var values: [String] = []
    for index in 0..<match.numberOfRanges {
      guard let partRange = Range(match.range(at: index), in: text) else {
        values.append("")
        continue
      }
      values.append(String(text[partRange]))
    }
    return values
  }

  private static func queryInt(_ text: String, _ key: String) -> Int? {
    let pattern = "[?&]\(key)=(\\d+)"
    guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
          let groups = groups(regex, text), groups.count > 1,
          let value = Int(groups[1]) else { return nil }
    return value
  }

  private static func startSeconds(_ text: String) -> Double {
    let pattern = "[?&](?:t|start)=([^&#\\s]+)"
    guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
          let groups = groups(regex, text), groups.count > 1 else { return 0 }
    let raw = groups[1].removingPercentEncoding ?? groups[1]
    if let seconds = Double(raw) { return max(0, seconds) }
    let unitRegex = try? NSRegularExpression(pattern: "(\\d+)([hms])",
                                             options: [.caseInsensitive])
    guard let unitRegex = unitRegex else { return 0 }
    let range = NSRange(raw.startIndex..<raw.endIndex, in: raw)
    var total: Double = 0
    for match in unitRegex.matches(in: raw, options: [], range: range) {
      guard let amountRange = Range(match.range(at: 1), in: raw),
            let unitRange = Range(match.range(at: 2), in: raw),
            let amount = Double(raw[amountRange]) else { continue }
      switch raw[unitRange].lowercased() {
      case "h": total += amount * 3600
      case "m": total += amount * 60
      default: total += amount
      }
    }
    return total
  }
}

/// Resolves b23.tv / bili2233.cn short links. It follows the redirect with a
/// tiny ranged GET, returns the final video URL, and falls back to the HTML
/// jump page used by some links. Results are cached for ten minutes, matching
/// the desktop shell's resolver.
final class ShortShareResolver: NSObject, URLSessionDataDelegate {
  static let shared = ShortShareResolver()

  private var completion: ((String?) -> Void)?
  private var requestedURL: URL?
  private var finalURL: URL?
  private var buffer = Data()
  private var session: URLSession!
  private var cache: [String: (value: String, at: Date)] = [:]
  private let maxBytes = 32 * 1024
  private let cacheTTL: TimeInterval = 10 * 60

  override init() {
    super.init()
    let config = URLSessionConfiguration.ephemeral
    config.timeoutIntervalForRequest = 9
    config.timeoutIntervalForResource = 12
    config.httpMaximumConnectionsPerHost = 2
    config.requestCachePolicy = .reloadIgnoringLocalCacheData
    session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
  }

  func resolve(_ url: URL, completion: @escaping (String?) -> Void) {
    let key = url.absoluteString
    if let hit = cache[key], Date().timeIntervalSince(hit.at) < cacheTTL {
      completion(hit.value)
      return
    }
    guard self.completion == nil else {
      completion(nil)
      return
    }
    self.completion = completion
    requestedURL = url
    finalURL = nil
    buffer.removeAll(keepingCapacity: true)

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.timeoutInterval = 9
    request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
                     forHTTPHeaderField: "Accept")
    request.setValue("https://www.bilibili.com/", forHTTPHeaderField: "Referer")
    request.setValue(O11A1BiliClient.desktopUserAgent,
                     forHTTPHeaderField: "User-Agent")
    session.dataTask(with: request).resume()
  }

  func urlSession(_ session: URLSession, dataTask: URLSessionDataTask,
                  didReceive response: URLResponse,
                  completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
    finalURL = response.url
    completionHandler(.allow)
  }

  func urlSession(_ session: URLSession, dataTask: URLSessionDataTask,
                  didReceive data: Data) {
    buffer.append(data)
    if buffer.count >= maxBytes {
      dataTask.cancel()
    }
  }

  func urlSession(_ session: URLSession, task: URLSessionTask,
                  didCompleteWithError error: Error?) {
    guard let block = completion else { return }
    completion = nil
    let rawURL = finalURL?.absoluteString
      ?? task.currentRequest?.url?.absoluteString
      ?? requestedURL?.absoluteString
      ?? ""
    let body = String(data: buffer, encoding: .utf8)
      ?? String(data: buffer, encoding: .isoLatin1)
      ?? ""
    let unescaped = body.replacingOccurrences(of: "\\/", with: "/")
    let bodyCandidate = Self.videoURL(in: unescaped)
    let rawCandidate = Self.videoURL(in: rawURL)
    let candidate: String?
    if let rawCandidate = rawCandidate, Self.isDirectVideo(rawCandidate) {
      candidate = rawCandidate
    } else if let bodyCandidate = bodyCandidate {
      candidate = bodyCandidate
    } else {
      candidate = rawCandidate
    }
    if let candidate = candidate, let requestedURL = requestedURL {
      cache[requestedURL.absoluteString] = (candidate, Date())
      block(candidate)
    } else {
      block(nil)
    }
  }

  private static let videoPattern = try! NSRegularExpression(
    pattern: "https?://[^\\s\"'<>\\\\]*(?:bilibili\\.com/video/(?:BV[0-9A-Za-z]{10}|av\\d+)|(?:b23\\.tv|bili2233\\.cn)/[A-Za-z0-9]+)[^\\s\"'<>\\\\]*",
    options: [.caseInsensitive])
  private static let directPattern = try! NSRegularExpression(
    pattern: "bilibili\\.com/video/(?:BV[0-9A-Za-z]{10}|av\\d+)",
    options: [.caseInsensitive])

  private static func isDirectVideo(_ text: String) -> Bool {
    let range = NSRange(text.startIndex..<text.endIndex, in: text)
    return directPattern.firstMatch(in: text, options: [], range: range) != nil
  }

  private static func videoURL(in text: String) -> String? {
    guard !text.isEmpty else { return nil }
    let range = NSRange(text.startIndex..<text.endIndex, in: text)
    guard let match = videoPattern.firstMatch(in: text, options: [], range: range),
          let part = Range(match.range, in: text) else { return nil }
    return String(text[part])
  }
}
