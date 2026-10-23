import Foundation
import SwiftData

/// The person using the app. Local only; there is no account in v1.
@Model
public final class UserProfile {
    public var name: String
    public var ageConfirmedAt: Date?
    public var createdAt: Date
    /// Start of the day the prep phase ends and the quit days begin.
    public var quitDay: Date
    /// Hour (0–23) when "today" ends, so late-night check-ins count for the right day.
    public var dayBoundaryHour: Int
    public var currencyCode: String
    public var nrtInterestRaw: String?

    @Relationship(deleteRule: .cascade) public var products: [ProductUse] = []
    @Relationship(deleteRule: .cascade) public var reasons: [Reason] = []
    @Relationship(deleteRule: .cascade) public var progress: ProgramProgress?
    @Relationship(deleteRule: .cascade) public var nrtPlan: NRTPlan?
    public var triggersRaw: [String] = []
    public var cravingTimesRaw: [String] = []
    public var pastAttemptsRaw: String?
    public var obstaclesRaw: [String] = []

    public init(name: String, quitDay: Date, currencyCode: String, dayBoundaryHour: Int = 4, createdAt: Date = .now) {
        self.name = name
        self.quitDay = quitDay
        self.currencyCode = currencyCode
        self.dayBoundaryHour = dayBoundaryHour
        self.createdAt = createdAt
    }

    public var triggers: [Trigger] {
        get { triggersRaw.compactMap(Trigger.init(rawValue:)) }
        set { triggersRaw = newValue.map(\.rawValue) }
    }

    public var nrtInterest: NRTInterest? {
        get { nrtInterestRaw.flatMap(NRTInterest.init(rawValue:)) }
        set { nrtInterestRaw = newValue?.rawValue }
    }

    public var primaryProduct: ProductUse? {
        products.first(where: \.isPrimary) ?? products.first
    }
}

/// One product the user uses, with their baseline before quitting.
@Model
public final class ProductUse {
    public var productRaw: String
    public var isPrimary: Bool
    /// Cigarettes, puffs or pouches per day.
    public var unitsPerDay: Double
    /// Price of one purchase (a pack, a pod or disposable, a can).
    public var pricePerPurchase: Decimal
    /// Units in one purchase (cigarettes per pack, puffs per pod, pouches per can).
    public var unitsPerPurchase: Double
    public var yearsOfUse: Double?
    /// Pouch strength in mg, pouches only.
    public var strengthMg: Double?

    public init(product: Product, isPrimary: Bool, unitsPerDay: Double, pricePerPurchase: Decimal,
                unitsPerPurchase: Double, yearsOfUse: Double? = nil, strengthMg: Double? = nil) {
        self.productRaw = product.rawValue
        self.isPrimary = isPrimary
        self.unitsPerDay = unitsPerDay
        self.pricePerPurchase = pricePerPurchase
        self.unitsPerPurchase = unitsPerPurchase
        self.yearsOfUse = yearsOfUse
        self.strengthMg = strengthMg
    }

    public var product: Product { Product(rawValue: productRaw) ?? .cigarettes }

    public var baseline: Baseline {
        Baseline(product: product, unitsPerDay: unitsPerDay, pricePerPurchase: pricePerPurchase, unitsPerPurchase: unitsPerPurchase)
    }
}

/// A reason to quit, in the user's words, with an optional photo. Reused in the pledge and SOS.
@Model
public final class Reason {
    public var text: String
    @Attribute(.externalStorage) public var photo: Data?
    public var createdAt: Date

    public init(text: String, photo: Data? = nil, createdAt: Date = .now) {
        self.text = text
        self.photo = photo
        self.createdAt = createdAt
    }
}

/// Which program days are done. Days unlock in order.
@Model
public final class ProgramProgress {
    @Relationship(deleteRule: .cascade) public var completions: [DayCompletion] = []
    public var lastActiveAt: Date?
    /// Set when the program paused after a break (S5.7): this finished day is replayed before moving on.
    public var replayDayRaw: String?

    public init() {}

    public var completedDayIDs: Set<ProgramDayID> {
        Set(completions.compactMap(\.dayID))
    }

    public var replayDay: ProgramDayID? {
        get { replayDayRaw.flatMap(ProgramDayID.init(description:)) }
        set { replayDayRaw = newValue?.description }
    }

    /// The most recently finished program day.
    public var lastCompleted: ProgramDayID? {
        completions.max { $0.completedAt < $1.completedAt }?.dayID
    }
}

/// An if-then plan made in a lesson exercise; shown again in Craving SOS.
@Model
public final class IfThenPlan {
    public var situation: String
    public var action: String
    public var createdAt: Date

