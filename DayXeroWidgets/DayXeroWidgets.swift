import ActivityKit
import DayXeroCore
import SwiftData
import SwiftUI
import WidgetKit

@main
struct DayXeroWidgets: WidgetBundle {
    init() {
        DX.Typeface.register()
    }

    var body: some Widget {
        DaysFreeWidget()
        CravingSOSWidget()
        TodayWidget()
        WaterWidget()
        ForecastWidget()
        LogWidget()
        CravingSOSControl()
        LogWaterControl()
        BreatheControl()
        GuardControl()
        CravingLiveActivity()
        BreathingLiveActivity()
        GuardLiveActivity()
    }
}

// MARK: - One-tap logging (S7.1)

struct LogEntryCounts: TimelineEntry {
    struct Item: Hashable {
        let product: Product
        let today: Int
    }

    let date: Date
    /// True before Quit Day: the widget logs uses. After, it offers a craving log and SOS.
    let isPrep: Bool
    let daysClear: Int?
    let prepDay: Int?
    let items: [Item]
}

struct LogProvider: TimelineProvider {
    func placeholder(in context: Context) -> LogEntryCounts {
        LogEntryCounts(date: .now, isPrep: true, daysClear: nil, prepDay: 3,
                       items: [.init(product: .vape, today: 15), .init(product: .cigarettes, today: 3)])
    }

