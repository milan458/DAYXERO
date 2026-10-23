@testable import DayXero
import DayXeroCore
import Foundation
import Testing

struct SlipTests {
    var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/London")!
        return c
    }()

    var clock: DayClock { DayClock(calendar: calendar, boundaryHour: 4) }

    func at(_ day: Int, _ hour: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour))!
    }

    @Test func slipsAreCountedPerDayWithTheLateNightBoundary() {
        // 2am on the 24th still belongs to the 23rd.
        let times = [at(23, 9), at(23, 15), at(24, 2), at(22, 20)]
        #expect(Slips.count(onDayOf: at(23, 22), timestamps: times, clock: clock) == 3)
    }

    @Test func aToughDayStartsAtTheThirdSlip() {
        #expect(!Slips.isToughDay(slipsToday: 2))
        #expect(Slips.isToughDay(slipsToday: 3))
    }

    @Test func whenMovesTheSlipTime() {
        let logged = at(23, 16)
        #expect(Slips.time(.justNow, loggedAt: logged, clock: clock) == logged)
        #expect(Slips.time(.yesterday, loggedAt: logged, clock: clock) == at(22, 16))
        // Halfway between the 4am day start and 4pm.
        #expect(Slips.time(.earlierToday, loggedAt: logged, clock: clock) == at(23, 10))
    }

    @Test func everyTriggerHasFourIdeasForNextTime() {
        for trigger in Trigger.allCases {
            #expect(trigger.nextTimeSuggestions.count == 4)
        }
    }
}
