import DayXeroCore
import SwiftData
import SwiftUI

/// The app after onboarding: Today, Toolkit, Program and Progress in the floating dock, with Craving SOS in the middle.
struct HomeView: View {
    let profile: UserProfile
    @State private var tab = UserDefaults.standard.string(forKey: "dx.tab") ?? "today"
    @Environment(SOSRouter.self) private var sos
    @Environment(Entitlement.self) private var entitlement
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            switch tab {
            case "program":
                ProgramView(profile: profile)
            case "progress":
                ProgressTab(profile: profile)
            case "toolkit", "water":
                // "water" is the old tab id: open the toolkit with the tracker showing.
                ToolkitView(profile: profile, openWater: tab == "water")
            default:
                TodayView(profile: profile)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // The dock floats over the tabs; the inset lets every tab's last row scroll clear of it.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            DXDock(
                items: [
                    DXDockItem(id: "today", title: "Today", systemImage: "house"),
                    DXDockItem(id: "toolkit", title: "Toolkit", systemImage: "shield"),
                    DXDockItem(id: "program", title: "Program", systemImage: "book.closed"),
                    DXDockItem(id: "progress", title: "Progress", systemImage: "chart.bar"),
                ],
                selection: dockSelection,
                // Today, Toolkit, Craving SOS in the middle, Program, Progress.
                sosPosition: 2,
                sosAction: { sos.open(source: "dock") }
            )
            .padding(.bottom, DX.Space.xxs)
        }
        .dxCanvas()
        // A break of 3+ days pauses the program until the last day is replayed (S5.7).
        .onChange(of: scenePhase, initial: true) { _, phase in
            if phase == .active { ProgramUpkeep.checkForBreak(profile, isPro: entitlement.isPro) }
        }
    }

    private var dockSelection: Binding<String> {
        Binding(get: { tab == "water" ? "toolkit" : tab }, set: { tab = $0 })
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
        .dxCanvas()
    }
}

struct TodayView: View {
    let profile: UserProfile
    @State private var showWater = false
    @Environment(Entitlement.self) private var entitlement
    @Environment(\.modelContext) private var context
    @AppStorage("dx.sosHintSeen") private var sosHintSeen = false
    @State private var openLesson: ProgramView.LessonOpen?
    @State private var upgradeTitle: String?
    @State private var showUpgrade = false
    @State private var showPaywall = false
    @Environment(\.dynamicTypeSize) private var typeSize
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
    /// The use just logged with one tap, for the Undo / Add details toast (S7.1).
    @State private var justLogged: LogEntry?
    @State private var detailsFor: LogEntry?
    @State private var loggedFeedback = false

