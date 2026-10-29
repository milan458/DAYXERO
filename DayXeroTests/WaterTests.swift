@testable import DayXero
import DayXeroCore
import Foundation
import SwiftData
import Testing

struct WaterTests {
    /// The reference screens: 72 kg, works out most days, mild → 2,376 + 350 = 2,726 → 2,750 ml, 11 glasses.
    @Test func workedExample() {
        let b = WaterGoal.calculate(weightKg: 72, activity: .worksOut, climate: .mild)
        #expect(b.baseMl == 2376)
        #expect(b.rawMl == 2726)
        #expect(b.goalMl == 2750)
        #expect(b.glasses == 11)
        #expect(b.roundingMl == 24)
    }

    @Test func clampsToOneAndAHalfAndFourLitres() {
        #expect(WaterGoal.calculate(weightKg: 35, activity: .mostlySitting, climate: .mild).goalMl == 1500)
        #expect(WaterGoal.calculate(weightKg: 200, activity: .veryActive, climate: .hot).goalMl == 4000)
    }

    @Test func roundsHalfAGlassUp() {
        // 2,125 ml is exactly between 2,000 and 2,250.
        let kg = 2125.0 / WaterGoal.mlPerKg
        #expect(WaterGoal.calculate(weightKg: kg, activity: .mostlySitting, climate: .mild).goalMl == 2250)
        // Just under the halfway point rounds down.
        #expect(WaterGoal.calculate(weightKg: 2120.0 / 33, activity: .mostlySitting, climate: .mild).goalMl == 2000)
    }

    @Test func activityAndClimateAdd() {
        let b = WaterGoal.calculate(weightKg: 60, activity: .veryActive, climate: .hot)
        #expect(b.activityMl == 700 && b.climateMl == 500)
        #expect(b.rawMl == 1980 + 1200)
        #expect(b.goalMl == 3250)
        #expect(WaterGoal.calculate(weightKg: 60, activity: .onMyFeet, climate: .mild).activityMl == 0)
    }

    @Test func poundsConvertBeforeCalculating() {
        let kg = WaterGoal.kilograms(pounds: 158.73)
        #expect(abs(kg - 72) < 0.01)
        #expect(WaterGoal.calculate(weightKg: kg, activity: .worksOut, climate: .mild).goalMl == 2750)
    }

    @Test func adjustingStaysWithinLimits() {
        #expect(WaterGoal.adjusted(2750, by: 1) == 3000)
        #expect(WaterGoal.adjusted(1500, by: -1) == 1500)
        #expect(WaterGoal.adjusted(4000, by: 1) == 4000)
    }

    @Test func drinksAreWaterOnly() {
        #expect(Drink.allCases.map(\.ml) == [250, 500, 300, 330])
        #expect(Drink.allCases.allSatisfy { $0.hydrationFactor == 1 })
        #expect(!Drink.allCases.map(\.rawValue).contains { ["beer", "wine", "alcohol", "soda", "juice"].contains($0) })
    }

    @Test func formatsLikeTheReference() {
        #expect(WaterFormat.amount(1250, units: .metric) == "1.25")
        #expect(WaterFormat.amount(2750, units: .metric) == "2.75")
        #expect(WaterFormat.amount(1500, units: .metric) == "1.5")
        #expect(WaterFormat.amount(2000, units: .metric) == "2.0")
        #expect(WaterFormat.size(250, units: .imperial) == "8 fl oz")
        #expect(WaterFormat.glasses(1250) == 5)
    }

    @MainActor @Test func totalsUndoAndStreak() throws {
        let container = try DataStore.makeContainer(inMemory: true)
        let context = container.mainContext
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let clock = DayClock(calendar: calendar, boundaryHour: 4)
        let now = Date(timeIntervalSince1970: 1_800_000_000)   // a fixed afternoon
        let today = clock.day(containing: now)

        // Yesterday and the day before met a 1,000 ml goal; today has 750 so far.
        for back in 1...2 {
            for i in 0..<4 { WaterLog.log(.glass, at: now.addingTimeInterval(Double(-back * 86_400 + i * 60)), in: context) }
        }
        WaterLog.log(.glass, at: now.addingTimeInterval(-120), in: context)
        WaterLog.log(.bottle, at: now.addingTimeInterval(-60), in: context)
        let all = try context.fetch(FetchDescriptor<WaterEntry>())
        #expect(WaterDay.total(all, on: today, clock: clock) == 750)
        #expect(WaterDay.streak(all, goalMl: 1000, now: now, clock: clock) == 2)

        WaterLog.log(.tea, at: now, in: context)
        let after = try context.fetch(FetchDescriptor<WaterEntry>())
        #expect(WaterDay.streak(after, goalMl: 1000, now: now, clock: clock) == 3)

        let undone = WaterLog.undoLast(today: today, clock: clock, in: context)
        #expect(undone?.drink == .tea)
        #expect(WaterDay.total(try context.fetch(FetchDescriptor<WaterEntry>()), on: today, clock: clock) == 750)
    }

    @MainActor @Test func onboardingAsksNoWaterQuestionsAndStartsOnTwoLitres() throws {
        let model = OnboardingModel()
        #expect(!model.sequence.map(\.key).contains { $0.hasPrefix("water") })

        let container = try DataStore.makeContainer(inMemory: true)
        model.name = "Sam"
        model.products = [.vape]
        model.setBaseline(BaselineDraft(unitsPerDay: 100, price: 10, unitsPerPurchase: 600), for: .vape)
        try model.save(into: container.mainContext)
        let saved = try #require(try container.mainContext.fetch(FetchDescriptor<WaterProfile>()).first)
        #expect(saved.effectiveGoalMl == 2000)
        #expect(saved.weightKg == nil && saved.heightCm == nil)
    }

    // MARK: Personalise goal (S18.5)

    @Test func theSheetStartsFromTheProfileAndCalculates() {
        let profile = WaterProfile(units: .metric)
        var draft = WaterGoalDraft(profile: profile)
        #expect(draft.weightKg == WaterGoalDraft.startingWeightKg)
        draft.weightKg = 72
        draft.activity = .worksOut
        #expect(draft.goalMl == 2750)
    }

    @Test func adjustingBackToTheCalculationClearsTheOverride() {
        var draft = WaterGoalDraft(units: .metric, weightKg: 72, activity: .worksOut, climate: .mild)
        draft.adjust(by: 1)
        #expect(draft.override == 3000 && draft.goalMl == 3000)
        draft.adjust(by: -1)
        #expect(draft.override == nil && draft.goalMl == 2750)
    }

    @Test func savingWritesTheGoalAndLeavesHeightAlone() {
        let profile = WaterProfile(heightCm: 180, weightKg: 60, units: .metric)
        var draft = WaterGoalDraft(profile: profile)
        draft.weightKg = 72
        draft.activity = .worksOut
        draft.climate = .hot
        draft.adjust(by: 1)
        draft.apply(to: profile)
        #expect(profile.weightKg == 72)
        #expect(profile.heightCm == 180)
        #expect(profile.activity == .worksOut && profile.climate == .hot)
        #expect(profile.goalMl == 3250)
        #expect(profile.goalOverrideMl == 3500)
        #expect(profile.effectiveGoalMl == 3500)
    }
}
