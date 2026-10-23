@testable import DayXero
import DayXeroCore
import Foundation
import Testing

struct MilestoneTests {
    @Test func theScheduleMilanKept() {
        #expect(Milestone.all.map(\.id) == ["quitDay", "1", "3", "7", "14", "30", "60", "90", "100", "180", "365"])
    }

    @Test func quitDayThenTheFirstFullDay() {
        #expect(Milestone.reached(daysClear: 0).isEmpty)
        #expect(Milestone.reached(daysClear: 1) == [.quitDay])
        #expect(Milestone.reached(daysClear: 2) == [.quitDay, .days(1)])
        #expect(Milestone.reached(daysClear: 7).last == .days(7))
        #expect(Milestone.next(daysClear: 7) == .days(14))
    }

    @Test func onlyTheLatestIsCelebratedAfterABreak() {
        #expect(Milestone.toCelebrate(daysClear: 12, celebrated: []) == .days(7))
        #expect(Milestone.toCelebrate(daysClear: 12, celebrated: ["7"]) == nil)
        #expect(Milestone.toCelebrate(daysClear: 14, celebrated: ["quitDay", "1", "3", "7"]) == .days(14))
    }

    @Test func linesThatMakeClaimsNameASource() throws {
        let timeline = try #require(HealthTimeline.bundled)
        for milestone in Milestone.all {
            #expect(!milestone.line.isEmpty)
            if let id = milestone.sourceID { #expect(timeline.source(id) != nil) }
        }
        #expect(Milestone.days(7).sourceID != nil)
    }

    @Test func idsRoundTrip() {
        for milestone in Milestone.all { #expect(Milestone(id: milestone.id) == milestone) }
        #expect(Milestone(id: "5") == nil)
    }
}
