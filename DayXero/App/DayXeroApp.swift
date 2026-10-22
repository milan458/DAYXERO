import DayXeroCore
import SwiftData
import SwiftUI

@main
struct DayXeroApp: App {
    private let container: ModelContainer
    @State private var entitlement: Entitlement

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
        _entitlement = State(initialValue: Entitlement(store: Self.makeStore()))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(entitlement)
                .task { await entitlement.refresh() }
        }
        .modelContainer(container)
    }

    private static func makeStore() -> PurchaseStore {
        #if DEBUG
        if let mode = UserDefaults.standard.string(forKey: "dx.store").flatMap(MockStore.Mode.init(rawValue:)) {
            return MockStore(mode: mode)
        }
        #endif
        return Subscriptions.shared
    }
}

/// Routes between onboarding and the app. Home (Section 4) and the paywall (Section 3) slot in here.
struct RootView: View {
    @Query private var profiles: [UserProfile]
    @AppStorage("dx.underAge") private var underAge = false
    /// The full paywall shows once, right after onboarding. After that, upgrades happen at locked days.
    @AppStorage("dx.paywallDone") private var paywallDone = false
    @Environment(Entitlement.self) private var entitlement

    var body: some View {
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "dx.showGallery") {
            DesignSystemGallery()
        } else if UserDefaults.standard.bool(forKey: "dx.paywallPreview") {
            PaywallView(name: "Milan", quitDay: Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now,
                        model: PaywallModel(store: entitlement.store, entitlement: entitlement), onClose: {})
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
            if paywallDone || entitlement.isPro {
                PlaceholderHome(profile: profile)
            } else {
                PaywallView(name: profile.name, quitDay: profile.quitDay,
                            model: PaywallModel(store: entitlement.store, entitlement: entitlement),
                            onClose: { paywallDone = true })
            }
        } else {
            OnboardingFlow(onFinished: {})
        }
    }
}

/// Temporary landing after onboarding until Sections 3 and 4 are built.
private struct PlaceholderHome: View {
    let profile: UserProfile
    @Environment(\.modelContext) private var context
    @Environment(Entitlement.self) private var entitlement
    @State private var showGallery = false

    var body: some View {
        VStack(alignment: .leading, spacing: DX.Space.m) {
            Text("Plan saved").dxText(.micro)
            Text("Hi \(profile.name)").dxText(.title)
            Text("Quit Day: \(profile.quitDay, format: .dateTime.weekday(.wide).day().month())").dxText(.subtitle)
            Text(entitlement.isPro ? "Full program unlocked." : "Free version: counter, Craving SOS and Day 1.").dxText(.subtitle)
            Text("Home (Section 4) comes next.").dxText(.subtitle)
            Spacer()
            Button("Design system gallery") { showGallery = true }.buttonStyle(.dxSecondary)
            #if DEBUG
            Button("Restart onboarding") {
                context.delete(profile)
                try? context.save()
                UserDefaults.standard.set(false, forKey: "dx.paywallDone")
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
