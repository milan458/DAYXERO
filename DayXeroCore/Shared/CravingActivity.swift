import ActivityKit
import Foundation

/// Live Activity for a craving SOS session (Section 6). Shared by the app and the widget extension.
public struct CravingActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable, Sendable {
        public var endsAt: Date
        public var passed: Bool

        public init(endsAt: Date, passed: Bool = false) {
            self.endsAt = endsAt
            self.passed = passed
        }
    }

    public var startedAt: Date

    public init(startedAt: Date) {
        self.startedAt = startedAt
    }
}

/// Standard urge-surfing session length.
public enum CravingSession {
    public static let length: TimeInterval = 180
}
