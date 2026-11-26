@testable import DayXero
import Foundation
import Testing

/// 27 Nov 2026: the shield keeps a program session's picture out of a screen recording, and the lesson audio
/// waits while one runs, so its voice stays out too.
@MainActor
struct LessonCaptureTests {
    private func narrator() -> LessonNarrator {
        LessonNarrator(transcript: "Breathe in. Hold it there. Now let it go.", url: nil, seconds: 12)
    }

    @Test func aRecordingHoldsTheLessonAndItPlaysOnAfter() {
        let n = narrator()
        defer { n.stop() }
        n.play()
        #expect(n.playing)
        n.captureChanged(true)
        #expect(!n.playing)
        #expect(n.heldForCapture)
        n.captureChanged(false)
        #expect(n.playing)
        #expect(!n.heldForCapture)
    }

    @Test func aPauseByHandDuringARecordingStaysPaused() {
        let n = narrator()
        defer { n.stop() }
        n.play()
        n.captureChanged(true)
        n.pause()
        #expect(!n.heldForCapture)
        n.captureChanged(false)
        #expect(!n.playing)
    }

    @Test func aLessonThatWasNotPlayingIsLeftAlone() {
        let n = narrator()
        defer { n.stop() }
        n.captureChanged(true)
        #expect(!n.heldForCapture)
        n.captureChanged(false)
        #expect(!n.playing)
    }
}
