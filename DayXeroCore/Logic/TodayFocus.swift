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

/// Resilience on Today's post-quit hero (UX-09, CLIN-07): days since Quit Day with no slip logged, out of all days since
/// Quit Day, as "45 of 46 days · 98%". Quit Day counts as day 1, as in "days since Quit Day". It never resets to zero:
/// a slip takes one day off the clear count, and every clear day after it adds one back.
public enum Resilience {
    public struct Days: Sendable, Equatable {
        public let clear: Int
        public let total: Int

        public init(clear: Int, total: Int) {
            self.clear = clear
            self.total = total
        }

        /// 0...100 to the nearest whole number, but never 100 with a slip in it: 199 of 200 shows 99%.
        public var percent: Int {
            guard total > 0 else { return 100 }
            let rounded = Int((Double(clear) / Double(total) * 100).rounded())
            return clear < total ? min(rounded, 99) : 100
        }
    }

    /// Clear days and all days since Quit Day. Before Quit Day: 0 of 0.
    public static func days(quitDay: Date, slips: [Date], now: Date, clock: DayClock) -> Days {
        let start = clock.startOfDate(quitDay)
        let today = clock.day(containing: now)
        guard today >= start else { return Days(clear: 0, total: 0) }
        let total = clock.days(fromDate: quitDay, to: now) + 1
        let slipDays = Set(slips.map { clock.day(containing: $0) }.filter { $0 >= start && $0 <= today })
        return Days(clear: max(total - slipDays.count, 0), total: total)
    }

    public static func percent(quitDay: Date, slips: [Date], now: Date, clock: DayClock) -> Int {
        days(quitDay: quitDay, slips: slips, now: now, clock: clock).percent
    }
}
