import DayXeroCore
import Foundation
import Testing

/// The plan reveal's day list (S18.2): every prep day is either listed or counted.
struct PlanTimelineTests {
    var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/London")!
        return c
    }()

    var today: Date { calendar.date(from: DateComponents(year: 2026, month: 10, day: 27))! }

    func kinds(_ prep: Int) -> [PlanTimeline.Kind] {
        PlanTimeline.items(prepDays: prep, today: today, calendar: calendar).map(\.kind)
    }

    @Test func aShortPrepShowsTheWeekWithDaysClearAfterQuitDay() {
        #expect(kinds(3) == [.prep(1), .prep(2), .prep(3), .quitDay, .clear(2), .clear(3), .clear(4)])
        #expect(!PlanTimeline.isLong(prepDays: 3))
    }

    @Test func sixPrepDaysEndOnQuitDay() {
        #expect(kinds(6) == [.prep(1), .prep(2), .prep(3), .prep(4), .prep(5), .prep(6), .quitDay])
    }

    @Test func aWeekOrMoreCountsTheDaysItDoesNotList() {
        #expect(kinds(7) == [.prep(1), .prep(2), .prep(3), .prep(4), .prep(5), .morePrep(2), .quitDay])
        #expect(kinds(9) == [.prep(1), .prep(2), .prep(3), .prep(4), .prep(5), .morePrep(4), .quitDay])
        #expect(kinds(30) == [.prep(1), .prep(2), .prep(3), .prep(4), .prep(5), .morePrep(25), .quitDay])
        #expect(PlanTimeline.isLong(prepDays: 7))
    }

    @Test func quitDayCarriesItsRealDate() throws {
        let items = PlanTimeline.items(prepDays: 9, today: today, calendar: calendar)
        let quit = try #require(items.last)
        #expect(quit.kind == .quitDay)
        #expect(quit.date == calendar.date(byAdding: .day, value: 9, to: today))
        #expect(items[5].date == calendar.date(byAdding: .day, value: 5, to: today))
    }
}
