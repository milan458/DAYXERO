import Foundation

/// The program's on-screen content (program v2): seven prep days, Day Xero and four weeks after, plus the SOS tracks.
/// Everything lives in `program.json`, so copy changes are edits to that file, not code.
public struct ProgramContent: Decodable, Sendable {
    public let version: String
    public let contentStatus: String
    public let audio: AudioNaming
    public let phases: [Phase]
    public let sessions: [Session]
    public let sosTracks: [SOSTrack]

    public init(data: Data) throws {
        self = try JSONDecoder().decode(ProgramContent.self, from: data)
    }

    /// The bundled file. Missing or broken content is caught by the tests.
    public static let bundled: ProgramContent? = {
        guard let url = Bundle(for: ProgramBundleToken.self).url(forResource: "program", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? ProgramContent(data: data)
    }()

    public func session(_ id: String) -> Session? { sessions.first { $0.id == id } }

    public func phase(of session: Session) -> Phase? { phases.first { $0.id == session.phaseId } }

    /// The prep sessions (Prep 1 to Prep 7).
    public var prepSessionIds: Set<String> { Set(sessions.filter { $0.phaseId == "prep" }.map(\.id)) }

    /// The session after this one in program order.
    public func session(after id: String) -> Session? {
        guard let i = sessions.firstIndex(where: { $0.id == id }), sessions.indices.contains(i + 1) else { return nil }
        return sessions[i + 1]
    }

    // MARK: Audio

    public struct AudioNaming: Decodable, Sendable {
        public let folder: String
        public let fileName: String
        public let transcriptFileName: String

        /// "vo_P1_smoking.m4a".
        public func file(session: String, variant: String) -> String {
            fileName.replacingOccurrences(of: "{sessionId}", with: session).replacingOccurrences(of: "{variant}", with: variant)
        }

        public func transcript(session: String, variant: String) -> String {
            transcriptFileName.replacingOccurrences(of: "{sessionId}", with: session).replacingOccurrences(of: "{variant}", with: variant)
        }
    }

    public struct AudioVariants: Decodable, Sendable, Equatable {
        public let variants: [String]

        /// The recording to play: the NRT version for someone with an active NRT plan, else their main product's,
        /// else the shared one.
        public func pick(for variant: ProgramVariant, nrtActive: Bool) -> String {
            if nrtActive, variants.contains("nrt") { return "nrt" }
            if variants.contains(variant.rawValue) { return variant.rawValue }
            return "default"
        }
    }

    // MARK: Structure

    public struct Phase: Decodable, Sendable, Identifiable {
        public let id: String
        public let title: String
        public let subtitle: String
        public let sessionIds: [String]
    }

    public struct Session: Decodable, Sendable, Identifiable {
        public let id: String
        public let phaseId: String
        /// "Prep 3", "Day 10".
        public let label: String
        public let title: Varied<String>
        public let subtitle: Varied<String>
        public let durationMinutes: Int
        public let listenHint: Varied<String>?
        public let unlock: Unlock
        public let audio: AudioVariants
        public let beats: [Beat]
        public let mission: Mission?
        public let completionText: Varied<String>

        /// Beats played before the audio, then the rest, each in file order.
        public var beatsBeforeAudio: [Beat] { beats.filter { $0.position == .beforeAudio } }
        public var beatsAfterAudio: [Beat] { beats.filter { $0.position == .afterAudio } }
    }

    public struct Unlock: Decodable, Sendable, Equatable {
        public enum Rule: String, Decodable, Sendable {
            case first
            case nextDayAfterPrevious = "next_day_after_previous"
            case dayXero = "day_xero"
            case daysSinceQuit = "days_since_quit"
        }

        public let rule: Rule
        public let minDay: Int?
    }

    public struct Mission: Decodable, Sendable {
        public let text: Varied<String>
        public let logType: LogType?
        /// Shown as a short sheet the first time the person logs `logType` after the session (P3).
        public let followUp: [Beat]?

        public enum LogType: String, Decodable, Sendable {
            case use
            case morningBuffer = "morning_buffer"
            case mindfulUse = "mindful_use"
            case stressSigh = "stress_sigh"
            case surfPractice = "surf_practice"
            case cravingOutcome = "craving_outcome"
        }
    }

    public struct SOSTrack: Decodable, Sendable, Identifiable {
        public let id: String
        public let title: String
        public let subtitle: String
        public let durationSeconds: Int
        public let audio: AudioVariants
        /// "slip_debrief": the track ends by opening the slip debrief.
        public let endAction: String?
    }
}

private final class ProgramBundleToken {}

/// Which wording a person sees: their main product's.
public enum ProgramVariant: String, CaseIterable, Sendable {
    case smoking, vaping, pouches

