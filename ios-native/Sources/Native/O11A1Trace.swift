import Foundation

/// Lightweight load-timing marks. Only used on cold paths (opening a video,
/// fetching a play URL), never on a render loop.
enum O11A1Trace {
  private static var start: TimeInterval { ProcessInfo.processInfo.systemUptime }

  static func mark(_ area: String, _ message: @autoclosure () -> String) {
    NSLog("[O11A1TRACE] %8.3f %@ %@", start, area, message())
  }

  static func since(_ time: TimeInterval) -> String {
    String(format: "%.0fms", (start - time) * 1000)
  }

  static var now: TimeInterval { start }
}
