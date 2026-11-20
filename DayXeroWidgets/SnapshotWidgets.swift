import ActivityKit
import AppIntents
import DayXeroCore
import SwiftUI
import WidgetKit

// The snapshot-driven widgets (S17.4–S17.9), their timelines (S17.1) and gallery entries (S17.13).

struct SnapshotEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
    /// No active plan (the hard paywall, 16 Nov 2026): the widget shows the subscribe state instead of any figures.
    var locked = false
}

/// What every widget shows without an active plan: no figures, no buttons. Tapping it opens the app, which opens
/// on the paywall. `onViolet` is false on the quick-log widget's reading ground.
struct WidgetSubscribeView: View {
    var onViolet = true
    @Environment(\.widgetFamily) private var family

    private var ink: Color { onViolet ? .white : DX.Ground.reading.ink }
    private var muted: Color { onViolet ? .white.opacity(0.6) : DX.Ground.reading.muted }

    var body: some View {
        switch family {
        case .accessoryInline:
            Text("DayXero: start your plan")
        case .accessoryCircular:
            Image(systemName: "lock.fill").font(.system(size: 18, weight: .semibold))
                .accessibilityLabel(Text("DayXero: start your plan"))
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 1) {
                Text(verbatim: "DayXero").font(DX.Typeface4.swiftUIFont(.body, size: 14, weight: 700))
                Text("Start your plan in the app").font(DX.Typeface4.swiftUIFont(.body, size: 12, weight: 500))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        default:
            VStack(alignment: .leading, spacing: DX.Space.xxs) {
                Image(systemName: "lock.fill").font(.system(size: 15, weight: .semibold)).foregroundStyle(muted)
                    .accessibilityHidden(true)
                Spacer(minLength: 0)
                Text("Start your plan").font(DX.Typeface4.swiftUIFont(.body, size: 16, weight: 700)).foregroundStyle(ink)
                Text("Open DayXero to subscribe and use this widget.")
                    .font(DX.Typeface4.swiftUIFont(.body, size: 12, weight: 500)).foregroundStyle(muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

/// Reads the App Group snapshot. Entries at the day boundary (so the day count rolls over on time) and, for the
/// forecast, at the window's start and end. Counters tick by themselves via timer text.
struct SnapshotProvider: TimelineProvider {
    var includeWindowEdges = false

    func placeholder(in context: Context) -> SnapshotEntry {
        SnapshotEntry(date: .now, snapshot: .sample())
    }

    func getSnapshot(in context: Context, completion: @escaping (SnapshotEntry) -> Void) {
        completion(SnapshotEntry(date: .now, snapshot: context.isPreview ? .sample() : (WidgetSnapshot.load() ?? .sample()),
                                 locked: !context.isPreview && !PlanGate.isActive))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SnapshotEntry>) -> Void) {
        let now = Date.now
        // Before onboarding there's no snapshot: show the sample until the app writes one.
        let snapshot = WidgetSnapshot.load() ?? .sample()
        var dates = [now]
        if snapshot.nextDayStart > now { dates.append(snapshot.nextDayStart) }
        if includeWindowEdges, let window = snapshot.nextWindow {
            dates += [window.start, window.end].filter { $0 > now }
        }
        let locked = !PlanGate.isActive
        let entries = dates.sorted().map { SnapshotEntry(date: $0, snapshot: snapshot, locked: locked) }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

private struct ModeReader<Content: View>: View {
    @Environment(\.widgetRenderingMode) private var mode
    @Environment(\.widgetFamily) private var family
    @Environment(\.showsWidgetContainerBackground) private var showsBackground
    @ViewBuilder let content: (WidgetRenderingMode, WidgetFamily, Bool) -> Content

    var body: some View {
        content(mode, family, !showsBackground)
            .containerBackground(for: .widget) { WidgetTone.background }
    }
}

struct DaysFreeWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetSnapshot.Kind.days, provider: SnapshotProvider()) { entry in
            ModeReader { mode, family, standBy in
                if entry.locked { WidgetSubscribeView() } else {
                    DayCounterWidgetView(snapshot: entry.snapshot, family: family, mode: mode, standBy: standBy)
                }
            }
        }
        .configurationDisplayName("Days since Day Xero")
        .description("Your days since Day Xero, at a glance.")
        .supportedFamilies([.systemSmall, .accessoryInline])
    }
}

struct CravingSOSWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetSnapshot.Kind.sos, provider: SnapshotProvider()) { entry in
            ModeReader { mode, family, _ in
                if entry.locked { WidgetSubscribeView() } else { SOSWidgetView(snapshot: entry.snapshot, family: family, mode: mode) }
            }
        }
        .configurationDisplayName("Craving SOS")
        .description("One tap to ride out a craving.")
        .supportedFamilies([.systemSmall, .accessoryCircular])
    }
}

