import DayXeroCore
import SwiftData
import SwiftUI

/// The Program tab (decision 31): the phase you pick drawn as a winding path on mint, done stops ticked,
/// today's a big play button, later ones locked, the phase's last session as its milestone. Tapping a stop opens a
/// bottom sheet with its illustration, when it opens and what to do (UX-02, 2 Nov 2026); the list of session cards
/// under the path went. Finished sessions replay. Nothing is ever shown as missed, overdue or failed.
struct ProgramView: View {
    private let motion = MotionPolicy()
    let profile: UserProfile
    @Environment(Entitlement.self) private var entitlement
    @Environment(NRTRouter.self) private var nrt
    @Environment(\.modelContext) private var context
    @State private var open: SessionOpen?
    @State private var upgradeTitle: String?
    @State private var showPaywall = false
    /// The stop whose sheet is open (UX-02).
    @State private var sheet: StopSheet?
    /// What the sheet's button asked for, done once the sheet has closed so a session or paywall can open.
    @State private var afterSheet: StopSheet?
    /// Glim's weekly check-in after graduation (S27.18); the same setting as Settings › Notifications.
    @AppStorage(DailyReminderSettings.weeklyKey) private var weekly = DailyReminderSettings.offUntilChosen

    private let ground = DX.Ground.mint
    /// v5 (022): the plan's page is a warm cream in light with sage hills at the bottom; the one navy in dark.
    private let page = Color(light: 0xFBF6EC, dark: 0x0E1322)
    /// Tiles and the note card: kit card-2 on the plan page.
    private let tileFill = Color(light: 0xEEF5EC, dark: 0x212A41)

