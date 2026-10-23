import Foundation
import SwiftData

/// The SOS session in progress, kept in the App Group so intents (Siri, Control Center, the Live Activity's
/// "It passed" button) can see and finish it (S6.4, S6.5).
public enum SOSState {
    private static var defaults: UserDefaults { UserDefaults(suiteName: DataStore.appGroup) ?? .standard }
    private static let startedKey = "sos.startedAt"
    private static let requestKey = "sos.openRequest"
    private static let outsideKey = "sos.finishedOutside"

    /// When the session in progress started, or nil when none is running.
    public static var startedAt: Date? {
        get { defaults.object(forKey: startedKey) as? Date }
        set { defaults.set(newValue, forKey: startedKey) }
    }

    /// Asks the app to open a session next time it's active; `source` is for analytics.
    public static func requestOpen(source: String) {
        defaults.set(source, forKey: requestKey)
    }

    /// The pending open request's source, cleared once read.
    public static func consumeOpenRequest() -> String? {
        let source = defaults.string(forKey: requestKey)
        defaults.removeObject(forKey: requestKey)
        return source
    }

    /// Set when the session was finished outside the app (the Live Activity's "It passed").
    public static func consumeFinishedOutside() -> CravingOutcome? {
        let raw = defaults.string(forKey: outsideKey)
        defaults.removeObject(forKey: outsideKey)
        return raw.flatMap(CravingOutcome.init(rawValue:))
    }

    static func markFinishedOutside(_ outcome: CravingOutcome) {
        defaults.set(outcome.rawValue, forKey: outsideKey)
    }
}

/// Saves SOS sessions (S6.6). Each session is one log entry, identified by its start time, written as soon as
/// the outcome is known; the optional trigger and strength are added afterwards.
@MainActor
public enum CravingLog {
    public static func record(_ outcome: CravingOutcome, startedAt: Date, endedAt: Date = .now, in context: ModelContext) {
        let entry = entry(startedAt: startedAt, in: context) ?? {
            let new = LogEntry(kind: outcome == .slipped ? .slip : .craving, timestamp: startedAt)
            context.insert(new)
            return new
        }()
        entry.kindRaw = (outcome == .slipped ? LogKind.slip : .craving).rawValue
        entry.outcome = outcome
        entry.sosDurationSeconds = max(endedAt.timeIntervalSince(startedAt), 0)
        try? context.save()
    }

    public static func annotate(startedAt: Date, trigger: Trigger?, intensity: Int?, in context: ModelContext) {
        guard let entry = entry(startedAt: startedAt, in: context) else { return }
        entry.triggerRaw = trigger?.rawValue
        entry.intensity = intensity
        try? context.save()
    }

    public static func entry(startedAt: Date, in context: ModelContext) -> LogEntry? {
        let descriptor = FetchDescriptor<LogEntry>(predicate: #Predicate { $0.timestamp == startedAt })
        return try? context.fetch(descriptor).first
    }
}

/// Hooks the app fills in at launch, so intents compiled into both the app and the widget extension can reach
/// app-only work (the store it has open, ending the Live Activity, presenting the session).
@MainActor
public enum SOSBridge {
    public static var container: ModelContainer?
    public static var endLiveActivity: (@MainActor () async -> Void)?
    public static var openSession: (@MainActor (String) -> Void)?

    /// "It passed" from the Lock Screen or Dynamic Island: save the craving and end the countdown.
    public static func passedOutside() async {
        if let start = SOSState.startedAt, let container = container ?? (try? DataStore.makeContainer()) {
            CravingLog.record(.passed, startedAt: start, in: container.mainContext)
            SOSState.markFinishedOutside(.passed)
        }
        SOSState.startedAt = nil
        await endLiveActivity?()
    }

    /// Siri, Shortcuts, Control Center: open a session now if the app is running, or as soon as it is.
    public static func requestSession(source: String) {
        if let openSession {
            openSession(source)
        } else {
            SOSState.requestOpen(source: source)
        }
    }
}
