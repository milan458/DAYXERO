import DayXeroCore
import Foundation
import Observation
import SwiftData

/// Quit Day defaults. Placeholder until the ported program content sets the prep length (S2.8).
enum QuitDayPolicy {
    static let recommendedDaysAhead = 7
    static let earliestDaysAhead = 1
    static let latestDaysAhead = 30
}

struct BaselineDraft: Equatable {
    var unitsPerDay: Double
    var price: Decimal?
    var unitsPerPurchase: Double
    var years: YearsOfUse?
    /// Pouches only. nil means "Not sure".
    var strengthMg: Double?

    static func starting(for product: Product) -> BaselineDraft {
        switch product {
        case .cigarettes: BaselineDraft(unitsPerDay: 10, unitsPerPurchase: 20)
        case .vape: BaselineDraft(unitsPerDay: 200, unitsPerPurchase: 600)
        case .pouches: BaselineDraft(unitsPerDay: 8, unitsPerPurchase: 20)
        }
    }

    var isComplete: Bool {
        guard let price else { return false }
        return unitsPerDay > 0 && price > 0 && unitsPerPurchase > 0
    }
}

enum YearsOfUse: Double, CaseIterable, Identifiable {
    case underOne = 0.5, oneToThree = 2, threeToFive = 4, fivePlus = 6
    var id: Double { rawValue }
    var title: LocalizedStringResource {
        switch self {
        case .underOne: "< 1 yr"
        case .oneToThree: "1–3 yrs"
        case .threeToFive: "3–5 yrs"
        case .fivePlus: "5+ yrs"
        }
    }
}

struct ReasonDraft: Identifiable, Equatable {
    let id = UUID()
    var text: String
    var photo: Data?
}

enum OnboardingStep: Hashable {
    case welcome, age, underAge, name, products, baseline(Product), triggers, reasons, pastAttempts,
         quitDay, nrt, waterBody, waterDay, waterGoal, building, reveal, reminders

    /// Analytics name.
    var key: String {
        switch self {
        case .welcome: "welcome"
        case .age: "age"
        case .underAge: "under_age"
        case .name: "name"
        case .products: "products"
        case let .baseline(product): "baseline_\(product.rawValue)"
        case .triggers: "triggers"
        case .reasons: "reasons"
        case .pastAttempts: "past_attempts"
        case .quitDay: "quit_day"
        case .nrt: "nrt"
        case .waterBody: "water_body"
        case .waterDay: "water_day"
        case .waterGoal: "water_goal"
        case .building: "building"
        case .reveal: "reveal"
        case .reminders: "reminders"
        }
    }

    var isSkippable: Bool {
        switch self {
        case .triggers, .reasons, .pastAttempts, .nrt: true
        default: false
        }
    }
}

@MainActor
@Observable
final class OnboardingModel {
    // Answers
    var isAdult: Bool?
    var name = ""
    var products: Set<Product> = []
    var usesNRT = false
    var baselines: [Product: BaselineDraft] = [:]
    var triggers: Set<Trigger> = []
    var cravingTimes: Set<TimeOfDay> = []
    var reasons: [ReasonDraft] = []
    var pastAttempts: PastAttempts?
    var obstacles: Set<Obstacle> = []
    var quitDay: Date
    var nrtInterest: NRTInterest?
    let currencyCode: String

    // Water goal (S2.14). Height and weight stay on the phone and are never shown as a BMI.
    var waterUnits = WaterUnits.default()
    var heightCm = 175.0
    var weightKg = 72.0
    var waterActivity: WaterActivity?
    var waterClimate = WaterClimate.mild
    /// Set by the Adjust stepper; always wins over the calculation.
    var waterGoalOverride: Int?
    /// "Skip, use 8 glasses": 2 L, and the activity and goal screens are skipped.
    var waterSkipped = false

    // Navigation
    private(set) var path: [OnboardingStep] = [.welcome]
    var step: OnboardingStep { path.last ?? .welcome }

