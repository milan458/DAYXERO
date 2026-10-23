import Foundation

/// Countries with label presets (S9.2). Everywhere else enters the pack's schedule by hand.
public enum LabelCountry: String, CaseIterable, Sendable {
    case us, uk, au, de

    public var title: LocalizedStringResource {
        switch self {
        case .us: "US"
        case .uk: "UK"
        case .au: "Australia"
        case .de: "Germany"
        }
    }

    /// The preset country for a region code such as "GB", or nil to enter by hand.
    public init?(region: String?) {
        switch region?.uppercased() {
        case "US": self = .us
        case "GB": self = .uk
        case "AU": self = .au
        case "DE": self = .de
        default: return nil
        }
    }
}

/// A schedule printed on common packs, offered only as a starting point to match against the person's own pack.
public struct NRTPreset: Identifiable, Sendable {
    public let id: String
    public let country: LabelCountry
    public let types: Set<NRTType>
    public let title: LocalizedStringResource
    /// What the label says about who starts here, shown as the label's words, not advice.
    public let labelNote: LocalizedStringResource?
    public let steps: [PlanStep]
    public let source: HealthSource

    public var totalWeeks: Int { steps.reduce(0) { $0 + $1.weeks } }
}

public enum NRTLabels {
    public static let all: [NRTPreset] = [
        NRTPreset(id: "us-patch-10", country: .us, types: [.patch], title: "10 weeks, starting on 21 mg",
                  labelNote: "US labels: more than 10 cigarettes a day, start on 21 mg.",
                  steps: [PlanStep(strengthMg: 21, weeks: 6), PlanStep(strengthMg: 14, weeks: 2), PlanStep(strengthMg: 7, weeks: 2)],
                  source: HealthSources.usPatch10),
        NRTPreset(id: "us-patch-8", country: .us, types: [.patch], title: "8 weeks, starting on 21 mg",
                  labelNote: "Some US packs use 4 weeks on 21 mg instead of 6.",
                  steps: [PlanStep(strengthMg: 21, weeks: 4), PlanStep(strengthMg: 14, weeks: 2), PlanStep(strengthMg: 7, weeks: 2)],
                  source: HealthSources.usPatch8),
        NRTPreset(id: "us-patch-14", country: .us, types: [.patch], title: "8 weeks, starting on 14 mg",
                  labelNote: "US labels: 10 cigarettes a day or fewer, start on 14 mg.",
                  steps: [PlanStep(strengthMg: 14, weeks: 6), PlanStep(strengthMg: 7, weeks: 2)],
                  source: HealthSources.usPatch10),
        NRTPreset(id: "us-gum-12", country: .us, types: [.gum, .lozenge], title: "12 weeks, as on the pack",
                  labelNote: "US labels: 4 mg if your first cigarette is within 30 minutes of waking, otherwise 2 mg.",
                  steps: [PlanStep(strengthMg: 0, weeks: 6, note: "1 piece every 1–2 hours"),
                          PlanStep(strengthMg: 0, weeks: 3, note: "1 piece every 2–4 hours"),
                          PlanStep(strengthMg: 0, weeks: 3, note: "1 piece every 4–8 hours")],
                  source: HealthSources.usGum),
        NRTPreset(id: "uk-patch-24", country: .uk, types: [.patch], title: "24-hour patch, 10 weeks from 21 mg",
                  labelNote: "UK 24-hour packs: fewer than 10 a day, start on 14 mg for 6 weeks instead.",
                  steps: [PlanStep(strengthMg: 21, weeks: 6), PlanStep(strengthMg: 14, weeks: 2), PlanStep(strengthMg: 7, weeks: 2)],
                  source: HealthSources.ukPatch24),
        NRTPreset(id: "uk-patch-24-light", country: .uk, types: [.patch], title: "24-hour patch, 8 weeks from 14 mg",
                  labelNote: nil,
                  steps: [PlanStep(strengthMg: 14, weeks: 6), PlanStep(strengthMg: 7, weeks: 2)],
                  source: HealthSources.ukPatch24),
        NRTPreset(id: "uk-patch-16", country: .uk, types: [.patch], title: "16-hour patch, 12 weeks from 25 mg",
                  labelNote: "UK 16-hour packs: worn from morning to bedtime.",
                  steps: [PlanStep(strengthMg: 25, weeks: 8), PlanStep(strengthMg: 15, weeks: 2), PlanStep(strengthMg: 10, weeks: 2)],
                  source: HealthSources.ukPatch16),
        NRTPreset(id: "uk-patch-16-light", country: .uk, types: [.patch], title: "16-hour patch, 12 weeks from 15 mg",
                  labelNote: nil,
                  steps: [PlanStep(strengthMg: 15, weeks: 8), PlanStep(strengthMg: 10, weeks: 4)],
                  source: HealthSources.ukPatch16),
        NRTPreset(id: "au-patch", country: .au, types: [.patch], title: "10 weeks, starting on 21 mg",
                  labelNote: "Australian packs: 10 or more a day, start on 21 mg. The last step can run 2–4 weeks.",
                  steps: [PlanStep(strengthMg: 21, weeks: 6), PlanStep(strengthMg: 14, weeks: 2), PlanStep(strengthMg: 7, weeks: 2)],
                  source: HealthSources.auPatch),
        NRTPreset(id: "de-patch", country: .de, types: [.patch], title: "3 steps from 21 mg",
                  labelNote: "German packs: more than 20 a day, start on 21 mg. Each step runs 3–4 weeks; set yours to match.",
                  steps: [PlanStep(strengthMg: 21, weeks: 4), PlanStep(strengthMg: 14, weeks: 4), PlanStep(strengthMg: 7, weeks: 4)],
                  source: HealthSources.dePatch),
        NRTPreset(id: "de-patch-light", country: .de, types: [.patch], title: "2 steps from 14 mg",
                  labelNote: "German packs: fewer than 20 a day, start on 14 mg.",
                  steps: [PlanStep(strengthMg: 14, weeks: 4), PlanStep(strengthMg: 7, weeks: 4)],
                  source: HealthSources.dePatch),
    ]

