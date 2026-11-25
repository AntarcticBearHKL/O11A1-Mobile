import Foundation
import Compression
import UIKit

/// Small box used by synchronous URLSession calls.
final class O11A1Box<T>: @unchecked Sendable {
  var value: T?
}

func o11a1String(_ value: Any?) -> String {
  if let text = value as? String { return text }
  if let number = value as? NSNumber { return number.stringValue }
  return ""
}

func o11a1Int(_ value: Any?) -> Int {
  if let number = value as? Int { return number }
  if let number = value as? NSNumber { return number.intValue }
  if let text = value as? String { return Int(text) ?? 0 }
  return 0
}

func o11a1Int64(_ value: Any?) -> Int64 {
  if let number = value as? Int64 { return number }
  if let number = value as? NSNumber { return number.int64Value }
  if let text = value as? String { return Int64(text) ?? 0 }
  return 0
}

func o11a1Bool(_ value: Any?) -> Bool {
  if let flag = value as? Bool { return flag }
  if let number = value as? NSNumber { return number.boolValue }
  return false
}

func o11a1Data(_ object: [String: Any]) -> Data {
  if let data = try? JSONSerialization.data(withJSONObject: object, options: []) {
    return data
  }
  return Data("{\"ok\":false,\"error\":\"json\"}".utf8)
}

func o11a1Error(_ message: String) -> Data {
  return o11a1Data(["ok": false, "error": message])
}

func o11a1HTTPS(_ raw: String) -> String {
  if raw.hasPrefix("//") { return "https:" + raw }
  if raw.hasPrefix("http://") {
    return "https://" + String(raw.dropFirst("http://".count))
  }
  return raw
}

func o11a1DecodeEntities(_ raw: String) -> String {
  var text = raw
  text = text.replacingOccurrences(of: "&lt;", with: "<")
  text = text.replacingOccurrences(of: "&gt;", with: ">")
  text = text.replacingOccurrences(of: "&quot;", with: "\"")
  text = text.replacingOccurrences(of: "&#39;", with: "'")
  text = text.replacingOccurrences(of: "&nbsp;", with: " ")
  text = text.replacingOccurrences(of: "&amp;", with: "&")
  return text
}

func o11a1StripHTML(_ raw: String) -> String {
  let plain = raw.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
  return o11a1DecodeEntities(plain)
}

func o11a1Duration(_ seconds: Int) -> String {
  let total = max(0, seconds)
  let hours = total / 3600
  let minutes = (total % 3600) / 60
  let remainder = total % 60
  if hours > 0 { return String(format: "%d:%02d:%02d", hours, minutes, remainder) }
  return String(format: "%02d:%02d", minutes, remainder)
}

func o11a1DurationSeconds(_ text: String) -> Int {
  if text.isEmpty { return 0 }
  var total = 0
  for part in text.split(separator: ":") {
    guard let value = Int(part.trimmingCharacters(in: .whitespaces)) else { return 0 }
    total = total * 60 + value
  }
  return total
}

func o11a1Count(_ value: Int64) -> String {
  if value >= 100_000_000 { return String(format: "%.1f 亿", Double(value) / 100_000_000) }
  if value >= 10_000 { return String(format: "%.1f 万", Double(value) / 10_000) }
  return "\(value)"
}

func o11a1QualityLabel(_ quality: Int) -> String {
  switch quality {
  case 127: return "8K"
  case 126: return "杜比"
  case 125: return "HDR"
  case 120: return "4K"
  case 116: return "1080P60"
  case 112: return "1080P+"
  case 80: return "1080P"
  case 74: return "720P60"
  case 64: return "720P"
  case 32: return "480P"
  case 16: return "360P"
  case 6: return "240P"
  default: return "\(quality)P"
  }
}

func o11a1Base64URLEncode(_ data: Data) -> String {
  return data.base64EncodedString()
    .replacingOccurrences(of: "+", with: "-")
    .replacingOccurrences(of: "/", with: "_")
    .replacingOccurrences(of: "=", with: "")
}

func o11a1Base64URLDecode(_ text: String) -> Data? {
  var value = text.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
  while value.count % 4 != 0 { value += "=" }
  return Data(base64Encoded: value)
}

func o11a1Inflate(_ data: Data) -> Data? {
  guard data.count > 6 else { return nil }
  let bytes = [UInt8](data)
  let zlibWrapped = bytes[0] == 0x78 && ((Int(bytes[0]) * 256 + Int(bytes[1])) % 31 == 0)
  let payload: Data
  if zlibWrapped {
    payload = data.subdata(in: 2..<(data.count - 4))
  } else {
    payload = data
  }
  let capacity = max(payload.count * 20, 1_048_576)
  var output = Data(count: capacity)
  let written = output.withUnsafeMutableBytes { destination -> Int in
    guard let destinationBase = destination.bindMemory(to: UInt8.self).baseAddress else { return 0 }
    return payload.withUnsafeBytes { source -> Int in
      guard let sourceBase = source.bindMemory(to: UInt8.self).baseAddress else { return 0 }
      return compression_decode_buffer(
        destinationBase,
        capacity,
        sourceBase,
        payload.count,
        nil,
        COMPRESSION_ZLIB
      )
    }
  }
  guard written > 0 else { return nil }
  return Data(output.prefix(written))
}

enum O11A1Orientation {
  static func apply(_ mode: String) {
    if #available(iOS 16.0, *) {
      guard let scene = UIApplication.shared.connectedScenes
        .compactMap({ $0 as? UIWindowScene })
        .first else { return }
      let mask: UIInterfaceOrientationMask
      switch mode {
      case "landscape-left": mask = .landscapeLeft
      case "landscape-right": mask = .landscapeRight
      default: mask = .portrait
      }
      let preferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: mask)
      scene.requestGeometryUpdate(preferences) { _ in }
      if let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
        root.setNeedsUpdateOfSupportedInterfaceOrientations()
      }
    } else {
      let value: UIInterfaceOrientation
      switch mode {
      case "landscape-left": value = .landscapeLeft
      case "landscape-right": value = .landscapeRight
      default: value = .portrait
      }
      UIDevice.current.setValue(value.rawValue, forKey: "orientation")
      UIViewController.attemptRotationToDeviceOrientation()
    }
  }
}