struct TodayWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetSnapshot.Kind.today, provider: SnapshotProvider(includeWindowEdges: true)) { entry in
            ModeReader { mode, _, _ in
                if entry.locked { WidgetSubscribeView() } else { TodayWidgetView(snapshot: entry.snapshot, mode: mode) }
            }
        }
        .configurationDisplayName("Today")
        .description("Days, money kept, water and your next lesson.")
        .supportedFamilies([.systemMedium])
    }
}

struct WaterWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetSnapshot.Kind.water, provider: SnapshotProvider()) { entry in
            ModeReader { mode, family, _ in
                if entry.locked { WidgetSubscribeView() } else { WaterWidgetView(snapshot: entry.snapshot, family: family, mode: mode) }
            }
        }
        .configurationDisplayName("Water")
        .description("See today's water and log a glass.")
        .supportedFamilies([.systemSmall, .accessoryCircular])
    }
}

struct ForecastWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetSnapshot.Kind.forecast, provider: SnapshotProvider(includeWindowEdges: true)) { entry in
            ModeReader { mode, family, _ in
                if entry.locked { WidgetSubscribeView() } else {
                    ForecastWidgetView(snapshot: entry.snapshot, family: family, mode: mode, date: entry.date,
                                       guarding: !Activity<GuardActivityAttributes>.activities.isEmpty)
                }
            }
        }
        .configurationDisplayName("Craving forecast")
        .description("Your next likely craving, and a one-tap guard.")
        .supportedFamilies([.systemSmall, .accessoryRectangular])
    }
}

// MARK: - Controls (S17.9)

struct CravingSOSControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "in.dayxero.app.sos-control") {
            ControlWidgetButton(action: OpenSOSIntent()) {
                Label("Craving SOS", systemImage: "alternatingcurrent")
            }
            .tint(WidgetTone.sage)
        }
        .displayName("Craving SOS")
        .description("Start a three-minute session to ride out a craving.")
    }
}

struct LogWaterControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "in.dayxero.app.water-control") {
            ControlWidgetButton(action: LogWaterIntent(from: .controlCenter)) {
                Label("Log water", systemImage: "capsule.portrait.bottomhalf.filled")
            }
        }
        .displayName("Log water")
        .description("Log a glass of water.")
    }
}

struct BreatheControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "in.dayxero.app.breathe-control") {
            ControlWidgetButton(action: StartBreathingIntent()) {
                Label("Breathe", systemImage: "circle.circle")
            }
        }
        .displayName("Breathe")
        .description("A short breathing exercise on your Lock Screen.")
    }
}

struct GuardControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "in.dayxero.app.guard-control") {
            ControlWidgetButton(action: GuardWindowIntent()) {
                Label("Guard 30 min", systemImage: "shield")
            }
        }
        .displayName("Guard 30 min")
        .description("Keep a quiet guard on your Lock Screen through a likely craving time.")
    }
}

// MARK: - Breathing and Window Guard Live Activities (S12.5, S14.7)

/// Live Activities can't animate: the pattern, a still ring and a self-updating countdown.
struct BreathingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BreathingActivityAttributes.self) { context in
            HStack(spacing: 14) {
                ring(36)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(context.state.done ? "Done" : "Breathe with the pattern")
                        if context.state.done { Image(systemName: "checkmark").accessibilityHidden(true) }
                    }
                    .font(.system(size: 15, weight: .semibold))
                    Text(verbatim: "\(context.attributes.patternName.uppercased()) · \(context.attributes.counts)")
                        .font(DX.Typeface4.swiftUIFont(.body, size: 12, weight: 600).monospacedDigit()).foregroundStyle(.white.opacity(0.6))
                    if !context.state.done {
                        ProgressView(timerInterval: context.attributes.startedAt...max(context.state.endsAt, context.attributes.startedAt),
                                     countsDown: false) { EmptyView() } currentValueLabel: { EmptyView() }
                            .tint(WidgetTone.sage)
                    }
                }
                Spacer(minLength: 0)
                if !context.state.done {
                    VStack(alignment: .trailing, spacing: 6) {
                        Text(timerInterval: Date.now...max(context.state.endsAt, .now), countsDown: true)
                            .font(.system(size: 22, weight: .bold)).monospacedDigit().foregroundStyle(WidgetTone.sage)
                            .frame(maxWidth: 70, alignment: .trailing)
                        Button(intent: StopBreathingIntent()) {
                            Text("Stop").font(.system(size: 13, weight: .semibold)).padding(.horizontal, 12).frame(minHeight: 28)
                                .background(.white.opacity(0.14), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .foregroundStyle(.white)
            .padding(16)
            .activityBackgroundTint(WidgetTone.background.opacity(0.9))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) { ring(30) }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: Date.now...max(context.state.endsAt, .now), countsDown: true)
                        .font(.system(size: 20, weight: .bold)).monospacedDigit().foregroundStyle(WidgetTone.sage)
                        .frame(maxWidth: 64, alignment: .trailing)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(verbatim: "\(context.attributes.patternName.uppercased()) · \(context.attributes.counts)")
                        .font(DX.Typeface4.swiftUIFont(.body, size: 12, weight: 600).monospacedDigit()).foregroundStyle(.white.opacity(0.7))
                }
            } compactLeading: {
                ring(18)
            } compactTrailing: {
                Text(timerInterval: Date.now...max(context.state.endsAt, .now), countsDown: true)
                    .monospacedDigit().foregroundStyle(WidgetTone.sage).frame(maxWidth: 44)
            } minimal: {
                ring(18)
            }
            .keylineTint(WidgetTone.sage)
        }
    }

    private func ring(_ size: CGFloat) -> some View {
        ZStack {
            Circle().stroke(WidgetTone.moss, lineWidth: size * 0.16)
            Circle().stroke(WidgetTone.sage, lineWidth: size * 0.07)
        }
        .frame(width: size, height: size)
    }
}

