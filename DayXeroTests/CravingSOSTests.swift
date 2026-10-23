@testable import DayXero
import DayXeroCore
import Foundation
import SwiftData
import Testing

@MainActor
struct CravingSOSTests {
    // MARK: Breathing and timing (S6.1, S6.2)

    @Test func breathingStartsAtSixAMinuteAndSlowsToFive() {
        #expect(CravingWave.breathLength(at: 0) == 10)
        #expect(CravingWave.breathLength(at: 90) == 11)
        #expect(CravingWave.breathLength(at: 180) == 12)
        #expect(CravingWave.breathLength(at: 600) == 12)
    }

    @Test func firstBreathIsFourInSixOut() {
        let start = CravingWave.breath(at: 0)
        #expect(start.phase == .breatheIn && start.index == 0 && start.scale == 0)
        let top = CravingWave.breath(at: 3.99)
        #expect(top.phase == .breatheIn && top.scale > 0.99)
        let out = CravingWave.breath(at: 4.01)
        #expect(out.phase == .breatheOut && out.index == 0)
        #expect(CravingWave.breath(at: 10.05).index == 1)
        #expect(CravingWave.breath(at: 10.05).phase == .breatheIn)
    }

    @Test func breathsGetLongerThroughTheSession() {
        let early = CravingWave.breath(at: 5)
        let late = CravingWave.breath(at: 175)
        #expect(late.inhaleSeconds + late.exhaleSeconds > early.inhaleSeconds + early.exhaleSeconds)
    }

    @Test func countdownAndWording() {
        #expect(CravingWave.remaining(roundElapsed: 19) == 161)
        #expect(CravingWave.remaining(roundElapsed: 400) == 0)
        #expect(!CravingWave.isPastPeak(roundElapsed: 89))
        #expect(CravingWave.isPastPeak(roundElapsed: 90))
    }

    @Test func reasonsTakeTurns() {
        #expect(CravingWave.reasonIndex(elapsed: 10, count: 0) == nil)
        #expect(CravingWave.reasonIndex(elapsed: 39, count: 3) == 0)
        #expect(CravingWave.reasonIndex(elapsed: 41, count: 3) == 1)
        #expect(CravingWave.reasonIndex(elapsed: 125, count: 3) == 0)
    }

    // MARK: Logging (S6.6)

    @Test func eachSessionIsOneEntryWithItsOutcomeAndExtras() throws {
        let context = ModelContext(try DataStore.makeContainer(inMemory: true))
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        CravingLog.record(.passed, startedAt: start, endedAt: start.addingTimeInterval(185), in: context)
        CravingLog.record(.passed, startedAt: start, endedAt: start.addingTimeInterval(190), in: context)
        CravingLog.annotate(startedAt: start, trigger: .coffee, intensity: 7, in: context)
        let entries = try context.fetch(FetchDescriptor<LogEntry>())
        #expect(entries.count == 1)
        let entry = try #require(entries.first)
        #expect(entry.kind == .craving && entry.outcome == .passed)
        #expect(entry.sosDurationSeconds == 190)
        #expect(entry.trigger == .coffee && entry.intensity == 7)
    }

    @Test func aSlipFromSOSIsLoggedAsASlip() throws {
        let context = ModelContext(try DataStore.makeContainer(inMemory: true))
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        CravingLog.record(.slipped, startedAt: start, endedAt: start.addingTimeInterval(60), in: context)
        let entry = try #require(try context.fetch(FetchDescriptor<LogEntry>()).first)
        #expect(entry.kind == .slip && entry.outcome == .slipped)
    }

    @Test func weeklyCountOnlyCountsCravingsRiddenOutThisWeek() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        calendar.firstWeekday = 2
        let now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 23, hour: 12))!  // Friday
        func entry(daysAgo: Int, _ outcome: CravingOutcome, kind: LogKind = .craving) -> LogEntry {
            let e = LogEntry(kind: kind, timestamp: now.addingTimeInterval(Double(-daysAgo) * 86_400))
            e.outcome = outcome
            return e
        }
        let entries = [entry(daysAgo: 0, .passed), entry(daysAgo: 3, .passed), entry(daysAgo: 1, .closed),
                       entry(daysAgo: 2, .slipped, kind: .slip), entry(daysAgo: 6, .passed)]
        #expect(CravingStats.passedThisWeek(entries, now: now, calendar: calendar) == 2)
    }
}
