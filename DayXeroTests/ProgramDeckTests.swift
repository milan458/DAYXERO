@testable import DayXero
import DayXeroCore
import Foundation
import Testing

/// Program v3 (6 Nov 2026): the prep days and Day Xero as decks of five cards (docs/program/DECK_SCHEMA.md).
struct ProgramDeckTests {
    private func content() throws -> ProgramContent { try #require(ProgramContent.bundled, "program.json is missing or broken") }

    @Test func inlineWordingFollowsTheProduct() {
        let text = "Before you {s: light up | v: take a hit | p: put one in}, pause."
        #expect(ProgramInline.resolve(text, .smoking) == "Before you light up, pause.")
        #expect(ProgramInline.resolve(text, .vaping) == "Before you take a hit, pause.")
        #expect(ProgramInline.resolve(text, .pouches) == "Before you put one in, pause.")
        // An empty part leaves no double space or space before punctuation.
        #expect(ProgramInline.resolve("Stop {s: | v: | p: the pouch } now.", .smoking) == "Stop now.")
        // Placeholders and plain braces are left for the placeholder filler.
        #expect(ProgramInline.resolve("On {quit_date}.", .vaping) == "On {quit_date}.")
    }

    @Test func scriptsReadWithoutTheirTags() {
        let chapter = "[warmly] Hi. [pause] You don't have to {s: smoke | v: vape | p: use pouches} today.\n\n[long pause] That's it."
        #expect(ProgramInline.spoken(chapter, .vaping) == "Hi. You don't have to vape today.\n\nThat's it.")
        #expect(ProgramInline.paragraphs(chapter, .pouches) == ["Hi. You don't have to use pouches today.", "That's it."])
    }

    @Test func everyPrepDayAndDayXeroIsADeckOfFive() throws {
        let program = try content()
        for id in ["P1", "P2", "P3", "P4", "P5", "P6", "P7", "DX"] {
            let session = try #require(program.session(id))
            let deck = try #require(session.deck, "\(id) is not a deck")
            #expect(deck.count == 5, "\(id)")
            #expect(deck.map(\.id) == (1...5).map { "\(id).\($0)" })
            #expect(session.beats.isEmpty, "\(id)")
            #expect(session.recap?.learned.count == 3, "\(id)")
            #expect(deck.reduce(0) { $0 + $1.minutes } == session.durationMinutes, "\(id)")
            // Every day has something to listen to, and every listen has a script to read until the audio arrives.
            let listens = deck.filter { $0.format == .listen }
            #expect(!listens.isEmpty, "\(id)")
            for card in listens {
                let chapters = try #require(card.script?.chapters, "\(card.id)")
                for variant in ProgramVariant.allCases {
                    #expect(!chapters.flatMap { ProgramInline.paragraphs($0.text.resolve(variant) ?? "", variant) }.isEmpty, "\(card.id)")
                }
            }
        }
        // The week after keeps the v2 shape.
        #expect(program.session("W1D1")?.isDeck == false)
    }

    /// The holds that start things still exist: Day Xero's starts the counter, Prep 7's marks the night before.
    @Test func theHoldsSurviveTheDeck() throws {
        let program = try content()
        let dx = try #require(program.session("DX"))
        let first = try #require(dx.deck?.first)
        #expect(first.beats.contains { $0.type == .commit && $0.sets == "quit_timestamp" })
        #expect(first.before.contains { $0.textFrom == "note_to_dayxero" })
        let p7 = try #require(program.session("P7"))
        #expect(p7.everyBeat.contains { $0.type == .commit && $0.sets == "dayxero_ready" })
        let p1 = try #require(program.session("P1"))
        #expect(p1.everyBeat.contains { $0.type == .commit })
        #expect(dx.unlock.rule == .dayXero)
    }

    /// P1's money moved to the day's recap.
    @Test func prepOnesRecapCarriesTheMoney() throws {
        let p1 = try #require(try content().session("P1"))
        let lines = (p1.recap?.statLines ?? []).compactMap { $0.resolve(.smoking) }
        #expect(lines.contains { $0.contains("{yearly_cost}") })
        let values = ProgramPlaceholders(["yearly_units": "4,380", "unit_plural": "cigarettes", "currency": "$", "yearly_cost": "2,555"])
        #expect(lines.compactMap { values.fill($0) }.contains { $0.contains("$2,555") })
    }

    /// Decided 6 Nov: P3's guided use may be saved for later. It and the card that waits for it go after the rest.
    @Test func aCardSavedForLaterMovesWithWhatWaitsForIt() throws {
        let p3 = try #require(try content().session("P3"))
        let guided = try #require(p3.deck?.first { $0.canSaveForLater })
        #expect(guided.id == "P3.3")
        #expect(guided.laterTakes == ["P3.4"])
        #expect(p3.playOrder(savedForLater: []).map(\.id) == ["P3.1", "P3.2", "P3.3", "P3.4", "P3.5"])
        #expect(p3.playOrder(savedForLater: ["P3.3"]).map(\.id) == ["P3.1", "P3.2", "P3.5", "P3.3", "P3.4"])
    }

    @Test func mythAnswersAreSetForEveryProduct() throws {
        let program = try content()
        for session in program.sessions where session.isDeck {
            for card in session.deck ?? [] where card.format == .myth {
                #expect(card.statements?.count == 5, "\(card.id)")
                for statement in card.statements ?? [] {
                    for variant in ProgramVariant.allCases {
                        #expect(statement.answer.resolve(variant) != nil, "\(card.id)")
                    }
                }
            }
        }
    }

    @Test func theRecordingFollowsTheCardsId() throws {
        let program = try content()
        let card = try #require(program.session("P1")?.deck?.first)
        #expect(card.audioKey == "P1_1")
        #expect(program.audio.file(session: card.audioKey, variant: "pouches") == "vo_P1_1_pouches.m4a")
    }

    @Test func theCheckerCatchesABrokenDeck() throws {
        let broken = """
        {"version": "x", "contentStatus": "draft",
         "audio": {"folder": "a", "fileName": "vo_{sessionId}_{variant}.m4a", "transcriptFileName": "tx.json"},
         "phases": [{"id": "prep", "title": "Prep", "subtitle": "", "sessionIds": ["P1"]}],
         "sessions": [
          {"id": "P1", "phaseId": "prep", "label": "Prep 1", "title": "T", "subtitle": "", "durationMinutes": 9,
           "unlock": {"rule": "first"}, "audio": {"variants": ["default"]}, "beats": [],
           "deck": [
            {"id": "P1.1", "format": "listen", "title": "L", "minutes": 6, "commit": "Ok {who}"},
            {"id": "P1.9", "format": "try", "title": "T", "minutes": 2, "commit": "Ok", "laterTakes": ["P1.7"]}
           ],
           "recap": {"learned": ["One"]},
           "completionText": "Done"}
         ],
         "sosTracks": []}
        """
        let program = try ProgramContent(data: Data(broken.utf8))
        let problems = program.problems(patterns: ["box"]).joined(separator: "\n")
        #expect(problems.contains("P1 has 2 cards; a day has 5"))
        #expect(problems.contains("minutes aren't the sum"))
        #expect(problems.contains("should be P1.2"))
        #expect(problems.contains("is a listen with no script"))
        #expect(problems.contains("is an activity with no beats"))
        #expect(problems.contains("holds back P1.7"))
        #expect(problems.contains("recap needs 3 things learned"))
        #expect(problems.contains("unknown placeholder {who}"))
        // A deck day isn't asked for a 90-second stack.
        #expect(!problems.contains("P1 has 0 cards; a stack"))
    }

    /// The hand comes first, each card ends on its played screen, and the day ends on the mission and the recap.
    @MainActor @Test func backNeverCrossesAHoldInADeck() throws {
        let dx = try #require(try content().session("DX"))
        let hold = try #require(dx.everyBeat.first { $0.sets == "quit_timestamp" })
        let steps: [SessionFlowView.FlowStep] = [.hand, .card("DX.1"), .beat(hold.id), .played("DX.1"), .card("DX.2")]
        #expect(!SessionFlowView.canGoBack(from: 3, in: steps, beats: dx.everyBeat))
        #expect(SessionFlowView.canGoBack(from: 4, in: steps, beats: dx.everyBeat))
        #expect(SessionFlowView.canGoBack(from: 1, in: steps, beats: dx.everyBeat))
    }
}
