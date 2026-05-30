import AVFoundation
import Vision
import UIKit
import CoreImage

final class TryCameraManager: NSObject, ObservableObject {

    @Published var hasHand    = false
    @Published var fingerCount = 0

    let session = AVCaptureSession()
    private let videoOutput   = AVCaptureVideoDataOutput()
    private let processingQueue = DispatchQueue(label: "nailtry.camera", qos: .userInitiated)

    private let handPoseRequest: VNDetectHumanHandPoseRequest = {
        let r = VNDetectHumanHandPoseRequest()
        r.maximumHandCount = 2
        return r
    }()

    // Thread-safe storage
    private let lock = NSLock()
    private var _frame:   CIImage?    = nil
    private var _regions: [NailRegion] = []

    var latestFrame:   CIImage?     { lock.withLock { _frame   } }
    var latestRegions: [NailRegion] { lock.withLock { _regions } }

    // Design state (read by compositor on bg thread — simple value types, safe)
    var currentDesign: NailDesign = .solid(UIColor(red: 0.95, green: 0.44, blue: 0.62, alpha: 1))
    var opacity: Float = 0.78
    var blendMode: NailCompositor.BlendMode = .multiply
    var nailScale: CGFloat = 1.0
    var tipOffset: CGFloat = 0.0

    /// Called after each processed frame — trigger MTKView redraw
    var onFrameReady: (() -> Void)?

    // MARK: - Setup

    func setup() {
        session.sessionPreset = .hd1280x720
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input  = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }
        session.addInput(input)
        videoOutput.setSampleBufferDelegate(self, queue: processingQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(videoOutput) { session.addOutput(videoOutput) }
        videoOutput.connection(with: .video)?.videoOrientation = .portrait
    }

    func start() { processingQueue.async { if !self.session.isRunning { self.session.startRunning() } } }
    func stop()  { processingQueue.async { if  self.session.isRunning { self.session.stopRunning()  } } }
}

// MARK: - Sample Buffer Delegate

extension TryCameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let ciImage   = CIImage(cvPixelBuffer: pixelBuffer)
        let imageSize = ciImage.extent.size

        // Vision hand pose
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        try? handler.perform([handPoseRequest])

        var regions: [NailRegion] = []

        if let observations = handPoseRequest.results {
            for obs in observations {
                let pairs: [(VNHumanHandPoseObservation.JointName,
                             VNHumanHandPoseObservation.JointName)] = [
                    (.thumbIP,   .thumbTip),
                    (.indexDIP,  .indexTip),
                    (.middleDIP, .middleTip),
                    (.ringDIP,   .ringTip),
                    (.littleDIP, .littleTip),
                ]

                for (dipName, tipName) in pairs {
                    guard let dip = try? obs.recognizedPoint(dipName),
                          let tip = try? obs.recognizedPoint(tipName),
                          dip.confidence > 0.5, tip.confidence > 0.5 else { continue }

                    let dx = tip.x - dip.x
                    let dy = tip.y - dip.y
                    let lenNorm  = sqrt(dx*dx + dy*dy)
                    let angle    = atan2(dy, dx)

                    // Center at 50% between DIP and Tip
                    let cx = (dip.x + tip.x) * 0.5 * imageSize.width
                    let cy = (dip.y + tip.y) * 0.5 * imageSize.height

                    let heightPx = lenNorm * imageSize.height
                    let widthPx  = heightPx * 0.62

                    regions.append(NailRegion(
                        centerX:  cx,
                        centerY:  cy,
                        widthPx:  widthPx,
                        heightPx: heightPx,
                        angleRad: angle
                    ))
                }
            }
        }

        let count = regions.count
        lock.withLock {
            _frame   = ciImage
            _regions = regions
        }

        DispatchQueue.main.async {
            self.hasHand     = count > 0
            self.fingerCount = count
        }

        onFrameReady?()
    }
}
