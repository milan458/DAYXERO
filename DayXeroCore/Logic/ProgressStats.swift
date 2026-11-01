import Foundation

/// A product's pre-quit baseline, as plain values for calculations.
public struct Baseline: Sendable, Equatable {
    public let product: Product
    public let unitsPerDay: Double
    public let pricePerPurchase: Decimal
    public let unitsPerPurchase: Double

    public init(product: Product, unitsPerDay: Double, pricePerPurchase: Decimal, unitsPerPurchase: Double) {
        self.product = product
        self.unitsPerDay = unitsPerDay
        self.pricePerPurchase = pricePerPurchase
        self.unitsPerPurchase = unitsPerPurchase
    }

    public var costPerDay: Decimal {
        guard unitsPerPurchase > 0 else { return 0 }
        return pricePerPurchase * Decimal(unitsPerDay / unitsPerPurchase)
    }
}

/// Program "day" arithmetic that respects the user's day boundary.
public struct DayClock: Sendable {
    public let calendar: Calendar
    /// Hour (0–23) when the day rolls over. 4 means 1am still counts as yesterday.
    public let boundaryHour: Int

    public init(calendar: Calendar = .current, boundaryHour: Int) {
        self.calendar = calendar
        self.boundaryHour = min(max(boundaryHour, 0), 23)
    }

    /// The calendar day a moment belongs to, as the start of that day.
    public func day(containing date: Date) -> Date {
        let shifted = calendar.date(byAdding: .hour, value: -boundaryHour, to: date) ?? date
        return calendar.startOfDay(for: shifted)
    }

    /// Start of a calendar date such as Quit Day. Dates aren't moments, so the boundary doesn't shift them.
    public func startOfDate(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    /// Whole days from the day `moment` falls in to the calendar date `date`.
    public func days(from moment: Date, toDate date: Date) -> Int {
        calendar.dateComponents([.day], from: day(containing: moment), to: startOfDate(date)).day ?? 0
    }

    /// Whole days from the calendar date `date` to the day `moment` falls in.
    public func days(fromDate date: Date, to moment: Date) -> Int {
        calendar.dateComponents([.day], from: startOfDate(date), to: day(containing: moment)).day ?? 0
    }
}

/// Home and Progress numbers. Slips never reduce days since Quit Day or the progress visual; since S27.9 they do
/// reduce units avoided.
public struct ProgressStats: Sendable {
    public let quitDay: Date
    public let baselines: [Baseline]
    public let clock: DayClock

    public init(quitDay: Date, baselines: [Baseline], clock: DayClock) {
        self.quitDay = quitDay
        self.baselines = baselines
        self.clock = clock
    }

    public func isPrep(at now: Date) -> Bool {
        clock.day(containing: now) < clock.startOfDate(quitDay)
    }

    /// Days until Quit Day during prep; 0 on and after Quit Day.
    public func daysUntilQuitDay(at now: Date) -> Int {
        max(clock.days(from: now, toDate: quitDay), 0)
    }

    /// Days since Quit Day, counting Quit Day itself as day 1 (shown as "days since Quit Day", S27.9). Logged slips
    /// are deliberately not an input: this number never resets.
    public func daysClear(at now: Date) -> Int {
        isPrep(at: now) ? 0 : clock.days(fromDate: quitDay, to: now) + 1
    }

    /// Time since Quit Day began (its date plus the day boundary), in days. Zero during prep.
    public func elapsedDays(at now: Date) -> Double {
        let start = clock.startOfDate(quitDay)
        let realStart = clock.calendar.date(byAdding: .hour, value: clock.boundaryHour, to: start) ?? start
        return max(now.timeIntervalSince(realStart) / 86_400, 0)
    }

    /// Units not used, per product, since Quit Day.
    public func unitsAvoided(at now: Date) -> [Product: Int] {
        let elapsed = elapsedDays(at: now)
        var result: [Product: Int] = [:]
        for baseline in baselines {
            result[baseline.product, default: 0] += Int((baseline.unitsPerDay * elapsed).rounded(.down))
        }
        return result
    }

    /// Units not used since Quit Day, less what logged slips used (S27.9), never below zero. A slip with no product
    /// counts against `primary`; slips before Quit Day or after `now` are not counted.
    public func unitsAvoided(at now: Date, slips: [SlipRecord], primary: Product?) -> [Product: Int] {
        var result = unitsAvoided(at: now)
        let quit = clock.startOfDate(quitDay)
        for slip in slips where clock.day(containing: slip.timestamp) >= quit && slip.timestamp <= now {
            guard let product = slip.product ?? primary, let current = result[product] else { continue }
            result[product] = max(current - Slips.units(slip.amount, product: product), 0)
        }
        return result
    }

    /// Money kept across all products since Quit Day, rounded down to cents.
    public func moneyKept(at now: Date) -> Decimal {
        let elapsed = Decimal(elapsedDays(at: now))
        let total = baselines.reduce(Decimal(0)) { $0 + $1.costPerDay * elapsed }
        var value = total
        var rounded = Decimal()
        NSDecimalRound(&rounded, &value, 2, .down)
        return rounded
    }

    /// Projected money kept per year, for the plan reveal.
    public var moneyPerYear: Decimal {
        baselines.reduce(Decimal(0)) { $0 + $1.costPerDay } * 365
    }
}
