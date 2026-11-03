import Foundation

/// What's free and what comes with the full program (Milan, 3 Nov 2026, BET-1; replaces MON-01's "Prep 1 to 3 free").
///
/// | Free | Full program (7-day trial, then yearly; or monthly, or lifetime) |
/// | --- | --- |
/// | Each prep session's intro and its first two cards; the counter, Craving SOS, the 60-second breathing timer, evening check-ins | The rest of each prep session (activities, cards 3 and 4, the audio, the mission), Day Xero, Weeks 1–4, Jelli's voice coaching, the if-then slip planner, the 12-week NRT scheduler, trigger heatmaps |
///
/// A free user who reads a prep session's two free cards meets the prep-day paywall. That counts as their day's prep:
/// the next prep session opens tomorrow, and after subscribing every prep session is open in full as catch-up.
/// Craving SOS stays free; only Jelli's voice in it is part of the full program (Milan, 2 Nov 2026).
public enum FullProgram {
    /// How a session opens for someone.
    public enum Access: Equatable, Sendable {
        /// The whole session.
        case full
        /// The intro and the first `previewCards` cards, then the prep-day paywall.
        case preview
        /// Nothing until they subscribe: the upgrade sheet instead.
        case locked
    }

    /// The prep sessions a free user can open for their free part.
    public static let previewSessionIds: Set<String> = ["P1", "P2", "P3", "P4", "P5", "P6", "P7"]
    /// Cards a free user reads in each prep session before the paywall.
    public static let previewCards = 2
    /// The trial on the yearly plan. The App Store decides who gets one; this is what the screens promise.
    public static let trialDays = 7

    /// Whether a session has a free part (every prep session).
    public static func isPreviewable(sessionId: String) -> Bool {
        previewSessionIds.contains(sessionId)
    }

    /// How a session opens. A session finished while subscribed stays open in full for replay.
    public static func access(sessionId: String, isPro: Bool, completed: Bool = false) -> Access {
        if isPro || completed { return .full }
        return isPreviewable(sessionId: sessionId) ? .preview : .locked
    }

    /// Whether a session can't be opened at all without the full program (Day Xero onwards, for a free user).
    public static func needsUpgrade(sessionId: String, isPro: Bool, completed: Bool = false) -> Bool {
        access(sessionId: sessionId, isPro: isPro, completed: completed) == .locked
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

    /// When a trial bought today ends, and how that falls against the Quit Day: the paywall says both.
    public static func trialEnd(startingOn start: Date, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: trialDays, to: start) ?? start
    }

    /// Whole days between the Quit Day and the trial's end: positive when it ends after the Quit Day.
    public static func trialEndsDaysAfterQuitDay(trialEnd: Date, quitDay: Date, calendar: Calendar = .current) -> Int {
        calendar.dateComponents([.day], from: calendar.startOfDay(for: quitDay), to: calendar.startOfDay(for: trialEnd)).day ?? 0
    }

    // MARK: The yearly offer by day since download

    /// Days since download on which the yearly plan is $29.99 instead of $39.99, with the same 7-day trial and
    /// renewing at $29.99 (Milan, 3 Nov 2026). The download day is day 1.
    public static let offerDays: Set<Int> = [4, 6]
    /// What the offer takes off the yearly price, for the badge.
    public static let offerPercent = 25

    /// The download day is day 1, counted on the person's own day clock, so "today only" ends when their day ends.
    public static func dayNumber(installedOn installed: Date, now: Date, clock: DayClock) -> Int {
        let days = clock.calendar.dateComponents([.day], from: clock.day(containing: installed), to: clock.day(containing: now)).day ?? 0
        return max(days, 0) + 1
    }

    /// Whether today is one of the yearly offer's days.
    public static func isOfferDay(installedOn installed: Date?, now: Date, clock: DayClock) -> Bool {
        guard let installed else { return false }
        return offerDays.contains(dayNumber(installedOn: installed, now: now, clock: clock))
    }
}

/// The day DayXero was first opened on this phone: day 1 for the yearly offer (`FullProgram.offerDays`).
public enum InstallDay {
    public static let key = "dx.firstLaunch"

    public static func date(in defaults: UserDefaults = .standard) -> Date? {
        defaults.object(forKey: key) as? Date
    }

    /// Records the first launch once; later launches leave it alone.
    public static func recordIfNeeded(now: Date = .now, in defaults: UserDefaults = .standard) {
        guard defaults.object(forKey: key) == nil else { return }
        defaults.set(now, forKey: key)
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
