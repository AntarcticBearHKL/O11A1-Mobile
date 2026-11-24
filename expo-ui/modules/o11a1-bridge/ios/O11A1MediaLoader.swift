import Foundation
import AVFoundation

/// Streams Bilibili DASH media through AVAssetResourceLoader so every request
/// carries the account's Referer/User-Agent/Cookie headers. AVURLAsset's
/// private header option is not applied to all DASH segment requests on newer
/// iOS builds, which makes the CDN answer 403; the resource loader path always
/// adds them. Bytes are forwarded as they arrive, not buffered in full.
final class O11A1MediaLoader: NSObject, AVAssetResourceLoaderDelegate, URLSessionDataDelegate {

  static let shared = O11A1MediaLoader()

  private final class AssetInfo {
    let url: URL
    let headers: [String: String]
    let contentType: String
    var loggedStatus = false

    init(url: URL, headers: [String: String], contentType: String) {
      self.url = url
      self.headers = headers
      self.contentType = contentType
    }
  }

  private final class RequestContext {
    let request: AVAssetResourceLoadingRequest
    let asset: AssetInfo
    var task: URLSessionDataTask?
    var range: String?
    var logged = false
    var finished = false

    init(request: AVAssetResourceLoadingRequest, asset: AssetInfo) {
      self.request = request
      self.asset = asset
    }
  }

  private let callbackQueue = DispatchQueue(label: "o11a1.media.loader")
  private let lock = NSLock()
  private var assets: [String: AssetInfo] = [:]
  private var contexts: [Int: RequestContext] = [:]

  private lazy var delegateQueue: OperationQueue = {
    let queue = OperationQueue()
    queue.name = "o11a1.media.loader.session"
    queue.maxConcurrentOperationCount = 1
    queue.underlyingQueue = callbackQueue
    return queue
  }()

  private lazy var session: URLSession = {
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 30
    config.timeoutIntervalForResource = 3600
    config.requestCachePolicy = .reloadIgnoringLocalCacheData
    config.httpMaximumConnectionsPerHost = 6
    return URLSession(configuration: config, delegate: self, delegateQueue: delegateQueue)
  }()

  func asset(for url: URL, headers: [String: String], contentType: String) -> AVURLAsset {
    let token = UUID().uuidString.replacingOccurrences(of: "-", with: "")
    lock.lock()
    assets[token] = AssetInfo(url: url, headers: headers, contentType: contentType)
    lock.unlock()
    var components = URLComponents()
    components.scheme = "o11a1media"
    components.host = "asset"
    let ext = url.pathExtension.isEmpty ? "m4s" : url.pathExtension
    components.path = "/\(token).\(ext)"
    guard let customURL = components.url else {
      return AVURLAsset(url: url)
    }
    let asset = AVURLAsset(url: customURL)
    asset.resourceLoader.setDelegate(self, queue: callbackQueue)
    return asset
  }

  private func assetInfo(for url: URL?) -> AssetInfo? {
    guard let url = url, url.scheme == "o11a1media" else { return nil }
    let token = url.deletingPathExtension().lastPathComponent
    guard !token.isEmpty else { return nil }
    lock.lock()
    defer { lock.unlock() }
    return assets[token]
  }

  func resourceLoader(
    _ resourceLoader: AVAssetResourceLoader,
    shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest
  ) -> Bool {
    guard let assetInfo = assetInfo(for: loadingRequest.request.url) else { return false }
    var request = URLRequest(url: assetInfo.url)
    for (key, value) in assetInfo.headers {
      request.setValue(value, forHTTPHeaderField: key)
    }
    var range = "bytes=0-1"
    if let dataRequest = loadingRequest.dataRequest {
      let offset = max(0, dataRequest.requestedOffset)
      let length = max(0, dataRequest.requestedLength)
      if dataRequest.requestsAllDataToEndOfResource || length == 0 {
        range = "bytes=\(offset)-"
      } else {
        range = "bytes=\(offset)-\(offset + Int64(length) - 1)"
      }
    }
    request.setValue(range, forHTTPHeaderField: "Range")
    let task = session.dataTask(with: request)
    let context = RequestContext(request: loadingRequest, asset: assetInfo)
    context.task = task
    context.range = range
    contexts[task.taskIdentifier] = context
    task.resume()
    return true
  }

