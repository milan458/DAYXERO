import Foundation

/// One logged slip as plain values, for the counters (S27.9).
public struct SlipRecord: Sendable, Equatable {
    public let timestamp: Date
    /// nil when the person didn't say; the slip then counts against their main product.
    public let product: Product?
    public let amount: SlipAmount?

    public init(timestamp: Date, product: Product? = nil, amount: SlipAmount? = nil) {
        self.timestamp = timestamp
        self.product = product
        self.amount = amount
    }
}

/// Rules for slips (S8). A slip never changes days since Quit Day, the Home hero or milestones. Since S27.9 it does
/// take its units off "not smoked", "puffs not taken" and "pouches not used", so those numbers stay true.
public enum Slips {
    /// From this many slips in one day, the talk-through ends with an offer of NRT help or another look at the plan.
    public static let toughDayThreshold = 3
    /// Slips on this many of the last `freshStartWindow` days bring Jelli's offer of a fresh Quit Day (S27.9).
    public static let freshStartThreshold = 4
    public static let freshStartWindow = 7

    /// Units a slip takes off the "not used" counter. The amount is a rough answer ("a few puffs", "one session",
    /// "more"), so these are deliberately low estimates. No answer counts as one unit.
    public static func units(_ amount: SlipAmount?, product: Product) -> Int {
        guard let amount else { return 1 }
        switch (product, amount) {
        case (.vape, .aLittle): return 3
        case (.vape, .one): return 10
        case (.vape, .more): return 20
        case (_, .aLittle), (_, .one): return 1
        case (_, .more): return 2
        }
    }

    /// Days among the last `freshStartWindow` (today included) with at least one slip on or after Quit Day.
    public static func slipDays(timestamps: [Date], quitDay: Date, now: Date, clock: DayClock) -> Int {
        let today = clock.day(containing: now)
        let quit = clock.startOfDate(quitDay)
        guard let first = clock.calendar.date(byAdding: .day, value: -(freshStartWindow - 1), to: today) else { return 0 }
        let start = max(first, quit)
        let days = Set(timestamps.map { clock.day(containing: $0) }.filter { $0 >= start && $0 <= today })
        return days.count
    }

    /// Whether Jelli offers a fresh Quit Day. A new Quit Day keeps every log; slips before it stop counting here.
    public static func offersFreshStart(timestamps: [Date], quitDay: Date, now: Date, clock: DayClock) -> Bool {
        slipDays(timestamps: timestamps, quitDay: quitDay, now: now, clock: clock) >= freshStartThreshold
    }

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
