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
    /// The session was closed with ✕ before choosing an outcome.
    case closed
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

    /// "Then I'll…" ideas for the slip talk-through (S8.2), drafted by Claude and approved by Milan.
    public var nextTimeSuggestions: [LocalizedStringResource] {
        switch self {
        case .morning: ["drink water before anything else", "shower first", "step outside for fresh air", "open Craving SOS"]
        case .coffee: ["take a short walk", "switch to tea for a week", "have it somewhere new", "open Craving SOS"]
        case .meals: ["get up from the table straight away", "brush my teeth", "chew sugar-free gum", "take a short walk"]
        case .stress: ["open Craving SOS", "breathe slowly for one minute", "step away for five minutes", "text a friend"]
        case .alcohol: ["alternate with water", "stand away from smokers", "leave a little earlier", "keep gum in my pocket"]
        case .boredom: ["do something with my hands", "go for a walk", "play a quick game", "open Craving SOS"]
        case .social: ["tell a friend I'm quitting", "stand with non-smokers", "have gum ready", "step away and breathe"]
        case .driving: ["keep mints in the car", "put on a podcast", "clear the car of vapes and lighters", "open the window and breathe"]
        case .work: ["take my break somewhere new", "walk around the block", "take a break with a non-smoker", "drink water"]
        case .phone: ["put the phone down for five minutes", "move to another room", "chew sugar-free gum", "open Craving SOS"]
        case .other: ["open Craving SOS", "take a short walk", "drink water", "text a friend"]
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

    /// Morning 5–11, midday 11–14, afternoon 14–17, evening 17–22, late night 22–5.
    public init(hour: Int) {
        switch hour {
        case 5..<11: self = .morning
        case 11..<14: self = .midday
        case 14..<17: self = .afternoon
        case 17..<22: self = .evening
        default: self = .lateNight
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

    public var title: LocalizedStringResource {
        switch self {
        case .low: "Low"
        case .meh: "Meh"
        case .okay: "Okay"
        case .good: "Good"
        case .great: "Great"
        }
    }
}

/// Roughly how much was used in a slip (S8.2).
public enum SlipAmount: String, Codable, CaseIterable, Sendable {
    case aLittle, one, more
}

/// Where a craving happened (S7.2, optional).
public enum Place: String, Codable, CaseIterable, Sendable {
    case home, work, out, driving

    public var title: LocalizedStringResource {
        switch self {
        case .home: "Home"
        case .work: "Work"
        case .out: "Out"
        case .driving: "Driving"
        }
    }
}

public enum NRTType: String, Codable, CaseIterable, Sendable {
    case patch, gum, lozenge, inhaler

    public var title: LocalizedStringResource {
        switch self {
        case .patch: "Patch"
        case .gum: "Gum"
        case .lozenge: "Lozenge"
        case .inhaler: "Inhaler"
        }
    }
}

public enum NRTInterest: String, Codable, Sendable {
    case using, wantIt, notInterested
}
