import Foundation

/// Today's one focus card (UX-08, 2 Nov 2026). From 6 AM to 6 PM it's today's lesson, or after Day Xero the next
/// change in the body (UX-09). After 6 PM it turns to Glim's evening check-in until that's done; late at night,
/// once checked in, it offers winding down. Evening cards never show in the morning.
public enum TodayFocus: Sendable, Equatable {
    /// Today's program session (State A, prep).
    case lesson
    /// The body-recovery milestone (State B, after Day Xero).
    case recovery
    /// Glim's evening check-in: "A minute on how today went".
    case checkIn
    /// "Can't sleep? Breathe with Glim".
    case windDown

    /// The day's focus is the lesson (or recovery) from this hour...
    public static let dayStartHour = 6
    /// ...until this one, when the evening check-in takes over.
    public static let eveningHour = 18
    /// From this hour until the morning, a finished check-in hands over to winding down.
    public static let nightHour = 22

    public static func pick(hour: Int, postQuit: Bool, checkedIn: Bool) -> TodayFocus {
        let usual: TodayFocus = postQuit ? .recovery : .lesson
        if (dayStartHour..<eveningHour).contains(hour) { return usual }
        if !checkedIn { return .checkIn }
        return hour >= nightHour || hour < dayStartHour ? .windDown : usual
    }
}

/// Short spans of time for Today's hero and counters (UX-05, UX-09): "3d 14h", "5h 20m", "45m".
public enum TimeFree {
    public static func short(_ seconds: TimeInterval, locale: Locale = .current) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = locale
        let formatter = DateComponentsFormatter()
        formatter.calendar = calendar
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2
        // Whole units, rounded down, so "3d 14h" never runs ahead of the real time.
        let minutes = Int(max(seconds, 0) / 60)
        let components: DateComponents
        if minutes >= 24 * 60 {
            formatter.allowedUnits = [.day, .hour]
            components = DateComponents(day: minutes / (24 * 60), hour: minutes % (24 * 60) / 60)
        } else if minutes >= 60 {
            formatter.allowedUnits = [.hour, .minute]
            components = DateComponents(hour: minutes / 60, minute: minutes % 60)
        } else {
            formatter.allowedUnits = [.minute]
            formatter.zeroFormattingBehavior = .pad
            components = DateComponents(minute: minutes)
        }
        return formatter.string(from: components) ?? ""
    }
}

/// Resilience on Today's post-quit hero (UX-09): the share of days since Quit Day with no slip logged. Quit Day counts
/// as day 1, as in "days since Quit Day". A slip lowers it a little; it never resets, and a day with no slip lifts it.
public enum Resilience {
    /// 0...100, rounded down, so 100% means no slip at all.
    public static func percent(quitDay: Date, slips: [Date], now: Date, clock: DayClock) -> Int {
        let start = clock.startOfDate(quitDay)
        let today = clock.day(containing: now)
        guard today >= start else { return 100 }
        let days = clock.days(fromDate: quitDay, to: now) + 1
        let slipDays = Set(slips.map { clock.day(containing: $0) }.filter { $0 >= start && $0 <= today })
        let clear = max(days - slipDays.count, 0)
        return Int((Double(clear) / Double(max(days, 1)) * 100).rounded(.down))
    }
}
