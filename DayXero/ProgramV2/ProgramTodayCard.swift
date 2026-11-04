import DayXeroCore
import SwiftData
import SwiftUI

/// Which session to open, and whether as a replay.
struct SessionOpen: Identifiable, Hashable {
    let id: String
    var isReplay = false
}

/// Free tier (MON-01): the counter, Craving SOS, the 60-second breathing timer and Prep 1 to 3. Prep 4 onwards needs
/// Pro or the 7-day trial, which is sold at the Prep 4 paywall whenever the Quit Day is. See `FullProgram`.
enum ProgramV2Access {
    static var freeSessions: Set<String> { FullProgram.freeSessionIds }
    /// The Day Xero session: its completion is the sun moment, and anyone still without the full program gets the
    /// Quit Day offer after it once (decision 23). Under MON-01 Day Xero is paid, so that only happens to someone
    /// whose subscription ended part-way.
    static let offerAfter = "DX"

    static func needsUpgrade(_ sessionId: String, isPro: Bool) -> Bool {
        !DemoMode.isOn && FullProgram.needsUpgrade(sessionId: sessionId, isPro: isPro)
    }
}

/// What Home's Today card shows (handoff 4.5).
struct ProgramToday {
    enum Kind: Equatable {
        /// "Prep 3 · 6 min · Start", or Continue.
        case open(sessionId: String, inProgress: Bool, needsUpgrade: Bool)
        /// Done for today: the mission, and when the next session comes.
        case waiting(next: String)
        case complete
    }

    let kind: Kind
    let label: String
    let title: String
    let minutes: Int
    /// The latest finished session's mission, shown until the next session opens.
    let mission: String?
    /// Quit Day has come and this is a prep session left over: catch-up that never holds back Day Xero (S27.7).
    let prepRunsOver: Bool
    /// A quit-week session from an earlier day. Today's header counts "Day 3" by the calendar, so a "Day 2" session
    /// is labelled a catch-up rather than "Today", and the screen never shows two different days as today (S27.5).
    /// Prep left over after the Quit Day is a catch-up too (S27.7).
    let isCatchUp: Bool

    @MainActor
    init?(store: ProgramStore, isPro: Bool, now: Date = .now) {
        guard let content = store.content else { return nil }
        let variant = store.variant
        let lastDone = store.records().filter { $0.completedAt != nil }.max { ($0.completedAt ?? .distantPast) < ($1.completedAt ?? .distantPast) }
        let lastSession = lastDone.flatMap { content.session($0.sessionId) }
        mission = lastSession?.mission.map { store.placeholders(now: now).fillDropping($0.text.resolve(variant) ?? "") }
        guard let current = store.current(now: now), let session = content.session(current.id) else {
            kind = .complete
            label = ""
            title = ""
            minutes = 0
            prepRunsOver = false
            isCatchUp = false
            return
        }
        label = session.label
        title = session.title.resolve(variant) ?? ""
        minutes = store.minutes(of: session)
        prepRunsOver = session.phaseId == "prep" && store.clock.day(containing: now) >= store.clock.startOfDate(store.profile.quitDay)
        if prepRunsOver {
            isCatchUp = true
        } else if session.phaseId == "w1", session.unlock.rule == .daysSinceQuit, let minDay = session.unlock.minDay,
           let quit = store.profile.progress?.quitTimestamp, let engine = store.unlock() {
            isCatchUp = engine.daysSinceQuit(quit, now: now) > minDay
        } else {
            isCatchUp = false
        }
        switch current.state {
        case .available, .inProgress:
            kind = .open(sessionId: session.id, inProgress: current.state == .inProgress,
                         needsUpgrade: ProgramV2Access.needsUpgrade(session.id, isPro: isPro))
        case let .scheduled(wait):
            let next: String = switch wait {
            case .tomorrow: String(localized: "Next session tomorrow")
            case let .dayXero(date): String(localized: "Day Xero is \(date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))")
            case let .quitDay(days): String(localized: "Next session on Day \(ProgramUnlock.counterDay(daysSinceQuit: days))")
            }
            kind = .waiting(next: next)
        case .locked, .completed:
            kind = .complete
        }
    }
}

// Today draws the session with `TodaySessionCard` (DayXero/Home/TodayTimeline.swift) and owns opening it, its
// upgrade sheet and the queued first session, so a session survives the card moving between the focus slot and the
// timeline at 6 PM.
