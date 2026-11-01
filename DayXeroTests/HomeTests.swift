@testable import DayXero
import DayXeroCore
import Foundation
import SwiftData
import Testing

@MainActor
struct HomeTests {
    var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/London")!
        c.firstWeekday = 2
        return c
    }()

    func date(_ d: Int, _ h: Int = 10, month: Int = 10) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: d, hour: h))!
    }

    func schedule() -> ProgramSchedule {
        // Onboarded Thu 22 Oct, Quit Day Thu 29 Oct: 7 prep days.
        ProgramSchedule(startedOn: date(22), quitDay: date(29, 0), clock: DayClock(calendar: calendar, boundaryHour: 4))
    }

    // MARK: Schedule

    @Test func outlineIsPrepThenQuitWeekThenFourWeeks() {
        let s = schedule()
        #expect(s.prepDays == 7)
        #expect(s.outline.count == 7 + 7 + 4)
        #expect(s.outline.first == ProgramDayID(phase: .prep, index: 1))
        #expect(s.outline.last == ProgramDayID(phase: .maintenance, index: 4))
    }

    @Test func prepDaysOpenAsSoonAsThePreviousIsDone() {
        let s = schedule()
        let done: Set = [ProgramDayID(phase: .prep, index: 1)]
        #expect(s.availability(of: ProgramDayID(phase: .prep, index: 2), completed: done, at: date(22, 11)) == .available)
    }

    @Test func quitDaysWaitForTheirCalendarDay() {
        let s = schedule()
        var done = Set((1...7).map { ProgramDayID(phase: .prep, index: $0) })
        done.insert(ProgramDayID(phase: .quit, index: 1))
        let day2 = ProgramDayID(phase: .quit, index: 2)
        // Day 1 finished on Quit Day evening: Day 2 opens Friday.
        #expect(s.availability(of: day2, completed: done, at: date(29, 20)) == .opensOn(calendar.startOfDay(for: date(30))))
        #expect(s.availability(of: day2, completed: done, at: date(30, 8)) == .available)
    }

    @Test func maintenanceWeeksOpenWeekly() {
        let s = schedule()
        #expect(s.opensOn(ProgramDayID(phase: .maintenance, index: 1)) == calendar.startOfDay(for: date(5, 0, month: 11)))
        #expect(s.opensOn(ProgramDayID(phase: .maintenance, index: 2)) == calendar.startOfDay(for: date(12, 0, month: 11)))
    }

    @Test func milestones() {
        #expect(Milestones.next(after: 0) == 1)
        #expect(Milestones.next(after: 3) == 7)
        #expect(Milestones.next(after: 12) == 14)
        #expect(Milestones.previous(atOrBefore: 12) == 7)
        #expect(Milestones.next(after: 365) == nil)
    }

    // MARK: Snapshot

    func profile(in context: ModelContext, completed: [ProgramDayID] = []) -> UserProfile {
        let p = UserProfile(name: "Milan", quitDay: date(29, 0), currencyCode: "USD", createdAt: date(22, 9))
        context.insert(p)
        p.products.append(ProductUse(product: .vape, isPrimary: true, unitsPerDay: 200, pricePerPurchase: 8, unitsPerPurchase: 600))
        let progress = ProgramProgress()
        p.progress = progress
        for id in completed { progress.completions.append(DayCompletion(day: id, completedAt: date(22))) }
        return p
    }

    @Test func prepSnapshotCountsDownAndStripStartsToday() throws {
        let context = ModelContext(try DataStore.makeContainer(inMemory: true))
        let p = profile(in: context, completed: (1...3).map { ProgramDayID(phase: .prep, index: $0) })
        let snap = HomeSnapshot(profile: p, isPro: true, now: date(25), calendar: calendar)
        #expect(snap.phase == .prep(daysUntilQuitDay: 4))
        #expect(snap.prepDayNumber == 4)
        #expect(snap.prepDone == 3)
        #expect(snap.weekStrip.first?.state == .today)
        #expect(snap.weekStrip[4].state == .quitDay)
        #expect(snap.weekStrip[1].state == .prep)
        #expect(snap.lesson?.day == ProgramDayID(phase: .prep, index: 4))
    }

    /// Program v2 sessions are what Prep 1 to 7 write, so they count toward "x of 7 prep done" and the prep streak.
    @Test func prepCountsProgramSessions() throws {
        let context = ModelContext(try DataStore.makeContainer(inMemory: true))
        let p = profile(in: context)
        for (offset, id) in ["P1", "P2", "P3"].enumerated() {
            let record = SessionRecord(sessionId: id, startedAt: date(22 + offset, 19), contentVersion: "test")
            record.completedAt = date(22 + offset, 20)
            context.insert(record)
        }
        // Started, not finished: doesn't count.
        context.insert(SessionRecord(sessionId: "P4", startedAt: date(25, 9), contentVersion: "test"))
        try context.save()
        let snap = HomeSnapshot(profile: p, isPro: true, now: date(25, 10), calendar: calendar)
        #expect(snap.prepDone == 3)
        #expect(snap.lessonStreak == 3)
        // Home passes its own query's records.
        let none = HomeSnapshot(profile: p, isPro: true, now: date(25, 10), calendar: calendar, sessions: [])
        #expect(none.prepDone == 0)
        #expect(none.lessonStreak == 0)
    }

    @Test func quitWeekSnapshotShowsDayAndCounters() throws {
        let context = ModelContext(try DataStore.makeContainer(inMemory: true))
        let done = (1...7).map { ProgramDayID(phase: .prep, index: $0) } + [ProgramDayID(phase: .quit, index: 1), ProgramDayID(phase: .quit, index: 2)]
        let p = profile(in: context, completed: done)
        let snap = HomeSnapshot(profile: p, isPro: true, now: date(31, 12), calendar: calendar)
        #expect(snap.phase == .quitWeek(day: 3))
        #expect(snap.counters.first?.product == .vape)
        #expect((snap.counters.first?.avoided ?? 0) > 400)
        #expect(snap.nextMilestone == 7)
        #expect(snap.quitWeekDone == 2)
        // Quit Day (Thu 29) is past by Saturday, so it shows as a clear day, not the upcoming-Quit-Day ring.
        #expect(snap.weekStrip.first { calendar.isDate($0.date, inSameDayAs: date(29)) }?.state == .clear)
        #expect(snap.lesson?.availability == .available)
    }

    /// Prep week is free (decision 15): a free user's second prep day opens without an upgrade.
    @Test func prepWeekIsFreeForEveryone() throws {
        let context = ModelContext(try DataStore.makeContainer(inMemory: true))
        let p = profile(in: context, completed: [ProgramDayID(phase: .prep, index: 1)])
        let free = HomeSnapshot(profile: p, isPro: false, now: date(23), calendar: calendar)
        #expect(free.lesson?.needsUpgrade == false)
        let pro = HomeSnapshot(profile: p, isPro: true, now: date(23), calendar: calendar)
        #expect(pro.lesson?.needsUpgrade == false)
    }

    @Test func aLoggedSlipDoesNotChangeHome() throws {
        let context = ModelContext(try DataStore.makeContainer(inMemory: true))
        let p = profile(in: context)
        let before = HomeSnapshot(profile: p, isPro: true, now: date(31, 12), calendar: calendar)
        context.insert(LogEntry(kind: .slip, product: .vape, timestamp: date(30, 18)))
        try context.save()
        let after = HomeSnapshot(profile: p, isPro: true, now: date(31, 12), calendar: calendar)
        #expect(before.daysClear == after.daysClear)
        #expect(before.counters == after.counters)
        #expect(before.moneyKept == after.moneyKept)
    }
}
