@testable import DayXero
import DayXeroCore
import Foundation
import Testing

struct CalmToolsTests {
    @Test func threeToFiveShortTools() {
        #expect((3...5).contains(CalmTool.allCases.count))
        #expect(CalmTool.allCases.allSatisfy { $0.minutes <= 3 })
    }

    @Test func boxBreathingGoesRoundTheSquare() {
        #expect(BoxBreath.moment(at: 0).side == .breatheIn)
        #expect(BoxBreath.moment(at: 0).count == 4)
        #expect(BoxBreath.moment(at: 3.5).count == 1)
        #expect(BoxBreath.moment(at: 4).side == .holdIn)
        #expect(BoxBreath.moment(at: 8.5).side == .breatheOut)
        #expect(BoxBreath.moment(at: 12).side == .holdOut)
        #expect(BoxBreath.moment(at: 16).side == .breatheIn)
        #expect(abs(BoxBreath.moment(at: 8).around - 0.5) < 0.0001)
    }

    @Test func groundingCountsDownFiveToOne() {
        #expect(Grounding.steps.map(\.count) == [5, 4, 3, 2, 1])
    }

    @Test func theHelpLinePointsToADirectory() {
        #expect(HelpLine.directory.host() == "findahelpline.com")
    }
}
