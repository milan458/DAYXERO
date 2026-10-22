import DayXeroCore
import SwiftData
import SwiftUI

@main
struct DayXeroApp: App {
    private let container: ModelContainer

    init() {
        DX.Typeface.register()
        do {
            container = try DataStore.makeContainer()
        } catch {
            fatalError("Could not open the DayXero store: \(error)")
        }
        Subscriptions.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}

/// Until Section 2 lands, the app opens on the design-system gallery (Section 1's deliverable).
struct RootView: View {
    var body: some View {
        DesignSystemGallery()
    }
}
