import DayXeroCore
import SwiftData
import SwiftUI

/// The app after onboarding: four tabs, Today · Program · SOS · Progress (S27.11, 1 Nov 2026). Evening folded into
/// Today's evening and night states; Me became Progress, with Settings behind its gear. On iPhone Duo with vertical
/// bars, the older dock stands on the side edge.
struct HomeView: View {
    let profile: UserProfile
    @State private var tab = UserDefaults.standard.string(forKey: "dx.tab") ?? "today"
    @Environment(SOSRouter.self) private var sos
    @Environment(Entitlement.self) private var entitlement
    @Environment(\.scenePhase) private var scenePhase
    /// Where iPhone Duo puts vertical bars right now; nil on other iPhones and where it doesn't (S18.13).
    @State private var barEdge: HorizontalEdge?

    var body: some View {
        GeometryReader { geo in
            let edge = dockEdge(in: geo.size)
            let alignment: Alignment = edge == nil ? .bottom : edge == .leading ? .leading : .trailing
            let dockPadding: Edge.Set = edge == nil ? .bottom : edge == .leading ? .leading : .trailing
            ZStack(alignment: alignment) {
                tabContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    // Every tab scrolls clear of the dock, on whichever edge it stands (S18.13). The inset covers the
                    // raised SOS button too, with room to spare, so the bar never sits over the last card (UX-11).
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        if edge == nil { Color.clear.frame(height: V4TabBar.contentInset) }
                    }
                    .safeAreaInset(edge: edge ?? .trailing, spacing: 0) {
                        if edge != nil { Color.clear.frame(width: DXDock.thickness + DX.Space.xs) }
                    }
                if edge == nil {
                    // S27.11: Today · Program · SOS · Progress.
                    V4TabBar(selection: v4Selection)
                        .padding(.bottom, DX.Space.xxs)
                } else {
                    dock(axis: .vertical)
                        .padding(dockPadding, DX.Space.xxs)
                }
            }
        }
        .readVerticalBarEdge($barEdge)
        .background(DX.Ground.reading.background.ignoresSafeArea())
        // Program v2 missions ask their quick question after a logged use or an SOS session (handoff 4.4).
        .modifier(MissionPrompts(profile: profile))
    }
}

extension HomeView {
    @ViewBuilder
    private var tabContent: some View {
        switch tab {
        case "program":
            ProgramView(profile: profile)
        case "progress", "me":
            // Progress, with Settings behind its gear (S27.11). "me" is the old tab id.
            ProgressTab(profile: profile)
        default:
            // "evening", "toolkit" and "water" are old tab ids: their content now lives on Today (S27.11, S27.12).
            TodayView(profile: profile)
        }
    }

    /// The v4 tab bar's selection. SOS opens Craving SOS rather than switching tabs: straight into Jelli's breathing
    /// session, never Glim's calm tools list (UX-03). The calm tools are one step further, behind "Still strong".
    private var v4Selection: Binding<V4Tab> {
        Binding(
            get: {
                switch tab {
                case "program": .program
                case "progress", "me": .progress
                default: .today
                }
            },
            set: { new in
                switch new {
                case .sos: sos.open(source: "dock")
                case .today: tab = "today"
                case .program: tab = "program"
                case .progress: tab = "progress"
                }
            }
        )
    }

    private func dock(axis: Axis) -> some View {
        DXDock(
            items: [
                DXDockItem(id: "today", title: "Today", systemImage: "house"),
                DXDockItem(id: "program", title: "Program", systemImage: "book.closed"),
                DXDockItem(id: "progress", title: "Progress", systemImage: "chart.bar"),
            ],
            selection: Binding(get: {
                switch tab {
                case "water", "evening", "toolkit": "today"
                case "me": "progress"
                default: tab
                }
            }, set: { tab = $0 }),
            // The same order as the tab bar (S27.11): Today, Program, Craving SOS, Progress.
            sosPosition: 2,
            axis: axis,
            sosAction: { sos.open(source: "dock") }
        )
    }

    /// The dock stands on the edge where iPhone Duo puts vertical bars; in a window wider than it is tall it
    /// stands on the trailing edge anyway, so it never eats into a short screen's height.
    private func dockEdge(in size: CGSize) -> HorizontalEdge? {
        if let barEdge { return barEdge }
        return size.width > size.height ? .trailing : nil
    }
}

