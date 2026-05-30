import SwiftUI
import MetalKit
import CoreImage

// MARK: - Metal renderer

final class NailTryRenderer: NSObject, MTKViewDelegate {

    private let commandQueue: MTLCommandQueue
    let ciContext: CIContext
    private let compositor = NailCompositor()

    var camera: TryCameraManager?

    init?(device: MTLDevice) {
        guard let q = device.makeCommandQueue() else { return nil }
        commandQueue = q
        ciContext     = CIContext(mtlDevice: device, options: [
            .workingColorSpace: NSNull(),
            .useSoftwareRenderer: false
        ])
    }

    // MTKViewDelegate

    func draw(in view: MTKView) {
        guard let camera,
              let frame    = camera.latestFrame,
              let drawable = view.currentDrawable,
              let cmdBuf   = commandQueue.makeCommandBuffer() else { return }

        let regions = camera.latestRegions
        let design  = camera.currentDesign
        let opacity = camera.opacity
        let blend   = camera.blendMode
        let nailScale = camera.nailScale
        let tipOffset = camera.tipOffset

        // Composite
        let composite = compositor.composite(
            frame:     frame,
            regions:   regions,
            design:    design,
            opacity:   opacity,
            blendMode: blend,
            nailScale: nailScale,
            tipOffset: tipOffset
        )

        // Scale composite to drawable size (aspect fill)
        let drawSize  = view.drawableSize
        let frameSize = frame.extent.size
        let scale     = max(drawSize.width / frameSize.width,
                            drawSize.height / frameSize.height)
        let scaledW   = frameSize.width  * scale
        let scaledH   = frameSize.height * scale
        let offsetX   = (drawSize.width  - scaledW) / 2
        let offsetY   = (drawSize.height - scaledH) / 2

        let final = composite.transformed(by:
            CGAffineTransform(scaleX: scale, y: scale)
            .translatedBy(x: offsetX / scale, y: offsetY / scale)
        )

        let bounds = CGRect(origin: .zero, size: drawSize)
        ciContext.render(final,
                         to: drawable.texture,
                         commandBuffer: cmdBuf,
                         bounds: bounds,
                         colorSpace: CGColorSpaceCreateDeviceRGB())

        cmdBuf.present(drawable)
        cmdBuf.commit()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
}

// MARK: - SwiftUI wrapper

struct MetalCameraView: UIViewRepresentable {
    let camera: TryCameraManager

    func makeUIView(context: Context) -> MTKView {
        guard let device = MTLCreateSystemDefaultDevice() else {
            return MTKView()
        }
        let view = MTKView(frame: .zero, device: device)
        view.framebufferOnly  = false
        view.enableSetNeedsDisplay = true
        view.isPaused         = true
        view.clearColor       = MTLClearColorMake(0, 0, 0, 1)

        let renderer = context.coordinator.renderer
        renderer?.camera = camera
        view.delegate = renderer

        camera.onFrameReady = { [weak view] in
            DispatchQueue.main.async { view?.setNeedsDisplay() }
        }
        return view
    }

    func updateUIView(_ uiView: MTKView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        let renderer: NailTryRenderer?
        init() {
            let device = MTLCreateSystemDefaultDevice()
            renderer = device.flatMap { NailTryRenderer(device: $0) }
        }
    }
}
