import DayXeroCore
import Foundation
import Testing

struct ProgramUnlockTests {
    let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    var unlock: ProgramUnlock {
        ProgramUnlock(steps: [
            .init(id: "P1", rule: .first),
            .init(id: "P2", rule: .nextDayAfterPrevious),
            .init(id: "P3", rule: .nextDayAfterPrevious),
            .init(id: "DX", rule: .dayXero),
            .init(id: "D1", rule: .daysSinceQuit, minDay: 1),
            .init(id: "D2", rule: .daysSinceQuit, minDay: 2),
            .init(id: "D10", rule: .daysSinceQuit, minDay: 10),
        ], clock: DayClock(calendar: calendar, boundaryHour: 4))
    }

    /// Day `day` of November 2026 at `hour` UTC.
    func at(_ day: Int, _ hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour))!
    }

    func states(_ records: [String: ProgramUnlock.Record], quitDay: Int = 10, quitTimestamp: Date? = nil, now: Date)
        -> [String: ProgramUnlock.State] {
        Dictionary(uniqueKeysWithValues: unlock.states(records: records, quitDay: at(quitDay, 0), quitTimestamp: quitTimestamp, now: now)
            .map { ($0.id, $0.state) })
    }

    @Test func theFirstSessionIsOpenAndTheRestWaitOrLock() {
        let s = states([:], now: at(1))
        #expect(s["P1"] == .available)
        #expect(s["P2"] == .locked && s["DX"] == .locked && s["D10"] == .locked)
    }

    @Test func prepOpensOneSessionPerDay() {
        let done: [String: ProgramUnlock.Record] = ["P1": .init(startedAt: at(1, 9), completedAt: at(1, 9))]
        #expect(states(done, now: at(1, 22))["P2"] == .scheduled(.tomorrow))
        // Before the 4am boundary it is still the same day.
        #expect(states(done, now: at(2, 3))["P2"] == .scheduled(.tomorrow))
        #expect(states(done, now: at(2, 5))["P2"] == .available)
        #expect(states(done, now: at(2, 5))["P3"] == .locked)
    }

    @Test func aStartedSessionIsInProgress() {
        let s = states(["P1": .init(startedAt: at(1, 9))], now: at(1, 10))
        #expect(s["P1"] == .inProgress)
        #expect(s["P2"] == .locked)
    }

    @Test func dayXeroWaitsForTheQuitDayWhenPrepFinishesEarly() {
        let prep: [String: ProgramUnlock.Record] = [
            "P1": .init(completedAt: at(1)), "P2": .init(completedAt: at(2)), "P3": .init(completedAt: at(3)),
        ]
        #expect(states(prep, quitDay: 10, now: at(5))["DX"] == .scheduled(.dayXero(at(10, 0))))
        #expect(states(prep, quitDay: 10, now: at(10, 6))["DX"] == .available)
    }

    /// S27.7: Day Xero comes on the chosen Quit Day even when prep runs short; prep stays open as catch-up.
    @Test func dayXeroOpensOnTheQuitDayEvenWhenPrepIsUnfinished() {
        let unfinished: [String: ProgramUnlock.Record] = ["P1": .init(completedAt: at(1)), "P2": .init(completedAt: at(2))]
        // Before the Quit Day the next prep session is the one waiting, and Day Xero stays locked behind it.
        let before = states(unfinished, quitDay: 10, now: at(9))
        #expect(before["P3"] == .available)
        #expect(before["DX"] == .locked)
        // On the Quit Day, Day Xero is open and the unfinished prep session is still open as catch-up.
        let quitDay = states(unfinished, quitDay: 10, now: at(10, 6))
        #expect(quitDay["DX"] == .available)
        #expect(quitDay["P3"] == .available)
        // Home leads with Day Xero, not the catch-up.
        let home = unlock.current(records: unfinished, quitDay: at(10, 0), quitTimestamp: nil, now: at(10, 6))
        #expect(home?.id == "DX")
    }

    @Test func prepCatchUpHasNoOneADayWaitAfterTheQuitDay() {
        let quit = at(10, 8)
        var records: [String: ProgramUnlock.Record] = ["P1": .init(completedAt: at(1)), "DX": .init(completedAt: quit)]
        // P2 opens straight away after the Quit Day, and P3 the same day once P2 is done.
        #expect(states(records, quitTimestamp: quit, now: at(10, 9))["P2"] == .available)
        records["P2"] = .init(completedAt: at(10, 9))
        #expect(states(records, quitTimestamp: quit, now: at(10, 10))["P3"] == .available)
        // The weeks follow Day Xero, not prep: Day 2 opens the next day whatever prep is left.
        #expect(states(records, quitTimestamp: quit, now: at(11, 9))["D1"] == .available)
    }

    @Test func homeShowsPrepCatchUpWhileTheWeekChainWaits() {
        let quit = at(10, 8)
        let records: [String: ProgramUnlock.Record] = ["P1": .init(completedAt: at(1)), "DX": .init(completedAt: quit)]
        // Evening of the Quit Day: Day 2 waits for tomorrow, so the open catch-up comes first.
        let home = unlock.current(records: records, quitDay: at(10, 0), quitTimestamp: quit, now: at(10, 20))
        #expect(home?.id == "P2" && home?.state == .available)
        // Next morning the week chain is open again and leads.
        let next = unlock.current(records: records, quitDay: at(10, 0), quitTimestamp: quit, now: at(11, 9))
        #expect(next?.id == "D1")
    }

    @Test func theDayXeroDateIsTheQuitDay() {
        // The same date the old "prep finished early" case waited for: the Quit Day's calendar date.
        #expect(unlock.dayXeroDate(quitDay: at(10, 15)) == unlock.clock.startOfDate(at(10, 0)))
    }

    @Test func weekSessionsOpenByDaysSinceDayXero() {
        let quit = at(10, 8)
        var records: [String: ProgramUnlock.Record] = [
            "P1": .init(completedAt: at(1)), "P2": .init(completedAt: at(2)), "P3": .init(completedAt: at(3)),
            "DX": .init(completedAt: quit),
        ]
        #expect(states(records, quitTimestamp: quit, now: at(10, 20))["D1"] == .scheduled(.quitDay(1)))
        #expect(states(records, quitTimestamp: quit, now: at(11, 9))["D1"] == .available)
        records["D1"] = .init(completedAt: at(11, 9))
        #expect(states(records, quitTimestamp: quit, now: at(11, 10))["D2"] == .scheduled(.quitDay(2)))
    }

    @Test func comingBackAfterAGapCatchesUpWithoutWaiting() {
        let quit = at(10, 8)
        var records: [String: ProgramUnlock.Record] = [
            "P1": .init(completedAt: at(1)), "P2": .init(completedAt: at(2)), "P3": .init(completedAt: at(3)),
            "DX": .init(completedAt: quit),
        ]
        // Back on day 25: Day 1 is open; finishing it opens Day 2 straight away, the same day.
        let back = at(25, 9)
        #expect(states(records, quitTimestamp: quit, now: back)["D1"] == .available)
        records["D1"] = .init(completedAt: back)
        #expect(states(records, quitTimestamp: quit, now: at(25, 10))["D2"] == .available)
        records["D2"] = .init(completedAt: at(25, 10))
        #expect(states(records, quitTimestamp: quit, now: at(25, 11))["D10"] == .available)
    }

    @Test func theCurrentSessionIsTheFirstNotFinished() {
        let records: [String: ProgramUnlock.Record] = ["P1": .init(completedAt: at(1))]
        let current = unlock.current(records: records, quitDay: at(10, 0), quitTimestamp: nil, now: at(1, 20))
        #expect(current?.id == "P2" && current?.state == .scheduled(.tomorrow))
    }

    @Test func theBundledProgramUnlocksInItsOwnOrder() throws {
        let content = try #require(ProgramContent.bundled)
        let unlock = ProgramUnlock(content: content, clock: DayClock(calendar: calendar, boundaryHour: 4))
        #expect(unlock.steps.first?.rule == .first)
        #expect(unlock.steps.first { $0.id == "DX" }?.rule == .dayXero)
        #expect(unlock.steps.first { $0.id == "W2S2" }?.minDay == 10)
        #expect(unlock.steps.last?.minDay == 30)
    }

    /// A week session's label is the Today counter's day it opens on: Day Xero is Day 1, so `minDay` 3 is "Day 4",
    /// and "Next session on Day …" uses the same number.
    @Test func weekSessionLabelsMatchTheDayCounter() throws {
        let content = try #require(ProgramContent.bundled)
        let clock = DayClock(calendar: calendar, boundaryHour: 4)
        let unlock = ProgramUnlock(content: content, clock: clock)
        let quit = at(6, 8)
        let stats = ProgressStats(quitDay: at(6, 0), baselines: [], clock: clock)
        #expect(ProgramUnlock.counterDay(daysSinceQuit: 0) == stats.daysClear(at: quit))
        for session in content.sessions where session.unlock.rule == .daysSinceQuit {
            let minDay = try #require(session.unlock.minDay)
            let opens = try #require(calendar.date(byAdding: .day, value: minDay, to: quit))
            #expect(unlock.daysSinceQuit(quit, now: opens) == minDay)
            #expect(stats.daysClear(at: opens) == ProgramUnlock.counterDay(daysSinceQuit: minDay))
            #expect(session.label == "Day \(ProgramUnlock.counterDay(daysSinceQuit: minDay))")
        }
    }
}