/// Stand-in for tabs and steps that later sections fill in.
struct ComingSoon: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(title).v4Text(.title).padding(.top, DX.Space.xl)
            Spacer()
            V4StateView(.empty, systemImage: systemImage, title: "Coming soon", message: message)
            Spacer()
        }
        .padding(.horizontal, DX.Space.m)
        .dxReadableColumn()
        .background(Read4.background.ignoresSafeArea())
    }
}

/// Prep day 1 opens by itself the first time Home shows after onboarding (S22), so the first thing after setting up
/// is the program working, not a dashboard. Prep 1 to 3 are free; the trial is offered at Prep 4 (MON-01).
enum FirstLesson {
    static let key = "dx.openFirstLesson"
}

/// Today (UX-07, UX-09; 2 Nov 2026): one screen, no scrolling at the usual text sizes. A kicker line, a hero card,
/// one focus card that follows the time of day (UX-08), and a two-cell bento row. Before Day Xero the hero counts
/// down to Quit Day; after it, it counts time free. The Your day list, the streak card, the body-change row and the
/// NRT invitations went: the hero, the focus card and the Program tab carry them now.
struct TodayView: View {
    let profile: UserProfile
    /// The uses just logged, one or a batch (UX-05), for the Undo / Add trigger toast.
    @State private var justLogged: [LogEntry]?
    @State private var detailsFor: LogEntry?
    @State private var loggedFeedback = false
    @Environment(Entitlement.self) private var entitlement
    @Environment(\.modelContext) private var context
    @State private var upgradeTitle: String?
    @State private var showUpgrade = false
    @State private var showPaywall = false
    @Environment(LogRouter.self) private var log
    @Query(sort: \LogEntry.timestamp, order: .reverse) private var logs: [LogEntry]
    @Query(sort: \IfThenPlan.createdAt, order: .reverse) private var plans: [IfThenPlan]
    @Query(sort: \Pledge.madeAt, order: .reverse) private var pledges: [Pledge]
    @Query private var checkIns: [CheckIn]
    /// Program v2 sessions, so the prep count updates as soon as a session is finished.
    @Query private var sessionRecords: [SessionRecord]
    @State private var showPledge = UserDefaults.standard.bool(forKey: "dx.openPledge")
    @State private var showCheckIn = UserDefaults.standard.bool(forKey: "dx.openCheckIn")
    /// Screenshots: `-dx.openCalmList` or `-dx.openCalm <tool>` open the calm tools (they lived on the Evening tab).
    @State private var showCalmTools = UserDefaults.standard.bool(forKey: "dx.openCalmList")
        || UserDefaults.standard.string(forKey: "dx.openCalm") != nil
    @State private var settingsPage: SettingsSheet.Page? = UserDefaults.standard.string(forKey: "dx.openSettings").flatMap(SettingsSheet.Page.init(rawValue:))
    @State private var showSettings = UserDefaults.standard.string(forKey: "dx.openSettings") != nil
    @State private var celebrating: Milestone?
    @State private var showHealth = false
    @Environment(\.dynamicTypeSize) private var typeSize
    /// Xero's coffee note (CLIN-02): the Quit Day it was dismissed for, so a fresh Quit Day brings it back.
    @AppStorage("dx.caffeineAlertDismissedFor") private var caffeineDismissedFor = 0.0
    /// The swap trap (CLIN-05): the day it was last dismissed; it can come back another day.
    @AppStorage("dx.swapTrapDismissedOn") private var swapDismissedOn = 0.0
    /// Today's prep challenge (CLIN-11): the day it was last done.
    @AppStorage("dx.prepChallengeDoneOn") private var challengeDoneOn = 0.0

