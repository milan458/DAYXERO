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
}
