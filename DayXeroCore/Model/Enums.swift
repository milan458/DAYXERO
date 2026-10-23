import Foundation

/// A nicotine product. Each has its own program variant and its own counter unit.
public enum Product: String, Codable, CaseIterable, Sendable {
    case cigarettes, vape, pouches

    public var title: LocalizedStringResource {
        switch self {
        case .cigarettes: "Cigarettes"
        case .vape: "Vape"
        case .pouches: "Nicotine pouches"
        }
    }

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

/// Situations that bring on cravings, in the order onboarding shows them.
public enum Trigger: String, Codable, CaseIterable, Sendable {
    case morning, coffee, meals, stress, alcohol, boredom, social, driving, work, phone, other

    public var title: LocalizedStringResource {
        switch self {
        case .morning: "Waking up"
        case .coffee: "Coffee"
        case .meals: "After meals"
        case .stress: "Stress"
        case .alcohol: "Drinking"
        case .boredom: "Boredom"
        case .social: "With friends"
        case .driving: "Driving"
        case .work: "Work breaks"
        case .phone: "On my phone"
        case .other: "Something else"
        }
    }

    /// Completes "If it's …" in an if-then plan.
    public var situation: LocalizedStringResource {
        switch self {
        case .morning: "first thing in the morning"
        case .coffee: "after coffee"
        case .meals: "after a meal"
        case .stress: "a stressful moment"
        case .alcohol: "a night of drinking"
        case .boredom: "a bored moment"
        case .social: "time with friends"
        case .driving: "a drive"
        case .work: "a work break"
        case .phone: "scrolling time"
        case .other: "a strong craving"
        }
    }
}

public enum TimeOfDay: String, Codable, CaseIterable, Sendable {
    case morning, midday, afternoon, evening, lateNight

    public var title: LocalizedStringResource {
        switch self {
        case .morning: "Morning"
        case .midday: "Midday"
        case .afternoon: "Afternoon"
        case .evening: "Evening"
        case .lateNight: "Late night"
        }
    }
}

public enum PastAttempts: String, Codable, CaseIterable, Sendable {
    case notYet, onceOrTwice, many

    public var title: LocalizedStringResource {
        switch self {
        case .notYet: "Not yet"
        case .onceOrTwice: "Once or twice"
        case .many: "Lots of times"
        }
    }
}

/// What got in the way of a past attempt.
public enum Obstacle: String, Codable, CaseIterable, Sendable {
    case cravings, stress, social, irritability, weight, sleep, other

    public var title: LocalizedStringResource {
        switch self {
        case .cravings: "Cravings"
        case .stress: "Stress"
        case .social: "Social situations"
        case .irritability: "Irritability"
        case .weight: "Weight"
        case .sleep: "Sleep"
        case .other: "Other"
        }
    }
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
