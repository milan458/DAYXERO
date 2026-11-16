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
                // v5: every switch is the kit toggle (coral on, the ink at 30% off).
                .toggleStyle(.dx)
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

/// Routes between onboarding, the hard paywall and Home (16 Nov 2026). Without an active plan the paywall is the
/// only screen after onboarding, and it can't be closed.
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
    /// Once a purchase or restore starts on the paywall, it stays up for its "You're all set" screen.
    @State private var paywallPurchaseStarted = false
    /// The forest wordmark grows over whatever opens first, on a cold start only.
    @State private var launching = LaunchGrowOverlay.shouldPlay
    /// The first screen is built as the launch scene starts to fade, so its entrance plays where it can be seen
    /// (it used to run under the scene and be over by the time the scene lifted).
    @State private var revealed = !LaunchGrowOverlay.shouldPlay
    private let motion = MotionPolicy()

    var body: some View {
        Group {
            if revealed { routed } else { LaunchPaperColor() }
        }
            .overlay {
                if launching {
                    LaunchGrowOverlay(onReveal: { revealed = true }) { launching = false }
                }
            }
            .preferredColorScheme(AppearanceSetting(rawValue: appearance)?.colorScheme)
            .environment(sos)
            .environment(log)
            .environment(nrt)
            .fullScreenCover(item: behindPaywall($nrt.sheet)) { sheet in
                if let profile = profiles.first {
                    switch sheet {
                    case .setup: NRTSetupView(profile: profile) { nrt.sheet = nil }
                    case .taper: TaperSetupView(profile: profile) { nrt.sheet = nil }
                    }
                }
            }
            // v5 (041): the menu is a sheet over Today; a craving or a slip is a full-screen form (042-046). Both stay
            // behind the hard paywall, like the NRT and SOS covers.
            .sheet(isPresented: behindPaywall($log.menuShown), onDismiss: { log.menuDismissed() }) {
                LogSheet(profile: profiles.first, start: .menu, onPush: { log.push($0) }) { log.page = nil }
                    .environment(sos)
                    .presentationDetents([.height(436), .large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(32)
            }
            .fullScreenCover(item: behindPaywall($log.form)) { page in
                LogSheet(profile: profiles.first, start: page) { log.page = nil }
                    .environment(sos)
            }
            // Craving SOS sits above everything in the app, so every way in reaches it in one step (S6.5). Like the
            // log and NRT sheets it stays behind the hard paywall: a widget, Siri or a link can't open it without a plan.
            .fullScreenCover(item: behindPaywall($sos.launch)) { launch in
                CravingSOSView(profile: profiles.first, source: launch.source) { sos.launch = nil }
            }
            // A request that arrives without a plan is dropped, not kept for later.
            .onChange(of: sos.launch != nil) { _, asked in if asked, !entitlement.isPro { sos.launch = nil } }
            .onChange(of: log.page != nil) { _, asked in if asked, !entitlement.isPro { log.page = nil } }
            .onChange(of: nrt.sheet != nil) { _, asked in if asked, !entitlement.isPro { nrt.sheet = nil } }
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
                // A trial that has turned into a paid plan, or one that ended unpaid, shows up here.
                Task { await entitlement.refreshOnReturn() }
                DailyReminders.isPro = entitlement.isPro
                DailyReminders.refresh(in: modelContext)
                SOSBridge.openSession = { [sos] source in sos.open(source: source) }
                SOSBridge.openCravingLog = { [log] in log.open(.craving) }
                if let source = SOSState.consumeOpenRequest() { sos.open(source: source) }
                if LogRequest.consumeCravingLog() { log.open(.craving) }
                // A slip logged from Siri or the widget opens Jelli's if-then planner (CLIN-10).
                if SlipPlanRequest.consume(), log.page == nil { log.open(.slipPlan) }
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

    /// A sheet or cover that only shows with an active plan (the hard paywall, 16 Nov 2026).
    private func behindPaywall<Item>(_ item: Binding<Item?>) -> Binding<Item?> {
        Binding(get: { entitlement.isPro ? item.wrappedValue : nil }, set: { item.wrappedValue = $0 })
    }

    /// The same gate for a sheet shown by a flag (the v5 log menu).
    private func behindPaywall(_ shown: Binding<Bool>) -> Binding<Bool> {
        Binding(get: { entitlement.isPro && shown.wrappedValue }, set: { shown.wrappedValue = $0 })
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
                        onClose: {})
        } else {
            content
        }
        #else
        content
        #endif
    }

    /// Onboarding hands over to Home with a 0.3 s cross-fade (QW6): a hard cut read as a glitch, and a flip or zoom
    /// would be hidden by Prep 1 rising over Home a moment later anyway.
    private var content: some View {
        ZStack { screen }
    }

    @ViewBuilder
    private var screen: some View {
        if underAge {
            UnderAgeScreen().background(Read4.background.ignoresSafeArea())
        } else if let profile = profiles.first, !finishingOnboarding {
            if !entitlement.isPro || paywallPurchaseStarted {
                HardPaywall(profile: profile, onPurchaseStarted: { paywallPurchaseStarted = true }) {
                    withAnimation(motion.animation(.easeInOut(duration: 0.3))) { paywallPurchaseStarted = false }
                }
                .transition(.opacity)
            } else {
                home(profile)
            }
        } else {
            OnboardingFlow(onSaving: { finishingOnboarding = true }, onFinished: {
                // "Start my prep week" queued Prep 1 (FirstLesson); Home opens it once it has faded in.
                withAnimation(motion.animation(.easeInOut(duration: 0.3))) { finishingOnboarding = false }
            })
            .transition(.opacity)
        }
    }

    @ViewBuilder
    private func home(_ profile: UserProfile) -> some View {
        #if DEBUG
        if let session = UserDefaults.standard.string(forKey: "dx.openSession") {
            // Screenshots: a program v2 session, at the step given by -dx.sessionStep.
            SessionFlowView(sessionId: session, profile: profile)
        } else {
            HomeView(profile: profile)
                .transition(.opacity)
        }
        #else
        HomeView(profile: profile)
            .transition(.opacity)
        #endif
    }
}