    public init(_ product: Product) {
        switch product {
        case .cigarettes: self = .smoking
        case .vape: self = .vaping
        case .pouches: self = .pouches
        }
    }
}

/// A value that is the same for everyone, or differs by product: `{"default": …, "smoking": …, "vaping": …, "pouches": …}`.
public enum Varied<Value: Decodable & Sendable>: Decodable, Sendable {
    case same(Value)
    case byKey([String: Value])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Value.self) {
            self = .same(value)
        } else {
            self = .byKey(try container.decode([String: Value].self))
        }
    }

    /// The person's product's version, else the default. Nil only for broken content, which the tests catch.
    public func resolve(_ variant: ProgramVariant) -> Value? {
        switch self {
        case let .same(value): value
        case let .byKey(values): values[variant.rawValue] ?? values["default"]
        }
    }

    /// Every version in the file, for checking.
    var all: [Value] {
        switch self {
        case let .same(value): [value]
        case let .byKey(values): Array(values.values)
        }
    }
}

extension Varied: Equatable where Value: Equatable {}

// MARK: Beats

/// One activity in a session. Fields are shared across types; each type reads the ones it needs.
public struct Beat: Decodable, Sendable, Identifiable {
    public enum Kind: String, Decodable, Sendable, CaseIterable {
        case statReveal = "stat_reveal", quiz, choice, slider
        case sliderGroup = "slider_group", reflect
        case tapReveal = "tap_reveal"
        case planBuilder = "plan_builder", checklist, breathe, commit, scenario, note, info, share
        case nrtChoice = "nrt_choice"
        case nrtStepdown = "nrt_stepdown"
        case slipDebriefPractice = "slip_debrief_practice"
        case planCard = "plan_card"
    }

    public enum Position: String, Decodable, Sendable {
        case beforeAudio = "before_audio", afterAudio = "after_audio"
    }

    public enum Condition: String, Decodable, Sendable {
        case nrtActive = "nrt_active", nrtNotActive = "nrt_not_active"
    }

    public enum Length: String, Decodable, Sendable { case short, long }

    public struct Option: Decodable, Sendable, Equatable, Identifiable {
        public let id: String
        public let text: String
        /// Takes priority over the beat's feedback when this option is chosen.
        public let feedback: String?

        public init(id: String, text: String, feedback: String? = nil) {
            self.id = id
            self.text = text
            self.feedback = feedback
        }
    }

    public struct Card: Decodable, Sendable, Equatable {
        public let front: String
        public let back: String?
        /// Shows a saved answer instead of fixed text. The card is hidden while that answer is empty.
        public let backFrom: String?
    }

    public struct SliderItem: Decodable, Sendable, Equatable {
        public let label: String
        public let minLabel: String
        public let maxLabel: String
        public let saveAs: String
    }

    public let id: String
    public let type: Kind
    public let position: Position
    /// Shows Skip. Required beats: commit, and any quiz or choice not marked optional.
    public let optional: Bool
    public let showIf: Condition?

    public let prompt: Varied<String>?
    public let title: Varied<String>?
    public let text: Varied<String>?
    public let body: Varied<String>?
    public let label: Varied<String>?
    public let feedback: Varied<String>?
    public let footer: Varied<String>?
    public let placeholder: Varied<String>?
    public let minLabel: Varied<String>?
    public let maxLabel: Varied<String>?
    public let safetyText: Varied<String>?
    public let intro: Varied<String>?
    public let outro: Varied<String>?
    public let prefill: Varied<String>?
    public let lines: [Varied<String>]?
    public let options: Varied<[Option]>?
    /// slider_group's sliders (`items` in the file).
    public let sliders: [SliderItem]?
    /// checklist's items (`items` in the file).
    public let checklist: Varied<[String]>?
    public let cards: [Card]?

    public let saveAs: String?
    public let correctId: String?
    public let optionsFrom: String?
    public let prefillFrom: String?
    public let textFrom: String?
    public let highlightFrom: String?
    public let compareWith: String?
    public let compareLabels: [String]?
    public let carryOverFrom: String?
    public let quoteFrom: String?
    public let cardType: String?
    public let link: String?
    public let pattern: String?
    public let sets: String?
    public let fields: [String]?
    public let chips: [String]?
    public let guidePrompts: [String]?
    public let suggestions: [String]?

