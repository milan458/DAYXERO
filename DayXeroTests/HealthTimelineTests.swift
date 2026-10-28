@testable import DayXero
import DayXeroCore
import Foundation
import Testing

struct HealthTimelineTests {
    @Test func theBundledTimelineLoadsAndEveryItemHasASource() throws {
        let timeline = try #require(HealthTimeline.bundled)
        for product in Product.allCases {
            let items = timeline.items(for: product)
            #expect(!items.isEmpty)
            for item in items {
                let source = try #require(timeline.source(item.source), "\(item.id) has no source")
                #expect(source.url.scheme == "https")
                #expect(item.toHours >= item.fromHours)
            }
        }
    }

    @Test func vapingAndPouchesSayWhereEvidenceIsThin() throws {
        let timeline = try #require(HealthTimeline.bundled)
        #expect(timeline.note(for: .vape) != nil)
        #expect(timeline.note(for: .pouches) != nil)
        #expect(timeline.note(for: .cigarettes) == nil)
        // No lung claims outside the smoking timeline.
        #expect(!timeline.items(for: .vape).contains { $0.title.lowercased().contains("lung") })
        #expect(timeline.items(for: .vape).first { $0.id == "withdrawal-start" }?.source == "smokefree-vaping")
    }

    @Test func itemsAreDoneUnderWayOrAhead() {
        let item = HealthTimeline.Item(id: "x", fromHours: 336, toHours: 2184, when: "", title: "", line: "", detail: "", source: "acs")
        #expect(HealthTimeline.state(of: item, elapsedHours: -5) == .ahead)
        #expect(HealthTimeline.state(of: item, elapsedHours: 100) == .ahead)
        #expect(HealthTimeline.state(of: item, elapsedHours: 2184) == .done)
        guard case let .underWay(fraction) = HealthTimeline.state(of: item, elapsedHours: 1260) else {
            Issue.record("expected under way")
            return
        }
        #expect(abs(fraction - 0.5) < 0.001)
    }

    @Test func timeCountsFromTheStartOfQuitDay() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        let clock = DayClock(calendar: calendar, boundaryHour: 4)
        let quit = calendar.date(from: DateComponents(year: 2026, month: 10, day: 12, hour: 15))!
        let now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 13, hour: 6))!
        #expect(HealthTimeline.elapsedHours(quitDay: quit, now: now, clock: clock) == 30)
    }

    @Test func timelineDataDecodesFromJSON() throws {
        let json = """
        { "version": 1, "sources": { "s": { "label": "L", "title": "T", "url": "https://example.org" } },
          "groups": { "g": [ { "id": "a", "fromHours": 0, "toHours": 1, "when": "W", "title": "T", "line": "", "detail": "D", "source": "s" } ] },
          "products": { "cigarettes": { "groups": ["g"] } } }
        """
        let timeline = try HealthTimeline(data: Data(json.utf8))
        #expect(timeline.items(for: .cigarettes).map(\.id) == ["a"])
        #expect(timeline.items(for: .vape).isEmpty)
    }

    @Test func homeFeaturesTheChangeUnderWayAndTheNextOne() {
        func item(_ id: String, _ from: Double, _ to: Double) -> HealthTimeline.Item {
            HealthTimeline.Item(id: id, fromHours: from, toHours: to, when: "", title: id, line: "", detail: "", source: "acs")
        }
        let items = [item("a", 0, 2), item("b", 1, 72), item("c", 24, 168), item("d", 336, 2184)]
        // Before Quit Day: nothing under way, the first change is next.
        let before = HealthTimeline.nowAndNext(items, elapsedHours: -10)
        #expect(before.now == nil && before.next?.id == "a")
        // 30 hours in: b and c overlap, the later one is featured; d is next.
        let day2 = HealthTimeline.nowAndNext(items, elapsedHours: 30)
        #expect(day2.now?.id == "c" && day2.next?.id == "d")
        // Past everything.
        let late = HealthTimeline.nowAndNext(items, elapsedHours: 5000)
        #expect(late.now == nil && late.next == nil)
    }
}
