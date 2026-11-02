import DayXeroCore
import Foundation
import Testing

struct TodayPlanTests {
    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }

    private func date(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute))!
    }

    @Test func slotsFollowTheHour() {
        #expect(TodaySlot(hour: 5) == .morning)
        #expect(TodaySlot(hour: 11) == .morning)
        #expect(TodaySlot(hour: 12) == .afternoon)
        #expect(TodaySlot(hour: 17) == .evening)
        #expect(TodaySlot(hour: 22) == .night)
        #expect(TodaySlot(hour: 3) == .night)
    }

    @Test func aWaveNeedsThreeCravingsOnTwoDays() {
        let now = date(8, 7)
        let two: [(time: Date, trigger: Trigger?)] = [(date(6, 9, 30), .coffee), (date(7, 9, 50), .coffee)]
        #expect(CravingPattern.usualWave(two, now: now, calendar: calendar) == nil)
        let sameDay: [(time: Date, trigger: Trigger?)] = [(date(7, 9, 30), .coffee), (date(7, 9, 40), .coffee), (date(7, 9, 50), .coffee)]
        #expect(CravingPattern.usualWave(sameDay, now: now, calendar: calendar) == nil)
    }

    @Test func theWaveIsTheAverageTimeAndTheCommonTrigger() {
        let now = date(8, 7)
        let log: [(time: Date, trigger: Trigger?)] = [
            (date(5, 9, 30), .coffee), (date(6, 9, 40), .coffee), (date(7, 9, 50), nil), (date(7, 15, 0), .stress),
        ]
        let wave = CravingPattern.usualWave(log, now: now, calendar: calendar)
        #expect(wave == UsualWave(minuteOfDay: 9 * 60 + 40, trigger: .coffee))
    }

    @Test func onlyWavesStillToComeToday() {
        let log: [(time: Date, trigger: Trigger?)] = [(date(5, 9, 30), .coffee), (date(6, 9, 40), .coffee), (date(7, 9, 50), .coffee)]
        #expect(CravingPattern.usualWave(log, now: date(8, 11), calendar: calendar) == nil)
    }

    @Test func oldCravingsDontCount() {
        let log: [(time: Date, trigger: Trigger?)] = [(date(1, 9, 30), .coffee), (date(2, 9, 40), .coffee), (date(3, 9, 50), .coffee)]
        #expect(CravingPattern.usualWave(log, now: date(30, 7), calendar: calendar) == nil)
    }

    @Test func topCardByTimeOfDay() {
        let wave = UsualWave(minuteOfDay: 580, trigger: .coffee)
        #expect(TodayTopCard.pick(slot: .morning, wave: wave, checkedIn: false) == .wave(wave))
        #expect(TodayTopCard.pick(slot: .morning, wave: nil, checkedIn: false) == .lesson)
        #expect(TodayTopCard.pick(slot: .afternoon, wave: wave, checkedIn: false) == .lesson)
        #expect(TodayTopCard.pick(slot: .evening, wave: nil, checkedIn: false) == .checkIn)
        #expect(TodayTopCard.pick(slot: .evening, wave: nil, checkedIn: true) == .lesson)
        #expect(TodayTopCard.pick(slot: .night, wave: nil, checkedIn: false) == .windDown)
    }

    // MARK: Focus slot (UX-08)

    @Test func theLessonUntilSixThenTheCheckIn() {
        #expect(TodayFocus.pick(hour: 6, postQuit: false, checkedIn: false) == .lesson)
        #expect(TodayFocus.pick(hour: 17, postQuit: false, checkedIn: false) == .lesson)
        #expect(TodayFocus.pick(hour: 18, postQuit: false, checkedIn: false) == .checkIn)
        #expect(TodayFocus.pick(hour: 23, postQuit: false, checkedIn: false) == .checkIn)
        #expect(TodayFocus.pick(hour: 2, postQuit: false, checkedIn: false) == .checkIn)
    }

    @Test func noEveningCardInTheMorning() {
        for hour in 6..<18 {
            #expect(TodayFocus.pick(hour: hour, postQuit: false, checkedIn: false) == .lesson)
            #expect(TodayFocus.pick(hour: hour, postQuit: true, checkedIn: false) == .recovery)
        }
    }

    @Test func afterTheCheckInTheLessonComesBackThenWindingDown() {
        #expect(TodayFocus.pick(hour: 19, postQuit: false, checkedIn: true) == .lesson)
        #expect(TodayFocus.pick(hour: 19, postQuit: true, checkedIn: true) == .recovery)
        #expect(TodayFocus.pick(hour: 22, postQuit: true, checkedIn: true) == .windDown)
        #expect(TodayFocus.pick(hour: 3, postQuit: false, checkedIn: true) == .windDown)
    }

    // MARK: Hero numbers (UX-05, UX-09)

    @Test func timeFreeIsShort() {
        let en = Locale(identifier: "en_US")
        #expect(TimeFree.short(3 * 86_400 + 14 * 3_600 + 20 * 60, locale: en) == "3d 14h")
        #expect(TimeFree.short(5 * 3_600 + 20 * 60 + 59, locale: en) == "5h 20m")
        #expect(TimeFree.short(45 * 60 + 30, locale: en) == "45m")
        #expect(TimeFree.short(20, locale: en) == "0m")
    }

    @Test func resilienceIsTheShareOfDaysWithoutASlip() {
        let clock = DayClock(calendar: calendar, boundaryHour: 4)
        let quitDay = date(5, 0)
        #expect(Resilience.percent(quitDay: quitDay, slips: [], now: date(8, 10), clock: clock) == 100)
        // Before Quit Day there's nothing to lose.
        #expect(Resilience.percent(quitDay: quitDay, slips: [], now: date(3, 10), clock: clock) == 100)
        // Day 4 of 4, with two slips on one day: 3 of 4 days clear.
        #expect(Resilience.percent(quitDay: quitDay, slips: [date(6, 13), date(6, 20)], now: date(8, 10), clock: clock) == 75)
        // A slip at 2 AM counts for the day before; prep-week uses don't count at all.
        #expect(Resilience.percent(quitDay: quitDay, slips: [date(7, 2), date(2, 12)], now: date(8, 10), clock: clock) == 75)
        // One slip in three days rounds down, so only a clean run shows 100%.
        #expect(Resilience.percent(quitDay: quitDay, slips: [date(5, 12)], now: date(7, 10), clock: clock) == 66)
    }
}
