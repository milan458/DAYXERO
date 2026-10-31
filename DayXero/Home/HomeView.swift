import DayXeroCore
import SwiftData
import SwiftUI

/// The app after onboarding: v4 Nav2 (Today, Program, SOS, Evening, Me). On iPhone Duo with vertical bars,
/// the older dock stands on the side edge.
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
                    // Every tab scrolls clear of the dock, on whichever edge it stands (S18.13).
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        if edge == nil { Color.clear.frame(height: 70 + DX.Space.xs) }
                    }
                    .safeAreaInset(edge: edge ?? .trailing, spacing: 0) {
                        if edge != nil { Color.clear.frame(width: DXDock.thickness + DX.Space.xs) }
                    }
                if edge == nil {
                    // v4 Nav2 (decision 21): Today · Program · SOS · Evening · Me.
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
            // Me holds Progress and Settings (decision 21).
            ProgressTab(profile: profile)
        case "toolkit", "water", "evening":
            // Evening holds the calm tools (decision 21). "water" is an old tab id: open with the tracker showing.
            ToolkitView(profile: profile, openWater: tab == "water")
        default:
            TodayView(profile: profile)
        }
    }

    /// The v4 tab bar's selection. SOS opens Craving SOS rather than switching tabs.
    private var v4Selection: Binding<V4Tab> {
        Binding(
            get: {
                switch tab {
                case "program": .program
                case "progress", "me": .me
                case "toolkit", "water", "evening": .evening
                default: .today
                }
            },
            set: { new in
                switch new {
                case .sos: sos.open(source: "dock")
                case .today: tab = "today"
                case .program: tab = "program"
                case .evening: tab = "evening"
                case .me: tab = "me"
                }
            }
        )
    }

    private func dock(axis: Axis) -> some View {
        DXDock(
            items: [
                DXDockItem(id: "today", title: "Today", systemImage: "house"),
                DXDockItem(id: "toolkit", title: "Toolkit", systemImage: "shield"),
                DXDockItem(id: "program", title: "Program", systemImage: "book.closed"),
                DXDockItem(id: "progress", title: "Progress", systemImage: "chart.line.uptrend.xyaxis.circle"),
            ],
            selection: Binding(get: {
                switch tab {
                case "water", "evening": "toolkit"
                case "me": "progress"
                default: tab
                }
            }, set: { tab = $0 }),
            // Today, Toolkit, Craving SOS in the middle, Program, Progress.
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
            Text(title).dxText(.title).padding(.top, DX.Space.xl)
            Spacer()
            DXStateView(.empty, systemImage: systemImage, title: "Coming soon", message: message)
            Spacer()
        }
        .padding(.horizontal, DX.Space.m)
        .dxReadableColumn()
        .dxCanvas()
    }
}

/// Prep day 1 opens by itself the first time Home shows after the paywall (S22), so the first thing after starting
/// a trial is the program working, not a dashboard.
enum FirstLesson {
    static let key = "dx.openFirstLesson"
}

