import SwiftUI
import PhotosUI

struct DesignPaletteView: View {
    @Binding var selectedDesign: NailDesign
    @Binding var opacity: Float
    @Binding var blendMode: NailCompositor.BlendMode
    @Binding var nailScale: Double
    @Binding var tipOffset: Double

    @State private var tab: PaletteTab = .color
    @State private var photoItem: PhotosPickerItem?
    @State private var selectedColorIndex = 1   // ベビーピンク default
    @State private var selectedSampleID: Int?

    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            HStack(spacing: 0) {
                ForEach(PaletteTab.allCases, id: \.self) { t in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) { tab = t }
                    } label: {
                        Text(t.label)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(tab == t ? NailTryStyle.rose : NailTryStyle.muted)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                tab == t
                                ? NailTryStyle.pink.opacity(0.40)
                                : Color.clear
                            )
                    }
                }
            }
            .background(Color.white.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .padding(.horizontal, 16)
            .padding(.top, 12)

            // Content
            Group {
                switch tab {
                case .color:    colorGrid
                case .sample:   sampleGrid
                case .gradient: gradientList
                case .photo:    photoSection
                case .settings: settingsSection
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(NailTryStyle.line, lineWidth: 1)
        )
    }

    // MARK: - Color Grid

    private var colorGrid: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(NailPresets.colors.indices, id: \.self) { i in
                    let item = NailPresets.colors[i]
                    ColorDot(
                        color: item.color,
                        name: item.name,
                        isSelected: selectedColorIndex == i
                    )
                    .onTapGesture {
                        selectedColorIndex = i
                        selectedSampleID = nil
                        selectedDesign = .solid(item.color)
                    }
                }
            }
            .padding(.vertical, 14)
        }
    }

    // MARK: - Sample Grid

    private var sampleGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 9), count: 5),
                spacing: 10
            ) {
                ForEach(NailPresets.samples) { sample in
                    SampleTile(
                        sample: sample,
                        isSelected: selectedSampleID == sample.id
                    )
                    .onTapGesture {
                        selectedSampleID = sample.id
                        selectedColorIndex = -1
                        selectedDesign = .sample(sample)
                    }
                }
            }
            .padding(.vertical, 12)
        }
        .frame(maxHeight: 260)
    }

    // MARK: - Gradient List

    private var gradientList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(NailPresets.gradients) { g in
                    GradientDot(gradient: g)
                        .onTapGesture {
                        selectedDesign = .gradient(g)
                        selectedColorIndex = -1
                        selectedSampleID = nil
                        }
                }
            }
            .padding(.vertical, 14)
        }
    }

    // MARK: - Photo picker

    private var photoSection: some View {
        VStack(spacing: 12) {
            PhotosPicker(selection: $photoItem, matching: .images) {
                Label("写真を選ぶ / Choose Photo", systemImage: "photo.on.rectangle")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(NailTryStyle.rose)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .onChange(of: photoItem) { item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self),
                       let img = UIImage(data: data) {
                        selectedSampleID = nil
                        selectedColorIndex = -1
                        selectedDesign = .photo(img)
                    }
                }
            }
            Text("選んだ画像がそのまま爪に合成されます")
                .font(.caption)
                .foregroundColor(NailTryStyle.muted)
        }
        .padding(.vertical, 14)
    }

    // MARK: - Settings

    private var settingsSection: some View {
        VStack(spacing: 16) {
            // Opacity
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("不透明度 / Opacity")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(NailTryStyle.ink)
                    Spacer()
                    Text("\(Int(opacity * 100))%")
                        .font(.caption.monospacedDigit())
                        .foregroundColor(NailTryStyle.muted)
                }
                Slider(value: $opacity, in: 0.3...1.0)
                    .tint(NailTryStyle.rose)
            }

            // Blend mode
            VStack(alignment: .leading, spacing: 6) {
                Text("ブレンドモード / Blend")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(NailTryStyle.ink)
                HStack(spacing: 8) {
                    ForEach(blendModes, id: \.0) { label, mode in
                        Button {
                            blendMode = mode
                        } label: {
                            Text(label)
                                .font(.caption2.weight(.semibold))
                                .foregroundColor(blendMode == mode ? .white : NailTryStyle.muted)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(blendMode == mode ? NailTryStyle.rose : Color.clear)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(NailTryStyle.line, lineWidth: 1))
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("爪サイズ / Fit")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(NailTryStyle.ink)
                    Spacer()
                    Text("\(Int(nailScale * 100))%")
                        .font(.caption.monospacedDigit())
                        .foregroundColor(NailTryStyle.muted)
                }
                Slider(value: $nailScale, in: 0.7...1.35)
                    .tint(NailTryStyle.rose)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("先端寄せ / Tip")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(NailTryStyle.ink)
                    Spacer()
                    Text("\(Int(tipOffset * 100))")
                        .font(.caption.monospacedDigit())
                        .foregroundColor(NailTryStyle.muted)
                }
                Slider(value: $tipOffset, in: -0.18...0.18)
                    .tint(NailTryStyle.rose)
            }
        }
        .padding(.vertical, 14)
    }

    private let blendModes: [(String, NailCompositor.BlendMode)] = [
        ("Multiply",   .multiply),
        ("Overlay",    .overlay),
        ("Soft Light", .softLight),
    ]
}

