import Foundation

/// The swap trap on the prep tracker (CLIN-05, 2 Nov 2026): cigarettes or vape puffs going down while pouches go up.
/// Total nicotine hasn't fallen, it has moved, and the pouches then need quitting too. Compares the last few full days
/// logged against the person's own baseline from onboarding.
public enum SwapTrap {
    public struct Finding: Sendable, Equatable {
        /// Cigarettes or vape, whichever fell.
        public let falling: [Product]
        public let rising: Product
    }

    /// Full days looked at, ending yesterday. Today is still going, so it doesn't count.
    public static let windowDays = 3
    /// At least this many full days logged before anything is said.
    public static let minimumDays = 2
    /// Down to this share of the baseline or below counts as falling…
    public static let fallShare = 0.75
    /// …and up by this share, and by at least `minimumRise` a day, counts as rising.
    public static let riseShare = 1.25
    public static let minimumRise = 2.0

    /// - Parameters:
    ///   - uses: every logged use (not cravings), any product.
    ///   - baselines: units a day from onboarding, per product.
    ///   - since: when tracking began (the profile's creation); days before it aren't counted as zero.
    public static func check(uses: [(product: Product, time: Date)], baselines: [Product: Double], since: Date,
                             now: Date, clock: DayClock) -> Finding? {
        let today = clock.day(containing: now)
        let firstTracked = clock.day(containing: since)
        let cal = clock.calendar
        let days: [Date] = (1...windowDays).compactMap { cal.date(byAdding: .day, value: -$0, to: today) }
            .filter { $0 >= firstTracked }
        guard days.count >= minimumDays else { return nil }
        let window = Set(days)

        func average(_ product: Product) -> Double {
            Double(uses.filter { $0.product == product && window.contains(clock.day(containing: $0.time)) }.count) / Double(days.count)
        }

        guard let pouchBase = baselines[.pouches], pouchBase > 0 else { return nil }
        let pouches = average(.pouches)
        guard pouches >= max(pouchBase * riseShare, pouchBase + minimumRise) else { return nil }
        let falling = [Product.cigarettes, .vape].filter { product in
            guard let base = baselines[product], base > 0 else { return false }
            return average(product) <= base * fallShare
        }
        return falling.isEmpty ? nil : Finding(falling: falling, rising: .pouches)
    }
}
