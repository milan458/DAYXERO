import Foundation
import SwiftData

/// The person's water goal inputs (S7.5). Height and weight stay on the phone: never in analytics or an
/// export they haven't asked for.
@Model
public final class WaterProfile {
    public var heightCm: Double?
    public var weightKg: Double?
    public var activityRaw: String
    public var climateRaw: String
    public var unitSystemRaw: String
    /// Calculated from weight, activity and climate (or 2,000 ml when onboarding was skipped).
    public var goalMl: Int
    /// A manual adjustment, which always wins over the calculation.
    public var goalOverrideMl: Int?
    /// The drink the tracker logs next; remembered between visits.
    public var selectedDrinkRaw: String
    public var createdAt: Date

    public init(heightCm: Double? = nil, weightKg: Double? = nil, activity: WaterActivity = .mostlySitting,
                climate: WaterClimate = .mild, units: WaterUnits = .metric, goalMl: Int = WaterGoal.skippedMl,
                goalOverrideMl: Int? = nil, createdAt: Date = .now) {
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.activityRaw = activity.rawValue
        self.climateRaw = climate.rawValue
        self.unitSystemRaw = units.rawValue
        self.goalMl = goalMl
        self.goalOverrideMl = goalOverrideMl
        self.selectedDrinkRaw = Drink.glass.rawValue
        self.createdAt = createdAt
    }

    public var activity: WaterActivity {
        get { WaterActivity(rawValue: activityRaw) ?? .mostlySitting }
        set { activityRaw = newValue.rawValue }
    }

    public var climate: WaterClimate {
        get { WaterClimate(rawValue: climateRaw) ?? .mild }
        set { climateRaw = newValue.rawValue }
    }

    public var units: WaterUnits {
        get { WaterUnits(rawValue: unitSystemRaw) ?? .metric }
        set { unitSystemRaw = newValue.rawValue }
    }

    public var selectedDrink: Drink {
        get { Drink(rawValue: selectedDrinkRaw) ?? .glass }
        set { selectedDrinkRaw = newValue.rawValue }
    }

    /// The goal in use: the override if there is one.
    public var effectiveGoalMl: Int { goalOverrideMl ?? goalMl }
}

/// One drink logged (S7.5).
@Model
public final class WaterEntry {
    public var id: UUID
    public var timestamp: Date
    public var drinkId: String
    public var amountMl: Int
    /// 1.0 for every v1 drink; kept so it can change without a migration.
    public var hydrationFactor: Double
    public var countedMl: Int
    public var sourceRaw: String

    public init(drink: Drink, amountMl: Int? = nil, source: WaterSource = .app, timestamp: Date = .now) {
        id = UUID()
        self.timestamp = timestamp
        drinkId = drink.rawValue
        let amount = amountMl ?? drink.ml
        self.amountMl = amount
        hydrationFactor = drink.hydrationFactor
        countedMl = Int((Double(amount) * drink.hydrationFactor).rounded())
        sourceRaw = source.rawValue
    }

    public var drink: Drink { Drink(rawValue: drinkId) ?? .glass }
}
