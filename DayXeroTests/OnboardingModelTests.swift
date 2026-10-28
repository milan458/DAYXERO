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

    @Test func welcomeGoesStraightToProductsAndTheAgeCheckIsTheFooter() {
        let model = makeModel()
        #expect(model.sequence.prefix(2) == [.welcome, .products])
        model.next()
        #expect(model.step == .products)
        #expect(!model.canContinue)
    }

    @Test func stepsRunInTheNewOrder() {
        let model = makeModel()
        model.products = [.cigarettes, .vape]
        #expect(model.sequence == [.welcome, .products, .baseline(.cigarettes), .baseline(.vape), .baselineSummary, .triggers,
                                   .personal, .pastAttempts, .nrt, .quitDay, .building, .reveal, .trial])
    }

    @Test func requiredStepsBlockContinueUntilAnswered() {
        let model = makeModel()
        model.products = [.cigarettes]
        func go(to step: OnboardingStep) { while model.step != step { model.next() } }

        go(to: .triggers)
        #expect(!model.canContinue)
        model.firstUse = .withinThirty
        #expect(!model.canContinue)
        model.triggers = [.coffee]
        #expect(model.canContinue)

        model.next()
        #expect(model.step == .personal)
        model.name = "  "
        model.why.text = "Breathe easier."
        #expect(!model.canContinue)
        model.name = "Milan"
        #expect(model.canContinue)
        model.why.text = " "
        #expect(!model.canContinue)
        model.why.text = "Breathe easier."

        model.next()
        model.pastAttempts = .onceOrTwice
        #expect(!model.canContinue, "Tried before: say what got in the way")
        model.obstacles = [.stress]
        #expect(model.canContinue)
        model.pastAttempts = .notYet
        #expect(model.canContinue)

        model.next()
        #expect(model.step == .nrt)
        #expect(!model.canContinue)
        model.nrtInterest = .notInterested
        #expect(model.canContinue)
    }

    @Test func baselinesStartOnTheRegionsUsualPrices() {
        let gbp = makeModel()
        #expect(gbp.baseline(for: .cigarettes).price == 15)
        #expect(gbp.baseline(for: .cigarettes).isComplete)
        #expect(gbp.baseline(for: .vape).strengthMg == 20)
        let india = OnboardingModel(now: now, calendar: .init(identifier: .gregorian), locale: Locale(identifier: "en_IN"))
        #expect(india.baseline(for: .cigarettes).price == 500)
        #expect(india.baseline(for: .vape).price == 800)
        #expect(india.baseline(for: .vape).strengthMg == 50)
        let elsewhere = OnboardingModel(now: now, calendar: .init(identifier: .gregorian), locale: Locale(identifier: "ja_JP"))
        #expect(elsewhere.baseline(for: .cigarettes).price == nil, "No presets: they type the price")
    }

    @Test func theTrialReminderComesTwoDaysBeforeUnlessTheTrialIsTooShort() {
        let day: TimeInterval = 86_400
        #expect(TrialReminder.leadDays(trialEndsAt: now.addingTimeInterval(7 * day), now: now) == 2)
        #expect(TrialReminder.leadDays(trialEndsAt: now.addingTimeInterval(3 * day), now: now) == 2)
        #expect(TrialReminder.leadDays(trialEndsAt: now.addingTimeInterval(2 * day), now: now) == 1)
    }

    @Test func packPresetsFollowPackSize() {
        #expect(PricePresets.pack(currency: "INR", size: 20) == [350, 500, 700])
        #expect(PricePresets.pack(currency: "INR", size: 10) == [180, 250, 350])
        #expect(PricePresets.pack(currency: "INR", size: 1) == [18, 25, 35])
        #expect(PricePresets.pack(currency: "JPY", size: 20).isEmpty)
    }

    @Test func nicotineAndTimeEstimatesMatchTheMockup() {
        // 10 cigarettes and two 600-puff 5% pods a week: about 27 cigarettes' worth.
        let cigarettes = NicotineEstimate.mgPerDay(.cigarettes, unitsPerDay: 10, strength: nil)
        let vape = NicotineEstimate.mgPerDay(.vape, unitsPerDay: VapeUsage.puffsPerDay(podsPerWeek: 2, puffsPerPod: 600), strength: 50)
        #expect(abs(cigarettes - 12) < 0.001)
        #expect(Int(NicotineEstimate.cigarettes(mg: vape).rounded()) == 17)
        #expect(Int(NicotineEstimate.cigarettes(mg: cigarettes + vape).rounded()) == 27)
        #expect(Int(TimeSpent.hoursPerYear(.cigarettes, unitsPerDay: 10).rounded()) == 365)
        #expect(TimeSpent.hoursPerYear(.pouches, unitsPerDay: 10) == 0)
    }

    @Test func dailyMoneyAddsEveryProduct() {
        let model = makeModel()
        model.products = [.cigarettes, .vape]
        model.setBaseline(BaselineDraft(unitsPerDay: 10, price: 500, unitsPerPurchase: 20), for: .cigarettes)
        model.setBaseline(BaselineDraft(unitsPerDay: VapeUsage.puffsPerDay(podsPerWeek: 2, puffsPerPod: 600), price: 800,
                                        unitsPerPurchase: 600), for: .vape)
        // ₹91,250 from cigarettes, plus two ₹800 pods a week (the mockup rounds that to 52 weeks, ₹83,200).
        let yearly = NSDecimalNumber(decimal: model.moneyPerDay * 365).doubleValue
        #expect(abs(yearly - (91_250 + 800 * 2 * 365 / 7.0)) < 1)
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

    @Test func savingWritesTheProfile() throws {
        let container = try DataStore.makeContainer(inMemory: true)
        let context = ModelContext(container)
        let model = makeModel()
        model.name = " Milan "
        model.products = [.vape, .pouches]
        model.setBaseline(BaselineDraft(unitsPerDay: 200, price: 8, unitsPerPurchase: 600), for: .vape)
        model.setBaseline(BaselineDraft(unitsPerDay: 8, price: 6, unitsPerPurchase: 20, strengthMg: 11), for: .pouches)
        model.why = ReasonDraft(text: " Breathe easier ")
        model.triggers = [.coffee]
        model.firstUse = .withinFive
        model.confidence = 6.6
        model.nrtInterest = .using
        model.nrtFormats = [.gum, .patch]

        try model.save(into: context, now: now)

        let profile = try #require(try context.fetch(FetchDescriptor<UserProfile>()).first)
        #expect(profile.name == "Milan")
        #expect(profile.products.count == 2)
        #expect(profile.primaryProduct?.product == .vape)
        #expect(profile.products.first { $0.product == .pouches }?.strengthMg == 11)
        #expect(profile.reasons.map(\.text) == ["Breathe easier"])
        #expect(profile.triggers == [.coffee])
        #expect(profile.firstUse == .withinFive)
        #expect(profile.confidence == 7)
        #expect(profile.nrtFormats == [.patch, .gum])
        #expect(profile.cravingTimesRaw == [TimeOfDay.morning.rawValue])
        #expect(profile.ageConfirmedAt == now)
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