    func getSnapshot(in context: Context, completion: @escaping (LogEntryCounts) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : Self.entry(at: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LogEntryCounts>) -> Void) {
        let now = Date.now
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: now) ?? now.addingTimeInterval(3600)
        completion(Timeline(entries: [Self.entry(at: now)], policy: .after(next)))
    }

    static func entry(at date: Date) -> LogEntryCounts {
        guard let container = try? DataStore.makeContainer(),
              let profile = try? ModelContext(container).fetch(FetchDescriptor<UserProfile>()).first else {
            return LogEntryCounts(date: date, isPrep: false, daysClear: nil, prepDay: nil, items: [])
        }
        let context = ModelContext(container)
        let clock = DayClock(boundaryHour: profile.dayBoundaryHour)
        let stats = ProgressStats(quitDay: profile.quitDay, baselines: [], clock: clock)
        let today = clock.day(containing: date)
        let logs = (try? context.fetch(FetchDescriptor<LogEntry>(predicate: #Predicate { $0.timestamp >= today }))) ?? []
        let items = profile.products
            .sorted { ($0.isPrimary ? 0 : 1) < ($1.isPrimary ? 0 : 1) }
            .map { use in LogEntryCounts.Item(product: use.product, today: logs.filter { $0.product == use.product && $0.kind != .craving }.count) }
        let prepDay = (clock.calendar.dateComponents([.day], from: clock.startOfDate(profile.createdAt), to: today).day ?? 0) + 1
        return LogEntryCounts(date: date, isPrep: stats.isPrep(at: date), daysClear: stats.isPrep(at: date) ? nil : stats.daysClear(at: date),
                              prepDay: prepDay, items: items)
    }
}

struct LogWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "QuickLog", provider: LogProvider()) { entry in
            LogWidgetView(entry: entry)
                .containerBackground(DX.Palette.canvas, for: .widget)
        }
        .configurationDisplayName("Quick log")
        .description("Log a use with one tap during prep, or a craving after Quit Day.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct LogWidgetView: View {
    let entry: LogEntryCounts
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if entry.isPrep, !entry.items.isEmpty {
            VStack(alignment: .leading, spacing: DX.Space.xs) {
                Text("Prep day \(entry.prepDay ?? 1) · today").dxText(.micro)
                let columns = family == .systemMedium ? 2 : 1
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DX.Space.xs), count: columns), spacing: DX.Space.xs) {
                    ForEach(entry.items.prefix(family == .systemMedium ? 4 : 2), id: \.self) { item in
                        Button(intent: LogUseIntent(product: LoggedProduct(item.product))) {
                            HStack(spacing: DX.Space.xs) {
                                Image(systemName: "plus").font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(DX.Palette.onPrimary)
                                    .frame(width: 28, height: 28)
                                    .background(DX.Palette.primary, in: Circle())
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(verbatim: item.today.formatted()).font(.system(size: 18, weight: .bold)).monospacedDigit()
                                        .foregroundStyle(DX.Palette.text)
                                    Text(label(item.product)).font(.system(size: 10)).foregroundStyle(DX.Palette.text2).lineLimit(1)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(8)
                            .background(DX.Palette.surface2, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        } else {
            VStack(alignment: .leading, spacing: DX.Space.xxs) {
                if let days = entry.daysClear { Text("Day \(days) clear").dxText(.micro) }
                Text("Log a craving").font(.system(size: 15, weight: .semibold)).foregroundStyle(DX.Palette.text)
                Spacer(minLength: 0)
                HStack(spacing: DX.Space.xs) {
                    Link(destination: URL(string: "dayxero://log/craving")!) {
                        Image(systemName: "plus").font(.system(size: 15, weight: .bold))
                            .foregroundStyle(DX.Palette.onPrimary)
                            .frame(width: 40, height: 40)
                            .background(DX.Palette.primary, in: Circle())
                    }
                    .accessibilityLabel(Text("Log a craving"))
                    Link(destination: URL(string: "dayxero://sos?source=widget")!) {
                        Image(systemName: "flame").font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(DX.Palette.onAccent)
                            .frame(width: 40, height: 40)
                            .background(DX.Palette.sage, in: Circle())
                    }
                    .accessibilityLabel(Text("Craving SOS"))
                }
                if family == .systemMedium {
                    // A quiet way to log a slip; it opens the talk-through (S8.1).
                    Link(destination: URL(string: "dayxero://log/slip")!) {
                        Text("Slipped? \(Text("Log it").underline())").font(.system(size: 12)).foregroundStyle(DX.Palette.text2)
                    }
                    .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private func label(_ product: Product) -> LocalizedStringKey {
        switch product {
        case .cigarettes: "Cigarettes"
        case .vape: "Puff sessions"
        case .pouches: "Pouches"
        }
    }
}

// MARK: - Craving Live Activity (S6.4)

struct CravingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CravingActivityAttributes.self) { context in
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    appMark
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Riding it out").font(.system(size: 15, weight: .semibold))
                        Text("Breathe out slowly").font(.system(size: 12)).foregroundStyle(.white.opacity(0.6))
                    }
                    Spacer()
                    countdown(context.state.endsAt).font(.system(size: 28, weight: .bold)).foregroundStyle(DX.Palette.sage)
                        .frame(maxWidth: 90, alignment: .trailing)
                }
                ProgressView(timerInterval: context.state.endsAt.addingTimeInterval(-CravingSession.length)...context.state.endsAt,
                             countsDown: false) { EmptyView() } currentValueLabel: { EmptyView() }
                    .tint(DX.Palette.sage)
                actions
            }
            .foregroundStyle(.white)
            .padding(16)
            .activityBackgroundTint(Color(white: 0.11).opacity(0.85))
            .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        appMark
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Riding it out").font(.system(size: 14, weight: .semibold))
                            Text("Breathe out slowly").font(.system(size: 11)).foregroundStyle(.white.opacity(0.6))
                        }
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    countdown(context.state.endsAt).font(.system(size: 26, weight: .bold)).foregroundStyle(DX.Palette.sage)
                        .frame(maxWidth: 80, alignment: .trailing)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    actions.padding(.top, 6)
                }
            } compactLeading: {
                Image(systemName: "wind").foregroundStyle(DX.Palette.sage)
            } compactTrailing: {
                countdown(context.state.endsAt).foregroundStyle(DX.Palette.sage).frame(maxWidth: 44)
            } minimal: {
                Image(systemName: "wind").foregroundStyle(DX.Palette.sage)
            }
            .widgetURL(URL(string: "dayxero://sos?source=live_activity"))
            .keylineTint(DX.Palette.sage)
        }
    }

    private var appMark: some View {
        Circle().fill(DX.Palette.sage).frame(width: 9, height: 9)
            .frame(width: 28, height: 28)
            .background(.black, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func countdown(_ endsAt: Date) -> some View {
        Text(timerInterval: Date.now...max(endsAt, .now), countsDown: true).monospacedDigit()
    }

    private var actions: some View {
        HStack(spacing: 8) {
            Button(intent: CravingPassedIntent()) {
                Text("It passed").font(.system(size: 14, weight: .semibold)).frame(maxWidth: .infinity, minHeight: 36)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.black)
            .background(DX.Palette.sage, in: Capsule())
            Link(destination: URL(string: "dayxero://sos?source=live_activity")!) {
                Text("Open").font(.system(size: 14, weight: .semibold)).frame(maxWidth: .infinity, minHeight: 36)
                    .background(.white.opacity(0.14), in: Capsule())
            }
        }
    }
}