    private let calendar: Calendar
    private let today: Date

    init(now: Date = .now, calendar: Calendar = .current, locale: Locale = .current) {
        self.calendar = calendar
        self.today = calendar.startOfDay(for: now)
        self.quitDay = calendar.date(byAdding: .day, value: QuitDayPolicy.recommendedDaysAhead, to: today) ?? today
        self.currencyCode = locale.currency?.identifier ?? "USD"
    }

    /// Products in display order, which is also the order of their baseline screens.
    var orderedProducts: [Product] { Product.allCases.filter(products.contains) }

    var recommendedQuitDay: Date {
        calendar.date(byAdding: .day, value: QuitDayPolicy.recommendedDaysAhead, to: today) ?? today
    }

    var quitDayRange: ClosedRange<Date> {
        let first = calendar.date(byAdding: .day, value: QuitDayPolicy.earliestDaysAhead, to: today) ?? today
        let last = calendar.date(byAdding: .day, value: QuitDayPolicy.latestDaysAhead, to: today) ?? today
        return first...last
    }

    var prepDays: Int {
        calendar.dateComponents([.day], from: today, to: calendar.startOfDay(for: quitDay)).day ?? 0
    }

    /// Steps in order for the current answers. Baselines repeat per product.
    var sequence: [OnboardingStep] {
        [.welcome, .age, .name, .products] + orderedProducts.map(OnboardingStep.baseline)
            + [.triggers, .reasons, .pastAttempts, .quitDay, .nrt, .waterBody]
            + (waterSkipped ? [] : [.waterDay, .waterGoal])
            + [.building, .reveal, .reminders]
    }

    /// 0...1 for the progress bar.
    var progress: Double {
        let steps = sequence
        guard let index = steps.firstIndex(of: step), steps.count > 1 else { return 0 }
        return Double(index) / Double(steps.count - 1)
    }

    func baseline(for product: Product) -> BaselineDraft {
        baselines[product] ?? .starting(for: product)
    }

    func setBaseline(_ draft: BaselineDraft, for product: Product) {
        baselines[product] = draft
    }

    var canContinue: Bool {
        switch step {
        case .age: isAdult != nil
        case .name: !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .products: !products.isEmpty
        case let .baseline(product): baseline(for: product).isComplete
        case .reasons: reasons.contains { !$0.text.trimmingCharacters(in: .whitespaces).isEmpty }
        case .quitDay: quitDayRange.contains(calendar.startOfDay(for: quitDay))
        case .waterDay: waterActivity != nil
        default: true
        }
    }

    // MARK: Navigation

    func next() {
        if step == .age, isAdult == false {
            path.append(.underAge)
            return
        }
        if step == .waterBody { waterSkipped = false }
        if step == .products, usesNRT, nrtInterest == nil {
            nrtInterest = .using
        }
        let steps = sequence
        guard let index = steps.firstIndex(of: step), index + 1 < steps.count else { return }
        path.append(steps[index + 1])
    }

    /// "Skip, use 8 glasses."
    func skipWater() {
        waterSkipped = true
        waterGoalOverride = nil
        Analytics.track(.onboardingStepSkipped(step: step.key))
        let steps = sequence
        guard let index = steps.firstIndex(of: step), index + 1 < steps.count else { return }
        path.append(steps[index + 1])
    }

    /// How the goal was worked out, from the answers so far.
    var waterBreakdown: WaterGoal.Breakdown {
        WaterGoal.calculate(weightKg: weightKg, activity: waterActivity ?? .mostlySitting, climate: waterClimate)
    }

    var waterGoalMl: Int { waterSkipped ? WaterGoal.skippedMl : (waterGoalOverride ?? waterBreakdown.goalMl) }

    func skip() {
        Analytics.track(.onboardingStepSkipped(step: step.key))
        next()
    }

    func back() {
        guard path.count > 1 else { return }
        path.removeLast()
        // The build moment is not a place to come back to.
        if step == .building { path.removeLast() }
    }

