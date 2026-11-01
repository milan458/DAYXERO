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

    /// Each milestone's illustration is a real change on the timeline, so it has its own drawing (S21.6).
    @Test func illustratedMilestonesPointAtTimelineItems() throws {
        let timeline = try #require(HealthTimeline.bundled)
        let ids = Set(timeline.items(for: .vape).map(\.id) + timeline.items(for: .cigarettes).map(\.id))
        for milestone in Milestone.all {
            if let id = milestone.healthItemID { #expect(ids.contains(id), "\(id)") }
        }
        #expect(Milestone.days(3).healthItemID == "nicotine-gone")
    }

    @Test func idsRoundTrip() {
        for milestone in Milestone.all { #expect(Milestone(id: milestone.id) == milestone) }
        #expect(Milestone(id: "5") == nil)
    }

    /// S27.16: no two milestones look alike: each has its own token, and no two share sky, token and company.
    @Test func everyMilestoneLooksDifferent() {
        let tokens = Milestone.all.map(\.token)
        #expect(Set(tokens).count == Milestone.all.count, "One token per milestone")
        let looks = Milestone.all.map { "\($0.scene.rawValue)/\($0.token.rawValue)/\($0.company.rawValue)" }
        #expect(Set(looks).count == Milestone.all.count)
    }

    /// Xero celebrates alone in the first weeks, Jelli joins at one month, the whole crew from three months.
    @Test func theCrewJoinsAsTheMonthsGoBy() {
        #expect(Milestone.quitDay.company == .xero)
        #expect(Milestone.days(14).company == .xero)
        #expect(Milestone.days(30).company == .xeroAndJelli)
        #expect(Milestone.days(60).company == .xeroAndJelli)
        #expect(Milestone.days(90).company == .crew)
        #expect(Milestone.days(365).company == .crew)
    }
}
