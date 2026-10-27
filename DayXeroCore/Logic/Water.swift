import Foundation
import SwiftData

/// Water: goal maths, drinks, daily totals and logging (S7.5), from DAYXERO_NOTIFICATIONS_WATER_HANDOFF.md, part A.
/// Copy rule: water gives your hands and mouth something to do; it doesn't flush nicotine or cure cravings.

public enum WaterActivity: String, CaseIterable, Sendable {
    case mostlySitting, onMyFeet, worksOut, veryActive

    public var title: LocalizedStringResource {
        switch self {
        case .mostlySitting: "Mostly sitting"
        case .onMyFeet: "On my feet a lot"
        case .worksOut: "I work out most days"
        case .veryActive: "Very active"
        }
    }

    public var extraMl: Int {
        switch self {
        case .mostlySitting, .onMyFeet: 0
        case .worksOut: 350
        case .veryActive: 700
        }
    }
}

public enum WaterClimate: String, CaseIterable, Sendable {
    case mild, hot

    public var title: LocalizedStringResource {
        switch self {
        case .mild: "Mild or cool"
        case .hot: "Hot or humid"
        }
    }

    public var extraMl: Int { self == .hot ? 500 : 0 }
}

public enum WaterUnits: String, CaseIterable, Sendable {
    /// cm · kg, ml and litres.
    case metric
    /// ft · lb, fl oz.
    case imperial

    /// US devices start in ft · lb.
    public static func `default`(for locale: Locale = .current) -> WaterUnits {
        locale.measurementSystem == .us ? .imperial : .metric
    }
}

public enum WaterSource: String, CaseIterable, Sendable {
    case app, widget, notification, liveActivity, controlCenter, siri
}

/// The v1 drinks. All count at 100%; no alcohol and no sugary quick-logs, ever.
public enum Drink: String, CaseIterable, Sendable, Identifiable {
    case glass, bottle, tea, sparkling

    public var id: String { rawValue }

    public var name: LocalizedStringResource {
        switch self {
        case .glass: "Glass"
        case .bottle: "Bottle"
        case .tea: "Tea"
        case .sparkling: "Sparkling"
        }
    }

    public var ml: Int {
        switch self {
        case .glass: 250
        case .bottle: 500
        case .tea: 300
        case .sparkling: 330
        }
    }

    public var hydrationFactor: Double { 1.0 }

    /// The liquid's gradient, top and bottom, while this was the latest drink (A5).
    public var gradient: (top: UInt32, bottom: UInt32) {
        switch self {
        case .glass, .bottle: (0xE9EECF, 0x9DA66A)
        case .tea: (0xEBCB92, 0xA8763A)
        case .sparkling: (0xF3F5E6, 0xBFC79A)
        }
    }
}

public enum WaterGoal {
    public static let glassMl = 250
    public static let minMl = 1500
    public static let maxMl = 4000
    /// "Skip, use 8 glasses."
    public static let skippedMl = 2000
    public static let mlPerKg = 33.0
    public static let kgPerLb = 0.45359237

    public struct Breakdown: Equatable, Sendable {
        public let baseMl: Int
        public let activityMl: Int
        public let climateMl: Int
        public let rawMl: Int
        public let goalMl: Int

        public var glasses: Int { goalMl / WaterGoal.glassMl }
        /// What rounding to the nearest glass and the 1.5–4 L limits changed.
        public var roundingMl: Int { goalMl - rawMl }
    }

    /// base = weight × 33 ml, plus activity and climate, rounded to the nearest glass (halves round up),
    /// kept within 1.5–4.0 L.
    public static func calculate(weightKg: Double, activity: WaterActivity, climate: WaterClimate) -> Breakdown {
        let base = Int((weightKg * mlPerKg).rounded())
        let raw = base + activity.extraMl + climate.extraMl
        let rounded = Int((Double(raw) / Double(glassMl)).rounded(.toNearestOrAwayFromZero)) * glassMl
        return Breakdown(baseMl: base, activityMl: activity.extraMl, climateMl: climate.extraMl,
                         rawMl: raw, goalMl: min(max(rounded, minMl), maxMl))
    }

    public static func kilograms(pounds: Double) -> Double { pounds * kgPerLb }

    /// The onboarding and Settings stepper: one glass at a time, within the limits.
    public static func adjusted(_ goalMl: Int, by glasses: Int) -> Int {
        min(max(goalMl + glasses * glassMl, minMl), maxMl)
    }
}

/// The "Personalise goal" sheet's answers before they're saved (S18.5). Height isn't asked: the goal only
/// uses weight, activity and climate.
public struct WaterGoalDraft: Equatable, Sendable {
    /// Where the weight ruler starts for someone who hasn't given one.
    public static let startingWeightKg = 70.0

    public var units: WaterUnits
    public var weightKg: Double
    public var activity: WaterActivity
    public var climate: WaterClimate
    /// Set by the Adjust stepper; always wins over the calculation.
    public var override: Int?

