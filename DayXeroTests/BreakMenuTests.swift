import DayXeroCore
import Foundation
import Testing

/// S27.18: Craving SOS shows the person's own break menu, most helpful first, and quick questions show their numbers back.
struct BreakMenuTests {
    @Test func theMenuIsTheSavedBreaksThenTheWayToMove() {
        #expect(BreakMenu.items(menu: ["Step outside", "Text someone", " "], move: "Walk") == ["Step outside", "Text someone", "Walk"])
        // A way to move that's already on the menu isn't repeated.
        #expect(BreakMenu.items(menu: ["Walk around the block", "Walk"], move: "walk") == ["Walk around the block", "Walk"])
        #expect(BreakMenu.items(menu: [], move: nil).isEmpty)
    }

    @Test func whatHelpedMostComesFirstElseTheirOwnOrder() {
        let items = ["Step outside", "Make tea or coffee properly", "Text someone"]
        #expect(BreakMenu.ordered(items, helped: []) == items)
        #expect(BreakMenu.ordered(items, helped: ["Text someone", "Just breathing", "text someone", "Step outside"])
            == ["Text someone", "Step outside", "Make tea or coffee properly"])
    }

    @Test func onlyFastActingNRTGetsTheUseItNowRow() {
        #expect(!BreakMenu.hasFastActingNRT([]))
        #expect(!BreakMenu.hasFastActingNRT([.patch]))
        #expect(BreakMenu.hasFastActingNRT([.patch, .gum]))
        #expect(BreakMenu.hasFastActingNRT([.lozenge]))
        #expect(BreakMenu.hasFastActingNRT([.inhaler]))
    }

    @Test func theMenuIsBuiltInTheProgramWhereSOSLooksForIt() throws {
        let content = try #require(ProgramContent.bundled)
        let session = try #require(content.session(BreakMenu.buildingSessionId))
        #expect(session.beats.contains { $0.saveAs == BreakMenu.menuKey })
        #expect(content.sessions.contains { $0.beats.contains { $0.saveAs == BreakMenu.moveKey } })
        // SOS's suggestions before a menu exists are three of that session's own options.
        let options = try #require(session.beats.first { $0.saveAs == BreakMenu.menuKey }?.options?.resolve(.smoking)).map(\.id)
        #expect(Set(["outside", "water", "breathe"]).isSubset(of: Set(options)))
    }

    @Test func peaksReadBackFromTheSavedAnswers() throws {
        let lines = ["2026-11-03 8", "2026-11-04 6", "2026-11-05 4"]
        #expect(MissionTrend.values(from: lines) == [8, 6, 4])
        let summary = try #require(MissionTrend.summary(of: lines))
        #expect(summary.values == [8, 6, 4])
        #expect(summary.falling)
        #expect(!summary.rising)
        // Only says "lower each time" when it is.
        #expect(MissionTrend.summary(of: ["2026-11-03 6", "2026-11-04 7", "2026-11-05 4"])?.falling == false)
        #expect(MissionTrend.summary(of: ["2026-11-03 6"])?.falling == false)
        #expect(MissionTrend.summary(of: []) == nil)
    }

    @Test func morningGapsReadBackWithTheLongestYet() throws {
        let lines = ["2026-11-02 0 min", "2026-11-03 5 min", "2026-11-04 15+ min"]
        let summary = try #require(MissionTrend.summary(of: lines))
        #expect(summary.values == [0, 5, 15])
        #expect(summary.rising)
        #expect(summary.best == 15)
        #expect(summary.latestIsBest)
        #expect(MissionTrend.summary(of: ["2026-11-02 10 min", "2026-11-03 5 min"])?.latestIsBest == false)
        // Lines that aren't answers are skipped, and only the latest five are shown.
        #expect(MissionTrend.values(from: ["garbled", "2026-11-02 x"]).isEmpty)
        let many = (1...8).map { "2026-11-0\($0) \($0)" }
        #expect(MissionTrend.summary(of: many)?.values == [4, 5, 6, 7, 8])
    }
}
