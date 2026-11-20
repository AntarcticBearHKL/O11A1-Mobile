import Foundation
import AVFoundation
import VideoToolbox
import CoreVideo

/// VideoToolbox decode + frame queue. The renderer pulls a previous/current
/// pair from this engine every display tick and blends between them.
final class PlayerEngine {
  struct Snapshot {
    let previous: CVPixelBuffer
    let current: CVPixelBuffer
    let alpha: Float
  }

  struct Stats {
    let hardware: Bool
    let codec: String
    let width: Int
    let height: Int
    let decodedFrames: Int
    let queueDepth: Int
    let error: String
  }

  private final class SessionContext {
    weak var engine: PlayerEngine?
    let generation: Int

    init(engine: PlayerEngine, generation: Int) {
      self.engine = engine
      self.generation = generation
    }
  }

  private struct DecodedFrame {
    let buffer: CVPixelBuffer
    let pts: Double
  }

  private let condition = NSCondition()
  private var frames: [DecodedFrame] = []
  private var baseHost: Double?
  private var basePTS: Double = 0
  private var running = false
  private var generation = 0
  private var currentReader: AVAssetReader?
  private var sourceURL: URL?

  private var hardware = false
  private var codec = "—"
  private var width = 0
  private var height = 0
  private var decoded = 0
  private var errorText = ""

  private let maxAhead = 6

  func start(url: URL) {
    stop()

    condition.lock()
    sourceURL = url
    running = true
    generation += 1
    let activeGeneration = generation
    frames.removeAll()
    baseHost = nil
    basePTS = 0
    decoded = 0
    errorText = ""
    condition.broadcast()
    condition.unlock()

    let thread = Thread { [weak self] in
      self?.run(generation: activeGeneration)
    }
    thread.name = "o11a1-video-decode"
    thread.qualityOfService = .userInteractive
    thread.start()
  }

  func stop() {
    condition.lock()
    running = false
    generation += 1
    let reader = currentReader
    currentReader = nil
    frames.removeAll()
    baseHost = nil
    basePTS = 0
    condition.broadcast()
    condition.unlock()
    reader?.cancelReading()
  }

  func snapshot(now: Double) -> Snapshot? {
    condition.lock()
    defer { condition.unlock() }

    guard !frames.isEmpty else {
      return nil
    }
    if baseHost == nil {
      baseHost = now
      basePTS = frames[0].pts
    }
    guard let baseHost else {
      return nil
    }

    let target = basePTS + (now - baseHost)
    while frames.count >= 2 && frames[1].pts <= target {
      frames.removeFirst()
    }
    condition.broadcast()

    let first = frames[0]
    guard frames.count >= 2 else {
      return Snapshot(previous: first.buffer, current: first.buffer, alpha: 0)
    }
    let second = frames[1]
    let span = max(0.0001, second.pts - first.pts)
    let alpha = Float(min(1.0, max(0.0, (target - first.pts) / span)))
    return Snapshot(previous: first.buffer, current: second.buffer, alpha: alpha)
  }

  func stats() -> Stats {
    condition.lock()
    let snapshot = Stats(
      hardware: hardware,
      codec: codec,
      width: width,
      height: height,
      decodedFrames: decoded,
      queueDepth: frames.count,
      error: errorText
    )
    condition.unlock()
    return snapshot
  }

  // MARK: - Decode thread

  private func run(generation activeGeneration: Int) {
    while isActive(activeGeneration) {
      autoreleasepool {
        do {
          try playOnce(generation: activeGeneration)
        } catch {
          guard isActive(activeGeneration) else {
            return
          }
          setError(error.localizedDescription)
          condition.lock()
          _ = condition.wait(until: Date().addingTimeInterval(1.0))
          condition.unlock()
        }
      }

      guard isActive(activeGeneration) else {
        break
      }

      // Let the display link consume the final frames before the clip loops.
      let deadline = Date().addingTimeInterval(1.2)
      condition.lock()
      while running && generation == activeGeneration && !frames.isEmpty && Date() < deadline {
        _ = condition.wait(until: Date().addingTimeInterval(0.05))
      }
      if running && generation == activeGeneration {
        frames.removeAll()
        baseHost = nil
        basePTS = 0
        condition.broadcast()
        _ = condition.wait(until: Date().addingTimeInterval(0.05))
      }
      condition.unlock()
    }
  }

