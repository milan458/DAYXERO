import Foundation

/// What's free forever and what comes with the full program (Milan, 16 Nov 2026). Replaces MON-01 (Prep 1 to 3
/// free, a 7-day trial sold at Prep 4): the paywall now comes straight after onboarding, with a 3-day trial on
/// the yearly plan, and no program session is free.
///
/// | Free forever | Full program (3-day trial on yearly, or 3 months) |
/// | --- | --- |
/// | The counter, Craving SOS, the calm tools with Jelli's voice, logging and the if-then slip plan | The program path (prep, Day Xero, Weeks 1–4), the 12-week NRT scheduler, trigger heatmaps |
///
/// During the free trial only Prep 1 to 3 open, one a day; the rest opens once the first payment is taken.
public enum FullProgram {
    /// Program sessions open without the full program: none.
    public static let freeSessionIds: Set<String> = []
    /// The sessions a free trial opens, one a day. Everything after waits for the trial to end.
    public static let trialSessionIds: Set<String> = ["P1", "P2", "P3"]
    /// The trial on the yearly plan. The App Store decides who gets one; this is what the screens promise.
    public static let trialDays = 3

    /// Whether a program session is part of the free tier.
    public static func isFree(sessionId: String) -> Bool {
        freeSessionIds.contains(sessionId)
    }

    /// Whether opening a session needs the full program. A session finished while subscribed stays open for replay.
    public static func needsUpgrade(sessionId: String, isPro: Bool, completed: Bool = false) -> Bool {
        !isPro && !completed && !isFree(sessionId: sessionId)
    }

    /// The features outside the program path.
    public enum Feature: String, CaseIterable, Sendable {
        /// Jelli's and the breathing coach's spoken cues in Craving SOS and the calm tools. Free.
        case voiceCoaching
        /// Saving an if-then plan after a slip. Free, with the rest of logging.
        case ifThenPlanner
        /// The NRT plan with its 12-week step-down. Paid; nothing is taken from a plan already made.
        case nrtScheduler
        /// The craving heat map, triggers and weekly trend on Progress. Paid; free shows when you've logged so far.
        case triggerHeatmaps

        /// Whether the feature needs the full program.
        public var isPaid: Bool {
            switch self {
            case .voiceCoaching, .ifThenPlanner: false
            case .nrtScheduler, .triggerHeatmaps: true
            }
        }
    }

    public static func has(_ feature: Feature, isPro: Bool) -> Bool { isPro || !feature.isPaid }

    /// When a trial bought at `start` ends, and how that falls against the Quit Day.
    public static func trialEnd(startingOn start: Date, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: trialDays, to: start) ?? start
    }

    /// Whole days between the Quit Day and the trial's end: positive when it ends after the Quit Day.
    public static func trialEndsDaysAfterQuitDay(trialEnd: Date, quitDay: Date, calendar: Calendar = .current) -> Int {
        calendar.dateComponents([.day], from: calendar.startOfDay(for: quitDay), to: calendar.startOfDay(for: trialEnd)).day ?? 0
    }
}

/// The paywall's price in habit terms (MON-03): "Costs 8 days of smoking", from the person's own spend.
public struct PriceAnchor: Equatable, Sendable {
    public enum Habit: Equatable, Sendable {
        case smoking, vaping, pouches
        /// More than one product: the spend is all of them together.
        case nicotine
    }

    /// Whole days of the person's usual spend that the price adds up to, rounded up so it never understates the price.
    public let days: Int
    public let habit: Habit

    public init(days: Int, habit: Habit) {
        self.days = days
        self.habit = habit
    }

    /// Beyond this the comparison stops helping (a light user's year can cost months of spend), so it isn't shown.
    public static let maxDays = 90

    /// nil when there's nothing honest to say: no spend, a price or spend in another currency, or more than `maxDays`.
    public static func make(price: Decimal, priceCurrency: String, spendPerYear: Decimal, spendCurrency: String,
                            products: [Product]) -> PriceAnchor? {
        guard price > 0, spendPerYear > 0, !products.isEmpty,
              priceCurrency.uppercased() == spendCurrency.uppercased() else { return nil }
        let perDay = NSDecimalNumber(decimal: spendPerYear).doubleValue / 365
        guard perDay > 0 else { return nil }
        let days = max(Int((NSDecimalNumber(decimal: price).doubleValue / perDay).rounded(.up)), 1)
        guard days <= maxDays else { return nil }
        let habit: Habit = switch Set(products).count > 1 ? nil : products.first {
        case .cigarettes?: .smoking
        case .vape?: .vaping
        case .pouches?: .pouches
        case nil: .nicotine
        }
        return PriceAnchor(days: days, habit: habit)
    }
}
