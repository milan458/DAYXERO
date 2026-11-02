import DayXeroCore
import SwiftData
import SwiftUI

/// The Program tab (decision 31): the phase you pick drawn as a winding path on mint, done stops ticked,
/// today's a big play button, later ones locked, the phase's last session as its milestone. Tapping a stop opens a
/// bottom sheet with its illustration, when it opens and what to do (UX-02, 2 Nov 2026); the list of session cards
/// under the path went. Finished sessions replay. Nothing is ever shown as missed, overdue or failed.
struct ProgramView: View {
    let profile: UserProfile
    @Environment(Entitlement.self) private var entitlement
    @Environment(NRTRouter.self) private var nrt
    @Environment(\.modelContext) private var context
    @State private var open: SessionOpen?
    @State private var upgradeTitle: String?
    @State private var showPaywall = false
    @State private var picked: String?
    /// The stop whose sheet is open (UX-02).
    @State private var sheet: StopSheet?
    /// What the sheet's button asked for, done once the sheet has closed so a session or paywall can open.
    @State private var afterSheet: StopSheet?
    /// Glim's weekly check-in after graduation (S27.18); the same setting as Settings › Notifications.
    @AppStorage(DailyReminderSettings.weeklyKey) private var weekly = DailyReminderSettings.offUntilChosen

    private let ground = DX.Ground.mint
    /// Tiles and the note card on mint: cream in light, deep green in dark.
    private let tileFill = Color(light: 0xFFF8EE, dark: 0x16382D)

