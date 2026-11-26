import Foundation

extension BiliAPI {
  func popularItems(page: Int, completion: @escaping (Result<[VideoItem], Error>) -> Void) {
    run({ self.client.popular(page: page, ps: 20) }) { result in
      switch result {
      case .failure(let error): completion(.failure(error))
      case .success(let json): completion(.success(nativeItems(json)))
      }
    }
  }


  func bangumi(page: Int, seasonType: Int, completion: @escaping (Result<[VideoItem], Error>) -> Void) {
    run({ self.client.bangumi(page: page, seasonType: seasonType) }) { result in
      switch result {
      case .failure(let error): completion(.failure(error))
      case .success(let json):
        let rows = (json["items"] as? [[String: Any]]) ?? []
        completion(.success(rows.map { VideoItem(json: $0) }))
      }
    }
  }

  func live(page: Int, completion: @escaping (Result<[VideoItem], Error>) -> Void) {
    run({ self.client.live(page: page) }) { result in
      switch result {
      case .failure(let error): completion(.failure(error))
      case .success(let json):
        let rows = (json["items"] as? [[String: Any]]) ?? []
        completion(.success(rows.map { VideoItem(json: $0) }))
      }
    }
  }

  func zone(rid: Int, page: Int, completion: @escaping (Result<[VideoItem], Error>) -> Void) {
    run({ self.client.zone(rid: rid, page: page) }) { result in
      switch result {
      case .failure(let error): completion(.failure(error))
      case .success(let json): completion(.success(nativeItems(json)))
      }
    }
  }

  func messages(page: Int, filter: String, completion: @escaping (Result<[VideoItem], Error>) -> Void) {
    run({ self.client.messages(page: page, filter: filter) }) { result in
      switch result {
      case .failure(let error): completion(.failure(error))
      case .success(let json):
        let rows = (json["items"] as? [[String: Any]]) ?? []
        let mapped = rows.map { row -> VideoItem in
          var item = VideoItem(json: row)
          item.kind = "message"
          return item
        }
        completion(.success(mapped))
      }
    }
  }

  func history(page: Int, cursor: String, completion: @escaping (Result<([VideoItem], String), Error>) -> Void) {
    run({ self.client.history(page: page, cursor: cursor) }) { result in
      switch result {
      case .failure(let error): completion(.failure(error))
      case .success(let json):
        let rows = (json["items"] as? [[String: Any]]) ?? []
        completion(.success((rows.map { VideoItem(json: $0) }, o11a1String(json["next"]))))
      }
    }
  }

  func season(_ seasonId: Int64, completion: @escaping (Result<SeasonResult, Error>) -> Void) {
    run({ self.client.season(seasonId: seasonId) }) { result in
      switch result {
      case .failure(let error): completion(.failure(error))
      case .success(let json):
        var season = SeasonResult()
        season.title = o11a1String(json["title"])
        season.cover = o11a1HTTPS(o11a1String(json["cover"]))
        season.evaluate = o11a1String(json["evaluate"])
        let rows = (json["episodes"] as? [[String: Any]]) ?? []
        season.episodes = rows.map { VideoItem(json: $0) }
        completion(.success(season))
      }
    }
  }

  func playPgc(epId: Int64, bvid: String, cid: Int64, qn: Int, completion: @escaping (Result<PlaySource, Error>) -> Void) {
    run({ self.client.playPgc(epId: epId, bvid: bvid, cid: cid, qn: qn) }) { result in
      self.finishPlay(result, completion)
    }
  }

  func liveRoom(roomId: Int64, completion: @escaping (Result<LiveSource, Error>) -> Void) {
    run({ self.client.liveRoom(roomId: roomId) }) { result in
      switch result {
      case .failure(let error): completion(.failure(error))
      case .success(let json):
        var source = LiveSource()
        source.url = o11a1String(json["url"]).isEmpty ? o11a1String(json["remote"]) : o11a1String(json["url"])
        source.title = o11a1String(json["title"])
        source.owner = o11a1String(json["owner"])
        source.format = o11a1String(json["format"])
        if source.url.isEmpty {
          completion(.failure(NativeError.message("没有可用的直播地址")))
        } else {
          completion(.success(source))
        }
      }
    }
  }

  func danmaku(cid: Int64, completion: @escaping (Result<[DanmakuItem], Error>) -> Void) {
    run({ self.client.danmaku(cid: cid) }) { result in
      switch result {
      case .failure(let error): completion(.failure(error))
      case .success(let json):
        let rows = (json["items"] as? [[String: Any]]) ?? []
        let items = rows.map { row -> DanmakuItem in
          var item = DanmakuItem()
          item.time = (row["t"] as? NSNumber)?.doubleValue ?? 0
          item.text = o11a1String(row["text"])
          item.color = UInt32(max(0, o11a1Int(row["color"])))
          item.mode = o11a1Int(row["mode"])
          return item
        }.filter { !$0.text.isEmpty }
        completion(.success(items))
      }
    }
  }

  func sendDanmaku(cid: Int64, message: String, progressMs: Int64, completion: ((Bool) -> Void)? = nil) {
    run({ self.client.sendDanmaku(cid: cid, message: message, progressMs: progressMs) }) { result in
      if case .failure = result { completion?(false) } else { completion?(true) }
    }
  }

  func aiChat(endpoint: String, apiKey: String, model: String, prompt: String,
              completion: @escaping (Result<String, Error>) -> Void) {
    run({ self.client.aiChat(endpoint: endpoint, apiKey: apiKey, model: model, prompt: prompt) }) { result in
      switch result {
      case .failure(let error): completion(.failure(error))
      case .success(let json):
        let text = o11a1String(json["text"])
        if text.isEmpty { completion(.failure(NativeError.message("AI 返回了空内容"))) }
        else { completion(.success(text)) }
      }
    }
  }
}
