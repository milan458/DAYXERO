@testable import DayXero
import DayXeroCore
import Foundation
import Testing

struct DailyRhythmTests {
    var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/London")!
        c.firstWeekday = 2
        return c
    }()

    func at(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour, minute: minute))!
    }

    func rhythm(boundary: Int = 4) -> DailyRhythm { DailyRhythm(clock: DayClock(calendar: calendar, boundaryHour: boundary)) }

    @Test func pledgeInTheMorningCheckInInTheEvening() {
        let r = rhythm()
        #expect(!r.isPledgeTime(at(24, 3)))
        #expect(r.isPledgeTime(at(24, 4)))
        #expect(r.isPledgeTime(at(24, 11, 59)))
        #expect(!r.isPledgeTime(at(24, 12)))
        #expect(!r.isCheckInTime(at(24, 17, 59)))
        #expect(r.isCheckInTime(at(24, 18)))
        #expect(r.isCheckInTime(at(25, 1)))
        #expect(!r.isCheckInTime(at(25, 4)))
    }

    @Test func aLateCheckInCountsForTheDayJustLived() {
        let r = rhythm()
        // 1am on Sunday still belongs to Saturday.
        #expect(calendar.isDate(r.day(at: at(25, 1)), inSameDayAs: at(24, 12)))
        #expect(r.hasCheckedIn([r.day(at: at(25, 1))], at: at(24, 21)))
        // With midnight as the end of the day, it's Sunday.
        #expect(calendar.isDate(rhythm(boundary: 0).day(at: at(25, 1)), inSameDayAs: at(25, 12)))
    }

    @Test func reasonsWithPhotosComeFirstThenTakeTurns() {
        let photos = [false, true, false]
        #expect(DailyRhythm.reasonIndex(hasPhoto: photos, dayNumber: 0) == 1)
        #expect(DailyRhythm.reasonIndex(hasPhoto: photos, dayNumber: 1) == 0)
        #expect(DailyRhythm.reasonIndex(hasPhoto: photos, dayNumber: 2) == 2)
        #expect(DailyRhythm.reasonIndex(hasPhoto: photos, dayNumber: 3) == 1)
        #expect(DailyRhythm.reasonIndex(hasPhoto: photos, dayNumber: -2) != nil)
        #expect(DailyRhythm.reasonIndex(hasPhoto: [], dayNumber: 1) == nil)
    }

    @Test func remindersSkipWhatsAlreadyDoneToday() {
        let r = rhythm()
        let now = at(24, 7)
        let all = r.reminders(pledgeMinute: 480, checkInMinute: 1260, pledgedToday: false, checkedInToday: false, now: now)
        #expect(all.count == 14)
        let pledged = r.reminders(pledgeMinute: 480, checkInMinute: 1260, pledgedToday: true, checkedInToday: false, now: now)
        #expect(pledged.count == 13)
        #expect(!pledged.contains { $0.id == "daily.pledge.20261024" })
        let off = r.reminders(pledgeMinute: nil, checkInMinute: nil, pledgedToday: false, checkedInToday: false, now: now)
        #expect(off.isEmpty)
        // Past times today aren't scheduled.
        let evening = r.reminders(pledgeMinute: 480, checkInMinute: 1260, pledgedToday: false, checkedInToday: false, now: at(24, 22))
        #expect(evening.count == 12)
    }

    @Test func weekRowMarksCheckInDays() {
        let r = rhythm()
        // Saturday 24 Oct; check-ins Monday and Wednesday.
        let week = r.weekCheckIns([r.day(at: at(19, 21)), r.day(at: at(21, 21))], at: at(24, 21))
        #expect(week == [true, false, true, false, false, false, false])
    }
}
