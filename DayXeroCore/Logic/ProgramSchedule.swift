import Foundation

/// The program's day list and when each day opens.
///
/// Prep days run from the day someone finishes onboarding to the day before Quit Day. The quit week
/// is seven days starting on Quit Day; the maintenance arc is four weekly sessions after that.
/// A day opens once the previous day is done (plan §1). Quit-week and maintenance days also wait for
/// their calendar day, because they line up with real days after Quit Day (S4.8, default pending Milan).
public struct ProgramSchedule: Sendable {
    public static let quitWeekDays = 7
    public static let maintenanceWeeks = 4

    public let engine: ProgramEngine
    public let quitDay: Date
    public let clock: DayClock

    /// - Parameters:
    ///   - startedOn: the day onboarding finished (Day 1 of prep).
    ///   - quitDay: Quit Day's calendar date.
    public init(startedOn: Date, quitDay: Date, clock: DayClock) {
        let prepDays = max(clock.calendar.dateComponents([.day], from: clock.startOfDate(startedOn), to: clock.startOfDate(quitDay)).day ?? 0, 0)
        var outline = (0..<prepDays).map { ProgramDayID(phase: .prep, index: $0 + 1) }
        outline += (1...Self.quitWeekDays).map { ProgramDayID(phase: .quit, index: $0) }
        outline += (1...Self.maintenanceWeeks).map { ProgramDayID(phase: .maintenance, index: $0) }
        self.engine = ProgramEngine(outline: outline)
        self.quitDay = quitDay
        self.clock = clock
    }

    public var outline: [ProgramDayID] { engine.outline }
    public var prepDays: Int { outline.filter { $0.phase == .prep }.count }

    /// The calendar date a day opens on, or nil if it isn't tied to the calendar (prep days).
    public func opensOn(_ day: ProgramDayID) -> Date? {
        let start = clock.startOfDate(quitDay)
        switch day.phase {
        case .prep: return nil
        case .quit: return clock.calendar.date(byAdding: .day, value: day.index - 1, to: start)
        case .maintenance: return clock.calendar.date(byAdding: .day, value: Self.quitWeekDays + 7 * (day.index - 1), to: start)
        }
    }

    public enum Availability: Equatable, Sendable {
        case completed
        case available
        /// Next in line, but its calendar day hasn't come yet.
        case opensOn(Date)
        case locked
    }

    public func availability(of day: ProgramDayID, completed: Set<ProgramDayID>, at now: Date) -> Availability {
        switch engine.state(of: day, completed: completed) {
        case .completed: return .completed
        case .locked: return .locked
        case .available:
            if let date = opensOn(day), clock.day(containing: now) < date { return .opensOn(date) }
            return .available
        }
    }

    /// The day Home should feature: the next one to do, or nil when the program is finished.
    public func featuredDay(completed: Set<ProgramDayID>) -> ProgramDayID? {
        engine.nextDay(completed: completed)
    }
}

/// Days-clear milestones (S13.1 suggested schedule, pending Milan's confirmation).
public enum Milestones {
    public static let days = [1, 3, 7, 14, 30, 60, 90, 100, 180, 365]

    /// The next milestone strictly after `daysClear`, or nil after the last one.
    public static func next(after daysClear: Int) -> Int? {
        days.first { $0 > daysClear }
    }

    /// The milestone at or before `daysClear`, used as the start of the progress bar toward the next one.
    public static func previous(atOrBefore daysClear: Int) -> Int {
        days.last { $0 <= daysClear } ?? 0
    }
}
