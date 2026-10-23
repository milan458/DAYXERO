@testable import DayXero
import DayXeroCore
import Foundation
import SwiftData
import Testing

@MainActor
struct ProgramTests {
    var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/London")!
        return c
    }()

    func date(_ d: Int, _ h: Int = 10, month: Int = 10) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: d, hour: h))!
    }

    var clock: DayClock { DayClock(calendar: calendar, boundaryHour: 4) }

    // MARK: Pause and replay (S5.7)

    @Test func threeIdleDaysPauseTheProgram() {
        let last = ProgramDayID(phase: .quit, index: 3)
        #expect(Inactivity.replayDue(lastActive: date(31), lastCompleted: last, programFinished: false, now: date(2, month: 11), clock: clock) == nil)
        #expect(Inactivity.replayDue(lastActive: date(31), lastCompleted: last, programFinished: false, now: date(3, month: 11), clock: clock) == last)
    }

    @Test func noPauseWithoutAFinishedDayOrAfterTheProgram() {
        #expect(Inactivity.replayDue(lastActive: date(1), lastCompleted: nil, programFinished: false, now: date(20), clock: clock) == nil)
        #expect(Inactivity.replayDue(lastActive: date(1), lastCompleted: ProgramDayID(phase: .maintenance, index: 4),
                                     programFinished: true, now: date(20), clock: clock) == nil)
    }

    @Test func aPendingReplayHoldsBackTheNextDayButKeepsProgress() throws {
        let context = ModelContext(try DataStore.makeContainer(inMemory: true))
        let profile = UserProfile(name: "Milan", quitDay: date(29, 0), currencyCode: "USD", createdAt: date(22, 9))
        context.insert(profile)
        profile.products.append(ProductUse(product: .vape, isPrimary: true, unitsPerDay: 200, pricePerPurchase: 8, unitsPerPurchase: 600))
        let progress = ProgramProgress()
        profile.progress = progress
        let prep = (1...7).map { ProgramDayID(phase: .prep, index: $0) }
        for id in prep { progress.completions.append(DayCompletion(day: id, completedAt: date(22 + id.index - 1))) }
        progress.replayDay = prep.last

        let state = ProgramState(profile: profile, isPro: true, now: date(3, month: 11), calendar: calendar)
        #expect(state.availability(ProgramDayID(phase: .quit, index: 1)) == .locked)
        #expect(state.availability(prep[0]) == .completed)
        let home = HomeSnapshot(profile: profile, isPro: true, now: date(3, month: 11), calendar: calendar)
        #expect(home.lesson?.isReplay == true)
        #expect(home.prepDone == 7)
    }

    // MARK: Content as data (S5.1)

    @Test func dayIDsRoundTripThroughText() {
        #expect(ProgramDayID(description: "quit-3") == ProgramDayID(phase: .quit, index: 3))
        #expect(ProgramDayID(description: "maintenance-2")?.phase == .maintenance)
        #expect(ProgramDayID(description: "nope") == nil)
    }

    @Test func lessonJSONDecodes() throws {
        let json = """
        { "lessons": [ { "day": "quit-3", "title": "Riding out the urge", "minutes": 7,
          "steps": [ { "type": "reading", "lead": "L", "body": "B", "notes": { "cigarettes": "N" } },
                     { "type": "audio", "title": "T", "file": "a.m4a", "seconds": 180, "transcript": "X" },
                     { "type": "ifThen", "title": "T", "actions": ["walk"] } ] } ] }
        """
        let file = try JSONDecoder().decode(LessonFile.self, from: Data(json.utf8))
        let lesson = try #require(file.lessons.first)
        #expect(lesson.day == ProgramDayID(phase: .quit, index: 3))
        #expect(!lesson.placeholder)
        #expect(lesson.steps.count == 3)
        #expect(lesson.steps[0] == .reading(lead: "L", body: "B", notes: ["cigarettes": "N"]))
        let again = try JSONDecoder().decode(LessonContent.self, from: JSONEncoder().encode(lesson))
        #expect(again == lesson)
    }

    @Test func placeholdersAreTaggedAndWeeksAfterUseTheCheckInFormat() {
        let day = LessonLibrary.placeholder(for: ProgramDayID(phase: .quit, index: 3), product: .vape)
        #expect(day.placeholder)
        #expect(day.steps.contains { if case .audio = $0 { true } else { false } })
        let week = LessonLibrary.placeholder(for: ProgramDayID(phase: .maintenance, index: 1), product: .vape)
        #expect(week.steps.first == .weekRating)
    }
}
