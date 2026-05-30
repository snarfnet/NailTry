import SwiftUI

struct TryOnView: View {
    @StateObject private var camera = TryCameraManager()

    @State private var selectedDesign: NailDesign = .solid(
        UIColor(red: 1.00, green: 0.82, blue: 0.87, alpha: 1)  // ベビーピンク
    )
    @State private var opacity: Float    = 0.78
    @State private var blendMode: NailCompositor.BlendMode = .multiply
    @State private var nailScale: Double = 1.0
    @State private var tipOffset: Double = 0.0
    @State private var showPalette = true
    @State private var showSaveFlash = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // Camera + composite (full screen)
            MetalCameraView(camera: camera)
                .ignoresSafeArea()

            // Gradient overlay (for readability)
            NailTryStyle.cameraGlass
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // Header
            VStack {
                headerBar
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)

            // Bottom: palette + status
            VStack(spacing: 10) {
                // Status pill
                statusPill

                if showPalette {
                    DesignPaletteView(
                        selectedDesign: $selectedDesign,
                        opacity:        $opacity,
                        blendMode:      $blendMode,
                        nailScale:      $nailScale,
                        tipOffset:      $tipOffset
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 24)

            // Save flash
            if showSaveFlash {
                Color.white.opacity(0.5)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
        .onChange(of: selectedDesign) { _ in updateCamera() }
        .onChange(of: opacity)        { _ in updateCamera() }
        .onChange(of: blendMode)      { _ in updateCamera() }
        .onChange(of: nailScale)      { _ in updateCamera() }
        .onChange(of: tipOffset)      { _ in updateCamera() }
        .onAppear  { camera.setup(); camera.start(); updateCamera() }
        .onDisappear { camera.stop() }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Nail Try")
                    .font(.system(.title3, design: .serif).weight(.bold))
                    .foregroundColor(.white)
                Text("爪にデザインを重ねて試着")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.75))
            }

            Spacer()

            HStack(spacing: 12) {
                // Save button
                Button { saveSnapshot() } label: {
                    Image(systemName: "square.and.arrow.down")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }

                // Toggle palette
                Button {
                    withAnimation(.spring(response: 0.3)) { showPalette.toggle() }
                } label: {
                    Image(systemName: showPalette ? "chevron.down.circle.fill" : "paintpalette.fill")
                        .font(.title3)
                        .foregroundStyle(.white, NailTryStyle.pink.opacity(0.5))
                        .frame(width: 42, height: 42)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
            }
        }
    }

    // MARK: - Status Pill

    private var statusPill: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(camera.hasHand ? NailTryStyle.rose : Color.white.opacity(0.4))
                .frame(width: 8, height: 8)
            Text(camera.hasHand
                 ? "\(camera.fingerCount)本の指を検出中"
                 : "手をカメラに向けてください")
                .font(.caption.weight(.semibold))
                .foregroundColor(.white)
            Spacer()
            if camera.hasHand {
                Text("LIVE")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(NailTryStyle.rose)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 1))
    }

    // MARK: - Sync design to camera

    private func updateCamera() {
        camera.currentDesign = selectedDesign
        camera.opacity       = opacity
        camera.blendMode     = blendMode
        camera.nailScale     = CGFloat(nailScale)
        camera.tipOffset     = CGFloat(tipOffset)
    }

    // MARK: - Save snapshot

    private func saveSnapshot() {
        // Flash effect
        withAnimation(.easeIn(duration: 0.08)) { showSaveFlash = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation { showSaveFlash = false }
        }

        // Capture current composite as UIImage and save
        guard let frame   = camera.latestFrame else { return }
        let regions   = camera.latestRegions
        let compositor = NailCompositor()
        let composite = compositor.composite(
            frame:     frame,
            regions:   regions,
            design:    camera.currentDesign,
            opacity:   camera.opacity,
            blendMode: camera.blendMode,
            nailScale: camera.nailScale,
            tipOffset: camera.tipOffset
        )

        let ctx = CIContext()
        guard let cg = ctx.createCGImage(composite, from: composite.extent) else { return }
        let img = UIImage(cgImage: cg)
        UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
    }
}
