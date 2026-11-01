import DayXeroCore
import Foundation
import SwiftUI
import Testing

struct CrewArtTests {
    @Test func svgPathReadsXerosBody() {
        let body = SVGPath.path("M100 34 C138 34 166 68 166 112 C166 156 138 188 100 188 C62 188 34 156 34 112 C34 68 62 34 100 34 Z")
        let box = body.boundingRect
        #expect(abs(box.minX - 34) < 0.5 && abs(box.maxX - 166) < 0.5)
        #expect(abs(box.minY - 34) < 0.5 && abs(box.maxY - 188) < 0.5)
    }

    @Test func svgPathHandlesRelativeAndImplicitCommands() {
        // Jelli's crown star uses only relative lines.
        let star = SVGPath.path("M100 18 l4 9 l9 1 l-7 6 l2 9 l-8 -5 l-8 5 l2 -9 l-7 -6 l9 -1 Z").boundingRect
        #expect(abs(star.minX - 87) < 0.01 && abs(star.maxX - 113) < 0.01)
        #expect(abs(star.minY - 18) < 0.01 && abs(star.maxY - 43) < 0.01)
        // h and implicit pairs after M (the zzz mark).
        let z = SVGPath.path("M150 40 h12 l-12 12 h12").boundingRect
        #expect(z == CGRect(x: 150, y: 40, width: 12, height: 12))
        let implicit = SVGPath.path("M0 0 10 0 10 10").boundingRect
        #expect(implicit == CGRect(x: 0, y: 0, width: 10, height: 10))
    }

    @Test func tokenizerSplitsSignsAndDecimals() {
        #expect(SVGPath.path("M0 0L-2.5-5").boundingRect == CGRect(x: -2.5, y: -5, width: 2.5, height: 5))
    }

    @Test func artTrackEasesAndLoops() {
        #expect(ArtTrack.ease(0) < 0.0001)
        #expect(abs(ArtTrack.ease(1) - 1) < 0.0001)
        #expect(abs(ArtTrack.ease(0.5) - 0.5) < 0.0001)
        let hop = ArtTrack(scalars: [0, -7, 0], times: [0, 0.5, 1], duration: 4, spline: true)
        #expect(abs(hop.scalar(at: 2) + 7) < 0.0001)
        #expect(abs(hop.scalar(at: 6) + 7) < 0.0001)
        #expect(hop.scalar(at: 2, animate: false) == 0)
        // Before `begin`, a track rests on its first value.
        let bubble = ArtTrack(scalars: [130, 40], duration: 5, begin: 1)
        #expect(bubble.scalar(at: 0.5) == 130)
        #expect(abs(bubble.scalar(at: 3.5) - 85) < 0.0001)
    }

    @Test func blinkHoldsOpenThenCloses() {
        let blink = ArtTrack(scalars: [1, 1, 0.1, 1], times: [0, 0.92, 0.96, 1], duration: 4.5)
        #expect(blink.scalar(at: 2) == 1)
        #expect(abs(blink.scalar(at: 0.96 * 4.5) - 0.1) < 0.0001)
    }

    @Test func crewStageFollowsDaysClear() {
        #expect([0, 6, 7, 13, 14, 27, 28, 365].map(CrewGrowth.stage(daysClear:)) == [1, 1, 2, 2, 3, 3, 4, 4])
    }

    /// Persona checks: Day 1 (Quit Day) 23, Sun 8 Nov (3 days clear) 28, prep 20, capped at 100.
    @Test func skyClarityMatchesThePersona() {
        #expect(CrewGrowth.clarity(daysClear: 0) == 20)
        #expect(CrewGrowth.clarity(daysClear: 1) == 23)
        #expect(CrewGrowth.clarity(daysClear: 3) == 28)
        #expect(CrewGrowth.clarity(daysClear: 31) == 100)
    }

    /// S27.16: each stage looks different at a glance: Xero grows from the feet and his colour deepens.
    @Test func xeroGrowsAndDeepensByStage() {
        let looks = (1...4).map { XeroView.look(stage: $0) }
        #expect(looks.map(\.grow) == [0.8, 0.88, 0.95, 1])
        #expect(Set(looks.map(\.body)).count == 4, "Every stage has its own body colour")
        #expect(looks.map(\.cheek) == looks.map(\.cheek).sorted(), "Cheeks warm up with the stage")
        // Out-of-range stages clamp to the ends.
        #expect(XeroView.look(stage: 0) == looks[0])
        #expect(XeroView.look(stage: 9) == looks[3])
    }
}
