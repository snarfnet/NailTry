import SwiftUI

@main
struct NailTryApp: App {
    var body: some Scene {
        WindowGroup {
            TryOnView()
                .tint(NailTryStyle.rose)
        }
    }
}
