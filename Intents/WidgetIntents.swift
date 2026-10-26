import ActivityKit
import AppIntents
import DayXeroCore
import SwiftData
import WidgetKit

// Widget and control intents (S17.2). Compiled into the app and the widget extension.

/// Where a water log came from, for analytics and the entry's source.
enum WaterLogSource: String, AppEnum {
    // App Intent enum names can't contain "Siri" (ITMS-90626), so voice and Shortcuts logs are "shortcut".
    case widget, controlCenter, shortcut, liveActivity

    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Source" }
    static var caseDisplayRepresentations: [WaterLogSource: DisplayRepresentation] {
        [.widget: "Widget", .controlCenter: "Control Center", .shortcut: "Shortcut", .liveActivity: "Live Activity"]
    }

    var source: WaterSource {
        switch self {
        case .widget: .widget
        case .controlCenter: .controlCenter
        case .shortcut: .siri
        case .liveActivity: .liveActivity
        }
    }
}

/// +1 glass (or the last chosen drink) from a widget, control, Live Activity or Siri, without opening the app.
struct LogWaterIntent: AppIntent {
    static let title: LocalizedStringResource = "Log water"
    static let description = IntentDescription("Logs a glass of water, or your usual drink.")

    @Parameter(title: "Source", default: .shortcut) var from: WaterLogSource

    init() {}

    init(from: WaterLogSource) {
        self.from = from
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try SOSBridge.container ?? DataStore.makeContainer()
        let context = container.mainContext
        let drink = (try? context.fetch(FetchDescriptor<WaterProfile>()).first)?.selectedDrink ?? .glass
        WaterLog.log(drink, source: from.source, in: context)
        WidgetSnapshot.refreshWater(in: context)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetSnapshot.Kind.water)
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetSnapshot.Kind.today)
        let snapshot = WidgetSnapshot.load()
        if let snapshot {
            return .result(dialog: "Logged. \(snapshot.glassesToday) of \(snapshot.glassesGoal) glasses today.")
        }
        return .result(dialog: "Logged.")
    }
}

/// Opens straight into Craving SOS, which starts the session and its Live Activity.
struct OpenSOSIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Craving SOS"
    static let description = IntentDescription("Opens a three-minute session to ride out a craving.")
    static let openAppWhenRun = true
    static let isDiscoverable = false

    @MainActor
    func perform() async throws -> some IntentResult {
        SOSBridge.requestSession(source: "widget")
        return .result()
    }
}

/// Starts a breathing session on the Lock Screen and Dynamic Island without opening the app.
struct StartBreathingIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Breathe"
    static let description = IntentDescription("Starts a short breathing exercise on your Lock Screen.")

    @MainActor
    func perform() async throws -> some IntentResult {
        let data = OrbData.bundled
        let pattern = data.pattern(UserDefaults.standard.string(forKey: "dx.breathePattern") ?? "box")
        let cycle = BreathPhase.allCases.reduce(0) { $0 + pattern.seconds($1) }
        let now = Date.now
        let ends = now.addingTimeInterval(Double(cycle * pattern.recommendedCycles))
        let counts = BreathPhase.allCases.filter { pattern.seconds($0) > 0 }
            .map { "\($0.word == "inhale" ? "in" : $0.word == "exhale" ? "out" : $0.word) \(pattern.seconds($0))" }
            .joined(separator: " · ")
        for activity in Activity<BreathingActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return .result() }
        let attributes = BreathingActivityAttributes(patternID: pattern.id, patternName: pattern.name, counts: counts,
                                                     cycles: pattern.recommendedCycles, startedAt: now)
        _ = try? Activity.request(attributes: attributes,
                                  content: .init(state: .init(endsAt: ends), staleDate: ends.addingTimeInterval(15 * 60)))
        return .result()
    }
}

/// Ends the breathing session early.
struct StopBreathingIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Stop breathing"
    static let isDiscoverable = false

    @MainActor
    func perform() async throws -> some IntentResult {
        for activity in Activity<BreathingActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        return .result()
    }
}

/// Guards the next predicted craving window, or the next 30 minutes when none is predicted.
struct GuardWindowIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Guard my next window"
    static let description = IntentDescription("Keeps a quiet guard on your Lock Screen through a likely craving time.")

    @MainActor
    func perform() async throws -> some IntentResult {
        let snapshot = WidgetSnapshot.load()
        let now = Date.now
        let window = snapshot?.nextWindow.flatMap { $0.start.timeIntervalSince(now) < 3 * 3600 ? $0 : nil }
        let start = window.map { max($0.start, now) } ?? now
        let end = window?.end ?? now.addingTimeInterval(30 * 60)
        for activity in Activity<GuardActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return .result() }
        let label = window?.trigger.map { String(localized: $0.title) } ?? ""
        let attributes = GuardActivityAttributes(windowStart: window?.start ?? start, triggerLabel: label,
                                                 riddenOut: snapshot?.cravingsRidden ?? 0)
        _ = try? Activity.request(attributes: attributes,
                                  content: .init(state: .init(endsAt: end), staleDate: end.addingTimeInterval(30 * 60)))
        return .result()
    }
}

/// "I'm good": ends the guard with the same quiet win as getting through the window.
struct EndGuardIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "I'm good"
    static let isDiscoverable = false

    @MainActor
    func perform() async throws -> some IntentResult {
        for activity in Activity<GuardActivityAttributes>.activities {
            let state = GuardActivityAttributes.ContentState(endsAt: .now, passed: true)
            await activity.end(.init(state: state, staleDate: nil), dismissalPolicy: .after(.now.addingTimeInterval(30 * 60)))
        }
        return .result()
    }
}
