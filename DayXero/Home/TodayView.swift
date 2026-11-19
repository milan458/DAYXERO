import DayXeroCore
import SwiftData
import SwiftUI

/// Today (v5, cook/site/screens/015-018): a paper-cut scene with the crew, the greeting and the day's line; under it
/// the one card that matters now, the prep countdown, the day's log, then the rest of the day as quiet lists.
/// Scrolling folds the scene into a slim header pinned at the top. After 6 PM the whole screen goes dark with Glim
/// on the night ground (see `HomeView`). Motion specs are in TodayHero.swift and TodayTimeline.swift.
///
/// Every number here comes from the same place the rest of the app reads it, so Today, Program and Progress agree:
/// prep sessions and days clear from `HomeSnapshot`, the session from `ProgramToday`, smoke-free days from
/// `Resilience` (and the week's ticks follow the same rule, `TodayWeek`), body changes from `HealthTimeline` and
/// `RecoveryCopy`, the pledge and check-in from `DailyRhythm`, and the next milestone from `Milestones`.
struct TodayView: View {
    let profile: UserProfile
    /// The uses just logged, one or a batch (UX-05), for the Undo / Add trigger toast.
    @State private var justLogged: [LogEntry]?
    @State private var detailsFor: LogEntry?
    @State private var loggedFeedback = false
    @Environment(Entitlement.self) private var entitlement
    @Environment(\.modelContext) private var context
    private let motion = MotionPolicy()
    @State private var upgradeTitle: String?
    @State private var showUpgrade = false
    @State private var showPaywall = false
    /// The session open over Today. Held here, not on the card, so it stays open when the card moves at 6 PM.
    @State private var session: SessionOpen?
    @Environment(LogRouter.self) private var log
    @Query(sort: \LogEntry.timestamp, order: .reverse) private var logs: [LogEntry]
    @Query(sort: \Pledge.madeAt, order: .reverse) private var pledges: [Pledge]
    @Query(sort: \CheckIn.madeAt, order: .reverse) private var checkIns: [CheckIn]
    /// Program v2 sessions, so the prep count and the week's ticks update as soon as a session is finished.
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
    /// The sky's height, and whether it has scrolled far enough away for the slim card.
    @State private var heroHeight: CGFloat = 480
    @State private var showSlim = false
    @Environment(\.dynamicTypeSize) private var typeSize
    /// Today's prep challenge (CLIN-11): the day it was last done.
    @AppStorage("dx.prepChallengeDoneOn") private var challengeDoneOn = 0.0