    var body: some View {
        // Re-evaluates each minute so counters tick and the day rolls over on its own.
        TimelineView(.everyMinute) { timeline in
            let now = timeline.date
            let snap = HomeSnapshot(profile: profile, isPro: entitlement.isPro, now: now, sessions: sessionRecords)
            let state = TodayState(snap: snap, quitTimestamp: profile.progress?.quitTimestamp)
            // Half-open iPhone Duo: the hero on one side of the fold, what to do on the other (S18.14).
            FoldAware {
                column { overview(snap, state: state, now: now) }
            } secondary: {
                column { actions(snap, state: state, now: now) }
            } flat: {
                column {
                    overview(snap, state: state, now: now)
                    actions(snap, state: state, now: now)
                }
            }
        }
        .overlay(alignment: .bottom) {
            if let entries = justLogged { loggedToast(entries) }
        }
        .animation(DX.Move.animation(DX.Move.settle, reduceMotion: false), value: justLogged)
        .task(id: justLogged) {
            guard justLogged != nil else { return }
            try? await Task.sleep(for: .seconds(4))
            justLogged = nil
        }
        .sensoryFeedback(DX.Haptic.commit, trigger: loggedFeedback)
        .sheet(item: $detailsFor) { entry in
            CravingLogForm(profile: profile, editing: entry, onSaved: { detailsFor = nil })
                .presentationDetents([.large])
        }
        .onAppear {
            checkMilestone()
        }
        // Holding Day Xero's commit starts the counter; celebrate as soon as the session closes.
        .onReceive(NotificationCenter.default.publisher(for: .dxSessionClosed)) { _ in
            Task {
                try? await Task.sleep(for: .seconds(0.6))
                checkMilestone()
            }
        }
        .fullScreenCover(item: $celebrating) { milestone in
            MilestoneMoment(milestone: milestone, stats: MilestoneStats(profile: profile, logs: logs)) {
                CelebratedMilestones.markReached(daysClear: HomeSnapshot(profile: profile, isPro: entitlement.isPro).daysClear)
                celebrating = nil
            }
        }
        .sheet(isPresented: $showHealth) {
            HealthTimelineView(profile: profile, onClose: { showHealth = false })
        }
        .fullScreenCover(isPresented: $showPledge) {
            PledgeView(profile: profile) { showPledge = false }
        }
        .fullScreenCover(isPresented: $showCheckIn) {
            CheckInView(profile: profile) { showCheckIn = false }
        }
        .fullScreenCover(isPresented: $showCalmTools) {
            CalmToolsView(onClose: { showCalmTools = false }, fromSOS: false)
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet(profile: profile, start: settingsPage)
        }
        .sheet(isPresented: $showUpgrade) {
            UpgradeSheet(dayTitle: upgradeTitle ?? "", model: PaywallModel(store: entitlement.store, entitlement: entitlement),
                         showAllPlans: { showUpgrade = false; showPaywall = true },
                         onUnlocked: { showUpgrade = false })
                .presentationDetents([.medium, .large])
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(name: profile.name, quitDay: profile.quitDay,
                        model: PaywallModel(store: entitlement.store, entitlement: entitlement),
                        onClose: { showPaywall = false })
        }
    }

    // MARK: Milestones (S13.2)

    /// The first time Home shows on a milestone day, celebrate the latest milestone not yet celebrated.
    private func checkMilestone() {
        #if DEBUG
        if let raw = UserDefaults.standard.string(forKey: "dx.milestone") {
            celebrating = Milestone(id: raw)
            return
        }
        // Screenshot scenarios show Home itself, not the moment.
        if DebugScenario.current != nil { return }
        #endif
        let days = HomeSnapshot(profile: profile, isPro: entitlement.isPro).daysClear
        if let milestone = Milestone.toCelebrate(daysClear: days, celebrated: CelebratedMilestones.ids) {
            celebrating = milestone
        }
    }

    // MARK: Layout

