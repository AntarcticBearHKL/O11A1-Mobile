import UIKit

struct BiliShareTarget {
  var bvid: String = ""
  var aid: Int64 = 0
  var part: Int = 1
  var startSeconds: Double = 0
}

/// Watches the pasteboard for Bilibili share text and reports the video it
/// points at. Mirrors the desktop parser: full/mobile video links, b23.tv and
/// bili2233.cn short links (with or without https), bvid query links, bare
/// BV/av ids, wrapped in 【title】 text, with ?p= and ?t= support.
final class ClipboardShareWatcher {
  static let shared = ClipboardShareWatcher()
  var onOpen: ((BiliShareTarget) -> Void)?

  private var started = false
  private var resolving = false
  private var lastText = ""

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
    lastText = raw
    if let short = parsed.shortURL {
      resolving = true
      ShortShareResolver.shared.resolve(short) { [weak self] resolved in
        guard let self = self else { return }
        self.resolving = false
        if let resolved = resolved, let target = Self.parse(resolved)?.target {
          DispatchQueue.main.async { self.onOpen?(target) }
        }
      }
    } else if let target = parsed.target {
      onOpen?(target)
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

/// Resolves a b23.tv / bili2233.cn short link by reading its first redirect
/// without downloading the video page.
final class ShortShareResolver: NSObject, URLSessionTaskDelegate {
  static let shared = ShortShareResolver()
  private var completion: ((String?) -> Void)?
  private var session: URLSession!

  override init() {
    super.init()
    let configuration = URLSessionConfiguration.ephemeral
    configuration.timeoutIntervalForRequest = 10
    session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
  }

  func resolve(_ url: URL, completion: @escaping (String?) -> Void) {
    self.completion = completion
    var request = URLRequest(url: url)
    request.httpMethod = "HEAD"
    request.timeoutInterval = 10
    request.setValue(
      "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) "
        + "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
      forHTTPHeaderField: "User-Agent")
    session.dataTask(with: request).resume()
  }

  func urlSession(_ session: URLSession, task: URLSessionTask,
                  willPerformHTTPRedirection response: HTTPURLResponse,
                  newRequest request: URLRequest,
                  completionHandler: @escaping (URLRequest?) -> Void) {
    let block = completion
    completion = nil
    block?(request.url?.absoluteString)
    completionHandler(nil)
  }

  func urlSession(_ session: URLSession, task: URLSessionTask,
                  didCompleteWithError error: Error?) {
    guard let block = completion else { return }
    completion = nil
    block(task.currentRequest?.url?.absoluteString
      ?? task.originalRequest?.url?.absoluteString)
  }
}
