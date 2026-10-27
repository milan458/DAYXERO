@testable import DayXero
import DayXeroCore
import Foundation
import Testing

struct BioOrbTests {
    let data = OrbData.bundled

    @Test func dataFileLoadsWithEverythingTheOrbDraws() {
        #expect(data.plasmaLayers.count == 4)
        #expect(data.geometry.vertices == 120)
        #expect(Set(data.breathingPatterns.map(\.id)) == ["box", "478", "wave"])
        #expect(data.sos.sessionSeconds == 180)
        #expect(data.sos.defaultPattern == "wave")
        #expect(data.coachingLines.count == 3)
        for phase in BreathPhase.allCases { #expect(!data.scripts(phase).isEmpty) }
    }

    /// The toolkit's breathing exercises run on the orb with real patterns (S12.4).
    @Test func calmBreathingToolsUseOrbPatterns() {
        let breathing = CalmTool.allCases.compactMap(\.orbPattern)
        #expect(breathing == ["box", "478"])
        for id in breathing { #expect(data.breathingPatterns.contains { $0.id == id }) }
    }

    /// No "AI" in the labels, and no lung or carbon monoxide claims (spec §9 defaults).
    @Test func copyFollowsTheRevisedWording() {
        #expect(data.labels.badgeSpeaking == "COACH SPEAKING")
        #expect(data.labels.coachButton == "Coach me")
        let all = data.coachingLines.map(\.text) + BreathPhase.allCases.flatMap { data.scripts($0) }
        for banned in ["AI", "carbon monoxide", "cilia", "lungs", "neurochemical"] {
            #expect(!all.contains { $0.contains(banned) }, "\(banned)")
        }
    }

    @Test func phasesRunInOrderAndSkipEmptyOnes() {
        var session = BreathSession(mode: .breathing, pattern: "478", data: data)
        #expect(session.phase == .inhale && session.remaining == 4)
        var changes: [BreathPhase] = []
        for _ in 0..<(4 + 7 + 8) {
            for case let .phaseChanged(p) in session.tick(data: data) { changes.append(p) }
        }
        // 4·7·8 has no rest, so it goes straight back to Inhale and starts cycle 2.
        #expect(changes == [.hold, .exhale, .inhale])
        #expect(session.cycle == 2)
    }

    @Test func breathingEndsAfterTheRecommendedCycles() {
        var session = BreathSession(mode: .breathing, pattern: "box", data: data)
        var seconds = 0
        while !session.finished, seconds < 1000 {
            _ = session.tick(data: data)
            seconds += 1
        }
        #expect(seconds == 16 * 4)   // 4·4·4·4, four cycles
        #expect(session.cycle == 4)
    }

    @Test func sosCountsDownWithCoachingCuesThenFinishes() {
        var session = BreathSession(mode: .sos(seconds: 180), pattern: "wave", data: data)
        #expect(session.startTrigger == "sos_start")
        var cues: [(Int, String)] = []
        var finishedAt: Int?
        for second in 1...200 {
            for event in session.tick(data: data) {
                if case let .coach(trigger) = event { cues.append((180 - second, trigger)) }
                if event == .finished { finishedAt = second }
            }
        }
        #expect(cues.map(\.0) == [90, 30])
        #expect(cues.map(\.1) == ["mid_session", "near_completion"])
        #expect(finishedAt == 180)
        #expect(session.sosRemaining == 0)
    }

    @Test func switchingPatternRestartsTheBreathButNotTheCountdown() {
        var session = BreathSession(mode: .sos(seconds: 180), pattern: "wave", data: data)
        for _ in 0..<7 { _ = session.tick(data: data) }
        session.switchPattern(to: "box", data: data)
        #expect(session.phase == .inhale && session.remaining == 4 && session.cycle == 1)
        #expect(session.sosRemaining == 173)
    }

    @MainActor @Test func engineEasesTheBreathPerFrameAndKeepsCoachLinesOnScreen() {
        let engine = OrbEngine(mode: .breathing, pattern: "box", data: data)
        engine.start()
        var t = 0.0
        engine.advance(to: t)
        let start = engine.breathScale
        // Half a second at 120Hz moves the same as at 60Hz.
        for _ in 0..<60 { t += 1.0 / 120; engine.advance(to: t) }
        let at120 = engine.breathScale
        let other = OrbEngine(mode: .breathing, pattern: "box", data: data)
        other.start()
        var t2 = 0.0
        other.advance(to: t2)
        for _ in 0..<30 { t2 += 1.0 / 60; other.advance(to: t2) }
        #expect(at120 > start)
        #expect(abs(at120 - other.breathScale) < 0.002)
        #expect(abs(engine.orbTime - 1.05) < 0.001)   // 0.035 per 60fps frame, 2.1 a second

        // A coaching line survives the next phase change.
        let line = data.coachingLines[1]
        engine.beginLine(line, voiced: false)
        for _ in 0..<(4 * 120) { t += 1.0 / 120; engine.advance(to: t) }
        #expect(engine.session.phase == .hold)
        #expect(engine.transcript == line.text)
        #expect(engine.coachSpeaking)
    }

    @MainActor @Test func captionOnlyLinesEndAfterTheirDuration() {
        let engine = OrbEngine(mode: .breathing, pattern: "box", data: data)
        let line = data.coachingLines[2]
        engine.advance(to: 0)
        engine.beginLine(line, voiced: false)
        var t = 0.0
        while t < line.durationSeconds + 0.1 { t += 1.0 / 60; engine.advance(to: t) }
        #expect(!engine.coachSpeaking)
    }

    // MARK: Caption (S18.11)

    @Test func linesSplitIntoSentencesWithTheirOffsets() {
        let text = "I'm right here with you. Cravings rise, peak and fade. Let's ride this one together—inhale slowly."
        let parts = OrbCaptionText.fragments(text)
        #expect(parts.map(\.text) == ["I'm right here with you.", "Cravings rise, peak and fade.", "Let's ride this one together—inhale slowly."])
        let ns = text as NSString
        #expect(parts[1].start == ns.range(of: "Cravings").location)
        #expect(parts[2].start == ns.range(of: "Let's").location)
        #expect(OrbCaptionText.fragment(containing: 0, in: parts) == 0)
        #expect(OrbCaptionText.fragment(containing: ns.range(of: "peak").location, in: parts) == 1)
    }

    @Test func ellipsesSplitButShortLinesStayWhole() {
        #expect(OrbCaptionText.fragments("Breathe in slowly... let your shoulders drop.").map(\.text)
            == ["Breathe in slowly...", "let your shoulders drop."])
        #expect(OrbCaptionText.fragments("Hold gently").map(\.text) == ["Hold gently"])
        #expect(OrbCaptionText.fragments("Use 3.5 mg.").map(\.text) == ["Use 3.5 mg."])
    }

    @Test func withoutVoiceEachSentenceGetsTimeForItsLength() {
        let parts = OrbCaptionText.fragments("Short one. A much longer second sentence here.")
        #expect(OrbCaptionText.fragment(at: 0.5, duration: 10, in: parts) == 0)
        #expect(OrbCaptionText.fragment(at: 4, duration: 10, in: parts) == 1)
        #expect(OrbCaptionText.fragment(at: 12, duration: 10, in: parts) == 1)
    }

    @MainActor @Test func theCaptionFollowsTheLineThenTheScript() {
        let engine = OrbEngine(mode: .breathing, pattern: "box", data: data)
        engine.advance(to: 0)
        let line = data.coachingLines[0]
        let parts = OrbCaptionText.fragments(line.text)
        #expect(parts.count > 1)
        engine.beginLine(line, voiced: true)
        #expect(engine.caption == parts[0].text)
        engine.spoke(upTo: parts[1].start)
        #expect(engine.caption == parts[1].text)
        engine.lineEnded()
        #expect(engine.caption == parts[1].text)

        let quiet = OrbEngine(mode: .breathing, pattern: "box", data: data)
        quiet.advance(to: 0)
        quiet.beginLine(line, voiced: false)
        var t = 0.0
        while t < line.durationSeconds - 0.2 { t += 1.0 / 60; quiet.advance(to: t) }
        #expect(quiet.caption == parts[parts.count - 1].text)
    }
}