    public static func presets(for type: NRTType, country: LabelCountry?) -> [NRTPreset] {
        guard let country else { return [] }
        return all.filter { $0.country == country && $0.types.contains(type) }
    }

    public static func preset(id: String?) -> NRTPreset? {
        all.first { $0.id == id }
    }

    /// Strengths on sale, for entering a pack's schedule by hand.
    public static func strengths(for type: NRTType) -> [Double] {
        switch type {
        case .patch: [25, 21, 15, 14, 10, 7]
        case .gum, .lozenge: [4, 2, 1.5]
        case .inhaler: [15, 10]
        }
    }
}

/// Where someone is in a list of steps, by date (S9.2, S9.3, S9.5).
public struct StepSchedule: Sendable {
    public struct Span: Sendable, Equatable {
        public let index: Int
        public let step: PlanStep
        /// First day of the step.
        public let start: Date
        /// First day after the step.
        public let end: Date
    }

    public let spans: [Span]
    public let clock: DayClock

    public init(startDate: Date, steps: [PlanStep], clock: DayClock) {
        self.clock = clock
        var day = clock.startOfDate(startDate)
        var spans: [Span] = []
        for (i, step) in steps.enumerated() {
            let end = clock.calendar.date(byAdding: .day, value: max(step.weeks, 0) * 7, to: day) ?? day
            spans.append(Span(index: i, step: step, start: day, end: end))
            day = end
        }
        self.spans = spans
    }

    public var start: Date? { spans.first?.start }
    /// First day after the last step.
    public var end: Date? { spans.last?.end }

    public var totalDays: Int {
        guard let start, let end else { return 0 }
        return clock.calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }

    /// The step running on the day containing `now`; nil before the start and after the end.
    public func current(at now: Date) -> Span? {
        let today = clock.day(containing: now)
        return spans.first { today >= $0.start && today < $0.end }
    }

    public func next(after span: Span) -> Span? {
        spans.indices.contains(span.index + 1) ? spans[span.index + 1] : nil
    }

    public func hasStarted(at now: Date) -> Bool {
        guard let start else { return false }
        return clock.day(containing: now) >= start
    }

    public func isFinished(at now: Date) -> Bool {
        guard let end else { return true }
        return clock.day(containing: now) >= end
    }

    /// 1-based day within the whole plan.
    public func dayNumber(at now: Date) -> Int {
        guard let start else { return 0 }
        return (clock.calendar.dateComponents([.day], from: start, to: clock.day(containing: now)).day ?? 0) + 1
    }

    /// Start days of the steps after the first, for step-down reminders.
    public var stepDownDays: [(Date, PlanStep)] {
        spans.dropFirst().map { ($0.start, $0.step) }
    }
}

/// The optional pouch taper (S9.3): it ends the day before Quit Day, and only runs if it fits.
public enum PouchTaperPlan {
    /// Halving from the onboarding strength down to about 1.5 mg, one week a step.
    public static func suggestedSteps(from strengthMg: Double) -> [PlanStep] {
        var steps: [PlanStep] = []
        var mg = strengthMg
        while mg > 1.5, steps.count < 4 {
            steps.append(PlanStep(strengthMg: mg, weeks: 1))
            mg = mg.rounded() / 2
        }
        steps.append(PlanStep(strengthMg: max(mg, 1), weeks: 1))
        return steps
    }

    /// The day the taper must start so it ends the day before Quit Day.
    public static func startDate(steps: [PlanStep], quitDay: Date, clock: DayClock) -> Date {
        let days = steps.reduce(0) { $0 + $1.weeks * 7 }
        return clock.calendar.date(byAdding: .day, value: -days, to: clock.startOfDate(quitDay)) ?? quitDay
    }

    /// Whether the taper fits between today and Quit Day.
    public static func fits(steps: [PlanStep], quitDay: Date, now: Date, clock: DayClock) -> Bool {
        startDate(steps: steps, quitDay: quitDay, clock: clock) >= clock.day(containing: now)
    }