    public let multi: Bool
    public let allowOther: Bool
    public let skipIfEmpty: Bool
    public let editable: Bool
    public let pick: Int?
    public let maxEntries: Int?
    public let cycles: Int?
    /// Still decoded so older content loads; every hold now lasts `DX.Move.hold` (S27.20).
    public let holdSeconds: Int?
    public let length: Length?

    /// Commit, and a quiz or choice not marked optional, must be answered before the session can finish.
    public var isRequired: Bool {
        switch type {
        case .commit: true
        case .quiz, .choice: !optional
        default: false
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, type, position, optional, showIf, prompt, title, text, body, label, feedback, footer, placeholder
        case minLabel, maxLabel, safetyText, intro, outro, prefill, lines, options, items, cards
        case saveAs, correctId, optionsFrom, prefillFrom, textFrom, highlightFrom, compareWith, compareLabels
        case carryOverFrom, quoteFrom, cardType, link, pattern, sets, fields, chips, guidePrompts, suggestions
        case multi, allowOther, skipIfEmpty, editable, pick, maxEntries, cycles, holdSeconds, length
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        type = try c.decode(Kind.self, forKey: .type)
        position = try c.decodeIfPresent(Position.self, forKey: .position) ?? .afterAudio
        optional = try c.decodeIfPresent(Bool.self, forKey: .optional) ?? false
        showIf = try c.decodeIfPresent(Condition.self, forKey: .showIf)
        prompt = try c.decodeIfPresent(Varied<String>.self, forKey: .prompt)
        title = try c.decodeIfPresent(Varied<String>.self, forKey: .title)
        text = try c.decodeIfPresent(Varied<String>.self, forKey: .text)
        body = try c.decodeIfPresent(Varied<String>.self, forKey: .body)
        label = try c.decodeIfPresent(Varied<String>.self, forKey: .label)
        feedback = try c.decodeIfPresent(Varied<String>.self, forKey: .feedback)
        footer = try c.decodeIfPresent(Varied<String>.self, forKey: .footer)
        placeholder = try c.decodeIfPresent(Varied<String>.self, forKey: .placeholder)
        minLabel = try c.decodeIfPresent(Varied<String>.self, forKey: .minLabel)
        maxLabel = try c.decodeIfPresent(Varied<String>.self, forKey: .maxLabel)
        safetyText = try c.decodeIfPresent(Varied<String>.self, forKey: .safetyText)
        intro = try c.decodeIfPresent(Varied<String>.self, forKey: .intro)
        outro = try c.decodeIfPresent(Varied<String>.self, forKey: .outro)
        prefill = try c.decodeIfPresent(Varied<String>.self, forKey: .prefill)
        lines = try c.decodeIfPresent([Varied<String>].self, forKey: .lines)
        options = try c.decodeIfPresent(Varied<[Option]>.self, forKey: .options)
        // `items` is sliders for slider_group and plain lines for checklist.
        if type == .sliderGroup {
            sliders = try c.decodeIfPresent([SliderItem].self, forKey: .items)
            checklist = nil
        } else {
            sliders = nil
            checklist = try c.decodeIfPresent(Varied<[String]>.self, forKey: .items)
        }
        cards = try c.decodeIfPresent([Card].self, forKey: .cards)
        saveAs = try c.decodeIfPresent(String.self, forKey: .saveAs)
        correctId = try c.decodeIfPresent(String.self, forKey: .correctId)
        optionsFrom = try c.decodeIfPresent(String.self, forKey: .optionsFrom)
        prefillFrom = try c.decodeIfPresent(String.self, forKey: .prefillFrom)
        textFrom = try c.decodeIfPresent(String.self, forKey: .textFrom)
        highlightFrom = try c.decodeIfPresent(String.self, forKey: .highlightFrom)
        compareWith = try c.decodeIfPresent(String.self, forKey: .compareWith)
        compareLabels = try c.decodeIfPresent([String].self, forKey: .compareLabels)
        carryOverFrom = try c.decodeIfPresent(String.self, forKey: .carryOverFrom)
        quoteFrom = try c.decodeIfPresent(String.self, forKey: .quoteFrom)
        cardType = try c.decodeIfPresent(String.self, forKey: .cardType)
        link = try c.decodeIfPresent(String.self, forKey: .link)
        pattern = try c.decodeIfPresent(String.self, forKey: .pattern)
        sets = try c.decodeIfPresent(String.self, forKey: .sets)
        fields = try c.decodeIfPresent([String].self, forKey: .fields)
        chips = try c.decodeIfPresent([String].self, forKey: .chips)
        guidePrompts = try c.decodeIfPresent([String].self, forKey: .guidePrompts)
        suggestions = try c.decodeIfPresent([String].self, forKey: .suggestions)
        multi = try c.decodeIfPresent(Bool.self, forKey: .multi) ?? false
        allowOther = try c.decodeIfPresent(Bool.self, forKey: .allowOther) ?? false
        skipIfEmpty = try c.decodeIfPresent(Bool.self, forKey: .skipIfEmpty) ?? false
        editable = try c.decodeIfPresent(Bool.self, forKey: .editable) ?? false
        pick = try c.decodeIfPresent(Int.self, forKey: .pick)
        maxEntries = try c.decodeIfPresent(Int.self, forKey: .maxEntries)
        cycles = try c.decodeIfPresent(Int.self, forKey: .cycles)
        holdSeconds = try c.decodeIfPresent(Int.self, forKey: .holdSeconds)
        length = try c.decodeIfPresent(Length.self, forKey: .length)
    }

    /// Every on-screen string field, with its name, for checking.
    var textFields: [(name: String, value: Varied<String>)] {
        let named: [(String, Varied<String>?)] = [
            ("prompt", prompt), ("title", title), ("text", text), ("body", body), ("label", label), ("feedback", feedback),
            ("footer", footer), ("placeholder", placeholder), ("minLabel", minLabel), ("maxLabel", maxLabel),
            ("safetyText", safetyText), ("intro", intro), ("outro", outro), ("prefill", prefill),
        ]
        return named.compactMap { name, value in value.map { (name, $0) } }
            + (lines ?? []).enumerated().map { ("lines[\($0.offset)]", $0.element) }
    }

    /// Saved answers this beat reads.
    var reads: [String] {
        [optionsFrom, prefillFrom, textFrom, highlightFrom, compareWith, carryOverFrom, quoteFrom].compactMap { $0 }
            + (cards ?? []).compactMap(\.backFrom) + (fields ?? [])
    }

    /// Saved answers this beat writes.
    var writes: [String] {
        [saveAs].compactMap { $0 } + (sliders ?? []).map(\.saveAs)
    }
}

// MARK: Placeholders

/// Fills `{days_free}` and the like in on-screen text. Narration never carries them.
public struct ProgramPlaceholders: Sendable {
    public static let known: Set<String> = [
        "unit_singular", "unit_plural", "daily_units", "yearly_units", "currency", "yearly_cost", "quit_date",
        "primary_reason", "days_free", "money_kept", "cravings_ridden",
    ]

