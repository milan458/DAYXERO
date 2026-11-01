@testable import DayXero
import DayXeroCore
import Foundation
import Testing

struct ProgramContentTests {
    private func content() throws -> ProgramContent { try #require(ProgramContent.bundled, "program.json is missing or broken") }

    @Test func theBundledProgramLoadsWithEveryPhaseAndSession() throws {
        let program = try content()
        #expect(program.phases.map(\.id) == ["prep", "dayxero", "w1", "w2", "w3", "w4"])
        #expect(program.sessions.count == 24)
        #expect(program.sessions.first?.id == "P1" && program.sessions.last?.id == "W4S3")
        #expect(program.sosTracks.map(\.id) == ["SOS1", "SOS2", "SOS3", "SOS4"])
    }

    @Test func theContentHasNoProblems() throws {
        let patterns = Set(OrbData.bundled.breathingPatterns.map(\.id))
        let problems = try content().problems(patterns: patterns)
        #expect(problems.isEmpty, "\(problems.joined(separator: "\n"))")
    }

    @Test func theCheckerCatchesBrokenContent() throws {
        let broken = """
        {"version": "x", "contentStatus": "draft",
         "audio": {"folder": "a", "fileName": "vo_{sessionId}_{variant}.m4a", "transcriptFileName": "tx.json"},
         "phases": [{"id": "prep", "title": "Prep", "subtitle": "", "sessionIds": ["P1", "P2"]}],
         "sessions": [
          {"id": "P1", "phaseId": "prep", "label": "Prep 1", "title": "One {nickname}", "subtitle": "", "durationMinutes": 5,
           "unlock": {"rule": "first"}, "audio": {"variants": ["smoking"]},
           "beats": [
            {"id": "B1", "type": "quiz", "prompt": "Q", "options": [{"id": "a", "text": "A"}], "correctId": "b"},
            {"id": "B2", "type": "note", "title": "T", "textFrom": "no_line"},
            {"id": "B2", "type": "breathe", "pattern": "spin", "cycles": 2, "label": {"vaping": "Breathe"}}
           ],
           "completionText": "Done"}
         ],
         "sosTracks": []}
        """
        let program = try ProgramContent(data: Data(broken.utf8))
        let problems = program.problems(patterns: ["box"]).joined(separator: "\n")
        #expect(problems.contains("phase session lists don't match"))
        #expect(problems.contains("beat B2 appears twice"))
        #expect(problems.contains("quiz answer isn't one of its options"))
        #expect(problems.contains("reads no_line before anything saves it"))
        #expect(problems.contains("breathes a pattern the orb doesn't have"))
        #expect(problems.contains("unknown placeholder {nickname}"))
        #expect(problems.contains("label has nothing for smoking"))
        #expect(problems.contains("no audio for some products and no default"))
    }

    @Test func wordingFollowsTheMainProduct() throws {
        let program = try content()
        let p3 = try #require(program.session("P3"))
        let notice = try #require(p3.mission?.followUp?.first { $0.id == "P3.F2" })
        #expect(notice.options?.resolve(.smoking)?.contains { $0.text == "Harsh taste" } == true)
        #expect(notice.options?.resolve(.vaping)?.contains { $0.text == "Mostly sweetener" } == true)
        #expect(notice.options?.resolve(.pouches)?.contains { $0.text == "Burn on my gum" } == true)

        // A checklist with no default and per-product lists.
        let p6 = try #require(program.session("P6"))
        let friction = try #require(p6.beats.first { $0.id == "P6.1" })
        #expect(friction.checklist?.resolve(.vaping)?.first == "Off my desk")
        // The same list for everyone.
        let kit = try #require(p6.beats.first { $0.id == "P6.2" })
        #expect(kit.checklist?.resolve(.pouches)?.count == 4)

        // A footer only vaping has.
        let p7 = try #require(program.session("P7"))
        let clearOut = try #require(p7.beats.first { $0.id == "P7.1" })
        #expect(clearOut.footer?.resolve(.vaping)?.contains("battery") == true)
        #expect(clearOut.footer?.resolve(.smoking) == nil)

        // Pouches get the taper option; the others the default three.
        let nrt = try #require(p6.beats.first { $0.type == .nrtChoice })
        #expect(nrt.options?.resolve(.pouches)?.map(\.id) == ["setup", "have", "taper", "no"])
        #expect(nrt.options?.resolve(.smoking)?.map(\.id) == ["setup", "have", "no"])
    }

    @Test func productsMapToTheirWording() {
        #expect(ProgramVariant(.cigarettes) == .smoking)
        #expect(ProgramVariant(.vape) == .vaping)
        #expect(ProgramVariant(.pouches) == .pouches)
    }

    @Test func audioPicksNRTThenProductThenDefault() throws {
        let program = try content()
        let w4s1 = try #require(program.session("W4S1"))
        #expect(w4s1.audio.pick(for: .smoking, nrtActive: true) == "nrt")
        #expect(w4s1.audio.pick(for: .smoking, nrtActive: false) == "default")
        let p1 = try #require(program.session("P1"))
        #expect(p1.audio.pick(for: .vaping, nrtActive: true) == "vaping")
        let p5 = try #require(program.session("P5"))
        #expect(p5.audio.pick(for: .pouches, nrtActive: false) == "default")
        #expect(program.audio.file(session: "P1", variant: "vaping") == "vo_P1_vaping.m4a")
    }

    @Test func beatsSplitAroundTheAudioAndKnowWhatsRequired() throws {
        let program = try content()
        let p4 = try #require(program.session("P4"))
        #expect(p4.beatsBeforeAudio.map(\.id) == ["P4.1"])
        #expect(p4.beatsAfterAudio.first?.id == "P4.2")
        let p1 = try #require(program.session("P1"))
        #expect(p1.beats.first { $0.type == .commit }?.isRequired == true)
        #expect(p1.beats.first { $0.type == .quiz }?.isRequired == true)
        #expect(p1.beats.first { $0.type == .reflect }?.isRequired == false)
        let w1d6 = try #require(program.session("W1D6"))
        #expect(w1d6.beats.first { $0.id == "W1D6.3" }?.optional == true)
    }

    @Test func placeholdersFillOrDropButNeverShowBraces() {
        let values = ProgramPlaceholders(["days_free": "14", "money_kept": "₹6,200"])
        #expect(values.fill("{days_free} days free.") == "14 days free.")
        #expect(values.fill("{cravings_ridden} cravings ridden out.") == nil)
        let dropped = values.fillDropping("Roughly {currency}{yearly_cost} kept, {days_free} days.")
        #expect(!dropped.contains("{") && !dropped.contains("}"))
        #expect(dropped.contains("14 days"))
    }

    @Test func countPhrasesAgreeWithTheirNoun() {
        let values = ProgramPlaceholders(["days_free": "1", "cravings_ridden": "1"],
                                         phrases: ["{days_free} days": "1 day", "{cravings_ridden} cravings": "1 craving"])
        #expect(values.fill("{days_free} days free.") == "1 day free.")
        #expect(values.fill("{cravings_ridden} cravings ridden out.") == "1 craving ridden out.")
        #expect(values.fillDropping("{days_free} days free, {money_kept} kept.") == "1 day free, kept.")
    }

    @Test func theSighBreathRunsInhaleTopUpExhaleRest() {
        let orb = OrbData.bundled
        let sigh = orb.pattern("sigh")
        #expect(sigh.id == "sigh")
        var session = BreathSession(mode: .breathing, pattern: "sigh", data: orb)
        var order: [BreathPhase] = [session.phase]
        for _ in 0..<(2 + 1 + 6 + 1) {
            for case let .phaseChanged(p) in session.tick(data: orb) { order.append(p) }
        }
        #expect(Array(order.prefix(5)) == [.inhale, .topUp, .exhale, .rest, .inhale])
        #expect(BreathPhase.topUp.word == "sip in")
        #expect(!orb.scripts(.topUp).isEmpty)
    }
}
