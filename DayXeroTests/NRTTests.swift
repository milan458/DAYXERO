@testable import DayXero
import DayXeroCore
import Foundation
import Testing

struct NRTTests {
    var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/London")!
        return c
    }()

    var clock: DayClock { DayClock(calendar: calendar, boundaryHour: 4) }

    func at(_ day: Int, _ hour: Int = 10, month: Int = 10) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour))!
    }

    // MARK: Label presets (S9.2)

    @Test func everyPresetCountryHasAPatchSchedule() {
        for country in LabelCountry.allCases {
            #expect(!NRTLabels.presets(for: .patch, country: country).isEmpty)
        }
        #expect(NRTLabels.presets(for: .patch, country: nil).isEmpty)
        #expect(NRTLabels.presets(for: .inhaler, country: .us).isEmpty)
    }

    @Test func presetsMatchTheLabels() {
        #expect(NRTLabels.preset(id: "us-patch-10")?.totalWeeks == 10)
        #expect(NRTLabels.preset(id: "us-patch-8")?.totalWeeks == 8)
        #expect(NRTLabels.preset(id: "us-gum-12")?.totalWeeks == 12)
        #expect(NRTLabels.preset(id: "uk-patch-16")?.steps.map(\.strengthMg) == [25, 15, 10])
        #expect(NRTLabels.preset(id: "au-patch")?.steps.map(\.weeks) == [6, 2, 2])
    }

    @Test func regionsMapToLabelCountries() {
        #expect(LabelCountry(region: "GB") == .uk)
        #expect(LabelCountry(region: "de") == .de)
        #expect(LabelCountry(region: "IN") == nil)
    }

    // MARK: Step schedule (S9.2, S9.5)

    @Test func stepsRunBackToBackFromTheStartDate() throws {
        let preset = try #require(NRTLabels.preset(id: "us-patch-10"))
        let schedule = StepSchedule(startDate: at(29), steps: preset.steps, clock: clock)
        #expect(schedule.totalDays == 70)
        #expect(schedule.current(at: at(28)) == nil)
        #expect(!schedule.hasStarted(at: at(28)))
        #expect(schedule.current(at: at(29))?.index == 0)
        // 6 weeks after 29 Oct is 10 Dec: step 2 starts.
        #expect(schedule.current(at: at(10, month: 12))?.index == 1)
        #expect(schedule.current(at: at(9, 23, month: 12))?.index == 0)
        let jan7 = calendar.date(from: DateComponents(year: 2027, month: 1, day: 7, hour: 10))!
        #expect(schedule.isFinished(at: jan7))
        #expect(!schedule.isFinished(at: jan7.addingTimeInterval(-86_400)))
        #expect(schedule.stepDownDays.map(\.1.strengthMg) == [14, 7])
    }

    // MARK: Pouch taper (S9.3)

    @Test func suggestedTaperHalvesDownToAboutOnePointFive() {
        #expect(PouchTaperPlan.suggestedSteps(from: 6).map(\.strengthMg) == [6, 3, 1.5])
        #expect(PouchTaperPlan.suggestedSteps(from: 3).map(\.strengthMg) == [3, 1.5])
    }

    @Test func theTaperOnlyRunsIfItFitsBeforeQuitDay() {
        let steps = PouchTaperPlan.suggestedSteps(from: 6)
        #expect(!PouchTaperPlan.fits(steps: steps, quitDay: at(29), now: at(23), clock: clock))
        #expect(PouchTaperPlan.fits(steps: steps, quitDay: at(20, month: 11), now: at(23), clock: clock))
        // Three one-week steps from today.
        #expect(PouchTaperPlan.quitDayToFit(steps: steps, now: at(23), clock: clock) == calendar.startOfDay(for: at(13, month: 11)))
        #expect(PouchTaperPlan.startDate(steps: steps, quitDay: at(20, month: 11), clock: clock) == calendar.startOfDay(for: at(30)))
    }

    // MARK: Reminders (S9.4)

    @Test func patchRemindersSkipTickedDaysAndStepDownsComeTheEveningBefore() {
        let plan = NRTPlan(type: .patch, startDate: at(29), steps: [PlanStep(strengthMg: 21, weeks: 1), PlanStep(strengthMg: 14, weeks: 1)],
                           dailyReminderMinute: 450, createdAt: at(23))
        plan.lastCheckedDay = at(30, 8)
        let reminders = NRTReminderPlan.reminders(for: plan, now: at(29, 6), clock: clock)
        let daily = reminders.filter { $0.id.contains(".daily.") }
        #expect(daily.count == 13)
        #expect(daily.first?.date == calendar.date(bySettingHour: 7, minute: 30, second: 0, of: at(29)))
        #expect(!daily.contains { calendar.isDate($0.date, inSameDayAs: at(30)) })
        let steps = reminders.filter { $0.id.contains(".step.") }
        #expect(steps.map(\.date) == [calendar.date(bySettingHour: 19, minute: 0, second: 0, of: at(4, month: 11))])
    }

    @Test func noRemindersOnceThePlanIsOver() {
        let plan = NRTPlan(type: .patch, startDate: at(1), steps: [PlanStep(strengthMg: 21, weeks: 1)], dailyReminderMinute: 450)
        #expect(NRTReminderPlan.reminders(for: plan, now: at(23), clock: clock).isEmpty)
    }
}