  func resourceLoader(
    _ resourceLoader: AVAssetResourceLoader,
    didCancel loadingRequest: AVAssetResourceLoadingRequest
  ) {
    guard let entry = contexts.first(where: { $0.value.request === loadingRequest }) else { return }
    entry.value.task?.cancel()
    contexts.removeValue(forKey: entry.key)
  }

  func urlSession(
    _ session: URLSession,
    dataTask: URLSessionDataTask,
    didReceive response: URLResponse,
    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
  ) {
    guard let context = contexts[dataTask.taskIdentifier] else {
      completionHandler(.cancel)
      return
    }
    let http = response as? HTTPURLResponse
    let status = http?.statusCode ?? 0
    if !context.asset.loggedStatus {
      context.asset.loggedStatus = true
      NSLog("[O11A1] media %@ status=%d range=%@ total=%lld",
            context.asset.url.host ?? "?", status, context.range ?? "-",
            response.expectedContentLength)
    }
    if status >= 400 {
      completionHandler(.cancel)
      finish(context, error: NSError(
        domain: "O11A1MediaLoader",
        code: status,
        userInfo: [NSLocalizedDescriptionKey: "media HTTP \(status)"]
      ))
      return
    }
    if status == 200, let dataRequest = context.request.dataRequest,
       dataRequest.requestedOffset > 0, !dataRequest.requestsAllDataToEndOfResource {
      completionHandler(.cancel)
      finish(context, error: NSError(
        domain: "O11A1MediaLoader",
        code: 200,
        userInfo: [NSLocalizedDescriptionKey: "server ignored byte range"]
      ))
      return
    }
    if let info = context.request.contentInformationRequest {
      info.contentType = context.asset.contentType
      var total = response.expectedContentLength
      if let http = http,
         let value = http.value(forHTTPHeaderField: "Content-Range")?
           .split(separator: "/").last,
         let parsed = Int64(value) {
        total = parsed
      }
      if total > 0 {
        info.contentLength = total
      }
      let acceptsRanges = (http?.value(forHTTPHeaderField: "Accept-Ranges")?
        .lowercased().contains("bytes") ?? false) || status == 206
      info.isByteRangeAccessSupported = acceptsRanges
    }
    completionHandler(.allow)
  }

  func urlSession(
    _ session: URLSession,
    dataTask: URLSessionDataTask,
    didReceive data: Data
  ) {
    guard let context = contexts[dataTask.taskIdentifier],
          let dataRequest = context.request.dataRequest else { return }
    dataRequest.respond(with: data)
  }

  func urlSession(
    _ session: URLSession,
    task: URLSessionTask,
    didCompleteWithError error: Error?
  ) {
    guard let context = contexts[task.taskIdentifier] else { return }
    finish(context, error: error)
  }

  func urlSession(
    _ session: URLSession,
    task: URLSessionTask,
    willPerformHTTPRedirection response: HTTPURLResponse,
    newRequest request: URLRequest,
    completionHandler: @escaping (URLRequest?) -> Void
  ) {
    guard let context = contexts[task.taskIdentifier] else {
      completionHandler(request)
      return
    }
    var updated = request
    for (key, value) in context.asset.headers {
      updated.setValue(value, forHTTPHeaderField: key)
    }
    if let range = context.range {
      updated.setValue(range, forHTTPHeaderField: "Range")
    }
    completionHandler(updated)
  }

  private func finish(_ context: RequestContext, error: Error? = nil) {
    guard !context.finished else { return }
    context.finished = true
    if let task = context.task {
      contexts.removeValue(forKey: task.taskIdentifier)
    }
    if let error = error {
      NSLog("[O11A1] media failed %@ %@", context.asset.url.host ?? "?", error.localizedDescription)
      context.request.finishLoading(with: error)
    } else {
      context.request.finishLoading()
    }
  }
}