    public var values: [String: String]
    /// Spans swapped whole before placeholders fill, so a count agrees with its noun:
    /// `"{days_free} days"` becomes "1 day" rather than "1 days".
    public var phrases: [String: String]

    public init(_ values: [String: String] = [:], phrases: [String: String] = [:]) {
        self.values = values
        self.phrases = phrases
    }

    private func replacingPhrases(_ text: String) -> String {
        phrases.reduce(text) { $0.replacingOccurrences(of: $1.key, with: $1.value) }
    }

    static func names(in text: String) -> [String] {
        var names: [String] = []
        var rest = text[...]
        while let open = rest.firstIndex(of: "{"), let close = rest[open...].firstIndex(of: "}") {
            names.append(String(rest[rest.index(after: open)..<close]))
            rest = rest[rest.index(after: close)...]
        }
        return names
    }

    /// The text with every placeholder filled, or nil if any can't be (a stat line is then dropped).
    public func fill(_ text: String) -> String? {
        var out = replacingPhrases(text)
        for name in Self.names(in: out) {
            guard let value = values[name] else { return nil }
            out = out.replacingOccurrences(of: "{\(name)}", with: value)
        }
        return out
    }

    /// The text with what can be filled filled and the rest taken out, so no raw braces ever show.
    public func fillDropping(_ text: String) -> String {
        var out = replacingPhrases(text)
        for name in Self.names(in: out) {
            out = out.replacingOccurrences(of: "{\(name)}", with: values[name] ?? "")
        }
        while out.contains("  ") { out = out.replacingOccurrences(of: "  ", with: " ") }
        return out.replacingOccurrences(of: " .", with: ".").replacingOccurrences(of: " ,", with: ",")
            .trimmingCharacters(in: .whitespaces)
    }
}

// MARK: Checking

extension ProgramContent {
    /// Keys onboarding saves before the program starts.
    public static let onboardingKeys: Set<String> = ["reasons", "primary_reason"]
    static let audioVariants: Set<String> = ["default", "smoking", "vaping", "pouches", "nrt"]

