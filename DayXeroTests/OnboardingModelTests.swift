@testable import DayXero
import DayXeroCore
import Foundation
import SwiftData
import Testing

@MainActor
struct OnboardingModelTests {
    let now: Date = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/London")!
        return c.date(from: DateComponents(year: 2026, month: 10, day: 22, hour: 10))!
    }()

    func makeModel() -> OnboardingModel {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return OnboardingModel(now: now, calendar: calendar, locale: Locale(identifier: "en_GB"))
    }

    @Test func dualUsersGetABaselineStepPerProductInDisplayOrder() {
        let model = makeModel()
        model.products = [.vape, .cigarettes]
        let baselines = model.sequence.filter { if case .baseline = $0 { true } else { false } }
        #expect(baselines == [.baseline(.cigarettes), .baseline(.vape)])
    }

    @Test func underEighteensGoToTheExitScreen() {
        let model = makeModel()
        model.next() // welcome → age
        model.isAdult = false
        model.next()
        #expect(model.step == .underAge)
    }

    @Test func requiredStepsBlockContinueUntilAnswered() {
        let model = makeModel()
        model.next()
        #expect(model.step == .age)
        #expect(!model.canContinue)
        model.isAdult = true
        model.next()
        #expect(model.step == .name)
        model.name = "   "
        #expect(!model.canContinue)
        model.name = "Milan"
        model.next()
        #expect(model.step == .products)
        #expect(!model.canContinue)
    }

    @Test func baselineNeedsAPrice() {
        var draft = BaselineDraft.starting(for: .vape)
        #expect(!draft.isComplete)
        draft.price = 0
        #expect(!draft.isComplete)
        draft.price = 8.5
        #expect(draft.isComplete)
    }

    @Test func quitDayDefaultsToAWeekOutAndStaysInRange() {
        let model = makeModel()
        #expect(model.prepDays == QuitDayPolicy.recommendedDaysAhead)
        #expect(model.quitDayRange.contains(model.quitDay))
        #expect(model.currencyCode == "GBP")
    }

    @Test func tickingNRTPreselectsAlreadyUsing() {
        let model = makeModel()
        model.next(); model.isAdult = true; model.next(); model.name = "M"; model.next()
        model.products = [.pouches]
        model.usesNRT = true
        model.next()
        #expect(model.nrtInterest == .using)
        #expect(model.step == .baseline(.pouches))
    }

    @Test func savingWritesTheProfile() throws {
        let container = try DataStore.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let model = makeModel()
        model.name = " Milan "
        model.products = [.vape, .pouches]
        model.setBaseline(BaselineDraft(unitsPerDay: 200, price: 8, unitsPerPurchase: 600), for: .vape)
        model.setBaseline(BaselineDraft(unitsPerDay: 8, price: 6, unitsPerPurchase: 20, strengthMg: 11), for: .pouches)
        model.reasons = [ReasonDraft(text: "Breathe easier"), ReasonDraft(text: "  ")]
        model.triggers = [.coffee]

        try model.save(into: context, now: now)

        let profile = try #require(try context.fetch(FetchDescriptor<UserProfile>()).first)
        #expect(profile.name == "Milan")
        #expect(profile.products.count == 2)
        #expect(profile.primaryProduct?.product == .vape)
        #expect(profile.products.first { $0.product == .pouches }?.strengthMg == 11)
        #expect(profile.reasons.map(\.text) == ["Breathe easier"])
        #expect(profile.triggers == [.coffee])
        #expect(profile.progress != nil)
    }

    // MARK: Vapes in pods a week (S18.8)

    @Test func vapersStartOnTwoPodsAWeek() {
        let draft = BaselineDraft.starting(for: .vape)
        #expect(draft.podsPerWeek == 2)
        #expect(abs(draft.unitsPerDay - 1200.0 / 7) < 0.001)
    }

    @Test func changingPuffsPerPodKeepsPodsAWeek() {
        var draft = BaselineDraft.starting(for: .vape)
        draft.podsPerWeek = 3.5
        draft.puffsPerPod = 800
        #expect(draft.podsPerWeek == 3.5)
        #expect(abs(draft.unitsPerDay - 400) < 0.001)
    }

    @Test func podsAWeekRoundToHalfAPodAndMoneyStaysTheSame() {
        #expect(VapeUsage.podsPerWeek(puffsPerDay: 200, puffsPerPod: 600) == 2.5)
        #expect(VapeUsage.format(2) == "2" && VapeUsage.format(2.5) == "2.5")
        // A pod at 8.50, two a week, is 8.50 × 2 × 365 / 7 a year however puffs per pod is set.
        let puffs = VapeUsage.puffsPerDay(podsPerWeek: 2, puffsPerPod: 600)
        let yearly = 8.5 * puffs / 600 * 365
        #expect(abs(yearly - 8.5 * 2 * 365 / 7) < 0.001)
    }

    @Test func savedVapeUsePodsAWeekKeepPodsWhenPuffsChange() {
        let use = ProductUse(product: .vape, isPrimary: true, unitsPerDay: VapeUsage.puffsPerDay(podsPerWeek: 2, puffsPerPod: 600),
                             pricePerPurchase: 8, unitsPerPurchase: 600)
        #expect(use.podsPerWeek == 2)
        use.setPuffsPerPod(1000)
        #expect(use.podsPerWeek == 2)
        #expect(abs(use.unitsPerDay - 2000.0 / 7) < 0.001)
    }
}
