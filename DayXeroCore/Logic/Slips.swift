import Foundation

/// Rules for slips (S8). A slip never changes days clear, the Home hero or milestones; it only adds to insights.
public enum Slips {
    /// From this many slips in one day, the talk-through ends with an offer of NRT help or another look at the plan.
    public static let toughDayThreshold = 3

    /// Slips logged on the day containing `now`.
    public static func count(onDayOf now: Date, timestamps: [Date], clock: DayClock) -> Int {
        let today = clock.day(containing: now)
        return timestamps.filter { clock.day(containing: $0) == today }.count
    }

    public static func isToughDay(slipsToday: Int) -> Bool {
        slipsToday >= toughDayThreshold
    }

    /// "When?" in the talk-through.
    public enum When: String, CaseIterable, Sendable {
        case justNow, earlierToday, yesterday
    }

    /// Moves a slip's time to match the answer to "When?". "Just now" keeps the time it was logged.
    public static func time(_ when: When, loggedAt: Date, clock: DayClock) -> Date {
        switch when {
        case .justNow:
            return loggedAt
        case .earlierToday:
            // Halfway between when the day began (at the boundary hour) and when it was logged.
            let day = clock.day(containing: loggedAt)
            let start = clock.calendar.date(byAdding: .hour, value: clock.boundaryHour, to: day) ?? day
            return start.addingTimeInterval(loggedAt.timeIntervalSince(start) / 2)
        case .yesterday:
            return clock.calendar.date(byAdding: .day, value: -1, to: loggedAt) ?? loggedAt
        }
    }
}
