import Foundation

struct VideoItem: Equatable {
  var bvid = ""
  var aid: Int64 = 0
  var cid: Int64 = 0
  var mid: Int64 = 0
  var title = ""
  var pic = ""
  var owner = "UP 主"
  var ownerFace = ""
  var duration = "00:00"
  var durationSec = 0
  var play: Int64 = 0
  var playText = "0"
  var desc = ""

  init() {}

  init(json: [String: Any]) {
    bvid = o11a1String(json["bvid"])
    aid = o11a1Int64(json["aid"])
    cid = o11a1Int64(json["cid"])
    mid = o11a1Int64(json["mid"])
    title = o11a1String(json["title"])
    pic = o11a1HTTPS(o11a1String(json["pic"]))
    owner = o11a1String(json["owner"])
    ownerFace = o11a1HTTPS(o11a1String(json["ownerFace"]))
    duration = o11a1String(json["duration"])
    durationSec = o11a1Int(json["durationSec"])
    play = o11a1Int64(json["play"])
    playText = o11a1String(json["playText"])
    desc = o11a1String(json["desc"])
    if title.isEmpty { title = "视频" }
    if owner.isEmpty { owner = "UP 主" }
    if duration.isEmpty { duration = "00:00" }
    if playText.isEmpty { playText = "0" }
  }
}

struct FeedResult {
  var items: [VideoItem] = []
  var page = 1
  var fresh = 1
  var error: String?
}

struct PlaySource {
  var url = ""
  var backup = ""
  var quality = 0
  var qualityLabel = ""
  var cid: Int64 = 0
}

struct AccountInfo {
  var loggedIn = false
  var name = ""
  var face = ""
  var mid: Int64 = 0
  var level = 0
  var vip = false
  var sign = ""
}

struct CommentItem {
  var rpid: Int64 = 0
  var name = ""
  var face = ""
  var message = ""
  var likes = 0
  var time = 0
  var replies = 0
}

enum NativeError: LocalizedError {
  case message(String)
  case cancelled

  var errorDescription: String? {
    switch self {
    case .message(let value): return value
    case .cancelled: return "已取消"
    }
  }
}

func nativeJSON(_ data: Data) -> [String: Any]? {
  guard let object = try? JSONSerialization.jsonObject(with: data) else { return nil }
  return object as? [String: Any]
}

func nativeItems(_ json: [String: Any]) -> [VideoItem] {
  guard let rows = json["items"] as? [[String: Any]] else { return [] }
  return rows.map { VideoItem(json: $0) }
}
