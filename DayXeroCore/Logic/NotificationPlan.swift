import Foundation

/// Every program notification DayXero sends (S14.1), with quiet hours (S14.2) and copy that never guilts (S14.3).
/// Worked out ahead each time the app opens; nothing is scheduled past the two "away" notes.
public enum NotificationPlan {
    public enum Kind: String, CaseIterable, Sendable {
        case pledge, lesson, checkIn, milestone, away, weekly

        /// Which one drops first when more than the daily cap are due: the highest number.
        var dropOrder: Int {
            switch self {
            case .milestone: 0
            case .weekly: 1
            case .away: 2
            case .pledge: 3
            case .lesson: 4
            case .checkIn: 5
            }
        }
    }

    public struct Settings: Sendable, Equatable {
        /// Minutes after midnight, or nil when that kind is off.
        public var pledge: Int? = 8 * 60
        public var lesson: Int? = 12 * 60
        public var checkIn: Int? = 21 * 60
        public var milestone: Int? = 9 * 60
        public var awayOn = true
        /// Glim's weekly check-in after graduation (S27.18): minutes after midnight, or nil when off. Off unless switched
        /// on in Settings, so a fresh install still sends only the two daily notes onboarding promises.
        public var weekly: Int? = nil
        /// The weekly check-in's day: `Calendar` weekday numbering, 1 is Sunday.
        public var weeklyWeekday = 1
        /// Quiet hours as minutes after midnight; may wrap past midnight. nil when off.
        public var quietStart: Int? = 22 * 60 + 30
        public var quietEnd: Int? = 7 * 60 + 30

        public init() {}
    }

    public struct Notification: Sendable, Equatable {
        public let id: String
        public let kind: Kind
        public let date: Date
        public let title: String
        public let body: String
    }

    /// What the plan needs to know about today, from the app.
    public struct Inputs: Sendable {
        public var now: Date
        public var pledgedToday: Bool
        public var checkedInToday: Bool
        /// Days (start of day) on which a new lesson opens or today's lesson is waiting, e.g. "Day 4".
        public var lessons: [(day: Date, name: String, minutes: Int)]
        /// Milestones by the day they're reached.
        public var milestones: [(day: Date, title: String)]
        /// The day the program would replay after a break, e.g. "Day 3"; nil before the first lesson is done.
        public var replayName: String?
        /// The next lesson's name for the first away note, e.g. "Day 4".
        public var nextLessonName: String?
        /// The four weeks are done (graduation held). Glim's weekly check-in starts then.
        public var graduated: Bool

        public init(now: Date, pledgedToday: Bool, checkedInToday: Bool, lessons: [(day: Date, name: String, minutes: Int)] = [],
                    milestones: [(day: Date, title: String)] = [], replayName: String? = nil, nextLessonName: String? = nil,
                    graduated: Bool = false) {
            self.now = now
            self.pledgedToday = pledgedToday
            self.checkedInToday = checkedInToday
            self.lessons = lessons
            self.milestones = milestones
            self.replayName = replayName
            self.nextLessonName = nextLessonName
            self.graduated = graduated
        }
    }

    /// At most this many program notifications a day. NRT and trial reminders don't count.
    public static let dailyCap = 3
    /// Daily reminders run for today and tomorrow; after that the person is "away" and only the away notes go out.
    public static let activeDays = 2
    /// Away notes on these days after the last open (Milan's pause-and-replay rule), then nothing.
    public static let awayDays = [2, 3]
    /// Away notes go out at this time.
    public static let awayMinute = 10 * 60

    public static func plan(_ settings: Settings, inputs: Inputs, calendar: Calendar) -> [Notification] {
        let today = calendar.startOfDay(for: inputs.now)
        var all: [Notification] = []

        for offset in 0..<activeDays {
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            let stamp = Self.stamp(day, calendar)
            if let m = settings.pledge, !(offset == 0 && inputs.pledgedToday) {
                all.append(make(.pledge, "\(stamp)", day, m, NotificationCopy.pledge, calendar))
            }
            if let m = settings.lesson, let lesson = inputs.lessons.first(where: { calendar.isDate($0.day, inSameDayAs: day) }) {
                all.append(make(.lesson, "\(stamp)", day, m, NotificationCopy.lesson(name: lesson.name, minutes: lesson.minutes), calendar))
            }
            if let m = settings.checkIn, !(offset == 0 && inputs.checkedInToday) {
                all.append(make(.checkIn, "\(stamp)", day, m, NotificationCopy.checkIn, calendar))
            }
        }

        if let m = settings.milestone {
            for milestone in inputs.milestones {
                let day = calendar.startOfDay(for: milestone.day)
                guard let offset = calendar.dateComponents([.day], from: today, to: day).day, (0..<activeDays).contains(offset) else { continue }
                all.append(make(.milestone, Self.stamp(day, calendar), day, m, NotificationCopy.milestone(title: milestone.title), calendar))
            }
        }

        if settings.awayOn {
            for (i, offset) in awayDays.enumerated() {
                guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
                let copy = i == 0 ? NotificationCopy.awayFirst(next: inputs.nextLessonName) : NotificationCopy.awaySecond(replay: inputs.replayName)
                all.append(make(.away, Self.stamp(day, calendar), day, awayMinute, copy, calendar))
            }
        }

        // Glim's weekly check-in (S27.18): the next one only, on its weekday, once the four weeks are done.
        if let m = settings.weekly, inputs.graduated {
            for offset in 0...7 {
                guard let day = calendar.date(byAdding: .day, value: offset, to: today),
                      calendar.component(.weekday, from: day) == settings.weeklyWeekday else { continue }
                let note = make(.weekly, Self.stamp(day, calendar), day, m, NotificationCopy.weekly, calendar)
                if note.date > inputs.now {
                    all.append(note)
                    break
                }
            }
        }

        let quiet = all.map { shift($0, settings: settings, calendar: calendar) }.filter { $0.date > inputs.now }
        return cap(quiet, calendar: calendar).sorted { $0.date < $1.date }
    }

