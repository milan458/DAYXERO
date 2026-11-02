import DayXeroCore
import Foundation
import Testing

/// The clinical review changes (CLIN-01 to CLIN-11, 2 Nov 2026) that live in DayXeroCore.
struct ClinicalTests {
    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }

    private var clock: DayClock { DayClock(calendar: calendar, boundaryHour: 4) }

    private func date(_ day: Int, _ hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour))!
    }

    // MARK: CLIN-02

    /// Smoke, not nicotine, speeds caffeine up: so smokers who named coffee, from Quit Day through its first week.
    @Test func theCoffeeNoteIsForSmokersInQuitWeek() {
        #expect(CaffeineAlert.applies(products: [.cigarettes], triggers: [.coffee], daysSinceQuit: 0))
        #expect(CaffeineAlert.applies(products: [.vape, .cigarettes], triggers: [.stress, .coffee], daysSinceQuit: 6))
        #expect(!CaffeineAlert.applies(products: [.cigarettes], triggers: [.coffee], daysSinceQuit: 7))
        #expect(!CaffeineAlert.applies(products: [.cigarettes], triggers: [.coffee], daysSinceQuit: -1))
        #expect(!CaffeineAlert.applies(products: [.cigarettes], triggers: [.stress], daysSinceQuit: 2))
        #expect(!CaffeineAlert.applies(products: [.vape, .pouches], triggers: [.coffee], daysSinceQuit: 2))
        #expect(String(localized: CaffeineAlert.body).contains("halve your coffee this week"))
    }

    // MARK: CLIN-05

    private func uses(_ product: Product, perDay: Int, days: ClosedRange<Int>) -> [(product: Product, time: Date)] {
        days.flatMap { day in (0..<perDay).map { _ in (product: product, time: date(day)) } }
    }

    @Test func theSwapTrapFlagsCigarettesDownPouchesUp() {
        let baselines: [Product: Double] = [.cigarettes: 20, .pouches: 4]
        let swapped = uses(.cigarettes, perDay: 10, days: 2...4) + uses(.pouches, perDay: 9, days: 2...4)
        let finding = SwapTrap.check(uses: swapped, baselines: baselines, since: date(1), now: date(5), clock: clock)
        #expect(finding == SwapTrap.Finding(falling: [.cigarettes], rising: .pouches))

        // Both coming down: no flag.
        let both = uses(.cigarettes, perDay: 10, days: 2...4) + uses(.pouches, perDay: 3, days: 2...4)
        #expect(SwapTrap.check(uses: both, baselines: baselines, since: date(1), now: date(5), clock: clock) == nil)
        // Pouches up but cigarettes steady: no flag.
        let steady = uses(.cigarettes, perDay: 19, days: 2...4) + uses(.pouches, perDay: 9, days: 2...4)
        #expect(SwapTrap.check(uses: steady, baselines: baselines, since: date(1), now: date(5), clock: clock) == nil)
        // Today doesn't count, and one full day isn't enough.
        let today = uses(.cigarettes, perDay: 2, days: 5...5) + uses(.pouches, perDay: 20, days: 5...5)
        #expect(SwapTrap.check(uses: today, baselines: baselines, since: date(4), now: date(5), clock: clock) == nil)
        // Nobody who doesn't use pouches gets it.
        #expect(SwapTrap.check(uses: swapped, baselines: [.cigarettes: 20], since: date(1), now: date(5), clock: clock) == nil)
    }

    @Test func theSwapTrapCatchesVapeToo() {
        let baselines: [Product: Double] = [.vape: 200, .pouches: 5]
        let swapped = uses(.vape, perDay: 100, days: 3...4) + uses(.pouches, perDay: 8, days: 3...4)
        #expect(SwapTrap.check(uses: swapped, baselines: baselines, since: date(3), now: date(5), clock: clock)?.falling == [.vape])
    }

    // MARK: CLIN-09

    @Test func finishingATaskIsATrigger() {
        #expect(Trigger.allCases.contains(.finishedTask))
        #expect(String(localized: Trigger.finishedTask.title) == "Finished a task / chore")
        #expect(Trigger.finishedTask.nextTimeSuggestions.count == 4)
        // Saved values from before still read back.
        #expect(Trigger(rawValue: "phone") == .phone)
    }

    // MARK: CLIN-11

    @Test func everyPrepDayHasItsOwnChallenge() {
        #expect(PrepChallenge.all.count >= 7)
        #expect(Set(PrepChallenge.all.map(\.id)).count == PrepChallenge.all.count)
        let week = (1...7).map { PrepChallenge.forPrepDay($0).id }
        #expect(Set(week).count == 7)
        // A longer prep goes round again; nonsense days fall back to the first.
        #expect(PrepChallenge.forPrepDay(PrepChallenge.all.count + 1) == PrepChallenge.all[0])
        #expect(PrepChallenge.forPrepDay(0) == PrepChallenge.all[0])
    }
}
