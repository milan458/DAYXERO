import DayXeroCore
import SwiftData
import SwiftUI

@main
struct DayXeroApp: App {
    private let container: ModelContainer
    @State private var entitlement: Entitlement

    init() {
        DX.Typeface4.register()
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
        let store = Self.makeStore()
        // Superwall first, then RevenueCat, then keep Superwall's subscription status in step with RevenueCat's (S20).
        Paywalls.configure(usingStandInStore: Self.usesStandIns || !(store is Subscriptions))
        Subscriptions.shared.configure()
        Paywalls.syncWithRevenueCat()
        Analytics.configure()
        _entitlement = State(initialValue: Entitlement(store: store))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(entitlement)
                .task { await entitlement.refresh() }
        }
        .modelContainer(container)
    }

    /// Tests, screenshots and seeded scenarios launch with `-dx.` arguments; they keep to DayXero's own paywall.
    private static var usesStandIns: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains { $0.hasPrefix("-dx.") }
        #else
        false
        #endif
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

/// Routes between onboarding and Home. There's no paywall after onboarding: the prep week and Day Xero are free,
/// and the trial is offered on Quit Day after the Day Xero session (decisions 15 and 23).
struct RootView: View {
    @Query private var profiles: [UserProfile]
    @AppStorage("dx.underAge") private var underAge = false
    @Environment(Entitlement.self) private var entitlement
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    @State private var sos = SOSRouter()
    @State private var log = LogRouter()
    @State private var nrt = NRTRouter()
    @AppStorage(AppearanceSetting.key) private var appearance = AppearanceSetting.automatic.rawValue
    /// Onboarding saves the profile before its last screen (reminders). This keeps that screen up until it's done,
    /// instead of the new profile swapping Home in underneath it.
    @State private var finishingOnboarding = false

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
                LogSheet(profile: profiles.first, start: page, detent: $log.detent) { log.page = nil }
                    .environment(sos)
                    .presentationDetents([.medium, .large], selection: $log.detent)
            }
            // Craving SOS sits above everything, so every way in reaches it in one step (S6.5).
            .fullScreenCover(item: $sos.launch) { launch in
                CravingSOSView(profile: profiles.first, source: launch.source) { sos.launch = nil }
            }
            // Widgets read a snapshot; rebuild it after anything is saved (S17.1).
            .onReceive(NotificationCenter.default.publisher(for: ModelContext.didSave)) { _ in
                WidgetSync.refresh(in: modelContext, isPro: entitlement.isPro)
            }
            .onChange(of: entitlement.isPro) { _, pro in
                DailyReminders.isPro = pro
                DailyReminders.refresh(in: modelContext)
            }
            .onOpenURL { url in
                // DayXero's own links first; anything else may be a Superwall paywall preview or web-checkout link (S20).
                guard url.scheme == "dayxero", url.host() == "log" || url.host() == "sos" else {
                    _ = Paywalls.handleDeepLink(url)
                    return
                }
                if url.host() == "log" {
                    log.open(url.path().contains("craving") ? .craving : url.path().contains("slip") ? .slip : .menu)
                    return
                }
                let source = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                    .queryItems?.first { $0.name == "source" }?.value
                sos.open(source: source ?? "link")
            }
            .onChange(of: scenePhase, initial: true) { _, phase in
                if phase == .background { WidgetSync.refresh(in: modelContext, isPro: entitlement.isPro) }
                guard phase == .active else { return }
                WidgetSync.refresh(in: modelContext, isPro: entitlement.isPro)
                NRTReminders.refresh(profile: profiles.first)
                if let profile = profiles.first { Paywalls.setAttributes(for: profile) }
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
        if let page = UserDefaults.standard.string(forKey: "dx.v4Gallery") {
            V4Gallery(page: page)
        } else if UserDefaults.standard.bool(forKey: "dx.illustrationGallery") {
            MilestoneIllustrationGallery()
        } else if let page = UserDefaults.standard.string(forKey: "dx.widgetGallery") {
            WidgetGallery(page: page)
        } else if UserDefaults.standard.bool(forKey: "dx.paywallPreview") {
            PaywallView(name: "Milan", quitDay: Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now,
                        model: PaywallModel(store: entitlement.store, entitlement: entitlement),
                        context: UserDefaults.standard.bool(forKey: "dx.paywallFirstRun") ? PaywallContext(sampleCurrency: "USD") : nil,
                        onClose: {})
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
            UnderAgeScreen().background(Read4.background.ignoresSafeArea())
        } else if let profile = profiles.first, !finishingOnboarding {
            #if DEBUG
            if let session = UserDefaults.standard.string(forKey: "dx.openSession") {
                // Screenshots: a program v2 session, at the step given by -dx.sessionStep.
                SessionFlowView(sessionId: session, profile: profile)
            } else {
                HomeView(profile: profile)
            }
            #else
            HomeView(profile: profile)
            #endif
        } else {
            OnboardingFlow(onSaving: { finishingOnboarding = true }, onFinished: {
                // Prep week is free and the trial is offered after Day Xero (decisions 15, 23),
                // so onboarding goes straight to Home, which opens Prep 1 by itself.
                UserDefaults.standard.set(true, forKey: FirstLesson.key)
                finishingOnboarding = false
            })
        }
    }
}
