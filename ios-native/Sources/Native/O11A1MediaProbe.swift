import Foundation

/// One-byte range probe for a signed media URL. Measures the real CDN time to
/// first byte and warms DNS/TLS before AVPlayer requests the file. The response
/// body is discarded, so this is effectively a preconnect.
enum O11A1MediaProbe {
  static func probe(urlString: String, headers: [String: String]) {
    guard let url = URL(string: urlString), !urlString.isEmpty else { return }
    var request = URLRequest(url: url)
    for (key, value) in headers {
      request.setValue(value, forHTTPHeaderField: key)
    }
    request.setValue("bytes=0-1", forHTTPHeaderField: "Range")
    request.timeoutInterval = 10
    let config = URLSessionConfiguration.ephemeral
    config.timeoutIntervalForRequest = 10
    config.timeoutIntervalForResource = 15
    config.httpMaximumConnectionsPerHost = 2
    config.waitsForConnectivity = false
    let session = URLSession(configuration: config)
    let started = O11A1Trace.now
    session.dataTask(with: request) { data, response, error in
      let http = response as? HTTPURLResponse
      let status = http?.statusCode ?? -1
      let contentRange = http?.value(forHTTPHeaderField: "Content-Range") ?? "-"
      let bytes = data?.count ?? 0
      let failure = error?.localizedDescription ?? ""
      O11A1Trace.mark(
        "probe",
        "host=\(url.host ?? "?") status=\(status) bytes=\(bytes) range=\(contentRange) \(O11A1Trace.since(started)) \(failure)")
      session.finishTasksAndInvalidate()
    }.resume()
  }
}
