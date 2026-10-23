import Foundation

/// Patterns for the Progress tab (S7.3), from the person's own logs: when cravings hit, what sets them off,
/// and how this week compares with earlier ones. Slips show here and nowhere else.
public struct Insights: Sendable {
    /// One log, reduced to what insights need.
    public struct Point: Sendable, Equatable {
        public var timestamp: Date
        public var kind: LogKind
        public var outcome: CravingOutcome?
        public var trigger: Trigger?

        public init(timestamp: Date, kind: LogKind, outcome: CravingOutcome? = nil, trigger: Trigger? = nil) {
            self.timestamp = timestamp
            self.kind = kind
            self.outcome = outcome
            self.trigger = trigger
        }

        public init(_ entry: LogEntry) {
            self.init(timestamp: entry.timestamp, kind: entry.kind, outcome: entry.outcome, trigger: entry.trigger)
        }
    }

    public enum Series: String, Sendable, CaseIterable {
        /// Cravings, from SOS sessions and craving logs.
        case cravings
        /// Uses during prep and slips after Quit Day.
        case uses
    }

    /// Insights open once the first log is a week old and there are at least this many logs.
    public static let minimumLogs = 5
    public static let minimumDays = 7
    /// The heat map and triggers look back this far.
    public static let windowDays = 28

    public let points: [Point]
    public let now: Date
    public let calendar: Calendar

    public init(points: [Point], now: Date, calendar: Calendar = .current) {
        self.points = points.filter { $0.timestamp <= now }
        self.now = now
        self.calendar = calendar
    }

    // MARK: Readiness

    /// Whole days since the first log, capped at `minimumDays`.
    public var daysOfData: Int {
        guard let first = points.map(\.timestamp).min() else { return 0 }
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: first), to: calendar.startOfDay(for: now)).day ?? 0
        return min(max(days, 0), Self.minimumDays)
    }

    public var isReady: Bool {
        daysOfData >= Self.minimumDays && points.count >= Self.minimumLogs
    }

    /// 0…1 towards being ready, for the meter.
    public var readiness: Double {
        let days = Double(daysOfData) / Double(Self.minimumDays)
        let logs = Double(min(points.count, Self.minimumLogs)) / Double(Self.minimumLogs)
        return min(days, logs)
    }

    // MARK: Heat map

    /// Counts by time of day (rows, in `TimeOfDay.allCases` order) and weekday (columns, Monday first).
    public func heatMap(_ series: Series) -> [[Int]] {
        var grid = Array(repeating: Array(repeating: 0, count: 7), count: TimeOfDay.allCases.count)
        for point in recent(series) {
            let row = TimeOfDay.allCases.firstIndex(of: TimeOfDay(hour: calendar.component(.hour, from: point.timestamp)))!
            grid[row][Self.mondayIndex(point.timestamp, calendar: calendar)] += 1
        }
        return grid
    }

    /// The busiest stretch, for the line under the heat map: weekdays or weekends, and a time of day.
    public struct Peak: Sendable, Equatable {
        public let weekend: Bool
        public let time: TimeOfDay
    }

    /// The two busiest stretches, busiest first. Weekend cells count per day so two days can match five.
    public func peaks(_ series: Series) -> [Peak] {
        let grid = heatMap(series)
        var scores: [(Peak, Double)] = []
        for (row, time) in TimeOfDay.allCases.enumerated() {
            let weekdays = grid[row][0..<5].reduce(0, +)
            let weekends = grid[row][5..<7].reduce(0, +)
            if weekdays > 0 { scores.append((Peak(weekend: false, time: time), Double(weekdays) / 5)) }
            if weekends > 0 { scores.append((Peak(weekend: true, time: time), Double(weekends) / 2)) }
        }
        return scores.sorted { $0.1 > $1.1 }.prefix(2).map(\.0)
    }

    // MARK: Triggers

    public struct TriggerCount: Sendable, Equatable {
        public let trigger: Trigger
        public let count: Int
    }

    /// Triggers tagged on cravings and slips, most common first.
    public var topTriggers: [TriggerCount] {
        let tagged = points.filter { $0.timestamp >= windowStart && $0.kind != .use }.compactMap(\.trigger)
        let counts = Dictionary(tagged.map { ($0, 1) }, uniquingKeysWith: +)
        return counts
            .map { TriggerCount(trigger: $0.key, count: $0.value) }
            .sorted { $0.count != $1.count ? $0.count > $1.count : Trigger.allCases.firstIndex(of: $0.trigger)! < Trigger.allCases.firstIndex(of: $1.trigger)! }
            .prefix(5)
            .map { $0 }
    }

    public var taggedCount: Int {
        points.filter { $0.timestamp >= windowStart && $0.kind != .use && $0.trigger != nil }.count
    }

    // MARK: Weeks

    public struct Week: Sendable, Equatable {
        public let start: Date
        public let cravings: Int
        public let riddenOut: Int
        public let isCurrent: Bool
    }

    /// The current calendar week and the ones before it, oldest first.
    public func weeks(count: Int = 3) -> [Week] {
        guard let current = calendar.dateInterval(of: .weekOfYear, for: now) else { return [] }
        return (0..<count).reversed().compactMap { back in
            guard let start = calendar.date(byAdding: .weekOfYear, value: -back, to: current.start),
                  let interval = calendar.dateInterval(of: .weekOfYear, for: start) else { return nil }
            let cravings = points.filter { $0.kind == .craving && interval.contains($0.timestamp) }
            return Week(start: interval.start, cravings: cravings.count,
                        riddenOut: cravings.filter { $0.outcome == .passed }.count, isCurrent: back == 0)
        }
    }

    /// Change in cravings this week against last week, as a fraction (-0.36 means 36% fewer). nil without last week's data.
    public var weekOnWeekChange: Double? {
        let weeks = weeks(count: 2)
        guard weeks.count == 2, weeks[0].cravings > 0 else { return nil }
        return Double(weeks[1].cravings - weeks[0].cravings) / Double(weeks[0].cravings)
    }

    // MARK: Helpers

    private var windowStart: Date {
        calendar.date(byAdding: .day, value: -Self.windowDays, to: now) ?? now
    }

    private func recent(_ series: Series) -> [Point] {
        points.filter { point in
            guard point.timestamp >= windowStart else { return false }
            switch series {
            case .cravings: return point.kind == .craving
            case .uses: return point.kind == .use || point.kind == .slip
            }
        }
    }

    /// 0 for Monday … 6 for Sunday, whatever the calendar's first weekday.
    static func mondayIndex(_ date: Date, calendar: Calendar) -> Int {
        (calendar.component(.weekday, from: date) + 5) % 7
    }
}
