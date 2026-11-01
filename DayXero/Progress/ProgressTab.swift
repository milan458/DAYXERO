import DayXeroCore
import SwiftData
import SwiftUI

/// The Progress tab (S7.3, S7.4): what you've gained, then your patterns once there's a week of logs.
struct ProgressTab: View {
    let profile: UserProfile
    @Environment(Entitlement.self) private var entitlement
    @Environment(LogRouter.self) private var log
    @Environment(\.modelContext) private var context
    @Environment(\.dynamicTypeSize) private var typeSize
    @Query(sort: \LogEntry.timestamp, order: .reverse) private var entries: [LogEntry]
    @Query private var checkIns: [CheckIn]
    @State private var series = Insights.Series.cravings
    @State private var editing: LogEntry?
    @State private var showHealth = UserDefaults.standard.bool(forKey: "dx.openHealth")
    @State private var milestoneOpen: Milestone?
    @State private var sharing = UserDefaults.standard.bool(forKey: "dx.shareCard")
    /// S27.11: Progress is the fourth tab and the way into Settings (Export, Delete, Privacy).
    @State private var showSettings = false

    var body: some View {
        TimelineView(.everyMinute) { timeline in
            let now = timeline.date
            let snap = HomeSnapshot(profile: profile, isPro: entitlement.isPro, now: now)
            let insights = Insights(points: entries.map(Insights.Point.init), now: now)
            // Half-open iPhone Duo: what you've gained on one side of the fold, the details on the other (S18.14).
            FoldAware {
                column { gained(snap, insights: insights) }
            } secondary: {
                column { details(insights, now: now) }
            } flat: {
                column {
                    gained(snap, insights: insights)
                    details(insights, now: now)
                }
            }
        }
        .fullScreenCover(item: $milestoneOpen) { milestone in
            MilestoneMoment(milestone: milestone, stats: MilestoneStats(profile: profile, logs: entries)) { milestoneOpen = nil }
        }
        .sheet(isPresented: $sharing) {
            ShareCardMaker(milestone: nil, stats: MilestoneStats(profile: profile, logs: entries)).presentationDetents([.large])
        }
        .sheet(isPresented: $showHealth) {
            HealthTimelineView(profile: profile, onClose: { showHealth = false })
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet(profile: profile)
        }
        .sheet(item: $editing) { entry in
            Group {
                if entry.kind == .slip {
                    SlipFlow(entry: entry, profile: profile, startInTalkThrough: true) { editing = nil }
                } else {
                    CravingLogForm(profile: profile, editing: entry, onSaved: { editing = nil })
                }
            }
            .presentationDetents([.large])
        }
    }

    // MARK: Layout