    var body: some View {
        // Re-evaluates each minute so counters tick and the day rolls over on its own.
        TimelineView(.everyMinute) { timeline in
            let snap = HomeSnapshot(profile: profile, isPro: entitlement.isPro, now: timeline.date)
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    header(snap, now: timeline.date)
                    hero(snap)
                    dailyCard(now: timeline.date)
                    WaterHomeCard(profile: profile, now: timeline.date, onOpen: { showWater = true })
                    if let lesson = snap.lesson {
                        if lesson.isReplay {
                            ReplayCard(title: lesson.title, minutes: LessonLibrary.lesson(for: lesson.day, product: profile.primaryProduct?.product ?? .cigarettes).minutes) {
                                openLesson = .init(day: lesson.day, isReplay: true)
                            }
                        } else {
                            lessonCard(lesson, finished: snap.finishedToday)
                        }
                    }
                    if snap.phase == .quitDay, !sosHintSeen { sosHint }
                    // A plan made today, after a slip or in a lesson, stays on Home for the rest of the day (S8.3).
                    if let plan = plans.first, DayClock(boundaryHour: profile.dayBoundaryHour).day(containing: plan.createdAt)
                        == DayClock(boundaryHour: profile.dayBoundaryHour).day(containing: timeline.date) {
                        PlanCard(situation: plan.situation, action: plan.action, title: "Your plan for next time")
                    }
                    nrtSection(snap, now: timeline.date)
                    if isPrep(snap) { useRows(now: timeline.date) }
                    tiles(snap)
                    if let next = snap.nextMilestone, !isPrep(snap) { milestone(next: next, daysClear: snap.daysClear) }
                }
                .padding(.horizontal, DX.Space.m)
                .padding(.top, DX.Space.s)
                .padding(.bottom, DX.Space.l)
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
        .fullScreenCover(isPresented: $showPledge) {
            PledgeView(profile: profile) { showPledge = false }
        }
        .fullScreenCover(isPresented: $showWater) {
            WaterTrackerView(profile: profile, onClose: { showWater = false })
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

    @ViewBuilder
    private func nrtSection(_ snap: HomeSnapshot, now: Date) -> some View {
        let clock = DayClock(boundaryHour: profile.dayBoundaryHour)
        // Plans stay on Home until a week after they finish.
        let shown = profile.nrtPlans.filter { plan in
            guard let end = StepSchedule(startDate: plan.startDate, steps: plan.steps, clock: clock).end else { return false }
            return clock.day(containing: now) < (clock.calendar.date(byAdding: .day, value: 7, to: end) ?? end)
        }
        ForEach(shown.sorted { $0.createdAt < $1.createdAt }) { plan in
            NRTCard(plan: plan, clock: clock, now: now)
        }
        if profile.nrtPlans.isEmpty, profile.nrtInterest == .using || profile.nrtInterest == .wantIt {
            NRTInviteRow(title: "Set up your NRT", detail: "Reminders for patches and step-downs", systemImage: "bandage") {
                nrt.sheet = .setup
            }
        }
        if isPrep(snap), profile.products.contains(where: { $0.product == .pouches }) {
            if let taper = profile.pouchTaper {
                Button { nrt.sheet = .taper } label: { TaperCard(taper: taper, clock: clock, now: now) }.buttonStyle(.plain)
            } else {
                NRTInviteRow(title: "Step down your pouches", detail: "Optional, before Quit Day", systemImage: "chart.line.downtrend.xyaxis") {
                    nrt.sheet = .taper
                }
            }
        }
    }

    // MARK: One-tap logging in prep (S7.1)

    @ViewBuilder
    private func useRows(now: Date) -> some View {
        Text("Log a use · today").dxText(.micro).padding(.top, DX.Space.xs)
        ForEach(profile.products.sorted { ($0.isPrimary ? 0 : 1) < ($1.isPrimary ? 0 : 1) }) { use in
            let counts = useCounts(use.product, now: now)
            Button { logUse(use.product) } label: {
                HStack(spacing: DX.Space.s) {
                    Image(systemName: LogSheet.icon(use.product)).font(.system(size: 18)).foregroundStyle(DX.Palette.text)
                        .frame(width: 42, height: 42).background(DX.Palette.surface2, in: Circle())
                    VStack(alignment: .leading, spacing: 1) {
                        Text(usePlural(use.product)).font(.custom(DX.Typeface.semibold, size: 15, relativeTo: .body)).foregroundStyle(DX.Palette.text)
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
        urgeRow(now: now)
    }

    /// An urge goes straight to the craving form (strength, trigger, or ride it out with SOS), not via the Log menu.
    private func urgeRow(now: Date) -> some View {
        let clock = DayClock(boundaryHour: profile.dayBoundaryHour)
        let today = clock.day(containing: now)
        let urges = logs.prefix(300).filter { $0.kind == .craving && clock.day(containing: $0.timestamp) == today }
        let ridden = urges.filter { $0.outcome == .passed }.count
        return Button { log.open(.craving) } label: {
            HStack(spacing: DX.Space.s) {
                Image(systemName: "flame").font(.system(size: 18)).foregroundStyle(DX.Palette.accentInk)
                    .frame(width: 42, height: 42).background(DX.Palette.accentSoft, in: Circle())
                VStack(alignment: .leading, spacing: 1) {
                    Text("Urges").font(.custom(DX.Typeface.semibold, size: 15, relativeTo: .body)).foregroundStyle(DX.Palette.text)
                    Text("\(urges.count) today · \(ridden) ridden out").dxText(.subtitle)
                }
                Spacer(minLength: DX.Space.xs)
                Text("+ Urge").font(.custom(DX.Typeface.semibold, size: 13, relativeTo: .footnote))
                    .foregroundStyle(DX.Palette.onAccent)
                    .padding(.horizontal, 14).frame(height: 40)
                    .background(DX.Palette.sage, in: Capsule())
            }
            .padding(.vertical, DX.Space.s).padding(.horizontal, 14)
            .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(DX.Palette.hairline))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint(Text("Logs an urge: how strong, and what set it off"))
    }

    private func useCounts(_ product: Product, now: Date) -> (today: Int, yesterday: Int) {
        let clock = DayClock(boundaryHour: profile.dayBoundaryHour)
        let today = clock.day(containing: now)
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today
        let mine = logs.filter { $0.product == product && $0.kind != .craving && $0.timestamp >= yesterday }
        let todayCount = mine.filter { clock.day(containing: $0.timestamp) == today }.count
        return (todayCount, mine.count - todayCount)
    }

    private func usePlural(_ product: Product) -> LocalizedStringKey {
        switch product {
        case .cigarettes: "Cigarettes"
        case .vape: "Puff sessions"
        case .pouches: "Pouches"
        }
    }

    private func logUse(_ product: Product) {
        justLogged = UseLog.log(product, in: context)
        loggedFeedback.toggle()
    }

    private func loggedToast(_ entry: LogEntry) -> some View {
        let count = entry.product.map { useCounts($0, now: .now).today } ?? 0
        return HStack(spacing: DX.Space.s) {
            Image(systemName: "checkmark").font(.system(size: 13, weight: .bold))
            Text(toastTitle(entry.product, count: count)).font(.custom(DX.Typeface.semibold, size: 13, relativeTo: .footnote))
                .lineLimit(2)
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
        case .vape: String(localized: "Puff session #\(count) logged")
        case .pouches: String(localized: "Pouch #\(count) logged")
        case nil: String(localized: "Logged")
        }
    }

    private func isPrep(_ snap: HomeSnapshot) -> Bool {
        if case .prep = snap.phase { return true }
        return false
    }

    // MARK: Sections

    private func header(_ snap: HomeSnapshot, now: Date) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(eyebrow(snap, now: now)).dxText(.micro)
                Text(title(snap, now: now)).dxText(.title).font(.custom(DX.Typeface.bold, size: 24, relativeTo: .title))
            }
            Spacer()
            LogButton { log.open() }
            Button { settingsPage = nil; showSettings = true } label: { Image(systemName: "person").accessibilityLabel(Text("Profile and settings")) }
                .buttonStyle(.dxIcon)
        }
        .padding(.bottom, DX.Space.xxs)
    }

    private func eyebrow(_ snap: HomeSnapshot, now: Date) -> String {
        let weekday = now.formatted(.dateTime.weekday(.wide))
        switch snap.phase {
        case .prep: return "\(weekday) · \(String(localized: "Prep day \(snap.prepDayNumber)"))"
        case .quitDay: return "\(weekday) · \(String(localized: "Quit Day"))"
        case let .quitWeek(day): return "\(weekday) · \(String(localized: "Day \(day)"))"
        case let .after(days): return "\(weekday) · \(String(localized: "Week \(days / 7 + 1)"))"
        }
    }

    private func title(_ snap: HomeSnapshot, now: Date) -> String {
        if snap.phase == .quitDay { return String(localized: "Today's the day, \(profile.name)") }
        if snap.finishedToday != nil { return String(localized: "Nice work, \(profile.name)") }
        return "\(HomeSnapshot.greeting(at: now)), \(profile.name)"
    }

    @ViewBuilder
    private func hero(_ snap: HomeSnapshot) -> some View {
        DXGlassCard {
            VStack(alignment: .leading, spacing: 4) {
                switch snap.phase {
                case let .prep(days):
                    Text("Quit Day in").dxText(.micro)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(days, format: .number).dxText(.hero)
                        Text("\(days == 1 ? String(localized: "day") : String(localized: "days")) · \(profile.quitDay.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))")
                            .dxText(.heroDenominator)
                    }
                    Text(verbatim: prepLine).dxText(.subtitle)
                    DXWeekStrip(days: snap.weekStrip).padding(.top, DX.Space.s)
                case .quitDay:
                    Text("Days clear").dxText(.micro)
                    DXFraction(1, of: ProgramSchedule.quitWeekDays)
                    Text("Your first day. One craving at a time.").dxText(.subtitle)
                    DXProgressBar(value: 1.0 / Double(ProgramSchedule.quitWeekDays), tint: .primary).padding(.top, DX.Space.s)
                    DXWeekStrip(days: snap.weekStrip).padding(.top, DX.Space.s)
                case let .quitWeek(day):
                    Text("Days clear").dxText(.micro)
                    DXFraction(day, of: ProgramSchedule.quitWeekDays)
                    let weekFraction = Double(snap.quitWeekDone) / Double(ProgramSchedule.quitWeekDays)
                    DXMetric("Quit week", value: weekFraction.formatted(.percent.precision(.fractionLength(0))),
                             progress: weekFraction, tint: .primary)
                        .padding(.top, DX.Space.xs)
                    DXWeekStrip(days: snap.weekStrip).padding(.top, DX.Space.s)
                case let .after(days):
                    Text("Days clear").dxText(.micro)
                    DXFraction(days, unit: "days")
                    if let next = snap.nextMilestone {
                        DXMetric(LocalizedStringKey(milestoneLabel(next)), value: "\(days) / \(next)",
                                 progress: snap.milestoneFraction, tint: .accent)
                            .padding(.top, DX.Space.xs)
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var prepLine: String {
        let verbs = Product.allCases.filter { p in profile.products.contains { $0.product == p } }.map { product -> String in
            switch product {
            case .cigarettes: String(localized: "smoke")
            case .vape: String(localized: "vape")
            case .pouches: String(localized: "use pouches")
            }
        }
        let joined = ListFormatter.localizedString(byJoining: verbs.reversed())
        return String(localized: "You can still \(joined) while you prepare.")
    }

    @ViewBuilder
    private func lessonCard(_ lesson: HomeSnapshot.Lesson, finished: ProgramDayID?) -> some View {
        DXCard(padding: DX.Space.m) {
            VStack(alignment: .leading, spacing: 4) {
                if let finished {
                    Label {
                        Text("\(LessonCatalog.title(for: finished)) done").font(DX.TextStyle.subtitle.font).foregroundStyle(DX.Palette.text2)
                    } icon: {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(DX.Palette.sage)
                    }
                }
                Text(finished == nil ? "Today · \(lesson.position)" : "Next · \(lesson.position)").dxText(.micro)
                HStack(spacing: 6) {
                    Text(lesson.title).dxText(.cardHeading)
                    if lesson.placeholder { PlaceholderTag() }
                }
                switch lesson.availability {
                case let .opensOn(date):
                    Label {
                        Text(opensText(date)).dxText(.subtitle)
                    } icon: {
                        Image(systemName: "clock").foregroundStyle(DX.Palette.muted)
                    }
                case .available where lesson.needsUpgrade:
                    Label {
                        Text("Part of the full program").dxText(.micro)
                    } icon: {
                        Image(systemName: "lock").foregroundStyle(DX.Palette.muted)
                    }
                    Button("Unlock \(lesson.title)") { upgradeTitle = lesson.title; showUpgrade = true }
                        .buttonStyle(.dxPrimary).padding(.top, DX.Space.xs)
                case .available:
                    Button(lesson.resumeStep > 0 ? "Continue" : finished == nil ? "Start" : "Start next") {
                        openLesson = .init(day: lesson.day, isReplay: false)
                    }
                        .buttonStyle(.dxPrimary).padding(.top, DX.Space.xs)
                case .completed, .locked:
                    EmptyView()
                }
            }
        }
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

    @ViewBuilder
    private func tiles(_ snap: HomeSnapshot) -> some View {
        let columns = typeSize.isAccessibilitySize
            ? [GridItem(.flexible())]
            : [GridItem(.flexible(), spacing: DX.Space.xs), GridItem(.flexible())]
        LazyVGrid(columns: columns, alignment: .leading, spacing: DX.Space.xs) {
            if isPrep(snap) {
                tile("You'll keep", value: snap.moneyPerYear.formatted(.currency(code: snap.currencyCode).precision(.fractionLength(0))),
                     caption: "a year, from Quit Day")
                tile("Prep days done", value: "\(snap.prepDone) / \(snap.prepTotal)", caption: snap.prepDone > 0 ? "on track" : "starts today")
            } else {
                ForEach(snap.counters) { counter in
                    tile(avoidedLabel(counter.product), value: counter.avoided.formatted(),
                         caption: "\(counter.perDayBefore) a day before")
                }
                tile("Money kept", value: snap.moneyKept.formatted(.currency(code: snap.currencyCode)),
                     caption: snap.phase == .quitDay ? "since this morning" : "since \(profile.quitDay.formatted(.dateTime.weekday(.wide)))")
            }
        }
    }

    private func avoidedLabel(_ product: Product) -> LocalizedStringKey {
        switch product {
        case .cigarettes: "Cigarettes not smoked"
        case .vape: "Puffs not taken"
        case .pouches: "Pouches not used"
        }
    }

    private func tile(_ label: LocalizedStringKey, value: String, caption: LocalizedStringKey) -> some View {
        DXCard(padding: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(label).dxText(.micro).fixedSize(horizontal: false, vertical: true)
                Text(verbatim: value).dxText(.cardHeading).font(.custom(DX.Typeface.bold, size: 20, relativeTo: .title3))
                    .contentTransition(.numericText())
                Text(caption).dxText(.subtitle)
            }
            .frame(maxWidth: .infinity, minHeight: 84, alignment: .topLeading)
        }
        .accessibilityElement(children: .combine)
    }

    private func milestoneLabel(_ next: Int) -> String {
        switch next {
        case 7: String(localized: "To one week")
        case 14: String(localized: "To two weeks")
        case 30: String(localized: "To one month")
        case 365: String(localized: "To one year")
        default: String(localized: "To \(next) days")
        }
    }

    private func milestoneName(_ next: Int) -> String {
        switch next {
        case 1: String(localized: "Your first day clear")
        case 7: String(localized: "One week clear")
        case 14: String(localized: "Two weeks clear")
        case 30: String(localized: "One month clear")
        case 365: String(localized: "One year clear")
        default: String(localized: "\(next) days clear")
        }
    }

    private func milestone(next: Int, daysClear: Int) -> some View {
        let remaining = next - daysClear
        return DXCapsuleCard {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Next milestone").dxText(.micro)
                    Text("\(milestoneName(next)) · \(remaining == 1 ? String(localized: "tomorrow") : String(localized: "in \(remaining) days"))")
                        .dxText(.cardHeading).font(.custom(DX.Typeface.semibold, size: 14, relativeTo: .subheadline))
                }
                Spacer()
                Image(systemName: "flag")
                    .foregroundStyle(DX.Palette.accentInk)
                    .frame(width: 40, height: 40)
                    .background(DX.Palette.accentSoft, in: Circle())
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
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
