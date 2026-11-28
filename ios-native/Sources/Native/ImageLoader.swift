import UIKit

final class ImageLoader {
  static let shared = ImageLoader()

  private let cache = NSCache<NSString, UIImage>()
  private let session: URLSession
  private let diskDirectory: URL?
  private let diskQueue = DispatchQueue(label: "o11a1.image.disk", qos: .utility)

  private init() {
    let base = FileManager.default.urls(for: .cachesDirectory,
                                        in: .userDomainMask).first
    let directory = base?.appendingPathComponent("O11A1ImageCache",
                                                  isDirectory: true)
    if let directory = directory {
      try? FileManager.default.createDirectory(at: directory,
                                               withIntermediateDirectories: true)
    }
    diskDirectory = directory

    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 15
    config.requestCachePolicy = .returnCacheDataElseLoad
    config.httpMaximumConnectionsPerHost = 6
    session = URLSession(configuration: config)
    cache.countLimit = 220
    cache.totalCostLimit = 80 * 1024 * 1024
    pruneDiskCache()
  }

  func load(_ urlString: String, into imageView: UIImageView, placeholder: UIImage? = nil) {
    let key = urlString as NSString
    imageView.accessibilityIdentifier = urlString
    imageView.image = placeholder
    guard !urlString.isEmpty else { return }
    if let cached = cache.object(forKey: key) {
      imageView.image = cached
      return
    }
    if let diskURL = diskURL(for: urlString) {
      diskQueue.async { [weak self, weak imageView] in
        guard let self = self,
              let data = try? Data(contentsOf: diskURL),
              let image = UIImage(data: data) else { return }
        self.cache.setObject(image, forKey: key, cost: data.count)
        DispatchQueue.main.async {
          guard let imageView = imageView,
                imageView.accessibilityIdentifier == urlString else { return }
          imageView.image = image
        }
      }
    }
    guard let url = URL(string: urlString) else { return }
    var request = URLRequest(url: url)
    request.setValue("https://www.bilibili.com/", forHTTPHeaderField: "Referer")
    request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
    session.dataTask(with: request) { [weak self, weak imageView] data, _, _ in
      guard let self = self, let data = data, let image = UIImage(data: data) else { return }
      self.cache.setObject(image, forKey: key, cost: data.count)
      if let diskURL = self.diskURL(for: urlString) {
        self.diskQueue.async {
          try? data.write(to: diskURL, options: .atomic)
        }
      }
      DispatchQueue.main.async {
        guard let imageView = imageView, imageView.accessibilityIdentifier == urlString else { return }
        imageView.image = image
      }
    }.resume()
  }

  func cachedImage(_ urlString: String) -> UIImage? {
    guard !urlString.isEmpty else { return nil }
    return cache.object(forKey: urlString as NSString)
  }

  func clearMemory() {
    cache.removeAllObjects()
  }

  /// Load an image without binding it to a view. Used by inline comment
  /// emotes, which need a `UIImage` for an NSTextAttachment.
  func loadImage(_ urlString: String, completion: @escaping (UIImage?) -> Void) {
    guard !urlString.isEmpty else {
      DispatchQueue.main.async { completion(nil) }
      return
    }
    let key = urlString as NSString
    if let cached = cache.object(forKey: key) {
      DispatchQueue.main.async { completion(cached) }
      return
    }
    if let diskURL = diskURL(for: urlString) {
      diskQueue.async { [weak self] in
        guard let self = self,
              let data = try? Data(contentsOf: diskURL),
              let image = UIImage(data: data) else { return }
        self.cache.setObject(image, forKey: key, cost: data.count)
        DispatchQueue.main.async { completion(image) }
      }
    }
    guard let url = URL(string: urlString) else {
      DispatchQueue.main.async { completion(nil) }
      return
    }
    var request = URLRequest(url: url)
    request.setValue("https://www.bilibili.com/", forHTTPHeaderField: "Referer")
    request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
    session.dataTask(with: request) { [weak self] data, _, _ in
      guard let self = self, let data = data, let image = UIImage(data: data) else {
        DispatchQueue.main.async { completion(nil) }
        return
      }
      self.cache.setObject(image, forKey: key, cost: data.count)
      if let diskURL = self.diskURL(for: urlString) {
        self.diskQueue.async {
          try? data.write(to: diskURL, options: .atomic)
        }
      }
      DispatchQueue.main.async { completion(image) }
    }.resume()
  }

  private func diskURL(for urlString: String) -> URL? {
    guard let directory = diskDirectory else { return nil }
    var hash: UInt64 = 1469598103934665603
    for byte in urlString.utf8 {
      hash ^= UInt64(byte)
      hash = hash &* 1099511628211
    }
    return directory.appendingPathComponent(String(hash, radix: 16) + ".img")
  }

  private func pruneDiskCache() {
    guard let directory = diskDirectory else { return }
    diskQueue.async {
      let cutoff = Date().addingTimeInterval(-30 * 24 * 60 * 60)
      let keys: Set<URLResourceKey> = [.contentModificationDateKey]
      guard let files = try? FileManager.default.contentsOfDirectory(
        at: directory, includingPropertiesForKeys: Array(keys)) else { return }
      for file in files {
        guard let values = try? file.resourceValues(forKeys: keys),
              let modified = values.contentModificationDate else { continue }
        if modified < cutoff {
          try? FileManager.default.removeItem(at: file)
        }
      }
    }
  }
}
