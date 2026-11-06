@testable import DayXero
import DayXeroCore
import Foundation
import Testing

struct ProgramContentTests {
    private func content() throws -> ProgramContent { try #require(ProgramContent.bundled, "program.json is missing or broken") }

    @Test func theBundledProgramLoadsWithEveryPhaseAndSession() throws {
        let program = try content()
        #expect(program.phases.map(\.id) == ["prep", "dayxero", "w1", "w2", "w3", "w4", "after"])
        #expect(program.sessions.count == 28)
        #expect(program.sessions.first?.id == "P1" && program.sessions.last?.id == "B90")
        #expect(program.sosTracks.map(\.id) == ["SOS1", "SOS2", "SOS3", "SOS4"])
    }

    /// S27.18: no cliff at Day 31. Three boosters follow graduation, on Days 45, 60 and 90, opening by days since
    /// Day Xero like the weeks before them. Their content is a draft for Milan to review.
    @Test func boostersFollowGraduation() throws {
        let program = try content()
        let after = try #require(program.phases.first { $0.id == "after" })
        #expect(after.sessionIds == ["B45", "B60", "B90"])
        let boosters = after.sessionIds.compactMap { program.session($0) }
        #expect(boosters.map(\.label) == ["Day 45", "Day 60", "Day 90"])
        #expect(boosters.map(\.unlock.minDay) == [44, 59, 89])
        #expect(boosters.allSatisfy { $0.unlock.rule == .daysSinceQuit })
        // The graduation session still ends the four weeks, so the finale plays there and not after a booster.
        #expect(program.session(after: "W4S3")?.id == "B45")
        #expect(boosters.allSatisfy { !$0.beats.contains { $0.sets == "graduated_at" } })
    }

    /// MON-04: every v2 session has a 90-second read of three to five cards, worded for each product. The prep days
    /// and Day Xero are decks of five cards instead (program v3) and have no stack.
    @Test func everySessionHasACardStack() throws {
        let program = try content()
        for session in program.sessions {
            if session.isDeck {
                #expect(session.cards == nil && session.deck?.count == 5, "\(session.id)")
            } else {
                #expect(ProgramContent.cardStackSize.contains(session.cards?.count ?? 0), "\(session.id)")
            }
        }
        let w1d1 = try #require(program.session("W1D1")?.cards)
        #expect(!w1d1.isEmpty)
    }

    /// MON-04: with the 90-second read in place of the audio, sessions say their own, shorter length: never more than
    /// the listening length, never under 2 minutes.
    @Test func theReadVersionHasItsOwnShorterLength() throws {
        let program = try content()
        for session in program.sessions {
            let minutes = session.readMinutes()
            #expect((2...session.durationMinutes).contains(minutes), "\(session.id): \(minutes) min")
        }
        // A deck day's length is its cards' minutes; the v2 sessions read faster than they listen.
        for session in program.sessions where session.isDeck {
            #expect(session.readMinutes() == session.durationMinutes, "\(session.id)")
        }
        let v2 = program.sessions.filter { !$0.isDeck }
        #expect(v2.reduce(0) { $0 + $1.readMinutes() } < v2.reduce(0) { $0 + $1.durationMinutes })
    }

    /// A breathing beat lasts its cycles of its pattern; the content's patterns come from the orb data.
    @Test func aBreathingBeatLastsItsCycles() throws {
        let p4 = try #require(try content().session("P4"))
        let breathe = try #require(p4.everyBeat.first { $0.type == .breathe })
        #expect(breathe.typicalSeconds(cycleSeconds: { _ in 10 }) == 10 * (breathe.cycles ?? 3))
        #expect(OrbData.bundled.breathingPatterns.first { $0.id == "box" }?.cycleSeconds == 16)
    }

    /// MON-04: the card stack sits where the audio goes; the recording plays only for someone who chose to listen.
    @MainActor @Test func theLessonIsTheCardStackUnlessTheyChoseToListen() {
        #expect(SessionFlowView.lessonStep(hasCards: true, hasAudio: false, format: .listen) == .cards)
        #expect(SessionFlowView.lessonStep(hasCards: true, hasAudio: true, format: .read) == .cards)
        #expect(SessionFlowView.lessonStep(hasCards: true, hasAudio: true, format: .listen) == .audio)
        #expect(SessionFlowView.lessonStep(hasCards: false, hasAudio: true, format: .read) == .audio)
        #expect(SessionFlowView.lessonStep(hasCards: false, hasAudio: false, format: .read) == nil)
    }

    /// Back works on every step after the first, so P1's "Which one matters most?" can go back to "Your reasons" when
    /// nothing was written; never on the first step, the completion, or straight after a hold (it could be redone).
    @MainActor @Test func backIsOfferedExceptAfterAHold() throws {
        let p1 = try #require(try content().session("P1"))
        let beats = p1.everyBeat
        let reasonsBeat = try #require(beats.first { $0.saveAs == "reasons" })
        let pickBeat = try #require(beats.first { $0.saveAs == "primary_reason" })
        #expect(pickBeat.optionsFrom == "reasons")
        let steps: [SessionFlowView.FlowStep] = [.hand, .card("P1.4"), .beat(reasonsBeat.id), .beat(pickBeat.id), .completion]
        #expect(SessionFlowView.canGoBack(from: 3, in: steps, beats: beats))
        #expect(!SessionFlowView.canGoBack(from: 0, in: steps, beats: beats))
        #expect(!SessionFlowView.canGoBack(from: steps.count - 1, in: steps, beats: beats))
        let hold = try #require(beats.first { $0.type == .commit })
        let withMission: [SessionFlowView.FlowStep] = [.hand, .beat(hold.id), .mission, .completion]
        #expect(!SessionFlowView.canGoBack(from: 2, in: withMission, beats: beats))
    }

    /// CLIN-08: Week 2's "The flat days" (dopamine and brain fog) opens on Day 13, between Sleep and Two weeks. Its id
    /// is W2S4 because session ids are saved in people's records; the order comes from the list, not the number.
    @Test func weekTwoHasTheFlatDays() throws {
        let program = try content()
        let week2 = try #require(program.phases.first { $0.id == "w2" })
        #expect(week2.sessionIds == ["W2S1", "W2S2", "W2S4", "W2S3"])
        let flat = try #require(program.session("W2S4"))
        #expect(flat.title.resolve(.smoking) == "The flat days")
        #expect(flat.label == "Day 13")
        #expect(flat.unlock.minDay == 12)
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
        let notice = try #require(p3.everyBeat.first { $0.saveAs == "mindful_notice" })
        #expect(notice.options?.resolve(.smoking)?.contains { $0.text == "Harsh taste" } == true)
        #expect(notice.options?.resolve(.vaping)?.contains { $0.text == "Mostly sweetener" } == true)
        #expect(notice.options?.resolve(.pouches)?.contains { $0.text == "Burn on my gum" } == true)

        // A checklist with no default and per-product lists.
        let p6 = try #require(program.session("P6"))
        let friction = try #require(p6.everyBeat.first { $0.saveAs == "friction_checklist" })
        #expect(friction.checklist?.resolve(.vaping)?.first == "Off my desk")
        // The same list for everyone.
        let kit = try #require(p6.everyBeat.first { $0.saveAs == "quit_kit_checklist" })
        #expect(kit.checklist?.resolve(.pouches)?.count == 4)

        // A footer only vaping has.
        let p7 = try #require(program.session("P7"))
        let clearOut = try #require(p7.everyBeat.first { $0.saveAs == "clearout_checklist" })
        #expect(clearOut.footer?.resolve(.vaping)?.contains("battery") == true)
        #expect(clearOut.footer?.resolve(.smoking) == nil)

        // Pouches get the taper option; the others the default three.
        let nrt = try #require(p6.everyBeat.first { $0.type == .nrtChoice })
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
        let w1d1 = try #require(program.session("W1D1"))
        #expect(w1d1.audio.pick(for: .pouches, nrtActive: false) == "default")
        #expect(program.audio.file(session: "P1", variant: "vaping") == "vo_P1_vaping.m4a")
    }

    @Test func beatsSplitAroundTheAudioAndKnowWhatsRequired() throws {
        let program = try content()
        let w3s1 = try #require(program.session("W3S1"))
        #expect(w3s1.beatsBeforeAudio.map(\.id) == ["W3S1.1"])
        #expect(w3s1.beatsAfterAudio.first?.id != "W3S1.1")
        let p1 = try #require(program.session("P1"))
        #expect(p1.everyBeat.first { $0.type == .commit }?.isRequired == true)
        #expect(p1.everyBeat.first { $0.type == .reflect }?.isRequired == false)
        let w1d2 = try #require(program.session("W1D2"))
        #expect(w1d2.beats.first { $0.type == .quiz }?.isRequired == true)
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
