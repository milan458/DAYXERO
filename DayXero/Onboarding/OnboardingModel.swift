import DayXeroCore
import Foundation
import Observation
import SwiftData

/// Quit Day defaults. Placeholder until the ported program content sets the prep length (S2.8).
enum QuitDayPolicy {
    /// A full prep week: one prep session a day.
    static let recommendedDaysAhead = 7
    /// Prep can be 3 to 7 days (S27.7). Day Xero opens on the Quit Day whatever prep is done, and unfinished prep
    /// sessions stay open as catch-up (ProgramUnlock.states).
    static let earliestDaysAhead = 3
    static let latestDaysAhead = 30
}

struct BaselineDraft: Equatable {
    var unitsPerDay: Double
    var price: Decimal?
    var unitsPerPurchase: Double
    var years: YearsOfUse?
    /// Pouches in mg, vapes in mg/ml (S22). nil means "Not sure".
    var strengthMg: Double?
    /// Vapes only: counted in puffs a day rather than pods a week (S22).
    var byPuffs = false

    static func starting(for product: Product, currency: String = "") -> BaselineDraft {
        switch product {
        case .cigarettes:
            let presets = PricePresets.pack(currency: currency, size: 20)
            return BaselineDraft(unitsPerDay: 10, price: presets.count == 3 ? presets[1] : nil, unitsPerPurchase: 20)
        case .vape:
            return BaselineDraft(unitsPerDay: VapeUsage.puffsPerDay(podsPerWeek: 2, puffsPerPod: 600),
                                 price: PricePresets.vape(currency: currency)?.price, unitsPerPurchase: 600,
                                 strengthMg: currency.isEmpty ? nil : PricePresets.vapeStrength(currency: currency))
        case .pouches:
            let presets = PricePresets.can(currency: currency)
            return BaselineDraft(unitsPerDay: 8, price: presets.count == 3 ? presets[1] : nil, unitsPerPurchase: 20, strengthMg: 6)
        }
    }

    var isComplete: Bool {
        guard let price else { return false }
        return unitsPerDay > 0 && price > 0 && unitsPerPurchase > 0
    }

    /// Vapes only: what the baseline screen asks, stored as puffs a day (S18.8).
    var podsPerWeek: Double {
        get { VapeUsage.podsPerWeek(puffsPerDay: unitsPerDay, puffsPerPod: unitsPerPurchase) }
        set { unitsPerDay = VapeUsage.puffsPerDay(podsPerWeek: newValue, puffsPerPod: unitsPerPurchase) }
    }

    /// Vapes only: a new puffs-per-pod figure keeps pods a week where it was.
    var puffsPerPod: Double {
        get { unitsPerPurchase }
        set {
            let pods = podsPerWeek
            unitsPerPurchase = newValue
            if pods > 0, newValue > 0, !byPuffs { podsPerWeek = pods }
        }
    }