  private func playOnce(generation activeGeneration: Int) throws {
    guard let sourceURL else {
      throw makeError("no video source")
    }

    let asset = AVURLAsset(url: sourceURL)
    guard let track = asset.tracks(withMediaType: .video).first else {
      throw makeError("video track not found")
    }

    let reader = try AVAssetReader(asset: asset)
    let output = AVAssetReaderTrackOutput(track: track, outputSettings: nil)
    output.alwaysCopiesSampleData = false
    guard reader.canAdd(output) else {
      throw makeError("AVAssetReader rejected the video output")
    }
    reader.add(output)
    guard reader.startReading() else {
      throw reader.error ?? makeError("AVAssetReader did not start")
    }

    condition.lock()
    currentReader = reader
    condition.unlock()

    defer {
      reader.cancelReading()
      condition.lock()
      if currentReader === reader {
        currentReader = nil
      }
      condition.unlock()
    }

    guard let firstSample = output.copyNextSampleBuffer() else {
      throw reader.error ?? makeError("video track is empty")
    }
    let sampleFormat = CMSampleBufferGetFormatDescription(firstSample)
    let trackFormat: CMFormatDescription? = track.formatDescriptions.isEmpty
      ? nil
      : (track.formatDescriptions[0] as! CMFormatDescription)
    guard let format = sampleFormat ?? trackFormat else {
      throw makeError("missing format description (sample and track)")
    }

    let dimensions = CMVideoFormatDescriptionGetDimensions(format)
    let subtype = CMFormatDescriptionGetMediaSubType(format)
    updateInfo(
      width: Int(dimensions.width),
      height: Int(dimensions.height),
      codec: codecName(subtype)
    )

    let context = SessionContext(engine: self, generation: activeGeneration)
    let contextPointer = Unmanaged.passRetained(context).toOpaque()

    let callback: VTDecompressionOutputCallback = { refcon, _, status, _, imageBuffer, pts, _ in
      guard let refcon else {
        return
      }
      let sessionContext = Unmanaged<SessionContext>.fromOpaque(refcon).takeUnretainedValue()
      guard status == noErr, let imageBuffer else {
        return
      }
      sessionContext.engine?.append(
        imageBuffer as CVPixelBuffer,
        pts: pts.seconds,
        generation: sessionContext.generation
      )
    }

    let attributes: [String: Any] = [
      kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
      kCVPixelBufferMetalCompatibilityKey as String: true,
      kCVPixelBufferIOSurfacePropertiesKey as String: [String: Any]()
    ]

    var specification: [String: Any] = [:]
    var canRequireHardware = false
    if #available(iOS 17.0, *) {
      specification[kVTVideoDecoderSpecification_EnableHardwareAcceleratedVideoDecoder as String] = true
      specification[kVTVideoDecoderSpecification_RequireHardwareAcceleratedVideoDecoder as String] = true
      canRequireHardware = true
    }

    var callbackRecord = VTDecompressionOutputCallbackRecord()
    callbackRecord.decompressionOutputRefCon = contextPointer
    callbackRecord.decompressionOutputCallback = callback

    var createdSession: VTDecompressionSession?
    var status = VTDecompressionSessionCreate(
      allocator: kCFAllocatorDefault,
      formatDescription: format,
      decoderSpecification: specification as CFDictionary,
      imageBufferAttributes: attributes as CFDictionary,
      outputCallback: &callbackRecord,
      decompressionSessionOut: &createdSession
    )

