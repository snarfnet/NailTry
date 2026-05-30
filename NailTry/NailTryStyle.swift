import SwiftUI
import UIKit

enum NailTryStyle {
    // MARK: - Colors
    static let pink     = Color(UIColor(red: 0.98, green: 0.72, blue: 0.80, alpha: 1))
    static let rose     = Color(UIColor(red: 0.94, green: 0.45, blue: 0.62, alpha: 1))
    static let cream    = Color(UIColor(red: 0.99, green: 0.97, blue: 0.95, alpha: 1))
    static let ink      = Color(UIColor(red: 0.22, green: 0.16, blue: 0.20, alpha: 1))
    static let muted    = Color(UIColor(red: 0.60, green: 0.52, blue: 0.56, alpha: 1))
    static let line     = Color(UIColor(red: 0.90, green: 0.84, blue: 0.87, alpha: 1))
    static let cardBg   = Color.white.opacity(0.88)

    // MARK: - Gradient
    static let pinkGradient = LinearGradient(
        colors: [
            Color(UIColor(red: 1.00, green: 0.88, blue: 0.92, alpha: 1)),
            Color(UIColor(red: 0.98, green: 0.78, blue: 0.86, alpha: 1))
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cameraGlass = LinearGradient(
        colors: [
            Color.black.opacity(0.32),
            Color.clear,
            Color.clear,
            Color.black.opacity(0.55)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Shared card component

struct NTCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }

    var body: some View {
        content
            .padding(16)
            .background(NailTryStyle.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(NailTryStyle.line, lineWidth: 1)
            )
    }
}
