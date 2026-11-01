import ActivityKit
import DayXeroCore
import SwiftData
import SwiftUI
import WidgetKit

@main
struct DayXeroWidgets: WidgetBundle {
    init() {
        DX.Typeface4.register()
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
                .containerBackground(DX.Ground.reading.background, for: .widget)
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
                Text("Prep day \(entry.prepDay ?? 1) · today").font(DX.Typeface4.swiftUIFont(.body, size: 12, weight: 700)).textCase(.uppercase).foregroundStyle(DX.Ground.reading.muted)
                let columns = family == .systemMedium ? 2 : 1
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DX.Space.xs), count: columns), spacing: DX.Space.xs) {
                    ForEach(entry.items.prefix(family == .systemMedium ? 4 : 2), id: \.self) { item in
                        Button(intent: LogUseIntent(product: LoggedProduct(item.product))) {
                            HStack(spacing: DX.Space.xs) {
                                Image(systemName: "plus").font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(DX.Ground.reading.background)
                                    .frame(width: 28, height: 28)
                                    .background(DX.Ground.reading.ink, in: Circle())
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(verbatim: item.today.formatted()).font(DX.Typeface4.swiftUIFont(.display, size: 19, weight: 800)).monospacedDigit()
                                        .foregroundStyle(DX.Ground.reading.ink)
                                    Text(label(item.product)).font(DX.Typeface4.swiftUIFont(.body, size: 12, weight: 500)).foregroundStyle(DX.Ground.reading.muted).lineLimit(1)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(8)
                            .background(DX.Fill.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        } else {
            VStack(alignment: .leading, spacing: DX.Space.xxs) {
                if let days = entry.daysClear { Text("Day \(days) since Quit Day").font(DX.Typeface4.swiftUIFont(.body, size: 12, weight: 700)).textCase(.uppercase).foregroundStyle(DX.Ground.reading.muted) }
                Text("Log a craving").font(DX.Typeface4.swiftUIFont(.body, size: 16, weight: 600)).foregroundStyle(DX.Ground.reading.ink)
                Spacer(minLength: 0)
                HStack(spacing: DX.Space.xs) {
                    Link(destination: URL(string: "dayxero://log/craving")!) {
                        Image(systemName: "plus").font(.system(size: 15, weight: .bold))
                            .foregroundStyle(DX.Ground.reading.background)
                            .frame(width: 40, height: 40)
                            .background(DX.Ground.reading.ink, in: Circle())
                    }
                    .accessibilityLabel(Text("Log a craving"))
                    Link(destination: URL(string: "dayxero://sos?source=widget")!) {
                        Image(systemName: "flame").font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(DX.Fill.cream)
                            .frame(width: 40, height: 40)
                            .background(DX.Fill.green, in: Circle())
                    }
                    .accessibilityLabel(Text("Craving SOS"))
                }
                if family == .systemMedium {
                    // A quiet way to log a slip; it opens the talk-through (S8.1).
                    Link(destination: URL(string: "dayxero://log/slip")!) {
                        Text("Slipped? \(Text("Log it").underline())").font(DX.Typeface4.swiftUIFont(.body, size: 12, weight: 500)).foregroundStyle(DX.Ground.reading.muted)
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
        case .vape: "Times vaped"
        case .pouches: "Pouches"
        }
    }
}

// MARK: - Craving Live Activity (S6.4)

/// SOS on the Lock Screen and in the Dynamic Island (v4, Phase 7): Jelli's ocean, the time ridden counting up
/// from the start (no countdown, design doc §10 F13), "It passed" and Open.
struct CravingLiveActivity: Widget {
    private static let ocean = Color(hex: 0x2A52DB)
    private static let solid = Color(hex: 0x1D3A9E)
    private static let cream = Color(hex: 0xFFF8EE)
    private static let soft = Color(hex: 0xE3EAFF)

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CravingActivityAttributes.self) { context in
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    jelli(36)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Riding it out with Jelli").font(DX.Typeface4.swiftUIFont(.body, size: 16, weight: 700))
                        Text("Breathe in for 4, out for 6").font(DX.Typeface4.swiftUIFont(.body, size: 12, weight: 500))
                            .foregroundStyle(Self.soft)
                    }
                    Spacer()
                    ridden(context.attributes.startedAt).font(DX.Typeface4.swiftUIFont(.display, size: 28, weight: 800))
                        .frame(maxWidth: 96, alignment: .trailing)
                }
                actions
            }
            .foregroundStyle(Self.cream)
            .padding(16)
            .activityBackgroundTint(Self.ocean)
            .activitySystemActionForegroundColor(Self.cream)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        jelli(30)
                        Text("With Jelli").font(DX.Typeface4.swiftUIFont(.body, size: 14, weight: 700))
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ridden(context.attributes.startedAt).font(DX.Typeface4.swiftUIFont(.display, size: 24, weight: 800))
                        .foregroundStyle(Self.soft)
                        .frame(maxWidth: 84, alignment: .trailing)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    actions.padding(.top, 6)
                }
            } compactLeading: {
                jelli(22)
            } compactTrailing: {
                ridden(context.attributes.startedAt).foregroundStyle(Self.soft).frame(maxWidth: 48)
            } minimal: {
                jelli(22)
            }
            .widgetURL(URL(string: "dayxero://sos?source=live_activity"))
            .keylineTint(Self.ocean)
        }
    }

    private func jelli(_ size: CGFloat) -> some View {
        JelliView(mood: .breathe, stage: 1, points: size * 0.9, animate: false)
            .frame(width: size, height: size)
            .background(Self.solid, in: Circle())
            .clipShape(Circle())
            .accessibilityHidden(true)
    }

    /// Time ridden so far, counting up.
    private func ridden(_ startedAt: Date) -> some View {
        Text(startedAt, style: .timer).monospacedDigit().multilineTextAlignment(.trailing)
    }

    private var actions: some View {
        HStack(spacing: 8) {
            Button(intent: CravingPassedIntent()) {
                Text("It passed").font(DX.Typeface4.swiftUIFont(.body, size: 16, weight: 700))
                    .frame(maxWidth: .infinity, minHeight: 40)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Self.ocean)
            .background(Self.cream, in: Capsule())
            Link(destination: URL(string: "dayxero://sos?source=live_activity")!) {
                Text("Open").font(DX.Typeface4.swiftUIFont(.body, size: 16, weight: 600))
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .background(Self.solid, in: Capsule())
            }
        }
    }
}