    var body: some View {
        TimelineView(.everyMinute) { timeline in
            let store = ProgramStore(context: context, profile: profile)
            let states = Dictionary(store.states(now: timeline.date).map { ($0.id, $0.state) }, uniquingKeysWith: { a, _ in a })
            let current = store.current(now: timeline.date)?.id
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if let content = store.content {
                        let phase = selectedPhase(content, current: current)
                        header(phase, states: states, now: timeline.date)
                        if let graduated = profile.progress?.graduatedAt { completeHeader(graduated) }
                        let nextPhase = content.phases.firstIndex { $0.id == phase.id }
                            .flatMap { $0 + 1 < content.phases.count ? content.phases[$0 + 1] : nil }
                        ProgramPathMap(stops: stops(phase, content: content, states: states, current: current, store: store, now: timeline.date),
                                       ground: ground,
                                       goal: nextPhase.map { next in
                                           .init(title: next.title, isDayXero: next.id == "dayxero",
                                                 subtitle: next.id == "dayxero"
                                                    ? profile.quitDay.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()) : nil)
                                       }) { stop in
                            guard let session = content.session(stop.id) else { return }
                            sheet = StopSheet(session: session, title: stop.title, state: states[stop.id] ?? .locked,
                                              needsUpgrade: stop.needsUpgrade)
                        }
                        if let line = teaseLine(phase, content: content, states: states, current: current, variant: store.variant) {
                            // v5 (022): the locked row on the hill, a lock tile and one line.
                            HStack(spacing: 12) {
                                DXIcon(.lock, size: 18, weight: 2.4)
                                    .foregroundStyle(ground.ink)
                                    .frame(width: 34, height: 34)
                                    .background(ground.ink.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                Text(verbatim: line).dxFace(.body, 15, weight: 600).foregroundStyle(ground.ink)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.leading, 10).padding(.trailing, 16)
                            .frame(minHeight: 48)
                            .background(Color(light: (0xFFFFFF, 0.72), dark: (0x182034, 0.8)), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(DX.Ground.reading.line, lineWidth: 1))
                            .accessibilityElement(children: .combine)
                            .dxArrive(0, delay: 2.1)
                        }
                        // After graduation the program keeps going: boosters on Days 45, 60 and 90, and Glim
                        // checking in once a week if they want it (S27.18).
                        if profile.progress?.graduatedAt != nil { weeklyCheckIn }
                    }
                    nrtGroup(now: timeline.date)
                }
                .padding(.horizontal, DX.Layout.gutter)
                .dxReadableColumn()
                .padding(.top, 8)
                .padding(.bottom, DX.Space.l)
            }
            .background(page.ignoresSafeArea())
            .dxGround(.mint, paint: false)
        }
        .sheet(item: $sheet, onDismiss: {
            guard let item = afterSheet else { return }
            afterSheet = nil
            tap(item.session.id, state: item.state, title: item.title, needsUpgrade: item.needsUpgrade)
        }) { item in
            stopSheet(item)
        }
        .dxCover(item: $open, onDismiss: { NotificationCenter.default.post(name: .dxSessionClosed, object: nil) }) { item in
            SessionFlowView(sessionId: item.id, profile: profile, isReplay: item.isReplay)
        }
        .sheet(item: Binding(get: { upgradeTitle.map { SessionOpen(id: $0) } }, set: { upgradeTitle = $0?.id })) { item in
            UpgradeSheet(dayTitle: item.id, model: PaywallModel(store: entitlement.store, entitlement: entitlement),
                         showAllPlans: { upgradeTitle = nil; showPaywall = true },
                         onUnlocked: { upgradeTitle = nil })
                .presentationDetents([.medium, .large])
        }
        .dxCover(isPresented: $showPaywall) {
            PaywallView(name: profile.name, quitDay: profile.quitDay,
                        model: PaywallModel(store: entitlement.store, entitlement: entitlement),
                        onClose: { showPaywall = false })
        }
    }

    // MARK: Phases

    /// The phase picked, else the one holding today's session, else the last.
    private func selectedPhase(_ content: ProgramContent, current: String?) -> ProgramContent.Phase {
        if let current, let phase = content.phases.first(where: { $0.sessionIds.contains(current) }) { return phase }
        return content.phases.last ?? content.phases[0]
    }

    /// v5 (022): "Prep week", then "3 of 7 done · 4 days to Day Xero".
    private func header(_ phase: ProgramContent.Phase, states: [String: ProgramUnlock.State], now: Date) -> some View {
        let done = phase.sessionIds.filter { if case .completed = states[$0] { true } else { false } }.count
        let clock = DayClock(boundaryHour: profile.dayBoundaryHour)
        let days = max(clock.calendar.dateComponents([.day], from: clock.day(containing: now), to: clock.startOfDate(profile.quitDay)).day ?? 0, 0)
        let count = Text("\(done) of \(phase.sessionIds.count)").dxRun(15, weight: 700).foregroundStyle(ground.ink)
        let tail: Text = if phase.id == "prep" {
            days == 0 ? Text(" done · Day Xero is today") : Text(" done · ^[\(days) day](inflect: true) to Day Xero")
        } else {
            Text(" done")
        }
        return VStack(alignment: .leading, spacing: 4) {
            Text(verbatim: phase.id == "prep" ? String(localized: "Prep week") : phase.title)
                .dxType(.large).foregroundStyle(ground.ink)
                .accessibilityAddTraits(.isHeader)
                .dxArrive(0)
            (count + tail).dxType(.footnote).foregroundStyle(ProgramPathMap.muted)
                .dxArrive(1)
        }
    }

    // MARK: Path

    private func stops(_ phase: ProgramContent.Phase, content: ProgramContent, states: [String: ProgramUnlock.State],
                       current: String?, store: ProgramStore, now: Date) -> [ProgramPathMap.Stop] {
        let clock = DayClock(boundaryHour: profile.dayBoundaryHour)
        let today = clock.day(containing: now)
        let ids = phase.sessionIds
        // Sessions open one a day in order: a later one's day follows the one before it.
        var cursor = today
        return ids.enumerated().compactMap { index, id in
            guard let session = content.session(id) else { return nil }
            let state = states[id] ?? .locked
            let open = state == .available || state == .inProgress
            let needsUpgrade = open && ProgramV2Access.needsUpgrade(id, isPro: entitlement.isPro)
            let label = session.label
            let kind: ProgramPathMap.Stop.Kind
            let kicker: String
            switch state {
            case let .completed(date):
                kind = .done
                cursor = clock.day(containing: date)
                kicker = String(localized: "\(label) · \(date.formatted(.dateTime.weekday(.abbreviated))) · done")
            case .available, .inProgress:
                kind = .today
                cursor = today
                let cards = session.deck?.count ?? session.cards?.count ?? 0
                let parts = [String(localized: "Today"), label] + (cards > 0 ? [String(AttributedString(localized: "^[\(cards) card](inflect: true)").characters)] : [])
                    + [String(localized: "\(store.minutes(of: session)) min")]
                kicker = parts.joined(separator: " · ")
            case let .scheduled(wait):
                kind = index == ids.count - 1 ? .goal : .locked
                let opens: Date = switch wait {
                case .tomorrow: clock.calendar.date(byAdding: .day, value: 1, to: today) ?? today
                case let .dayXero(date): clock.startOfDate(date)
                case let .trialEnds(date): clock.startOfDate(date)
                case let .quitDay(days): clock.calendar.date(byAdding: .day, value: days, to: clock.startOfDate(profile.quitDay)) ?? today
                }
                cursor = opens
                kicker = String(localized: "\(label) · opens \(Self.opensText(opens, today: today, calendar: clock.calendar))")
            case .locked:
                kind = index == ids.count - 1 ? .goal : .locked
                cursor = clock.calendar.date(byAdding: .day, value: 1, to: max(cursor, today)) ?? cursor
                kicker = String(localized: "\(label) · opens \(Self.opensText(cursor, today: today, calendar: clock.calendar))")
            }
            return ProgramPathMap.Stop(id: id, title: session.title.resolve(store.variant) ?? "", kicker: kicker, kind: kind,
                                       minutes: store.minutes(of: session), needsUpgrade: needsUpgrade,
                                       accessibility: accessibilityState(state))
        }
    }

    /// "Tue" within the coming week, "Mon, Nov 16" further out.
    private static func opensText(_ date: Date, today: Date, calendar: Calendar) -> String {
        let days = calendar.dateComponents([.day], from: today, to: date).day ?? 0
        return days < 7 ? date.formatted(.dateTime.weekday(.abbreviated))
            : date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }

    /// The locked row on the hill: during prep, when the weeks open; later, what's next.
    private func teaseLine(_ phase: ProgramContent.Phase, content: ProgramContent, states: [String: ProgramUnlock.State],
                           current: String?, variant: ProgramVariant) -> String? {
        if phase.id == "prep" {
            return String(localized: "Weeks 1 to 4 open on \(profile.quitDay.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))")
        }
        return nextLine(content, states: states, current: current, variant: variant)
    }

    /// "Next up: Lower the bar, tomorrow. No rush." for the next session that's waiting.
    private func nextLine(_ content: ProgramContent, states: [String: ProgramUnlock.State], current: String?, variant: ProgramVariant) -> String? {
        for phase in content.phases {
            for id in phase.sessionIds {
                guard case let .scheduled(wait)? = states[id], let session = content.session(id) else { continue }
                let title = session.title.resolve(variant) ?? session.label
                return switch wait {
                case .tomorrow: String(localized: "Next up: \(title), tomorrow. No rush.")
                case let .quitDay(days): String(localized: "Next up: \(title), on Day \(ProgramUnlock.counterDay(daysSinceQuit: days)). No rush.")
                case let .dayXero(date): String(localized: "Day Xero is \(date.formatted(.dateTime.weekday(.wide).day().month(.abbreviated))). No rush.")
                case let .trialEnds(date): String(localized: "Next up: \(title), after your free trial, on \(date.formatted(.dateTime.weekday(.wide).day().month(.abbreviated))).")
                }
            }
        }
        if let current, let next = content.session(after: current), states[current] != nil {
            return String(localized: "Next up: \(next.title.resolve(variant) ?? next.label), after today's. No rush.")
        }
        return nil
    }

    // MARK: Stop sheet (UX-02)

    /// A path stop, as its bottom sheet shows it.
    struct StopSheet: Identifiable {
        let session: ProgramContent.Session
        let title: String
        let state: ProgramUnlock.State
        let needsUpgrade: Bool
        var id: String { session.id }
    }

    /// The stop's illustration, "Prep 3 · 6 min" or when it opens, its title, and one button: Start, Continue,
    /// Replay or Unlock. A stop that isn't open yet says when it will, with nothing to press.
    private func stopSheet(_ item: StopSheet) -> some View {
        let session = item.session
        let open = item.state == .available || item.state == .inProgress
        let done: Bool = if case .completed = item.state { true } else { false }
        let minutes = ProgramStore(context: context, profile: profile).minutes(of: session)
        let kicker: String = if item.needsUpgrade {
            String(localized: "\(session.label) · Unlock to start")
        } else if open {
            String(localized: "Today · \(minutes) min")
        } else if done {
            String(localized: "\(session.label) · \(minutes) min")
        } else {
            String(localized: "\(session.label) · \(waitText(item.state) ?? String(localized: "Comes later"))")
        }
        let button: String? = if item.needsUpgrade {
            String(localized: "Unlock \(session.label)")
        } else if item.state == .inProgress {
            String(localized: "Continue")
        } else if open {
            String(localized: "Start")
        } else if done {
            String(localized: "Replay")
        } else {
            nil
        }
        let note: String? = if done {
            String(localized: "Done. Play it again any time.")
        } else if item.state == .inProgress {
            String(localized: "Xero saved your place.")
        } else if !open {
            String(localized: "No rush. It opens by itself.")
        } else {
            nil
        }
        return VStack(alignment: .leading, spacing: DX.Space.m) {
            HStack(spacing: 14) {
                KitArt(ProgramArt.kind(for: session.id), cornerRadius: 22)
                    .frame(width: 84, height: 84)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(verbatim: kicker).dxType(.footnote).foregroundStyle(DX.Ground.reading.muted)
                    Text(verbatim: item.title).dxType(.title).foregroundStyle(DX.Ground.reading.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            if let note {
                Text(verbatim: note).dxType(.body).foregroundStyle(DX.Ground.reading.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            if let button {
                Button(button) {
                    afterSheet = item
                    sheet = nil
                }
                .buttonStyle(.dx(.primary, on: .reading))
            } else {
                Button("Close") { sheet = nil }
                    .buttonStyle(.dx(.secondary, on: .reading))
            }
        }
        .padding(.horizontal, DX.Layout.gutter)
        .padding(.top, DX.Space.xl)
        .padding(.bottom, DX.Space.s)
        .presentationDetents([.height(340), .medium])
        .presentationDragIndicator(.visible)
        .presentationBackground(DX.Ground.reading.background)
    }

    private func tap(_ id: String, state: ProgramUnlock.State, title: String, needsUpgrade: Bool) {
        switch state {
        case .completed:
            open = SessionOpen(id: id, isReplay: true)
        case .available, .inProgress:
            if needsUpgrade {
                Paywalls.present(.unlockProgramDay, params: ["day": id]) { outcome in
                    switch outcome {
                    case .fallback: upgradeTitle = title
                    case .unlocked: entitlement.grantFromElsewhere()
                    case .closed: break
                    }
                }
            } else {
                open = SessionOpen(id: id)
            }
        case .scheduled, .locked:
            break
        }
    }


    private func waitText(_ state: ProgramUnlock.State) -> String? {
        guard case let .scheduled(wait) = state else { return nil }
        return switch wait {
        case .tomorrow: String(localized: "Unlocks tomorrow")
        case let .dayXero(date): String(localized: "Day Xero is \(date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))")
        case let .quitDay(days): String(localized: "Unlocks on Day \(ProgramUnlock.counterDay(daysSinceQuit: days))")
        case let .trialEnds(date): String(localized: "Opens after your free trial, on \(date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))")
        }
    }

    private func accessibilityState(_ state: ProgramUnlock.State) -> String {
        switch state {
        case .completed: String(localized: "Done. Plays again.")
        case .available: String(localized: "Ready to start")
        case .inProgress: String(localized: "In progress")
        case .scheduled: waitText(state) ?? ""
        case .locked: String(localized: "Comes later")
        }
    }

    private func completeHeader(_ date: Date) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Program complete · \(date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))")
                .v4Text(.micro).foregroundStyle(Read4.accent)
            if case let .text(line)? = ProgramStore(context: context, profile: profile).answer("identity_statement") {
                Text(verbatim: "“\(line).”").dxFont(19, weight: 700, style: .title3).foregroundStyle(Read4.ink)
            }
            Text("Replay any session, any time.").v4Text(.subtitle)
        }
        .padding(DX.Space.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Read4.accentSoft, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }


    /// "Every Sunday · 1 min / Glim checks in: how was your week?" with a switch (S27.18). Off until chosen.
    private var weeklyCheckIn: some View {
        Toggle(isOn: Binding(get: { weekly >= 0 }, set: { on in
            weekly = on ? DailyReminderSettings.defaultWeekly : DailyReminderSettings.offUntilChosen
            DailyReminders.refresh(in: context)
        })) {
            HStack(spacing: 12) {
                GlimView(mood: .calm, stage: CrewGrowth.stage(daysClear: 31), size: .avatar, animate: false)
                    .frame(width: 40, height: 40)
                    .background(DX.Ground.violet.background, in: Circle())
                    .clipShape(Circle())
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Every Sunday · 1 min").dxType(.caption).foregroundStyle(DX.Ground.reading.muted)
                    Text("Glim checks in: how was your week?").dxType(.headline).foregroundStyle(DX.Ground.reading.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .tint(DX.Fill.green)
        .padding(.horizontal, 14).padding(.vertical, 12)
        .frame(minHeight: 44)
        .background(tileFill, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.top, DX.Space.xs)
    }

    // MARK: NRT

    /// NRT plans and the pouch step-down live here once they're set up; Home only invites (S19.6).
    /// A plan stays until a week after its last step.
    @ViewBuilder
    private func nrtGroup(now: Date) -> some View {
        let clock = DayClock(boundaryHour: profile.dayBoundaryHour)
        let plans = profile.nrtPlans.filter { plan in
            guard let end = StepSchedule(startDate: plan.startDate, steps: plan.steps, clock: clock).end else { return false }
            return clock.day(containing: now) < (clock.calendar.date(byAdding: .day, value: 7, to: end) ?? end)
        }
        let prep = ProgressStats(quitDay: profile.quitDay, baselines: [], clock: clock).isPrep(at: now)
        let taper = prep ? profile.pouchTaper : nil
        // The invitations moved here from Today, which no longer scrolls (UX-07).
        if profile.nrtPlans.isEmpty, profile.nrtInterest == .using || profile.nrtInterest == .wantIt {
            NRTInviteRow(title: "Set up your NRT", detail: "Reminders for patches and step-downs", systemImage: "bandage") {
                nrt.sheet = .setup
            }
            .padding(.top, DX.Space.xs)
        }
        if prep, profile.pouchTaper == nil, profile.products.contains(where: { $0.product == .pouches }) {
            NRTInviteRow(title: "Step down your pouches", detail: "Optional, before Quit Day", systemImage: "chart.line.downtrend.xyaxis") {
                nrt.sheet = .taper
            }
        }
        if !plans.isEmpty || taper != nil {
            Text("Your NRT").v4Text(.micro).padding(.top, DX.Space.s)
            ForEach(plans.sorted { $0.createdAt < $1.createdAt }) { plan in
                NRTCard(plan: plan, clock: clock, now: now)
            }
            if let taper {
                Button { nrt.sheet = .taper } label: { TaperCard(taper: taper, clock: clock, now: now) }.buttonStyle(.plain)
            }
        }
    }
}