    private func column<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        // Built here: ScrollViewReader's closure escapes, and `content` doesn't.
        let built = content()
        return ScrollViewReader { proxy in
            // Fits without scrolling at the usual text sizes; it scrolls only when it must (large text, iPhone SE).
            ScrollView {
                VStack(alignment: .leading, spacing: DX.Space.m) { built }
                    .padding(.horizontal, DX.Space.m)
                    .dxReadableColumn()
                    .padding(.top, DX.Space.xs)
                    .padding(.bottom, DX.Space.s)
            }
            .scrollBounceBehavior(.basedOnSize)
            #if DEBUG
            // Screenshots of Home's lower half: `-dx.homeScroll lower`.
            .onAppear { if UserDefaults.standard.string(forKey: "dx.homeScroll") == "lower" { proxy.scrollTo("lower", anchor: .top) } }
            #endif
        }
    }

    /// The kicker and the hero.
    @ViewBuilder
    private func overview(_ snap: HomeSnapshot, state: TodayState, now: Date) -> some View {
        let ground = TodayClock.ground(at: now)
        let stage = CrewGrowth.stage(daysClear: snap.daysClear)
        TodayKicker(text: kicker(snap, state: state), name: profile.name) { settingsPage = nil; showSettings = true }
        switch state {
        case .prep:
            TodayPrepHero(snap: snap, quitDay: profile.quitDay, why: why, ground: ground, crewStage: stage)
        case .postQuit:
            TodayQuitHero(timeFree: TimeFree.short(now.timeIntervalSince(quitMoment)),
                          resilience: Resilience.days(quitDay: profile.quitDay, slips: logs.filter { $0.kind == .slip }.map(\.timestamp),
                                                      now: now, clock: clock),
                          product: primaryProduct, moneyKept: snap.moneyKept, currencyCode: snap.currencyCode,
                          why: why, ground: ground, crewStage: stage)
        }
    }

    /// The focus card, the bento row, and the two things that only show some of the time: the morning pledge and
    /// a plan made today.
    @ViewBuilder
    private func actions(_ snap: HomeSnapshot, state: TodayState, now: Date) -> some View {
        focusCard(state: state, now: now).id("lower")
        if showsCaffeineAlert(now: now) {
            XeroNoteCard(kicker: String(localized: "From Xero"), title: String(localized: CaffeineAlert.title),
                         message: String(localized: CaffeineAlert.body), source: HealthSources.caffeineAfterQuitting) {
                caffeineDismissedFor = clock.startOfDate(profile.quitDay).timeIntervalSince1970
            }
        }
        bento(state: state, now: now)
        if state == .prep, let finding = swapTrap(now: now) {
            XeroNoteCard(kicker: String(localized: "From Xero"), title: String(localized: "Watch the swap"),
                         message: swapMessage(finding)) {
                swapDismissedOn = clock.day(containing: now).timeIntervalSince1970
            }
        }
        if case .prep = snap.phase, state == .prep { challengeRow(snap, now: now) }
        if showsPledge(now: now) { pledgeRow }
        // A plan made today, after a slip or in a lesson, stays on Home for the rest of the day (S8.3).
        if let plan = plans.first, clock.day(containing: plan.createdAt) == clock.day(containing: now) {
            PlanCard(situation: plan.situation, action: plan.action, title: "Your plan for next time")
        }
    }

    // MARK: Clinical notes (CLIN-02, CLIN-05, CLIN-11)

    /// Xero's coffee note: people who smoke and named coffee as a trigger, Quit Day through its first week.
    private func showsCaffeineAlert(now: Date) -> Bool {
        let quit = clock.startOfDate(profile.quitDay)
        guard caffeineDismissedFor != quit.timeIntervalSince1970 else { return false }
        return CaffeineAlert.applies(products: profile.products.map(\.product), triggers: profile.triggers,
                                     daysSinceQuit: clock.days(fromDate: profile.quitDay, to: now))
    }

    /// Cigarettes or puffs down while pouches go up, against their own baseline. Hidden for the rest of the day once dismissed.
    private func swapTrap(now: Date) -> SwapTrap.Finding? {
        guard swapDismissedOn != clock.day(containing: now).timeIntervalSince1970 else { return nil }
        let uses: [(product: Product, time: Date)] = logs.filter { $0.kind == .use }.compactMap { entry in
            entry.product.map { (product: $0, time: entry.timestamp) }
        }
        var baselines: [Product: Double] = [:]
        for use in profile.products { baselines[use.product] = use.unitsPerDay }
        return SwapTrap.check(uses: uses, baselines: baselines, since: profile.createdAt, now: now, clock: clock)
    }

    private func swapMessage(_ finding: SwapTrap.Finding) -> String {
        let fell: String = finding.falling == [.vape] ? String(localized: "Your puffs are down")
            : finding.falling == [.cigarettes] ? String(localized: "Your cigarettes are down")
            : String(localized: "Your cigarettes and puffs are down")
        return String(localized: "\(fell), but pouches are up. The nicotine has moved, not dropped, and pouches would need quitting too. Try to bring all of it down together.")
    }

    @ViewBuilder
    private func challengeRow(_ snap: HomeSnapshot, now: Date) -> some View {
        let today = clock.day(containing: now).timeIntervalSince1970
        let done = challengeDoneOn == today
        PrepChallengeRow(challenge: PrepChallenge.forPrepDay(snap.prepDayNumber), done: done) {
            challengeDoneOn = done ? 0 : today
            if !done { Analytics.track(.prepChallengeDone(day: snap.prepDayNumber)) }
        }
    }

    // MARK: Kicker and hero

    /// "Prep day 1 of 7 · Hi, Milan", "Quit Day · Hi, Milan" or "Day 4 · Hi, Milan". Upper-cased by the kicker.
    private func kicker(_ snap: HomeSnapshot, state: TodayState) -> String {
        let hi = profile.name.isEmpty ? String(localized: "Hi") : String(localized: "Hi, \(profile.name)")
        let day: String
        switch (state, snap.phase) {
        case (.prep, .prep):
            let total = max(snap.prepTotal, 1)
            day = String(localized: "Prep day \(min(max(snap.prepDayNumber, 1), total)) of \(total)")
        case (.prep, _):
            day = String(localized: "Quit Day")
        case (.postQuit, _):
            day = String(localized: "Day \(max(snap.daysClear, 1))")
        }
        return "\(day) · \(hi)"
    }

    /// The reason they gave in onboarding (UX-06): their first reason, in their own words.
    private var why: String? {
        let first = profile.reasons.sorted { $0.createdAt < $1.createdAt }.first?.text
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return first?.isEmpty == false ? first : nil
    }

    /// When the time free counts from: Day Xero's commit, or else the start of Quit Day.
    private var quitMoment: Date {
        if let held = profile.progress?.quitTimestamp { return held }
        let start = clock.startOfDate(profile.quitDay)
        return clock.calendar.date(byAdding: .hour, value: clock.boundaryHour, to: start) ?? start
    }

    private var clock: DayClock { DayClock(boundaryHour: profile.dayBoundaryHour) }

    private var primaryProduct: Product {
        profile.primaryProduct?.product ?? profile.products.first?.product ?? .cigarettes
    }

    // MARK: Focus (UX-08)

    /// One card by the time of day: the lesson until 6 PM (after Day Xero, the day's session while it's open, then
    /// recovery once it's done); then Glim's check-in; late at night, once checked in, winding down. The program card
    /// always stays in place, hidden when it isn't the focus, so a session it opened is never closed under the person
    /// when 6 PM comes.
    private func focusCard(state: TodayState, now: Date) -> some View {
        let rhythm = DailyRhythm(clock: clock)
        let checkedIn = debugDaily == "checkedIn" || rhythm.hasCheckedIn(checkIns.map(\.day), at: now)
        // A session that needs Pro isn't pushed on Today; Program offers it.
        let sessionOpen: Bool = if case .open(_, _, false)? = ProgramToday(store: ProgramStore(context: context, profile: profile),
                                                                          isPro: entitlement.isPro, now: now)?.kind { true } else { false }
        var focus = TodayFocus.pick(hour: TodayClock.hour(at: now), postQuit: state == .postQuit, checkedIn: checkedIn,
                                    sessionOpen: sessionOpen)
        // Straight after onboarding, Prep 1 opens from the lesson card whatever the hour (S22).
        if state == .prep, UserDefaults.standard.bool(forKey: FirstLesson.key) { focus = .lesson }
        return VStack(spacing: 0) {
            ProgramTodayCard(profile: profile, showsCard: focus == .lesson)
            switch focus {
            case .lesson:
                EmptyView()
            case .recovery:
                RecoveryCard(product: primaryProduct, quitDay: profile.quitDay, clock: clock, now: now) { showHealth = true }
            case .checkIn:
                ColourCard(kicker: String(localized: "With Glim · 1 min"), title: String(localized: "A minute on how today went"),
                           detail: nil, fill: ColourCard.glim) { showCheckIn = true }
                    .accessibilityHint(Text("Opens the evening check-in"))
            case .windDown:
                ColourCard(kicker: String(localized: "Wind down"), title: String(localized: "Can't sleep? Breathe with Glim"),
                           detail: String(localized: "A slow breath, then rest."), fill: ColourCard.night) { showCalmTools = true }
            }
        }
    }

    /// "Morning pledge · 10 sec", until noon and until it's made. The only row left of Your day (UX-01): the
    /// lesson is the focus card, and the check-in takes the focus card in the evening.
    private func showsPledge(now: Date) -> Bool {
        let rhythm = DailyRhythm(clock: clock)
        let force = debugDaily
        let pledged = force == "pledged" || rhythm.hasPledged(pledges.map(\.day), at: now)
        return !pledged && (force == "pledge" || rhythm.isPledgeTime(now))
    }

    private var pledgeRow: some View {
        Button { showPledge = true } label: {
            HStack(spacing: 10) {
                Image(systemName: "sun.max").font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DX.Ground.reading.ink)
                    .frame(width: 32, height: 32).background(DX.Fill.surface, in: Circle())
                    .accessibilityHidden(true)
                Text("Morning pledge").dxType(.body).foregroundStyle(DX.Ground.reading.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("10 sec").dxType(.footnote).foregroundStyle(DX.Ground.reading.muted)
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold))
                    .foregroundStyle(DX.Ground.reading.muted).accessibilityHidden(true)
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 52)
            .background(DX.Fill.raised, in: RoundedRectangle(cornerRadius: DX.Layout.smallCardRadius, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text("Opens the morning pledge"))
    }

    /// Screenshots can't choose the time of day, so DEBUG builds can force which card shows.
    private var debugDaily: String? {
        #if DEBUG
        UserDefaults.standard.string(forKey: "dx.forceDaily")
        #else
        nil
        #endif
    }

    // MARK: Bento

    /// Water on the left; on the right, today's uses before Day Xero (UX-07) or urges surfed after it (UX-09).
    /// Side by side, or stacked at accessibility text sizes.
    @ViewBuilder
    private func bento(state: TodayState, now: Date) -> some View {
        let water = WaterBentoCell(profile: profile, now: now)
        if typeSize.isAccessibilitySize {
            VStack(spacing: DX.Space.s) {
                water
                rightCell(state: state, now: now)
            }
        } else {
            HStack(spacing: DX.Space.s) {
                water
                rightCell(state: state, now: now)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private func rightCell(state: TodayState, now: Date) -> some View {
        switch state {
        case .prep: useCell(primaryProduct, now: now)
        case .postQuit: urgesCell(now: now)
        }
    }

    /// Today's uses of the main product: the count, the time since the last use, and batch buttons (UX-05). Puffs come
    /// five and ten at a time, so a vape day isn't a hundred taps. The label opens the log for anything else.
    private func useCell(_ product: Product, now: Date) -> some View {
        let count = useCount(product, now: now)
        let title: String = switch product {
        case .cigarettes: String(localized: "Cigarettes today")
        case .vape: String(localized: "Puffs today")
        case .pouches: String(localized: "Pouches today")
        }
        let batches = product == .vape ? [5, 10] : [1, 5]
        let lastUse = logs.first { $0.kind != .craving }?.timestamp
        return BentoCell {
            Button { log.open() } label: {
                VStack(alignment: .leading, spacing: 8) {
                    BentoLabel(title: title, systemImage: LogSheet.icon(product))
                    BentoNumber(value: "\(count)", unit: String(localized: "logged"))
                    if let lastUse, lastUse <= now {
                        Text("\(TimeFree.short(now.timeIntervalSince(lastUse))) nicotine-free")
                            .dxType(.footnote).foregroundStyle(DX.Fill.green)
                            .lineLimit(1).minimumScaleFactor(0.8)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text("Log, \(title): \(count)"))
            .accessibilityHint(Text("Opens the log"))
            Spacer(minLength: 0)
            HStack(spacing: 6) {
                ForEach(Array(batches.enumerated()), id: \.element) { index, batch in
                    Button { logUse(product, count: batch) } label: {
                        BentoPill(title: "+\(batch)", accent: index == 0)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(batchLabel(product, count: batch)))
                    .accessibilityIdentifier(index == 0 ? "home.log.\(product.rawValue)" : "home.log.\(product.rawValue).\(batch)")
                }
            }
        }
    }

    private func batchLabel(_ product: Product, count: Int) -> String {
        switch product {
        case .cigarettes: count == 1 ? String(localized: "Log a cigarette") : String(localized: "Log \(count) cigarettes")
        case .vape: String(localized: "Log \(count) puffs")
        case .pouches: count == 1 ? String(localized: "Log a pouch") : String(localized: "Log \(count) pouches")
        }
    }

    /// Urges surfed after Day Xero (UX-09): cravings ridden out, all time and today. Log opens the sheet, where a
    /// craving or a slip is one more tap.
    private func urgesCell(now: Date) -> some View {
        let ridden = logs.filter { $0.kind == .craving && $0.outcome == .passed }
        let today = clock.day(containing: now)
        let todayCount = ridden.filter { clock.day(containing: $0.timestamp) == today }.count
        return BentoCell {
            BentoLabel(title: String(localized: "Urges surfed"), systemImage: "water.waves")
            BentoNumber(value: "\(ridden.count)", unit: String(localized: "ridden out"))
            Text(todayCount > 0 ? "+\(todayCount) today" as LocalizedStringKey : "None yet today")
                .dxType(.footnote).foregroundStyle(todayCount > 0 ? DX.Fill.green : DX.Ground.reading.muted)
                .lineLimit(1).minimumScaleFactor(0.8)
            Spacer(minLength: 0)
            Button { log.open() } label: { BentoPill(title: String(localized: "Log")) }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Log a craving or slip"))
                .accessibilityIdentifier("home.log.urge")
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: Logging (S24, UX-05)

    private func logUse(_ product: Product, count: Int) {
        let entries = UseLog.log(product, count: count, in: context)
        guard !entries.isEmpty else { return }
        justLogged = entries
        loggedFeedback.toggle()
        if entries.first?.kind == .use { NotificationCenter.default.post(name: .dxUseLogged, object: nil) }
        // A slip (from Quit Day on) goes straight to Jelli's if-then planner (CLIN-10).
        if entries.first?.kind == .slip {
            Analytics.track(.slipLogged(source: "today"))
            log.open(.slipPlan)
        }
    }

    private func loggedToast(_ entries: [LogEntry]) -> some View {
        let product = entries.first?.product
        let count = product.map { useCount($0, now: .now) } ?? 0
        return HStack(spacing: DX.Space.s) {
            Image(systemName: "checkmark").font(.system(size: 13, weight: .bold))
            Text(toastTitle(product, logged: entries.count, total: count)).lineLimit(2)
            Spacer(minLength: DX.Space.xs)
            Button("Undo") {
                UseLog.undo(entries, in: context)
                justLogged = nil
            }
            .opacity(0.75)
            // A trigger belongs to one use; a batch is just counted.
            if entries.count == 1, let entry = entries.first {
                Button("Add trigger") {
                    detailsFor = entry
                    justLogged = nil
                }
            }
        }
        .dxFont(14, weight: 600, style: .footnote)
        .foregroundStyle(Read4.onInk)
        .buttonStyle(.plain)
        .padding(.vertical, DX.Space.s).padding(.horizontal, 14)
        .background(Read4.ink, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.black.opacity(0.15), radius: 16, y: 8)
        .padding(.horizontal, DX.Space.m)
        .padding(.bottom, DX.Space.s)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .accessibilityElement(children: .contain)
    }

    /// "Cigarette #4 logged" for one; "5 puffs logged · 25 today" for a batch.
    private func toastTitle(_ product: Product?, logged: Int, total: Int) -> String {
        if logged > 1 {
            return switch product {
            case .cigarettes: String(localized: "\(logged) cigarettes logged · \(total) today")
            case .vape: String(localized: "\(logged) puffs logged · \(total) today")
            case .pouches: String(localized: "\(logged) pouches logged · \(total) today")
            case nil: String(localized: "Logged")
            }
        }
        return switch product {
        case .cigarettes: String(localized: "Cigarette #\(total) logged")
        case .vape: String(localized: "Puff #\(total) logged")
        case .pouches: String(localized: "Pouch #\(total) logged")
        case nil: String(localized: "Logged")
        }
    }

    private func useCount(_ product: Product, now: Date) -> Int {
        let today = clock.day(containing: now)
        return logs.filter { $0.product == product && $0.kind != .craving && clock.day(containing: $0.timestamp) == today }.count
    }

    /// "in 3h", "in 4 days", "in 6 weeks", "in 9 months", "in 2 years".
    static func relative(hours: Double) -> String {
        let h = max(hours, 0)
        if h < 48 { return String(localized: "in \(max(Int(h.rounded(.up)), 1))h") }
        let days = Int((h / 24).rounded())
        if days < 14 { return String(localized: "in \(days) days") }
        if days < 60 { return String(localized: "in \(Int((Double(days) / 7).rounded())) weeks") }
        if days < 730 { return String(localized: "in \(Int((Double(days) / 30.4).rounded())) months") }
        return String(localized: "in \(Int((Double(days) / 365).rounded())) years")
    }
}