    var body: some View {
        TimelineView(.everyMinute) { timeline in
            let store = ProgramStore(context: context, profile: profile)
            let states = Dictionary(store.states(now: timeline.date).map { ($0.id, $0.state) }, uniquingKeysWith: { a, _ in a })
            let current = store.current(now: timeline.date)?.id
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Prep, Quit Day, then four weeks").dxType(.footnote).foregroundStyle(ground.muted)
                        // Plain title: the hand-drawn mark is kept for celebrations and onboarding (S27.15).
                        Text("Your program")
                            .dxType(.large).foregroundStyle(ground.ink)
                            .accessibilityAddTraits(.isHeader)
                    }
                    if let content = store.content {
                        let phase = selectedPhase(content, current: current)
                        phasePicker(content, states: states, current: current, selected: phase.id)
                        if let graduated = profile.progress?.graduatedAt { completeHeader(graduated) }
                        ProgramPathMap(stops: stops(phase, content: content, states: states, current: current, store: store),
                                       ground: ground) { stop in
                            guard let session = content.session(stop.id) else { return }
                            sheet = StopSheet(session: session, title: stop.title, state: states[stop.id] ?? .locked,
                                              needsUpgrade: stop.needsUpgrade)
                        }
                        if let line = nextLine(content, states: states, current: current, variant: store.variant) {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "lock.open").font(.system(size: 15, weight: .semibold)).foregroundStyle(DX.Fill.green)
                                    .accessibilityHidden(true)
                                Text(verbatim: line).dxType(.footnote).foregroundStyle(DX.Ground.reading.ink)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(14)
                            .background(tileFill, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        }
                        Text(verbatim: phaseHeading(phase, states: states)).dxType(.footnote)
                            .foregroundStyle(ground.muted)
                        // After graduation the program keeps going: boosters on Days 45, 60 and 90, and Glim
                        // checking in once a week if they want it (S27.18).
                        if profile.progress?.graduatedAt != nil { weeklyCheckIn }
                    }
                    variantLine.padding(.top, DX.Space.s)
                    nrtGroup(now: timeline.date)
                }
                .padding(.horizontal, DX.Layout.gutter)
                .dxReadableColumn()
                .padding(.top, DX.Space.l)
                .padding(.bottom, DX.Space.l)
            }
            .background(ground.background.ignoresSafeArea())
        }
        .sheet(item: $sheet, onDismiss: {
            guard let item = afterSheet else { return }
            afterSheet = nil
            tap(item.session.id, state: item.state, title: item.title, needsUpgrade: item.needsUpgrade)
        }) { item in
            stopSheet(item)
        }
        .fullScreenCover(item: $open, onDismiss: { NotificationCenter.default.post(name: .dxSessionClosed, object: nil) }) { item in
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
    }

    // MARK: Phases

    /// The phase picked, else the one holding today's session, else the last.
    private func selectedPhase(_ content: ProgramContent, current: String?) -> ProgramContent.Phase {
        if let picked, let phase = content.phases.first(where: { $0.id == picked }) { return phase }
        if let current, let phase = content.phases.first(where: { $0.sessionIds.contains(current) }) { return phase }
        return content.phases.last ?? content.phases[0]
    }

    /// Phase pills in a track: a tick when done, ink for the one shown. The track runs edge to edge and scrolls the
    /// pill shown to the centre, with the ends fading out, so a pill is never cut off mid-word at the screen edge.
    private func phasePicker(_ content: ProgramContent, states: [String: ProgramUnlock.State], current: String?, selected: String) -> some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    ForEach(content.phases) { phase in
                        let done = !phase.sessionIds.isEmpty && phase.sessionIds.allSatisfy { if case .completed = states[$0] { true } else { false } }
                        let on = phase.id == selected
                        Button {
                            withAnimation(DX.Move.settle) { picked = phase.id }
                        } label: {
                            HStack(spacing: 4) {
                                Text(verbatim: phase.title).dxFont(14, weight: 700, style: .footnote)
                                    .lineLimit(1)
                                if done { Image(systemName: "checkmark").font(.system(size: 11, weight: .heavy)) }
                            }
                            // A pill is as wide as its title: it scrolls rather than squeezing or wrapping.
                            .fixedSize()
                            .foregroundStyle(on ? DX.Ground.reading.background : ground.ink)
                            .padding(.horizontal, 14)
                            .frame(minHeight: DX.Layout.touchTarget)
                            .background(on ? ground.ink : Color.clear, in: Capsule())
                            .contentShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .id(phase.id)
                        .accessibilityAddTraits(on ? [.isButton, .isSelected] : .isButton)
                        .accessibilityValue(Text(done ? "Done" : ""))
                    }
                }
                .padding(4)
                .background(Color(light: (0x1E1A3A, 0.08), dark: (0xFFFFFF, 0.08)), in: Capsule())
            }
            // At rest the track lines up with the title; scrolled, it runs to the screen edges under the fades.
            .contentMargins(.horizontal, DX.Layout.gutter, for: .scrollContent)
            .padding(.horizontal, -DX.Layout.gutter)
            .mask { Self.edgeFade }
            .onAppear { proxy.scrollTo(selected, anchor: .center) }
            .onChange(of: selected) { _, id in
                withAnimation(DX.Move.settle) { proxy.scrollTo(id, anchor: .center) }
            }
        }
    }

    /// Opaque in the middle, fading to clear over the gutter at each end.
    private static var edgeFade: some View {
        HStack(spacing: 0) {
            LinearGradient(colors: [.clear, .black], startPoint: .leading, endPoint: .trailing)
                .frame(width: DX.Layout.gutter)
            Rectangle().fill(.black)
            LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing)
                .frame(width: DX.Layout.gutter)
        }
    }

    private func phaseHeading(_ phase: ProgramContent.Phase, states: [String: ProgramUnlock.State]) -> String {
        let done = phase.sessionIds.filter { if case .completed = states[$0] { true } else { false } }.count
        return String(localized: "\(phase.title) · \(done) of \(phase.sessionIds.count) done")
    }

    // MARK: Path

    private func stops(_ phase: ProgramContent.Phase, content: ProgramContent, states: [String: ProgramUnlock.State],
                       current: String?, store: ProgramStore) -> [ProgramPathMap.Stop] {
        let ids = phase.sessionIds
        return ids.enumerated().compactMap { index, id in
            guard let session = content.session(id) else { return nil }
            let state = states[id] ?? .locked
            let open = state == .available || state == .inProgress
            let needsUpgrade = open && ProgramV2Access.needsUpgrade(id, isPro: entitlement.isPro)
            let kind: ProgramPathMap.Stop.Kind
            if case .completed = state { kind = .done }
            else if open && !needsUpgrade { kind = .today }
            else if index == ids.count - 1 { kind = .goal }
            else { kind = .locked }
            return ProgramPathMap.Stop(id: id, title: session.title.resolve(store.variant) ?? "", kind: kind,
                                       minutes: session.durationMinutes, needsUpgrade: needsUpgrade,
                                       accessibility: accessibilityState(state))
        }
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
        let kicker: String = if item.needsUpgrade {
            String(localized: "\(session.label) · Unlock to start")
        } else if open {
            String(localized: "Today · \(session.durationMinutes) min")
        } else if done {
            String(localized: "\(session.label) · \(session.durationMinutes) min")
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
                    case .unlocked: entitlement.grant()
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

    private var variantLine: some View {
        let primary = profile.primaryProduct?.product ?? .cigarettes
        let others = profile.products.map(\.product).filter { $0 != primary }
        return HStack(spacing: DX.Space.xs) {
            Image(systemName: "book.closed").foregroundStyle(Read4.accent)
            Text(variantText(primary: primary, others: others)).dxType(.footnote).foregroundStyle(Read4.muted)
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Read4.card, in: RoundedRectangle(cornerRadius: DX.Layout.smallCardRadius, style: .continuous))
    }

    private func variantText(primary: Product, others: [Product]) -> AttributedString {
        let name: String = switch primary {
        case .cigarettes: String(localized: "Smoking program")
        case .vape: String(localized: "Vaping program")
        case .pouches: String(localized: "Pouches program")
        }
        var text = AttributedString(name)
        text.font = DX.Typeface4.swiftUIFont(.body, size: 14, weight: 600)
        text.foregroundColor = Read4.ink
        if !others.isEmpty {
            let list = ListFormatter.localizedString(byJoining: others.map { String(localized: $0.title).lowercased() })
            text += AttributedString(String(localized: ", with notes for \(list)"))
        }
        return text
    }
}
