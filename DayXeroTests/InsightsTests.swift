@testable import DayXero
import DayXeroCore
import Foundation
import SwiftData
import Testing

@MainActor
struct InsightsTests {
    var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/London")!
        c.firstWeekday = 2
        return c
    }()

    /// Friday 23 October 2026, noon.
    var now: Date { at(23, 12) }

    func at(_ day: Int, _ hour: Int, month: Int = 10) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour))!
    }

    func craving(_ day: Int, _ hour: Int, _ trigger: Trigger? = nil, passed: Bool = false) -> Insights.Point {
        Insights.Point(timestamp: at(day, hour), kind: .craving, outcome: passed ? .passed : nil, trigger: trigger)
    }

    // MARK: A week of data (S7.3)

    @Test func needsAWeekAndFiveLogs() {
        let four = (16...19).map { craving($0, 9) }
        #expect(!Insights(points: four, now: now, calendar: calendar).isReady)
        let recentFive = (19...23).map { craving($0, 9) }
        let notOldEnough = Insights(points: recentFive, now: now, calendar: calendar)
        #expect(!notOldEnough.isReady)
        #expect(notOldEnough.daysOfData == 4)
        let ready = Insights(points: (16...20).map { craving($0, 9) }, now: now, calendar: calendar)
        #expect(ready.isReady && ready.readiness == 1)
    }

    @Test func timeOfDayBuckets() {
        #expect(TimeOfDay(hour: 4) == .lateNight)
        #expect(TimeOfDay(hour: 5) == .morning)
        #expect(TimeOfDay(hour: 11) == .midday)
        #expect(TimeOfDay(hour: 16) == .afternoon)
        #expect(TimeOfDay(hour: 21) == .evening)
        #expect(TimeOfDay(hour: 23) == .lateNight)
    }

    @Test func heatMapPutsLogsInTheRightCell() {
        // Mon 19 Oct 8am, Sat 17 Oct 8pm.
        let insights = Insights(points: [craving(19, 8), craving(19, 9), craving(17, 20)], now: now, calendar: calendar)
        let grid = insights.heatMap(.cravings)
        #expect(grid[0][0] == 2)
        #expect(grid[3][5] == 1)
        #expect(insights.heatMap(.uses).flatMap { $0 }.allSatisfy { $0 == 0 })
    }

    @Test func peaksWeighWeekendsPerDay() {
        // Five weekday mornings (1 a day) against two weekend evenings (1.5 a day).
        let points = [19, 20, 21, 22, 23].map { craving($0, 8) } + [craving(17, 20), craving(17, 21), craving(18, 20)]
        let peaks = Insights(points: points, now: now, calendar: calendar).peaks(.cravings)
        #expect(peaks == [Insights.Peak(weekend: true, time: .evening), Insights.Peak(weekend: false, time: .morning)])
    }

    @Test func topTriggersIgnoreUsesAndOldLogs() {
        let points = [craving(20, 8, .coffee), craving(21, 8, .coffee), craving(21, 15, .stress),
                      Insights.Point(timestamp: at(22, 9), kind: .use, trigger: .stress),
                      Insights.Point(timestamp: at(22, 9), kind: .slip, trigger: .stress),
                      craving(1, 9, .stress, month: 9)]
        let insights = Insights(points: points, now: now, calendar: calendar)
        #expect(insights.topTriggers.map(\.trigger) == [.coffee, .stress])
        #expect(insights.topTriggers.map(\.count) == [2, 2])
        #expect(insights.taggedCount == 4)
    }

    @Test func weeksCompareWithLastWeek() {
        let lastWeek = (12...16).map { craving($0, 9) }
        let thisWeek = [craving(19, 9, passed: true), craving(20, 9, passed: true), craving(21, 9)]
        let insights = Insights(points: lastWeek + thisWeek, now: now, calendar: calendar)
        let weeks = insights.weeks()
        #expect(weeks.map(\.cravings) == [0, 5, 3])
        #expect(weeks.last?.riddenOut == 2 && weeks.last?.isCurrent == true)
        #expect(insights.weekOnWeekChange == -0.4)
    }

    // MARK: One-tap logging (S7.1)

    @Test func aUseBeforeQuitDayIsTrackingAndAfterIsASlip() throws {
        let context = ModelContext(try DataStore.makeContainer(inMemory: true))
        let profile = UserProfile(name: "Milan", quitDay: at(26, 0), currencyCode: "USD", createdAt: at(19, 9))
        context.insert(profile)
        #expect(UseLog.log(.vape, at: at(23, 9), in: context).kind == .use)
        #expect(UseLog.log(.vape, at: at(27, 9), in: context).kind == .slip)
        #expect(!UseLog.isSlip(profile: profile, at: at(25, 12)))
    }

    @Test func useCountsAreForTodayAndYesterday() throws {
        let context = ModelContext(try DataStore.makeContainer(inMemory: true))
        let clock = DayClock(calendar: calendar, boundaryHour: 4)
        for hour in [9, 13, 18] { UseLog.log(.cigarettes, at: at(23, hour), in: context) }
        UseLog.log(.cigarettes, at: at(22, 20), in: context)
        UseLog.log(.cigarettes, at: at(20, 20), in: context)
        UseLog.log(.vape, at: at(23, 10), in: context)
        let counts = UseLog.counts(.cigarettes, at: at(23, 20), in: context, clock: clock)
        #expect(counts.today == 3 && counts.yesterday == 1)
    }
}

private extension InsightsTests {
    func craving(_ day: Int, _ hour: Int, _ trigger: Trigger?, month: Int) -> Insights.Point {
        Insights.Point(timestamp: at(day, hour, month: month), kind: .craving, trigger: trigger)
    }
}
