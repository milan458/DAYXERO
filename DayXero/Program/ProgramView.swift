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
                    VStack(alignment: .leading, spacing: DX.Space.xs) {
                        Text("Your program").dxText(.micro)
                        Text("Program").dxText(.title).accessibilityAddTraits(.isHeader)
                        variantLine.padding(.vertical, DX.Space.xs)
                        if let graduated = profile.progress?.graduatedAt { completeHeader(graduated) }
                        nrtGroup(now: timeline.date)
                        if let content = store.content {
                            ForEach(content.phases) { phase in
                                phaseSection(phase, content: content, states: states, current: current, store: store)
                            }
                        }
                    }
                    .padding(.horizontal, DX.Space.m)
                    .dxReadableColumn()
                    .padding(.top, DX.Space.xl)
                    .padding(.bottom, DX.Space.l)
                }
                .onAppear {
                    // Land on the current session.
                    if let current { proxy.scrollTo(current, anchor: .center) }
                }
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
    }

    // MARK: Phases

    @ViewBuilder
    private func phaseSection(_ phase: ProgramContent.Phase, content: ProgramContent, states: [String: ProgramUnlock.State],
                              current: String?, store: ProgramStore) -> some View {
        let sessions = phase.sessionIds.compactMap { content.session($0) }
        let done = sessions.filter { if case .completed = states[$0.id] { true } else { false } }.count
        let allDone = done == sessions.count && !sessions.isEmpty
        HStack(alignment: .firstTextBaseline) {
            Text(verbatim: "\(phase.title) · \(phase.subtitle)").dxText(.micro)
            Spacer()
            Text(verbatim: "\(done) of \(sessions.count)").font(.custom(DX.Typeface.regular, size: 11, relativeTo: .caption2))
                .foregroundStyle(DX.Palette.muted)
        }
        .padding(.top, DX.Space.m)
        .accessibilityAddTraits(.isHeader)
        if allDone, profile.progress?.graduatedAt == nil, !unfolded.contains(phase.id) {
            // A finished phase folds away until the person asks to see it.
            Button { unfolded.insert(phase.id) } label: {
                HStack(spacing: DX.Space.xs) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(DX.Palette.accentInk)
                    Text("\(phase.title) done · show").font(DX.TextStyle.subtitle.font).foregroundStyle(DX.Palette.text2)
                    Spacer()
                }
                .padding(DX.Space.s)
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(DX.Palette.faint, style: StrokeStyle(lineWidth: 1, dash: [4, 4])))
            }
            .buttonStyle(.plain)
        } else {
            ForEach(sessions) { session in
                row(session, state: states[session.id] ?? .locked, isCurrent: session.id == current, store: store)
                    .id(session.id)
            }
        }
    }

    private func row(_ session: ProgramContent.Session, state: ProgramUnlock.State, isCurrent: Bool, store: ProgramStore) -> some View {
        let variant = store.variant
        let title = session.title.resolve(variant) ?? ""
        let open = state == .available || state == .inProgress
        let needsUpgrade = open && ProgramV2Access.needsUpgrade(session.id, isPro: entitlement.isPro)
        return Button {
            tap(session, state: state, title: title, needsUpgrade: needsUpgrade)
        } label: {
            HStack(spacing: DX.Space.s) {
                badge(session, state: state)
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: "\(session.label) · \(session.durationMinutes) min").dxText(.micro)
                    Text(verbatim: title).font(.custom(DX.Typeface.semibold, size: 15, relativeTo: .body)).foregroundStyle(DX.Palette.text)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: DX.Space.xs)
                trailing(state, needsUpgrade: needsUpgrade)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, DX.Space.s)
            .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(open ? DX.Palette.accentInk : DX.Palette.hairline, lineWidth: open ? 1.5 : 1))
            .opacity(state == .locked ? 0.55 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityValue(Text(accessibilityState(state)))
        .popover(isPresented: Binding(get: { waitingTip == session.id }, set: { if !$0 { waitingTip = nil } })) {
            Text(verbatim: waitText(state) ?? "").dxText(.subtitle).padding().presentationCompactAdaptation(.popover)
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

    @ViewBuilder
    private func badge(_ session: ProgramContent.Session, state: ProgramUnlock.State) -> some View {
        let short = session.id == "DX" ? "DX" : session.label.split(separator: " ").last.map(String.init) ?? ""
        ZStack {
            switch state {
            case .completed:
                Circle().fill(DX.Palette.accentSoft)
                Image(systemName: "checkmark").font(.system(size: 13, weight: .bold)).foregroundStyle(DX.Palette.accentInk)
            case .available, .inProgress:
                Circle().fill(DX.Palette.primary)
                Text(verbatim: short).font(.custom(DX.Typeface.semibold, size: 12, relativeTo: .caption)).foregroundStyle(DX.Palette.onPrimary)
            default:
                Circle().fill(DX.Palette.surface2)
                Text(verbatim: short).font(.custom(DX.Typeface.semibold, size: 12, relativeTo: .caption)).foregroundStyle(DX.Palette.text2)
            }
        }
        .frame(width: 32, height: 32)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func trailing(_ state: ProgramUnlock.State, needsUpgrade: Bool) -> some View {
        switch state {
        case .available, .inProgress:
            Text(needsUpgrade ? "Unlock" : state == .inProgress ? "Continue" : "Start")
                .font(.custom(DX.Typeface.semibold, size: 14, relativeTo: .footnote))
                .foregroundStyle(DX.Palette.onPrimary)
                .padding(.horizontal, 16).frame(height: 34)
                .background(DX.Palette.primary, in: Capsule())
        case .scheduled:
            Text(verbatim: waitText(state) ?? "").font(.custom(DX.Typeface.regular, size: 12, relativeTo: .caption))
                .foregroundStyle(DX.Palette.muted).multilineTextAlignment(.trailing).frame(maxWidth: 110, alignment: .trailing)
        case .completed:
            Text("Replay").font(.custom(DX.Typeface.regular, size: 12, relativeTo: .caption)).foregroundStyle(DX.Palette.muted)
        case .locked:
            EmptyView()
        }
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
                .dxText(.micro).foregroundStyle(DX.Palette.accentInk)
            if case let .text(line)? = ProgramStore(context: context, profile: profile).answer("identity_statement") {
                Text(verbatim: "“\(line).”").font(.custom(DX.Typeface.bold, size: 20, relativeTo: .title3)).foregroundStyle(DX.Palette.text)
            }
            Text("Replay any session, any time.").dxText(.subtitle)
        }
        .padding(DX.Space.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DX.Palette.accentSoft, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
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
            Text("Your NRT").dxText(.micro).padding(.top, DX.Space.s)
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
            Image(systemName: "book.closed").foregroundStyle(DX.Palette.accentInk)
            Text(variantText(primary: primary, others: others)).font(DX.TextStyle.subtitle.font).foregroundStyle(DX.Palette.text2)
            Spacer(minLength: 0)
        }
        .padding(DX.Space.s)
        .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(DX.Palette.hairline))
    }

    private func variantText(primary: Product, others: [Product]) -> AttributedString {
        let name: String = switch primary {
        case .cigarettes: String(localized: "Smoking program")
        case .vape: String(localized: "Vaping program")
        case .pouches: String(localized: "Pouches program")
        }
        var text = AttributedString(name)
        text.font = .custom(DX.Typeface.semibold, size: 13, relativeTo: .footnote)
        text.foregroundColor = DX.Palette.text
        if !others.isEmpty {
            let list = ListFormatter.localizedString(byJoining: others.map { String(localized: $0.title).lowercased() })
            text += AttributedString(String(localized: ", with notes for \(list)"))
        }
        return text
    }
}
