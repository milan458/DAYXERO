@testable import DayXero
import DayXeroCore
import Foundation
import Testing

@MainActor
final class StubStore: PurchaseStore {
    var plans: [PlanOption] = [
        PlanOption(plan: .annual, price: 39.99, currencyCode: "USD", priceText: "$39.99", perMonthText: "$3.33", trialDays: 3),
        PlanOption(plan: .monthly, price: 9.99, currencyCode: "USD", priceText: "$9.99", perMonthText: nil, trialDays: nil),
        PlanOption(plan: .lifetime, price: 79.99, currencyCode: "USD", priceText: "$79.99", perMonthText: nil, trialDays: nil),
    ]
    var failLoad = false
    var outcome: PurchaseOutcome = .purchased
    var restoreFinds = false

    func loadPlans() async throws -> [PlanOption] {
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

    // MARK: The trial waits for Quit Day (decisions 15 and 23)

    @Test func beforeQuitDayThePlanWithTheTrialIsHeldBack() async {
        let (model, _) = make(StubStore())
        model.trialOpensOn = now.addingTimeInterval(7 * 86_400)
        await model.load()
        #expect(model.isBeforeQuitDay)
        #expect(model.heldTrialDays == 3)
        #expect(model.plans.map(\.plan) == [.monthly, .lifetime])
        #expect(model.plans.allSatisfy { $0.trialDays == nil })
        #expect(model.selected == .monthly)
        #expect(model.trialEndDate == nil)
    }

    @Test func onQuitDayTheTrialIsOffered() async {
        let (model, _) = make(StubStore())
        // Later the same day still counts as Quit Day.
        model.trialOpensOn = now.addingTimeInterval(3_600)
        await model.load()
        #expect(!model.isBeforeQuitDay)
        #expect(model.heldTrialDays == nil)
        #expect(model.selected == .annual)
        #expect(model.trialEndDate == now.addingTimeInterval(3 * 86_400))
    }

    @Test func withoutAQuitDayEveryPlanIsOffered() async {
        let (model, _) = make(StubStore())
        await model.load()
        #expect(model.plans.count == 3)
        #expect(model.heldTrialDays == nil)
    }

    @Test func aYearlyPlanWithoutATrialIsStillSoldBeforeQuitDay() async {
        let store = StubStore()
        store.plans[0] = PlanOption(plan: .annual, price: 39.99, currencyCode: "USD", priceText: "$39.99", perMonthText: "$3.33", trialDays: nil)
        let (model, _) = make(store)
        model.trialOpensOn = now.addingTimeInterval(7 * 86_400)
        await model.load()
        #expect(model.plans.count == 3)
        #expect(model.heldTrialDays == nil)
        #expect(model.selected == .annual)
    }

    @Test func thePlanTitleFallsBackWithoutAName() {
        #expect(PaywallView.readyTitle(name: "Milan") == "Milan, your plan is ready")
        #expect(PaywallView.readyTitle(name: "") == "Your plan is ready")
        #expect(PaywallView.readyTitle(name: "  ") == "Your plan is ready")
    }

    @Test func freeSessionsAreAllOfPrepAndDayXero() {
        #expect(ProgramV2Access.freeSessions == ["P1", "P2", "P3", "P4", "P5", "P6", "P7", "DX"])
        #expect(!ProgramV2Access.needsUpgrade("P7", isPro: false))
        #expect(!ProgramV2Access.needsUpgrade("DX", isPro: false))
    }

    /// Prep week and Quit Day are free (decisions 15 and 23); Quit week day 2 onwards needs Pro.
    @Test func prepWeekAndQuitDayAreFree() {
        let outline = [ProgramDayID(phase: .prep, index: 1), ProgramDayID(phase: .prep, index: 2),
                       ProgramDayID(phase: .quit, index: 1), ProgramDayID(phase: .quit, index: 2)]
        let engine = ProgramEngine(outline: outline)
        #expect(FreeTier.canOpen(outline[0], engine: engine, completed: [], isPro: false))
        #expect(FreeTier.canOpen(outline[1], engine: engine, completed: [outline[0]], isPro: false))
        #expect(FreeTier.canOpen(outline[2], engine: engine, completed: Set(outline[0...1]), isPro: false))
        #expect(!FreeTier.canOpen(outline[3], engine: engine, completed: Set(outline[0...2]), isPro: false))
        #expect(FreeTier.canOpen(outline[3], engine: engine, completed: Set(outline[0...2]), isPro: true))
    }
}
