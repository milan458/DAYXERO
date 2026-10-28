@testable import DayXero
import DayXeroCore
import Foundation
import Testing

/// Home's streak and adherence card (S19.4).
struct AdherenceTests {
    var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/London")!
        return c
    }()

    func date(_ d: Int, _ h: Int = 10) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: d, hour: h))!
    }

    var clock: DayClock { DayClock(calendar: calendar, boundaryHour: 4) }

    /// Onboarded Thu 22 Oct, Quit Day Thu 29 Oct: 7 prep days.
    var schedule: ProgramSchedule { ProgramSchedule(startedOn: date(22), quitDay: date(29, 0), clock: clock) }

    func prep(_ n: Int...) -> Set<ProgramDayID> { Set(n.map { ProgramDayID(phase: .prep, index: $0) }) }

    @Test func nothingIsDueOnTheFirstDay() {
        #expect(Adherence.fraction(schedule: schedule, startedOn: date(22), completed: [], now: date(22, 20)) == 1)
    }

    @Test func todaysLessonIsntDueUntilTheDayIsOver() {
        // Fri 23 Oct: prep day 1 was due yesterday and is done; today's isn't due yet.
        #expect(Adherence.fraction(schedule: schedule, startedOn: date(22), completed: prep(1), now: date(23, 9)) == 1)
        // Mon 26 Oct: days 1-4 due, three done.
        #expect(Adherence.fraction(schedule: schedule, startedOn: date(22), completed: prep(1, 2, 3), now: date(26, 9)) == 0.75)
    }

    @Test func doingAheadNeverGoesPastAHundred() {
        #expect(Adherence.fraction(schedule: schedule, startedOn: date(22), completed: prep(1, 2, 3), now: date(23, 9)) == 1)
    }

    @Test func quitWeekDaysAreDueOnTheirOwnDay() {
        let s = schedule
        #expect(Adherence.dueDate(of: ProgramDayID(phase: .quit, index: 1), startedOn: date(22), schedule: s) == calendar.startOfDay(for: date(29)))
        #expect(Adherence.dueDate(of: ProgramDayID(phase: .prep, index: 3), startedOn: date(22), schedule: s) == calendar.startOfDay(for: date(24)))
    }

    @Test func theStreakCountsDaysInARowEndingTodayOrYesterday() {
        let done = [date(22, 20), date(23, 9), date(24, 21)]
        #expect(Adherence.streak(completedAt: done, clock: clock, now: date(24, 22)) == 3)
        // Thursday's lesson not done yet: the streak still stands from yesterday.
        #expect(Adherence.streak(completedAt: done, clock: clock, now: date(25, 9)) == 3)
        // A whole day missed: it starts again.
        #expect(Adherence.streak(completedAt: done, clock: clock, now: date(26, 9)) == 0)
        // 2am still counts as the day before.
        #expect(Adherence.streak(completedAt: [date(22, 20), date(24, 2)], clock: clock, now: date(24, 10)) == 2)
    }

    @Test func theUsualCravingCountAveragesRecentDaysThatHadAny() {
        let dates = [date(20, 9), date(20, 15), date(20, 21), date(21, 10), date(23, 11), date(23, 12), date(24, 9)]
        // Today is the 24th: the 20th (3), 21st (1) and 23rd (2) count, today doesn't. 6 / 3 = 2.
        #expect(CravingPace.usual(cravingsAt: dates, clock: clock, now: date(24, 18)) == 2)
        #expect(CravingPace.today(cravingsAt: dates, clock: clock, now: date(24, 18)) == 1)
        #expect(CravingPace.usual(cravingsAt: [date(24, 9)], clock: clock, now: date(24, 18)) == nil)
    }
}
