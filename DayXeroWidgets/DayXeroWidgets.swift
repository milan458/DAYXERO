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
        DaysClearWidget()
        CravingLiveActivity()
    }
}

// MARK: - Days clear (home and lock screen)

struct DaysClearEntry: TimelineEntry {
    let date: Date
    /// nil before onboarding is finished.
    let daysClear: Int?
    let daysUntilQuitDay: Int?
}

struct DaysClearProvider: TimelineProvider {
    func placeholder(in context: Context) -> DaysClearEntry {
        DaysClearEntry(date: .now, daysClear: 3, daysUntilQuitDay: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (DaysClearEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : Self.entry(at: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DaysClearEntry>) -> Void) {
        let now = Date.now
        let next = Calendar.current.date(byAdding: .hour, value: 1, to: now) ?? now.addingTimeInterval(3600)
        completion(Timeline(entries: [Self.entry(at: now)], policy: .after(next)))
    }

    static func entry(at date: Date) -> DaysClearEntry {
        guard let container = try? DataStore.makeContainer() else {
            return DaysClearEntry(date: date, daysClear: nil, daysUntilQuitDay: nil)
        }
        let context = ModelContext(container)
        guard let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first else {
            return DaysClearEntry(date: date, daysClear: nil, daysUntilQuitDay: nil)
        }
        let stats = ProgressStats(
            quitDay: profile.quitDay,
            baselines: profile.products.map(\.baseline),
            clock: DayClock(boundaryHour: profile.dayBoundaryHour)
        )
        return DaysClearEntry(
            date: date,
            daysClear: stats.isPrep(at: date) ? nil : stats.daysClear(at: date),
            daysUntilQuitDay: stats.isPrep(at: date) ? stats.daysUntilQuitDay(at: date) : nil
        )
    }
}

struct DaysClearWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "DaysClear", provider: DaysClearProvider()) { entry in
            DaysClearView(entry: entry)
                .containerBackground(DX.Palette.canvas, for: .widget)
        }
        .configurationDisplayName("Days clear")
        .description("Your days clear, or the countdown to Quit Day.")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular])
    }
}

struct DaysClearView: View {
    let entry: DaysClearEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            VStack(spacing: 0) {
                Text(value, format: .number).font(.system(size: 20, weight: .bold)).monospacedDigit()
                Text(caption).font(.system(size: 9))
            }
        case .accessoryRectangular:
            VStack(alignment: .leading) {
                Text("DayXero").font(.headline)
                Text("\(value) \(Text(caption))")
            }
        default:
            VStack(alignment: .leading, spacing: DX.Space.xxs) {
                Text(entry.daysUntilQuitDay == nil ? "Days clear" : "Quit Day in").dxText(.micro)
                Spacer()
                Text(value, format: .number).dxText(.hero)
                Text(caption).dxText(.subtitle)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var value: Int { entry.daysClear ?? entry.daysUntilQuitDay ?? 0 }

    private var caption: LocalizedStringKey {
        if entry.daysClear != nil { return "days clear" }
        if entry.daysUntilQuitDay != nil { return "days to go" }
        return "Open DayXero to start"
    }
}

// MARK: - Craving Live Activity (built out in Section 6)

struct CravingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CravingActivityAttributes.self) { context in
            HStack {
                Circle().fill(DX.Palette.sage).frame(width: 10, height: 10)
                Text("Craving wave")
                Spacer()
                Text(timerInterval: Date.now...max(context.state.endsAt, .now), countsDown: true)
                    .monospacedDigit()
                    .frame(maxWidth: 64)
            }
            .foregroundStyle(.white)
            .padding()
            .activityBackgroundTint(.black)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text("Craving wave")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: Date.now...max(context.state.endsAt, .now), countsDown: true)
                        .monospacedDigit()
                }
            } compactLeading: {
                Circle().fill(DX.Palette.sage).frame(width: 10, height: 10)
            } compactTrailing: {
                Text(timerInterval: Date.now...max(context.state.endsAt, .now), countsDown: true)
                    .monospacedDigit()
                    .frame(maxWidth: 40)
            } minimal: {
                Circle().fill(DX.Palette.sage).frame(width: 10, height: 10)
            }
        }
    }
}