// MARK: - Palette Tab

private enum PaletteTab: CaseIterable {
    case color, sample, gradient, photo, settings
    var label: String {
        switch self {
        case .color:    return "カラー"
        case .sample:   return "サンプル"
        case .gradient: return "グラデ"
        case .photo:    return "画像"
        case .settings: return "設定"
        }
    }
}

// MARK: - Sample Tile

private struct SampleTile: View {
    let sample: NailSampleDesign
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 5) {
            Group {
                if let image = sample.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    NailTryStyle.line
                }
            }
            .frame(height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? NailTryStyle.rose : NailTryStyle.line,
                            lineWidth: isSelected ? 3 : 1)
            )
            .shadow(color: Color.black.opacity(isSelected ? 0.16 : 0.05), radius: isSelected ? 7 : 2)

            Text(sample.name)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(isSelected ? NailTryStyle.ink : NailTryStyle.muted)
                .lineLimit(1)
        }
    }
}

// MARK: - Color Dot

private struct ColorDot: View {
    let color: UIColor
    let name: String
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 5) {
            Circle()
                .fill(Color(color))
                .frame(width: 38, height: 38)
                .overlay(
                    Circle()
                        .stroke(isSelected ? NailTryStyle.rose : NailTryStyle.line,
                                lineWidth: isSelected ? 3 : 1.5)
                )
                .shadow(color: Color(color).opacity(0.4), radius: isSelected ? 6 : 2)
                .scaleEffect(isSelected ? 1.12 : 1.0)
                .animation(.spring(response: 0.25), value: isSelected)
            Text(name)
                .font(.system(size: 9))
                .foregroundColor(NailTryStyle.muted)
                .lineLimit(1)
        }
        .frame(width: 44)
    }
}

// MARK: - Gradient Dot

private struct GradientDot: View {
    let gradient: NailGradient

    var body: some View {
        VStack(spacing: 5) {
            Circle()
                .fill(LinearGradient(
                    colors: [Color(gradient.from), Color(gradient.to)],
                    startPoint: .top, endPoint: .bottom
                ))
                .frame(width: 38, height: 38)
                .overlay(Circle().stroke(NailTryStyle.line, lineWidth: 1.5))
                .shadow(color: Color(gradient.from).opacity(0.3), radius: 3)
            Text(gradient.name)
                .font(.system(size: 9))
                .foregroundColor(NailTryStyle.muted)
                .lineLimit(1)
        }
        .frame(width: 52)
    }
}
