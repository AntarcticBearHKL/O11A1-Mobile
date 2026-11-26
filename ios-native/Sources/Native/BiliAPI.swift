import Foundation

final class BiliAPI {
  static let shared = BiliAPI()

  let client = O11A1BiliClient()
  private let queue = DispatchQueue(label: "o11a1.api", qos: .userInitiated, attributes: .concurrent)

  var isLoggedIn: Bool { client.hasSession() }
  var mediaHeaders: [String: String] { client.mediaHeaders() }

  func run(
    _ work: @escaping () -> Data,
    _ completion: @escaping (Result<[String: Any], Error>) -> Void
  ) {
    queue.async {
      let data = work()
      guard let json = nativeJSON(data) else {
        DispatchQueue.main.async {
          completion(.failure(NativeError.message("鎺ュ彛杩斿洖寮傚父")))
        }
        return
      }
      let ok = (json["ok"] as? Bool) ?? ((json["ok"] as? NSNumber)?.boolValue ?? false)
      if !ok {
        let message = o11a1String(json["error"])
        DispatchQueue.main.async {
          completion(.failure(NativeError.message(message.isEmpty ? "璇锋眰澶辫触" : message)))
        }
        return
      }
      DispatchQueue.main.async { completion(.success(json)) }
    }
  }

  func recommend(page: Int, fresh: Int, completion: @escaping (Result<FeedResult, Error>) -> Void) {
    run({ self.client.recommend(page: page, ps: 20, fresh: fresh) }) { result in
      switch result {
      case .failure(let error):
        completion(.failure(error))
      case .success(let json):
        var feed = FeedResult()
        feed.items = nativeItems(json)
        feed.page = o11a1Int(json["page"])
        feed.fresh = o11a1Int(json["fresh"])
        completion(.success(feed))
      }
    }
  }

  func popular(page: Int, completion: @escaping (Result<FeedResult, Error>) -> Void) {
    run({ self.client.popular(page: page, ps: 20) }) { result in
      switch result {
      case .failure(let error):
        completion(.failure(error))
      case .success(let json):
        var feed = FeedResult()
        feed.items = nativeItems(json)
        feed.page = o11a1Int(json["page"])
        completion(.success(feed))
      }
    }
  }

  func search(_ keyword: String, page: Int, completion: @escaping (Result<[VideoItem], Error>) -> Void) {
    run({ self.client.search(keyword: keyword, page: page) }) { result in
      switch result {
      case .failure(let error): completion(.failure(error))
      case .success(let json): completion(.success(nativeItems(json)))
      }
    }
  }

  func suggest(_ term: String, completion: @escaping ([String]) -> Void) {
    queue.async {
      let data = self.client.suggest(term: term)
      let json = nativeJSON(data) ?? [:]
      let rows = (json["items"] as? [[String: Any]]) ?? []
      let values = rows.compactMap { o11a1String($0["value"]) }.filter { !$0.isEmpty }
      DispatchQueue.main.async { completion(values) }
    }
  }

  func playLow(_ item: VideoItem, completion: @escaping (Result<PlaySource, Error>) -> Void) {
    run({ self.client.playLow(bvid: item.bvid, cid: item.cid) }) { result in
      self.finishPlay(result, completion)
    }
  }

  func playQuality(_ item: VideoItem, qn: Int, completion: @escaping (Result<PlaySource, Error>) -> Void) {
    run({ self.client.playQuality(bvid: item.bvid, cid: item.cid, qn: qn) }) { result in
      self.finishPlay(result, completion)
    }
  }

  func finishPlay(
    _ result: Result<[String: Any], Error>,
    _ completion: @escaping (Result<PlaySource, Error>) -> Void
  ) {
    switch result {
    case .failure(let error):
      completion(.failure(error))
    case .success(let json):
      var source = PlaySource()
      source.url = o11a1String(json["url"]).isEmpty ? o11a1String(json["remote"]) : o11a1String(json["url"])
      source.backup = o11a1String(json["backup"]).isEmpty ? o11a1String(json["backupRemote"]) : o11a1String(json["backup"])
      source.quality = o11a1Int(json["quality"])
      source.qualityLabel = o11a1String(json["qualityLabel"])
      source.cid = o11a1Int64(json["cid"])
      if source.url.isEmpty {
        completion(.failure(NativeError.message("娌℃湁鍙挱鏀惧湴鍧€")))
      } else {
        completion(.success(source))
      }
    }
  }

