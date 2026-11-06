import Foundation

// Program v3 (6 Nov 2026): the prep days and Day Xero are a hand of five cards (docs/program/DECK_SCHEMA.md,
// mockups F1–F9 in design/program-deck). Each card is a listen, a reveal grid, a myth-or-fact deck, or a short
// activity built from the existing beats.

/// One card of a day's hand.
public struct DeckCard: Decodable, Sendable, Identifiable {
    public enum Format: String, Decodable, Sendable, CaseIterable {
        case listen, reveal, myth, breathe
        /// "try" in the JSON: a short activity built from beats.
        case activity = "try"
    }

    public let id: String
    public let format: Format
    public let title: Varied<String>
    public let minutes: Int
    /// "apricot" or "violet" for a listen, "mint", "ocean" or "sky" for an activity. Reveal and myth sit on the deck.
    public let ground: String?
    /// The card's last button, in the person's own words ("I'll just watch today").
    public let commit: Varied<String>
    public let intro: Varied<String>?
    /// A line shown when a listen ends.
    public let after: Varied<String>?
    public let script: Script?
    public let cards: [Reveal]?
    public let statements: [Statement]?
    /// Beats shown before the card's main view (Day Xero's note from last night).
    public let before: [Beat]
    /// Beats shown after it; a try or breathe card is only these.
    public let beats: [Beat]
    /// P3's guided use: the person may save it for later, and `laterTakes` wait with it.
    public let canSaveForLater: Bool
    public let laterTakes: [String]
    /// A reveal shows this many of its cards, the person's own triggers first (Prep 2); nil shows them all.
    public let showCount: Int?
    /// An evening card opens at this hour, local time (18 for 6 pm); nil is open all day.
    public let opensAt: Int?

    public struct Script: Decodable, Sendable {
        public let voice: String?
        public let chapters: [Chapter]

        public struct Chapter: Decodable, Sendable {
            public let title: String
            /// The spoken text: `[pause]` and delivery tags, `{s: … | v: … | p: …}` wording, paragraphs split by a blank line.
            public let text: Varied<String>
        }
    }

    /// A face-down question; turned over it shows the answer, and "Go deeper" opens the longer read.
    public struct Reveal: Decodable, Sendable {
        public let front: Varied<String>
        public let answer: Varied<String>
        public let deeper: Varied<String>
        public let keep: Varied<String>?
        public let source: Varied<String>?
        /// The onboarding trigger this card is about (`coffee`, `meals`…), so the person's own come first.
        public let trigger: String?
    }

    public struct Statement: Decodable, Sendable {
        public enum Answer: String, Decodable, Sendable { case myth, fact, partly }

        public let text: Varied<String>
        public let answer: Varied<Answer>
        public let verdict: Varied<String>
        public let explanation: Varied<String>
        public let source: Varied<String>?
    }

    enum CodingKeys: String, CodingKey {
        case id, format, title, minutes, ground, commit, intro, after, script, cards, statements, before, beats
        case canSaveForLater, laterTakes, showCount, opensAt
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        format = try c.decode(Format.self, forKey: .format)
        title = try c.decode(Varied<String>.self, forKey: .title)
        minutes = try c.decode(Int.self, forKey: .minutes)
        ground = try c.decodeIfPresent(String.self, forKey: .ground)
        commit = try c.decode(Varied<String>.self, forKey: .commit)
        intro = try c.decodeIfPresent(Varied<String>.self, forKey: .intro)
        after = try c.decodeIfPresent(Varied<String>.self, forKey: .after)
        script = try c.decodeIfPresent(Script.self, forKey: .script)
        cards = try c.decodeIfPresent([Reveal].self, forKey: .cards)
        statements = try c.decodeIfPresent([Statement].self, forKey: .statements)
        before = try c.decodeIfPresent([Beat].self, forKey: .before) ?? []
        beats = try c.decodeIfPresent([Beat].self, forKey: .beats) ?? []
        canSaveForLater = try c.decodeIfPresent(Bool.self, forKey: .canSaveForLater) ?? false
        laterTakes = try c.decodeIfPresent([String].self, forKey: .laterTakes) ?? []
        showCount = try c.decodeIfPresent(Int.self, forKey: .showCount)
        opensAt = try c.decodeIfPresent(Int.self, forKey: .opensAt)
    }