    /// Money a year at this baseline.
    var yearlyCost: Decimal? {
        guard let price, price > 0, unitsPerPurchase > 0 else { return nil }
        return price * Decimal(unitsPerDay) / Decimal(unitsPerPurchase) * 365
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

/// The onboarding steps (S22). The age check is the welcome screen's footer; the name is asked with the reason.
enum OnboardingStep: Hashable {
    case welcome, products, baseline(Product), baselineSummary, triggers, personal, pastAttempts,
         nrt, quitDay, building, reveal, trial

    /// Analytics and screenshot name.
    var key: String {
        switch self {
        case .welcome: "welcome"
        case .products: "products"
        case let .baseline(product): "baseline_\(product.rawValue)"
        case .baselineSummary: "baseline_summary"
        case .triggers: "triggers"
        case .personal: "personal"
        case .pastAttempts: "past_attempts"
        case .nrt: "nrt"
        case .quitDay: "quit_day"
        case .building: "building"
        case .reveal: "reveal"
        case .trial: "trial"
        }
    }
}

@MainActor
@Observable
final class OnboardingModel {
    // Answers
    var name = ""
    var products: Set<Product> = []
    var baselines: [Product: BaselineDraft] = [:]
    var firstUse: FirstUse?
    var triggers: Set<Trigger> = []
    /// Their reason, in their words, with an optional photo.
    var why = ReasonDraft(text: "")
    var pastAttempts: PastAttempts?
    var obstacles: Set<Obstacle> = []
    /// 0–10.
    var confidence: Double = 5
    var quitDay: Date
    var nrtInterest: NRTInterest?
    var nrtFormats: Set<NRTType> = []
    let currencyCode: String

    // Navigation
    private(set) var path: [OnboardingStep] = [.welcome]
    var step: OnboardingStep { path.last ?? .welcome }

    let calendar: Calendar
    /// The start of today.
    let today: Date

    init(now: Date = .now, calendar: Calendar = .current, locale: Locale = .current) {
        self.calendar = calendar
        self.today = calendar.startOfDay(for: now)
        self.quitDay = calendar.date(byAdding: .day, value: QuitDayPolicy.recommendedDaysAhead, to: today) ?? today
        self.currencyCode = CurrencyChoice.defaultCode(for: locale)
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
        [.welcome, .products] + orderedProducts.map(OnboardingStep.baseline)
            + [.baselineSummary, .triggers, .personal, .pastAttempts, .nrt, .quitDay, .building, .reveal, .trial]
    }

    /// 0...1 for the progress bar. The baseline screens share one slot, split between the products, so the total
    /// stays fixed: picking a second product never moves the bar back.
    var progress: Double {
        let fixed = sequence.filter { if case .baseline = $0 { false } else { true } }
        guard let summary = fixed.firstIndex(of: .baselineSummary) else { return 0 }
        // One more slot than `fixed` has, for the baselines, so the last step is fixed.count.
        let total = Double(fixed.count)
        if case let .baseline(product) = step {
            let products = orderedProducts
            let done = Double(products.firstIndex(of: product) ?? 0)
            return (Double(summary) + done / Double(max(products.count, 1))) / total
        }
        guard let index = fixed.firstIndex(of: step) else { return 0 }
        return Double(index >= summary ? index + 1 : index) / total
    }

    func baseline(for product: Product) -> BaselineDraft {
        baselines[product] ?? .starting(for: product, currency: currencyCode)
    }

    func setBaseline(_ draft: BaselineDraft, for product: Product) {
        baselines[product] = draft
    }

    var canContinue: Bool {
        switch step {
        case .products: !products.isEmpty
        case let .baseline(product): baseline(for: product).isComplete
        case .triggers: firstUse != nil && !triggers.isEmpty
        case .personal: !trimmedName.isEmpty && !why.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .pastAttempts: pastAttempts == .notYet || (pastAttempts != nil && !obstacles.isEmpty)
        case .nrt: nrtInterest != nil
        case .quitDay: quitDayRange.contains(calendar.startOfDay(for: quitDay))
        default: true
        }
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    // MARK: Navigation

    func next() {
        let steps = sequence
        guard let index = steps.firstIndex(of: step), index + 1 < steps.count else { return }
        path.append(steps[index + 1])
    }

    func back() {
        guard path.count > 1 else { return }
        path.removeLast()
        // The build moment is not a place to come back to.
        if step == .building { path.removeLast() }
    }

    var canGoBack: Bool {
        path.count > 1 && step != .reveal && step != .trial && step != .building
    }

    #if DEBUG
    /// Jumps to a step with sample answers, for screenshots (launch with `-dx.onboardingStep <key>`).
    func loadSample(jumpingTo key: String) {
        // The design persona (design doc §7): Sam, cigarettes and a vape, coffee and stress.
        name = "Sam"
        products = [.cigarettes, .vape]
        var vape = BaselineDraft.starting(for: .vape, currency: currencyCode)
        vape.years = .oneToThree
        var cigarettes = BaselineDraft.starting(for: .cigarettes, currency: currencyCode)
        cigarettes.years = .threeToFive
        baselines = [.vape: vape, .cigarettes: cigarettes]
        firstUse = .withinThirty
        triggers = [.coffee, .stress]
        why = ReasonDraft(text: "To keep up with Maya at the park")
        pastAttempts = .onceOrTwice
        obstacles = [.cravings, .stress]
        nrtInterest = .using
        nrtFormats = [.patch, .gum]
        let steps = sequence
        if let target = steps.first(where: { $0.key == key }) {
            path = [.welcome, target]
        }
    }
    #endif

    // MARK: Saving

    /// Writes the answers to the store. Called once, before the trial screen.
    @discardableResult
    func save(into context: ModelContext, now: Date = .now) throws -> UserProfile {
        let profile = UserProfile(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            quitDay: calendar.startOfDay(for: quitDay),
            currencyCode: currencyCode
        )
        context.insert(profile)
        // Continuing past the welcome screen confirms they're 18 or older (S22).
        profile.ageConfirmedAt = now
        profile.triggers = Trigger.allCases.filter(triggers.contains)
        profile.cravingTimesRaw = cravingTimes.map(\.rawValue)
        profile.firstUse = firstUse
        profile.confidence = Int(confidence.rounded())
        profile.nrtFormats = nrtInterest == .using ? NRTType.allCases.filter(nrtFormats.contains) : []
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
                strengthMg: product == .cigarettes ? nil : draft.strengthMg
            ))
        }
        let reason = why.text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !reason.isEmpty {
            profile.reasons.append(Reason(text: reason, photo: why.photo))
        }

        // Everyone starts on 8 glasses; the Water tab personalises it (S18.5).
        context.insert(WaterProfile(units: .default(), goalMl: WaterGoal.skippedMl))

        try context.save()
        Analytics.track(.onboardingCompleted)
        Analytics.track(.waterGoalSet(source: "default", goalBucket: "\(WaterGoal.skippedMl)"))
        return profile
    }

    /// Craving times for the predictor, now that onboarding asks about mornings instead (S22).
    var cravingTimes: [TimeOfDay] {
        var times: [TimeOfDay] = []
        if (firstUse != nil && firstUse != .later) || triggers.contains(.coffee) || triggers.contains(.morning) { times.append(.morning) }
        if triggers.contains(.meals) || triggers.contains(.work) { times.append(.midday) }
        if triggers.contains(.alcohol) || triggers.contains(.social) { times.append(.evening) }
        return times
    }

    /// Nicotine a day, all products together, in mg.
    var nicotinePerDay: Double {
        orderedProducts.reduce(0) { sum, product in
            let d = baseline(for: product)
            return sum + NicotineEstimate.mgPerDay(product, unitsPerDay: d.unitsPerDay, strength: d.strengthMg)
        }
    }

    /// Hours a year spent smoking or vaping.
    var hoursPerYear: Double {
        orderedProducts.reduce(0) { $0 + TimeSpent.hoursPerYear($1, unitsPerDay: baseline(for: $1).unitsPerDay) }
    }

    /// Money a day, all products together.
    var moneyPerDay: Decimal {
        orderedProducts.reduce(Decimal(0)) { $0 + (baseline(for: $1).yearlyCost ?? 0) } / 365
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