    /// The earliest Quit Day that leaves room for the whole taper, starting today.
    public static func quitDayToFit(steps: [PlanStep], now: Date, clock: DayClock) -> Date {
        let days = steps.reduce(0) { $0 + $1.weeks * 7 }
        return clock.calendar.date(byAdding: .day, value: days, to: clock.day(containing: now)) ?? now
    }
}

/// The NRT and taper reminders to schedule (S9.4), worked out ahead so the app can refresh them each time it opens.
public enum NRTReminderPlan {
    public struct Reminder: Sendable, Equatable {
        public let id: String
        public let date: Date
        public let title: String
        public let body: String

        public init(id: String, date: Date, title: String, body: String) {
            self.id = id
            self.date = date
            self.title = title
            self.body = body
        }
    }

    /// How far ahead daily reminders are scheduled. iOS keeps at most 64 pending; this leaves room for the rest.
    public static let dailyDays = 14
    /// Waking hours for "time for a piece".
    public static let wakingHours = 8..<22
    /// Step-down reminders go out the evening before.
    public static let eveningHour = 19

    public static func reminders(for plan: NRTPlan, now: Date, clock: DayClock) -> [Reminder] {
        let schedule = StepSchedule(startDate: plan.startDate, steps: plan.steps, clock: clock)
        guard let end = schedule.end, clock.day(containing: now) < end else { return [] }
        let cal = clock.calendar
        let tag = plan.typeRaw + "." + String(Int(plan.createdAt.timeIntervalSince1970))
        var out: [Reminder] = []
        let today = clock.day(containing: now)

        if let minute = plan.dailyReminderMinute {
            for offset in 0..<dailyDays {
                guard let day = cal.date(byAdding: .day, value: offset, to: today), day < end,
                      day >= (schedule.start ?? day),
                      let at = cal.date(byAdding: .minute, value: minute, to: day), at > now else { continue }
                // Already ticked today: no reminder.
                if let checked = plan.lastCheckedDay, clock.day(containing: checked) == day { continue }
                if plan.type == .patch {
                    out.append(Reminder(id: "nrt.\(tag).daily.\(stamp(day, cal))", date: at,
                                        title: String(localized: "Fresh patch time"),
                                        body: String(localized: "Swap today's patch. Follow the label on your pack.")))
                } else {
                    out.append(Reminder(id: "nrt.\(tag).daily.\(stamp(day, cal))", date: at,
                                        title: String(localized: "Your \(String(localized: plan.type.title).lowercased()) plan"),
                                        body: String(localized: "Keep some with you today. Follow the label on your pack.")))
                }
            }
        }

        if let hours = plan.pieceReminderHours, hours > 0, plan.type == .gum || plan.type == .lozenge {
            for offset in 0..<2 {
                guard let day = cal.date(byAdding: .day, value: offset, to: today), day < end else { continue }
                for hour in stride(from: wakingHours.lowerBound + hours, to: wakingHours.upperBound, by: hours) {
                    guard let at = cal.date(byAdding: .hour, value: hour, to: day), at > now else { continue }
                    out.append(Reminder(id: "nrt.\(tag).piece.\(stamp(day, cal)).\(hour)", date: at,
                                        title: String(localized: "Time for a piece?"),
                                        body: String(localized: "If you need one now, as your pack's label says.")))
                }
            }
        }

        if plan.stepReminders {
            for (day, step) in schedule.stepDownDays {
                guard let before = cal.date(byAdding: .day, value: -1, to: day),
                      let at = cal.date(byAdding: .hour, value: eveningHour, to: before), at > now else { continue }
                out.append(Reminder(id: "nrt.\(tag).step.\(stamp(day, cal))", date: at,
                                    title: String(localized: "Tomorrow: your next step"),
                                    body: String(localized: "Your plan moves to \(strength(step.strengthMg)) tomorrow. Check your pack's label.")))
            }
        }
        return out
    }

    public static func reminders(for taper: PouchTaper, now: Date, clock: DayClock) -> [Reminder] {
        guard taper.stepReminders else { return [] }
        let schedule = StepSchedule(startDate: taper.startDate, steps: taper.steps, clock: clock)
        return schedule.stepDownDays.compactMap { day, step in
            guard let before = clock.calendar.date(byAdding: .day, value: -1, to: day),
                  let at = clock.calendar.date(byAdding: .hour, value: eveningHour, to: before), at > now else { return nil }
            return Reminder(id: "taper.step.\(stamp(day, clock.calendar))", date: at,
                            title: String(localized: "Tomorrow: \(strength(step.strengthMg)) pouches"),
                            body: String(localized: "Your taper steps down tomorrow. One step closer to Quit Day."))
        }
    }

    public static func strength(_ mg: Double) -> String {
        mg == mg.rounded() ? "\(Int(mg)) mg" : "\(mg.formatted(.number.precision(.fractionLength(1)))) mg"
    }

    private static func stamp(_ day: Date, _ cal: Calendar) -> String {
        let c = cal.dateComponents([.year, .month, .day], from: day)
        return String(format: "%04d%02d%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}