  func qrGenerate(completion: @escaping (Result<(String, String), Error>) -> Void) {
    run({ self.client.qrGenerate() }) { result in
      switch result {
      case .failure(let error):
        completion(.failure(error))
      case .success(let json):
        let url = o11a1String(json["url"])
        let key = o11a1String(json["key"])
        if url.isEmpty || key.isEmpty {
          completion(.failure(NativeError.message("浜岀淮鐮佺敓鎴愬け璐?)))
        } else {
          completion(.success((url, key)))
        }
      }
    }
  }

  func qrPoll(key: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
    run({ self.client.qrPoll(key: key) }, completion)
  }

  func videoInfo(_ bvid: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
    run({ self.client.videoInfo(bvid: bvid) }, completion)
  }

  func related(_ bvid: String, completion: @escaping (Result<[VideoItem], Error>) -> Void) {
    run({ self.client.related(bvid: bvid) }) { result in
      switch result {
      case .failure(let error): completion(.failure(error))
      case .success(let json): completion(.success(nativeItems(json)))
      }
    }
  }

  func account(completion: @escaping (AccountInfo) -> Void) {
    run({ self.client.account() }) { result in
      var info = AccountInfo()
      if case .success(let json) = result {
        info.loggedIn = (json["loggedIn"] as? Bool) ?? false
        info.name = o11a1String(json["name"])
        info.face = o11a1HTTPS(o11a1String(json["face"]))
        info.mid = o11a1Int64(json["mid"])
        info.level = o11a1Int(json["level"])
        info.vip = (json["vip"] as? Bool) ?? false
        info.sign = o11a1String(json["sign"])
      }
      completion(info)
    }
  }

  func following(page: Int, completion: @escaping (Result<[VideoItem], Error>) -> Void) {
    run({ self.client.following(page: page) }) { result in
      switch result {
      case .failure(let error): completion(.failure(error))
      case .success(let json): completion(.success(nativeItems(json)))
      }
    }
  }

  func dynamicFeed(page: Int, completion: @escaping (Result<[VideoItem], Error>) -> Void) {
    run({ self.client.dynamicFeed(page: page, filter: "all") }) { result in
      switch result {
      case .failure(let error): completion(.failure(error))
      case .success(let json): completion(.success(nativeItems(json)))
      }
    }
  }

  func favorites(page: Int, completion: @escaping (Result<[VideoItem], Error>) -> Void) {
    run({ self.client.favorites(page: page) }) { result in
      switch result {
      case .failure(let error): completion(.failure(error))
      case .success(let json): completion(.success(nativeItems(json)))
      }
    }
  }

  func history(page: Int, completion: @escaping (Result<[VideoItem], Error>) -> Void) {
    run({ self.client.history(page: page, cursor: "") }) { result in
      switch result {
      case .failure(let error): completion(.failure(error))
      case .success(let json): completion(.success(nativeItems(json)))
      }
    }
  }

  func ranking(page: Int, completion: @escaping (Result<[VideoItem], Error>) -> Void) {
    run({ self.client.ranking(page: page) }) { result in
      switch result {
      case .failure(let error): completion(.failure(error))
      case .success(let json): completion(.success(nativeItems(json)))
      }
    }
  }

  func space(mid: Int64, page: Int, completion: @escaping (Result<[VideoItem], Error>) -> Void) {
    run({ self.client.space(mid: mid, page: page, order: "pubdate") }) { result in
      switch result {
      case .failure(let error): completion(.failure(error))
      case .success(let json): completion(.success(nativeItems(json)))
      }
    }
  }

  func comments(aid: Int64, page: Int, completion: @escaping (Result<[CommentItem], Error>) -> Void) {
    run({ self.client.comments(aid: aid, page: page) }) { result in
      switch result {
      case .failure(let error): completion(.failure(error))
      case .success(let json):
        let rows = (json["items"] as? [[String: Any]]) ?? []
        let items = rows.map { row -> CommentItem in
          var item = CommentItem()
          item.rpid = o11a1Int64(row["rpid"])
          item.name = o11a1String(row["name"])
          item.face = o11a1HTTPS(o11a1String(row["face"]))
          item.message = o11a1String(row["message"])
          item.likes = o11a1Int(row["like"])
          item.time = o11a1Int(row["time"])
          item.replies = o11a1Int(row["count"])
          return item
        }
        completion(.success(items))
      }
    }
  }

  func like(aid: Int64, on: Bool, completion: ((Bool) -> Void)? = nil) {
    run({ self.client.like(aid: aid, on: on) }) { result in
      if case .failure = result { completion?(false) } else { completion?(true) }
    }
  }

  func coin(aid: Int64, completion: ((Bool) -> Void)? = nil) {
    run({ self.client.coin(aid: aid, count: 1, likeAlso: true) }) { result in
      if case .failure = result { completion?(false) } else { completion?(true) }
    }
  }

  func favorite(aid: Int64, on: Bool, completion: ((Bool) -> Void)? = nil) {
    run({ self.client.favorite(aid: aid, on: on) }) { result in
      if case .failure = result { completion?(false) } else { completion?(true) }
    }
  }

  func follow(mid: Int64, on: Bool, completion: ((Bool) -> Void)? = nil) {
    run({ self.client.follow(mid: mid, on: on) }) { result in
      if case .failure = result { completion?(false) } else { completion?(true) }
    }
  }

  func sendComment(aid: Int64, message: String, completion: ((Bool) -> Void)? = nil) {
    run({ self.client.sendComment(aid: aid, message: message) }) { result in
      if case .failure = result { completion?(false) } else { completion?(true) }
    }
  }

  func logout() {
    queue.async { _ = self.client.logout() }
  }
}
