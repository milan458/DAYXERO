import Foundation

/// When each program v2 session opens (handoff section 3). Pure logic: no store, no clock of its own.
/// Sessions go in order within two chains, prep and Day Xero onwards (see `states`). Nothing here looks at slips:
/// a slip never locks, delays or resets anything.
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
        /// Day Xero waits for the Quit Day: "Day Xero is Thu, 12 Nov". Its date is always the Quit Day (S27.7).
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
        /// When a free user reached the prep-day paywall after the session's free cards (BET-1). For prep it moves the
        /// chain on like finishing would (the next prep session opens the next day) while the session itself stays
        /// open, so it can be finished in full after subscribing.
        public var previewedAt: Date?

        public init(startedAt: Date? = nil, completedAt: Date? = nil, previewedAt: Date? = nil) {
            self.startedAt = startedAt
            self.completedAt = completedAt
            self.previewedAt = previewedAt
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

    /// The day Day Xero opens: the start of the Quit Day the person chose, whatever prep is done (S27.7).
    /// Unfinished prep doesn't move it; those sessions stay open as catch-up.
    public func dayXeroDate(quitDay: Date) -> Date {
        clock.startOfDate(quitDay)
    }

    /// Whole days since Day Xero was started (its commit set `quitTimestamp`): 0 on Day Xero itself, 1 the day after.
    public func daysSinceQuit(_ quitTimestamp: Date, now: Date) -> Int {
        clock.calendar.dateComponents([.day], from: clock.day(containing: quitTimestamp), to: clock.day(containing: now)).day ?? 0
    }

    /// Every session's state, in program order.
    ///
    /// Two chains (S27.7). Prep runs one session a day after the last, in order. Day Xero opens at the start of the
    /// Quit Day whether prep is finished or not, and the week sessions follow it, in order, by days since Day Xero.
    /// Prep left unfinished on the Quit Day becomes catch-up: the next prep session is open straight away (no
    /// one-a-day wait) and never blocks Day Xero or the weeks. Before the Quit Day, Day Xero shows as waiting only
    /// once prep is finished, so Home shows the next prep session first.
    /// - Parameters:
    ///   - records: started and finished times by session ID.
    ///   - quitDay: the Quit Day the person chose.
    ///   - quitTimestamp: when Day Xero's commit was held, if it has been.
    public func states(records: [String: Record], quitDay: Date, quitTimestamp: Date?, now: Date) -> [(id: String, state: State)] {
        var out: [(String, State)] = []
        var previousFinished: Date? = nil
        var waitingFound = false
        let dayXeroIndex = steps.firstIndex { $0.rule == .dayXero }
        let opensOn = dayXeroDate(quitDay: quitDay)
        let today = clock.day(containing: now)
        let quitDayHasCome = today >= opensOn
        for (i, step) in steps.enumerated() {
            let record = records[step.id]
            let open: State = record?.startedAt != nil ? .inProgress : .available
            if i == dayXeroIndex {
                // Day Xero starts its own chain: it never waits for prep.
                let prepDone = !waitingFound && (i == 0 || previousFinished != nil)
                waitingFound = false
                if let done = record?.completedAt {
                    out.append((step.id, .completed(done)))
                    previousFinished = done
                    continue
                }
                if quitDayHasCome {
                    out.append((step.id, open))
                } else {
                    out.append((step.id, prepDone ? .scheduled(.dayXero(opensOn)) : .locked))
                }
                waitingFound = true
                previousFinished = nil
                continue
            }
            if let done = record?.completedAt {
                out.append((step.id, .completed(done)))
                previousFinished = done
                continue
            }
            // A prep session whose free part was read (BET-1) stays open and lets the next one follow, a day later.
            let isPrepStep = dayXeroIndex.map { i < $0 } ?? false
            if isPrepStep, let previewed = record?.previewedAt, !waitingFound, i == 0 || previousFinished != nil {
                out.append((step.id, open))
                previousFinished = previewed
                continue
            }
            // Within a chain, only the session after the last finished one can be open or waiting.
            guard !waitingFound, i == 0 || previousFinished != nil else {
                out.append((step.id, .locked))
                continue
            }
            waitingFound = true
            switch step.rule {
            case .first:
                out.append((step.id, open))
            case .nextDayAfterPrevious:
                let finishedDay = clock.day(containing: previousFinished ?? now)
                // Prep catch-up after the Quit Day has no one-a-day wait.
                let isPrep = dayXeroIndex.map { i < $0 } ?? false
                let ready = today > finishedDay || (isPrep && quitDayHasCome)
                out.append((step.id, ready ? open : .scheduled(.tomorrow)))
            case .dayXero:
                // Only the first Day Xero step starts a chain; a second one (not expected) opens on the Quit Day too.
                out.append((step.id, quitDayHasCome ? open : .scheduled(.dayXero(opensOn))))
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
        let previewed = Set(records.filter { $0.value.previewedAt != nil && $0.value.completedAt == nil }.keys)
        return current(of: states(records: records, quitDay: quitDay, quitTimestamp: quitTimestamp, now: now), skipping: previewed)
    }

    /// The session to show on Home, from `states` (S27.7). Once Day Xero is open, its chain comes first: the chain's
    /// open session, then any open prep catch-up, then what the chain is waiting for. Before that, the first
    /// session not finished. nil once everything is finished.
    /// - Parameter skipping: prep sessions whose free part was read (BET-1). Home moves past them to the next session;
    ///   they stay open on the Program path. If nothing else is pending, the first of them is shown.
    public func current(of states: [(id: String, state: State)], skipping: Set<String> = []) -> (id: String, state: State)? {
        let unfinished = states.enumerated().filter {
            if case .completed = $0.element.state { return false }
            return true
        }
        let pending = unfinished.contains { !skipping.contains($0.element.id) } ? unfinished.filter { !skipping.contains($0.element.id) } : unfinished
        guard let dx = steps.firstIndex(where: { $0.rule == .dayXero }), dx < states.count, states[dx].state.isOpen else {
            return pending.first?.element
        }
        let chain = pending.filter { $0.offset >= dx }
        if let open = chain.first(where: { $0.element.state.isOpen }) { return open.element }
        if let catchUp = pending.first(where: { $0.offset < dx && $0.element.state.isOpen }) { return catchUp.element }
        return (chain.first ?? pending.first)?.element
    }
}