/// The hard paywall (16 Nov 2026): shown whenever there's no active plan, straight after onboarding and after a
/// subscription ends. There's no way past it but a purchase or a restore. Superwall's paywall shows first when a
/// campaign has one for `onboarding_complete`; closing that one leads to DayXero's own, not into the app.
struct HardPaywall: View {
    let profile: UserProfile
    let onPurchaseStarted: () -> Void
    let onDone: () -> Void

    @Environment(Entitlement.self) private var entitlement
    @State private var asked = false
    @State private var showOwn = false

    var body: some View {
        ZStack {
            Read4.background.ignoresSafeArea()
            if showOwn {
                PaywallView(name: profile.name, quitDay: profile.quitDay,
                            model: PaywallModel(store: entitlement.store, entitlement: entitlement),
                            onClose: onDone, onPurchaseStarted: onPurchaseStarted, closable: false)
            }
        }
        .safeAreaInset(edge: .bottom) {
            // Test builds only (debug and TestFlight): the way in without a purchase.
            if DemoMode.isAvailable, showOwn {
                Button("Demo mode (test builds)") { entitlement.setDemo(true) }
                    .dxFont(12, weight: 500, style: .caption2)
                    .foregroundStyle(Read4.muted)
                    .buttonStyle(.plain)
                    .padding(.bottom, 2)
            }
        }
        .task {
            guard !asked else { return }
            asked = true
            Paywalls.present(.onboardingComplete) { outcome in
                switch outcome {
                case .unlocked:
                    entitlement.grantFromElsewhere()
                    onDone()
                case .fallback, .closed:
                    showOwn = true
                }
            }
        }
    }
}

/// What sits under the launch scene before the first screen is revealed: the launch colour, edge to edge.
private struct LaunchPaperColor: View {
    var body: some View {
        Color("LaunchPaper").ignoresSafeArea()
    }
}
