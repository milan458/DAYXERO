@testable import DayXero
import DayXeroCore
import Foundation
import Testing

@MainActor
final class StubStore: PurchaseStore {
    var plans: [PlanOption] = [
        PlanOption(plan: .annual, price: 39.99, currencyCode: "USD", priceText: "$39.99", perMonthText: "$3.33", trialDays: 3),
        PlanOption(plan: .monthly, price: 9.99, currencyCode: "USD", priceText: "$9.99", perMonthText: nil, trialDays: nil),
        PlanOption(plan: .lifetime, price: 99.99, currencyCode: "USD", priceText: "$99.99", perMonthText: nil, trialDays: nil),
    ]
    var failLoad = false
    /// What the last load asked for: true on an offer day.
    var askedForOffer: Bool?
    var outcome: PurchaseOutcome = .purchased
    var restoreFinds = false

    func loadPlans(offer: Bool) async throws -> [PlanOption] {
        askedForOffer = offer
        if failLoad { throw StoreError.unavailable }
        return plans
    }
    func purchase(_ plan: Plan) async throws -> PurchaseOutcome { outcome }
    func restore() async throws -> Bool { restoreFinds }
    func hasPro() async -> Bool { false }
}

@MainActor
struct PaywallModelTests {
    let now = Date(timeIntervalSince1970: 1_792_670_400) // Thu 22 Oct 2026

    func make(_ store: StubStore) -> (PaywallModel, Entitlement) {
        let entitlement = Entitlement(store: store)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let model = PaywallModel(store: store, entitlement: entitlement, calendar: calendar, now: { [now] in now })
        model.installedOn = nil
        return (model, entitlement)
    }

    @Test func yearlyIsPreselectedAndTheTrialEndDateIsExact() async {
        let (model, _) = make(StubStore())
        await model.load()
        #expect(model.phase == .ready)
        #expect(model.selected == .annual)
        #expect(model.trialEndDate == now.addingTimeInterval(3 * 86_400))
    }

    @Test func noTrialDateForPlansWithoutATrial() async {
        let (model, _) = make(StubStore())
        await model.load()
        model.select(.monthly)
        #expect(model.trialEndDate == nil)
    }

    @Test func savingIsRoundedDownSoItsNeverOverstated() async {
        let (model, _) = make(StubStore())
        await model.load()
        // 39.99 vs 12 × 9.99 = 119.88 → 66.6% → shown as 66%.
        #expect(model.annualSavingPercent == 66)
    }

    @Test func noSavingShownWhenItIsntReal() async {
        let store = StubStore()
        store.plans[0] = PlanOption(plan: .annual, price: 119, currencyCode: "USD", priceText: "$119", perMonthText: nil, trialDays: nil)
        let (model, _) = make(store)
        await model.load()
        #expect(model.annualSavingPercent == nil)
    }

    @Test func failedLoadShowsTheErrorState() async {
        let store = StubStore()
        store.failLoad = true
        let (model, _) = make(store)
        await model.load()
        #expect(model.phase == .failed)
    }

    @Test func purchaseUnlocks() async {
        let (model, entitlement) = make(StubStore())
        await model.load()
        model.select(.lifetime)
        await model.purchase()
        #expect(model.phase == .unlocked)
        #expect(entitlement.isPro)
    }

    @Test func pendingAndCancelledDontUnlock() async {
        let store = StubStore()
        let (model, entitlement) = make(store)
        await model.load()
        store.outcome = .pending
        await model.purchase()
        #expect(model.phase == .pending)
        store.outcome = .cancelled
        await model.load()
        await model.purchase()
        #expect(model.phase == .ready)
        #expect(!entitlement.isPro)
    }

    @Test func restoreWithNothingFoundExplainsWhy() async {
        let (model, entitlement) = make(StubStore())
        await model.load()
        await model.restore()
        #expect(model.notice != nil)
        #expect(!entitlement.isPro)
    }

    // MARK: The trial is sold whenever the Quit Day is (MON-01)

