import DayXeroCore
import SwiftData
import SwiftUI

/// The Program tab (handoff 4.1): a path through prep, Day Xero and the four weeks after, grouped by phase.
/// Finished sessions can be replayed, the current one is highlighted, the next shows when it opens, and later ones
/// are dimmed with their titles showing. Nothing is ever shown as missed, overdue or failed.
struct ProgramView: View {
    let profile: UserProfile
    @Environment(Entitlement.self) private var entitlement
    @Environment(NRTRouter.self) private var nrt
    @Environment(\.modelContext) private var context
    @State private var open: SessionOpen?
    @State private var upgradeTitle: String?
    @State private var showPaywall = false
    @State private var unfolded: Set<String> = []
    @State private var waitingTip: String?

    var body: some View {
        TimelineView(.everyMinute) { timeline in
            let store = ProgramStore(context: context, profile: profile)
            let states = Dictionary(store.states(now: timeline.date).map { ($0.id, $0.state) }, uniquingKeysWith: { a, _ in a })
            let current = store.current(now: timeline.date)?.id
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Prep, Quit Day, then four weeks").dxType(.caption).textCase(.uppercase).foregroundStyle(Read4.muted)
                        Text("Your program").dxType(.large).foregroundStyle(Read4.ink).accessibilityAddTraits(.isHeader)
                        if let content = store.content {
                            phasePills(content, states: states, current: current, proxy: proxy)
                        }
                        variantLine.padding(.vertical, DX.Space.xxs)
                        if let graduated = profile.progress?.graduatedAt { completeHeader(graduated) }
                        nrtGroup(now: timeline.date)
                        if let content = store.content {
                            ForEach(content.phases) { phase in
                                phaseSection(phase, content: content, states: states, current: current, store: store)
                                    .id("phase-\(phase.id)")
                            }
                            if let line = nextLine(content, states: states, variant: store.variant) {
                                Text(verbatim: line).dxType(.footnote).foregroundStyle(Read4.muted)
                                    .frame(maxWidth: .infinity).multilineTextAlignment(.center)
                                    .padding(.top, DX.Space.s)
                            }
                        }
                    }
                    .padding(.horizontal, DX.Layout.gutter)
                    .dxReadableColumn()
                    .padding(.top, DX.Space.l)
                    .padding(.bottom, DX.Space.l)
                }
                .background(Read4.background)
                .onAppear {
                    // Land on the current session.
                    if let current { proxy.scrollTo(current, anchor: .center) }
                }
            }
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

    @ViewBuilder
    private func phaseSection(_ phase: ProgramContent.Phase, content: ProgramContent, states: [String: ProgramUnlock.State],
                              current: String?, store: ProgramStore) -> some View {
        let sessions = phase.sessionIds.compactMap { content.session($0) }
        let done = sessions.filter { if case .completed = states[$0.id] { true } else { false } }.count
        let allDone = done == sessions.count && !sessions.isEmpty
        VStack(alignment: .leading, spacing: 8) {
        HStack(alignment: .firstTextBaseline) {
            Text(verbatim: "\(phase.title) · \(phase.subtitle)").v4Text(.micro)
            Spacer()
            Text(verbatim: "\(done) of \(sessions.count)").dxFont(12, weight: 400, style: .caption2)
                .foregroundStyle(Read4.muted)
        }
        .padding(.top, DX.Space.m)
        .accessibilityAddTraits(.isHeader)
        if allDone, profile.progress?.graduatedAt == nil, !unfolded.contains(phase.id) {
            // A finished phase folds away until the person asks to see it.
            Button { unfolded.insert(phase.id) } label: {
                HStack(spacing: DX.Space.xs) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Read4.accent)
                    Text("\(phase.title) done · show").dxType(.footnote).foregroundStyle(Read4.muted)
                    Spacer()
                }
                .padding(DX.Space.s)
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Read4.faint, style: StrokeStyle(lineWidth: 1, dash: [4, 4])))
            }
            .buttonStyle(.plain)
        } else {
            ForEach(sessions) { session in
                row(session, state: states[session.id] ?? .locked, isCurrent: session.id == current, store: store)
                    .id(session.id)
            }
        }
        }
    }

    /// Phase pills: a tick when a phase is done, ink for the one you're in. A tap scrolls to it.
    private func phasePills(_ content: ProgramContent, states: [String: ProgramUnlock.State], current: String?,
                            proxy: ScrollViewProxy) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(content.phases) { phase in
                    let ids = phase.sessionIds
                    let done = !ids.isEmpty && ids.allSatisfy { if case .completed = states[$0] { true } else { false } }
                    let now = current.map(ids.contains) ?? false
                    Button {
                        withAnimation(DX.Move.settle) { proxy.scrollTo("phase-\(phase.id)", anchor: .top) }
                    } label: {
                        HStack(spacing: 6) {
                            if done { Image(systemName: "checkmark.circle.fill").foregroundStyle(now ? Read4.onInk : Read4.accent) }
                            Text(verbatim: phase.title).dxFont(14, weight: now ? 700 : 600, style: .footnote)
                        }
                        .foregroundStyle(now ? Read4.onInk : Read4.ink)
                        .padding(.horizontal, 14)
                        .frame(minHeight: 44)
                        .background(now ? Read4.ink : Read4.surface, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityValue(Text(done ? "Done" : now ? "Now" : ""))
                }
            }
        }
        .scrollClipDisabled()
    }

    /// "Day 4 opens tomorrow. No rush." for the next session that's waiting.
    private func nextLine(_ content: ProgramContent, states: [String: ProgramUnlock.State], variant: ProgramVariant) -> String? {
        for phase in content.phases {
            for id in phase.sessionIds {
                guard case let .scheduled(wait)? = states[id], let session = content.session(id) else { continue }
                return switch wait {
                case .tomorrow: String(localized: "\(session.label) opens tomorrow. No rush.")
                case let .quitDay(day): String(localized: "\(session.label) opens on Day \(day). No rush.")
                case let .dayXero(date): String(localized: "Day Xero is \(date.formatted(.dateTime.weekday(.wide).day().month(.abbreviated))). No rush.")
                }
            }
        }
        return nil
    }

    /// A day card (F10): done (green tick), today (apricot, play), waiting or later (lock). Nothing reads as missed.
    private func row(_ session: ProgramContent.Session, state: ProgramUnlock.State, isCurrent: Bool, store: ProgramStore) -> some View {
        let variant = store.variant
        let title = session.title.resolve(variant) ?? ""
        let open = state == .available || state == .inProgress
        let needsUpgrade = open && ProgramV2Access.needsUpgrade(session.id, isPro: entitlement.isPro)
        let today = open && !needsUpgrade
        let ground: DX.Ground = today ? .apricot : .reading
        return Button {
            tap(session, state: state, title: title, needsUpgrade: needsUpgrade)
        } label: {
            HStack(spacing: 14) {
                badge(session, state: state, needsUpgrade: needsUpgrade)
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: kicker(session, state: state, needsUpgrade: needsUpgrade).uppercased())
                        .dxType(.caption).foregroundStyle(ground.muted)
                    Text(verbatim: title).dxType(.headline).foregroundStyle(ground.ink)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                if case .completed = state {
                    Image(systemName: "arrow.counterclockwise").font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Read4.muted).accessibilityHidden(true)
                }
            }
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: DX.Layout.smallCardRadius, style: .continuous)
                    .fill(today ? DX.Ground.apricot.background : Read4.card)
                    .shadow(color: .black.opacity(today ? 0.14 : 0), radius: 0, x: 0, y: 5)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityValue(Text(accessibilityState(state)))
        .popover(isPresented: Binding(get: { waitingTip == session.id }, set: { if !$0 { waitingTip = nil } })) {
            Text(verbatim: waitText(state) ?? "").v4Text(.subtitle).padding().presentationCompactAdaptation(.popover)
        }
    }

    /// "TODAY · DAY 3 · 3 MIN", "DONE · DAY 2", "OPENS TOMORROW", or the label and length.
    private func kicker(_ session: ProgramContent.Session, state: ProgramUnlock.State, needsUpgrade: Bool) -> String {
        switch state {
        case .available, .inProgress:
            needsUpgrade ? String(localized: "\(session.label) · Unlock to start")
                : String(localized: "Today · \(session.label) · \(session.durationMinutes) min")
        case .completed: String(localized: "Done · \(session.label) · Replay")
        case .scheduled: "\(session.label) · \(waitText(state) ?? "")"
        case .locked: String(localized: "\(session.label) · \(session.durationMinutes) min")
        }
    }

    private func tap(_ session: ProgramContent.Session, state: ProgramUnlock.State, title: String, needsUpgrade: Bool) {
        switch state {
        case .completed:
            open = SessionOpen(id: session.id, isReplay: true)
        case .available, .inProgress:
            if needsUpgrade {
                Paywalls.present(.unlockProgramDay, params: ["day": session.id]) { outcome in
                    switch outcome {
                    case .fallback: upgradeTitle = title
                    case .unlocked: entitlement.grant()
                    case .closed: break
                    }
                }
            } else {
                open = SessionOpen(id: session.id)
            }
        case .scheduled:
            waitingTip = session.id
        case .locked:
            break
        }
    }

    private func badge(_ session: ProgramContent.Session, state: ProgramUnlock.State, needsUpgrade: Bool) -> some View {
        let (icon, box, ink): (String, Color, Color) = switch state {
        case .completed: ("checkmark", DX.Fill.green, DX.Fill.cream)
        case .available, .inProgress:
            needsUpgrade ? ("lock.open.fill", Read4.surface, Read4.ink)
                : ("play.fill", Color(light: 0x1E1A3A, dark: 0xFFC38A), Color(light: 0xFFF8EE, dark: 0x241433))
        case .scheduled, .locked: ("lock.fill", Read4.surface, Read4.muted)
        }
        return Image(systemName: icon)
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(ink)
            .frame(width: 40, height: 40)
            .background(box, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .accessibilityHidden(true)
    }

    private func waitText(_ state: ProgramUnlock.State) -> String? {
        guard case let .scheduled(wait) = state else { return nil }
        return switch wait {
        case .tomorrow: String(localized: "Unlocks tomorrow")
        case let .dayXero(date): String(localized: "Day Xero is \(date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))")
        case let .quitDay(day): String(localized: "Unlocks on Day \(day)")
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
        let taper = ProgressStats(quitDay: profile.quitDay, baselines: [], clock: clock).isPrep(at: now) ? profile.pouchTaper : nil
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
