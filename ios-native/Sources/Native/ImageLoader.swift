import UIKit

final class ImageLoader {
  static let shared = ImageLoader()

  private let cache = NSCache<NSString, UIImage>()
  private let session: URLSession

  private init() {
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 15
    config.requestCachePolicy = .returnCacheDataElseLoad
    config.httpMaximumConnectionsPerHost = 6
    session = URLSession(configuration: config)
    cache.countLimit = 220
    cache.totalCostLimit = 80 * 1024 * 1024
  }

  func load(_ urlString: String, into imageView: UIImageView, placeholder: UIImage? = nil) {
    let key = urlString as NSString
    imageView.image = placeholder
    guard !urlString.isEmpty else { return }
    if let cached = cache.object(forKey: key) {
      imageView.image = cached
      return
    }
    imageView.accessibilityIdentifier = urlString
    guard let url = URL(string: urlString) else { return }
    var request = URLRequest(url: url)
    request.setValue("https://www.bilibili.com/", forHTTPHeaderField: "Referer")
    request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
    session.dataTask(with: request) { [weak self, weak imageView] data, _, _ in
      guard let self = self, let data = data, let image = UIImage(data: data) else { return }
      self.cache.setObject(image, forKey: key, cost: data.count)
      DispatchQueue.main.async {
        guard let imageView = imageView, imageView.accessibilityIdentifier == urlString else { return }
        imageView.image = image
      }
    }.resume()
  }
}