    private func column<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        // Built here: ScrollViewReader's closure escapes, and `content` doesn't.
        let built = content()
        return ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 10) { built }
                    .padding(.horizontal, DX.Layout.gutter)
                    .dxReadableColumn()
                    .padding(.top, DX.Space.s)
                    .padding(.bottom, DX.Space.l)
            }
            #if DEBUG
            // App Store screenshots open on the patterns (`-dx.progressScroll patterns`).
            .onAppear {
                if UserDefaults.standard.string(forKey: "dx.progressScroll") == "patterns" { proxy.scrollTo("patterns", anchor: .top) }
            }
            #endif
        }
    }

    @ViewBuilder
    private func gained(_ snap: HomeSnapshot, insights: Insights) -> some View {
        header(snap)
        skyStrip(snap)
        tiles(snap, insights: insights)
        moneyLine(snap)
        if !isPrepPhase(snap) {
            MilestonesRow(daysClear: snap.daysClear) { milestoneOpen = $0 }
        }
    }

    @ViewBuilder
    private func details(_ insights: Insights, now: Date) -> some View {
        // What's changing in the body, from Quit Day (S10).
        whatsChanging(now: now)
        // The full step plan for each NRT product (S9.5).
        ForEach(profile.nrtPlans.sorted { $0.createdAt < $1.createdAt }) { plan in
            NRTCard(plan: plan, clock: DayClock(boundaryHour: profile.dayBoundaryHour), now: now, showAllSteps: true)
        }
        // Your patterns (decision 31): its own sky panel (mist retired in S27.13) with Glim, the heat map and the triggers.
        VStack(alignment: .leading, spacing: 12) {
            patternsHeader(insights)
            if insights.isReady {
                heatCard(insights)
                triggersCard(insights)
            } else {
                earlyPatterns(insights)
            }
        }
        .padding(DX.Space.m)
        .background(DX.Ground.sky.background, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .padding(.top, DX.Space.m)
        .id("patterns")
        if insights.isReady {
            trendCard(insights)
            recentLogs
        }
    }

    private static let patternCard = Color(light: 0xFFF8EE, dark: 0x14265E)

    private func patternsHeader(_ insights: Insights) -> some View {
        HStack(alignment: .bottom, spacing: DX.Space.xs) {
            VStack(alignment: .leading, spacing: 4) {
                Text(insights.isReady ? LocalizedStringKey("Last 4 weeks") : LocalizedStringKey("From your logs")).dxType(.footnote).foregroundStyle(DX.Ground.sky.muted)
                Text("Your patterns")
                    .dxType(.title).foregroundStyle(DX.Ground.sky.ink)
                    .accessibilityAddTraits(.isHeader)
            }
            .padding(.bottom, 8)
            Spacer(minLength: 0)
            // S27.15: Glim instead of the stock-style person.
            GlimView(mood: .calm, stage: 1, points: 88)
                .accessibilityHidden(true)
        }
    }

    /// A cream card inside the sky panel.
    private func patternPanel<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Self.patternCard, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    // MARK: What you've gained (S7.4)

    /// F12: "Since Quit Day · Fri 6 Nov" / "Your progress", with Log beside it.
    private func header(_ snap: HomeSnapshot) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(eyebrow(snap)).dxType(.caption).textCase(.uppercase).foregroundStyle(Read4.muted)
                // S27.15: plain title; the hand-drawn mark is kept for moments.
                Text("Your progress")
                    .dxType(.large).foregroundStyle(Read4.ink)
                    .accessibilityAddTraits(.isHeader)
            }
            Spacer()
            LogButton { log.open() }
            Button { showSettings = true } label: {
                Image(systemName: "gearshape").font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Read4.ink)
                    .frame(width: 44, height: 44)
                    .background(Read4.card, in: Circle())
                    .overlay(Circle().strokeBorder(Read4.hairline))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Settings"))
            .accessibilityIdentifier("progress.settings")
        }
        .padding(.top, DX.Space.m)
    }

    private func eyebrow(_ snap: HomeSnapshot) -> String {
        if case let .prep(days) = snap.phase {
            return String(localized: "Quit Day in \(days) days")
        }
        return String(localized: "Since Quit Day · \(profile.quitDay.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))")
    }

    /// The path at the sky's clarity, with "Sky 28% clear · clears a little each day".
    private func skyStrip(_ snap: HomeSnapshot) -> some View {
        let prep = isPrepPhase(snap)
        let clarity = prep ? CrewGrowth.prepClarity : CrewGrowth.clarity(daysClear: snap.daysClear)
        return HorizonScene(.path, clarity: clarity, fit: .bottom)
            .frame(height: 130)
            .clipShape(RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous))
            .overlay(alignment: .bottomLeading) {
                Text(prep ? "Sky \(clarity)% clear · clears from Quit Day" : "Sky \(clarity)% clear · clears a little each day")
                    .dxType(.caption)
                    .foregroundStyle(DX.Fill.navy)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(DX.Fill.cream.opacity(0.92), in: Capsule())
                    .padding(12)
            }
            .accessibilityElement(children: .combine)
    }

    /// A 2×2 grid that counts up: days clear, waves ridden out, not used, kept. In prep: prep done, waves, yearly, Quit Day.
    @ViewBuilder
    private func tiles(_ snap: HomeSnapshot, insights: Insights) -> some View {
        let columns = typeSize.isAccessibilitySize
            ? [GridItem(.flexible())]
            : [GridItem(.flexible(), spacing: 8), GridItem(.flexible())]
        let ridden = entries.filter { $0.kind == .craving && $0.outcome == .passed }.count
        let code = snap.currencyCode
        let whole: (Double) -> String = { Decimal($0).formatted(.currency(code: code).precision(.fractionLength(0))) }
        let cents: (Double) -> String = { Decimal($0).formatted(.currency(code: code).precision(.fractionLength(2))) }
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            if isPrepPhase(snap) {
                ProgressStat(value: Double(snap.prepDone), label: String(localized: "of \(snap.prepTotal) prep days done"))
                // "0 waves ridden out" reads as failure in a week where nobody is meant to resist yet (S27.5).
                if ridden > 0 {
                    ProgressStat(value: Double(ridden), label: ridden == 1 ? String(localized: "wave ridden out") : String(localized: "waves ridden out"))
                }
                ProgressStat(value: NSDecimalNumber(decimal: snap.moneyPerYear).doubleValue, label: String(localized: "to keep a year"), format: whole)
                // The same countdown as Today's header, from the chosen Quit Day (S27.5).
                let daysToQuit = Self.daysToQuit(snap)
                ProgressStat(value: Double(daysToQuit), label: daysToQuit == 1 ? String(localized: "day to Quit Day") : String(localized: "days to Quit Day"))
            } else {
                ProgressStat(value: Double(snap.daysClear), label: snap.daysClear == 1 ? String(localized: "day since Quit Day") : String(localized: "days since Quit Day"))
                ProgressStat(value: Double(ridden), label: ridden == 1 ? String(localized: "wave ridden out") : String(localized: "waves ridden out"))
                ForEach(snap.counters) { counter in
                    ProgressStat(value: Double(counter.avoided), label: String(localized: avoidedLabel(counter.product, count: counter.avoided)))
                }
                ProgressStat(value: NSDecimalNumber(decimal: snap.moneyKept).doubleValue, label: String(localized: "kept"), format: cents)
            }
        }
    }

    /// "$7 a day, about $2,555 a year. 2 evening check-ins with Glim."
    private func moneyLine(_ snap: HomeSnapshot) -> some View {
        let code = snap.currencyCode
        let perDay = (snap.moneyPerYear / 365).formatted(.currency(code: code).precision(.fractionLength(0)))
        let perYear = snap.moneyPerYear.formatted(.currency(code: code).precision(.fractionLength(0)))
        let checkInLine = checkIns.isEmpty ? "" : " " + (checkIns.count == 1 ? String(localized: "1 evening check-in with Glim.")
                                                         : String(localized: "\(checkIns.count) evening check-ins with Glim."))
        return Text(verbatim: String(localized: "\(perDay) a day, about \(perYear) a year.") + checkInLine)
            .dxType(.footnote)
            .foregroundStyle(Read4.muted)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// WHAT'S CHANGING: the change under way and the next one, each with its source; the whole timeline one tap away.
    @ViewBuilder
    private func whatsChanging(now: Date) -> some View {
        let product = profile.primaryProduct?.product ?? .cigarettes
        let timeline = HealthTimeline.bundled
        let items = timeline?.items(for: product) ?? []
        let elapsed = HealthTimeline.elapsedHours(quitDay: profile.quitDay, now: now, clock: DayClock(boundaryHour: profile.dayBoundaryHour))
        let (current, next) = HealthTimeline.nowAndNext(items, elapsedHours: elapsed)
        Text("What's changing").dxType(.caption).textCase(.uppercase).foregroundStyle(Read4.muted)
            .padding(.top, DX.Space.m)
            .accessibilityAddTraits(.isHeader)
        if let current {
            HealthFactCard(status: String(localized: "Happening now"), when: current.when, title: current.title, line: current.line,
                           sourceLabel: timeline?.source(current.source)?.label ?? "")
        }
        if let next {
            HealthFactCard(status: elapsed < 0 ? String(localized: "Starting on Quit Day") : String(localized: "Next"),
                           when: next.when, title: next.title, line: current == nil ? next.line : "",
                           sourceLabel: timeline?.source(next.source)?.label ?? "")
        }
        Button { showHealth = true } label: {
            Label("See the whole timeline", systemImage: "chevron.right")
                .labelStyle(TrailingIcon())
                .dxFont(14, weight: 700, style: .footnote)
                .foregroundStyle(Read4.ink)
                .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
    }

    private static func daysToQuit(_ snap: HomeSnapshot) -> Int {
        if case let .prep(days) = snap.phase { return days }
        return 0
    }

    private func isPrepPhase(_ snap: HomeSnapshot) -> Bool {
        if case .prep = snap.phase { return true }
        return false
    }

    private func avoidedLabel(_ product: Product, count: Int) -> String.LocalizationValue {
        switch product {
        case .cigarettes: count == 1 ? "cigarette not smoked" : "cigarettes not smoked"
        case .vape: count == 1 ? "puff not taken" : "puffs not taken"
        case .pouches: count == 1 ? "pouch not used" : "pouches not used"
        }
    }

    // MARK: Patterns (S7.3)

    private func heatCard(_ insights: Insights) -> some View {
        let grid = insights.heatMap(series)
        let peaks = insights.peaks(series)
        return patternPanel {
            VStack(alignment: .leading, spacing: DX.Space.s) {
                HStack(alignment: .top) {
                    Text(series == .cravings ? LocalizedStringKey("When cravings hit") : LocalizedStringKey("When you used")).dxType(.headline).foregroundStyle(Read4.ink)
                    Spacer()
                    SeriesToggle(selection: $series)
                }
                if let summary = summary(peaks) {
                    Text(summary).v4Text(.subtitle)
                }
                // Uses and slips in amber, so they read differently from cravings (S8.4).
                HeatMap(grid: grid, scale: series == .cravings ? HeatMap.cravingScale : HeatMap.useScale)
            }
        }
    }

    private func summary(_ peaks: [Insights.Peak]) -> AttributedString? {
        if series == .uses, let first = peaks.first {
            var text = AttributedString(peakName(first))
            text.font = DX.Typeface4.swiftUIFont(.body, size: 14, weight: 600)
            text.foregroundColor = Read4.ink
            return text + AttributedString(String(localized: " are when you've used most."))
        }
        guard let first = peaks.first else { return nil }
        var text = AttributedString(peakName(first))
        text.font = DX.Typeface4.swiftUIFont(.body, size: 14, weight: 600)
        text.foregroundColor = Read4.ink
        if peaks.count > 1 {
            var second = AttributedString(peakName(peaks[1]).lowercased())
            second.font = text.font
            second.foregroundColor = Read4.ink
            text += AttributedString(String(localized: " are your toughest time, then ")) + second + AttributedString(".")
        } else {
            text += AttributedString(String(localized: " are your toughest time."))
        }
        return text
    }

    private func peakName(_ peak: Insights.Peak) -> String {
        switch (peak.weekend, peak.time) {
        case (false, .morning): String(localized: "Weekday mornings")
        case (false, .midday): String(localized: "Weekday middays")
        case (false, .afternoon): String(localized: "Weekday afternoons")
        case (false, .evening): String(localized: "Weekday evenings")
        case (false, .lateNight): String(localized: "Weekday late nights")
        case (true, .morning): String(localized: "Weekend mornings")
        case (true, .midday): String(localized: "Weekend middays")
        case (true, .afternoon): String(localized: "Weekend afternoons")
        case (true, .evening): String(localized: "Weekend evenings")
        case (true, .lateNight): String(localized: "Weekend late nights")
        }
    }

    private func triggersCard(_ insights: Insights) -> some View {
        let top = insights.topTriggers
        let most = max(top.first?.count ?? 1, 1)
        return patternPanel {
            VStack(alignment: .leading, spacing: DX.Space.xs) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Top triggers").dxType(.headline).foregroundStyle(Read4.ink)
                    Spacer()
                    Text("\(insights.taggedCount) logged").v4Text(.micro)
                }
                if top.isEmpty {
                    Text("Tag what set a craving off, in SOS or a craving log, and your top triggers show here.").v4Text(.subtitle)
                }
                ForEach(top, id: \.trigger) { item in
                    HStack(spacing: DX.Space.xs) {
                        Text(item.trigger.title).dxFont(14, weight: 400, style: .footnote).foregroundStyle(Read4.ink)
                            .frame(width: typeSize.isAccessibilitySize ? nil : 96, alignment: .leading)
                        CoralBar(value: Double(item.count) / Double(most))
                        Text(verbatim: item.count.formatted()).dxFont(16, weight: 700, style: .body).foregroundStyle(Read4.ink)
                            .monospacedDigit().frame(minWidth: 24, alignment: .trailing)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    private func trendCard(_ insights: Insights) -> some View {
        let weeks = insights.weeks()
        let most = max(weeks.map(\.cravings).max() ?? 1, 1)
        let current = weeks.last
        return V4Card(padding: 14) {
            VStack(alignment: .leading, spacing: DX.Space.s) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Cravings by week").v4Text(.cardHeading)
                    Spacer()
                    if let change = insights.weekOnWeekChange { Text(changeLabel(change)).v4Text(.micro) }
                }
                HStack(alignment: .bottom, spacing: DX.Space.s) {
                    ForEach(Array(weeks.enumerated()), id: \.offset) { index, week in
                        VStack(spacing: 4) {
                            Text(verbatim: week.cravings.formatted()).dxFont(12, weight: 600, style: .caption1)
                                .foregroundStyle(Read4.ink)
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(week.isCurrent ? Read4.accent : Read4.track)
                                .frame(height: max(4, 72 * CGFloat(week.cravings) / CGFloat(most)))
                            Text(weekLabel(week, back: weeks.count - 1 - index))
                                .dxFont(12, weight: 400, style: .caption2)
                                .foregroundStyle(Read4.muted)
                                .lineLimit(1).minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity)
                        .accessibilityElement(children: .combine)
                    }
                }
                .frame(height: 112, alignment: .bottom)
                if let current, current.cravings > 0 {
                    Text("You rode out \(current.riddenOut) of \(current.cravings) cravings this week.").v4Text(.subtitle)
                }
            }
        }
    }

    private func changeLabel(_ change: Double) -> String {
        let percent = Int((abs(change) * 100).rounded())
        if percent == 0 { return String(localized: "Same as last week") }
        return change < 0 ? String(localized: "Down \(percent)%") : String(localized: "Up \(percent)%")
    }

    private func weekLabel(_ week: Insights.Week, back: Int) -> String {
        switch back {
        case 0: String(localized: "This week")
        case 1: String(localized: "Last week")
        default: week.start.formatted(.dateTime.day().month(.abbreviated))
        }
    }

    @ViewBuilder
    private var recentLogs: some View {
        Text("Recent logs").v4Text(.micro).padding(.top, DX.Space.s)
        ForEach(entries.prefix(8)) { entry in
            Button { editing = entry } label: { LogEntryRow(entry: entry) }
                .buttonStyle(.plain)
                .contextMenu {
                    Button("Delete", systemImage: "trash", role: .destructive) { delete(entry) }
                }
                .accessibilityAction(named: Text("Delete")) { delete(entry) }
                .accessibilityHint(Text("Add details"))
        }
    }

    private func delete(_ entry: LogEntry) {
        context.delete(entry)
        try? context.save()
    }

    /// Before there's a week of logs (S18.7): from the first log, when they happen so far; before any, one line
    /// over the blurred map. Either way, what the person told us in setup.
    private func earlyPatterns(_ insights: Insights) -> some View {
        patternPanel {
            VStack(alignment: .leading, spacing: DX.Space.s) {
                if insights.points.isEmpty {
                    ZStack {
                        HeatMap(grid: Self.sampleGrid)
                            .blur(radius: 4)
                            .opacity(0.4)
                            .accessibilityHidden(true)
                        Text("Your first log starts the map")
                            .dxFont(14, weight: 600, style: .footnote)
                            .foregroundStyle(Read4.ink)
                            .padding(.vertical, 8).padding(.horizontal, 14)
                            .background(Read4.surface, in: Capsule())
                    }
                } else {
                    let counts = insights.timeOfDayCounts
                    let most = max(counts.map(\.count).max() ?? 1, 1)
                    Text("When you've logged so far").v4Text(.cardHeading)
                    ForEach(counts, id: \.time) { item in
                        HStack(spacing: DX.Space.xs) {
                            Text(item.time.title).dxFont(14, weight: 400, style: .footnote).foregroundStyle(Read4.ink)
                                .frame(width: typeSize.isAccessibilitySize ? nil : 84, alignment: .leading)
                            V4ProgressBar(value: Double(item.count) / Double(most))
                            Text(verbatim: item.count.formatted()).dxFont(14, weight: 400, style: .footnote).foregroundStyle(Read4.muted)
                                .monospacedDigit().frame(minWidth: 22, alignment: .trailing)
                        }
                        .accessibilityElement(children: .combine)
                    }
                    V4ProgressBar(value: insights.readiness).accessibilityLabel(Text("Patterns ready"))
                    Text(readyLine(insights)).dxType(.headline).foregroundStyle(Read4.ink)
                }
                if let setup = fromSetup {
                    Text(setup).v4Text(.subtitle)
                }
            }
        }
    }

    private func readyLine(_ insights: Insights) -> String {
        let days = insights.daysUntilReady
        if days == 1 { return String(localized: "Full patterns tomorrow") }
        if days > 1 { return String(localized: "Full patterns in \(days) days") }
        let logs = insights.logsUntilReady
        return logs == 1 ? String(localized: "Full patterns after 1 more log") : String(localized: "Full patterns after \(logs) more logs")
    }

    /// The triggers and craving times from onboarding, e.g. "You said: Coffee · Stress · mornings".
    private var fromSetup: String? {
        let triggers = profile.triggers.prefix(3).map { String(localized: $0.title) }
        let times = profile.cravingTimesRaw.compactMap(TimeOfDay.init(rawValue:)).map { String(localized: $0.title).lowercased() }
        let all = triggers + times
        guard !all.isEmpty else { return nil }
        return String(localized: "You said: \(all.joined(separator: " · "))")
    }

    /// A made-up shape for the blurred placeholder only; never shown as data.
    private static let sampleGrid = [[3, 4, 3, 4, 3, 1, 1], [1, 2, 1, 1, 2, 2, 1], [2, 3, 2, 2, 1, 1, 0], [1, 1, 2, 1, 3, 4, 3], [0, 0, 1, 0, 1, 2, 1]]
}

struct LogButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Log", systemImage: "plus")
                .dxFont(14, weight: 600, style: .footnote)
                .foregroundStyle(Read4.ink)
                .padding(.horizontal, 14)
                .frame(minHeight: 36)
                .background(Read4.card, in: Capsule())
                .overlay(Capsule().strokeBorder(Read4.hairline))
        }
        .buttonStyle(.plain)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}

