import Foundation

struct HomeModuleDef {
  let id: String
  let name: String
  let desc: String
  let group: String
  let source: String
  let defaultOn: Bool
}

enum HomeModules {
  static let all: [HomeModuleDef] = [
    HomeModuleDef(id: "recommend", name: "推荐", desc: "首页推荐流与关注动态混排",
                  group: "首页", source: "recommend", defaultOn: true),
    HomeModuleDef(id: "hot", name: "热门", desc: "全站热门视频",
                  group: "首页", source: "hot", defaultOn: false),
    HomeModuleDef(id: "rank", name: "排行", desc: "排行榜与分区榜",
                  group: "首页", source: "rank", defaultOn: false),
    HomeModuleDef(id: "bangumi", name: "番剧", desc: "每日放送 / 番剧索引 / 排行榜",
                  group: "内容", source: "bangumi", defaultOn: true),
    HomeModuleDef(id: "movie", name: "影视", desc: "电影 / 电视剧 / 纪录片 / 综艺",
                  group: "内容", source: "movie", defaultOn: false),
    HomeModuleDef(id: "live", name: "直播", desc: "直播推荐 / 分区 / 房间",
                  group: "内容", source: "live", defaultOn: true),
    HomeModuleDef(id: "zone", name: "分区", desc: "20 个一级分区与最新投稿",
                  group: "内容", source: "zone", defaultOn: false),
    HomeModuleDef(id: "follow", name: "关注", desc: "关注的 UP 主投稿与动态",
                  group: "内容", source: "following", defaultOn: false),
    HomeModuleDef(id: "favorite", name: "收藏", desc: "收藏夹推荐 / 全部收藏夹",
                  group: "内容", source: "favorites", defaultOn: true),
    HomeModuleDef(id: "history", name: "历史", desc: "观看历史与续播进度",
                  group: "内容", source: "history", defaultOn: true),
    HomeModuleDef(id: "dynamic", name: "动态", desc: "全部 / 视频 / 图文",
                  group: "社区", source: "dynamic", defaultOn: false),
    HomeModuleDef(id: "fish", name: "养鱼", desc: "AI 看片 / 试验台 / 设置",
                  group: "社区", source: "fish", defaultOn: false),
  ]

  private static let statesKey = "o11a1.home.modules"
  private static let currentKey = "o11a1.home.moduleId"

  static var states: [String: Bool] {
    get {
      if let saved = UserDefaults.standard.dictionary(forKey: statesKey) as? [String: Bool] {
        var result = defaults
        for (key, value) in saved { result[key] = value }
        return result
      }
      return defaults
    }
    set {
      UserDefaults.standard.set(newValue, forKey: statesKey)
    }
  }

  static var defaults: [String: Bool] {
    var result: [String: Bool] = [:]
    for module in all { result[module.id] = module.defaultOn }
    return result
  }

  static var currentId: String? {
    get {
      let stored = UserDefaults.standard.string(forKey: currentKey)
      return stored?.isEmpty == false ? stored : "recommend"
    }
    set {
      UserDefaults.standard.set(newValue ?? "", forKey: currentKey)
    }
  }

  static func def(_ id: String?) -> HomeModuleDef? {
    guard let id = id else { return nil }
    return all.first { $0.id == id }
  }

  static var currentDef: HomeModuleDef? {
    let states = states
    var id = currentId
    if id == nil || states[id!] != true {
      id = all.first { states[$0.id] == true }?.id
      currentId = id
    }
    guard let found = id else { return nil }
    return def(found)
  }

  static var enabledCount: Int {
    all.filter { states[$0.id] == true }.count
  }

  /// Toggle one module and keep the current module valid.
  @discardableResult
  static func setOn(_ id: String, _ on: Bool) -> Bool {
    var states = self.states
    states[id] = on
    self.states = states
    var current = currentId
    var changed = false
    if on && current == nil {
      current = id
      currentId = id
      changed = true
    }
    if !on && current == id {
      current = all.first { states[$0.id] == true }?.id
      currentId = current
      changed = true
    }
    return changed
  }
}
