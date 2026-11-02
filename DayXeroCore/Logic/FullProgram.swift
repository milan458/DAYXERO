import Foundation

/// What's free forever and what comes with the full program (MON-01, 2 Nov 2026). Replaces decisions 15 and 23
/// (the whole prep week and Day Xero free, the trial sold only from Quit Day): the free taste is Prep 1 to 3, and
/// the 7-day trial is sold at the Prep 4 paywall, whenever the Quit Day is.
///
/// | Free forever | Full program (7-day trial, then yearly) |
/// | --- | --- |
/// | Prep 1–3, the counter, Craving SOS, the 60-second breathing timer | Prep 4–7, Day Xero, Weeks 1–4, Jelli's voice coaching, the if-then slip planner, the 12-week NRT scheduler, trigger heatmaps |
///
/// Craving SOS stays free; only Jelli's voice in it is part of the full program (Milan, 2 Nov 2026).
public enum FullProgram {
    /// The free taste of prep.
    public static let freeSessionIds: Set<String> = ["P1", "P2", "P3"]
    /// The first session behind the paywall: where the trial is offered.
    public static let firstPaidSessionId = "P4"
    /// The trial on the yearly plan. The App Store decides who gets one; this is what the screens promise.
    public static let trialDays = 7

    /// Whether a program session is part of the free tier.
    public static func isFree(sessionId: String) -> Bool {
        freeSessionIds.contains(sessionId)
    }

    /// Whether opening a session needs the full program. A session finished while subscribed stays open for replay.
    public static func needsUpgrade(sessionId: String, isPro: Bool, completed: Bool = false) -> Bool {
        !isPro && !completed && !isFree(sessionId: sessionId)
    }

    /// The paid features outside the program path. Each one has a free counterpart that keeps working.
    public enum Feature: String, CaseIterable, Sendable {
        /// Jelli's and the breathing coach's spoken cues. Free: the same sessions with subtitles, silent.
        case voiceCoaching
        /// Saving an if-then plan after a slip. Free: logging the slip, and the "nothing resets" message.
        case ifThenPlanner
        /// The NRT plan with its 12-week step-down. Free: nothing is taken from a plan already made.
        case nrtScheduler
        /// The craving heat map, triggers and weekly trend on Progress. Free: when you've logged so far.
        case triggerHeatmaps
    }

    public static func has(_ feature: Feature, isPro: Bool) -> Bool { isPro }

    /// When a trial bought today ends, and how that falls against the Quit Day: the paywall says both (MON-01).
    public static func trialEnd(startingOn start: Date, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: trialDays, to: start) ?? start
    }

    /// Whole days between the Quit Day and the trial's end: positive when it ends after the Quit Day.
    public static func trialEndsDaysAfterQuitDay(trialEnd: Date, quitDay: Date, calendar: Calendar = .current) -> Int {
        calendar.dateComponents([.day], from: calendar.startOfDay(for: quitDay), to: calendar.startOfDay(for: trialEnd)).day ?? 0
    }

    /// The first day Prep 4 can open for someone who starts Prep 1 on `firstDay`: three days later, one prep session a
    /// day. The plan screen in onboarding uses it to say when the trial would start.
    public static func earliestPaywallDay(firstDay: Date, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: freeSessionIds.count, to: calendar.startOfDay(for: firstDay)) ?? firstDay
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
