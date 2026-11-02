@testable import DayXero
import DayXeroCore
import Foundation
import Testing

struct NotificationPlanTests {
    var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/London")!
        return c
    }()

    func at(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute))!
    }

    func day(_ d: Int) -> Date { calendar.startOfDay(for: at(d, 12)) }

    @Test func todayTomorrowThenTwoAwayNotesThenNothing() {
        let plan = NotificationPlan.plan(.init(), inputs: .init(now: at(5, 7), pledgedToday: false, checkedInToday: false,
                                                                nextLessonName: "Day 4"), calendar: calendar)
        let kinds = plan.map(\.kind)
        #expect(kinds == [.pledge, .checkIn, .pledge, .checkIn, .away, .away])
        // Pledge and check-in pause while away: nothing after tomorrow but the two notes.
        #expect(plan.filter { $0.kind != .away }.allSatisfy { $0.date < day(7) })
        #expect(plan.last?.date == at(8, 10))
        #expect(plan.first { $0.kind == .away }?.title == "Day 4 is here when you are")
    }

    @Test func nothingForWhatsAlreadyDone() {
        let plan = NotificationPlan.plan(.init(), inputs: .init(now: at(5, 7), pledgedToday: true, checkedInToday: true), calendar: calendar)
        #expect(!plan.contains { $0.date < day(6) })
    }

    @Test func lessonAndMilestoneOnTheirDays() {
        let inputs = NotificationPlan.Inputs(now: at(5, 7), pledgedToday: true, checkedInToday: true,
                                             lessons: [(day(6), "Day 4", 7)], milestones: [(day(6), "One week in"), (day(20), "Two weeks in")])
        let plan = NotificationPlan.plan(.init(), inputs: inputs, calendar: calendar)
        #expect(plan.contains { $0.kind == .lesson && $0.date == at(6, 12) && $0.title == "Day 4 is ready" })
        #expect(plan.filter { $0.kind == .milestone }.map(\.title) == ["Today: One week in"])
    }

    @Test func atMostThreeADayDroppingTheCheckInFirst() {
        let inputs = NotificationPlan.Inputs(now: at(5, 7), pledgedToday: false, checkedInToday: false,
                                             lessons: [(day(5), "Day 4", 7)], milestones: [(day(5), "One week in")])
        let today = NotificationPlan.plan(.init(), inputs: inputs, calendar: calendar).filter { $0.date < day(6) }
        #expect(today.count == 3)
        #expect(Set(today.map(\.kind)) == [.milestone, .pledge, .lesson])
    }

    @Test func quietHoursMoveThingsToTheMorning() {
        let start = 22 * 60 + 30, end = 7 * 60 + 30
        #expect(NotificationPlan.outOfQuietHours(at(5, 23), start: start, end: end, calendar: calendar) == at(6, 7, 30))
        #expect(NotificationPlan.outOfQuietHours(at(5, 6), start: start, end: end, calendar: calendar) == at(5, 7, 30))
        #expect(NotificationPlan.outOfQuietHours(at(5, 12), start: start, end: end, calendar: calendar) == at(5, 12))
        #expect(NotificationPlan.outOfQuietHours(at(5, 13), start: 12 * 60, end: 14 * 60, calendar: calendar) == at(5, 14))
        var settings = NotificationPlan.Settings()
        settings.checkIn = 23 * 60
        let plan = NotificationPlan.plan(settings, inputs: .init(now: at(5, 7), pledgedToday: true, checkedInToday: false), calendar: calendar)
        #expect(plan.first { $0.kind == .checkIn }?.date == at(6, 7, 30))
    }

    /// S27.18: Glim's weekly check-in is off by default, comes only after graduation, on Sunday, and only the next one.
    @Test func weeklyCheckInAfterGraduationOnSundays() {
        // Thu 5 Nov 2026; the next Sunday is the 8th.
        let graduated = NotificationPlan.Inputs(now: at(5, 7), pledgedToday: true, checkedInToday: true, graduated: true)
        #expect(!NotificationPlan.plan(.init(), inputs: graduated, calendar: calendar).contains { $0.kind == .weekly })

        var settings = NotificationPlan.Settings()
        settings.weekly = 19 * 60
        let weekly = NotificationPlan.plan(settings, inputs: graduated, calendar: calendar).filter { $0.kind == .weekly }
        #expect(weekly.map(\.date) == [at(8, 19)])
        #expect(weekly.first?.title == NotificationCopy.weekly.0)

        let notYet = NotificationPlan.Inputs(now: at(5, 7), pledgedToday: true, checkedInToday: true, graduated: false)
        #expect(!NotificationPlan.plan(settings, inputs: notYet, calendar: calendar).contains { $0.kind == .weekly })

        // On Sunday after its time, the next one is a week later; quiet hours still move it.
        let sundayNight = NotificationPlan.Inputs(now: at(8, 20), pledgedToday: true, checkedInToday: true, graduated: true)
        #expect(NotificationPlan.plan(settings, inputs: sundayNight, calendar: calendar).filter { $0.kind == .weekly }.map(\.date) == [at(15, 19)])
        settings.weekly = 23 * 60
        #expect(NotificationPlan.plan(settings, inputs: graduated, calendar: calendar).first { $0.kind == .weekly }?.date == at(9, 7, 30))
    }

    /// CLIN-06: quiet graduation. Weeks 1 and 2 as usual; Weeks 3 and 4 drop the pledge note and allow two a day;
    /// from Week 5 one a day, with the check-in every other day. Off, everything comes back.
    @Test func quietGraduationStepsBackFromWeekThree() {
        // Thu 5 Nov. Quit Day on the 1st: Week 1, the full set.
        let inputs1 = NotificationPlan.Inputs(now: at(5, 7), pledgedToday: false, checkedInToday: false, quitDay: day(1))
        #expect(NotificationPlan.plan(.init(), inputs: inputs1, calendar: calendar).filter { $0.date < day(6) }.map(\.kind) == [.pledge, .checkIn])
        // 14 days in (Week 3): no pledge note.
        #expect(NotificationPlan.GraduationStage(daysSinceQuit: 14) == .lighter)
        let week3 = calendar.date(byAdding: .day, value: -14, to: day(5))!
        let inputs3 = NotificationPlan.Inputs(now: at(5, 7), pledgedToday: false, checkedInToday: false, quitDay: week3)
        #expect(NotificationPlan.plan(.init(), inputs: inputs3, calendar: calendar).filter { $0.date < day(6) }.map(\.kind) == [.checkIn])
        // 28 days in (Week 5): check-in on even days only, so on day 28 yes and day 29 no.
        let week5 = calendar.date(byAdding: .day, value: -28, to: day(5))!
        let inputs5 = NotificationPlan.Inputs(now: at(5, 7), pledgedToday: false, checkedInToday: false, quitDay: week5)
        let plan5 = NotificationPlan.plan(.init(), inputs: inputs5, calendar: calendar).filter { $0.kind != .away }
        #expect(plan5.map(\.kind) == [.checkIn])
        #expect(plan5.first.map { calendar.isDate($0.date, inSameDayAs: day(5)) } == true)
        // Switched off: the pledge note is back.
        var off = NotificationPlan.Settings()
        off.quietGraduation = false
        #expect(NotificationPlan.plan(off, inputs: inputs5, calendar: calendar).filter { $0.date < day(6) }.map(\.kind) == [.pledge, .checkIn])
        #expect(NotificationPlan.GraduationStage(daysSinceQuit: nil).cap == NotificationPlan.dailyCap)
        #expect(NotificationPlan.GraduationStage(daysSinceQuit: 40).cap == 1)
    }

    @Test func noGuiltWordsAnywhere() {
        var copy = [NotificationCopy.pledge, NotificationCopy.checkIn, NotificationCopy.lesson(name: "Day 4", minutes: 7),
                    NotificationCopy.milestone(title: "One week in"), NotificationCopy.awayFirst(next: "Day 4"),
                    NotificationCopy.awaySecond(replay: "Day 3"), NotificationCopy.awayFirst(next: nil), NotificationCopy.awaySecond(replay: nil),
                    NotificationCopy.weekly]
            .flatMap { [$0.0, $0.1] }
        copy += Milestone.all.map(\.title)
        for text in copy {
            for word in NotificationCopy.bannedWords {
                #expect(!text.lowercased().contains(word), "\"\(text)\" contains \"\(word)\"")
            }
        }
    }
}
