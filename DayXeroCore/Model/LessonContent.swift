import Foundation

/// One program day's lesson, as data (S5.1). Porting the Flutter content means writing these, not changing screens.
///
/// JSON shape (one file per product variant, `program-<product>.json`):
/// ```json
/// { "lessons": [ { "day": "quit-3", "title": "…", "minutes": 7, "placeholder": false,
///     "steps": [ { "type": "reading", "lead": "…", "body": "…", "notes": { "cigarettes": "…" } },
///                { "type": "audio", "title": "…", "subtitle": "…", "file": "urge-surfing.m4a", "seconds": 180, "transcript": "…" },
///                { "type": "ifThen", "title": "…", "subtitle": "…", "actions": ["…", "…"] } ] } ] }
/// ```
public struct LessonContent: Codable, Equatable, Sendable {
    public var day: ProgramDayID
    public var title: String
    public var minutes: Int
    /// True for stand-in content; the UI tags it so it can't be mistaken for the real thing.
    public var placeholder: Bool
    public var steps: [LessonStep]

    public init(day: ProgramDayID, title: String, minutes: Int, placeholder: Bool, steps: [LessonStep]) {
        self.day = day
        self.title = title
        self.minutes = minutes
        self.placeholder = placeholder
        self.steps = steps
    }

    enum CodingKeys: String, CodingKey { case day, title, minutes, placeholder, steps }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let raw = try c.decode(String.self, forKey: .day)
        guard let day = ProgramDayID(description: raw) else {
            throw DecodingError.dataCorruptedError(forKey: .day, in: c, debugDescription: "Bad day id \(raw)")
        }
        self.day = day
        title = try c.decode(String.self, forKey: .title)
        minutes = try c.decode(Int.self, forKey: .minutes)
        placeholder = try c.decodeIfPresent(Bool.self, forKey: .placeholder) ?? false
        steps = try c.decode([LessonStep].self, forKey: .steps)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(day.description, forKey: .day)
        try c.encode(title, forKey: .title)
        try c.encode(minutes, forKey: .minutes)
        try c.encode(placeholder, forKey: .placeholder)
        try c.encode(steps, forKey: .steps)
    }
}

public enum LessonStep: Codable, Equatable, Sendable {
    /// Text to read. `notes` holds short extras for dual users, keyed by product raw value.
    case reading(lead: String, body: String, notes: [String: String])
    /// Guided audio. `file` is a bundled resource name; nil while there's no recording yet.
    case audio(title: String, subtitle: String, file: String?, seconds: Int, transcript: String)
    /// "If <situation>, then I'll <action>": the situation comes from the person's own triggers.
    case ifThen(title: String, subtitle: String, actions: [String])
    /// Weekly check-in parts (S5.6).
    case weekRating
    case challengeReview(challenge: String)
    case nextChallenge(options: [String])

    private enum Kind: String, Codable { case reading, audio, ifThen, weekRating, challengeReview, nextChallenge }
    private enum Keys: String, CodingKey {
        case type, lead, body, notes, title, subtitle, file, seconds, transcript, actions, challenge, options
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Keys.self)
        switch try c.decode(Kind.self, forKey: .type) {
        case .reading:
            self = .reading(lead: try c.decode(String.self, forKey: .lead), body: try c.decode(String.self, forKey: .body),
                            notes: try c.decodeIfPresent([String: String].self, forKey: .notes) ?? [:])
        case .audio:
            self = .audio(title: try c.decode(String.self, forKey: .title), subtitle: try c.decodeIfPresent(String.self, forKey: .subtitle) ?? "",
                          file: try c.decodeIfPresent(String.self, forKey: .file), seconds: try c.decode(Int.self, forKey: .seconds),
                          transcript: try c.decode(String.self, forKey: .transcript))
        case .ifThen:
            self = .ifThen(title: try c.decode(String.self, forKey: .title), subtitle: try c.decodeIfPresent(String.self, forKey: .subtitle) ?? "",
                           actions: try c.decode([String].self, forKey: .actions))
        case .weekRating:
            self = .weekRating
        case .challengeReview:
            self = .challengeReview(challenge: try c.decode(String.self, forKey: .challenge))
        case .nextChallenge:
            self = .nextChallenge(options: try c.decode([String].self, forKey: .options))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: Keys.self)
        switch self {
        case let .reading(lead, body, notes):
            try c.encode(Kind.reading, forKey: .type); try c.encode(lead, forKey: .lead); try c.encode(body, forKey: .body)
            try c.encode(notes, forKey: .notes)
        case let .audio(title, subtitle, file, seconds, transcript):
            try c.encode(Kind.audio, forKey: .type); try c.encode(title, forKey: .title); try c.encode(subtitle, forKey: .subtitle)
            try c.encodeIfPresent(file, forKey: .file); try c.encode(seconds, forKey: .seconds); try c.encode(transcript, forKey: .transcript)
        case let .ifThen(title, subtitle, actions):
            try c.encode(Kind.ifThen, forKey: .type); try c.encode(title, forKey: .title); try c.encode(subtitle, forKey: .subtitle)
            try c.encode(actions, forKey: .actions)
        case .weekRating:
            try c.encode(Kind.weekRating, forKey: .type)
        case let .challengeReview(challenge):
            try c.encode(Kind.challengeReview, forKey: .type); try c.encode(challenge, forKey: .challenge)
        case let .nextChallenge(options):
            try c.encode(Kind.nextChallenge, forKey: .type); try c.encode(options, forKey: .options)
        }
    }
}

public struct LessonFile: Codable, Sendable {
    public var lessons: [LessonContent]
}