    /// Everything wrong with the content, empty when it's sound (handoff 2.5). `patterns` are the breathing patterns the orb knows.
    public func problems(patterns: Set<String>) -> [String] {
        var problems: [String] = []

        // Phases and sessions line up, in order, each session in one phase.
        let phaseOrder = phases.flatMap(\.sessionIds)
        if phaseOrder != sessions.map(\.id) { problems.append("phase session lists don't match the session order") }
        if Set(phaseOrder).count != phaseOrder.count { problems.append("a session is listed in more than one phase") }
        for phase in phases {
            for id in phase.sessionIds where session(id)?.phaseId != phase.id {
                problems.append("\(id) is listed in \(phase.id) but isn't a session of it")
            }
        }

        // Beat IDs are unique.
        let allBeats = sessions.flatMap { $0.beats + ($0.mission?.followUp ?? []) }
        var seen = Set<String>()
        for beat in allBeats where !seen.insert(beat.id).inserted { problems.append("beat \(beat.id) appears twice") }

        func check<T>(_ value: Varied<T>?, _ place: String) {
            guard let value else { return }
            for variant in ProgramVariant.allCases where value.resolve(variant) == nil {
                problems.append("\(place) has nothing for \(variant.rawValue)")
            }
        }
        func checkPlaceholders(_ value: Varied<String>?, _ place: String) {
            for text in value?.all ?? [] {
                for name in ProgramPlaceholders.names(in: text) where !ProgramPlaceholders.known.contains(name) {
                    problems.append("\(place) uses unknown placeholder {\(name)}")
                }
            }
        }
        func checkText(_ value: Varied<String>?, _ place: String) {
            check(value, place)
            for text in value?.all ?? [] {
                for name in ProgramPlaceholders.names(in: text) where !ProgramPlaceholders.known.contains(name) {
                    problems.append("\(place) uses unknown placeholder {\(name)}")
                }
            }
        }

        var saved = Self.onboardingKeys
        for session in sessions {
            checkText(session.title, "\(session.id).title")
            checkText(session.subtitle, "\(session.id).subtitle")
            checkText(session.listenHint, "\(session.id).listenHint")
            checkText(session.completionText, "\(session.id).completionText")
            checkText(session.mission?.text, "\(session.id).mission")
            for variant in session.audio.variants where !Self.audioVariants.contains(variant) {
                problems.append("\(session.id) has unknown audio variant \(variant)")
            }
            if !session.audio.variants.contains("default"),
               !ProgramVariant.allCases.allSatisfy({ session.audio.variants.contains($0.rawValue) }) {
                problems.append("\(session.id) has no audio for some products and no default")
            }
            if session.unlock.rule == .daysSinceQuit, session.unlock.minDay == nil {
                problems.append("\(session.id) unlocks by days since quit but has no minDay")
            }

            for beat in session.beats + (session.mission?.followUp ?? []) {
                let place = "\(session.id)/\(beat.id)"
                for field in beat.textFields {
                    // A footer may be for some products only (P7's battery note is for vaping); missing means none.
                    if field.name == "footer" {
                        checkPlaceholders(field.value, "\(place).footer")
                    } else {
                        checkText(field.value, "\(place).\(field.name)")
                    }
                }
                check(beat.options, "\(place).options")
                check(beat.checklist, "\(place).items")
                if beat.type == .quiz {
                    for variant in ProgramVariant.allCases {
                        let ids = beat.options?.resolve(variant)?.map(\.id) ?? []
                        if beat.correctId.map({ !ids.contains($0) }) ?? true {
                            problems.append("\(place) quiz answer isn't one of its options")
                        }
                    }
                }
                if beat.type == .breathe, beat.pattern.map({ !patterns.contains($0) }) ?? true {
                    problems.append("\(place) breathes a pattern the orb doesn't have")
                }
                for key in beat.reads where !saved.contains(key) {
                    problems.append("\(place) reads \(key) before anything saves it")
                }
                saved.formUnion(beat.writes)
            }
        }
        return problems
    }
}
