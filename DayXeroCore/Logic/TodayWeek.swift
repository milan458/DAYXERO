import Foundation

/// Today's week strip (Today redesign, 4 Nov 2026): seven days with today among them.
///
/// During prep the strip ends on Quit Day once Quit Day is within the week, so the countdown has somewhere to land;
/// with Quit Day further off it starts the day before today. From Quit Day on, it starts on Quit Day for the first
/// days, then keeps three days behind today.
///
/// A tick means the same thing the numbers around it mean: during prep, a session was finished that day; from Quit
/// Day on, no slip was logged that day, the same rule as `Resilience`, so "4 of 4 days" and four ticks always agree.
public struct TodayWeek: Equatable, Sendable {
    public enum Mark: Equatable, Sendable {
        /// Before the program started: just the date.
        case before
        /// Prep: a session was finished that day. From Quit Day: no slip logged that day.
        case done
        /// Prep: no session that day. From Quit Day: a slip was logged. Drawn plainly, never as a failure.
        case quiet
        /// Today, still under way.
        case today
        case future
    }

    public struct Day: Equatable, Sendable, Identifiable {
        public let date: Date
        public let mark: Mark
        public let isToday: Bool
        public let isQuitDay: Bool
        public var id: Date { date }
    }

    public let days: [Day]
    /// Quit Day's date, which may be outside the seven days: before it a tick is a session, from it a day with no slip.
    public let quitDay: Date

    public init(days: [Day], quitDay: Date) {
        self.days = days
        self.quitDay = quitDay
    }

    /// - Parameters:
    ///   - programStart: when the program began (the profile's creation); days before it are just dates.
    ///   - sessionsDone: when program sessions were finished.
    ///   - slips: when slips were logged.
    public static func make(now: Date, quitDay: Date, programStart: Date, sessionsDone: [Date], slips: [Date],
                            clock: DayClock) -> TodayWeek {
        let calendar = clock.calendar
        let today = clock.day(containing: now)
        let quit = clock.startOfDate(quitDay)
        let started = clock.day(containing: programStart)
        func adding(_ days: Int, to date: Date) -> Date {
            calendar.startOfDay(for: calendar.date(byAdding: .day, value: days, to: date) ?? date)
        }
        func gap(_ from: Date, _ to: Date) -> Int {
            calendar.dateComponents([.day], from: from, to: to).day ?? 0
        }

        let start: Date
        if today <= quit {
            start = gap(today, quit) <= 6 ? adding(-6, to: quit) : adding(-1, to: today)
        } else {
            start = max(quit, adding(-3, to: today))
        }

        let sessionDays = Set(sessionsDone.map { clock.day(containing: $0) })
        let slipDays = Set(slips.map { clock.day(containing: $0) })
        let days = (0..<7).map { offset -> Day in
            let date = adding(offset, to: start)
            let mark: Mark
            if date > today {
                mark = .future
            } else if date < quit {
                // Prep, including today before Quit Day.
                if sessionDays.contains(date) {
                    mark = .done
                } else if date == today {
                    mark = .today
                } else {
                    mark = date < started ? .before : .quiet
                }
            } else if slipDays.contains(date) {
                mark = .quiet
            } else {
                mark = date == today ? .today : .done
            }
            return Day(date: date, mark: mark, isToday: date == today, isQuitDay: date == quit)
        }
        return TodayWeek(days: days, quitDay: quit)
    }
}

/// How far the ring on Today has come after Quit Day: from Quit Day to the next change in the body that is counted
/// down (CLIN-01 "felt" changes never are), 0...1. Nil once every counted change has started.
public enum TodayRing {
    public static func fraction(elapsedHours: Double, nextChangeFromHours: Double?) -> Double? {
        guard let next = nextChangeFromHours, next > 0 else { return nil }
        return min(max(elapsedHours / next, 0), 1)
    }
}
