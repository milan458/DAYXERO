import DayXeroCore
import SwiftData
import SwiftUI

/// The app after onboarding: Today, Water, Program and Progress in the floating dock, with Craving SOS in the middle.
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
                        if edge == nil { Color.clear.frame(height: DXDock.thickness + DX.Space.xs) }
                    }
                    .safeAreaInset(edge: edge ?? .trailing, spacing: 0) {
                        if edge != nil { Color.clear.frame(width: DXDock.thickness + DX.Space.xs) }
                    }
                dock(axis: edge == nil ? .horizontal : .vertical)
                    .padding(dockPadding, DX.Space.xxs)
            }
        }
        .readVerticalBarEdge($barEdge)
        .dxCanvas()
        // A break of 3+ days pauses the program until the last day is replayed (S5.7).
        .onChange(of: scenePhase, initial: true) { _, phase in
            if phase == .active { ProgramUpkeep.checkForBreak(profile, isPro: entitlement.isPro) }
        }
    }
}

extension HomeView {
    @ViewBuilder
    private var tabContent: some View {
        switch tab {
        case "program":
            ProgramView(profile: profile)
        case "progress":
            ProgressTab(profile: profile)
        case "water":
            WaterTrackerView(profile: profile)
        default:
            TodayView(profile: profile, openWater: { tab = "water" }, openProgress: { tab = "progress" })
        }
    }