    var body: some View {
        // Re-evaluates each minute so counters tick, the day rolls over and night falls on its own.
        TimelineView(.everyMinute) { timeline in
            let now = timeline.date
            let day = TodayDay(view: self, now: now)
            GeometryReader { geo in
                let top = geo.safeAreaInsets.top
                // Half-open iPhone Duo: the sky on one side of the fold, the day on the other (S18.14).
                FoldAware {
                    scroll(top: top) { hero(day, top: top) }
                } secondary: {
                    scroll(top: 0) { lower(day).padding(.top, top) }
                } flat: {
                    scroll(top: top, tracksHero: true) {
                        hero(day, top: top)
                        lower(day)
                    }
                    .overlay(alignment: .top) {
                        if showSlim {
                            TodaySlimHeader(model: day.hero)
                                .dxReadableColumn()
                                .background(alignment: .top) {
                                    pageColor(day).opacity(0.94).background(.ultraThinMaterial).ignoresSafeArea(edges: .top)
                                }
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                }
            }
            .background(pageBackground(day).ignoresSafeArea())
        }
        .animation(motion.animation(DX.Move.settle), value: showSlim)
        .overlay(alignment: .bottom) {
            if let entries = justLogged { loggedToast(entries) }
        }
        .animation(motion.animation(DX.Move.settle), value: justLogged)
        .task(id: justLogged) {
            guard justLogged != nil else { return }
            try? await Task.sleep(for: .seconds(4))
            justLogged = nil
        }
        .task {
            // "Start my prep week" queued Prep 1 (S22, QW1). Let Home's cross-fade from onboarding settle first (QW6).
            guard UserDefaults.standard.bool(forKey: FirstLesson.key) else { return }
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            openQueuedFirstSession()
        }
        .sensoryFeedback(DX.Haptic.commit, trigger: loggedFeedback)
        .sheet(item: $detailsFor) { entry in
            CravingLogForm(profile: profile, editing: entry, onSaved: { detailsFor = nil })
                .presentationDetents([.large])
        }
        .onAppear { checkMilestone() }
        // Holding Day Xero's commit starts the counter; celebrate as soon as the session closes.
        .onReceive(NotificationCenter.default.publisher(for: .dxSessionClosed)) { _ in
            Task {
                try? await Task.sleep(for: .seconds(0.6))
                checkMilestone()
            }
        }
        .dxCover(item: $session, onDismiss: {
            NotificationCenter.default.post(name: .dxSessionClosed, object: nil)
        }) { item in
            SessionFlowView(sessionId: item.id, profile: profile, isReplay: item.isReplay)
        }
        .dxCover(item: $celebrating) { milestone in
            MilestoneMoment(milestone: milestone, stats: MilestoneStats(profile: profile, logs: logs)) {
                CelebratedMilestones.markReached(daysClear: HomeSnapshot(profile: profile, isPro: entitlement.isPro).daysClear)
                celebrating = nil
            }
        }
        .dxCover(isPresented: $showHealth) {
            HealthTimelineView(profile: profile, onClose: { showHealth = false })
        }
        .dxCover(isPresented: $showPledge) {
            PledgeView(profile: profile) { showPledge = false }
        }
        .dxCover(isPresented: $showCheckIn) {
            CheckInView(profile: profile) { showCheckIn = false }
        }
        .dxCover(isPresented: $showCalmTools) {
            CalmToolsView(onClose: { showCalmTools = false }, fromSOS: false)
        }
        .dxCover(isPresented: $showSettings) {
            SettingsSheet(profile: profile, start: settingsPage)
        }
        .sheet(isPresented: $showUpgrade) {
            UpgradeSheet(dayTitle: upgradeTitle ?? "", model: PaywallModel(store: entitlement.store, entitlement: entitlement),
                         showAllPlans: { showUpgrade = false; showPaywall = true },
                         onUnlocked: { showUpgrade = false })
                .presentationDetents([.medium, .large])
        }
        .dxCover(isPresented: $showPaywall) {
            PaywallView(name: profile.name, quitDay: profile.quitDay,
                        model: PaywallModel(store: entitlement.store, entitlement: entitlement),
                        onClose: { showPaywall = false })
        }
    }

    // MARK: Layout

    private func scroll<Content: View>(top: CGFloat, tracksHero: Bool = false, @ViewBuilder _ content: () -> Content) -> some View {
        let built = content()
        return ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) { built }
            }
            .scrollBounceBehavior(.basedOnSize)
            .ignoresSafeArea(.container, edges: .top)
            .onScrollGeometryChange(for: Bool.self) { geometry in
                tracksHero && geometry.contentOffset.y > max(heroHeight - top - 150, 60)
            } action: { _, folded in
                showSlim = folded
            }
            #if DEBUG
            // Screenshots of Today's lower half: `-dx.homeScroll lower`.
            .onAppear { if UserDefaults.standard.string(forKey: "dx.homeScroll") == "lower" { proxy.scrollTo("lower", anchor: .top) } }
            #endif
        }
    }

    private func hero(_ day: TodayDay, top: CGFloat) -> some View {
        let onRing: (() -> Void)? = if day.state == .postQuit { { showHealth = true } } else { nil }
        return TodayHero(model: day.hero, topInset: top, onProfile: { settingsPage = nil; showSettings = true }, onRing: onRing)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { heroHeight = $0 }
    }

    /// The page: the kit's lighter cream under the scene during prep (015); after Quit Day the apricot ground fading
    /// to cream down the scroll (016, 017); the night ground after 6 PM (018).
    private func pageColor(_ day: TodayDay) -> Color {
        day.night ? DX.Ground.violet.background : TodayInk.page
    }

    @ViewBuilder
    private func pageBackground(_ day: TodayDay) -> some View {
        if day.night {
            DX.Ground.violet.background
        } else if day.state == .postQuit {
            LinearGradient(stops: [.init(color: Color(light: 0xFFC38A, dark: 0x0E1322), location: 0),
                                   .init(color: Color(light: 0xFFD9B4, dark: 0x0E1322), location: 0.45),
                                   .init(color: TodayInk.page, location: 1)], startPoint: .top, endPoint: .bottom)
        } else {
            TodayInk.page
        }
    }

    /// The focus card, the prep countdown, the day's log and the rest of the day.
    private func lower(_ day: TodayDay) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if day.focus == .recovery {
                Text("Now").dxFace(.display, 19, weight: 700, tracking: -0.2).foregroundStyle(TodayInk.ink)
                    .padding(.leading, 2)
                    .accessibilityAddTraits(.isHeader)
                    .dxArrive(4)
            }
            focusCard(day).id("lower").dxArrive(4)
            if day.state == .prep, let stamps = day.stamps {
                TodayPrepStamps(daysToQuit: stamps.daysToQuit, quitDate: stamps.quitDate, done: stamps.done,
                                total: stamps.total, current: stamps.current)
                    .dxArrive(5)
            }
            // Waves and water ride in the Now card by day; in the evening they keep their own card.
            if day.night && day.focus != .recovery {
                logRows(day).todayCard().dxArrive(6)
            }
            timeline(day).padding(.top, 12)
        }
        .padding(.horizontal, DX.Layout.gutter)
        .padding(.top, day.night ? -24 : 18)
        // Room for the floating tab bar is HomeView's bottom inset (UX-11).
        .padding(.bottom, DX.Space.s)
        .dxReadableColumn()
    }

    // MARK: Focus (UX-08)

    /// One card by the time of day: the session until 6 PM (after Day Xero, the day's session while it's open, then
    /// what's changing in the body); then Glim's check-in; late at night, once checked in, winding down.
    @ViewBuilder
    private func focusCard(_ day: TodayDay) -> some View {
        switch day.focus {
        case .lesson:
            if let today = day.program {
                TodaySessionCard(today: today, style: .focus, crewStage: day.crewStage, onOpen: openSession, onUnlock: unlock)
            }
        case .recovery:
            let copy = day.recovery
            TodayFocusCard(art: .recovery(id: copy.featuredID ?? ""),
                           kicker: String(localized: "\(copy.kicker) · Day \(max(day.snap.daysClear, 1))"), title: copy.title,
                           crewStage: day.crewStage, action: { showHealth = true }) {
                Rectangle().fill(TodayInk.line).frame(height: 1)
                logRows(day)
            }
            .accessibilityHint(Text("Opens what changes in your body"))
        case .checkIn:
            TodayFocusCard(art: .checkIn, kicker: String(localized: "With Glim · 1 min"),
                           title: String(localized: "How did today go?"), button: String(localized: "Check in"),
                           crewStage: day.crewStage, action: { showCheckIn = true }) {
                TodayNightTicks(nights: day.nights)
                let done = day.nights.filter(\.done).count
                Group {
                    if done == 6 {
                        Text("\(Text("6 of 7 nights.").bold())\nTonight earns your 7-night badge.")
                    } else if done == 0 {
                        Text("\(Text("Your first night this week.").bold())\nSeven in a row earns the night badge.")
                    } else {
                        Text("\(Text("\(done) of 7 nights.").bold())\nTonight makes it \(done + 1).")
                    }
                }
                .dxType(.footnote)
                .foregroundStyle(DX.Ground.violet.muted)
                .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityHint(Text("Opens the evening check-in"))
        case .windDown:
            TodayFocusCard(art: .windDown, kicker: String(localized: "Wind down"),
                           title: String(localized: "Can't sleep? Breathe with Glim"),
                           detail: String(localized: "A slow breath, then rest."), button: String(localized: "Breathe"),
                           crewStage: day.crewStage) { showCalmTools = true }
        }
    }

    // MARK: Timeline

    /// The rest of the day as one quiet list (015 "Later today", 017 "Later"): the pledge, today's read, the prep
    /// challenge, logging the day's use and water during prep, Glim's check-in and the wind-down breath.
    @ViewBuilder
    private func timeline(_ day: TodayDay) -> some View {
        let challenge: PrepChallenge? = if day.state == .prep, case .prep = day.snap.phase {
            PrepChallenge.forPrepDay(day.snap.prepDayNumber)
        } else { nil }
        let recoveryRow = day.state == .postQuit && day.focus != .recovery
        TodaySection(title: day.state == .prep && !day.night ? String(localized: "Later today") : String(localized: "Later"), index: 7) {
            if let time = day.pledgedAt {
                TodayStep(node: .done) { TodayDoneRow(title: String(localized: "Morning pledge"), detail: done(at: time)) }
            } else if day.showsPledge {
                TodayRowCard(icon: .sun, title: String(localized: "Morning pledge"), detail: String(localized: "10 sec"),
                             showsChevron: true) { showPledge = true }
                    .accessibilityHint(Text("Opens the morning pledge"))
            }
            if let finished = day.sessionDone {
                TodayStep(node: .done) { TodayDoneRow(title: finished.title, detail: done(at: finished.time)) }
            } else if day.sessionRow, let today = day.program {
                readRow(today)
            }
            if recoveryRow {
                TodayRowCard(icon: .heart, eyebrow: day.recovery.kicker, title: day.recovery.title, showsChevron: true) { showHealth = true }
                    .accessibilityHint(Text("Opens what changes in your body"))
            }
            if let challenge {
                if day.challengeDone {
                    TodayStep(node: .done) { TodayDoneRow(title: String(localized: challenge.title), detail: String(localized: "Done")) }
                } else {
                    challengeRow(challenge, day: day)
                }
            }
            if day.state == .prep && !day.night {
                TodayRowCard(icon: .note, title: logTitle(day.products.first ?? primaryProduct),
                             detail: String(localized: "Tonight · 1 min"), showsChevron: true) { log.open() }
                    .accessibilityIdentifier("home.log.use")
                TodayWaterRow(profile: profile, now: day.now)
                    .padding(.horizontal, 16)
            }
            if let time = day.checkedInAt {
                TodayStep(node: .done) { TodayDoneRow(title: String(localized: "Evening check-in"), detail: done(at: time)) }
            } else if day.focus != .checkIn {
                TodayRowCard(icon: .moon, title: String(localized: "Check-in with Glim"),
                             detail: checkInLine, showsChevron: true) { showCheckIn = true }
                    .accessibilityHint(Text("Opens the evening check-in"))
            }
            if day.focus != .windDown {
                TodayRowCard(icon: .leaf, title: String(localized: "Wind-down breath"),
                             detail: String(localized: "10 PM · 3 min"), showsChevron: true) { showCalmTools = true }
            }
        }
    }

    /// Today's read in the Later list (017): the title, "Today's read · 3 min".
    @ViewBuilder
    private func readRow(_ today: ProgramToday) -> some View {
        if case let .open(id, inProgress, needsUpgrade) = today.kind {
            TodayRowCard(icon: .note, title: today.title.isEmpty ? today.label : today.title,
                         detail: inProgress ? String(localized: "Continue · \(today.minutes) min")
                             : today.isCatchUp ? String(localized: "Catch up · \(today.minutes) min")
                             : String(localized: "Today's read · \(today.minutes) min"),
                         trailing: needsUpgrade ? String(localized: "Unlock") : nil, showsChevron: true) {
                if needsUpgrade { unlock(id, today.title) } else { openSession(id) }
            }
            .accessibilityIdentifier("today.lesson")
        } else {
            TodaySessionCard(today: today, style: .row, onOpen: openSession, onUnlock: unlock)
        }
    }

    /// "Opens 6 PM · nudge at 9 PM".
    private var checkInLine: String {
        let minute = UserDefaults.standard.object(forKey: DailyReminderSettings.checkInKey) as? Int ?? DailyReminderSettings.defaultCheckIn
        guard minute >= 0 else { return String(localized: "Opens 6 PM") }
        let date = Calendar.current.date(bySettingHour: minute / 60, minute: minute % 60, second: 0, of: .now) ?? .now
        return String(localized: "Opens 6 PM · nudge at \(date.formatted(date: .omitted, time: .shortened))")
    }

    /// "Log today's cigarettes".
    private func logTitle(_ product: Product) -> String {
        switch product {
        case .cigarettes: String(localized: "Log today's cigarettes")
        case .vape: String(localized: "Log today's vaping")
        case .pouches: String(localized: "Log today's pouches")
        }
    }

    /// "Done · 8:12".
    private func done(at time: Date) -> String {
        String(localized: "Done · \(time.formatted(date: .omitted, time: .shortened))")
    }

    private func challengeRow(_ challenge: PrepChallenge, day: TodayDay) -> some View {
        Button {
            challengeDoneOn = day.clock.day(containing: day.now).timeIntervalSince1970
            Analytics.track(.prepChallengeDone(day: day.snap.prepDayNumber))
        } label: {
            HStack(alignment: .top, spacing: 14) {
                DXIcon(.flame, size: 22).foregroundStyle(TodayInk.muted).padding(.top, 2)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Today's challenge · 1 min").dxType(.caption).foregroundStyle(TodayInk.muted)
                    Text(challenge.title).dxFace(.display, 16, weight: 700).foregroundStyle(TodayInk.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(challenge.detail).dxFace(.body, 13, weight: 500).foregroundStyle(TodayInk.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
            }
            .padding(.leading, 16).padding(.trailing, 14).padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.dxPress)
        .sensoryFeedback(DX.Haptic.commit, trigger: day.challengeDone)
        .accessibilityHint(Text("Marks it done"))
    }

    // MARK: Logging (S24, UX-05)

    /// Through the day: every product before Day Xero with batch buttons (puffs by five and ten, so a vape day isn't a
    /// hundred taps); after it, urges surfed; water always. Tapping a count opens the log for anything else.
    /// The day's log rows (kit 017): a 40 pt icon tile, the count and its line, small pill buttons on the right.
    private func logRows(_ day: TodayDay) -> some View {
        VStack(spacing: 0) {
            if day.state == .prep {
                ForEach(Array(day.products.enumerated()), id: \.element) { index, product in
                    if index > 0 { divider }
                    useRow(product, day: day)
                }
            } else {
                urgesRow(day)
            }
            divider
            TodayWaterRow(profile: profile, now: day.now)
        }
        .padding(.horizontal, 16).padding(.vertical, 4)
    }

    private var divider: some View {
        Rectangle().fill(TodayInk.line).frame(height: 1)
    }

    private func useRow(_ product: Product, day: TodayDay) -> some View {
        let count = useCount(product, now: day.now)
        let title: String = switch product {
        case .cigarettes: String(localized: "Cigarettes today")
        case .vape: String(localized: "Puffs today")
        case .pouches: String(localized: "Pouches today")
        }
        let unit: String = switch product {
        case .cigarettes: count == 1 ? String(localized: "cigarette") : String(localized: "cigarettes")
        case .vape: count == 1 ? String(localized: "puff") : String(localized: "puffs")
        case .pouches: count == 1 ? String(localized: "pouch") : String(localized: "pouches")
        }
        let batches = product == .vape ? [5, 10] : [1, 5]
        return HStack(spacing: 10) {
            LogIcon(glyph: .product(product))
            Button { log.open() } label: {
                countText(count, unit: unit)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Log, \(title): \(count)"))
            .accessibilityHint(Text("Opens the log"))
            ForEach(Array(batches.enumerated()), id: \.element) { index, batch in
                Button { logUse(product, count: batch) } label: {
                    Text(verbatim: "+\(batch)").frame(minWidth: 20)
                }
                .buttonStyle(.dx(index == 0 ? .small : .ghostSmall, on: .apricot))
                .frame(height: 44)
                .fixedSize()
                .accessibilityLabel(Text(batchLabel(product, count: batch)))
                .accessibilityIdentifier(index == 0 ? "home.log.\(product.rawValue)" : "home.log.\(product.rawValue).\(batch)")
            }
        }
        .frame(minHeight: 52)
    }

    /// Waves ridden today (017): the wave tile, "3 waves today", "Ridden out with SOS", Log a wave.
    private func urgesRow(_ day: TodayDay) -> some View {
        let ridden = logs.filter { $0.kind == .craving && $0.outcome == .passed }
        let today = day.clock.day(containing: day.now)
        let todayCount = ridden.filter { day.clock.day(containing: $0.timestamp) == today }.count
        return HStack(spacing: 12) {
            DXIcon(.wave, size: 22).foregroundStyle(Color(light: 0x3554B5, dark: 0x9DB4FF))
                .frame(width: 44, height: 44)
                .background(Color(light: 0xF1E8DA, dark: 0x26304C), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                countText(todayCount, unit: todayCount == 1 ? String(localized: "wave today") : String(localized: "waves today"))
                Text("Ridden out with SOS").dxType(.caption).foregroundStyle(TodayInk.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            Button { log.open() } label: { Text("Log a wave") }
                .buttonStyle(.dx(.ghostSmall, on: .apricot))
                .frame(height: 44)
                .fixedSize()
                .accessibilityLabel(Text("Log a craving or slip"))
                .accessibilityIdentifier("home.log.urge")
        }
        .frame(minHeight: 62)
    }

    /// "4 cigarettes": the number in the display face.
    private func countText(_ count: Int, unit: String) -> some View {
        let big = DX.Typeface4.scaledFont(19, weight: 800, style: .title2, dynamicTypeSize: typeSize)
        return Text("\(Text(verbatim: "\(count)").font(big).foregroundStyle(TodayInk.ink)) \(Text(verbatim: unit))")
            .dxFont(15, weight: 600, style: .subheadline)
            .foregroundStyle(TodayInk.ink)
            .contentTransition(.numericText())
            .lineLimit(1).minimumScaleFactor(0.75)
    }

    private func batchLabel(_ product: Product, count: Int) -> String {
        switch product {
        case .cigarettes: count == 1 ? String(localized: "Log a cigarette") : String(localized: "Log \(count) cigarettes")
        case .vape: String(localized: "Log \(count) puffs")
        case .pouches: count == 1 ? String(localized: "Log a pouch") : String(localized: "Log \(count) pouches")
        }
    }

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
            if let product {
                LogIcon(glyph: .product(product))
                    .environment(\.colorScheme, .dark)
            } else {
                DXIcon(.check, size: 13, weight: 2.6)
            }
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
        // v5 kit `.toast`: ink in light, cream in dark, radius 20.
        .dxFace(.body, 15, weight: 600)
        .foregroundStyle(Color(light: 0xFFF8EE, dark: 0x1E1A3A))
        .buttonStyle(.plain)
        .padding(.vertical, DX.Space.xs).padding(.leading, 12).padding(.trailing, 16)
        .frame(minHeight: 52)
        .background(Color(light: 0x1E1A3A, dark: 0xFFF8EE), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.25), radius: 15, y: 12)
        .padding(.horizontal, 16)
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

    fileprivate func useCount(_ product: Product, now: Date) -> Int {
        let today = clock.day(containing: now)
        return logs.filter { $0.product == product && $0.kind != .craving && clock.day(containing: $0.timestamp) == today }.count
    }

    // MARK: Program

    private func openSession(_ id: String) {
        session = SessionOpen(id: id)
    }

    private func unlock(_ id: String, _ title: String) {
        Paywalls.present(.unlockProgramDay, params: ["day": id]) { outcome in
            switch outcome {
            case .fallback:
                upgradeTitle = title
                showUpgrade = true
            case .unlocked: entitlement.grantFromElsewhere()
            case .closed: break
            }
        }
    }

    /// Prep 1 opens once, after "Start my prep week" queued it (S22, QW1).
    private func openQueuedFirstSession() {
        guard UserDefaults.standard.bool(forKey: FirstLesson.key) else { return }
        UserDefaults.standard.set(false, forKey: FirstLesson.key)
        let store = ProgramStore(context: context, profile: profile)
        guard case .open(let id, _, false)? = ProgramToday(store: store, isPro: entitlement.isPro)?.kind else { return }
        session = SessionOpen(id: id)
    }

    /// True until the first prep session has been played to its end.
    static func firstPrepWaiting(_ store: ProgramStore) -> Bool {
        guard let first = store.content?.sessions.first(where: { $0.phaseId == "prep" })?.id else { return false }
        return store.record(first)?.completedAt == nil
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

    // MARK: Shared values

    fileprivate var clock: DayClock { DayClock(boundaryHour: profile.dayBoundaryHour) }

    /// When the time free counts from: Day Xero's commit, or else the start of Quit Day.
    fileprivate var quitMoment: Date {
        if let held = profile.progress?.quitTimestamp { return held }
        let start = clock.startOfDate(profile.quitDay)
        return clock.calendar.date(byAdding: .hour, value: clock.boundaryHour, to: start) ?? start
    }

    fileprivate var primaryProduct: Product {
        profile.primaryProduct?.product ?? profile.products.first?.product ?? .cigarettes
    }

    /// The reason they gave in onboarding (UX-06): their first reason, in their own words.
    fileprivate var why: String? {
        let first = profile.reasons.sorted { $0.createdAt < $1.createdAt }.first?.text
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return first?.isEmpty == false ? first : nil
    }

    /// Screenshots can't choose the time of day, so DEBUG builds can force which card shows.
    fileprivate var debugDaily: String? {
        #if DEBUG
        UserDefaults.standard.string(forKey: "dx.forceDaily")
        #else
        nil
        #endif
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

// MARK: Today's numbers

/// Everything Today shows at one moment, worked out once per render from the same sources the rest of the app reads,
/// so the sky, the slim card, the focus card and the timeline can't disagree.
@MainActor
private struct TodayDay {
    struct Finished {
        let title: String
        let time: Date
    }

    struct Ahead {
        let text: String
        let isQuitDay: Bool
    }

    struct Stamps {
        let daysToQuit: Int
        let quitDate: String
        let done: Int
        let total: Int
        let current: Int?
    }

    let now: Date
    let clock: DayClock
    let snap: HomeSnapshot
    let state: TodayState
    let night: Bool
    let program: ProgramToday?
    let focus: TodayFocus
    let products: [Product]
    let pledgedAt: Date?
    let showsPledge: Bool
    let checkedInAt: Date?
    let sessionDone: Finished?
    /// The session waits on the timeline while another card has the focus.
    let sessionRow: Bool
    let challengeDone: Bool
    let recovery: RecoveryCopy
    let ahead: Ahead?
    let crewStage: Int
    let hero: TodayHeroModel
    /// The prep countdown (015).
    let stamps: Stamps?
    /// The last seven nights for the check-in (018).
    let nights: [TodayNightTicks.Night]

    init(view: TodayView, now: Date) {
        let profile = view.profile
        let clock = view.clock
        self.now = now
        self.clock = clock
        let snap = HomeSnapshot(profile: profile, isPro: view.entitlementIsPro, now: now, sessions: view.sessionRecordsValue)
        self.snap = snap
        let state = TodayState(snap: snap, quitTimestamp: profile.progress?.quitTimestamp)
        self.state = state
        night = TodayClock.isNight(at: now)
        crewStage = CrewGrowth.stage(daysClear: snap.daysClear)
        let today = clock.day(containing: now)

        // The program session (handoff 4.5): open, waiting or complete.
        let store = ProgramStore(context: view.contextValue, profile: profile)
        program = ProgramToday(store: store, isPro: view.entitlementIsPro, now: now)
        let sessionOpen: Bool = if case .open(_, _, false)? = program?.kind { true } else { false }

        // The pledge and the check-in (DailyRhythm).
        let rhythm = DailyRhythm(clock: clock)
        let force = view.debugDaily
        let pledge = view.pledgesValue.first { rhythm.hasPledged([$0.day], at: now) }
        pledgedAt = force == "pledged" ? now : pledge?.madeAt
        showsPledge = pledgedAt == nil && (force == "pledge" || rhythm.isPledgeTime(now))
        let checkIn = view.checkInsValue.first { rhythm.hasCheckedIn([$0.day], at: now) }
        checkedInAt = force == "checkedIn" ? now : checkIn?.madeAt
        let checkInDays = view.checkInsValue.map(\.day)
        nights = (0..<7).reversed().map { back in
            let date = clock.calendar.date(byAdding: .day, value: -back, to: now) ?? now
            return TodayNightTicks.Night(date: clock.day(containing: date),
                                         done: back == 0 ? false : rhythm.hasCheckedIn(checkInDays, at: date), isTonight: back == 0)
        }

        var focus = TodayFocus.pick(hour: TodayClock.hour(at: now), postQuit: state == .postQuit,
                                    checkedIn: checkedInAt != nil, sessionOpen: sessionOpen)
        // Until Prep 1 is done, "Prep 1 · N min · Start" holds the focus whatever the hour (S22, QW1): it's where the
        // program starts, and closing it once mustn't hide it behind the evening check-in.
        if state == .prep, sessionOpen, TodayView.firstPrepWaiting(store) { focus = .lesson }
        self.focus = focus

        // A session finished today, shown as done in the morning.
        let finishedToday = view.sessionRecordsValue
            .filter { record in record.completedAt.map { clock.day(containing: $0) == today } ?? false }
            .max { ($0.completedAt ?? .distantPast) < ($1.completedAt ?? .distantPast) }
        if let finishedToday, let time = finishedToday.completedAt, let content = store.content?.session(finishedToday.sessionId) {
            let title = content.title.resolve(store.variant) ?? ""
            sessionDone = Finished(title: title.isEmpty ? content.label : "\(content.label) · \(title)", time: time)
        } else {
            sessionDone = nil
        }
        let programIsOpen: Bool = if case .open? = program?.kind { true } else { false }
        sessionRow = focus != .lesson && programIsOpen

        challengeDone = view.challengeDoneOnValue == today.timeIntervalSince1970

        let primary = view.primaryProduct
        products = [primary] + profile.products.map(\.product).filter { $0 != primary }
            .sorted { Product.allCases.firstIndex(of: $0)! < Product.allCases.firstIndex(of: $1)! }

        // The body (HealthTimeline): the recovery card's wording and the ring's next change.
        let items = HealthTimeline.bundled?.items(for: primary) ?? []
        let elapsed = HealthTimeline.elapsedHours(quitDay: profile.quitDay, now: now, clock: clock)
        recovery = RecoveryCopy.make(items, elapsedHours: elapsed)
        let nextChange = items.filter { !$0.isFelt && HealthTimeline.state(of: $0, elapsedHours: elapsed) == .ahead }
            .min { $0.fromHours < $1.fromHours }

        let money = Decimal(floor(NSDecimalNumber(decimal: snap.moneyKept).doubleValue))
            .formatted(.currency(code: snap.currencyCode).precision(.fractionLength(0)))
        let quitStart = clock.startOfDate(profile.quitDay)
        let daysToQuit = max(clock.days(from: now, toDate: profile.quitDay), 0)

        // What's ahead at the end of the timeline: Quit Day during prep, then the next milestone (Milestones).
        func dayName(_ date: Date) -> String {
            let gap = clock.calendar.dateComponents([.day], from: today, to: date).day ?? 0
            return gap <= 6 ? date.formatted(.dateTime.weekday(.wide)) : date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
        }
        if state == .prep {
            ahead = daysToQuit > 0 ? Ahead(text: String(localized: "\(dayName(quitStart)) · Quit Day"), isQuitDay: true) : nil
        } else if let next = snap.nextMilestone,
                  let date = clock.calendar.date(byAdding: .day, value: next == 1 ? 1 : next - 1, to: quitStart) {
            let label = next == 1 ? String(localized: "1 day free") : String(localized: "\(next) days free")
            ahead = Ahead(text: "\(dayName(date)) · \(label)", isQuitDay: false)
        } else {
            ahead = nil
        }

        // The scene and the slim header.
        let slips = view.logsValue.filter { $0.kind == .slip }.map(\.timestamp)
        let initial = profile.name.trimmingCharacters(in: .whitespacesAndNewlines).first.map { String($0).uppercased() }
        let greeting = TodayClock.greeting(at: now, name: profile.name)
        let quitDate = profile.quitDay.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
        let todayDate = now.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
        let avoided = snap.counters.first { $0.product == primary } ?? snap.counters.first
        let avoidedUnit: String = switch avoided?.product ?? primary {
        case .cigarettes: (avoided?.avoided ?? 0) == 1 ? String(localized: "cigarette not smoked") : String(localized: "cigarettes not smoked")
        case .vape: (avoided?.avoided ?? 0) == 1 ? String(localized: "puff not taken") : String(localized: "puffs not taken")
        case .pouches: (avoided?.avoided ?? 0) == 1 ? String(localized: "pouch not used") : String(localized: "pouches not used")
        }
        switch state {
        case .prep:
            let countdown: String = switch daysToQuit {
            case 0: String(localized: "Quit Day is today")
            case 1: String(localized: "1 day to Quit Day")
            default: String(localized: "\(daysToQuit) days to Quit Day")
            }
            let done = snap.prepDone, total = max(snap.prepTotal, 1)
            let label = program.map { if case .open = $0.kind { $0.label } else { "" } } ?? ""
            stamps = Stamps(daysToQuit: daysToQuit, quitDate: quitDate, done: done, total: total,
                            current: sessionOpen && done < total ? done + 1 : nil)
            let theme: String? = if case .open? = program?.kind, let line = program?.subtitle, !line.isEmpty { line } else { nil }
            hero = TodayHeroModel(
                night: night, mode: .prep, greeting: greeting,
                line: night ? String(localized: "\(countdown) · \(quitDate)") : theme.map { String(localized: "Today: \($0).") } ?? (daysToQuit == 0 ? countdown : "\(countdown) · \(quitDate)"),
                why: view.why, profileInitial: initial,
                pill: label.isEmpty ? todayDate : "\(todayDate) · \(label)",
                titleLead: "", titleWord: "", moneyKept: 0, currencyCode: snap.currencyCode, avoided: 0, avoidedUnit: "",
                nextMilestone: nil, nextFraction: 0, aheadText: nil,
                slimTitle: countdown,
                slimLine: daysToQuit == 0 ? String(localized: "Prep \(done) of \(total) done")
                    : String(localized: "\(quitDate) · Prep \(done) of \(total) done"),
                crewStage: crewStage,
                accessibilityLabel: String(localized: "Prep: \(done) of \(total) sessions done"))
        case .postQuit:
            stamps = nil
            let timeFree = TimeFree.short(now.timeIntervalSince(view.quitMoment))
            let resilience = Resilience.days(quitDay: profile.quitDay, slips: slips, now: now, clock: clock)
            let free: String = switch primary {
            case .cigarettes: String(localized: "\(resilience.clear) of \(resilience.total) days smoke-free")
            case .vape: String(localized: "\(resilience.clear) of \(resilience.total) days vape-free")
            case .pouches: String(localized: "\(resilience.clear) of \(resilience.total) days pouch-free")
            }
            let next: String? = nextChange.map {
                String(localized: "Next: \($0.title) · \(TodayView.relative(hours: $0.fromHours - elapsed))")
            }
            let earned = Milestones.days.last { $0 <= snap.daysClear }
            // The day a badge lands, the title is the badge (016); otherwise the time free.
            let fresh = earned.map { snap.daysClear - $0 <= 1 } ?? false
            let waves = view.logsValue.filter { $0.kind == .craving && $0.outcome == .passed && clock.day(containing: $0.timestamp) == today }.count
            hero = TodayHeroModel(
                night: night, mode: .postQuit(earned: earned), greeting: greeting,
                line: waves == 1 ? String(localized: "1 wave ridden today") : String(localized: "\(waves) waves ridden today"),
                why: view.why, profileInitial: initial,
                pill: todayDate,
                titleLead: fresh ? String(localized: "\(earned ?? 0)-day badge") : timeFree,
                titleWord: fresh ? String(localized: "earned") : String(localized: "free"),
                moneyKept: NSDecimalNumber(decimal: snap.moneyKept).doubleValue, currencyCode: snap.currencyCode,
                avoided: avoided?.avoided ?? 0, avoidedUnit: avoidedUnit,
                nextMilestone: snap.nextMilestone,
                nextFraction: snap.nextMilestone.map { Double(snap.daysClear) / Double(max($0, 1)) } ?? 1,
                aheadText: snap.nextMilestone.map { next in
                    let left = max(next - snap.daysClear, 1)
                    return left == 1 ? String(localized: "1 day to your \(next)-day badge")
                        : String(localized: "\(left) days to your \(next)-day badge")
                },
                slimTitle: snap.daysClear == 1 ? String(localized: "1 day free") : String(localized: "\(snap.daysClear) days free"),
                slimLine: todayDate,
                slimMoney: money,
                crewStage: crewStage,
                accessibilityLabel: [String(localized: "\(timeFree) free."), next].compactMap { $0 }.joined(separator: " "))
        }
    }
}

// The values `TodayDay` reads from the view, under names that say they're snapshots.
private extension TodayView {
    var entitlementIsPro: Bool { entitlement.isPro }
    var contextValue: ModelContext { context }
    var sessionRecordsValue: [SessionRecord] { sessionRecords }
    var pledgesValue: [Pledge] { pledges }
    var checkInsValue: [CheckIn] { checkIns }
    var logsValue: [LogEntry] { logs }
    var challengeDoneOnValue: Double { challengeDoneOn }
}

/// Water on the timeline: "3 of 9 glasses" and +1 glass, which logs the usual drink (S27.12). UI tests read
/// "Water · 3 of 8 glasses" from the count.
private struct TodayWaterRow: View {
    let profile: UserProfile
    let now: Date

    @Environment(\.modelContext) private var context
    @Environment(\.dynamicTypeSize) private var typeSize
    @Query(sort: \WaterEntry.timestamp) private var entries: [WaterEntry]
    @Query private var waterProfiles: [WaterProfile]
    @State private var logged = 0

    var body: some View {
        let clock = DayClock(boundaryHour: profile.dayBoundaryHour)
        let todays = WaterDay.entries(entries, on: clock.day(containing: now), clock: clock)
        let total = todays.reduce(0) { $0 + $1.countedMl }
        let goal = waterProfiles.first?.effectiveGoalMl ?? WaterGoal.skippedMl
        let drink = waterProfiles.first?.selectedDrink ?? .glass
        let glasses = WaterFormat.glasses(total)
        let goalGlasses = max(goal / WaterGoal.glassMl, 1)
        let units = waterProfiles.first?.units ?? WaterUnits.default()
        let big = DX.Typeface4.scaledFont(19, weight: 800, style: .title2, dynamicTypeSize: typeSize)
        HStack(spacing: 12) {
            WaterGlassTile(fill: Double(glasses) / Double(goalGlasses))
            VStack(alignment: .leading, spacing: 0) {
                Text("\(Text(verbatim: "\(glasses)").font(big).foregroundStyle(TodayInk.ink)) of \(goalGlasses)")
                    .dxFont(15, weight: 600, style: .subheadline)
                    .foregroundStyle(TodayInk.ink)
                    .contentTransition(.numericText())
                    .lineLimit(1).minimumScaleFactor(0.75)
                    .accessibilityLabel(Text("Water · \(glasses) of \(goalGlasses) glasses"))
                    .accessibilityIdentifier("today.water.count")
                Text("Glasses of water")
                    .dxType(.caption).foregroundStyle(TodayInk.muted)
                    .lineLimit(1).minimumScaleFactor(0.8)
                    .accessibilityLabel(Text("Daily goal \(WaterFormat.amount(goal, units: units)) \(WaterFormat.unit(units))"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                WaterLog.log(drink, source: .app, in: context)
                logged += 1
                Analytics.track(.waterLogged(source: WaterSource.app.rawValue, drink: drink.rawValue))
            } label: {
                HStack(spacing: 6) {
                    DXIcon(.plus, size: 15, weight: 2.6)
                    Text("1 glass")
                }
            }
            .buttonStyle(.dx(.ghostSmall, on: .apricot))
            .frame(height: 44)
            .fixedSize()
            // "Add", not "Log": UI tests find the use log by a button containing "Log".
            .accessibilityLabel(Text("Add \(Text(drink.name))"))
            .accessibilityIdentifier("today.water.add")
        }
        .frame(minHeight: 62)
        .sensoryFeedback(.impact(weight: .medium), trigger: logged)
    }
}

/// The drawn glass on the water row (017): its water rises to the day's share of the goal.
private struct WaterGlassTile: View {
    let fill: Double
    private let motion = MotionPolicy()

    var body: some View {
        Canvas { ctx, size in
            ctx.scaleBy(x: size.width / 44, y: size.height / 44)
            let glass = SVGPath.path("M14 11h16l-2 22a2 2 0 01-2 1.8h-8A2 2 0 0116 33z")
            let level = 33 - 20 * min(max(fill, 0), 1)
            var inner = ctx
            inner.clip(to: glass)
            inner.fill(Path(CGRect(x: 0, y: level, width: 44, height: 44)), with: .color(Color(hex: 0x7FB6F2)))
            ctx.stroke(glass, with: .color(Color(hex: 0x3554B5)), style: StrokeStyle(lineWidth: 2, lineJoin: .round))
        }
        .frame(width: 44, height: 44)
        .background(Color(light: 0xF1E8DA, dark: 0x26304C), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .animation(motion.animation(DX.Move.settle), value: fill)
        .accessibilityHidden(true)
    }
}
