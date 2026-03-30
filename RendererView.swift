import SwiftUI
import MetalKit
import CoreVideo
import CoreMedia

final class CaptureHub {
    static let shared = CaptureHub()
    private let lock = NSLock()
    private(set) var pixelBuffer: CVPixelBuffer?
    func update(_ pb: CVPixelBuffer) { lock.lock(); pixelBuffer = pb; lock.unlock() }
    func take() -> CVPixelBuffer? { lock.lock(); defer { lock.unlock() }; return pixelBuffer }
}

struct RendererView: NSViewRepresentable {
    func makeNSView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = MTLCreateSystemDefaultDevice()
        view.colorPixelFormat = .bgra8Unorm
        view.framebufferOnly = false
        view.preferredFramesPerSecond = 60
        let coordinator = context.coordinator
        coordinator.configure(view: view)
        return view
    }

    func updateNSView(_ nsView: MTKView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        private var renderer: SimpleRenderer?
        private var timer: Timer?

        func configure(view: MTKView) {
            renderer = SimpleRenderer(view: view)
            self.timer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
                guard let self, let pb = CaptureHub.shared.take() else { return }
                self.renderer?.update(with: pb)
            }
        }
    }
}

final class SimpleRenderer: NSObject, MTKViewDelegate {
    private let view: MTKView
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue

    private var latestTexture: MTLTexture?
    private var textureCache: CVMetalTextureCache?

    init(view: MTKView) {
        self.view = view
        self.device = view.device ?? MTLCreateSystemDefaultDevice()!
        self.commandQueue = device.makeCommandQueue()!
        super.init()
        var cache: CVMetalTextureCache?
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &cache)
        self.textureCache = cache
        self.view.delegate = self
    }

    func update(with pixelBuffer: CVPixelBuffer) {
        guard let cache = textureCache else { return }
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        var cvTex: CVMetalTexture?
        let status = CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault, cache, pixelBuffer, nil, .bgra8Unorm, width, height, 0, &cvTex)
        if status == kCVReturnSuccess, let cvTex, let tex = CVMetalTextureGetTexture(cvTex) {
            self.latestTexture = tex
        }
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let passDescriptor = view.currentRenderPassDescriptor else { return }

        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: passDescriptor)

        if let src = latestTexture {
            if let blit = commandBuffer.makeBlitCommandEncoder() {
                let w = min(src.width, drawable.texture.width)
                let h = min(src.height, drawable.texture.height)
                blit.copy(from: src,
                          sourceSlice: 0,
                          sourceLevel: 0,
                          sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
                          sourceSize: MTLSize(width: w, height: h, depth: 1),
                          to: drawable.texture,
                          destinationSlice: 0,
                          destinationLevel: 0,
                          destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0))
                blit.endEncoding()
            }
        }

        encoder?.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
