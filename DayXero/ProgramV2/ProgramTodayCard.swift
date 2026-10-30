import DayXeroCore
import SwiftData
import SwiftUI

/// Which session to open, and whether as a replay.
struct SessionOpen: Identifiable, Hashable {
    let id: String
    var isReplay = false
}

/// Free tier: the counter, Craving SOS and Prep 1. Everything after Prep 1 needs Pro or the trial.
enum ProgramV2Access {
    static let freeSessions: Set<String> = ["P1"]

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
    @Environment(\.colorScheme) private var colorScheme
    @State private var open: SessionOpen?
    @State private var upgradeTitle: String?
    @State private var showPaywall = false

    var body: some View {
        let store = ProgramStore(context: context, profile: profile)
        Group {
            if let today = ProgramToday(store: store, isPro: entitlement.isPro) {
                card(today)
            }
        }
        .fullScreenCover(item: $open) { item in
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
    }

    /// Prep 1 opens by itself the first time Home shows after the paywall (S22).
    private func openQueuedFirstSession() {
        guard UserDefaults.standard.bool(forKey: FirstLesson.key) else { return }
        UserDefaults.standard.set(false, forKey: FirstLesson.key)
        let store = ProgramStore(context: context, profile: profile)
        guard case .open(let id, _, false)? = ProgramToday(store: store, isPro: entitlement.isPro)?.kind else { return }
        open = SessionOpen(id: id)
    }

    @ViewBuilder
    private func card(_ today: ProgramToday) -> some View {
        let ink = DX.Palette.onPrimary
        let accent = Color(light: 0xBCC388, dark: 0x55621F)
        let shape = RoundedRectangle(cornerRadius: DX.Radius.hero, style: .continuous)
        VStack(alignment: .leading, spacing: 10) {
            switch today.kind {
            case let .open(id, inProgress, needsUpgrade):
                HStack {
                    Text(verbatim: "\(today.label) · \(today.minutes) min").dxText(.micro, color: accent)
                    Spacer()
                    if needsUpgrade { badge("Pro") }
                }
                Text(verbatim: today.title).font(.custom(DX.Typeface.bold, size: 22, relativeTo: .title2)).tracking(-0.4).foregroundStyle(ink)
                    .fixedSize(horizontal: false, vertical: true)
                if today.prepRunsOver {
                    Text("Finish prep when you're ready. Day Xero starts the morning after.")
                        .font(.custom(DX.Typeface.regular, size: 14, relativeTo: .subheadline)).foregroundStyle(ink.opacity(0.7))
                }
                if needsUpgrade {
                    button(String(localized: "Unlock \(today.label)"), systemImage: "lock.open") {
                        Paywalls.present(.unlockProgramDay, params: ["day": id]) { outcome in
                            switch outcome {
                            case .fallback: upgradeTitle = today.title
                            case .unlocked: entitlement.grant()
                            case .closed: break
                            }
                        }
                    }
                } else {
                    button(inProgress ? String(localized: "Continue") : String(localized: "Start · \(today.minutes) min"),
                           systemImage: "play.fill") { open = SessionOpen(id: id) }
                }
            case let .waiting(next):
                Text(today.mission == nil ? "Up next" : "Today's mission").dxText(.micro, color: accent)
                if let mission = today.mission {
                    Text(verbatim: mission).font(.custom(DX.Typeface.semibold, size: 18, relativeTo: .title3)).foregroundStyle(ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Label {
                    Text(verbatim: next).dxText(.subtitle, color: ink.opacity(0.7))
                } icon: {
                    Image(systemName: "clock").foregroundStyle(ink.opacity(0.5))
                }
            case .complete:
                Text("Program complete").dxText(.micro, color: accent)
                Text("Program complete. Replay any session.").font(.custom(DX.Typeface.bold, size: 20, relativeTo: .title3))
                    .foregroundStyle(ink)
            }
        }
        .padding(DX.Space.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack(alignment: .bottom) {
                shape.fill(DX.Palette.primary)
                Hills(still: true).frame(height: 64).opacity(0.55)
                    .environment(\.colorScheme, colorScheme == .dark ? .light : .dark)
            }
            .clipShape(shape)
        }
        .shadow(color: DX.Palette.sage.opacity(0.15), radius: 20)
        .shadow(color: DX.Palette.shadow, radius: 24, y: 12)
    }

    private func badge(_ text: LocalizedStringKey) -> some View {
        Text(text).font(.custom(DX.Typeface.bold, size: 10, relativeTo: .caption2)).textCase(.uppercase)
            .foregroundStyle(DX.Palette.onAccent)
            .padding(.vertical, 4).padding(.horizontal, 10)
            .background(DX.Palette.sage, in: Capsule())
    }

    private func button(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.custom(DX.Typeface.semibold, size: 15, relativeTo: .subheadline))
                .foregroundStyle(DX.Palette.primary)
                .frame(maxWidth: .infinity, minHeight: DX.Size.compactButtonHeight)
                .background(DX.Palette.onPrimary, in: Capsule())
        }
        .buttonStyle(.plain)
        .padding(.top, DX.Space.xs)
    }
}
