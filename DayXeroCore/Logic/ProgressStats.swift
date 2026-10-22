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

    /// Whole days from `start`'s day to `date`'s day.
    public func days(from start: Date, to date: Date) -> Int {
        calendar.dateComponents([.day], from: day(containing: start), to: day(containing: date)).day ?? 0
    }
}

/// Home and Progress numbers. Slips never reduce days clear or the progress visual.
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
        clock.day(containing: now) < clock.day(containing: quitDay)
    }

    /// Days until Quit Day during prep; 0 on and after Quit Day.
    public func daysUntilQuitDay(at now: Date) -> Int {
        max(clock.days(from: now, to: quitDay), 0)
    }

    /// Days clear counts Quit Day itself as day 1. Logged slips are deliberately not an input.
    public func daysClear(at now: Date) -> Int {
        isPrep(at: now) ? 0 : clock.days(from: quitDay, to: now) + 1
    }

    /// Time since the start of Quit Day, in days (fractional). Zero during prep.
    public func elapsedDays(at now: Date) -> Double {
        let start = clock.day(containing: quitDay)
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
