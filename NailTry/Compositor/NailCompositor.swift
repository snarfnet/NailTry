import UIKit
import CoreImage

// MARK: - Nail Region

struct NailRegion {
    let centerX: CGFloat    // pixel coords (CIImage space, bottom-left origin)
    let centerY: CGFloat
    let widthPx: CGFloat
    let heightPx: CGFloat
    let angleRad: CGFloat   // finger direction angle
}

// MARK: - Compositor

final class NailCompositor {

    // Mask cache keyed by quantized region params
    private var maskCache: [String: CIImage] = [:]

    // MARK: - Main entry

    func composite(
        frame: CIImage,
        regions: [NailRegion],
        design: NailDesign,
        opacity: Float,
        blendMode: BlendMode = .multiply,
        nailScale: CGFloat = 1.0,
        tipOffset: CGFloat = 0.0
    ) -> CIImage {
        guard !regions.isEmpty,
              let designCI = design.ciImage(size: frame.extent.size) else { return frame }

        // Adjust design opacity via alpha on a white background trick:
        // Lerp design toward white (which is neutral for multiply blend)
        let fadedDesign: CIImage
        if opacity < 0.99 {
            let white = CIImage(color: .white).cropped(to: frame.extent)
            fadedDesign = designCI.applyingFilter("CIBlendWithMask", parameters: [
                kCIInputBackgroundImageKey: white,
                kCIInputMaskImageKey: CIImage(color: CIColor(red: CGFloat(opacity),
                                                               green: CGFloat(opacity),
                                                               blue: CGFloat(opacity)))
                    .cropped(to: frame.extent)
            ])
        } else {
            fadedDesign = designCI
        }

        var result = frame

        for region in regions {
            let fittedRegion = fitted(region: region, nailScale: nailScale, tipOffset: tipOffset)
            let mask = nailMask(region: fittedRegion, imageSize: frame.extent.size)

            // Blend design onto current result
            let blendFilterName: String
            switch blendMode {
            case .multiply:  blendFilterName = "CIMultiplyBlendMode"
            case .overlay:   blendFilterName = "CIOverlayBlendMode"
            case .softLight: blendFilterName = "CISoftLightBlendMode"
            }

            let blended = fadedDesign.applyingFilter(blendFilterName, parameters: [
                kCIInputBackgroundImageKey: result
            ])

            // Mask: show blended only inside nail region
            result = result.applyingFilter("CIBlendWithMask", parameters: [
                kCIInputBackgroundImageKey: result,
                kCIInputImageKey: blended,
                kCIInputMaskImageKey: mask
            ])
        }

        return result
    }

    private func fitted(region: NailRegion, nailScale: CGFloat, tipOffset: CGFloat) -> NailRegion {
        let scale = min(max(nailScale, 0.65), 1.45)
        let offset = min(max(tipOffset, -0.25), 0.25)
        let dx = cos(region.angleRad) * region.heightPx * offset
        let dy = sin(region.angleRad) * region.heightPx * offset

        return NailRegion(
            centerX: region.centerX + dx,
            centerY: region.centerY + dy,
            widthPx: region.widthPx * scale,
            heightPx: region.heightPx * scale,
            angleRad: region.angleRad
        )
    }

    // MARK: - Mask generation

    private func nailMask(region: NailRegion, imageSize: CGSize) -> CIImage {
        // Quantize for cache key
        let key = "\(Int(region.centerX/4))-\(Int(region.centerY/4))-\(Int(region.widthPx))-\(Int(region.heightPx))-\(Int(region.angleRad * 57))"
        if let cached = maskCache[key] { return cached }

        // Render white rounded-rect (nail shape) on black using CGContext
        let uiImage = renderMask(region: region, imageSize: imageSize)
        var mask = CIImage(cgImage: uiImage.cgImage!)

        // Soft edge
        let sigma = Double(region.widthPx * 0.10)
        mask = mask.applyingGaussianBlur(sigma: sigma)
                   .cropped(to: CGRect(origin: .zero, size: imageSize))

        if maskCache.count > 30 { maskCache.removeAll() }
        maskCache[key] = mask
        return mask
    }

    private func renderMask(region: NailRegion, imageSize: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: imageSize, format: format)

        return renderer.image { ctx in
            let cg = ctx.cgContext
            // Black background
            cg.setFillColor(UIColor.black.cgColor)
            cg.fill(CGRect(origin: .zero, size: imageSize))

            // UIKit Y is flipped vs CIImage
            let uiCenterY = imageSize.height - region.centerY

            cg.saveGState()
            cg.translateBy(x: region.centerX, y: uiCenterY)
            // Vision angle: atan2(dy,dx) where dy is CIImage (up positive)
            // Finger points upward on screen → angle ≈ +90°, but UIKit Y is flipped
            cg.rotate(by: -region.angleRad - .pi / 2)

            let r = min(region.widthPx, region.heightPx) * 0.38
            let rect = CGRect(x: -region.widthPx / 2, y: -region.heightPx / 2,
                              width: region.widthPx, height: region.heightPx)
            let path = UIBezierPath(roundedRect: rect, cornerRadius: r)
            UIColor.white.setFill()
            path.fill()

            cg.restoreGState()
        }
    }

    // MARK: - Blend mode

    enum BlendMode: Equatable {
        case multiply
        case overlay
        case softLight
    }
}