struct TodayView: View {
    let profile: UserProfile
    @State private var showWater = false
    /// The use just logged with one tap, for the Undo / Add trigger toast.
    @State private var justLogged: LogEntry?
    @State private var detailsFor: LogEntry?
    @State private var loggedFeedback = false
    @Environment(Entitlement.self) private var entitlement
    @Environment(\.modelContext) private var context
    @AppStorage("dx.sosHintSeen") private var sosHintSeen = false
    @State private var openLesson: ProgramView.LessonOpen?
    @State private var upgradeTitle: String?
    @State private var showUpgrade = false
    @State private var showPaywall = false
    @Environment(LogRouter.self) private var log
    @Environment(NRTRouter.self) private var nrt
    @Query(sort: \LogEntry.timestamp, order: .reverse) private var logs: [LogEntry]
    @Query(sort: \IfThenPlan.createdAt, order: .reverse) private var plans: [IfThenPlan]
    @Query(sort: \Pledge.madeAt, order: .reverse) private var pledges: [Pledge]
    @Query private var checkIns: [CheckIn]
    @State private var showPledge = UserDefaults.standard.bool(forKey: "dx.openPledge")
    @State private var showCheckIn = UserDefaults.standard.bool(forKey: "dx.openCheckIn")
    @State private var showCalmTools = false
    @Environment(SOSRouter.self) private var sos
    @State private var settingsPage: SettingsSheet.Page? = UserDefaults.standard.string(forKey: "dx.openSettings").flatMap(SettingsSheet.Page.init(rawValue:))
    @State private var showSettings = UserDefaults.standard.string(forKey: "dx.openSettings") != nil
    @State private var celebrating: Milestone?
    @State private var showHealth = false
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        // Re-evaluates each minute so counters tick and the day rolls over on its own.
        TimelineView(.everyMinute) { timeline in
            let snap = HomeSnapshot(profile: profile, isPro: entitlement.isPro, now: timeline.date)
            // Half-open iPhone Duo: today at a glance on one side of the fold, what to do on the other (S18.14).
            FoldAware {
                column { overview(snap, now: timeline.date) }
            } secondary: {
                column { actions(snap, now: timeline.date) }
            } flat: {
                column {
                    overview(snap, now: timeline.date)
                    actions(snap, now: timeline.date)
                }
            }
        }
        .overlay(alignment: .bottom) {
            if let entry = justLogged { loggedToast(entry) }
        }
        .animation(DX.Motion.animation(DX.Motion.glide, reduceMotion: false), value: justLogged)
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
        .fullScreenCover(isPresented: $showWater) {
            WaterTrackerView(profile: profile, onClose: { showWater = false })
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
        .fullScreenCover(item: $openLesson) { item in
            LessonPlayer(day: item.day, profile: profile, isReplay: item.isReplay)
        }
        .sheet(isPresented: $showUpgrade) {
            UpgradeSheet(dayTitle: upgradeTitle ?? "", model: PaywallModel(store: entitlement.store, entitlement: entitlement),
                         showAllPlans: { showUpgrade = false; showPaywall = true },
                         onUnlocked: { showUpgrade = false })
                .presentationDetents([.medium])
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(name: profile.name, quitDay: profile.quitDay,
                        model: PaywallModel(store: entitlement.store, entitlement: entitlement),
                        onClose: { showPaywall = false })
        }
    }

