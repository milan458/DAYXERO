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
    @State private var series = Insights.Series.cravings
    @State private var editing: LogEntry?
    @State private var showHealth = UserDefaults.standard.bool(forKey: "dx.openHealth")

    var body: some View {
        TimelineView(.everyMinute) { timeline in
            let now = timeline.date
            let snap = HomeSnapshot(profile: profile, isPro: entitlement.isPro, now: now)
            let insights = Insights(points: entries.map(Insights.Point.init), now: now)
            ScrollView {
                VStack(alignment: .leading, spacing: DX.Space.xs) {
                    header(snap)
                    hero(snap)
                    tiles(snap, insights: insights)
                    // What's changing in the body, from Quit Day (S10).
                    HealthSummaryCard(profile: profile, now: now) { showHealth = true }
                    // The full step plan for each NRT product (S9.5).
                    ForEach(profile.nrtPlans.sorted { $0.createdAt < $1.createdAt }) { plan in
                        NRTCard(plan: plan, clock: DayClock(boundaryHour: profile.dayBoundaryHour), now: now, showAllSteps: true)
                    }
                    HStack(alignment: .firstTextBaseline) {
                        Text("Your patterns").dxText(.micro)
                        Spacer()
                        if insights.isReady { Text("Last 4 weeks").font(.custom(DX.Typeface.regular, size: 11, relativeTo: .caption2)).foregroundStyle(DX.Palette.muted) }
                    }
                    .padding(.top, DX.Space.m)
                    .accessibilityAddTraits(.isHeader)
                    if insights.isReady {
                        heatCard(insights)
                        triggersCard(insights)
                        trendCard(insights)
                        recentLogs
                    } else {
                        notReady(insights)
                    }
                }
                .padding(.horizontal, DX.Space.m)
                .padding(.top, DX.Space.s)
                .padding(.bottom, 120)
            }
        }
        .sheet(isPresented: $showHealth) {
            HealthTimelineView(profile: profile, onClose: { showHealth = false })
                .presentationDetents([.large])
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

    // MARK: What you've gained (S7.4)

    private func header(_ snap: HomeSnapshot) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(eyebrow(snap)).dxText(.micro)
                Text("Progress").dxText(.title).accessibilityAddTraits(.isHeader)
            }
            Spacer()
            LogButton { log.open() }
        }
        .padding(.bottom, DX.Space.xxs)
    }

    private func eyebrow(_ snap: HomeSnapshot) -> String {
        if case let .prep(days) = snap.phase {
            return String(localized: "Quit Day in \(days) days")
        }
        return String(localized: "Day \(snap.daysClear) · since \(profile.quitDay.formatted(.dateTime.weekday(.abbreviated).day().month()))")
    }

    private func hero(_ snap: HomeSnapshot) -> some View {
        let perDay = snap.moneyPerYear / 365
        let isPrep: Bool = if case .prep = snap.phase { true } else { false }
        return DXGlassCard {
            VStack(alignment: .leading, spacing: 4) {
                Text(isPrep ? LocalizedStringKey("You'll keep") : LocalizedStringKey("Money kept")).dxText(.micro)
                Text(verbatim: (isPrep ? snap.moneyPerYear : snap.moneyKept)
                    .formatted(.currency(code: snap.currencyCode).precision(.fractionLength(isPrep ? 0 : 2))))
                    .font(.custom(DX.Typeface.bold, size: 40, relativeTo: .largeTitle))
                    .foregroundStyle(DX.Palette.text)
                    .contentTransition(.numericText())
                if isPrep {
                    Text("a year, from Quit Day").dxText(.subtitle)
                } else {
                    Text("\(perDay.formatted(.currency(code: snap.currencyCode))) a day · on track for \(snap.moneyPerYear.formatted(.currency(code: snap.currencyCode).precision(.fractionLength(0)))) this year")
                        .dxText(.subtitle)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func tiles(_ snap: HomeSnapshot, insights: Insights) -> some View {
        let columns = typeSize.isAccessibilitySize
            ? [GridItem(.flexible())]
            : [GridItem(.flexible(), spacing: DX.Space.xs), GridItem(.flexible())]
        let ridden = entries.filter { $0.kind == .craving && $0.outcome == .passed }.count
        let isPrep: Bool = if case .prep = snap.phase { true } else { false }
        LazyVGrid(columns: columns, alignment: .leading, spacing: DX.Space.xs) {
            // Only the products picked in onboarding get a counter.
            if !isPrep {
                ForEach(snap.counters) { counter in
                    ProgressTile(label: avoidedLabel(counter.product), value: counter.avoided.formatted(),
                                 caption: "\(counter.perDayBefore) a day before")
                }
            }
            ProgressTile(label: "Cravings ridden out", value: ridden.formatted(),
                         caption: "\(CravingStats.passedThisWeek(entries, now: insights.now)) this week")
            if isPrep {
                ProgressTile(label: "Prep days done", value: "\(snap.prepDone) / \(snap.prepTotal)", caption: "before Quit Day")
            } else {
                ProgressTile(label: "Days clear", value: snap.daysClear.formatted(),
                             caption: "since \(profile.quitDay.formatted(.dateTime.weekday(.abbreviated).day().month()))")
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

    // MARK: Patterns (S7.3)

    private func heatCard(_ insights: Insights) -> some View {
        let grid = insights.heatMap(series)
        let peaks = insights.peaks(series)
        return DXCard(padding: 14) {
            VStack(alignment: .leading, spacing: DX.Space.s) {
                HStack(alignment: .top) {
                    Text(series == .cravings ? LocalizedStringKey("When cravings hit") : LocalizedStringKey("When you used")).dxText(.cardHeading)
                    Spacer()
                    SeriesToggle(selection: $series)
                }
                if let summary = summary(peaks) {
                    Text(summary).dxText(.subtitle)
                }
                // Uses and slips in amber, so they read differently from cravings (S8.4).
                HeatMap(grid: grid, tint: series == .cravings ? DX.Palette.sage : DX.Palette.amber)
            }
        }
    }

    private func summary(_ peaks: [Insights.Peak]) -> AttributedString? {
        if series == .uses, let first = peaks.first {
            var text = AttributedString(peakName(first))
            text.font = .custom(DX.Typeface.semibold, size: 13, relativeTo: .footnote)
            text.foregroundColor = DX.Palette.text
            return text + AttributedString(String(localized: " are when you've used most."))
        }
        guard let first = peaks.first else { return nil }
        var text = AttributedString(peakName(first))
        text.font = .custom(DX.Typeface.semibold, size: 13, relativeTo: .footnote)
        text.foregroundColor = DX.Palette.text
        if peaks.count > 1 {
            var second = AttributedString(peakName(peaks[1]).lowercased())
            second.font = text.font
            second.foregroundColor = DX.Palette.text
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
        return DXCard(padding: 14) {
            VStack(alignment: .leading, spacing: DX.Space.xs) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Top triggers").dxText(.cardHeading)
                    Spacer()
                    Text("\(insights.taggedCount) logged").dxText(.micro)
                }
                if top.isEmpty {
                    Text("Tag what set a craving off, in SOS or a craving log, and your top triggers show here.").dxText(.subtitle)
                }
                ForEach(top, id: \.trigger) { item in
                    HStack(spacing: DX.Space.xs) {
                        Text(item.trigger.title).font(DX.TextStyle.subtitle.font).foregroundStyle(DX.Palette.text)
                            .frame(width: typeSize.isAccessibilitySize ? nil : 96, alignment: .leading)
                        DXProgressBar(value: Double(item.count) / Double(most))
                        Text(verbatim: item.count.formatted()).font(DX.TextStyle.subtitle.font).foregroundStyle(DX.Palette.muted)
                            .monospacedDigit().frame(minWidth: 22, alignment: .trailing)
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
        return DXCard(padding: 14) {
            VStack(alignment: .leading, spacing: DX.Space.s) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Cravings by week").dxText(.cardHeading)
                    Spacer()
                    if let change = insights.weekOnWeekChange { Text(changeLabel(change)).dxText(.micro) }
                }
                HStack(alignment: .bottom, spacing: DX.Space.s) {
                    ForEach(Array(weeks.enumerated()), id: \.offset) { index, week in
                        VStack(spacing: 4) {
                            Text(verbatim: week.cravings.formatted()).font(.custom(DX.Typeface.semibold, size: 12, relativeTo: .caption))
                                .foregroundStyle(DX.Palette.text)
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(week.isCurrent ? DX.Palette.sage : DX.Palette.track)
                                .frame(height: max(4, 72 * CGFloat(week.cravings) / CGFloat(most)))
                            Text(weekLabel(week, back: weeks.count - 1 - index))
                                .font(.custom(DX.Typeface.regular, size: 10, relativeTo: .caption2))
                                .foregroundStyle(DX.Palette.muted)
                                .lineLimit(1).minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity)
                        .accessibilityElement(children: .combine)
                    }
                }
                .frame(height: 112, alignment: .bottom)
                if let current, current.cravings > 0 {
                    Text("You rode out \(current.riddenOut) of \(current.cravings) cravings this week.").dxText(.subtitle)
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
        Text("Recent logs").dxText(.micro).padding(.top, DX.Space.s)
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

    private func notReady(_ insights: Insights) -> some View {
        DXCard(padding: 14) {
            ZStack {
                HeatMap(grid: Self.sampleGrid)
                    .blur(radius: 4)
                    .opacity(0.4)
                    .accessibilityHidden(true)
                VStack(spacing: DX.Space.xs) {
                    Text("Insights need a week of logs").dxText(.cardHeading).multilineTextAlignment(.center)
                    DXProgressBar(value: insights.readiness).frame(maxWidth: 180)
                    Text("\(insights.daysOfData) of \(Insights.minimumDays) days · \(insights.points.count) logs so far").dxText(.subtitle)
                    Text("Log cravings as they happen and your patterns appear here.").dxText(.subtitle)
                        .multilineTextAlignment(.center)
                }
                .padding(DX.Space.s)
            }
        }
    }

    /// A made-up shape for the blurred placeholder only; never shown as data.
    private static let sampleGrid = [[3, 4, 3, 4, 3, 1, 1], [1, 2, 1, 1, 2, 2, 1], [2, 3, 2, 2, 1, 1, 0], [1, 1, 2, 1, 3, 4, 3], [0, 0, 1, 0, 1, 2, 1]]
}

struct LogButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Log", systemImage: "plus")
                .font(.custom(DX.Typeface.semibold, size: 13, relativeTo: .footnote))
                .foregroundStyle(DX.Palette.text)
                .padding(.horizontal, 14)
                .frame(minHeight: 36)
                .background(DX.Palette.surface1, in: Capsule())
                .overlay(Capsule().strokeBorder(DX.Palette.hairline))
        }
        .buttonStyle(.plain)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}

private struct ProgressTile: View {
    let label: LocalizedStringKey
    let value: String
    let caption: LocalizedStringKey

    var body: some View {
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
}

private struct SeriesToggle: View {
    @Binding var selection: Insights.Series

    var body: some View {
        HStack(spacing: 0) {
            option(.cravings, "Cravings")
            option(.uses, "Uses")
        }
        .padding(3)
        .background(DX.Palette.surface2, in: Capsule())
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
    }

    private func option(_ value: Insights.Series, _ title: LocalizedStringKey) -> some View {
        let on = selection == value
        return Button { selection = value } label: {
            Text(title)
                .font(.custom(DX.Typeface.semibold, size: 11, relativeTo: .caption2))
                .foregroundStyle(on ? DX.Palette.onPrimary : DX.Palette.text2)
                .padding(.vertical, 5).padding(.horizontal, 10)
                .background(on ? DX.Palette.primary : .clear, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
        .sensoryFeedback(DX.Haptic.select, trigger: on)
    }
}

/// Time of day (rows) by weekday (columns, Monday first).
struct HeatMap: View {
    let grid: [[Int]]
    var tint: Color = DX.Palette.sage

    var body: some View {
        let most = max(grid.flatMap { $0 }.max() ?? 1, 1)
        let days = Self.weekdayLetters
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Color.clear.frame(width: 64, height: 1)
                ForEach(0..<7, id: \.self) { i in
                    Text(verbatim: days[i]).font(.custom(DX.Typeface.regular, size: 10, relativeTo: .caption2))
                        .foregroundStyle(DX.Palette.muted).frame(maxWidth: .infinity)
                }
            }
            .accessibilityHidden(true)
            ForEach(Array(TimeOfDay.allCases.enumerated()), id: \.offset) { row, time in
                HStack(spacing: 4) {
                    Text(time.title).font(.custom(DX.Typeface.regular, size: 10, relativeTo: .caption2))
                        .foregroundStyle(DX.Palette.muted)
                        .lineLimit(1).minimumScaleFactor(0.8)
                        .frame(width: 64, alignment: .leading)
                    ForEach(0..<7, id: \.self) { col in
                        let value = grid[row][col]
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(value == 0 ? DX.Palette.track.opacity(0.5) : tint.opacity(0.2 + 0.8 * Double(value) / Double(most)))
                            .frame(height: 22)
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
                .foregroundStyle(entry.outcome == .passed ? DX.Palette.onAccent : DX.Palette.text2)
                .frame(width: 30, height: 30)
                .background(entry.outcome == .passed ? DX.Palette.sage : DX.Palette.track, in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.custom(DX.Typeface.semibold, size: 14, relativeTo: .subheadline)).foregroundStyle(DX.Palette.text)
                Text(verbatim: detail).dxText(.subtitle)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, DX.Space.s)
        .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(DX.Palette.hairline))
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