    @Test func beforeQuitDayEveryPlanIsSoldWithItsTrial() async {
        let (model, _) = make(StubStore())
        model.quitDay = now.addingTimeInterval(7 * 86_400)
        await model.load()
        #expect(model.plans.map(\.plan) == [.annual, .monthly, .lifetime])
        #expect(model.selected == .annual)
        #expect(model.trialEndDate == now.addingTimeInterval(3 * 86_400))
        // The stub's 3-day trial ends 4 days before a Quit Day a week away; the paywall says so.
        #expect(model.trialEndsAfterQuitDay == -4)
    }

    @Test func aTrialThatRunsPastQuitDaySaysHowFar() async {
        let (model, _) = make(StubStore())
        model.quitDay = now.addingTimeInterval(86_400)
        await model.load()
        #expect(model.trialEndsAfterQuitDay == 2)
        model.select(.monthly)
        #expect(model.trialEndsAfterQuitDay == nil)
    }

    @Test func withoutAQuitDayThereIsNoComparison() async {
        let (model, _) = make(StubStore())
        await model.load()
        #expect(model.plans.count == 3)
        #expect(model.trialEndsAfterQuitDay == nil)
    }

    /// A 7-day trial bought on a prep day ends 7 days later, whatever the Quit Day; the paywall says how that falls.
    @Test func aSevenDayTrialEndsAWeekAfterItStarts() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let quitDay = calendar.date(byAdding: .day, value: 7, to: now)!
        let end = FullProgram.trialEnd(startingOn: now, calendar: calendar)
        #expect(FullProgram.trialEndsDaysAfterQuitDay(trialEnd: end, quitDay: quitDay, calendar: calendar) == 0)
    }

    // MARK: Yearly offer on days 4 and 6 (BET-1)

    @Test func theOfferIsOnDaysFourAndSixAfterDownload() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let clock = DayClock(calendar: calendar, boundaryHour: 4)
        let installed = now // day 1
        let offerDays = (0..<9).filter { day in
            FullProgram.isOfferDay(installedOn: installed, now: calendar.date(byAdding: .day, value: day, to: installed)!, clock: clock)
        }.map { $0 + 1 }
        #expect(offerDays == [4, 6])
        #expect(!FullProgram.isOfferDay(installedOn: nil, now: now, clock: clock))
        // 2am on day 5 still belongs to day 4 with a 4am boundary, so the offer holds until the person's day ends.
        let day5At2am = calendar.date(byAdding: .hour, value: 4 * 24 + 2, to: calendar.startOfDay(for: installed))!
        #expect(FullProgram.dayNumber(installedOn: installed, now: day5At2am, clock: clock) == 4)
    }

    @Test func theModelAsksForTheOfferOnlyOnOfferDays() async {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let store = StubStore()
        let (model, _) = make(store)
        model.installedOn = calendar.date(byAdding: .day, value: -3, to: now) // today is day 4
        await model.load()
        #expect(store.askedForOffer == true)
        model.installedOn = calendar.date(byAdding: .day, value: -4, to: now) // day 5
        await model.load()
        #expect(store.askedForOffer == false)
    }

    @Test func anOfferProductCountsAsTheYearlyPlan() {
        #expect(Plan(productId: Plan.annualOfferProductId) == .annual)
        #expect(Plan(productId: "dayxero.monthly") == .monthly)
        #expect(Plan(productId: "something.else") == nil)
    }

    // MARK: Price anchor (MON-03)

    @Test func theAnchorIsTheYearlyPriceInDaysOfTheirOwnSpend() async throws {
        let (model, _) = make(StubStore())
        // $5 a day: $39.99 is 7.998 days, shown as 8 (rounded up, so it never understates the price).
        model.spend = PaywallModel.Spend(perYear: 5 * 365, currencyCode: "USD", products: [.cigarettes])
        await model.load()
        let annual = try #require(model.plans.first { $0.plan == .annual })
        #expect(model.anchor(for: annual) == PriceAnchor(days: 8, habit: .smoking))
        #expect(PriceAnchorLine.title(PriceAnchor(days: 8, habit: .smoking)) == "Costs 8 days of smoking")
        #expect(PriceAnchorLine.title(PriceAnchor(days: 1, habit: .vaping)) == "Costs 1 day of vaping")
    }

    @Test func noAnchorWithoutAnHonestComparison() {
        // Another currency, no spend, or more than 90 days of it.
        #expect(PriceAnchor.make(price: 2999, priceCurrency: "INR", spendPerYear: 1825, spendCurrency: "USD", products: [.vape]) == nil)
        #expect(PriceAnchor.make(price: 39.99, priceCurrency: "USD", spendPerYear: 0, spendCurrency: "USD", products: [.vape]) == nil)
        #expect(PriceAnchor.make(price: 39.99, priceCurrency: "USD", spendPerYear: 100, spendCurrency: "USD", products: [.vape]) == nil)
        // Currency codes compare without case.
        #expect(PriceAnchor.make(price: 2999, priceCurrency: "INR", spendPerYear: 73_000, spendCurrency: "inr", products: [.pouches])
                == PriceAnchor(days: 15, habit: .pouches))
        // Two products: the spend is all of it, said as nicotine.
        #expect(PriceAnchor.make(price: 39.99, priceCurrency: "USD", spendPerYear: 3650, spendCurrency: "USD", products: [.vape, .cigarettes])
                == PriceAnchor(days: 4, habit: .nicotine))
    }

    @Test func thePlanTitleFallsBackWithoutAName() {
        #expect(PaywallView.readyTitle(name: "Milan") == "Milan, your plan is ready")
        #expect(PaywallView.readyTitle(name: "") == "Your plan is ready")
        #expect(PaywallView.readyTitle(name: "  ") == "Your plan is ready")
    }

    /// BET-1: every prep session opens for its free part (intro and two cards); Day Xero and the weeks need the full program.
    @Test func prepSessionsOpenForTheirFreePart() {
        #expect(ProgramV2Access.previewSessions == ["P1", "P2", "P3", "P4", "P5", "P6", "P7"])
        #expect(FullProgram.previewCards == 2)
        #expect(FullProgram.access(sessionId: "P1", isPro: false) == .preview)
        #expect(FullProgram.access(sessionId: "P7", isPro: false) == .preview)
        #expect(FullProgram.access(sessionId: "DX", isPro: false) == .locked)
        #expect(FullProgram.access(sessionId: "W1D1", isPro: false) == .locked)
        #expect(FullProgram.access(sessionId: "P4", isPro: true) == .full)
        #expect(!ProgramV2Access.needsUpgrade("P4", isPro: false))
        #expect(ProgramV2Access.needsUpgrade("DX", isPro: false))
        // A session finished while subscribed stays open in full for replay.
        #expect(FullProgram.access(sessionId: "W1D2", isPro: false, completed: true) == .full)
        #expect(FullProgram.Feature.allCases.allSatisfy { FullProgram.has($0, isPro: true) && !FullProgram.has($0, isPro: false) })
    }

    /// The old day-based program follows the same line: prep days open, Quit Day onwards needs Pro.
    @Test func prepDaysOpenAndQuitDaysNeedPro() {
        let outline = (1...4).map { ProgramDayID(phase: .prep, index: $0) } + [ProgramDayID(phase: .quit, index: 1)]
        let engine = ProgramEngine(outline: outline)
        #expect(FreeTier.canOpen(outline[0], engine: engine, completed: [], isPro: false))
        #expect(FreeTier.canOpen(outline[3], engine: engine, completed: Set(outline[0...2]), isPro: false))
        #expect(!FreeTier.canOpen(outline[4], engine: engine, completed: Set(outline[0...3]), isPro: false))
        #expect(FreeTier.canOpen(outline[4], engine: engine, completed: Set(outline[0...3]), isPro: true))
        #expect(!FreeTier.isFree(outline[4], in: outline))
    }
}
