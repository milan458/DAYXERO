import Foundation

/// When each program v2 session opens (handoff section 3). Pure logic: no store, no clock of its own.
/// Sessions go strictly in order. Nothing here looks at slips: a slip never locks, delays or resets anything.
public struct ProgramUnlock: Sendable {
    public enum State: Equatable, Sendable {
        /// More than one step away. The title still shows.
        case locked
        /// Next up, waiting for a time.
        case scheduled(Wait)
        case available
        case inProgress
        case completed(Date)

        public var isOpen: Bool {
            switch self {
            case .available, .inProgress, .completed: true
            case .locked, .scheduled: false
            }
        }
    }

    public enum Wait: Equatable, Sendable {
        /// "Unlocks tomorrow".
        case tomorrow
        /// Day Xero waits for the Quit Day: "Day Xero is Thu, 12 Nov".
        case dayXero(Date)
        /// Opens this many days after Day Xero (the session's `minDay`). Shown with `counterDay`: "Unlocks on Day 11".
        case quitDay(Int)
    }

    /// The Today counter's number for the day that falls `daysSinceQuit` days after Day Xero. The counter calls
    /// Day Xero itself Day 1 (days clear), so a session with `minDay` 3 opens on Day 4.
    public static func counterDay(daysSinceQuit: Int) -> Int {
        daysSinceQuit + 1
    }

    public struct Record: Equatable, Sendable {
        public var startedAt: Date?
        public var completedAt: Date?

        public init(startedAt: Date? = nil, completedAt: Date? = nil) {
            self.startedAt = startedAt
            self.completedAt = completedAt
        }
    }

    public struct Step: Sendable {
        public let id: String
        public let rule: ProgramContent.Unlock.Rule
        public let minDay: Int?

        public init(id: String, rule: ProgramContent.Unlock.Rule, minDay: Int? = nil) {
            self.id = id
            self.rule = rule
            self.minDay = minDay
        }
    }

    public let steps: [Step]
    public let clock: DayClock

    public init(steps: [Step], clock: DayClock) {
        self.steps = steps
        self.clock = clock
    }

    public init(content: ProgramContent, clock: DayClock) {
        self.init(steps: content.sessions.map { Step(id: $0.id, rule: $0.unlock.rule, minDay: $0.unlock.minDay) }, clock: clock)
    }

    /// The day Day Xero opens: the later of the Quit Day and the day after the last prep session was finished.
    /// While prep isn't finished there's no date yet: Day Xero starts the morning after it is.
    public func dayXeroDate(quitDay: Date, prepFinishedAt: Date?) -> Date? {
        guard let prepFinishedAt else { return nil }
        let dayAfter = clock.calendar.date(byAdding: .day, value: 1, to: clock.day(containing: prepFinishedAt)) ?? prepFinishedAt
        return max(clock.startOfDate(quitDay), dayAfter)
    }

    /// Whole days since Day Xero was started (its commit set `quitTimestamp`): 0 on Day Xero itself, 1 the day after.
    public func daysSinceQuit(_ quitTimestamp: Date, now: Date) -> Int {
        clock.calendar.dateComponents([.day], from: clock.day(containing: quitTimestamp), to: clock.day(containing: now)).day ?? 0
    }

    /// Every session's state, in program order.
    /// - Parameters:
    ///   - records: started and finished times by session ID.
    ///   - quitDay: the Quit Day the person chose.
    ///   - quitTimestamp: when Day Xero's commit was held, if it has been.
    public func states(records: [String: Record], quitDay: Date, quitTimestamp: Date?, now: Date) -> [(id: String, state: State)] {
        var out: [(String, State)] = []
        var previousFinished: Date? = nil
        var waitingFound = false
        for (i, step) in steps.enumerated() {
            let record = records[step.id]
            if let done = record?.completedAt {
                out.append((step.id, .completed(done)))
                previousFinished = done
                continue
            }
            // Only the session after the last finished one can be open or waiting; the rest are locked.
            guard !waitingFound, i == 0 || previousFinished != nil else {
                out.append((step.id, .locked))
                continue
            }
            waitingFound = true
            let open: State = record?.startedAt != nil ? .inProgress : .available
            switch step.rule {
            case .first:
                out.append((step.id, open))
            case .nextDayAfterPrevious:
                let today = clock.day(containing: now)
                let finishedDay = clock.day(containing: previousFinished ?? now)
                out.append((step.id, today > finishedDay ? open : .scheduled(.tomorrow)))
            case .dayXero:
                let date = dayXeroDate(quitDay: quitDay, prepFinishedAt: previousFinished) ?? clock.startOfDate(quitDay)
                out.append((step.id, clock.day(containing: now) >= date ? open : .scheduled(.dayXero(date))))
            case .daysSinceQuit:
                let minDay = step.minDay ?? 0
                if let quitTimestamp, daysSinceQuit(quitTimestamp, now: now) >= minDay {
                    out.append((step.id, open))
                } else {
                    out.append((step.id, .scheduled(.quitDay(minDay))))
                }
            }
            previousFinished = nil
        }
        return out
    }

    /// The session to show on Home: the one open or waiting next, nil once everything is finished.
    public func current(records: [String: Record], quitDay: Date, quitTimestamp: Date?, now: Date) -> (id: String, state: State)? {
        states(records: records, quitDay: quitDay, quitTimestamp: quitTimestamp, now: now).first {
            if case .completed = $0.state { return false }
            return true
        }
    }
}