    var didFallBack = false
    if status != noErr && canRequireHardware {
      didFallBack = true
      if #available(iOS 17.0, *) {
        specification.removeValue(
          forKey: kVTVideoDecoderSpecification_RequireHardwareAcceleratedVideoDecoder as String
        )
      }
      status = VTDecompressionSessionCreate(
        allocator: kCFAllocatorDefault,
        formatDescription: format,
        decoderSpecification: specification as CFDictionary,
        imageBufferAttributes: attributes as CFDictionary,
        outputCallback: &callbackRecord,
        decompressionSessionOut: &createdSession
      )
    }

    guard status == noErr, let session = createdSession else {
      Unmanaged<SessionContext>.fromOpaque(contextPointer).release()
      throw makeError("VTDecompressionSessionCreate failed (\(status))")
    }
    setHardware(!didFallBack && (canRequireHardware || VTIsHardwareDecodeSupported(subtype)))

    defer {
      VTDecompressionSessionWaitForAsynchronousFrames(session)
      VTDecompressionSessionInvalidate(session)
      Unmanaged<SessionContext>.fromOpaque(contextPointer).release()
    }

    decode(session: session, sample: firstSample)

    while isActive(activeGeneration) {
      guard let sample = output.copyNextSampleBuffer() else {
        break
      }
      waitForSlot(generation: activeGeneration)
      if !isActive(activeGeneration) {
        break
      }
      decode(session: session, sample: sample)
    }

    VTDecompressionSessionWaitForAsynchronousFrames(session)

    if reader.status == .failed, let error = reader.error {
      setError(error.localizedDescription)
    }
  }

  private func decode(session: VTDecompressionSession, sample: CMSampleBuffer) {
    let status = VTDecompressionSessionDecodeFrame(
      session,
      sampleBuffer: sample,
      flags: [._EnableAsynchronousDecompression],
      frameRefcon: nil,
      infoFlagsOut: nil
    )
    if status != noErr {
      setError("VT decode failed (\(status))")
    }
  }

  private func waitForSlot(generation activeGeneration: Int) {
    condition.lock()
    while running && generation == activeGeneration && frames.count >= maxAhead {
      _ = condition.wait(until: Date().addingTimeInterval(0.05))
    }
    condition.unlock()
  }

  fileprivate func append(_ buffer: CVPixelBuffer, pts: Double, generation activeGeneration: Int) {
    condition.lock()
    defer { condition.unlock() }
    guard running && generation == activeGeneration else {
      return
    }

    let frame = DecodedFrame(buffer: buffer, pts: pts)
    if frames.isEmpty || (frames.last?.pts ?? 0) <= pts {
      frames.append(frame)
    } else {
      let index = frames.firstIndex { $0.pts > pts } ?? frames.endIndex
      frames.insert(frame, at: index)
    }
    decoded += 1
    condition.broadcast()
  }

  private func isActive(_ activeGeneration: Int) -> Bool {
    condition.lock()
    let active = running && generation == activeGeneration
    condition.unlock()
    return active
  }

  private func updateInfo(width: Int, height: Int, codec: String) {
    condition.lock()
    self.width = width
    self.height = height
    self.codec = codec
    condition.unlock()
  }

  private func setHardware(_ value: Bool) {
    condition.lock()
    hardware = value
    condition.unlock()
  }

  private func setError(_ message: String) {
    condition.lock()
    errorText = message
    condition.unlock()
  }

  private func codecName(_ subtype: FourCharCode) -> String {
    switch subtype {
    case kCMVideoCodecType_H264:
      return "H.264"
    case kCMVideoCodecType_HEVC:
      return "HEVC"
    default:
      let bytes: [UInt8] = [
        UInt8((subtype >> 24) & 0xff),
        UInt8((subtype >> 16) & 0xff),
        UInt8((subtype >> 8) & 0xff),
        UInt8(subtype & 0xff)
      ]
      return String(bytes: bytes, encoding: .ascii) ?? "video"
    }
  }

  private func makeError(_ message: String) -> NSError {
    return NSError(
      domain: "O11A1Video",
      code: -1,
      userInfo: [NSLocalizedDescriptionKey: message]
    )
  }

  deinit {
    stop()
  }
}
