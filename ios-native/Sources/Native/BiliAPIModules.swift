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
        season.episodes = rows.enumerated().map { index, row -> VideoItem in
          var item = VideoItem(json: row)
          item.duration = moduleEpisodeDuration(item.duration)
          item.meta = "第 \(index + 1) 话"
          return item
        }
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

  func liveHistory(roomId: Int64, completion: @escaping (Result<[LiveMessage], Error>) -> Void) {
    run({ self.client.liveHistory(roomId: roomId) }) { result in
      switch result {
      case .failure(let error):
        completion(.failure(error))
      case .success(let json):
        let rows = (json["items"] as? [[String: Any]]) ?? []
        let items = rows.map { row -> LiveMessage in
          var item = LiveMessage()
          item.user = o11a1String(row["user"])
          item.text = o11a1String(row["text"])
          item.time = o11a1String(row["time"])
          if item.user.isEmpty { item.user = "观众" }
          return item
        }.filter { !$0.text.isEmpty }
        completion(.success(items))
      }
    }
  }

  func searchHot(completion: @escaping (Result<[String], Error>) -> Void) {
    run({ self.client.searchHot() }) { result in
      switch result {
      case .failure(let error):
        completion(.failure(error))
      case .success(let json):
        let rows = (json["items"] as? [[String: Any]]) ?? []
        let values = rows.compactMap { row -> String? in
          let keyword = o11a1String(row["keyword"])
          return keyword.isEmpty ? nil : keyword
        }
        completion(.success(values))
      }
    }
  }

  func memberCenter(completion: @escaping (Result<MemberInfo, Error>) -> Void) {
    run({ self.client.memberCenter() }) { result in
      switch result {
      case .failure(let error):
        completion(.failure(error))
      case .success(let json):
        var info = MemberInfo()
        info.vip = (json["vip"] as? Bool) ?? false
        info.vipType = o11a1Int(json["vipType"])
        info.vipDue = o11a1Int64(json["vipDue"])
        let tasks = (json["tasks"] as? [[String: Any]]) ?? []
        info.tasks = tasks.map { row -> MemberTask in
          var task = MemberTask()
          task.label = o11a1String(row["label"])
          task.detail = o11a1String(row["detail"])
          task.done = (row["done"] as? Bool) ?? false
          task.reward = o11a1Int(row["reward"])
          return task
        }
        let logs = (json["log"] as? [[String: Any]]) ?? []
        info.log = logs.map { row -> MemberLog in
          var entry = MemberLog()
          entry.delta = o11a1Int(row["delta"])
          entry.reason = o11a1String(row["reason"])
          entry.time = o11a1String(row["time"])
          return entry
        }
        completion(.success(info))
      }
    }
  }

  func liveDanmuInfo(roomId: Int64,
                     completion: @escaping (Result<(String, String, Int), Error>) -> Void) {
    run({ self.client.liveDanmuInfo(roomId: roomId) }) { result in
      switch result {
      case .failure(let error):
        completion(.failure(error))
      case .success(let json):
        let token = o11a1String(json["token"])
        let host = o11a1String(json["host"])
        let port = o11a1Int(json["wssPort"])
        if token.isEmpty || host.isEmpty {
          completion(.failure(NativeError.message("直播弹幕信息为空")))
        } else {
          completion(.success((token, host, port <= 0 ? 443 : port)))
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

private func moduleEpisodeDuration(_ raw: String) -> String {
  guard let value = Int64(raw), value > 10_000 else { return raw }
  let total = value / 1000
  let hours = total / 3600
  let minutes = (total % 3600) / 60
  let seconds = total % 60
  if hours > 0 {
    return String(format: "%d:%02d:%02d", hours, minutes, seconds)
  }
  return String(format: "%02d:%02d", minutes, seconds)
}
