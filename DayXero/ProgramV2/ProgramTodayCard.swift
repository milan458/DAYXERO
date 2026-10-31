import DayXeroCore
import SwiftData
import SwiftUI

/// Which session to open, and whether as a replay.
struct SessionOpen: Identifiable, Hashable {
    let id: String
    var isReplay = false
}

/// Free tier: the counter, Craving SOS, the whole prep week and the Day Xero session (decisions 15 and 23).
/// Week 1 onwards needs Pro or the trial, which is offered after Day Xero.
enum ProgramV2Access {
    static let freeSessions: Set<String> = ["P1", "P2", "P3", "P4", "P5", "P6", "P7", "DX"]
    /// The session after which the trial is offered.
    static let offerAfter = "DX"

    static func needsUpgrade(_ sessionId: String, isPro: Bool) -> Bool {
        !isPro && !DemoMode.isOn && !freeSessions.contains(sessionId)
    }
}

/// What Home's Today card shows (handoff 4.5).
struct ProgramToday {
    enum Kind: Equatable {
        /// "Prep 3 · 6 min · Start", or Continue.
        case open(sessionId: String, inProgress: Bool, needsUpgrade: Bool)
        /// Done for today: the mission, and when the next session comes.
        case waiting(next: String)
        case complete
    }

    let kind: Kind
    let label: String
    let title: String
    let minutes: Int
    /// The latest finished session's mission, shown until the next session opens.
    let mission: String?
    /// Quit Day has come and prep isn't finished yet: said gently, once.
    let prepRunsOver: Bool

    @MainActor
    init?(store: ProgramStore, isPro: Bool, now: Date = .now) {
        guard let content = store.content else { return nil }
        let variant = store.variant
        let lastDone = store.records().filter { $0.completedAt != nil }.max { ($0.completedAt ?? .distantPast) < ($1.completedAt ?? .distantPast) }
        let lastSession = lastDone.flatMap { content.session($0.sessionId) }
        mission = lastSession?.mission.map { store.placeholders(now: now).fillDropping($0.text.resolve(variant) ?? "") }
        guard let current = store.current(now: now), let session = content.session(current.id) else {
            kind = .complete
            label = ""
            title = ""
            minutes = 0
            prepRunsOver = false
            return
        }
        label = session.label
        title = session.title.resolve(variant) ?? ""
        minutes = session.durationMinutes
        prepRunsOver = session.phaseId == "prep" && store.clock.day(containing: now) >= store.clock.startOfDate(store.profile.quitDay)
            && store.profile.progress?.quitTimestamp == nil
        switch current.state {
        case .available, .inProgress:
            kind = .open(sessionId: session.id, inProgress: current.state == .inProgress,
                         needsUpgrade: ProgramV2Access.needsUpgrade(session.id, isPro: isPro))
        case let .scheduled(wait):
            let next: String = switch wait {
            case .tomorrow: String(localized: "Next session tomorrow")
            case let .dayXero(date): String(localized: "Day Xero is \(date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))")
            case let .quitDay(day): String(localized: "Next session on Day \(day)")
            }
            kind = .waiting(next: next)
        case .locked, .completed:
            kind = .complete
        }
    }
}

/// Home's program card: the spotlight card in the app's style, with the five states from the handoff.
struct ProgramTodayCard: View {
    let profile: UserProfile

    @Environment(\.modelContext) private var context
    @Environment(Entitlement.self) private var entitlement
    @State private var open: SessionOpen?
    @State private var upgradeTitle: String?
    @State private var showPaywall = false
    /// The last session opened, so closing Day Xero can lead to the offer.
    @State private var lastOpened: String?
    @AppStorage("dx.dayXeroOfferShown") private var dayXeroOfferShown = false

    var body: some View {
        let store = ProgramStore(context: context, profile: profile)
        Group {
            if let today = ProgramToday(store: store, isPro: entitlement.isPro) {
                card(today)
            }
        }
        .fullScreenCover(item: $open, onDismiss: {
            NotificationCenter.default.post(name: .dxSessionClosed, object: nil)
            offerAfterDayXero(store)
        }) { item in
            SessionFlowView(sessionId: item.id, profile: profile, isReplay: item.isReplay)
        }
        .sheet(item: Binding(get: { upgradeTitle.map { SessionOpen(id: $0) } }, set: { upgradeTitle = $0?.id })) { item in
            UpgradeSheet(dayTitle: item.id, model: PaywallModel(store: entitlement.store, entitlement: entitlement),
                         showAllPlans: { upgradeTitle = nil; showPaywall = true },
                         onUnlocked: { upgradeTitle = nil })
                .presentationDetents([.medium])
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(name: profile.name, quitDay: profile.quitDay,
                        model: PaywallModel(store: entitlement.store, entitlement: entitlement),
                        onClose: { showPaywall = false })
        }
        .onAppear(perform: openQueuedFirstSession)
        .onChange(of: open) { _, item in
            if let item { lastOpened = item.id }
        }
    }

    /// Once Day Xero is done, a free user sees the trial offer once (decision 23). Until the v4 offer
    /// screen (G03) is built, it is the app's paywall.
    private func offerAfterDayXero(_ store: ProgramStore) {
        guard lastOpened == ProgramV2Access.offerAfter, !entitlement.isPro, !dayXeroOfferShown,
              case .completed = store.state(of: ProgramV2Access.offerAfter) else { return }
        dayXeroOfferShown = true
        showPaywall = true
    }

    /// Prep 1 opens by itself the first time Home shows after the paywall (S22).
    private func openQueuedFirstSession() {
        guard UserDefaults.standard.bool(forKey: FirstLesson.key) else { return }
        UserDefaults.standard.set(false, forKey: FirstLesson.key)
        let store = ProgramStore(context: context, profile: profile)
        guard case .open(let id, _, false)? = ProgramToday(store: store, isPro: entitlement.isPro)?.kind else { return }
        open = SessionOpen(id: id)
    }

    /// The green lesson card (F08 afternoon): "TODAY · DAY 3 · 3 MIN", the title, and a chevron.
    @ViewBuilder
    private func card(_ today: ProgramToday) -> some View {
        switch today.kind {
        case let .open(id, inProgress, needsUpgrade):
            let detail: String? = needsUpgrade ? String(localized: "Unlock \(today.label)")
                : today.prepRunsOver ? String(localized: "Finish prep when you're ready. Day Xero starts the morning after.")
                : inProgress ? String(localized: "Xero saved your place.") : nil
            ColourCard(kicker: String(localized: "Today · \(today.label) · \(today.minutes) min"), title: today.title,
                       detail: detail, fill: ColourCard.lesson) {
                if needsUpgrade {
                    Paywalls.present(.unlockProgramDay, params: ["day": id]) { outcome in
                        switch outcome {
                        case .fallback: upgradeTitle = today.title
                        case .unlocked: entitlement.grant()
                        case .closed: break
                        }
                    }
                } else {
                    open = SessionOpen(id: id)
                }
            }
            .accessibilityHint(needsUpgrade ? Text("Shows how to unlock it") : Text(inProgress ? "Continues the session" : "Starts the session"))
        case let .waiting(next):
            ColourCard(kicker: today.mission == nil ? String(localized: "Up next") : String(localized: "Today's mission"),
                       title: today.mission ?? next, detail: today.mission == nil ? nil : next,
                       fill: ColourCard.lesson, action: nil)
        case .complete:
            ColourCard(kicker: String(localized: "Program complete"), title: String(localized: "Replay any session."),
                       detail: nil, fill: ColourCard.lesson, action: nil)
        }
    }
}
