import Foundation

/// The days listed on the plan reveal (S2.10): today and the six days after it, or, when Quit Day is a week
/// or more away, the first prep days, a row for the rest, and Quit Day itself. No day is ever left out
/// without saying so.
public enum PlanTimeline {
    public enum Kind: Equatable, Sendable {
        /// Prep day n, from 1.
        case prep(Int)
        /// The prep days between the last listed one and Quit Day.
        case morePrep(Int)
        case quitDay
        /// Day n clear; Quit Day itself is day 1, so the first of these is day 2.
        case clear(Int)
    }

    public struct Item: Equatable, Sendable {
        public let kind: Kind
        /// The day the row is about; for `morePrep`, the first of those days.
        public let date: Date
    }

    public static let rows = 7
    /// Prep days listed before the "more" row when Quit Day is beyond the first week.
    public static let leadingPrepDays = 5

    /// - Parameters:
    ///   - prepDays: days from today to Quit Day. Today is prep day 1.
    ///   - today: the start of today.
    public static func items(prepDays: Int, today: Date, calendar: Calendar = .current) -> [Item] {
        let prep = max(prepDays, 0)
        func day(_ offset: Int) -> Date { calendar.date(byAdding: .day, value: offset, to: today) ?? today }

        guard prep >= rows else {
            return (0..<rows).map { offset in
                if offset < prep { return Item(kind: .prep(offset + 1), date: day(offset)) }
                if offset == prep { return Item(kind: .quitDay, date: day(offset)) }
                return Item(kind: .clear(offset - prep + 1), date: day(offset))
            }
        }
        var items = (0..<leadingPrepDays).map { Item(kind: .prep($0 + 1), date: day($0)) }
        items.append(Item(kind: .morePrep(prep - leadingPrepDays), date: day(leadingPrepDays)))
        items.append(Item(kind: .quitDay, date: day(prep)))
        return items
    }

    /// Whether the list reaches past the first week, so its heading should say "Up to Quit Day".
    public static func isLong(prepDays: Int) -> Bool { prepDays >= rows }
}