    private func dock(axis: Axis) -> some View {
        DXDock(
            items: [
                DXDockItem(id: "today", title: "Today", systemImage: "house"),
                DXDockItem(id: "water", title: "Water", systemImage: "drop"),
                DXDockItem(id: "program", title: "Program", systemImage: "book.closed"),
                DXDockItem(id: "progress", title: "Progress", systemImage: "chart.bar"),
            ],
            selection: $tab,
            // Today, Water, Craving SOS in the middle, Program, Progress.
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

struct TodayView: View {
    let profile: UserProfile
    /// Switches the dock to the water tracker.
    var openWater: () -> Void = {}
    /// Switches the dock to Progress (the header's round button).
    var openProgress: () -> Void = {}
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
    @State private var settingsPage: SettingsSheet.Page? = UserDefaults.standard.string(forKey: "dx.openSettings").flatMap(SettingsSheet.Page.init(rawValue:))
    @State private var showSettings = UserDefaults.standard.string(forKey: "dx.openSettings") != nil
    @State private var celebrating: Milestone?
    @State private var showHealth = false
    /// The use just logged with one tap, for the Undo / Add details toast (S7.1).
    @State private var justLogged: LogEntry?
    @State private var detailsFor: LogEntry?
    @State private var loggedFeedback = false

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
            try? await Task.sleep(for: .seconds(5))
            justLogged = nil
        }
        .sensoryFeedback(DX.Haptic.commit, trigger: loggedFeedback)
        .sheet(item: $detailsFor) { entry in
            CravingLogForm(profile: profile, editing: entry, onSaved: { detailsFor = nil })
                .presentationDetents([.large])
        }
        .onAppear { checkMilestone() }
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

    /// The top of Home, as on dayxero.in (S19): the header, the moss wave, today's lesson, and the streak.
    @ViewBuilder
    private func overview(_ snap: HomeSnapshot, now: Date) -> some View {
        header(snap, now: now)
        mossHeader(now: now)
        if let lesson = snap.lesson {
            if lesson.isReplay {
                ReplayCard(title: lesson.title, minutes: LessonLibrary.lesson(for: lesson.day, product: profile.primaryProduct?.product ?? .cigarettes).minutes) {
                    openLesson = .init(day: lesson.day, isReplay: true)
                }
            } else {
                lessonCard(lesson, finished: snap.finishedToday, prepTotal: snap.prepTotal)
            }
        }
        if snap.phase == .quitDay, !sosHintSeen { sosHint }
        // A plan made today, after a slip or in a lesson, stays on Home for the rest of the day (S8.3).
        if let plan = plans.first, DayClock(boundaryHour: profile.dayBoundaryHour).day(containing: plan.createdAt)
            == DayClock(boundaryHour: profile.dayBoundaryHour).day(containing: now) {
            PlanCard(situation: plan.situation, action: plan.action, title: "Your plan for next time")
        }
        streakCard(snap)
    }

    /// Then: the next change in the body, NRT set-up, logging in prep, today's pledge or check-in, and water.
    @ViewBuilder
    private func actions(_ snap: HomeSnapshot, now: Date) -> some View {
        milestoneRow(now: now).id("lower")
        nrtSection(snap, now: now)
        if isPrep(snap) { useRows(now: now) }
        dailyCard(now: now)
        WaterHomeCard(profile: profile, now: now, onOpen: openWater)
    }

    // MARK: Pledge and check-in (S11)

    @ViewBuilder
    private func dailyCard(now: Date) -> some View {
        let rhythm = DailyRhythm(clock: DayClock(boundaryHour: profile.dayBoundaryHour))
        let pledgedToday = rhythm.hasPledged(pledges.map(\.day), at: now)
        let force = debugDaily
        if force == "checkin" || (force == nil && rhythm.isCheckInTime(now) && !rhythm.hasCheckedIn(checkIns.map(\.day), at: now)) {
            DailyCard(systemImage: "moon", title: "Evening check-in", detail: "A minute on how today went", action: "Check in") {
                showCheckIn = true
            }
        } else if force == "pledge" || (force == nil && rhythm.isPledgeTime(now) && !pledgedToday) {
            DailyCard(systemImage: "sun.max", title: "Today's pledge", detail: "10 seconds, with one of your reasons", action: "Pledge") {
                showPledge = true
            }
        } else if force == "pledged" || (force == nil && rhythm.isPledgeTime(now) && pledgedToday), let pledge = pledges.first {
            DailyCard(systemImage: "checkmark", title: "Pledged at \(pledge.madeAt.formatted(date: .omitted, time: .shortened))",
                      detail: nil, action: nil, done: true) {}
        }
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

    // MARK: One-tap logging in prep (S7.1)

    @ViewBuilder
    private func useRows(now: Date) -> some View {
        Text("Log a use").dxText(.micro).padding(.top, DX.Space.xs)
        ForEach(profile.products.sorted { ($0.isPrimary ? 0 : 1) < ($1.isPrimary ? 0 : 1) }) { use in
            let counts = useCounts(use.product, now: now)
            Button { logUse(use.product) } label: {
                HStack(spacing: DX.Space.s) {
                    Image(systemName: LogSheet.icon(use.product)).font(.system(size: 18)).foregroundStyle(DX.Palette.text)
                        .frame(width: 42, height: 42).background(DX.Palette.surface2, in: Circle())
                    VStack(alignment: .leading, spacing: 1) {
                        // The same name as in the log sheet (S19.7).
                        Text(LogSheet.useTitle(use.product)).font(.custom(DX.Typeface.semibold, size: 15, relativeTo: .body)).foregroundStyle(DX.Palette.text)
                        Text("\(counts.today) today · \(counts.yesterday) yesterday").dxText(.subtitle)
                    }
                    Spacer(minLength: DX.Space.xs)
                    Image(systemName: "plus").font(.system(size: 16, weight: .bold)).foregroundStyle(DX.Palette.onPrimary)
                        .frame(width: 40, height: 40).background(DX.Palette.primary, in: Circle())
                }
                .padding(.vertical, DX.Space.s).padding(.horizontal, 14)
                .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(DX.Palette.hairline))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityHint(Text("Logs one now"))
        }
    }

    private func useCounts(_ product: Product, now: Date) -> (today: Int, yesterday: Int) {
        let clock = DayClock(boundaryHour: profile.dayBoundaryHour)
        let today = clock.day(containing: now)
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today
        let mine = logs.filter { $0.product == product && $0.kind != .craving && $0.timestamp >= yesterday }
        let todayCount = mine.filter { clock.day(containing: $0.timestamp) == today }.count
        return (todayCount, mine.count - todayCount)
    }

    private func logUse(_ product: Product) {
        justLogged = UseLog.log(product, in: context)
        loggedFeedback.toggle()
    }

    private func loggedToast(_ entry: LogEntry) -> some View {
        let count = entry.product.map { useCounts($0, now: .now).today } ?? 0
        return HStack(spacing: DX.Space.s) {
            Image(systemName: "checkmark").font(.system(size: 13, weight: .bold))
            Text("Logged · \(count) today").font(.custom(DX.Typeface.semibold, size: 13, relativeTo: .footnote))
            Spacer(minLength: DX.Space.xs)
            Button("Undo") {
                UseLog.undo(entry, in: context)
                justLogged = nil
            }
            .opacity(0.75)
            Button("Add details") {
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
        .dxReadableColumn()
        .padding(.bottom, DX.Space.xs)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .accessibilityElement(children: .contain)
    }

    private func isPrep(_ snap: HomeSnapshot) -> Bool {
        if case .prep = snap.phase { return true }
        return false
    }

    // MARK: Sections

    /// "Good morning" over the name, Settings, and the round button to Progress (S19.1).
    private func header(_ snap: HomeSnapshot, now: Date) -> some View {
        HStack(alignment: .center, spacing: DX.Space.xs) {
            VStack(alignment: .leading, spacing: 2) {
                Text(snap.phase == .quitDay ? String(localized: "Today's the day") : HomeSnapshot.greeting(at: now)).dxText(.micro)
                Text(verbatim: profile.name).dxText(.title).font(.custom(DX.Typeface.bold, size: 24, relativeTo: .title))
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            Spacer()
            Button { settingsPage = nil; showSettings = true } label: { Image(systemName: "person").accessibilityLabel(Text("Profile and settings")) }
                .buttonStyle(.dxIcon)
            Button(action: openProgress) {
                Image(systemName: "chart.line.uptrend.xyaxis").accessibilityLabel(Text("Your progress"))
            }
            .buttonStyle(.dxRound)
        }
        .padding(.bottom, DX.Space.xxs)
    }

    /// The moss wave with today's cravings, the next likely one, and Log (S19.2).
    private func mossHeader(now: Date) -> some View {
        let clock = DayClock(boundaryHour: profile.dayBoundaryHour)
        let cravings = logs.filter { $0.kind == .craving }.map(\.timestamp)
        let prep = ProgressStats(quitDay: profile.quitDay, baselines: [], clock: clock).isPrep(at: now)
        // The same events the widgets' forecast learns from (WidgetSync).
        let events = logs.filter { $0.kind == .craving || $0.kind == .slip || (prep && $0.kind == .use) }
            .map { CravingPredictor.Event(date: $0.timestamp, trigger: $0.trigger) }
        return MossWaveHeader(cravingsToday: CravingPace.today(cravingsAt: cravings, clock: clock, now: now),
                              usualCravings: CravingPace.usual(cravingsAt: cravings, clock: clock, now: now),
                              nextCraving: CravingPredictor.nextWindow(events: events, now: now),
                              now: now, onLog: { log.open() })
    }

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

    /// The lesson spotlight: a white card on dark, and the other way round on light, like dayxero.in.
    /// Its eyebrow is the one micro label inside a card (DESIGN_METHODOLOGY.md, S19.3).
    private func lessonCard(_ lesson: HomeSnapshot.Lesson, finished: ProgramDayID?, prepTotal: Int) -> some View {
        let ink = DX.Palette.onPrimary
        let minutes = LessonLibrary.lesson(for: lesson.day, product: profile.primaryProduct?.product ?? .cigarettes).minutes
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: DX.Space.xs) {
                Text(verbatim: lessonEyebrow(lesson.day)).dxText(.micro, color: ink.opacity(0.5))
                Spacer(minLength: DX.Space.xs)
                if lesson.placeholder { PlaceholderTag() }
                if let badge = lessonBadge(lesson) {
                    Text(badge).font(.custom(DX.Typeface.bold, size: 10, relativeTo: .caption2))
                        .textCase(.uppercase)
                        .foregroundStyle(DX.Palette.onAccent)
                        .padding(.vertical, 3).padding(.horizontal, 8)
                        .background(DX.Palette.sage, in: Capsule())
                }
            }
            if let finished {
                Label {
                    Text("\(LessonCatalog.title(for: finished)) done").dxText(.subtitle, color: ink.opacity(0.7))
                } icon: {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(DX.Palette.accentInk)
                }
            }
            Text(lesson.title).dxText(.cardHeading, color: ink).font(.custom(DX.Typeface.bold, size: 17, relativeTo: .headline))
            Text(verbatim: lessonDetail(lesson, prepTotal: prepTotal)).dxText(.subtitle, color: ink.opacity(0.7))
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
                let title = lesson.resumeStep > 0 ? String(localized: "Continue (\(minutes) min)")
                    : finished == nil ? String(localized: "Start today's lesson (\(minutes) min)")
                    : String(localized: "Start the next one (\(minutes) min)")
                lessonButton(title, systemImage: "play.fill") { openLesson = .init(day: lesson.day, isReplay: false) }
            case .completed, .locked:
                EmptyView()
            }
        }
        .padding(DX.Space.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DX.Palette.primary, in: RoundedRectangle(cornerRadius: DX.Radius.card, style: .continuous))
        .shadow(color: DX.Palette.sage.opacity(0.15), radius: 20)
        .shadow(color: DX.Palette.shadow, radius: 24, y: 12)
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
                .font(.custom(DX.Typeface.semibold, size: 14, relativeTo: .subheadline))
                .foregroundStyle(DX.Palette.primary)
                .frame(maxWidth: .infinity, minHeight: 44)
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
                Image(systemName: "flame").foregroundStyle(DX.Palette.accentInk)
                Text("Craving? Tap the green button any time. It takes 3 minutes.")
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

    // MARK: Streak and adherence (S19.4)

    /// Prep: lessons done in a row and the Quit Day countdown. From Quit Day: days clear toward the next milestone.
    /// Both with adherence: program days done out of those due.
    private func streakCard(_ snap: HomeSnapshot) -> some View {
        let percent = snap.adherence.formatted(.percent.precision(.fractionLength(0)))
        return DXGlassCard {
            VStack(alignment: .leading, spacing: DX.Space.s) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        switch snap.phase {
                        case let .prep(days):
                            Text("Prep streak").dxText(.micro, color: DX.Palette.accentInk)
                            streakNumber(snap.lessonStreak, of: snap.prepTotal)
                            Text(verbatim: "\(String(localized: "Quit Day")) \(profile.quitDay.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))) · \(days == 1 ? String(localized: "1 day to go") : String(localized: "\(days) days to go"))")
                                .dxText(.subtitle)
                        default:
                            Text("Smoke-free streak").dxText(.micro, color: DX.Palette.accentInk)
                            streakNumber(snap.daysClear, of: snap.nextMilestone)
                            if snap.phase == .quitDay { Text("Your first day. One craving at a time.").dxText(.subtitle) }
                        }
                    }
                    Spacer(minLength: DX.Space.s)
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Adherence").dxText(.micro)
                        Text(verbatim: percent).font(.custom(DX.Typeface.bold, size: 15, relativeTo: .subheadline))
                            .foregroundStyle(DX.Palette.accentInk)
                    }
                }
                DXProgressBar(value: snap.adherence, tint: .primary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    /// "4 / 7 days", or "12 days" past the last milestone.
    private func streakNumber(_ value: Int, of total: Int?) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(value, format: .number).dxText(.hero).contentTransition(.numericText())
            if let total {
                Text("/ \(total) days").dxText(.heroDenominator)
            } else {
                Text(value == 1 ? LocalizedStringKey("day") : LocalizedStringKey("days")).dxText(.heroDenominator)
            }
        }
    }

    // MARK: Next change in the body (S19.5)

    /// What's changing in the body now and what's next, with its illustration. Opens the health timeline.
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
                MilestoneIllustration(id: featured?.id ?? "")
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: featured?.title ?? String(localized: "Your body is recovering"))
                        .font(.custom(DX.Typeface.semibold, size: 14, relativeTo: .subheadline)).foregroundStyle(DX.Palette.text)
                        .multilineTextAlignment(.leading)
                    Text(verbatim: line).dxText(.subtitle).multilineTextAlignment(.leading)
                }
                .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: DX.Space.xs)
                Image(systemName: "chevron.right").font(.system(size: 11, weight: .semibold)).foregroundStyle(DX.Palette.text2)
                    .frame(width: 24, height: 24).background(DX.Palette.track, in: Circle())
                    .accessibilityHidden(true)
            }
            .padding(14)
            .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: DX.Radius.card, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: DX.Radius.card, style: .continuous).strokeBorder(DX.Palette.hairline))
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