    /// Moves a time inside quiet hours to the moment they end.
    public static func outOfQuietHours(_ date: Date, start: Int?, end: Int?, calendar: Calendar) -> Date {
        guard let start, let end, start != end else { return date }
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        let minute = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
        let inside = start < end ? (minute >= start && minute < end) : (minute >= start || minute < end)
        guard inside else { return date }
        let day = calendar.startOfDay(for: date)
        // Wrapping hours (22:30–7:30): late evening moves to the next morning.
        let endDay = (start > end && minute >= start) ? (calendar.date(byAdding: .day, value: 1, to: day) ?? day) : day
        return calendar.date(byAdding: .minute, value: end, to: endDay) ?? date
    }

    // MARK: Helpers

    private static func make(_ kind: Kind, _ tag: String, _ day: Date, _ minute: Int, _ copy: (String, String), _ calendar: Calendar) -> Notification {
        let date = calendar.date(byAdding: .minute, value: minute, to: day) ?? day
        return Notification(id: "prog.\(kind.rawValue).\(tag)", kind: kind, date: date, title: copy.0, body: copy.1)
    }

    private static func shift(_ n: Notification, settings: Settings, calendar: Calendar) -> Notification {
        let moved = outOfQuietHours(n.date, start: settings.quietStart, end: settings.quietEnd, calendar: calendar)
        return Notification(id: n.id, kind: n.kind, date: moved, title: n.title, body: n.body)
    }

    /// Keeps at most `dailyCap` per calendar day, dropping the lowest priority first.
    private static func cap(_ items: [Notification], calendar: Calendar) -> [Notification] {
        let byDay = Dictionary(grouping: items) { calendar.startOfDay(for: $0.date) }
        return byDay.values.flatMap { day in
            day.sorted { $0.kind.dropOrder < $1.kind.dropOrder }.prefix(dailyCap)
        }
    }

    static func stamp(_ day: Date, _ calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: day)
        return String(format: "%04d%02d%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}

/// All notification wording in one place (S14.3), drafted by Claude and kept by Milan.
public enum NotificationCopy {
    public static let pledge = (String(localized: "Good morning"), String(localized: "Ten seconds for today's pledge?"))
    public static let checkIn = (String(localized: "How did today go?"), String(localized: "A one-minute check-in, if you have it."))
    /// Glim's weekly check-in after graduation (S27.18).
    public static let weekly = (String(localized: "How was your week?"), String(localized: "Glim's Sunday check-in. One minute, if you have it."))

    public static func lesson(name: String, minutes: Int) -> (String, String) {
        (String(localized: "\(name) is ready"), String(localized: "\(minutes) minutes, whenever suits you."))
    }

    /// The number stays off the Lock Screen; it's shown in the app.
    public static func milestone(title: String) -> (String, String) {
        (String(localized: "Today: \(title)"), String(localized: "Open DayXero to see it."))
    }

    public static func awayFirst(next: String?) -> (String, String) {
        (next.map { String(localized: "\($0) is here when you are") } ?? String(localized: "DayXero is here when you are"),
         String(localized: "No catch-up needed."))
    }

    public static func awaySecond(replay: String?) -> (String, String) {
        (String(localized: "Welcome back, whenever you're ready"),
         replay.map { String(localized: "We'll start with a quick replay of \($0). Your days since Quit Day haven't changed.") }
            ?? String(localized: "Your days since Quit Day haven't changed."))
    }

    /// Words notifications never use (S14.3). A test checks every string against this list.
    public static let bannedWords = ["streak", "broke", "missed", "lose", "losing", "failed", "fail", "don't forget", "you haven't"]
}
