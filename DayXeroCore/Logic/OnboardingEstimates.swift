import Foundation

/// Rough daily nicotine, for onboarding's baseline screen (S22). Estimates for comparison, never a dose.
public enum NicotineEstimate {
    /// Nicotine absorbed from one cigarette: about 1–1.5 mg. Benowitz NL, Jacob P. Daily intake of nicotine during
    /// cigarette smoking. Clin Pharmacol Ther. 1984;35(4):499–504. doi:10.1038/clpt.1984.67, PMID 6705448.
    public static let mgPerCigarette = 1.2
    /// Absorbed per puff of a 50 mg/ml liquid: about ten puffs of a 5% vape match one cigarette. Scales with strength.
    public static let mgPerPuffAt50 = 0.12
    /// Share of a pouch's labelled nicotine that's absorbed.
    public static let pouchAbsorbed = 0.2
    /// Used when the strength isn't known.
    public static let defaultPouchMg = 6.0
    public static let defaultVapeMgPerMl = 20.0

    /// Milligrams absorbed a day.
    public static func mgPerDay(_ product: Product, unitsPerDay: Double, strength: Double?) -> Double {
        switch product {
        case .cigarettes: unitsPerDay * mgPerCigarette
        case .vape: unitsPerDay * mgPerPuffAt50 * (strength ?? defaultVapeMgPerMl) / 50
        case .pouches: unitsPerDay * (strength ?? defaultPouchMg) * pouchAbsorbed
        }
    }

    /// The same nicotine counted in cigarettes.
    public static func cigarettes(mg: Double) -> Double { mg / mgPerCigarette }
}

/// Time spent smoking or vaping, for "time back" (S22). Pouches sit in the mouth while life goes on, so they count none.
public enum TimeSpent {
    public static let minutesPerCigarette = 6.0
    /// Each puff, with picking the vape up and putting it down.
    public static let secondsPerPuff = 6.0

    public static func hoursPerYear(_ product: Product, unitsPerDay: Double) -> Double {
        switch product {
        case .cigarettes: unitsPerDay * minutesPerCigarette * 365 / 60
        case .vape: unitsPerDay * secondsPerPuff * 365 / 3600
        case .pouches: 0
        }
    }
}

/// One-tap prices for the baseline screens (S22), so most people never open the keyboard.
/// Regions not listed get a typed price instead.
public enum PricePresets {
    private struct Region {
        let pack20: [Decimal]
        let vape: Decimal
        let vapeStep: Decimal
        let can: [Decimal]
        /// Prices round to this.
        let unit: Decimal
        /// The usual legal maximum vape strength, in mg/ml.
        let vapeStrength: Double
    }

    private static let regions: [String: Region] = [
        "INR": Region(pack20: [350, 500, 700], vape: 800, vapeStep: 50, can: [300, 400, 500], unit: 10, vapeStrength: 50),
        "USD": Region(pack20: [8, 10, 12], vape: 10, vapeStep: 1, can: [5, 6, 7], unit: 0.5, vapeStrength: 50),
        "GBP": Region(pack20: [13, 15, 17], vape: 6, vapeStep: 0.5, can: [6, 7, 8], unit: 0.5, vapeStrength: 20),
        "EUR": Region(pack20: [7, 8.5, 10], vape: 7, vapeStep: 0.5, can: [5, 6, 7], unit: 0.5, vapeStrength: 20),
        "AUD": Region(pack20: [35, 45, 55], vape: 25, vapeStep: 1, can: [20, 25, 30], unit: 1, vapeStrength: 20),
        "CAD": Region(pack20: [14, 17, 20], vape: 12, vapeStep: 1, can: [10, 13, 15], unit: 1, vapeStrength: 20),
    ]

    /// Three typical prices for a pack of `size` (1 for a single cigarette). Empty where we don't know prices.
    public static func pack(currency: String, size: Double) -> [Decimal] {
        guard let region = regions[currency], size > 0 else { return [] }
        // A single cigarette rounds to a finer step than a pack.
        let unit = size == 1 ? region.unit / 10 : region.unit
        return region.pack20.map { round($0 * Decimal(size) / 20, to: unit) }
    }

    /// A pod or disposable's usual price and the stepper's step.
    public static func vape(currency: String) -> (price: Decimal, step: Decimal)? {
        regions[currency].map { ($0.vape, $0.vapeStep) }
    }

    public static func can(currency: String) -> [Decimal] { regions[currency]?.can ?? [] }

    /// 50 mg/ml where it's sold, 20 where the law caps it (UK, EU, Canada, Australia).
    public static func vapeStrength(currency: String) -> Double { regions[currency]?.vapeStrength ?? NicotineEstimate.defaultVapeMgPerMl }

    private static func round(_ value: Decimal, to unit: Decimal) -> Decimal {
        guard unit > 0 else { return value }
        var steps = value / unit
        var rounded = Decimal()
        NSDecimalRound(&rounded, &steps, 0, .plain)
        return max(rounded, 1) * unit
    }
}
