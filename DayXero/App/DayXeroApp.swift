import DayXeroCore
import SwiftData
import SwiftUI

@main
struct DayXeroApp: App {
    private let container: ModelContainer

    init() {
        DX.Typeface.register()
        do {
            // Unit tests run inside the app; give them a throwaway store.
            let isTesting = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
            container = try DataStore.makeContainer(inMemory: isTesting)
        } catch {
            fatalError("Could not open the DayXero store: \(error)")
        }
        Subscriptions.shared.configure()
        Analytics.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}

/// Routes between onboarding and the app. Home (Section 4) and the paywall (Section 3) slot in here.
struct RootView: View {
    @Query private var profiles: [UserProfile]
    @AppStorage("dx.underAge") private var underAge = false

    var body: some View {
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "dx.showGallery") {
            DesignSystemGallery()
        } else {
            content
        }
        #else
        content
        #endif
    }

    @ViewBuilder
    private var content: some View {
        if underAge {
            UnderAgeScreen().dxCanvas()
        } else if let profile = profiles.first {
            PlaceholderHome(profile: profile)
        } else {
            OnboardingFlow(onFinished: {})
        }
    }
}

/// Temporary landing after onboarding until Sections 3 and 4 are built.
private struct PlaceholderHome: View {
    let profile: UserProfile
    @Environment(\.modelContext) private var context
    @State private var showGallery = false

    var body: some View {
        VStack(alignment: .leading, spacing: DX.Space.m) {
            Text("Plan saved").dxText(.micro)
            Text("Hi \(profile.name)").dxText(.title)
            Text("Quit Day: \(profile.quitDay, format: .dateTime.weekday(.wide).day().month())").dxText(.subtitle)
            Text("The paywall (Section 3) and Home (Section 4) come next.").dxText(.subtitle)
            Spacer()
            Button("Design system gallery") { showGallery = true }.buttonStyle(.dxSecondary)
            #if DEBUG
            Button("Restart onboarding") {
                context.delete(profile)
                try? context.save()
            }
            .buttonStyle(.dxQuiet)
            #endif
        }
        .padding(DX.Space.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .dxCanvas()
        .sheet(isPresented: $showGallery) { DesignSystemGallery() }
    }
}