    public init(units: WaterUnits, weightKg: Double, activity: WaterActivity, climate: WaterClimate, override: Int? = nil) {
        self.units = units
        self.weightKg = weightKg
        self.activity = activity
        self.climate = climate
        self.override = override
    }

    public init(profile: WaterProfile) {
        self.init(units: profile.units, weightKg: profile.weightKg ?? Self.startingWeightKg, activity: profile.activity,
                  climate: profile.climate, override: profile.goalOverrideMl)
    }

    public var breakdown: WaterGoal.Breakdown {
        WaterGoal.calculate(weightKg: weightKg, activity: activity, climate: climate)
    }

    public var goalMl: Int { override ?? breakdown.goalMl }

    /// One glass more or less. Landing back on the calculated goal clears the adjustment.
    public mutating func adjust(by glasses: Int) {
        let adjusted = WaterGoal.adjusted(goalMl, by: glasses)
        override = adjusted == breakdown.goalMl ? nil : adjusted
    }

    /// Writes the answers to the profile. Height is left as it was.
    public func apply(to profile: WaterProfile) {
        profile.units = units
        profile.weightKg = weightKg
        profile.activity = activity
        profile.climate = climate
        profile.goalMl = breakdown.goalMl
        profile.goalOverrideMl = override
    }
}

/// Totals and streaks by the person's day (the day ends at their boundary hour, S11.3).
public enum WaterDay {
    public static func total(_ entries: [WaterEntry], on day: Date, clock: DayClock) -> Int {
        entries.filter { clock.day(containing: $0.timestamp) == day }.reduce(0) { $0 + $1.countedMl }
    }

    public static func entries(_ entries: [WaterEntry], on day: Date, clock: DayClock) -> [WaterEntry] {
        entries.filter { clock.day(containing: $0.timestamp) == day }.sorted { $0.timestamp < $1.timestamp }
    }

    /// Consecutive goal days, counting today if it's already met. A missed day just ends it, quietly.
    public static func streak(_ entries: [WaterEntry], goalMl: Int, now: Date = .now, clock: DayClock) -> Int {
        var totals: [Date: Int] = [:]
        for entry in entries { totals[clock.day(containing: entry.timestamp), default: 0] += entry.countedMl }
        var day = clock.day(containing: now)
        if (totals[day] ?? 0) < goalMl, let yesterday = clock.calendar.date(byAdding: .day, value: -1, to: day) {
            day = yesterday
        }
        var count = 0
        while (totals[day] ?? 0) >= goalMl {
            count += 1
            guard let previous = clock.calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return count
    }
}

/// Logging and undo, shared by the tracker, Home, widgets and intents.
public enum WaterLog {
    @discardableResult
    public static func log(_ drink: Drink, amountMl: Int? = nil, source: WaterSource = .app, at date: Date = .now,
                           in context: ModelContext) -> WaterEntry {
        let entry = WaterEntry(drink: drink, amountMl: amountMl, source: source, timestamp: date)
        context.insert(entry)
        try? context.save()
        return entry
    }

    /// Removes today's latest entry, wherever it was logged from. Returns it, or nil when there's nothing today.
    @discardableResult
    public static func undoLast(today: Date, clock: DayClock, in context: ModelContext) -> WaterEntry? {
        let all = (try? context.fetch(FetchDescriptor<WaterEntry>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)]))) ?? []
        guard let last = all.first(where: { clock.day(containing: $0.timestamp) == today }) else { return nil }
        context.delete(last)
        try? context.save()
        return last
    }
}

/// How amounts read: litres like the reference ("1.25", "1.5", "2.0"), or fl oz in the US unit system.
public enum WaterFormat {
    public static let mlPerFlOz = 29.5735

    /// The big number: "1.25" (litres) or "42" (fl oz).
    public static func amount(_ ml: Int, units: WaterUnits) -> String {
        switch units {
        case .metric:
            var text = String(format: "%.2f", Double(ml) / 1000)
            if text.hasSuffix("0") { text.removeLast() }
            return text
        case .imperial:
            return "\(Int((Double(ml) / mlPerFlOz).rounded()))"
        }
    }

    /// "L" or "fl oz".
    public static func unit(_ units: WaterUnits) -> String { units == .metric ? "L" : "fl oz" }

    /// A drink size: "250 ml", or "8 fl oz" (a glass reads as 8).
    public static func size(_ ml: Int, units: WaterUnits) -> String {
        switch units {
        case .metric: return "\(ml) ml"
        case .imperial:
            let oz = ml == WaterGoal.glassMl ? 8 : Int((Double(ml) / mlPerFlOz).rounded())
            return "\(oz) fl oz"
        }
    }

    public static func glasses(_ ml: Int) -> Int { Int((Double(ml) / Double(WaterGoal.glassMl)).rounded()) }
}
