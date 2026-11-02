import Foundation
import SwiftData

/// One-tap use logging from the app, the widget and Siri (S7.1). Before Quit Day a use is tracking;
/// from Quit Day on it's a slip, which never changes days clear.
@MainActor
public enum UseLog {
    /// Whether a use at `date` counts as a slip for this person.
    public static func isSlip(profile: UserProfile?, at date: Date = .now) -> Bool {
        guard let profile else { return false }
        let stats = ProgressStats(quitDay: profile.quitDay, baselines: [], clock: DayClock(boundaryHour: profile.dayBoundaryHour))
        return !stats.isPrep(at: date)
    }

    @discardableResult
    public static func log(_ product: Product, at date: Date = .now, in context: ModelContext) -> LogEntry {
        let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first
        let entry = LogEntry(kind: isSlip(profile: profile, at: date) ? .slip : .use, product: product, timestamp: date)
        context.insert(entry)
        try? context.save()
        return entry
    }

    /// Logs several uses at once (UX-05): "+5" and "+10" for puffs, so a vape day isn't a hundred single taps.
    /// Each is its own entry at the same moment, so every count, chart and insight reads them as before.
    @discardableResult
    public static func log(_ product: Product, count: Int, at date: Date = .now, in context: ModelContext) -> [LogEntry] {
        guard count > 0 else { return [] }
        let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first
        let kind: LogKind = isSlip(profile: profile, at: date) ? .slip : .use
        let entries = (0..<count).map { _ in LogEntry(kind: kind, product: product, timestamp: date) }
        for entry in entries { context.insert(entry) }
        try? context.save()
        return entries
    }

    /// Uses of `product` logged on the day containing `date`, and on the day before.
    public static func counts(_ product: Product, at date: Date = .now, in context: ModelContext,
                              clock: DayClock = DayClock(boundaryHour: 4)) -> (today: Int, yesterday: Int) {
        let today = clock.day(containing: date)
        let yesterday = clock.calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let raw: String? = product.rawValue
        let descriptor = FetchDescriptor<LogEntry>(predicate: #Predicate { $0.productRaw == raw && $0.timestamp >= yesterday })
        let entries = (try? context.fetch(descriptor)) ?? []
        let todayCount = entries.filter { clock.day(containing: $0.timestamp) == today }.count
        return (todayCount, entries.count - todayCount)
    }

    public static func undo(_ entry: LogEntry, in context: ModelContext) {
        context.delete(entry)
        try? context.save()
    }

    /// Undoes a batch logged with `log(_:count:at:in:)`.
    public static func undo(_ entries: [LogEntry], in context: ModelContext) {
        for entry in entries { context.delete(entry) }
        try? context.save()
    }
}

/// A slip logged outside the app (Siri, the widget) asks for Jelli's if-then planner the next time the app opens
/// (CLIN-10). Only a recent slip with no plan yet is opened.
public enum SlipPlanRequest {
    private static var defaults: UserDefaults { UserDefaults(suiteName: DataStore.appGroup) ?? .standard }
    private static let key = "log.openSlipPlan"
    /// A slip older than this doesn't open the planner by itself.
    public static let window: TimeInterval = 12 * 3600

    public static func request(at date: Date = .now) { defaults.set(date, forKey: key) }

    /// Whether a request from within `window` is waiting. Clears it either way.
    public static func consume(now: Date = .now) -> Bool {
        let requested = defaults.object(forKey: key) as? Date
        defaults.removeObject(forKey: key)
        guard let requested else { return false }
        return now.timeIntervalSince(requested) < window
    }
}

/// Asks the app to open the craving log, from Siri or a widget (S7.1).
public enum LogRequest {
    private static var defaults: UserDefaults { UserDefaults(suiteName: DataStore.appGroup) ?? .standard }
    private static let key = "log.openCraving"

    public static func requestCravingLog() { defaults.set(true, forKey: key) }

    public static func consumeCravingLog() -> Bool {
        let requested = defaults.bool(forKey: key)
        defaults.removeObject(forKey: key)
        return requested
    }
}
