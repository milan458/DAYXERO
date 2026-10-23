import Foundation

/// Timing for a Craving SOS session (S6.1, S6.2): the breathing rhythm, the countdown and what the screen shows when.
///
/// Breathing starts at 6 breaths a minute (4 s in, 6 s out) and slows evenly to 5 a minute (about 4.8 s in,
/// 7.2 s out) by the end of the first three minutes, then stays there.
public enum CravingWave {
    /// One round of the urge-surfing timer. "Another three minutes" starts a new round.
    public static let roundLength: TimeInterval = CravingSession.length
    /// How long each of the person's reasons stays on screen before the next one.
    public static let reasonInterval: TimeInterval = 40
    /// Share of each breath spent breathing in.
    static let inhaleShare = 0.4

    public enum Phase: Sendable, Equatable {
        case breatheIn, breatheOut
    }

    public struct Breath: Sendable, Equatable {
        public let phase: Phase
        /// 0…1 through the current phase.
        public let progress: Double
        /// 0…1 size of the breathing circle: grows on the in-breath, shrinks on the out-breath.
        public let scale: Double
        /// Counts breaths from the start, so a change means a new breath began.
        public let index: Int
        public let inhaleSeconds: Double
        public let exhaleSeconds: Double
    }

    /// Length of a whole breath that starts `elapsed` seconds into the session.
    public static func breathLength(at elapsed: TimeInterval) -> TimeInterval {
        10 + 2 * min(max(elapsed / roundLength, 0), 1)
    }

    public static func breath(at elapsed: TimeInterval) -> Breath {
        let t = max(elapsed, 0)
        var start = 0.0
        var index = 0
        while true {
            let length = breathLength(at: start)
            if t < start + length {
                let inhale = length * inhaleShare
                let local = t - start
                if local < inhale {
                    let p = local / inhale
                    return Breath(phase: .breatheIn, progress: p, scale: ease(p), index: index,
                                  inhaleSeconds: inhale, exhaleSeconds: length - inhale)
                }
                let p = (local - inhale) / (length - inhale)
                return Breath(phase: .breatheOut, progress: p, scale: 1 - ease(p), index: index,
                              inhaleSeconds: inhale, exhaleSeconds: length - inhale)
            }
            start += length
            index += 1
        }
    }

    /// Seconds left in the current round.
    public static func remaining(roundElapsed: TimeInterval) -> TimeInterval {
        max(roundLength - roundElapsed, 0)
    }

    /// 0…1 through the current round.
    public static func fraction(roundElapsed: TimeInterval) -> Double {
        min(max(roundElapsed / roundLength, 0), 1)
    }

    /// Halfway through a round the wording moves on to "It's past its peak".
    public static func isPastPeak(roundElapsed: TimeInterval) -> Bool {
        roundElapsed >= roundLength / 2
    }

    /// Which of `count` reasons to show, `elapsed` seconds into the session.
    public static func reasonIndex(elapsed: TimeInterval, count: Int) -> Int? {
        guard count > 0 else { return nil }
        return Int(max(elapsed, 0) / reasonInterval) % count
    }

    private static func ease(_ x: Double) -> Double {
        (1 - cos(.pi * min(max(x, 0), 1))) / 2
    }
}

/// Cravings ridden out, for the "That's 4 this week" line.
public enum CravingStats {
    /// Cravings with the outcome "passed" in the calendar week containing `now`.
    public static func passedThisWeek(_ entries: [LogEntry], now: Date, calendar: Calendar = .current) -> Int {
        guard let week = calendar.dateInterval(of: .weekOfYear, for: now) else { return 0 }
        return entries.filter { $0.kind == .craving && $0.outcome == .passed && week.contains($0.timestamp) }.count
    }
}
