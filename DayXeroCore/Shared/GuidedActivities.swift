import ActivityKit
import Foundation

/// A breathing session on the Lock Screen and in the Dynamic Island (S12.5), started by the Breathe control without
/// opening the app. Live Activities can't animate, so it shows the pattern and a self-updating countdown.
public struct BreathingActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable, Sendable {
        public var endsAt: Date
        public var done: Bool

        public init(endsAt: Date, done: Bool = false) {
            self.endsAt = endsAt
            self.done = done
        }
    }

    public var patternID: String
    public var patternName: String
    /// "in 4 · hold 4 · out 4 · hold 4"
    public var counts: String
    public var cycles: Int
    public var startedAt: Date

    public init(patternID: String, patternName: String, counts: String, cycles: Int, startedAt: Date) {
        self.patternID = patternID
        self.patternName = patternName
        self.counts = counts
        self.cycles = cycles
        self.startedAt = startedAt
    }
}

/// Guarding a likely craving window (S14.7): breathe, a glass of water, or "I'm good".
public struct GuardActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable, Sendable {
        public var endsAt: Date
        public var passed: Bool

        public init(endsAt: Date, passed: Bool = false) {
            self.endsAt = endsAt
            self.passed = passed
        }
    }

    public var windowStart: Date
    /// e.g. "After meals"; empty when there's no usual trigger.
    public var triggerLabel: String
    public var riddenOut: Int

    public init(windowStart: Date, triggerLabel: String, riddenOut: Int) {
        self.windowStart = windowStart
        self.triggerLabel = triggerLabel
        self.riddenOut = riddenOut
    }
}
