import DayXeroCore
import SwiftData
import SwiftUI

/// Which session to open, and whether as a replay.
struct SessionOpen: Identifiable, Hashable {
    let id: String
    var isReplay = false
}

/// Free tier (BET-1, 3 Nov 2026): the counter, Craving SOS, the 60-second breathing timer, and each prep session's
/// intro and first two cards, then the prep-day paywall. Day Xero onwards needs Pro or the 7-day trial. See `FullProgram`.
enum ProgramV2Access {
    /// Sessions a free user opens for their free part.
    static var previewSessions: Set<String> { FullProgram.previewSessionIds }
    /// The Day Xero session: its completion is the sun moment, and anyone still without the full program gets the
    /// Quit Day offer after it once (decision 23). Under MON-01 Day Xero is paid, so that only happens to someone
    /// whose subscription ended part-way.
    static let offerAfter = "DX"

    static func needsUpgrade(_ sessionId: String, isPro: Bool) -> Bool {
        !DemoMode.isOn && FullProgram.needsUpgrade(sessionId: sessionId, isPro: isPro)
    }

    /// How a session opens; demo mode opens everything in full.
    static func access(_ sessionId: String, isPro: Bool, completed: Bool = false) -> FullProgram.Access {
        DemoMode.isOn ? .full : FullProgram.access(sessionId: sessionId, isPro: isPro, completed: completed)
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
    /// Quit Day has come and this is a prep session left over: catch-up that never holds back Day Xero (S27.7).
    let prepRunsOver: Bool
    /// A quit-week session from an earlier day. Today's header counts "Day 3" by the calendar, so a "Day 2" session
    /// is labelled a catch-up rather than "Today", and the screen never shows two different days as today (S27.5).
    /// Prep left over after the Quit Day is a catch-up too (S27.7).
    let isCatchUp: Bool

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
            isCatchUp = false
            return
        }
        label = session.label
        title = session.title.resolve(variant) ?? ""
        minutes = store.minutes(of: session)
        prepRunsOver = session.phaseId == "prep" && store.clock.day(containing: now) >= store.clock.startOfDate(store.profile.quitDay)
        if prepRunsOver {
            isCatchUp = true
        } else if session.phaseId == "w1", session.unlock.rule == .daysSinceQuit, let minDay = session.unlock.minDay,
           let quit = store.profile.progress?.quitTimestamp, let engine = store.unlock() {
            isCatchUp = engine.daysSinceQuit(quit, now: now) > minDay
        } else {
            isCatchUp = false
        }
        switch current.state {
        case .available, .inProgress:
            kind = .open(sessionId: session.id, inProgress: current.state == .inProgress,
                         needsUpgrade: ProgramV2Access.needsUpgrade(session.id, isPro: isPro))
        case let .scheduled(wait):
            let next: String = switch wait {
            case .tomorrow: String(localized: "Next session tomorrow")
            case let .dayXero(date): String(localized: "Day Xero is \(date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))")
            case let .quitDay(days): String(localized: "Next session on Day \(ProgramUnlock.counterDay(daysSinceQuit: days))")
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
    /// False while Today's focus is another card (UX-08). The card stays in place, drawn as nothing, so a session it
    /// opened stays open and Prep 1 still opens by itself after onboarding.
    var showsCard = true

    @Environment(\.modelContext) private var context
    @Environment(Entitlement.self) private var entitlement
    @State private var open: SessionOpen?
    @State private var upgradeTitle: String?
    @State private var showPaywall = false

    var body: some View {
        let store = ProgramStore(context: context, profile: profile)
        Group {
            if showsCard, let today = ProgramToday(store: store, isPro: entitlement.isPro) {
                card(today)
            } else {
                // A real view, so the covers below stay attached while the card is hidden.
                Color.clear.frame(height: 0).accessibilityHidden(true)
            }
        }
        .fullScreenCover(item: $open, onDismiss: {
            NotificationCenter.default.post(name: .dxSessionClosed, object: nil)
        }) { item in
            SessionFlowView(sessionId: item.id, profile: profile, isReplay: item.isReplay)
        }
        .sheet(item: Binding(get: { upgradeTitle.map { SessionOpen(id: $0) } }, set: { upgradeTitle = $0?.id })) { item in
            UpgradeSheet(dayTitle: item.id, model: PaywallModel(store: entitlement.store, entitlement: entitlement),
                         showAllPlans: { upgradeTitle = nil; showPaywall = true },
                         onUnlocked: { upgradeTitle = nil })
                .presentationDetents([.medium, .large])
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(name: profile.name, quitDay: profile.quitDay,
                        model: PaywallModel(store: entitlement.store, entitlement: entitlement),
                        onClose: { showPaywall = false })
        }
        .task {
            // Let Home's cross-fade from onboarding settle before the session rises over it (QW6).
            guard UserDefaults.standard.bool(forKey: FirstLesson.key) else { return }
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            openQueuedFirstSession()
        }
    }

    /// Prep 1 opens once, after "Start my prep week" queued it (S22, QW1).
    private func openQueuedFirstSession() {
        guard UserDefaults.standard.bool(forKey: FirstLesson.key) else { return }
        UserDefaults.standard.set(false, forKey: FirstLesson.key)
        let store = ProgramStore(context: context, profile: profile)
        guard case .open(let id, _, false)? = ProgramToday(store: store, isPro: entitlement.isPro)?.kind else { return }
        open = SessionOpen(id: id)
    }

    /// The green lesson card: "Prep 3" (or "Catch up · Day 2" when behind), "Use with your eyes open · 6 min", and
    /// a Start, Continue or Unlock pill (UX-12).
    @ViewBuilder
    private func card(_ today: ProgramToday) -> some View {
        switch today.kind {
        case let .open(id, inProgress, needsUpgrade):
            // UX-12: "Prep 1" / "The first one of the day · 5 min" / Start. The label once, the title with its length.
            let detail: String? = needsUpgrade ? nil
                : today.prepRunsOver ? String(localized: "Prep catch-up, whenever you like. It never holds back Day Xero.")
                : inProgress ? String(localized: "Xero saved your place.") : nil
            let button: String = needsUpgrade ? String(localized: "Unlock") : inProgress ? String(localized: "Continue") : String(localized: "Start")
            ColourCard(kicker: today.isCatchUp ? String(localized: "Catch up · \(today.label)") : today.label,
                       title: String(localized: "\(today.title) · \(today.minutes) min"),
                       detail: detail, fill: ColourCard.lesson, actionTitle: button) {
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
            .accessibilityIdentifier("today.lesson")
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
