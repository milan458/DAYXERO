import Foundation

/// The morning pledge and evening check-in (S11). Both are optional; neither changes days clear.
public struct DailyRhythm: Sendable {
    /// The pledge card shows from the start of the day until this hour.
    public static let pledgeUntilHour = 12
    /// The check-in card shows from this hour until the day ends.
    public static let checkInFromHour = 18
    /// Day-end choices (S11.3): the hour after midnight when "today" ends.
    public static let boundaryChoices = [0, 2, 4, 6]

    public let clock: DayClock

    public init(clock: DayClock) {
        self.clock = clock
    }

    /// The day a pledge or check-in made at `now` belongs to.
    public func day(at now: Date) -> Date {
        clock.day(containing: now)
    }

    /// Morning: from the start of the day (the boundary hour) until midday.
    public func isPledgeTime(_ now: Date) -> Bool {
        let hour = clock.calendar.component(.hour, from: now)
        return hour >= clock.boundaryHour && hour < Self.pledgeUntilHour
    }

    /// Evening: from 6pm until the day ends, including the small hours before the boundary.
    public func isCheckInTime(_ now: Date) -> Bool {
        let hour = clock.calendar.component(.hour, from: now)
        return hour >= Self.checkInFromHour || hour < clock.boundaryHour
    }

    public func hasPledged(_ pledgeDays: [Date], at now: Date) -> Bool {
        let today = day(at: now)
        return pledgeDays.contains { clock.calendar.isDate($0, inSameDayAs: today) }
    }

    public func hasCheckedIn(_ checkInDays: [Date], at now: Date) -> Bool {
        let today = day(at: now)
        return checkInDays.contains { clock.calendar.isDate($0, inSameDayAs: today) }
    }

    /// Which reason the pledge shows today: reasons with a photo first, then the rest, one per day in turn.
    public static func reasonIndex(hasPhoto: [Bool], dayNumber: Int) -> Int? {
        guard !hasPhoto.isEmpty else { return nil }
        let order = hasPhoto.indices.filter { hasPhoto[$0] } + hasPhoto.indices.filter { !hasPhoto[$0] }
        return order[((dayNumber % order.count) + order.count) % order.count]
    }

    /// Days of the current week (Monday first) with a check-in, for the gentle week row.
    public func weekCheckIns(_ checkInDays: [Date], at now: Date) -> [Bool] {
        let today = day(at: now)
        let weekday = (clock.calendar.component(.weekday, from: today) + 5) % 7
        guard let monday = clock.calendar.date(byAdding: .day, value: -weekday, to: today) else { return [] }
        return (0..<7).map { offset in
            guard let d = clock.calendar.date(byAdding: .day, value: offset, to: monday) else { return false }
            return checkInDays.contains { clock.calendar.isDate($0, inSameDayAs: d) }
        }
    }

    // MARK: Reminders (S11.4)

    public struct Reminder: Sendable, Equatable {
        public let id: String
        public let date: Date
        public let title: String
        public let body: String
    }

    public static let reminderDays = 7

    /// Pledge and check-in reminders for the coming week. Today's is skipped once it's been done.
    /// - Parameters: minutes after midnight, or nil when that reminder is off.
    public func reminders(pledgeMinute: Int?, checkInMinute: Int?, pledgedToday: Bool, checkedInToday: Bool, now: Date) -> [Reminder] {
        let cal = clock.calendar
        let today = cal.startOfDay(for: now)
        var out: [Reminder] = []
        for offset in 0..<Self.reminderDays {
            guard let date = cal.date(byAdding: .day, value: offset, to: today) else { continue }
            let stamp = cal.dateComponents([.year, .month, .day], from: date)
            let tag = String(format: "%04d%02d%02d", stamp.year ?? 0, stamp.month ?? 0, stamp.day ?? 0)
            if let minute = pledgeMinute, let at = cal.date(byAdding: .minute, value: minute, to: date), at > now,
               !(offset == 0 && pledgedToday) {
                out.append(Reminder(id: "daily.pledge.\(tag)", date: at, title: String(localized: "Good morning"),
                                    body: String(localized: "Ten seconds for today's pledge?")))
            }
            if let minute = checkInMinute, let at = cal.date(byAdding: .minute, value: minute, to: date), at > now,
               !(offset == 0 && checkedInToday) {
                out.append(Reminder(id: "daily.checkin.\(tag)", date: at, title: String(localized: "How did today go?"),
                                    body: String(localized: "A one-minute check-in, if you have it.")))
            }
        }
        return out
    }
}
