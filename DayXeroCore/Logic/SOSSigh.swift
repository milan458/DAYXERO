import Foundation

/// Jelli's opening in Craving SOS (CHAR-01, 2 Nov 2026): three physiological sighs before anything else. A long
/// breath in through the nose, a short second sip on top, a long breath out through the mouth, a beat of rest:
/// 2 · 1 · 6 · 1 seconds from `breathing_orb_data.json`'s "sigh" pattern, three times, about 30 seconds. The
/// picture, the voice, the subtitle and the haptics all follow these steps.
public enum SOSSigh {
    public static let patternId = "sigh"
    public static let cycles = 3

    public struct Step: Sendable, Equatable {
        public let phase: BreathPhase
        public let seconds: Int
        /// 1...cycles.
        public let cycle: Int
    }

    /// Every step, in order. Phases the pattern gives no seconds are skipped.
    public static func steps(_ pattern: OrbData.Pattern, cycles: Int = cycles) -> [Step] {
        (1...max(cycles, 1)).flatMap { cycle in
            BreathPhase.allCases.compactMap { phase in
                let seconds = pattern.seconds(phase)
                return seconds > 0 ? Step(phase: phase, seconds: seconds, cycle: cycle) : nil
            }
        }
    }

    public static func totalSeconds(_ pattern: OrbData.Pattern, cycles: Int = cycles) -> Int {
        steps(pattern, cycles: cycles).reduce(0) { $0 + $1.seconds }
    }

    /// The one subtitle line for a phase, also what the voice says. Rest keeps the out-breath's line on screen.
    public static func cue(_ phase: BreathPhase) -> String {
        switch phase {
        case .inhale: String(localized: "In through your nose…")
        case .topUp: String(localized: "…and a little more")
        case .exhale, .rest: String(localized: "Slowly out through your mouth")
        case .hold: String(localized: "Hold it gently")
        }
    }

    /// Whether a phase is spoken. Rest is silent, so the line isn't said twice.
    public static func isSpoken(_ phase: BreathPhase) -> Bool { phase != .rest }

    /// How big Jelli is at the end of a phase: full on the breath in, a little more on the sip, small on the way out.
    public static func scale(after phase: BreathPhase) -> Double {
        switch phase {
        case .inhale: 1.08
        case .topUp, .hold: 1.15
        case .exhale, .rest: 0.88
        }
    }
}