struct GuardLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GuardActivityAttributes.self) { context in
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    ShieldGlyph(fill: WidgetTone.moss.opacity(0.5), stroke: WidgetTone.sage).frame(width: 26, height: 30)
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(context.state.passed ? "Window passed" : "Your \(context.attributes.windowStart.formatted(date: .omitted, time: .shortened)) window")
                            if context.state.passed { Image(systemName: "checkmark").accessibilityHidden(true) }
                        }
                        .font(.system(size: 15, weight: .semibold))
                        Text(context.attributes.triggerLabel.isEmpty ? String(localized: "You've got this.")
                             : String(localized: "\(context.attributes.triggerLabel). You've got this."))
                            .font(.system(size: 12)).foregroundStyle(.white.opacity(0.6))
                    }
                    Spacer(minLength: 0)
                    if !context.state.passed {
                        VStack(alignment: .trailing, spacing: 0) {
                            Text(timerInterval: Date.now...max(context.state.endsAt, .now), countsDown: true)
                                .font(.system(size: 20, weight: .bold)).monospacedDigit().foregroundStyle(WidgetTone.sage)
                                .frame(maxWidth: 70, alignment: .trailing)
                            Text("UNTIL \(context.state.endsAt.formatted(date: .omitted, time: .shortened))")
                                .font(.system(size: 9, weight: .semibold, design: .monospaced)).foregroundStyle(.white.opacity(0.5))
                        }
                    }
                }
                if !context.state.passed { actions }
            }
            .foregroundStyle(.white)
            .padding(16)
            .activityBackgroundTint(WidgetTone.background.opacity(0.9))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    ShieldGlyph(fill: WidgetTone.moss.opacity(0.5), stroke: WidgetTone.sage).frame(width: 22, height: 26)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: Date.now...max(context.state.endsAt, .now), countsDown: true)
                        .font(.system(size: 18, weight: .bold)).monospacedDigit().foregroundStyle(WidgetTone.sage)
                        .frame(maxWidth: 64, alignment: .trailing)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text("You've ridden out \(context.attributes.riddenOut) of these.").font(.system(size: 12)).foregroundStyle(.white.opacity(0.7))
                }
                DynamicIslandExpandedRegion(.bottom) { actions }
            } compactLeading: {
                ShieldGlyph(fill: .clear, stroke: WidgetTone.sage, lineWidth: 1.2).frame(width: 14, height: 16)
            } compactTrailing: {
                Text("until \(context.state.endsAt.formatted(date: .omitted, time: .shortened))")
                    .font(.system(size: 12, weight: .semibold)).foregroundStyle(WidgetTone.sage)
            } minimal: {
                ShieldGlyph(fill: .clear, stroke: WidgetTone.sage, lineWidth: 1.2).frame(width: 14, height: 16)
            }
            .keylineTint(WidgetTone.sage)
        }
    }

    private var actions: some View {
        HStack(spacing: 8) {
            Button(intent: StartBreathingIntent()) { pill("Breathe", filled: true) }.buttonStyle(.plain)
            Button(intent: LogWaterIntent(from: .liveActivity)) { pill("+1 water", filled: false) }.buttonStyle(.plain)
            Button(intent: EndGuardIntent()) { pill("I'm good", filled: false) }.buttonStyle(.plain)
        }
    }

    private func pill(_ title: LocalizedStringKey, filled: Bool) -> some View {
        Text(title).font(.system(size: 13, weight: .semibold))
            .foregroundStyle(filled ? .black : .white)
            .frame(maxWidth: .infinity, minHeight: 34)
            .background(filled ? WidgetTone.sage : .white.opacity(0.14), in: Capsule())
    }
}
