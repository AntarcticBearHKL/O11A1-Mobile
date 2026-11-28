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
  var pubdate: Int64 = 0
  var desc = ""
  var kind = "video"
  var seasonId: Int64 = 0
  var roomId: Int64 = 0
  var epId: Int64 = 0
  var user = ""
  var avatar = ""
  var text = ""
  var time: Int64 = 0
  var meta = ""
  var badge = ""
  var progress: Int64 = 0
  var unread = false

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
    pubdate = o11a1Int64(json["pubdate"])
    desc = o11a1String(json["desc"])
    kind = o11a1String(json["kind"]).isEmpty ? "video" : o11a1String(json["kind"])
    seasonId = o11a1Int64(json["seasonId"])
    roomId = o11a1Int64(json["roomId"])
    epId = o11a1Int64(json["epId"])
    user = o11a1String(json["user"])
    avatar = o11a1HTTPS(o11a1String(json["avatar"]))
    text = o11a1String(json["text"])
    time = o11a1Int64(json["time"])
    meta = o11a1String(json["meta"])
    badge = o11a1String(json["badge"])
    progress = o11a1Int64(json["progress"])
    if let value = json["unread"] as? Bool {
      unread = value
    } else if let value = json["unread"] as? NSNumber {
      unread = value.boolValue
    }
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

struct DynamicItem {
  var id = ""
  var kind = ""
  var author = "用户"
  var avatar = ""
  var mid: Int64 = 0
  var time: Int64 = 0
  var text = ""
  var images: [String] = []
  var likes = 0
  var comments = 0
  var video: VideoItem?

  init() {}

  init(json: [String: Any]) {
    id = o11a1String(json["id"])
    kind = o11a1String(json["kind"])
    author = o11a1String(json["author"])
    avatar = o11a1HTTPS(o11a1String(json["avatar"]))
    mid = o11a1Int64(json["mid"])
    time = o11a1Int64(json["time"])
    text = o11a1String(json["text"])
    likes = o11a1Int(json["likes"])
    comments = o11a1Int(json["comments"])
    if let rows = json["images"] as? [String] {
      images = rows.filter { !$0.isEmpty }
    } else if let rows = json["images"] as? [Any] {
      images = rows.compactMap { o11a1String($0) }.filter { !$0.isEmpty }
    }
    if let payload = json["video"] as? [String: Any] {
      video = VideoItem(json: payload)
    }
    if author.isEmpty { author = "用户" }
  }
}

struct PlaySource {
  var url = ""
  var backup = ""
  var quality = 0
  var qualityLabel = ""
  var cid: Int64 = 0
}

struct VideoPage: Equatable {
  var cid: Int64 = 0
  var page = 1
  var title = ""
  var duration = 0
}

/// A low-resolution stream that is already playing in the feed preview, handed
/// to the player so it can start from the same frame while the full-quality
/// stream is fetched and preloaded.
struct PreviewHandoff {
  var url = ""
  var backup = ""
  var seconds: Double = 0
  var duration: Double = 0
  var quality = 0
  var qualityLabel = ""
  var engine: VideoEngine?
}

struct FavoriteFolder {
  var id: Int64 = 0
  var title = ""
  var count = 0
}

struct SearchUser {
  var mid: Int64 = 0
  var name = ""
  var face = ""
  var fans = ""
}

struct SearchBangumi {
  var seasonId: Int64 = 0
  var title = ""
  var cover = ""
  var subtitle = ""
}

enum SearchEntry {
  case video(VideoItem)
  case user(SearchUser)
  case bangumi(SearchBangumi)
}

enum SearchType: String, CaseIterable {
  case all = "video"
  case bangumi = "media_bangumi"
  case user = "bili_user"

  var title: String {
    switch self {
    case .all: return "综合"
    case .bangumi: return "番剧"
    case .user: return "用户"
    }
  }
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
  var emotes: [String: String] = [:]
  var images: [String] = []
}

struct LiveSource {
  var url = ""
  var title = ""
  var owner = ""
  var format = ""
}

struct DanmakuItem {
  var time: Double = 0
  var text = ""
  var color: UInt32 = 0xFFFFFF
  var mode = 1
}

struct SeasonResult {
  var title = ""
  var cover = ""
  var evaluate = ""
  var episodes: [VideoItem] = []
}

struct MemberTask {
  var label = ""
  var detail = ""
  var done = false
  var reward = 0
}

struct MemberLog {
  var delta = 0
  var reason = ""
  var time = ""
}

struct MemberInfo {
  var vip = false
  var vipType = 0
  var vipDue: Int64 = 0
  var tasks: [MemberTask] = []
  var log: [MemberLog] = []
}

struct LiveMessage {
  var user = ""
  var text = ""
  var time = ""
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
