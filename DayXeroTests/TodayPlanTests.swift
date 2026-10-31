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
}
