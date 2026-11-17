import Foundation

/// The three moments DayXero asks for an App Store rating (17 Nov 2026).
public enum ReviewMoment: String, Sendable, CaseIterable {
    /// Prep 1 finished.
    case prepOne = "prep_1"
    /// A craving ridden out in Craving SOS, on the third day with the app or later.
    case sosPassed = "sos_passed"
    /// Day Xero finished.
    case dayXero = "day_xero"
}

/// When to ask for a rating. Each moment asks once, and never two on the same day. Apple decides whether the sheet
/// really shows (three times a year at most), so this only picks the moments.
public enum ReviewAsk {
    /// Craving SOS asks from this day with the app (the day they joined is day 1).
    public static let sosFromDay = 3

    /// The moment a finished program session stands for, if any.
    public static func moment(forSession id: String) -> ReviewMoment? {
        switch id {
        case "P1": .prepOne
        case "DX": .dayXero
        default: nil
        }
    }

    public static func shouldAsk(_ moment: ReviewMoment, asked: Set<ReviewMoment>, lastAsked: Date?, joined: Date, now: Date,
                                 calendar: Calendar = .current) -> Bool {
        guard !asked.contains(moment) else { return false }
        if let lastAsked, calendar.isDate(lastAsked, inSameDayAs: now) { return false }
        if moment == .sosPassed {
            let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: joined), to: calendar.startOfDay(for: now)).day ?? 0
            return days + 1 >= sosFromDay
        }
        return true
    }
}
