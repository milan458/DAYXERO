import Foundation

/// How the crew and the sky grow with days clear (tokens.json → characters.props.stage, sky).
public enum CrewGrowth {
    /// Character stage 1–4: under 7 days 1, under 14 days 2, under 28 days 3, then 4.
    public static func stage(daysClear: Int) -> Int {
        switch daysClear {
        case ..<7: 1
        case ..<14: 2
        case ..<28: 3
        default: 4
        }
    }

    /// Sky clarity during the prep week, before Quit Day.
    public static let prepClarity = 20

    /// Sky clarity 0–100 after Quit Day: min(100, round(20 + 2.8 × days clear)).
    public static func clarity(daysClear: Int) -> Int {
        guard daysClear > 0 else { return prepClarity }
        return min(100, Int((20 + 2.8 * Double(daysClear)).rounded()))
    }
}

/// The five moods every crew member has.
public enum CrewMood: String, CaseIterable, Sendable {
    /// Default, eyes open.
    case hello
    /// Eyes closed, small smile.
    case calm
    /// Eyes closed, slow 10 s breath.
    case breathe
    /// Celebrate only: Passed, milestones, finale.
    case cheer
    /// Evenings and wind-down.
    case sleepy
}