/// A value and what it is, in one sentence-case line (S18.10).
/// A counting stat on the reading ground (F12): 24 pt number, 12 pt label, raised card.
private struct ProgressStat: View {
    let value: Double
    let label: String
    var format: (Double) -> String = { String(Int($0.rounded(.down))) }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            CountingText(value, format: format)
                .dxType(.title)
                .foregroundStyle(Read4.ink)
                .lineLimit(1).minimumScaleFactor(0.6)
            Text(verbatim: label).dxType(.caption).foregroundStyle(Read4.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .topLeading)
        .v4Card(padding: 14)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "\(format(value)) \(label)"))
    }
}

/// Title first, then the icon.
private struct TrailingIcon: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) { configuration.title; configuration.icon.font(.system(size: 12, weight: .bold)) }
    }
}

private struct SeriesToggle: View {
    @Binding var selection: Insights.Series

    var body: some View {
        HStack(spacing: 0) {
            option(.cravings, "Cravings")
            option(.uses, "Uses")
        }
        .padding(3)
        .background(Read4.surface, in: Capsule())
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }

    private func option(_ value: Insights.Series, _ title: LocalizedStringKey) -> some View {
        let on = selection == value
        return Button { selection = value } label: {
            Text(title)
                .dxFont(12, weight: 600, style: .caption2)
                .foregroundStyle(on ? Read4.onInk : Read4.muted)
                .padding(.vertical, 5).padding(.horizontal, 10)
                .background(on ? Read4.ink : .clear, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
        .sensoryFeedback(DX.Haptic.select, trigger: on)
    }
}

/// Time of day (rows) by weekday (columns, Monday first).
struct HeatMap: View {
    let grid: [[Int]]
    var scale: [Color] = HeatMap.cravingScale

    /// Five steps, none to most (decision 31): cravings in ocean blues, uses and slips in amber.
    static let cravingScale: [Color] = [Color(light: 0xECE6F7, dark: 0x1B2C66), Color(hex: 0xB9C6FF), Color(hex: 0x7F9CF5),
                                        Color(hex: 0x2A52DB), Color(light: 0x1E1A3A, dark: 0xE3EAFF)]
    static let useScale: [Color] = [Color(light: 0xF6EBD9, dark: 0x3A2A10), Color(hex: 0xF2C98A), Color(hex: 0xE5A93C),
                                    Color(hex: 0xB07A1C), Color(light: 0x5A3A10, dark: 0xFFE8C2)]

    var body: some View {
        let most = max(grid.flatMap { $0 }.max() ?? 1, 1)
        let days = Self.weekdayLetters
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Color.clear.frame(width: 64, height: 1)
                ForEach(0..<7, id: \.self) { i in
                    Text(verbatim: days[i]).dxFont(12, weight: 400, style: .caption2)
                        .foregroundStyle(Read4.muted).frame(maxWidth: .infinity)
                }
            }
            .accessibilityHidden(true)
            ForEach(Array(TimeOfDay.allCases.enumerated()), id: \.offset) { row, time in
                HStack(spacing: 4) {
                    Text(time.title).dxFont(12, weight: 400, style: .caption2)
                        .foregroundStyle(Read4.muted)
                        .lineLimit(1).minimumScaleFactor(0.8)
                        .frame(width: 64, alignment: .leading)
                    ForEach(0..<7, id: \.self) { col in
                        let value = grid[row][col]
                        let level = value == 0 ? 0 : min(4, max(1, Int((4 * Double(value) / Double(most)).rounded(.up))))
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(scale[level])
                            .frame(height: 26)
                            .frame(maxWidth: .infinity)
                            .accessibilityElement()
                            .accessibilityLabel(Text("\(Self.weekdayNames[col]), \(Text(time.title))"))
                            .accessibilityValue(Text("\(value)"))
                    }
                }
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }

    /// Monday first, in the user's language.
    static var weekdayLetters: [String] {
        let symbols = Calendar.current.veryShortStandaloneWeekdaySymbols
        return Array(symbols[1...] + symbols[..<1])
    }

    static var weekdayNames: [String] {
        let symbols = Calendar.current.standaloneWeekdaySymbols
        return Array(symbols[1...] + symbols[..<1])
    }
}

/// One line in "Recent logs".
struct LogEntryRow: View {
    let entry: LogEntry

    var body: some View {
        HStack(spacing: DX.Space.s) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(entry.outcome == .passed ? DX.Fill.cream : Read4.muted)
                .frame(width: 30, height: 30)
                .background(entry.outcome == .passed ? Read4.accent : Read4.track, in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text(title).dxFont(14, weight: 600, style: .subheadline).foregroundStyle(Read4.ink)
                Text(verbatim: detail).v4Text(.subtitle)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, DX.Space.s)
        .background(Read4.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Read4.hairline))
        .accessibilityElement(children: .combine)
    }

    private var icon: String {
        switch entry.kind {
        case .craving: entry.outcome == .passed ? "checkmark" : "flame"
        case .slip: "heart"
        case .use: "plus"
        }
    }

    private var title: LocalizedStringKey {
        switch entry.kind {
        case .craving: entry.outcome == .passed ? "Craving ridden out" : "Craving"
        case .slip:
            if let product = entry.product {
                "Slip · \(Text(product.title))"
            } else {
                "Slip"
            }
        case .use: entry.product.map(LogSheet.useTitle) ?? "Use"
        }
    }

    private var detail: String {
        var parts = [Self.when(entry.timestamp)]
        if let trigger = entry.trigger { parts.append(String(localized: trigger.title)) }
        if entry.kind == .slip, entry.nextTime != nil { parts.append(String(localized: "plan made")) }
        if let intensity = entry.intensity {
            parts.append(intensity <= 3 ? String(localized: "mild") : intensity <= 7 ? String(localized: "moderate") : String(localized: "strong"))
        }
        return parts.joined(separator: " · ")
    }

    static func when(_ date: Date) -> String {
        let time = date.formatted(date: .omitted, time: .shortened)
        if Calendar.current.isDateInToday(date) { return String(localized: "Today \(time)") }
        if Calendar.current.isDateInYesterday(date) { return String(localized: "Yesterday \(time)") }
        return "\(date.formatted(.dateTime.weekday(.abbreviated).day().month())) \(time)"
    }
}

/// The coral bar for top triggers.
private struct CoralBar: View {
    let value: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Color(light: 0xEDE6DA, dark: 0x1B2C66))
                Capsule().fill(Color(hex: 0xFF7A55)).frame(width: proxy.size.width * min(1, max(0, value)))
            }
        }
        .frame(height: 12)
        .accessibilityHidden(true)
    }
}
