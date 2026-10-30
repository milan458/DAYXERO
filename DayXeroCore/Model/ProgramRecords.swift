import Foundation
import SwiftData

/// Where someone is in one program v2 session (handoff section 7). Created when the session is first opened.
@Model
public final class SessionRecord {
    public var sessionId: String
    public var startedAt: Date
    public var completedAt: Date?
    /// The step to resume at: intro, before-audio beats, audio, beats, mission, completion, counted from 0.
    public var currentStep: Int
    /// Seconds into the audio, saved every few seconds and on pause.
    public var audioPosition: Double
    public var audioVariant: String?
    /// The content version the session was started under. A changed version restarts an unfinished session after its audio.
    public var contentVersion: String

    public init(sessionId: String, startedAt: Date = .now, contentVersion: String) {
        self.sessionId = sessionId
        self.startedAt = startedAt
        self.currentStep = 0
        self.audioPosition = 0
        self.contentVersion = contentVersion
    }
}

/// One finished or skipped activity. Holds the value for activities that save nothing else (quiz picks, scenarios).
@Model
public final class BeatRecord {
    public var sessionId: String
    public var beatId: String
    public var completedAt: Date?
    public var skipped: Bool
    public var valueData: Data?

    public init(sessionId: String, beatId: String, completedAt: Date? = .now, skipped: Bool = false, value: ProgramAnswerValue? = nil) {
        self.sessionId = sessionId
        self.beatId = beatId
        self.completedAt = completedAt
        self.skipped = skipped
        self.valueData = value.flatMap { try? JSONEncoder().encode($0) }
    }

    public var value: ProgramAnswerValue? {
        valueData.flatMap { try? JSONDecoder().decode(ProgramAnswerValue.self, from: $0) }
    }
}

/// A saved answer, by key (`no_line`, `break_menu`…). Stays on the phone: in the data export, never in analytics.
@Model
public final class ProgramAnswer {
    @Attribute(.unique) public var key: String
    public var valueData: Data
    public var sessionId: String
    public var updatedAt: Date

    public init(key: String, value: ProgramAnswerValue, sessionId: String, updatedAt: Date = .now) {
        self.key = key
        self.valueData = (try? JSONEncoder().encode(value)) ?? Data()
        self.sessionId = sessionId
        self.updatedAt = updatedAt
    }

    public var value: ProgramAnswerValue? {
        get { try? JSONDecoder().decode(ProgramAnswerValue.self, from: valueData) }
        set { valueData = newValue.flatMap { try? JSONEncoder().encode($0) } ?? Data() }
    }
}

/// When a session's mission was shown, and when its follow-up was answered.
@Model
public final class MissionRecord {
    public var sessionId: String
    public var shownAt: Date
    public var followUpCompletedAt: Date?

    public init(sessionId: String, shownAt: Date = .now) {
        self.sessionId = sessionId
        self.shownAt = shownAt
    }
}

/// What an activity saves.
public enum ProgramAnswerValue: Codable, Equatable, Sendable {
    case text(String)
    case list([String])
    case number(Int)
    case plans([PlanLine])
    case date(Date)

    public struct PlanLine: Codable, Equatable, Sendable {
        public var situation: String
        public var action: String

        public init(situation: String, action: String) {
            self.situation = situation
            self.action = action
        }
    }

    /// As lines, for notes, cards and the plan card. A list shows one per line; a plan as "If …, then I will …".
    public var lines: [String] {
        switch self {
        case let .text(text): text.isEmpty ? [] : [text]
        case let .list(items): items.filter { !$0.isEmpty }
        case let .number(n): ["\(n)"]
        case let .plans(plans): plans.map { "If \($0.situation), then I will \($0.action.prefix(1).lowercased() + $0.action.dropFirst())." }
        case .date: []
        }
    }

    public var isEmpty: Bool { lines.isEmpty }
}
