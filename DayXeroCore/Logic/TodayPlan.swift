import Foundation

/// Today's time of day (F08). Morning and afternoon are Xero's; evening and night are Glim's.
public enum TodaySlot: String, Sendable, CaseIterable {
    case morning, afternoon, evening, night

    /// 5–12 morning, 12–17 afternoon, 17–22 evening, otherwise night.
    public init(hour: Int) {
        switch hour {
        case 5..<12: self = .morning
        case 12..<17: self = .afternoon
        case 17..<22: self = .evening
        default: self = .night
        }
    }

    public init(_ date: Date, calendar: Calendar = .current) {
        self.init(hour: calendar.component(.hour, from: date))
    }
}

/// A craving that usually comes at about the same time, learned from the person's own log.
public struct UsualWave: Sendable, Equatable {
    /// Minutes after midnight, rounded to 10 minutes.
    public let minuteOfDay: Int
    /// The trigger most of those cravings had, if one did.
    public let trigger: Trigger?

    public init(minuteOfDay: Int, trigger: Trigger?) {
        self.minuteOfDay = minuteOfDay
        self.trigger = trigger
    }
}

public enum CravingPattern {
    /// How far back the log is read.
    public static let lookbackDays = 14
    /// Cravings within this many minutes count as the same wave.
    public static let windowMinutes = 60
    /// A wave needs this many cravings, on at least `minimumDays` different days.
    public static let minimumCount = 3
    public static let minimumDays = 2

    /// The next wave later today, if the log shows one. Nothing is guessed: with too little data, nil.
    public static func usualWave(_ cravings: [(time: Date, trigger: Trigger?)], now: Date,
                                 calendar: Calendar = .current) -> UsualWave? {
        guard let from = calendar.date(byAdding: .day, value: -lookbackDays, to: now) else { return nil }
        let recent = cravings.filter { $0.time >= from && $0.time < now }
        let minutes = recent.map { calendar.component(.hour, from: $0.time) * 60 + calendar.component(.minute, from: $0.time) }
        let nowMinute = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)

        var best: (start: Int, members: [Int])?
        for start in Set(minutes).sorted() where start > nowMinute {
            let members = minutes.indices.filter { minutes[$0] >= start && minutes[$0] < start + windowMinutes }
            let days = Set(members.map { calendar.startOfDay(for: recent[$0].time) })
            guard members.count >= minimumCount, days.count >= minimumDays else { continue }
            if members.count > (best?.members.count ?? 0) { best = (start, members) }
        }
        guard let best else { return nil }
        let mean = Double(best.members.map { minutes[$0] }.reduce(0, +)) / Double(best.members.count)
        let rounded = Int((mean / 10).rounded()) * 10

        let triggers = best.members.compactMap { recent[$0].trigger }
        let counts = Dictionary(triggers.map { ($0, 1) }, uniquingKeysWith: +)
        let top = counts.max { $0.value < $1.value || ($0.value == $1.value && $0.key.rawValue > $1.key.rawValue) }
        let trigger = top.flatMap { $0.value * 2 >= best.members.count ? $0.key : nil }
        return UsualWave(minuteOfDay: min(rounded, 23 * 60 + 50), trigger: trigger)
    }
}

/// The coloured card at the top of Today (F08, migration plan §7.2).
public enum TodayTopCard: Sendable, Equatable {
    /// "Your coffee wave · Usually comes around 9:40": only when the log shows one.
    case wave(UsualWave)
    /// Today's program session (the green lesson card).
    case lesson
    /// "With Glim · How was today, really?"
    case checkIn
    /// "Can't sleep? Breathe with Glim"
    case windDown

    public static func pick(slot: TodaySlot, wave: UsualWave?, checkedIn: Bool) -> TodayTopCard {
        switch slot {
        case .morning: wave.map(TodayTopCard.wave) ?? .lesson
        case .afternoon: .lesson
        case .evening: checkedIn ? .lesson : .checkIn
        case .night: .windDown
        }
    }
}
