import DayXeroCore
import Foundation
import Testing

struct ProgressStatsTests {
    var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/London")!
        return c
    }()

    func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 0, _ min: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }

    var vape: Baseline {
        // 200 puffs a day, £8.00 for a 600-puff pod.
        Baseline(product: .vape, unitsPerDay: 200, pricePerPurchase: 8, unitsPerPurchase: 600)
    }

    func stats(boundary: Int = 4) -> ProgressStats {
        ProgressStats(quitDay: date(2026, 11, 1), baselines: [vape], clock: DayClock(calendar: calendar, boundaryHour: boundary))
    }

    @Test func prepPhaseCountsDownToQuitDay() {
        let now = date(2026, 10, 29, 12)
        #expect(stats().isPrep(at: now))
        #expect(stats().daysUntilQuitDay(at: now) == 3)
        #expect(stats().daysClear(at: now) == 0)
        #expect(stats().moneyKept(at: now) == 0)
    }

    @Test func quitDayIsDayOne() {
        #expect(stats().daysClear(at: date(2026, 11, 1, 12)) == 1)
        #expect(stats().daysClear(at: date(2026, 11, 3, 12)) == 3)
    }

    @Test func lateNightStillCountsAsTheSameDay() {
        // 1:30am on 3 Nov with a 4am boundary still belongs to 2 Nov.
        #expect(stats().daysClear(at: date(2026, 11, 3, 1, 30)) == 2)
        #expect(stats(boundary: 0).daysClear(at: date(2026, 11, 3, 1, 30)) == 3)
    }

    @Test func moneyAndUnitsFollowTheBaseline() {
        // Two full days after the Quit Day boundary (4am on 1 Nov).
        let now = date(2026, 11, 3, 4)
        #expect(stats().unitsAvoided(at: now)[.vape] == 400)
        #expect(stats().moneyKept(at: now) == Decimal(string: "5.33"))
    }

    @Test func yearlyProjection() {
        // 200/600 * £8 = £2.666… a day.
        let perYear = NSDecimalNumber(decimal: stats().moneyPerYear).doubleValue
        #expect(abs(perYear - 973.33) < 0.01)
    }
}
