import ExpoModulesCore
import VideoToolbox

public final class O11A1VideoModule: Module {
  public func definition() -> ModuleDefinition {
    Name("O11A1Video")

    View(O11A1PlayerView.self) {
      Events("onStats")

      Prop("source") { (view: O11A1PlayerView, source: String) in
        view.videoSource = source
      }

      Prop("interpolation") { (view: O11A1PlayerView, enabled: Bool) in
        view.interpolationEnabled = enabled
      }

      Prop("enhance") { (view: O11A1PlayerView, enabled: Bool) in
        view.enhanceEnabled = enabled
      }

      Prop("targetFps") { (view: O11A1PlayerView, fps: Double) in
        view.targetFps = fps
      }

      Prop("paused") { (view: O11A1PlayerView, paused: Bool) in
        view.paused = paused
      }

      OnViewDidUpdateProps { view in
        view.applyConfiguration()
      }
    }

    AsyncFunction("hardwareDecodeSupport") { () -> [String: Bool] in
      return [
        "h264": VTIsHardwareDecodeSupported(kCMVideoCodecType_H264),
        "hevc": VTIsHardwareDecodeSupported(kCMVideoCodecType_HEVC)
      ]
    }
  }
}
