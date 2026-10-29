import Foundation

/// Home's streak and adherence card (S19.4).
///
/// Adherence is the share of program days done out of those due before today. Today's day isn't due until the
/// day is over, so a morning before the lesson doesn't count against anyone; until one day is due it's 100%.
/// Doing a day early counts, and the share never goes past 100%.
public enum Adherence {
    /// The day a program day is due: prep day n on the nth day from the start (they open one after another,
    /// a day each), quit-week and weekly days on their own calendar day.
    public static func dueDate(of day: ProgramDayID, startedOn: Date, schedule: ProgramSchedule) -> Date {
        let calendar = schedule.clock.calendar
        let start = schedule.clock.startOfDate(startedOn)
        switch day.phase {
        case .prep: return calendar.date(byAdding: .day, value: day.index - 1, to: start) ?? start
        case .quit, .maintenance: return schedule.opensOn(day) ?? start
        }
    }

    /// 0...1.
    public static func fraction(schedule: ProgramSchedule, startedOn: Date, completed: Set<ProgramDayID>, now: Date) -> Double {
        let today = schedule.clock.day(containing: now)
        let due = schedule.outline.filter { dueDate(of: $0, startedOn: startedOn, schedule: schedule) < today }
        guard !due.isEmpty else { return 1 }
        let done = schedule.outline.filter(completed.contains).count
        return min(Double(done) / Double(due.count), 1)
    }

    /// Days in a row with a lesson done, ending today, or yesterday while today's is still to do.
    public static func streak(completedAt: [Date], clock: DayClock, now: Date) -> Int {
        let days = Set(completedAt.map { clock.day(containing: $0) })
        var day = clock.day(containing: now)
        if !days.contains(day) { day = clock.calendar.date(byAdding: .day, value: -1, to: day) ?? day }
        var count = 0
        while days.contains(day) {
            count += 1
            guard let previous = clock.calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return count
    }
}

/// The craving count on Home's moss header (S19.2): today's against a usual day.
public enum CravingPace {
    /// The usual number of cravings a day: the rounded average over the last 7 days before today that had any.
    /// Nil until there's at least one such day.
    public static func usual(cravingsAt dates: [Date], clock: DayClock, now: Date) -> Int? {
        let today = clock.day(containing: now)
        guard let weekAgo = clock.calendar.date(byAdding: .day, value: -7, to: today) else { return nil }
        var perDay: [Date: Int] = [:]
        for date in dates {
            let day = clock.day(containing: date)
            if day >= weekAgo, day < today { perDay[day, default: 0] += 1 }
        }
        guard !perDay.isEmpty else { return nil }
        return Int((Double(perDay.values.reduce(0, +)) / Double(perDay.count)).rounded())
    }

    public static func today(cravingsAt dates: [Date], clock: DayClock, now: Date) -> Int {
        let today = clock.day(containing: now)
        return dates.filter { clock.day(containing: $0) == today }.count
    }
}
