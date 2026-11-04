import DayXeroCore
import Foundation
import Testing

/// Today's week strip and ring (Today redesign, 4 Nov 2026).
struct TodayWeekTests {
    private var clock: DayClock {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return DayClock(calendar: c, boundaryHour: 4)
    }

    private func date(_ day: Int, _ hour: Int = 12, month: Int = 11) -> Date {
        clock.calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour))!
    }

    private func days(_ week: TodayWeek) -> [Int] {
        week.days.map { clock.calendar.component(.day, from: $0.date) }
    }

    @Test func prepEndsOnQuitDayWithFinishedSessionsTicked() {
        // Wednesday 4 Nov, Quit Day Sunday 8 Nov, prep started Monday, sessions on Monday and Tuesday.
        let week = TodayWeek.make(now: date(4, 9), quitDay: date(8, 0), programStart: date(2, 8),
                                  sessionsDone: [date(2, 20), date(3, 21)], slips: [], clock: clock)
        #expect(days(week) == [2, 3, 4, 5, 6, 7, 8])
        #expect(week.days.map(\.mark) == [.done, .done, .today, .future, .future, .future, .future])
        #expect(week.days.last?.isQuitDay == true)
        #expect(week.days.filter(\.isToday).count == 1)
    }

    @Test func todaysSessionTicksTodayDuringPrep() {
        let week = TodayWeek.make(now: date(4, 21), quitDay: date(8, 0), programStart: date(2, 8),
                                  sessionsDone: [date(4, 13)], slips: [], clock: clock)
        #expect(week.days[2].mark == .done)
        #expect(week.days[2].isToday)
    }

    @Test func daysBeforeTheProgramAreJustDates() {
        let week = TodayWeek.make(now: date(4, 9), quitDay: date(8, 0), programStart: date(4, 8),
                                  sessionsDone: [], slips: [], clock: clock)
        #expect(week.days.prefix(2).map(\.mark) == [.before, .before])
    }

    @Test func aLongPrepStartsTheDayBeforeToday() {
        let week = TodayWeek.make(now: date(4, 9), quitDay: date(24, 0), programStart: date(1, 8),
                                  sessionsDone: [], slips: [], clock: clock)
        #expect(days(week) == [3, 4, 5, 6, 7, 8, 9])
        #expect(!week.days.contains(where: \.isQuitDay))
    }

    @Test func quitDayItselfEndsTheWeek() {
        let week = TodayWeek.make(now: date(8, 9), quitDay: date(8, 0), programStart: date(2, 8),
                                  sessionsDone: [], slips: [], clock: clock)
        #expect(days(week) == [2, 3, 4, 5, 6, 7, 8])
        #expect(week.days.last?.isToday == true)
        #expect(week.days.last?.isQuitDay == true)
        #expect(week.days.last?.mark == .today)
    }

    @Test func afterQuitDayATickIsADayWithNoSlipLikeResilience() {
        // Day 4: Quit Day Sunday 8, today Wednesday 11, a slip on Tuesday.
        let slips = [date(10, 22)]
        let week = TodayWeek.make(now: date(11, 9), quitDay: date(8, 0), programStart: date(2, 8),
                                  sessionsDone: [], slips: slips, clock: clock)
        #expect(days(week) == [8, 9, 10, 11, 12, 13, 14])
        #expect(week.days.map(\.mark) == [.done, .done, .quiet, .today, .future, .future, .future])
        #expect(week.days.first?.isQuitDay == true)
        let resilience = Resilience.days(quitDay: date(8, 0), slips: slips, now: date(11, 9), clock: clock)
        let ticks = week.days.filter { $0.mark == .done }.count
        // Today isn't over, so it's counted by Resilience but not yet ticked.
        #expect(ticks == resilience.clear - 1)
    }

    @Test func laterTheWeekKeepsThreeDaysBehindToday() {
        let week = TodayWeek.make(now: date(30, 9), quitDay: date(8, 0), programStart: date(2, 8),
                                  sessionsDone: [], slips: [], clock: clock)
        #expect(days(week) == [27, 28, 29, 30, 1, 2, 3])
        #expect(week.days[3].isToday)
    }

    @Test func theDayRollsOverAtTheBoundaryHour() {
        // 2 am on Thursday still counts as Wednesday with a 4 am boundary.
        let week = TodayWeek.make(now: date(5, 2), quitDay: date(8, 0), programStart: date(2, 8),
                                  sessionsDone: [], slips: [], clock: clock)
        #expect(week.days.first(where: \.isToday).map { clock.calendar.component(.day, from: $0.date) } == 4)
    }

    @Test func theRingFillsToTheNextCountedChange() {
        #expect(TodayRing.fraction(elapsedHours: 84, nextChangeFromHours: 168) == 0.5)
        #expect(TodayRing.fraction(elapsedHours: 200, nextChangeFromHours: 168) == 1)
        #expect(TodayRing.fraction(elapsedHours: 10, nextChangeFromHours: nil) == nil)
    }
}
