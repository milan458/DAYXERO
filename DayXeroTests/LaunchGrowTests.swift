@testable import DayXero
import Testing

/// The opening animation: grows from the bottom up, finishes by 1.6 s, holds for a second, then hands off.
struct LaunchGrowTests {
    @Test func nothingIsDrawnAtTheStart() {
        let drawn = ForestLeaf.all.filter { $0.scale(at: 0) > 0 }
        #expect(drawn.isEmpty)
        #expect(Ease.progress(0, from: 0.15, to: 0.42) == 0)
    }

    @Test func everyLeafHasSettledByTheTimeTheNameArrives() {
        let unsettled = ForestLeaf.all.filter { abs($0.scale(at: 1.6) - 1) > 0.0001 }
        #expect(unsettled.isEmpty)
        #expect(ForestLeaf.all.count == 43)
    }

    @Test func leavesStartAfterTheTrunkHasBegunToGrow() {
        let earliest = ForestLeaf.all.map(\.start).min() ?? 0
        #expect(earliest > 0.28)
    }

    @Test func theFinishedMarkHoldsForASecondBeforeTheHandOff() {
        let timing = LaunchGrowTiming.full
        #expect(abs((timing.fadeStart - 1.6) - 1.0) < 0.001)
        #expect(timing.fade(at: 2.5) == 0)
        #expect(timing.fade(at: 3.0) == 1)
    }
}
