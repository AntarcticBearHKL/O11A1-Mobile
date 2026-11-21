import Foundation
import ExpoModulesCore

public final class O11A1BridgeModule: Module {
  private var server: O11A1LocalServer?

  public func definition() -> ModuleDefinition {
    Name("O11A1Bridge")

    AsyncFunction("start") { (files: [String: String]) -> Int in
      if let existing = self.server {
        return existing.port
      }
      let created = try O11A1LocalServer(files: files)
      try created.start()
      self.server = created
      return created.port
    }

    Function("port") { () -> Int in
      return self.server?.port ?? 0
    }

    Function("testFlow") { () -> String in
      return ProcessInfo.processInfo.environment["O11A1_TEST_FLOW"] ?? ""
    }

    Function("enableHighRefresh") {
      O11A1HighRefresh.shared.enable()
    }

    Function("highRefreshInfo") { () -> [String: Any] in
      return [
        "maxHz": O11A1HighRefresh.shared.maxHz(),
        "compositorFps": O11A1HighRefresh.shared.compositorFps()
      ]
    }
  }
}