    public init(situation: String, action: String, createdAt: Date = .now) {
        self.situation = situation
        self.action = action
        self.createdAt = createdAt
    }
}

/// Answers from a weekly check-in in the weeks after the quit week (S5.6).
@Model
public final class WeeklyCheckIn {
    public var week: Int
    /// 0 (easy) ... 1 (tough).
    public var cravingRating: Double
    /// Weekday indexes (0 = first day of the week) on which last week's challenge was done.
    public var challengeDays: [Int]
    public var nextChallenge: String?
    public var createdAt: Date

    public init(week: Int, cravingRating: Double, challengeDays: [Int], nextChallenge: String?, createdAt: Date = .now) {
        self.week = week
        self.cravingRating = cravingRating
        self.challengeDays = challengeDays
        self.nextChallenge = nextChallenge
        self.createdAt = createdAt
    }
}

@Model
public final class DayCompletion {
    public var phaseRaw: String
    public var index: Int
    public var completedAt: Date

    public init(day: ProgramDayID, completedAt: Date = .now) {
        self.phaseRaw = day.phase.rawValue
        self.index = day.index
        self.completedAt = completedAt
    }

    public var dayID: ProgramDayID? {
        ProgramPhase(rawValue: phaseRaw).map { ProgramDayID(phase: $0, index: index) }
    }
}

/// A craving, a slip, or a use during prep.
@Model
public final class LogEntry {
    public var kindRaw: String
    public var productRaw: String?
    public var timestamp: Date
    /// 1–10 for cravings.
    public var intensity: Int?
    public var triggerRaw: String?
    public var moodRaw: Int?
    public var placeRaw: String?
    public var note: String?
    /// Set for SOS sessions.
    public var sosDurationSeconds: Double?
    public var outcomeRaw: String?
    /// Slip debrief: one thing to try next time.
    public var nextTime: String?

    public init(kind: LogKind, product: Product? = nil, timestamp: Date = .now, intensity: Int? = nil,
                trigger: Trigger? = nil, mood: Mood? = nil, note: String? = nil) {
        self.kindRaw = kind.rawValue
        self.productRaw = product?.rawValue
        self.timestamp = timestamp
        self.intensity = intensity
        self.triggerRaw = trigger?.rawValue
        self.moodRaw = mood?.rawValue
        self.note = note
    }

    public var kind: LogKind { LogKind(rawValue: kindRaw) ?? .craving }
    public var product: Product? { productRaw.flatMap(Product.init(rawValue:)) }
    public var trigger: Trigger? { triggerRaw.flatMap(Trigger.init(rawValue:)) }
    public var mood: Mood? {
        get { moodRaw.flatMap(Mood.init(rawValue:)) }
        set { moodRaw = newValue?.rawValue }
    }
    public var place: Place? {
        get { placeRaw.flatMap(Place.init(rawValue:)) }
        set { placeRaw = newValue?.rawValue }
    }
    public var outcome: CravingOutcome? {
        get { outcomeRaw.flatMap(CravingOutcome.init(rawValue:)) }
        set { outcomeRaw = newValue?.rawValue }
    }
}

@Model
public final class Pledge {
    /// The program day this pledge belongs to (start of day, after the day boundary).
    public var day: Date
    public var madeAt: Date

    public init(day: Date, madeAt: Date = .now) {
        self.day = day
        self.madeAt = madeAt
    }
}

@Model
public final class CheckIn {
    public var day: Date
    public var madeAt: Date
    public var moodRaw: Int
    public var cravingCount: Int
    public var note: String?

    public init(day: Date, mood: Mood, cravingCount: Int, note: String? = nil, madeAt: Date = .now) {
        self.day = day
        self.moodRaw = mood.rawValue
        self.cravingCount = cravingCount
        self.note = note
        self.madeAt = madeAt
    }

    public var mood: Mood { Mood(rawValue: moodRaw) ?? .okay }
}

/// NRT the user is on. Step-down schedules follow the product label only (Section 9).
@Model
public final class NRTPlan {
    public var typeRaw: String
    public var strengthMg: Double
    public var startDate: Date
    @Relationship(deleteRule: .cascade) public var steps: [NRTStep] = []

    public init(type: NRTType, strengthMg: Double, startDate: Date) {
        self.typeRaw = type.rawValue
        self.strengthMg = strengthMg
        self.startDate = startDate
    }

    public var type: NRTType { NRTType(rawValue: typeRaw) ?? .patch }
}

@Model
public final class NRTStep {
    public var strengthMg: Double
    public var startDate: Date

    public init(strengthMg: Double, startDate: Date) {
        self.strengthMg = strengthMg
        self.startDate = startDate
    }
}
