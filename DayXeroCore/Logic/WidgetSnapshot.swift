import Foundation
import SwiftData

/// What every widget reads (S17.1): a small snapshot in the App Group, written by the app after each relevant
/// change and by widget intents after a water log. No free text from logs or check-ins ever goes in here.
public struct WidgetSnapshot: Codable, Sendable, Equatable {
    public enum Phase: String, Codable, Sendable {
        /// Before the first lesson is done.
        case beforeDay1
        /// Prep days, before Quit Day.
        case prep
        /// Quit Day and after, while the program runs.
        case quit
        /// After the program.
        case after
    }

    public struct Lesson: Codable, Sendable, Equatable {
        public let title: String
        public let minutes: Int

        public init(title: String, minutes: Int) {
            self.title = title
            self.minutes = minutes
        }
    }

    public var phase: Phase
    public var quitDate: Date
    /// Which prep day it is (1-based); prep only.
    public var prepDay: Int
    public var daysUntilQuitDay: Int
    /// Days clear, counting Quit Day as 1, as on Home.
    public var daysFree: Int
    /// The start of today by the person's day boundary, for the ticking "into the day" timer.
    public var currentDayStart: Date
    public var nextDayStart: Date
    public var moneyKept: Double
    public var currencyCode: String
    public var cravingsRidden: Int
    public var waterCountedMl: Int
    public var waterGoalMl: Int
    public var lastDrinkId: String
    public var nextWindow: CravingPredictor.Window?
    public var nextLesson: Lesson?
    public var nextMilestone: Int?
    /// Lock Screen widgets hide money and the word nicotine.
    public var privacyMode: Bool
    /// …and so do Home Screen widgets.
    public var privacyOnHomeScreen: Bool
    public var updatedAt: Date

    public init(phase: Phase, quitDate: Date, prepDay: Int, daysUntilQuitDay: Int, daysFree: Int, currentDayStart: Date,
                nextDayStart: Date, moneyKept: Double, currencyCode: String, cravingsRidden: Int, waterCountedMl: Int,
                waterGoalMl: Int, lastDrinkId: String, nextWindow: CravingPredictor.Window?, nextLesson: Lesson?,
                nextMilestone: Int?, privacyMode: Bool, privacyOnHomeScreen: Bool, updatedAt: Date) {
        self.phase = phase
        self.quitDate = quitDate
        self.prepDay = prepDay
        self.daysUntilQuitDay = daysUntilQuitDay
        self.daysFree = daysFree
        self.currentDayStart = currentDayStart
        self.nextDayStart = nextDayStart
        self.moneyKept = moneyKept
        self.currencyCode = currencyCode
        self.cravingsRidden = cravingsRidden
        self.waterCountedMl = waterCountedMl
        self.waterGoalMl = waterGoalMl
        self.lastDrinkId = lastDrinkId
        self.nextWindow = nextWindow
        self.nextLesson = nextLesson
        self.nextMilestone = nextMilestone
        self.privacyMode = privacyMode
        self.privacyOnHomeScreen = privacyOnHomeScreen
        self.updatedAt = updatedAt
    }

    public var glassesToday: Int { WaterFormat.glasses(waterCountedMl) }
    public var glassesGoal: Int { max(waterGoalMl / WaterGoal.glassMl, 1) }
    public var lastDrink: Drink { Drink(rawValue: lastDrinkId) ?? .glass }

    /// "$84", rounded to whole units.
    public var moneyText: String {
        moneyKept.formatted(.currency(code: currencyCode).precision(.fractionLength(0)))
    }

    // MARK: Storage

    public static let key = "dx.widgetSnapshot"
    /// Widget kinds, for targeted reloads.
    public enum Kind {
        public static let days = "DaysFree"
        public static let sos = "CravingSOS"
        public static let today = "Today"
        public static let water = "Water"
        public static let forecast = "CravingForecast"
        public static let all = [days, sos, today, water, forecast]
    }

    private static var defaults: UserDefaults { UserDefaults(suiteName: DataStore.appGroup) ?? .standard }

    public static func load() -> WidgetSnapshot? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    public func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        Self.defaults.set(data, forKey: Self.key)
    }

    /// Rereads today's water from the store, for a water log made outside the app (a widget or control).
    @MainActor
    public static func refreshWater(in context: ModelContext, now: Date = .now) {
        guard var snapshot = load() else { return }
        let boundary = (try? context.fetch(FetchDescriptor<UserProfile>()).first?.dayBoundaryHour) ?? 4
        let clock = DayClock(boundaryHour: boundary)
        let entries = (try? context.fetch(FetchDescriptor<WaterEntry>())) ?? []
        let today = WaterDay.entries(entries, on: clock.day(containing: now), clock: clock)
        snapshot.waterCountedMl = today.reduce(0) { $0 + $1.countedMl }
        snapshot.lastDrinkId = today.last?.drinkId ?? snapshot.lastDrinkId
        if let goal = (try? context.fetch(FetchDescriptor<WaterProfile>()).first)?.effectiveGoalMl { snapshot.waterGoalMl = goal }
        snapshot.updatedAt = now
        snapshot.save()
    }

    /// Sample data matching the signed-off references: day 12, $84 kept, 31 cravings ridden out, 6 of 11 glasses,
    /// a 3:00 pm window after lunch, "Hands and habits" next.
    public static func sample(now: Date = .now, calendar: Calendar = .current) -> WidgetSnapshot {
        let dayStart = calendar.startOfDay(for: now)
        let window = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: now) ?? now
        let start = window > now ? window : calendar.date(byAdding: .day, value: 1, to: window) ?? window
        return WidgetSnapshot(
            phase: .quit, quitDate: calendar.date(byAdding: .day, value: -11, to: dayStart) ?? dayStart, prepDay: 0,
            daysUntilQuitDay: 0, daysFree: 12, currentDayStart: dayStart,
            nextDayStart: calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart,
            moneyKept: 84, currencyCode: "USD", cravingsRidden: 31, waterCountedMl: 1500, waterGoalMl: 2750,
            lastDrinkId: Drink.glass.rawValue,
            nextWindow: .init(start: start, end: start.addingTimeInterval(40 * 60), confidence: 0.8, trigger: .meals),
            nextLesson: .init(title: "Hands and habits", minutes: 2), nextMilestone: 14,
            privacyMode: false, privacyOnHomeScreen: false, updatedAt: now)
    }
}