    var canGoBack: Bool {
        path.count > 1 && step != .reveal && step != .reminders && step != .building
    }

    #if DEBUG
    /// Jumps to a step with sample answers, for screenshots (launch with `-dx.onboardingStep <key>`).
    func loadSample(jumpingTo key: String) {
        isAdult = true
        name = "Milan"
        products = [.cigarettes, .vape]
        baselines = [
            .vape: BaselineDraft(unitsPerDay: 200, price: 8.5, unitsPerPurchase: 600, years: .oneToThree),
            .cigarettes: BaselineDraft(unitsPerDay: 6, price: 15, unitsPerPurchase: 20, years: .threeToFive),
        ]
        triggers = [.morning, .coffee, .stress, .work]
        cravingTimes = [.morning, .afternoon]
        reasons = [ReasonDraft(text: "Run with Aria without stopping to catch my breath")]
        pastAttempts = .onceOrTwice
        obstacles = [.cravings, .irritability]
        nrtInterest = .using
        waterUnits = .metric
        waterActivity = .worksOut
        let steps = sequence + [.underAge]
        if let target = steps.first(where: { $0.key == key }) {
            path = [.welcome, target]
        }
    }
    #endif

    // MARK: Saving

    /// Writes the answers to the store. Called once, before the reminders screen.
    @discardableResult
    func save(into context: ModelContext, now: Date = .now) throws -> UserProfile {
        let profile = UserProfile(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            quitDay: calendar.startOfDay(for: quitDay),
            currencyCode: currencyCode
        )
        context.insert(profile)
        profile.ageConfirmedAt = now
        profile.triggers = Trigger.allCases.filter(triggers.contains)
        profile.cravingTimesRaw = TimeOfDay.allCases.filter(cravingTimes.contains).map(\.rawValue)
        profile.pastAttemptsRaw = pastAttempts?.rawValue
        profile.obstaclesRaw = Obstacle.allCases.filter(obstacles.contains).map(\.rawValue)
        profile.nrtInterest = nrtInterest
        profile.progress = ProgramProgress()

        for (offset, product) in orderedProducts.enumerated() {
            let draft = baseline(for: product)
            profile.products.append(ProductUse(
                product: product,
                isPrimary: offset == 0,
                unitsPerDay: draft.unitsPerDay,
                pricePerPurchase: draft.price ?? 0,
                unitsPerPurchase: draft.unitsPerPurchase,
                yearsOfUse: draft.years?.rawValue,
                strengthMg: product == .pouches ? draft.strengthMg : nil
            ))
        }
        for reason in reasons where !reason.text.trimmingCharacters(in: .whitespaces).isEmpty {
            profile.reasons.append(Reason(text: reason.text, photo: reason.photo))
        }

        context.insert(WaterProfile(
            heightCm: waterSkipped ? nil : heightCm,
            weightKg: waterSkipped ? nil : weightKg,
            activity: waterActivity ?? .mostlySitting,
            climate: waterClimate,
            units: waterUnits,
            goalMl: waterSkipped ? WaterGoal.skippedMl : waterBreakdown.goalMl,
            goalOverrideMl: waterSkipped ? nil : waterGoalOverride
        ))

        try context.save()
        Analytics.track(.onboardingCompleted)
        let source = waterSkipped ? "skipped" : waterGoalOverride != nil ? "override" : "calculated"
        Analytics.track(.waterGoalSet(source: source, goalBucket: "\(waterGoalMl / 500 * 500)"))
        return profile
    }

    /// Plan-reveal numbers, computed with the same logic Home uses.
    var stats: ProgressStats {
        ProgressStats(
            quitDay: quitDay,
            baselines: orderedProducts.map { product in
                let d = baseline(for: product)
                return Baseline(product: product, unitsPerDay: d.unitsPerDay, pricePerPurchase: d.price ?? 0, unitsPerPurchase: d.unitsPerPurchase)
            },
            clock: DayClock(calendar: calendar, boundaryHour: 4)
        )
    }
}