    /// The reveal cards to show: the ones about the person's own triggers first, in the file's order, then the rest,
    /// cut to `showCount`.
    public func reveals(forTriggers triggers: [String]) -> [Reveal] {
        let all = cards ?? []
        let isMine = { (card: Reveal) -> Bool in
            guard let trigger = card.trigger else { return false }
            return triggers.contains(trigger)
        }
        let mine = all.filter(isMine)
        let rest = all.filter { !isMine($0) }
        let ordered = mine + rest
        return showCount.map { Array(ordered.prefix($0)) } ?? ordered
    }

    /// Whether an evening card is open at `hour` (0–23, local). After midnight it stays open until the day ends at
    /// `boundaryHour`, so a night owl's evening isn't cut off.
    public func isOpen(hour: Int, boundaryHour: Int) -> Bool {
        guard let opensAt else { return true }
        return hour >= opensAt || hour < boundaryHour
    }

    /// Whether the card has a screen of its own before its beats. Activities open on a short card intro too.
    public var hasMainView: Bool { true }

    /// The recording's file stem: card "P1.1" plays "vo_P1_1_smoking.m4a".
    public var audioKey: String { id.replacingOccurrences(of: ".", with: "_") }

    /// Every on-screen string, with where it is, for checking.
    var textFields: [(place: String, value: Varied<String>)] {
        var out: [(String, Varied<String>?)] = [("title", title), ("commit", commit), ("intro", intro), ("after", after)]
        for (i, card) in (cards ?? []).enumerated() {
            out += [("cards[\(i)].front", card.front), ("cards[\(i)].answer", card.answer), ("cards[\(i)].deeper", card.deeper),
                    ("cards[\(i)].keep", card.keep), ("cards[\(i)].source", card.source)]
        }
        for (i, s) in (statements ?? []).enumerated() {
            out += [("statements[\(i)].text", s.text), ("statements[\(i)].verdict", s.verdict),
                    ("statements[\(i)].explanation", s.explanation), ("statements[\(i)].source", s.source)]
        }
        return out.compactMap { place, value in value.map { (place, $0) } }
    }
}

/// The end of a deck day: what they learned, an optional line with their numbers (P1's money), and tomorrow.
public struct DayRecap: Decodable, Sendable {
    public let learned: [Varied<String>]
    public let statLines: [Varied<String>]?
    public let tomorrow: Varied<String>?
}

extension ProgramContent.Session {
    /// A prep day or Day Xero built as a hand of cards (program v3).
    public var isDeck: Bool { !(deck ?? []).isEmpty }

    /// Every beat the session can show: its own, the cards', and the mission's follow-up.
    public var everyBeat: [Beat] {
        beats + (deck ?? []).flatMap { $0.before + $0.beats } + (mission?.followUp ?? [])
    }

    /// The order the cards are played in. A card saved for later (and the cards that wait for it) go after the rest.
    public func playOrder(savedForLater: Set<String>) -> [DeckCard] {
        let cards = deck ?? []
        let held = cards.filter { savedForLater.contains($0.id) }
        let waiting = Set(held.flatMap { [$0.id] + $0.laterTakes })
        return cards.filter { !waiting.contains($0.id) } + cards.filter { waiting.contains($0.id) }
    }
}

/// Inline product wording: `{s: light up | v: take a hit | p: put one in}` becomes the person's version.
public enum ProgramInline {
    /// The text with every `{s: … | v: … | p: …}` replaced by the part for `variant`. Anything else is left alone.
    public static func resolve(_ text: String, _ variant: ProgramVariant) -> String {
        guard text.contains("{s:") else { return text }
        var out = ""
        var rest = text[...]
        while let open = rest.range(of: "{s:") {
            out += rest[..<open.lowerBound]
            guard let close = rest[open.upperBound...].firstIndex(of: "}") else {
                out += rest[open.lowerBound...]
                rest = ""
                break
            }
            let body = rest[open.upperBound..<close]
            let parts = body.split(separator: "|", omittingEmptySubsequences: false).map { $0.trimmingCharacters(in: .whitespaces) }
            if parts.count == 3, parts[1].hasPrefix("v:"), parts[2].hasPrefix("p:") {
                let picked: String = switch variant {
                case .smoking: parts[0]
                case .vaping: String(parts[1].dropFirst(2))
                case .pouches: String(parts[2].dropFirst(2))
                }
                out += picked.trimmingCharacters(in: .whitespaces)
            } else {
                out += rest[open.lowerBound...close]
            }
            rest = rest[rest.index(after: close)...]
        }
        out += rest
        return tidy(out)
    }

