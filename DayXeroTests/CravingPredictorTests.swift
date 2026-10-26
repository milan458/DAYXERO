@testable import DayXero
import DayXeroCore
import Foundation
import Testing

struct CravingPredictorTests {
    let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    private func at(_ dayOffset: Int, _ hour: Int, _ minute: Int = 0, from base: Date) -> Date {
        let day = calendar.date(byAdding: .day, value: dayOffset, to: calendar.startOfDay(for: base))!
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)!
    }

    /// A Monday morning, so the 3pm habit is still ahead today.
    var now: Date { calendar.date(from: DateComponents(year: 2026, month: 11, day: 2, hour: 9))! }

    @Test func findsAFixedThreePmHabitWithinAWeek() throws {
        let events = (1...6).map { CravingPredictor.Event(date: at(-$0, 15, 10, from: now), trigger: .meals) }
        let next = try #require(CravingPredictor.nextWindow(events: events, now: now, calendar: calendar))
        let startHour = calendar.component(.hour, from: next.start)
        #expect((14...15).contains(startHour))
        #expect(next.end > next.start)
        #expect(calendar.isDate(next.start, inSameDayAs: now))
        #expect(next.trigger == .meals)
    }

    @Test func sparseUsersGetNoWindow() {
        let events = [CravingPredictor.Event(date: at(-1, 15, from: now)), CravingPredictor.Event(date: at(-3, 20, from: now))]
        #expect(CravingPredictor.nextWindow(events: events, now: now, calendar: calendar) == nil)
    }

    @Test func fadesAfterThreeQuietWeeks() {
        let events = (22...30).map { CravingPredictor.Event(date: at(-$0, 15, from: now)) }
        #expect(CravingPredictor.nextWindow(events: events, now: now, calendar: calendar) == nil)
    }

    @Test func atMostThreeWindowsADay() {
        var events: [CravingPredictor.Event] = []
        for hour in [8, 11, 14, 17, 20] {
            for back in 1...5 { events.append(.init(date: at(-back, hour, from: now))) }
        }
        let windows = CravingPredictor.windows(on: now, events: events, now: now, calendar: calendar)
        #expect(windows.count <= 3)
        #expect(windows == windows.sorted { $0.start < $1.start })
    }

    @Test func snapshotRoundTripsAndKeepsNoFreeText() throws {
        let sample = WidgetSnapshot.sample(now: now, calendar: calendar)
        let data = try JSONEncoder().encode(sample)
        let back = try JSONDecoder().decode(WidgetSnapshot.self, from: data)
        #expect(back == sample)
        #expect(sample.glassesToday == 6 && sample.glassesGoal == 11)
        #expect(sample.moneyText == "$84")
        // Only fixed fields; nothing like a note or reason.
        let keys = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any]).keys
        #expect(!keys.contains { $0.lowercased().contains("note") || $0.lowercased().contains("reason") })
    }
}
