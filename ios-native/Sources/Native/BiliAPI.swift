import Foundation

final class BiliAPI {
  static let shared = BiliAPI()

  let client = O11A1BiliClient()
  private let queue = DispatchQueue(label: "o11a1.api", qos: .userInitiated, attributes: .concurrent)
  private let playCache = O11A1TTLCache<String, PlaySource>(ttl: 300, limit: 48)
  private let infoCache = O11A1TTLCache<String, [String: Any]>(ttl: 600, limit: 64)
  private let relatedCache = O11A1TTLCache<String, [VideoItem]>(ttl: 300, limit: 32)
  private let commentsCache = O11A1TTLCache<String, [CommentItem]>(ttl: 120, limit: 24)
  private let feedCache = O11A1TTLCache<String, FeedResult>(ttl: 180, limit: 16)
  private let prefetchLock = NSLock()
  private var prefetching = Set<String>()

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
        completion(.failure(NativeError.message("接口返回异常")))
        }
        return
      }
      let ok = (json["ok"] as? Bool) ?? ((json["ok"] as? NSNumber)?.boolValue ?? false)
      if !ok {
        let message = o11a1String(json["error"])
        DispatchQueue.main.async {
          completion(.failure(NativeError.message(message.isEmpty ? "请求失败" : message)))
        }
        return
      }
      DispatchQueue.main.async { completion(.success(json)) }
    }
  }

  func recommend(page: Int, fresh: Int, completion: @escaping (Result<FeedResult, Error>) -> Void) {
    let key = "recommend:\(page):\(fresh)"
    if let cached = feedCache.get(key) {
      DispatchQueue.main.async { completion(.success(cached)) }
      return
    }
    run({ self.client.recommend(page: page, ps: 20, fresh: fresh) }) { result in
      switch result {
      case .failure(let error):
        completion(.failure(error))
      case .success(let json):
        var feed = FeedResult()
        feed.items = nativeItems(json)
        feed.page = o11a1Int(json["page"])
        feed.fresh = o11a1Int(json["fresh"])
        self.feedCache.set(key, feed)
        completion(.success(feed))
      }
    }
  }

  func prefetchRecommend(page: Int, fresh: Int) {
    let key = "recommend:\(page):\(fresh)"
    if feedCache.get(key) != nil { return }
    prefetchLock.lock()
    if prefetching.contains(key) {
      prefetchLock.unlock()
      return
    }
    prefetching.insert(key)
    prefetchLock.unlock()
    recommend(page: page, fresh: fresh) { [weak self] _ in
      guard let self = self else { return }
      self.prefetchLock.lock()
      self.prefetching.remove(key)
      self.prefetchLock.unlock()
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

  private func playKey(_ item: VideoItem, qn: Int) -> String {
    return "\(item.bvid):\(item.cid):\(qn)"
  }

  func playLow(_ item: VideoItem, completion: @escaping (Result<PlaySource, Error>) -> Void) {
    let key = playKey(item, qn: 16)
    if let cached = playCache.get(key) {
      DispatchQueue.main.async { completion(.success(cached)) }
      return
    }
    run({ self.client.playLow(bvid: item.bvid, cid: item.cid) }) { result in
      self.finishPlay(result, cacheKey: key, completion)
    }
  }

  func playQuality(_ item: VideoItem, qn: Int, completion: @escaping (Result<PlaySource, Error>) -> Void) {
    let key = playKey(item, qn: qn)
    if let cached = playCache.get(key) {
      DispatchQueue.main.async { completion(.success(cached)) }
      return
    }
    run({ self.client.playQuality(bvid: item.bvid, cid: item.cid, qn: qn) }) { result in
      self.finishPlay(result, cacheKey: key, completion)
    }
  }

  /// Warm a signed play URL in the background. The feed calls this for the
  /// rows just below the viewport, so both the next preview and the player's
  /// full-quality request can skip the playurl round-trip.
  func prefetchPlayQuality(_ item: VideoItem, qn: Int) {
    guard !item.bvid.isEmpty else { return }
    let key = playKey(item, qn: qn)
    if playCache.get(key) != nil { return }
    prefetchLock.lock()
    if prefetching.contains(key) {
      prefetchLock.unlock()
      return
    }
    prefetching.insert(key)
    prefetchLock.unlock()
    playQuality(item, qn: qn) { [weak self] _ in
      guard let self = self else { return }
      self.prefetchLock.lock()
      self.prefetching.remove(key)
      self.prefetchLock.unlock()
    }
  }

  func finishPlay(
    _ result: Result<[String: Any], Error>,
    cacheKey: String? = nil,
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
        completion(.failure(NativeError.message("没有可播放地址")))
      } else {
        if let cacheKey = cacheKey {
          playCache.set(cacheKey, source)
        }
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
          completion(.failure(NativeError.message("二维码生成失败")))
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
    let key = "bvid:\(bvid)"
    if let cached = infoCache.get(key) {
      DispatchQueue.main.async { completion(.success(cached)) }
      return
    }
    run({ self.client.videoInfo(bvid: bvid) }) { result in
      if case .success(let json) = result {
        self.infoCache.set(key, json)
      }
      completion(result)
    }
  }

  func videoInfo(aid: Int64, completion: @escaping (Result<[String: Any], Error>) -> Void) {
    let key = "aid:\(aid)"
    if let cached = infoCache.get(key) {
      DispatchQueue.main.async { completion(.success(cached)) }
      return
    }
    run({ self.client.videoInfo(aid: aid) }) { result in
      if case .success(let json) = result {
        self.infoCache.set(key, json)
      }
      completion(result)
    }
  }

  func prefetchVideoInfo(bvid: String) {
    guard !bvid.isEmpty else { return }
    let key = "bvid:\(bvid)"
    if infoCache.get(key) != nil { return }
    prefetchLock.lock()
    if prefetching.contains(key) {
      prefetchLock.unlock()
      return
    }
    prefetching.insert(key)
    prefetchLock.unlock()
    videoInfo(bvid) { [weak self] _ in
      guard let self = self else { return }
      self.prefetchLock.lock()
      self.prefetching.remove(key)
      self.prefetchLock.unlock()
    }
  }

  func related(_ bvid: String, completion: @escaping (Result<[VideoItem], Error>) -> Void) {
    let key = "related:\(bvid)"
    if let cached = relatedCache.get(key) {
      DispatchQueue.main.async { completion(.success(cached)) }
      return
    }
    run({ self.client.related(bvid: bvid) }) { result in
      switch result {
      case .failure(let error): completion(.failure(error))
      case .success(let json):
        let items = nativeItems(json)
        self.relatedCache.set(key, items)
        completion(.success(items))
      }
    }
  }

  func prefetchRelated(_ bvid: String) {
    guard !bvid.isEmpty else { return }
    let key = "related:\(bvid)"
    if relatedCache.get(key) != nil { return }
    prefetchLock.lock()
    if prefetching.contains(key) {
      prefetchLock.unlock()
      return
    }
    prefetching.insert(key)
    prefetchLock.unlock()
    related(bvid) { [weak self] _ in
      guard let self = self else { return }
      self.prefetchLock.lock()
      self.prefetching.remove(key)
      self.prefetchLock.unlock()
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

  func dynamicTimeline(
    page: Int,
    filter: String,
    completion: @escaping (Result<([DynamicItem], Bool), Error>) -> Void
  ) {
    run({ self.client.dynamicFeed(page: page, filter: filter) }) { result in
      switch result {
      case .failure(let error):
        completion(.failure(error))
      case .success(let json):
        let rows = (json["items"] as? [[String: Any]]) ?? []
        let hasMore = (json["hasMore"] as? Bool) ?? (rows.count >= 20)
        completion(.success((rows.map { DynamicItem(json: $0) }, hasMore)))
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

  func reportHistory(aid: Int64, cid: Int64, progress: Int) {
    guard aid > 0, cid > 0, isLoggedIn else { return }
    run({ self.client.reportHistory(aid: aid, cid: cid, progress: progress) }) { _ in }
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

  struct UpProfilePage {
    var items: [VideoItem] = []
    var name = ""
    var face = ""
    var sign = ""
    var follower: Int64 = 0
    var followed = false
    var hasMore = false
    var page = 1
  }

  func upPage(mid: Int64, page: Int, order: String,
              completion: @escaping (Result<UpProfilePage, Error>) -> Void) {
    run({ self.client.space(mid: mid, page: page, order: order) }) { result in
      switch result {
      case .failure(let error):
        completion(.failure(error))
      case .success(let json):
        var up = UpProfilePage()
        up.items = nativeItems(json)
        up.name = o11a1String(json["name"])
        up.face = o11a1HTTPS(o11a1String(json["face"]))
        up.sign = o11a1String(json["sign"])
        up.follower = o11a1Int64(json["follower"])
        up.followed = (json["followed"] as? Bool)
          ?? ((json["followed"] as? NSNumber)?.boolValue ?? false)
        up.hasMore = (json["hasMore"] as? Bool)
          ?? ((json["hasMore"] as? NSNumber)?.boolValue ?? false)
        up.page = o11a1Int(json["page"])
        completion(.success(up))
      }
    }
  }

  func comments(aid: Int64, page: Int, sort: Int = 2,
                completion: @escaping (Result<[CommentItem], Error>) -> Void) {
    let key = "comments:\(aid):\(page):\(sort)"
    if let cached = commentsCache.get(key) {
      DispatchQueue.main.async { completion(.success(cached)) }
      return
    }
    run({ self.client.comments(aid: aid, page: page, sort: sort) }) { result in
      switch result {
      case .failure(let error): completion(.failure(error))
      case .success(let json):
        let items = self.commentItems(json)
        self.commentsCache.set(key, items)
        completion(.success(items))
      }
    }
  }

  func commentReplies(aid: Int64, root: Int64, page: Int,
                      completion: @escaping (Result<[CommentItem], Error>) -> Void) {
    run({ self.client.commentsReplies(aid: aid, root: root, page: page) }) { result in
      switch result {
      case .failure(let error): completion(.failure(error))
      case .success(let json): completion(.success(self.commentItems(json)))
      }
    }
  }

  private func commentItems(_ json: [String: Any]) -> [CommentItem] {
    let rows = (json["items"] as? [[String: Any]]) ?? []
    return rows.map { row -> CommentItem in
      var item = CommentItem()
      item.rpid = o11a1Int64(row["rpid"])
      item.name = o11a1String(row["user"])
      item.face = o11a1HTTPS(o11a1String(row["avatar"]))
      item.message = o11a1String(row["message"])
      if let map = row["emotes"] as? [String: Any] {
        for (key, value) in map {
          if let url = value as? String, !url.isEmpty {
            item.emotes[key] = url
          }
        }
      }
      item.likes = o11a1Int(row["like"])
      item.time = o11a1Int(row["time"])
      item.replies = o11a1Int(row["rcount"])
      if item.name.isEmpty { item.name = "用户" }
      return item
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
      if case .failure = result {
        completion?(false)
      } else {
        self.commentsCache.removeAll()
        completion?(true)
      }
    }
  }

  func logout() {
    queue.async { _ = self.client.logout() }
  }
}
