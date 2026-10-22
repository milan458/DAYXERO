import Foundation

/// A nicotine product. Each has its own program variant and its own counter unit.
public enum Product: String, Codable, CaseIterable, Sendable {
    case cigarettes, vape, pouches

    /// What the home counter counts: cigarettes, puffs or pouches.
    public var unit: LocalizedStringResource {
        switch self {
        case .cigarettes: "cigarettes"
        case .vape: "puffs"
        case .pouches: "pouches"
        }
    }
}

public enum ProgramPhase: String, Codable, CaseIterable, Sendable {
    /// Before Quit Day. Users may still use nicotine.
    case prep
    /// The 7-day program starting on Quit Day.
    case quit
    /// Weeks 2–5.
    case maintenance
}

public enum LogKind: String, Codable, CaseIterable, Sendable {
    case craving
    case slip
    /// A logged use during prep (tracking, not a slip).
    case use
}

public enum CravingOutcome: String, Codable, Sendable {
    case passed, slipped, pingedFriend
}

public enum Trigger: String, Codable, CaseIterable, Sendable {
    case morning, coffee, meals, alcohol, stress, boredom, social, driving, work, phone, afterSex, other
}

public enum Mood: Int, Codable, CaseIterable, Sendable {
    case low = 1, meh, okay, good, great
}

public enum NRTType: String, Codable, CaseIterable, Sendable {
    case patch, gum, lozenge, inhaler
}

public enum NRTInterest: String, Codable, Sendable {
    case using, wantIt, notInterested
}
