import Foundation
import Metal
import MetalKit
import CoreVideo
import QuartzCore

/// Metal pass: YUV/BGRA frame pair -> blend -> CAS-like adaptive sharpen.
final class MetalRenderer: NSObject, MTKViewDelegate {
  let device: MTLDevice
  private let commandQueue: MTLCommandQueue
  private var pipeline: MTLRenderPipelineState?
  private var textureCache: CVMetalTextureCache?

  weak var engine: PlayerEngine?
  var interpolationEnabled = true
  var enhanceEnabled = true
  private(set) var framesDrawn = 0

  private struct Uniforms {
    var weight: Float
    var strength: Float
    var texelX: Float
    var texelY: Float
  }

  override init() {
    guard let device = MTLCreateSystemDefaultDevice(),
          let queue = device.makeCommandQueue() else {
      fatalError("Metal is not available on this device")
    }
    self.device = device
    self.commandQueue = queue
    super.init()

    var cache: CVMetalTextureCache?
    if CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &cache) == kCVReturnSuccess {
      textureCache = cache
    }
    buildPipeline()
  }

  private func buildPipeline() {
    let source = """
    #include <metal_stdlib>
    using namespace metal;

    struct VertexOut {
      float4 position [[position]];
      float2 uv;
    };

    vertex VertexOut o11a1_vertex(uint vid [[vertex_id]],
                                  constant float2 &scale [[buffer(0)]]) {
      float2 positions[4] = {
        float2(-1.0, -1.0),
        float2(1.0, -1.0),
        float2(-1.0, 1.0),
        float2(1.0, 1.0)
      };
      float2 uvs[4] = {
        float2(0.0, 1.0),
        float2(1.0, 1.0),
        float2(0.0, 0.0),
        float2(1.0, 0.0)
      };
      VertexOut out;
      out.position = float4(positions[vid] * scale, 0.0, 1.0);
      out.uv = uvs[vid];
      return out;
    }

    struct Uniforms {
      float weight;
      float strength;
      float texelX;
      float texelY;
    };

    fragment float4 o11a1_fragment(VertexOut in [[stage_in]],
                                   texture2d<float> previous [[texture(0)]],
                                   texture2d<float> current [[texture(1)]],
                                   constant Uniforms &u [[buffer(0)]]) {
      constexpr sampler linearSampler(filter::linear, address::clamp_to_edge);
      float3 a = previous.sample(linearSampler, in.uv).rgb;
      float3 b = current.sample(linearSampler, in.uv).rgb;
      float3 color = mix(a, b, u.weight);

      if (u.strength > 0.0) {
        float2 dx = float2(u.texelX, 0.0);
        float2 dy = float2(0.0, u.texelY);
        float3 n = mix(previous.sample(linearSampler, in.uv - dy).rgb,
                       current.sample(linearSampler, in.uv - dy).rgb, u.weight);
        float3 s = mix(previous.sample(linearSampler, in.uv + dy).rgb,
                       current.sample(linearSampler, in.uv + dy).rgb, u.weight);
        float3 e = mix(previous.sample(linearSampler, in.uv + dx).rgb,
                       current.sample(linearSampler, in.uv + dx).rgb, u.weight);
        float3 w = mix(previous.sample(linearSampler, in.uv - dx).rgb,
                       current.sample(linearSampler, in.uv - dx).rgb, u.weight);

        float3 mn = min(min(n, s), min(e, w));
        float3 mx = max(max(n, s), max(e, w));
        float3 amp = clamp(min(mn, float3(1.0) - mx) / max(mx, float3(0.0001)), 0.0, 1.0);
        float3 blur = (n + s + e + w) * 0.25;
        color += (color - blur) * (0.55 + amp * u.strength);
      }

      return float4(clamp(color, 0.0, 1.0), 1.0);
    }
    """

    do {
      let library = try device.makeLibrary(source: source, options: nil)
      let descriptor = MTLRenderPipelineDescriptor()
      descriptor.vertexFunction = library.makeFunction(name: "o11a1_vertex")
      descriptor.fragmentFunction = library.makeFunction(name: "o11a1_fragment")
      descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
      pipeline = try device.makeRenderPipelineState(descriptor: descriptor)
    } catch {
      pipeline = nil
      NSLog("O11A1 Metal pipeline failed: \(error)")
    }
  }

  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    // The vertex scale is recomputed on every draw.
  }

  func draw(in view: MTKView) {
    guard let drawable = view.currentDrawable,
          let passDescriptor = view.currentRenderPassDescriptor,
          let commandBuffer = commandQueue.makeCommandBuffer() else {
      return
    }

    passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1)
    passDescriptor.colorAttachments[0].loadAction = .clear
    passDescriptor.colorAttachments[0].storeAction = .store

    guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescriptor) else {
      commandBuffer.present(drawable)
      commandBuffer.commit()
      return
    }

    framesDrawn += 1

    if let pipeline,
       let engine,
       let snapshot = engine.snapshot(now: CACurrentMediaTime()),
       let previous = makeTexture(snapshot.previous),
       let current = makeTexture(snapshot.current) {
      let pixelWidth = max(1, CVPixelBufferGetWidth(snapshot.current))
      let pixelHeight = max(1, CVPixelBufferGetHeight(snapshot.current))
      let drawableWidth = max(1.0, view.drawableSize.width)
      let drawableHeight = max(1.0, view.drawableSize.height)
      let viewAspect = Float(drawableWidth / drawableHeight)
      let videoAspect = Float(pixelWidth) / Float(pixelHeight)

      var scale = SIMD2<Float>(1, 1)
      if viewAspect > videoAspect {
        scale.x = videoAspect / viewAspect
      } else {
        scale.y = viewAspect / videoAspect
      }

      var uniforms = Uniforms(
        weight: interpolationEnabled ? snapshot.alpha : 0,
        strength: enhanceEnabled ? 0.6 : 0,
        texelX: 1.0 / Float(pixelWidth),
        texelY: 1.0 / Float(pixelHeight)
      )

      encoder.setRenderPipelineState(pipeline)
      encoder.setVertexBytes(&scale, length: MemoryLayout<SIMD2<Float>>.stride, index: 0)
      encoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 0)
      encoder.setFragmentTexture(previous.0, index: 0)
      encoder.setFragmentTexture(current.0, index: 1)
      encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)

      // Keep the CVMetalTexture wrappers alive until the GPU is done.
      commandBuffer.addCompletedHandler { _ in
        _ = previous.1
        _ = current.1
      }
    }

    encoder.endEncoding()
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }

  private func makeTexture(_ buffer: CVPixelBuffer) -> (MTLTexture, CVMetalTexture)? {
    guard let textureCache else {
      return nil
    }
    let width = CVPixelBufferGetWidth(buffer)
    let height = CVPixelBufferGetHeight(buffer)
    var cvTexture: CVMetalTexture?
    let status = CVMetalTextureCacheCreateTextureFromImage(
      kCFAllocatorDefault,
      textureCache,
      buffer,
      nil,
      .bgra8Unorm,
      width,
      height,
      0,
      &cvTexture
    )
    guard status == kCVReturnSuccess,
          let cvTexture,
          let texture = CVMetalTextureGetTexture(cvTexture) else {
      return nil
    }
    return (texture, cvTexture)
  }
}
