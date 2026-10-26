import Foundation

/// When this person's cravings tend to hit (S14.2), learnt on the phone from their own logs.
/// A 7 × 48 grid (weekday × half hour) where each event adds weight that halves every 7 days,
/// smoothed by ±30 minutes. A window is a run of busy slots with at least 3 events in the last 14 days.
public enum CravingPredictor {
    public struct Event: Sendable, Equatable {
        public let date: Date
        public let trigger: Trigger?

        public init(date: Date, trigger: Trigger? = nil) {
            self.date = date
            self.trigger = trigger
        }
    }

    public struct Window: Sendable, Equatable, Codable {
        public let start: Date
        public let end: Date
        /// 0...1, relative to this person's own busiest time.
        public let confidence: Double
        public let trigger: Trigger?

        public init(start: Date, end: Date, confidence: Double, trigger: Trigger?) {
            self.start = start
            self.end = end
            self.confidence = confidence
            self.trigger = trigger
        }
    }

    public static let slotsPerDay = 48
    public static let halfLifeDays = 7.0
    /// Slots at or above this share of the person's busiest slot count as busy.
    public static let threshold = 0.5
    public static let minimumEvents = 3
    public static let recentDays = 14.0
    public static let maxWindowsPerDay = 3

    /// Up to three windows on the day containing `day`, earliest first.
    public static func windows(on day: Date, events: [Event], now: Date, calendar: Calendar = .current) -> [Window] {
        let recent = events.filter { $0.date <= now && now.timeIntervalSince($0.date) <= recentDays * 86_400 }
        guard recent.count >= minimumEvents else { return [] }

        // Weighted grid with exponential decay.
        var grid = Array(repeating: Array(repeating: 0.0, count: slotsPerDay), count: 7)
        for event in events where event.date <= now {
            let age = now.timeIntervalSince(event.date) / 86_400
            let weight = pow(0.5, age / halfLifeDays)
            let (weekday, slot) = position(of: event.date, calendar: calendar)
            grid[weekday][slot] += weight
        }
        // Weekdays and weekends pool together while data is thin, so a 3pm habit shows every day.
        let pooled = recent.count < 21
        let weekday = position(of: day, calendar: calendar).weekday
        var row = Array(repeating: 0.0, count: slotsPerDay)
        if pooled {
            for d in 0..<7 { for s in 0..<slotsPerDay { row[s] += grid[d][s] / 7 } }
        } else {
            let weekend = isWeekend(weekday)
            let days = (0..<7).filter { isWeekend($0) == weekend }
            for d in days { for s in 0..<slotsPerDay { row[s] += grid[d][s] / Double(days.count) } }
        }
        // ±30 minutes of smoothing.
        var smoothed = Array(repeating: 0.0, count: slotsPerDay)
        for s in 0..<slotsPerDay {
            let before: Double = row[max(s - 1, 0)] * 0.5
            let after: Double = row[min(s + 1, slotsPerDay - 1)] * 0.5
            smoothed[s] = (before + row[s] + after) / 2
        }
        guard let peak = smoothed.max(), peak > 0 else { return [] }

        // Runs of busy slots.
        var runs: [(Int, Int)] = []
        var start: Int?
        for s in 0...slotsPerDay {
            let busy = s < slotsPerDay && smoothed[s] >= peak * threshold
            if busy, start == nil { start = s }
            if !busy, let begun = start { runs.append((begun, s)); start = nil }
        }
        let dayStart = calendar.startOfDay(for: day)
        let result: [Window] = runs.compactMap { run -> Window? in
            let begin = dayStart.addingTimeInterval(Double(run.0) * 1800)
            let finish = dayStart.addingTimeInterval(Double(run.1) * 1800)
            // At least three recent events fell in this stretch of the day (on any day).
            let inside = recent.filter { event in
                let slot = position(of: event.date, calendar: calendar).slot
                return slot >= run.0 - 1 && slot < run.1 + 1
            }
            guard inside.count >= minimumEvents else { return nil }
            let score = smoothed[run.0..<run.1].max() ?? 0
            return Window(start: begin, end: finish, confidence: min(score / peak, 1), trigger: topTrigger(inside))
        }
        return Array(result.sorted { $0.confidence > $1.confidence }.prefix(maxWindowsPerDay)).sorted { $0.start < $1.start }
    }

    /// The window happening now or next, today or tomorrow.
    public static func nextWindow(events: [Event], now: Date, calendar: Calendar = .current) -> Window? {
        if let today = windows(on: now, events: events, now: now, calendar: calendar).first(where: { $0.end > now }) {
            return today
        }
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) else { return nil }
        return windows(on: tomorrow, events: events, now: now, calendar: calendar).first
    }

    private static func position(of date: Date, calendar: Calendar) -> (weekday: Int, slot: Int) {
        let c = calendar.dateComponents([.weekday, .hour, .minute], from: date)
        return (((c.weekday ?? 1) - 1) % 7, min(((c.hour ?? 0) * 60 + (c.minute ?? 0)) / 30, slotsPerDay - 1))
    }

    /// Sunday is 0, Saturday 6.
    private static func isWeekend(_ weekday: Int) -> Bool { weekday == 0 || weekday == 6 }

    private static func topTrigger(_ events: [Event]) -> Trigger? {
        let counts = Dictionary(grouping: events.compactMap(\.trigger), by: { $0 }).mapValues(\.count)
        return counts.max { $0.value < $1.value }?.key
    }
}
