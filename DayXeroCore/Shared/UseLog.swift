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
