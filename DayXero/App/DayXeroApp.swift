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
            #if DEBUG
            // UI tests (-dx.uiTest) start every launch as a fresh install.
            let uiTest = UserDefaults.standard.bool(forKey: "dx.uiTest")
            if uiTest, let id = Bundle.main.bundleIdentifier { UserDefaults.standard.removePersistentDomain(forName: id) }
            let scenario = DebugScenario.current
            container = try DataStore.makeContainer(inMemory: isTesting || uiTest || scenario != nil)
            scenario?.seed(into: container)
            #else
            container = try DataStore.makeContainer(inMemory: isTesting)
            #endif
        } catch {
            fatalError("Could not open the DayXero store: \(error)")
        }
        SOSBridge.container = container
        SOSBridge.endLiveActivity = { await SOSLiveActivity.endAll() }
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

/// Routes between onboarding, the one-time paywall and Home.
struct RootView: View {
    @Query private var profiles: [UserProfile]
    @AppStorage("dx.underAge") private var underAge = false
    /// The full paywall shows once, right after onboarding. After that, upgrades happen at locked days.
    @AppStorage("dx.paywallDone") private var paywallDone = false
    @Environment(Entitlement.self) private var entitlement
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    @State private var sos = SOSRouter()
    @State private var log = LogRouter()
    @State private var nrt = NRTRouter()
    @State private var logDetent = PresentationDetent.medium
    @AppStorage(AppearanceSetting.key) private var appearance = AppearanceSetting.automatic.rawValue

    var body: some View {
        routed
            .preferredColorScheme(AppearanceSetting(rawValue: appearance)?.colorScheme)
            .environment(sos)
            .environment(log)
            .environment(nrt)
            .fullScreenCover(item: $nrt.sheet) { sheet in
                if let profile = profiles.first {
                    switch sheet {
                    case .setup: NRTSetupView(profile: profile) { nrt.sheet = nil }
                    case .taper: TaperSetupView(profile: profile) { nrt.sheet = nil }
                    }
                }
            }
            .sheet(item: $log.page) { page in
                LogSheet(profile: profiles.first, start: page, detent: $logDetent) { log.page = nil }
                    .environment(sos)
                    .presentationDetents([.medium, .large], selection: $logDetent)
            }
            // Craving SOS sits above everything, so every way in reaches it in one step (S6.5).
            .fullScreenCover(item: $sos.launch) { launch in
                CravingSOSView(profile: profiles.first, source: launch.source) { sos.launch = nil }
            }
            .onChange(of: entitlement.isPro) { _, pro in
                DailyReminders.isPro = pro
                DailyReminders.refresh(in: modelContext)
            }
            .onOpenURL { url in
                guard url.scheme == "dayxero" else { return }
                if url.host() == "log" {
                    log.open(url.path().contains("craving") ? .craving : url.path().contains("slip") ? .slip : .menu)
                    return
                }
                guard url.host() == "sos" else { return }
                let source = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                    .queryItems?.first { $0.name == "source" }?.value
                sos.open(source: source ?? "link")
            }
            .onChange(of: scenePhase, initial: true) { _, phase in
                guard phase == .active else { return }
                NRTReminders.refresh(profile: profiles.first)
                DailyReminders.isPro = entitlement.isPro
                DailyReminders.refresh(in: modelContext)
                SOSBridge.openSession = { [sos] source in sos.open(source: source) }
                SOSBridge.openCravingLog = { [log] in log.open(.craving) }
                if let source = SOSState.consumeOpenRequest() { sos.open(source: source) }
                if LogRequest.consumeCravingLog() { log.open(.craving) }
                #if DEBUG
                if UserDefaults.standard.bool(forKey: "dx.sos") {
                    sos.open(source: "debug")
                } else {
                    // Screenshots run one after another; don't carry a countdown into the next one.
                    Task { await SOSLiveActivity.endAll() }
                }
                switch UserDefaults.standard.string(forKey: "dx.logSheet") {
                case "menu": log.open(.menu)
                case "craving": log.open(.craving)
                case "slip": log.open(.slip)
                case "nrt": nrt.sheet = .setup
                case "taper": nrt.sheet = .taper
                default: break
                }
                #endif
            }
    }

    @ViewBuilder
    private var routed: some View {
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
            #if DEBUG
            if let raw = UserDefaults.standard.string(forKey: "dx.openLesson"), let day = ProgramDayID(description: raw) {
                LessonPlayer(day: day, profile: profile)
            } else if paywallDone || entitlement.isPro {
                HomeView(profile: profile)
            } else {
                PaywallView(name: profile.name, quitDay: profile.quitDay,
                            model: PaywallModel(store: entitlement.store, entitlement: entitlement),
                            onClose: { paywallDone = true })
            }
            #else
            if paywallDone || entitlement.isPro {
                HomeView(profile: profile)
            } else {
                PaywallView(name: profile.name, quitDay: profile.quitDay,
                            model: PaywallModel(store: entitlement.store, entitlement: entitlement),
                            onClose: { paywallDone = true })
            }
            #endif
        } else {
            OnboardingFlow(onFinished: {})
        }
    }
}
