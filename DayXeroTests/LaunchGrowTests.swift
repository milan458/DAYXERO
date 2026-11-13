@testable import DayXero
import Testing

/// The opening animation (v5): a 2.4 s paper-cut sunrise that holds, then hands off.
struct LaunchGrowTests {
    @Test func everythingStartsBelowOrHidden() {
        for i in 0..<5 { #expect(LaunchTimeline.hill(i, at: 0) > 0) }
        #expect(LaunchTimeline.sun(at: 0) == 240)
        #expect(LaunchTimeline.letter(0, at: 0) == 0)
        #expect(LaunchTimeline.xero(at: 0) == 0)
        #expect(LaunchTimeline.underline(at: 0) == 0)
    }

    @Test func everythingHasLandedByTwoPointFourSeconds() {
        let t = LaunchTimeline.duration
        for i in 0..<5 { #expect(LaunchTimeline.hill(i, at: t) == 0) }
        #expect(LaunchTimeline.sun(at: t) == 0)
        for n in 0..<7 { #expect(LaunchTimeline.letter(n, at: t) == 1) }
        #expect(LaunchTimeline.underline(at: t) == 1)
        #expect(LaunchTimeline.xero(at: t) == 1)
        #expect(LaunchTimeline.xeroLands < t)
    }

    @Test func layersRiseBackToFront() {
        // At 0.5 s the back hill is furthest along and the base layer least.
        let left = (0..<5).map { LaunchTimeline.hill($0, at: 0.5) }
        #expect(left == left.sorted())
    }

    @Test func theFinishedSceneHoldsBeforeTheHandOff() {
        let timing = LaunchGrowTiming.full
        #expect(timing.fadeStart - LaunchTimeline.duration >= 0.5)
        #expect(timing.fade(at: 2.9) == 0)
        #expect(timing.fade(at: 3.4) == 1)
    }
}