    /// Script text as it reads on screen: tags such as `[pause]` and `[warmly]` taken out.
    public static func spoken(_ text: String, _ variant: ProgramVariant) -> String {
        var out = resolve(text, variant)
        while let open = out.range(of: "["), let close = out[open.upperBound...].firstIndex(of: "]") {
            out.removeSubrange(open.lowerBound...close)
        }
        return tidy(out)
    }

    /// The paragraphs of a script chapter, for reading.
    public static func paragraphs(_ text: String, _ variant: ProgramVariant) -> [String] {
        spoken(text, variant).components(separatedBy: "\n\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    static func tidy(_ text: String) -> String {
        var out = text
        while out.contains("  ") { out = out.replacingOccurrences(of: "  ", with: " ") }
        for mark in [".", ",", "?", ";", ":"] { out = out.replacingOccurrences(of: " \(mark)", with: mark) }
        return out.replacingOccurrences(of: "\n ", with: "\n").replacingOccurrences(of: " \n", with: "\n")
            .trimmingCharacters(in: .whitespaces)
    }
}

extension ProgramContent {
    /// What's wrong with a deck day (docs/program/DECK_SCHEMA.md). `checkText` reports text that's missing for a product
    /// or uses an unknown placeholder, into the caller's list.
    func deckProblems(_ session: Session, checkText: (Varied<String>?, String) -> Void) -> [String] {
        guard let deck = session.deck else { return [] }
        var problems: [String] = []
        if deck.count != 5 { problems.append("\(session.id) has \(deck.count) cards; a day has 5") }
        if !session.beats.isEmpty { problems.append("\(session.id) keeps beats outside its cards") }
        if deck.reduce(0, { $0 + $1.minutes }) != session.durationMinutes {
            problems.append("\(session.id)'s minutes aren't the sum of its cards'")
        }
        for (n, card) in deck.enumerated() {
            let place = "\(session.id)/\(card.id)"
            if card.id != "\(session.id).\(n + 1)" { problems.append("\(place) should be \(session.id).\(n + 1)") }
            for field in card.textFields { checkText(field.value, "\(place).\(field.place)") }
            switch card.format {
            case .listen:
                let chapters = card.script?.chapters ?? []
                if chapters.isEmpty { problems.append("\(place) is a listen with no script") }
                for (i, chapter) in chapters.enumerated() {
                    checkText(chapter.text, "\(place).script[\(i)]")
                    for variant in ProgramVariant.allCases
                    where ProgramInline.paragraphs(chapter.text.resolve(variant) ?? "", variant).isEmpty {
                        problems.append("\(place).script[\(i)] has nothing to read for \(variant.rawValue)")
                    }
                }
            case .reveal:
                if !(4...6).contains(card.cards?.count ?? 0) { problems.append("\(place) needs 4 to 6 cards to reveal") }
                if let show = card.showCount, !(1...(card.cards?.count ?? 0)).contains(show) {
                    problems.append("\(place) shows more cards than it has")
                }
            case .myth:
                if (card.statements?.count ?? 0) != 5 { problems.append("\(place) needs 5 statements") }
                for (i, statement) in (card.statements ?? []).enumerated() {
                    for variant in ProgramVariant.allCases where statement.answer.resolve(variant) == nil {
                        problems.append("\(place).statements[\(i)] has no answer for \(variant.rawValue)")
                    }
                }
            case .activity, .breathe:
                if card.beats.isEmpty { problems.append("\(place) is an activity with no beats") }
            }
            if let hour = card.opensAt, !(0...23).contains(hour) { problems.append("\(place) opens at an hour that doesn't exist") }
            for later in card.laterTakes where !deck.contains(where: { $0.id == later }) {
                problems.append("\(place) holds back \(later), which isn't a card of this day")
            }
        }
        let recap = session.recap
        if recap?.learned.count != 3 { problems.append("\(session.id)'s recap needs 3 things learned") }
        for (i, line) in (recap?.learned ?? []).enumerated() { checkText(line, "\(session.id).recap.learned[\(i)]") }
        for (i, line) in (recap?.statLines ?? []).enumerated() { checkText(line, "\(session.id).recap.statLines[\(i)]") }
        checkText(recap?.tomorrow, "\(session.id).recap.tomorrow")
        return problems
    }
}
