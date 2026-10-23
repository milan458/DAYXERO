import Foundation

/// Milestones to celebrate (S13.1): Quit Day, then days 1, 3, 7, 14, 30, 60, 90, 100, 180 and 365.
/// They follow days clear, so a slip never takes one away.
public enum Milestone: Hashable, Sendable, Identifiable {
    case quitDay
    case days(Int)

    public static let all: [Milestone] = [.quitDay] + Milestones.days.map(Milestone.days)

    public var id: String {
        switch self {
        case .quitDay: "quitDay"
        case let .days(n): "\(n)"
        }
    }

    public init?(id: String) {
        if id == "quitDay" { self = .quitDay } else if let n = Int(id), Milestones.days.contains(n) { self = .days(n) } else { return nil }
    }

    /// Reached on Quit Day itself (day 1 on Home), the first full day the day after,
    /// and every other milestone on the day days clear reaches it, matching Home.
    public func isReached(daysClear: Int) -> Bool {
        switch self {
        case .quitDay: daysClear >= 1
        case .days(1): daysClear >= 2
        case let .days(n): daysClear >= n
        }
    }

    /// The days clear on which it's reached.
    public var reachedOnDay: Int {
        switch self {
        case .quitDay: 1
        case .days(1): 2
        case let .days(n): n
        }
    }

    public static func reached(daysClear: Int) -> [Milestone] {
        all.filter { $0.isReached(daysClear: daysClear) }
    }

    /// The milestone to celebrate now: the latest one reached and not yet celebrated. After a break, the earlier
    /// ones are quietly marked as reached instead of celebrated one after another.
    public static func toCelebrate(daysClear: Int, celebrated: Set<String>) -> Milestone? {
        guard let latest = reached(daysClear: daysClear).last, !celebrated.contains(latest.id) else { return nil }
        return latest
    }

    public static func next(daysClear: Int) -> Milestone? {
        all.first { !$0.isReached(daysClear: daysClear) }
    }

    /// The big number on the moment and the card.
    public var number: Int {
        switch self {
        case .quitDay: 1
        case let .days(n): n
        }
    }

    /// Drafted by Claude for Milan to edit (S13.2). Lines that make a claim name a source from the health timeline.
    public var title: String {
        switch self {
        case .quitDay: String(localized: "Quit Day")
        case .days(1): String(localized: "Your first full day")
        case .days(3): String(localized: "Three days clear")
        case .days(7): String(localized: "One week clear")
        case .days(14): String(localized: "Two weeks clear")
        case .days(30): String(localized: "One month clear")
        case .days(60): String(localized: "Two months clear")
        case .days(90): String(localized: "Three months clear")
        case .days(100): String(localized: "100 days clear")
        case .days(180): String(localized: "Six months clear")
        case .days(365): String(localized: "One year clear")
        case let .days(n): String(localized: "\(n) days clear")
        }
    }

    public var line: String {
        switch self {
        case .quitDay: String(localized: "Today's the day. You've prepared for this.")
        case .days(1): String(localized: "One whole day without nicotine. That's real.")
        case .days(3): String(localized: "By now most of the nicotine has left your body.")
        case .days(7): String(localized: "The first week is the hardest for most people. You did it.")
        case .days(14): String(localized: "Mood changes from withdrawal usually ease around now.")
        case .days(30): String(localized: "A whole month. Cravings come less often as the weeks go by.")
        case .days(60): String(localized: "Two months of choosing this, day after day.")
        case .days(90): String(localized: "Three months. This is becoming your normal.")
        case .days(100): String(localized: "Triple digits.")
        case .days(180): String(localized: "Half a year. Look how far you've come.")
        case .days(365): String(localized: "A full year nicotine-free.")
        case .days: ""
        }
    }

    /// The health-timeline source behind the line, if it makes a claim.
    public var sourceID: String? {
        switch self {
        case .days(3): "cdc-cotinine"
        case .days(7), .days(30): "smokefree"
        case .days(14): "smokefree-mood"
        default: nil
        }
    }

    /// "days clear" / "day clear" under the number.
    public var caption: String {
        switch self {
        case .quitDay: String(localized: "Quit Day")
        case .days(1): String(localized: "full day clear")
        case .days: String(localized: "days clear")
        }
    }
}