    private func openQueuedFirstLesson() {
        guard UserDefaults.standard.bool(forKey: FirstLesson.key) else { return }
        UserDefaults.standard.set(false, forKey: FirstLesson.key)
        let snap = HomeSnapshot(profile: profile, isPro: entitlement.isPro)
        guard celebrating == nil, let lesson = snap.lesson, lesson.availability == .available, !lesson.needsUpgrade else { return }
        openLesson = .init(day: lesson.day, isReplay: false)
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
            ScrollView {
                // 16 pt between sections, as on dayxero.in (S19).
                VStack(alignment: .leading, spacing: DX.Space.m) { built }
                    .padding(.horizontal, DX.Space.m)
                    .dxReadableColumn()
                    .padding(.top, DX.Space.s)
                    .padding(.bottom, DX.Space.l)
            }
            #if DEBUG
            // Screenshots of Home's lower half: `-dx.homeScroll lower`.
            .onAppear { if UserDefaults.standard.string(forKey: "dx.homeScroll") == "lower" { proxy.scrollTo("lower", anchor: .top) } }
            #endif
        }
    }

    /// The top of Home (S24, the Figma mockup): the header, today's lesson, logging, and the streak.
    @ViewBuilder
    private func overview(_ snap: HomeSnapshot, now: Date) -> some View {
        TodayHeaderV4(snap: snap, name: profile.name, now: now) { settingsPage = nil; showSettings = true }
        // F08 top card by time of day: the usual wave, Glim's check-in or winding down. The lesson card follows.
        let top = topCard(now: now)
        TodayTopCardV4(card: top, plan: wavePlan(top), onSOS: { sos.open(source: "wave card") },
                       onCheckIn: { showCheckIn = true }, onWindDown: { showCalmTools = true })
        // Program v2's session, mission or what's next (handoff 4.5), as the green lesson card.
        ProgramTodayCard(profile: profile).id("lower")
        YourDayList(rows: yourDay(now: now))
        if snap.phase == .quitDay, !sosHintSeen { sosHint }
        // A plan made today, after a slip or in a lesson, stays on Home for the rest of the day (S8.3).
        if let plan = plans.first, DayClock(boundaryHour: profile.dayBoundaryHour).day(containing: plan.createdAt)
            == DayClock(boundaryHour: profile.dayBoundaryHour).day(containing: now) {
            PlanCard(situation: plan.situation, action: plan.action, title: "Your plan for next time")
        }
        quickLog(snap, now: now)
        streakCard(snap)
    }

    /// Then: NRT set-up, the next change in the body, and today's pledge or check-in.
    @ViewBuilder
    private func actions(_ snap: HomeSnapshot, now: Date) -> some View {
        nrtSection(snap, now: now)
        milestoneRow(now: now)
    }

    // MARK: Pledge and check-in (S11)

    /// F08's top card. The wave comes from their own log of cravings and slips (sessions closed straight away don't count).
    private func topCard(now: Date) -> TodayTopCard {
        let rhythm = DailyRhythm(clock: DayClock(boundaryHour: profile.dayBoundaryHour))
        let cravings = logs.filter { ($0.kind == .craving && $0.outcome != .closed) || $0.kind == .slip }.map { (time: $0.timestamp, trigger: $0.trigger) }
        let wave = CravingPattern.usualWave(cravings, now: now)
        return TodayTopCard.pick(slot: TodayHeaderV4.slot(at: now), wave: wave,
                                 checkedIn: rhythm.hasCheckedIn(checkIns.map(\.day), at: now))
    }

    /// A plan they've saved for the wave's trigger, shown on the wave card.
    private func wavePlan(_ card: TodayTopCard) -> IfThenPlan? {
        guard case let .wave(wave) = card, let trigger = wave.trigger else { return nil }
        let situation = String(localized: trigger.situation)
        return plans.first { $0.situation == situation }
    }

    /// "Your day" (F08): the pledge, today's session and the evening check-in (S11). Both daily moments stay optional.
    private func yourDay(now: Date) -> [YourDayList.Row] {
        let rhythm = DailyRhythm(clock: DayClock(boundaryHour: profile.dayBoundaryHour))
        let force = debugDaily
        let pledged = force == "pledged" || rhythm.hasPledged(pledges.map(\.day), at: now)
        let checkedIn = rhythm.hasCheckedIn(checkIns.map(\.day), at: now)
        var rows: [YourDayList.Row] = []
        if pledged {
            rows.append(.init(id: "pledge", label: String(localized: "Morning pledge"), meta: String(localized: "done"), done: true, action: nil))
        } else if force == "pledge" || rhythm.isPledgeTime(now) {
            rows.append(YourDayList.Row(id: "pledge", label: String(localized: "Morning pledge"), meta: String(localized: "10 sec"),
                                        done: false, action: { showPledge = true }))
        }
        if let today = ProgramToday(store: ProgramStore(context: context, profile: profile), isPro: entitlement.isPro) {
            switch today.kind {
            case .open:
                rows.append(.init(id: "lesson", label: today.title, meta: String(localized: "\(today.minutes) min"), done: false, action: nil))
            case .waiting, .complete:
                rows.append(.init(id: "lesson", label: String(localized: "Today's session"), meta: String(localized: "done"), done: true, action: nil))
            }
        }
        let canCheckIn = force == "checkin" || rhythm.isCheckInTime(now)
        var openCheckIn: (() -> Void)?
        if !checkedIn && canCheckIn { openCheckIn = { showCheckIn = true } }
        rows.append(YourDayList.Row(id: "checkin", label: String(localized: "Evening check-in"),
                                    meta: checkedIn ? String(localized: "done") : checkInTime, done: checkedIn,
                                    action: openCheckIn))
        return rows
    }

    /// The check-in reminder's time, or "Tonight" when the reminder is off.
    private var checkInTime: String {
        guard let minute = DailyReminderSettings.checkInMinute,
              let time = Calendar.current.date(bySettingHour: minute / 60, minute: minute % 60, second: 0, of: .now) else {
            return String(localized: "Tonight")
        }
        return time.formatted(date: .omitted, time: .shortened)
    }

    /// Screenshots can't choose the time of day, so DEBUG builds can force which card shows.
    private var debugDaily: String? {
        #if DEBUG
        UserDefaults.standard.string(forKey: "dx.forceDaily")
        #else
        nil
        #endif
    }

    // MARK: NRT and pouch taper (S9.5)

    /// Only the invitations: once a plan is set up its card lives in Program (S19.6).
    @ViewBuilder
    private func nrtSection(_ snap: HomeSnapshot, now: Date) -> some View {
        if profile.nrtPlans.isEmpty, profile.nrtInterest == .using || profile.nrtInterest == .wantIt {
            NRTInviteRow(title: "Set up your NRT", detail: "Reminders for patches and step-downs", systemImage: "bandage") {
                nrt.sheet = .setup
            }
        }
        if isPrep(snap), profile.pouchTaper == nil, profile.products.contains(where: { $0.product == .pouches }) {
            NRTInviteRow(title: "Step down your pouches", detail: "Optional, before Quit Day", systemImage: "chart.line.downtrend.xyaxis") {
                nrt.sheet = .taper
            }
        }
    }

    // MARK: Logging (S24)

    private enum LogCell: Identifiable, Hashable {
        case product(Product)
        case water
        var id: Self { self }
    }

    /// A card per product, two to a row. With one product or three, water fills the gap so the grid stays even.
    @ViewBuilder
    private func quickLog(_ snap: HomeSnapshot, now: Date) -> some View {
        let products = profile.products.sorted { ($0.isPrimary ? 0 : 1) < ($1.isPrimary ? 0 : 1) }.map(\.product)
        let cells = products.map(LogCell.product) + (products.count % 2 == 1 ? [LogCell.water] : [])
        if typeSize.isAccessibilitySize {
            VStack(spacing: DX.Space.s) {
                ForEach(cells) { logCell($0, snap: snap, now: now) }
            }
        } else {
            Grid(horizontalSpacing: DX.Space.s, verticalSpacing: DX.Space.s) {
                ForEach(Array(stride(from: 0, to: cells.count, by: 2)), id: \.self) { start in
                    GridRow {
                        ForEach(cells[start..<min(start + 2, cells.count)]) { logCell($0, snap: snap, now: now) }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func logCell(_ cell: LogCell, snap: HomeSnapshot, now: Date) -> some View {
        switch cell {
        case let .product(product): productCard(product, snap: snap, now: now)
        case .water: WaterHomeCard(profile: profile, now: now, onOpen: { showWater = true })
        }
    }

    /// In prep: today's uses, logged in one tap (with Undo), and for vapes an Urge button straight to the craving form.
    /// From Quit Day: what's not been used since; Log opens the sheet, where a craving or a slip is one more tap.
    private func productCard(_ product: Product, snap: HomeSnapshot, now: Date) -> some View {
        let prep = isPrep(snap)
        let count = prep ? useCount(product, now: now) : (snap.counters.first { $0.product == product }?.avoided ?? 0)
        let title: LocalizedStringKey = switch (product, prep) {
        case (.cigarettes, true): "Cigarettes today"
        case (.vape, true): "Puffs and urges"
        case (.pouches, true): "Pouches today"
        case (.cigarettes, false): "Not smoked"
        case (.vape, false): "Puffs not taken"
        case (.pouches, false): "Pouches skipped"
        }
        let button: LocalizedStringKey = switch (product, prep) {
        case (.cigarettes, true): "+ Log cigarette"
        case (.vape, true): "+1 Puff"
        case (.pouches, true): "+ Log pouch"
        case (_, false): "+ Log craving or slip"
        }
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: DX.Space.xs) {
                Image(systemName: LogSheet.icon(product)).font(.system(size: 13, weight: .semibold)).foregroundStyle(DX.Ground.reading.ink)
                    .frame(width: 30, height: 30).background(DX.Fill.surface, in: Circle())
                    .accessibilityHidden(true)
                Text(title).dxFont(14, weight: 600, style: .footnote).foregroundStyle(DX.Ground.reading.muted)
                    .lineLimit(2).minimumScaleFactor(0.85)
            }
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(count, format: .number).dxType(.title).foregroundStyle(DX.Ground.reading.ink)
                    .contentTransition(.numericText())
                Text(prep ? "logged" as LocalizedStringKey : "since Quit Day").dxType(.caption)
                    .foregroundStyle(DX.Ground.reading.muted)
            }
            Spacer(minLength: 0)
            HStack(spacing: 6) {
                Button { if prep { logUse(product) } else { log.open() } } label: { pill(button) }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("home.log.\(product.rawValue)")
                    .accessibilityHint(prep ? Text("Logs one now") : Text("Opens the log"))
                // A puff and an urge are opposite things: the urge goes straight to the craving form.
                if prep, product == .vape {
                    Button { log.open(.craving) } label: { pill("+ Urge", accent: true) }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("home.log.urge")
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(DX.Fill.raised, in: RoundedRectangle(cornerRadius: DX.Layout.smallCardRadius, style: .continuous))
    }

    private func pill(_ title: LocalizedStringKey, accent: Bool = false) -> some View {
        Text(title).dxFont(14, weight: 700, style: .footnote)
            .foregroundStyle(accent ? DX.Ground.reading.background : DX.Ground.reading.ink)
            .lineLimit(1).minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(accent ? DX.Ground.reading.ink : DX.Fill.surface, in: Capsule())
    }

    private func logUse(_ product: Product) {
        justLogged = UseLog.log(product, in: context)
        loggedFeedback.toggle()
        if justLogged?.kind == .use { NotificationCenter.default.post(name: .dxUseLogged, object: nil) }
    }

    private func loggedToast(_ entry: LogEntry) -> some View {
        let count = entry.product.map { useCount($0, now: .now) } ?? 0
        return HStack(spacing: DX.Space.s) {
            Image(systemName: "checkmark").font(.system(size: 13, weight: .bold))
            Text(toastTitle(entry.product, count: count)).lineLimit(2)
            Spacer(minLength: DX.Space.xs)
            Button("Undo") {
                UseLog.undo(entry, in: context)
                justLogged = nil
            }
            .opacity(0.75)
            Button("Add trigger") {
                detailsFor = entry
                justLogged = nil
            }
        }
        .font(.custom(DX.Typeface.semibold, size: 13, relativeTo: .footnote))
        .foregroundStyle(DX.Palette.onPrimary)
        .buttonStyle(.plain)
        .padding(.vertical, DX.Space.s).padding(.horizontal, 14)
        .background(DX.Palette.primary, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: DX.Palette.shadow, radius: 16, y: 8)
        .padding(.horizontal, DX.Space.m)
        .padding(.bottom, DX.Space.s)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .accessibilityElement(children: .contain)
    }

    private func toastTitle(_ product: Product?, count: Int) -> String {
        switch product {
        case .cigarettes: String(localized: "Cigarette #\(count) logged")
        case .vape: String(localized: "Puff #\(count) logged")
        case .pouches: String(localized: "Pouch #\(count) logged")
        case nil: String(localized: "Logged")
        }
    }

    private func useCount(_ product: Product, now: Date) -> Int {
        let clock = DayClock(boundaryHour: profile.dayBoundaryHour)
        let today = clock.day(containing: now)
        return logs.filter { $0.product == product && $0.kind != .craving && clock.day(containing: $0.timestamp) == today }.count
    }

    private func isPrep(_ snap: HomeSnapshot) -> Bool {
        if case .prep = snap.phase { return true }
        return false
    }

    // MARK: Sections

    // MARK: Today's lesson (S19.3)

    /// "PREP PROGRAM · DAY 4", "QUIT WEEK · DAY 2", "WEEKLY · WEEK 3".
    private func lessonEyebrow(_ day: ProgramDayID) -> String {
        switch day.phase {
        case .prep: String(localized: "Prep program · Day \(day.index)")
        case .quit: String(localized: "Quit week · Day \(day.index)")
        case .maintenance: String(localized: "Weekly · Week \(day.index)")
        }
    }

    /// "1 of 9 · 6 min"; weekly sessions just say how long.
    private func lessonDetail(_ lesson: HomeSnapshot.Lesson, prepTotal: Int) -> String {
        let content = LessonLibrary.lesson(for: lesson.day, product: profile.primaryProduct?.product ?? .cigarettes)
        if let summary = content.summary, !summary.isEmpty { return summary }
        let place: String? = switch lesson.day.phase {
        case .prep: String(localized: "\(lesson.day.index) of \(prepTotal)")
        case .quit: String(localized: "\(lesson.day.index) of \(ProgramSchedule.quitWeekDays)")
        case .maintenance: nil
        }
        return [place, String(localized: "\(content.minutes) min")].compactMap { $0 }.joined(separator: " · ")
    }

    /// The lesson spotlight (S24): a white card on dark, and the other way round on light, with soft hills along
    /// its foot. Its eyebrow is the one micro label inside a card (DESIGN_METHODOLOGY.md, S19.3).
    private func lessonCard(_ lesson: HomeSnapshot.Lesson, finished: ProgramDayID?, prepTotal: Int, prep: Bool) -> some View {
        let ink = DX.Palette.onPrimary
        // Sage on the dark card, deep olive on the white one.
        let accent = Color(light: 0xBCC388, dark: 0x55621F)
        let content = LessonLibrary.lesson(for: lesson.day, product: profile.primaryProduct?.product ?? .cigarettes)
        let minutes = content.minutes
        let hasAudio = content.steps.contains { if case .audio = $0 { true } else { false } }
        let shape = RoundedRectangle(cornerRadius: DX.Radius.hero, style: .continuous)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: DX.Space.xs) {
                Text(verbatim: lessonEyebrow(lesson.day)).dxText(.micro, color: accent)
                Spacer(minLength: DX.Space.xs)
                if lesson.placeholder { PlaceholderTag() }
                if let badge = lessonBadge(lesson) {
                    Text(badge).font(.custom(DX.Typeface.bold, size: 10, relativeTo: .caption2))
                        .textCase(.uppercase)
                        .foregroundStyle(DX.Palette.onAccent)
                        .padding(.vertical, 4).padding(.horizontal, 10)
                        .background(DX.Palette.sage, in: Capsule())
                }
            }
            Label {
                Text(hasAudio ? "Audio + exercise · \(minutes) min" as LocalizedStringKey : "\(minutes) min")
            } icon: {
                Image(systemName: hasAudio ? "headphones" : "clock").foregroundStyle(accent)
            }
            .font(.custom(DX.Typeface.medium, size: 12, relativeTo: .caption))
            .foregroundStyle(ink.opacity(0.6))
            if let finished {
                Label {
                    Text("\(LessonCatalog.title(for: finished)) done").dxText(.subtitle, color: ink.opacity(0.7))
                } icon: {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(accent)
                }
            }
            Text(lesson.title).font(.custom(DX.Typeface.bold, size: 22, relativeTo: .title2)).tracking(-0.4).foregroundStyle(ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(verbatim: lessonLine(lesson, content: content, prepTotal: prepTotal, prep: prep))
                .font(.custom(DX.Typeface.regular, size: 14, relativeTo: .subheadline)).foregroundStyle(ink.opacity(0.65))
                .fixedSize(horizontal: false, vertical: true)
            switch lesson.availability {
            case let .opensOn(date):
                Label {
                    Text(opensText(date)).dxText(.subtitle, color: ink.opacity(0.7))
                } icon: {
                    Image(systemName: "clock").foregroundStyle(ink.opacity(0.5))
                }
            case .available where lesson.needsUpgrade:
                lessonButton(String(localized: "Unlock \(lesson.title)"), systemImage: "lock.open") {
                    upgradeTitle = lesson.title
                    // Superwall's paywall when a campaign has one here; the upgrade sheet otherwise (S20).
                    Paywalls.present(.unlockProgramDay, params: ["day": lesson.day.description]) { outcome in
                        switch outcome {
                        case .fallback: showUpgrade = true
                        case .unlocked: entitlement.grant()
                        case .closed: break
                        }
                    }
                }
            case .available:
                let title = lesson.resumeStep > 0 ? String(localized: "Continue · \(minutes) min")
                    : finished == nil ? String(localized: "Start \(LessonCatalog.title(for: lesson.day).lowercased()) lesson · \(minutes) min")
                    : String(localized: "Start the next one · \(minutes) min")
                lessonButton(title, systemImage: "play.fill") { openLesson = .init(day: lesson.day, isReplay: false) }
            case .completed, .locked:
                EmptyView()
            }
        }
        .padding(DX.Space.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack(alignment: .bottom) {
                shape.fill(DX.Palette.primary)
                // The welcome screen's hills, in the card's own palette: light hills on the white card.
                Hills(still: true).frame(height: 64).opacity(0.55)
                    .environment(\.colorScheme, colorScheme == .dark ? .light : .dark)
            }
            .clipShape(shape)
        }
        .shadow(color: DX.Palette.sage.opacity(0.15), radius: 20)
        .shadow(color: DX.Palette.shadow, radius: 24, y: 12)
    }

    /// Prep: what to do with today's lesson. Otherwise its summary, or where it sits in the program.
    private func lessonLine(_ lesson: HomeSnapshot.Lesson, content: LessonContent, prepTotal: Int, prep: Bool) -> String {
        if let summary = content.summary, !summary.isEmpty { return summary }
        guard prep else { return lessonDetail(lesson, prepTotal: prepTotal) }
        let things = profile.products.sorted { ($0.isPrimary ? 0 : 1) < ($1.isPrimary ? 0 : 1) }.prefix(2).map { use in
            switch use.product {
            case .cigarettes: String(localized: "cigarette")
            case .vape: String(localized: "vape")
            case .pouches: String(localized: "pouch")
            }
        }
        let next = things.count > 1 ? String(localized: "\(things[0]) or \(things[1])") : (things.first ?? String(localized: "cigarette"))
        return String(localized: "Keep using normally today. Do this \(content.minutes)-minute session before your next \(next).")
    }

    private func lessonBadge(_ lesson: HomeSnapshot.Lesson) -> LocalizedStringKey? {
        switch lesson.availability {
        case .available: return lesson.needsUpgrade ? LocalizedStringKey("Pro") : LocalizedStringKey("Unlocked")
        case .opensOn: return "Up next"
        case .completed: return "Done"
        case .locked: return nil
        }
    }

    /// The card's button: dark on the white card (light on the dark one), full width.
    private func lessonButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
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

    private func opensText(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInTomorrow(date) { return String(localized: "Opens tomorrow morning") }
        return String(localized: "Opens \(date.formatted(.dateTime.weekday(.wide)))")
    }

    private var sosHint: some View {
        Button { sosHintSeen = true } label: {
            HStack(spacing: DX.Space.xs) {
                Image(systemName: "sos.circle").foregroundStyle(DX.Palette.accentInk)
                Text("Craving? Tap SOS any time. It takes 3 minutes.")
                    .font(DX.TextStyle.subtitle.font).foregroundStyle(DX.Palette.text2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "xmark").font(.system(size: 11, weight: .semibold)).foregroundStyle(DX.Palette.muted)
            }
            .padding(DX.Space.s)
            .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(DX.Palette.faint, style: StrokeStyle(lineWidth: 1, dash: [4, 4])))
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text("Dismisses this tip"))
    }

    // MARK: Streak (S19.4, S24)

    /// Prep: lessons done in a row, the Quit Day countdown, and a segment per prep day. From Quit Day: days clear
    /// and the way to the next milestone (S24).
    private func streakCard(_ snap: HomeSnapshot) -> some View {
        let ink = DX.Ground.reading.ink
        let muted = DX.Ground.reading.muted
        let track = DX.Ground.reading.ink.opacity(0.12)
        let value: Double
        if case .prep = snap.phase {
            value = Double(snap.prepDone) / Double(max(snap.prepTotal, 1))
        } else {
            value = snap.nextMilestone == nil ? 1 : snap.milestoneFraction
        }
        return VStack(alignment: .leading, spacing: DX.Space.s) {
            HStack(alignment: .firstTextBaseline, spacing: DX.Space.xs) {
                switch snap.phase {
                case let .prep(days):
                    Text("Prep streak · \(snap.lessonStreak) / \(snap.prepTotal)").dxType(.caption).textCase(.uppercase).foregroundStyle(ink)
                    Spacer(minLength: DX.Space.xs)
                    Text(verbatim: "\(String(localized: "Quit Day")) \(profile.quitDay.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))) · \(days == 1 ? String(localized: "1 day") : String(localized: "\(days) days"))")
                        .dxType(.caption).foregroundStyle(muted)
                default:
                    Text("Smoke-free · \(snap.daysClear) \(snap.daysClear == 1 ? String(localized: "day") : String(localized: "days"))")
                        .dxType(.caption).textCase(.uppercase).foregroundStyle(ink)
                    Spacer(minLength: DX.Space.xs)
                    if let next = snap.nextMilestone {
                        Text("Next milestone · \(next) days").dxType(.caption).foregroundStyle(muted)
                    }
                }
            }
            if case .prep = snap.phase, snap.prepTotal <= 14 {
                // One segment per prep day: done ones full, today's half, the rest waiting.
                HStack(spacing: 6) {
                    ForEach(0..<max(snap.prepTotal, 1), id: \.self) { index in
                        Capsule()
                            .fill(index < snap.prepDone ? DX.Fill.green : track)
                            .overlay(alignment: .leading) {
                                if index == snap.prepDone, index == snap.prepDayNumber - 1 {
                                    GeometryReader { geo in Capsule().fill(DX.Fill.green.opacity(0.6)).frame(width: geo.size.width / 2) }
                                }
                            }
                            .frame(height: 8)
                    }
                }
            } else {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(track)
                        Capsule().fill(DX.Fill.green).frame(width: geo.size.width * min(1, max(0, value)))
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(.vertical, 14).padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DX.Fill.raised, in: RoundedRectangle(cornerRadius: DX.Layout.smallCardRadius, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    // MARK: Next change in the body (S19.5)

    /// What's changing in the body now and what's next, with its illustration (S21.6). Opens the health timeline.
    private func milestoneRow(now: Date) -> some View {
        let product = profile.primaryProduct?.product ?? .cigarettes
        let items = HealthTimeline.bundled?.items(for: product) ?? []
        let elapsed = HealthTimeline.elapsedHours(quitDay: profile.quitDay, now: now, clock: DayClock(boundaryHour: profile.dayBoundaryHour))
        let (current, next) = HealthTimeline.nowAndNext(items, elapsedHours: elapsed)
        let featured = current ?? next
        let line: String = if elapsed < 0, let first = next {
            String(localized: "Starts on Quit Day · \(first.when)")
        } else if let next {
            String(localized: "Next milestone: \(next.title) (\(Self.relative(hours: next.fromHours - elapsed)))")
        } else {
            String(localized: "Every change on the timeline is under way")
        }
        return Button { showHealth = true } label: {
            HStack(spacing: DX.Space.s) {
                // The change under way gets its progress ring; before Quit Day the first change shows in colour, as a preview.
                HealthBadge(id: featured?.id ?? "",
                            state: current.map { HealthTimeline.state(of: $0, elapsedHours: elapsed) } ?? .underWay(0),
                            size: 44, showsRing: current != nil)
                    .padding(current != nil ? 4 : 0)
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: featured?.title ?? String(localized: "Your body is recovering"))
                        .dxFont(16, weight: 700, style: .body).foregroundStyle(DX.Ground.reading.ink)
                        .multilineTextAlignment(.leading)
                    Text(verbatim: line).dxType(.footnote).foregroundStyle(DX.Ground.reading.muted).multilineTextAlignment(.leading)
                }
                .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: DX.Space.xs)
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .bold)).foregroundStyle(DX.Ground.reading.ink)
                    .frame(width: 32, height: 32).background(DX.Fill.surface, in: Circle())
                    .accessibilityHidden(true)
            }
            .padding(14)
            .background(DX.Fill.raised, in: RoundedRectangle(cornerRadius: DX.Layout.smallCardRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint(Text("Opens what changes in your body"))
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

/// The pledge or check-in card on Home (S11).
struct DailyCard: View {
    let systemImage: String
    let title: LocalizedStringKey
    let detail: LocalizedStringKey?
    let action: LocalizedStringKey?
    var done = false
    let onTap: () -> Void

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        Button(action: onTap) {
            // At accessibility sizes the action moves under the text so neither is squeezed.
            let layout = typeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: DX.Space.s)) : AnyLayout(HStackLayout(spacing: DX.Space.s))
            layout {
                HStack(spacing: DX.Space.s) {
                    Image(systemName: systemImage).font(.system(size: 17, weight: done ? .bold : .regular))
                        .foregroundStyle(done ? DX.Palette.onAccent : DX.Palette.accentInk)
                        .frame(width: 40, height: 40)
                        .background(done ? DX.Palette.sage : DX.Palette.accentSoft, in: Circle())
                    VStack(alignment: .leading, spacing: 1) {
                        Text(title).font(.custom(DX.Typeface.semibold, size: 15, relativeTo: .body)).foregroundStyle(DX.Palette.text)
                        if let detail { Text(detail).dxText(.subtitle) }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
                if !typeSize.isAccessibilitySize { Spacer(minLength: DX.Space.xs) }
                if let action {
                    Text(action).font(.custom(DX.Typeface.semibold, size: 13, relativeTo: .footnote))
                        .foregroundStyle(DX.Palette.onPrimary)
                        .padding(.vertical, 8).padding(.horizontal, 14)
                        .background(DX.Palette.primary, in: Capsule())
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(done ? DX.Palette.sage.opacity(0.45) : DX.Palette.hairline))
        }
        .buttonStyle(.plain)
        .disabled(done)
        .accessibilityElement(children: .combine)
    }
}
