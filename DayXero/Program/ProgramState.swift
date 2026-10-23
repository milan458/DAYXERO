import DayXeroCore
import Foundation

/// The program as both Home and the Program tab see it: schedule, what's done, what's open,
/// what needs the full program, and any replay owed after a break.
@MainActor
struct ProgramState {
    struct Row: Identifiable, Equatable {
        let day: ProgramDayID
        let lesson: LessonContent
        let availability: ProgramSchedule.Availability
        let needsUpgrade: Bool
        /// Calendar date the day lines up with (prep: the day it was or will be done on; quit days: their date).
        let date: Date?
        var id: String { day.description }
    }

    let schedule: ProgramSchedule
    let completed: Set<ProgramDayID>
    let replayDay: ProgramDayID?
    let product: Product
    let isPro: Bool
    let now: Date

    init(profile: UserProfile, isPro: Bool, now: Date = .now, calendar: Calendar = .current) {
        let clock = DayClock(calendar: calendar, boundaryHour: profile.dayBoundaryHour)
        schedule = ProgramSchedule(startedOn: profile.createdAt, quitDay: profile.quitDay, clock: clock)
        completed = profile.progress?.completedDayIDs ?? []
        replayDay = profile.progress?.replayDay
        product = profile.primaryProduct?.product ?? .cigarettes
        self.isPro = isPro
        self.now = now
    }

    var isFinished: Bool { schedule.featuredDay(completed: completed) == nil }

    func lesson(_ day: ProgramDayID) -> LessonContent {
        LessonLibrary.lesson(for: day, product: product)
    }

    func needsUpgrade(_ day: ProgramDayID) -> Bool {
        !isPro && !FreeTier.isFree(day, in: schedule.outline) && !completed.contains(day)
    }

    /// Availability, with a pending replay holding back everything after it (S5.7).
    func availability(_ day: ProgramDayID) -> ProgramSchedule.Availability {
        let base = schedule.availability(of: day, completed: completed, at: now)
        if replayDay != nil, base != .completed { return .locked }
        return base
    }

    func rows(_ phase: ProgramPhase) -> [Row] {
        schedule.outline.filter { $0.phase == phase }.map { day in
            Row(day: day, lesson: lesson(day), availability: availability(day), needsUpgrade: needsUpgrade(day), date: date(of: day))
        }
    }

    func date(of day: ProgramDayID) -> Date? {
        if let date = schedule.opensOn(day) { return date }
        let start = schedule.clock.startOfDate(schedule.quitDay)
        return schedule.clock.calendar.date(byAdding: .day, value: day.index - 1 - schedule.prepDays, to: start)
    }

    func position(_ day: ProgramDayID) -> String {
        switch day.phase {
        case .prep: String(localized: "Prep day \(day.index) of \(schedule.prepDays)")
        case .quit: String(localized: "Day \(day.index) of \(ProgramSchedule.quitWeekDays)")
        case .maintenance: String(localized: "Week \(day.index + 1)")
        }
    }

    /// Step to resume a lesson at, saved when someone closes the player mid-way.
    static func savedStep(for day: ProgramDayID) -> Int {
        UserDefaults.standard.integer(forKey: "dx.lessonStep.\(day.description)")
    }

    static func saveStep(_ step: Int, for day: ProgramDayID) {
        UserDefaults.standard.set(step, forKey: "dx.lessonStep.\(day.description)")
    }
}

/// Applies the pause-and-replay rule when the app opens (S5.7).
@MainActor
enum ProgramUpkeep {
    static func checkForBreak(_ profile: UserProfile, isPro: Bool, now: Date = .now) {
        guard let progress = profile.progress, progress.replayDay == nil else { return }
        let state = ProgramState(profile: profile, isPro: isPro, now: now)
        let lastActive = [progress.lastActiveAt, progress.completions.map(\.completedAt).max()].compactMap { $0 }.max()
        if let day = Inactivity.replayDue(lastActive: lastActive, lastCompleted: progress.lastCompleted,
                                          programFinished: state.isFinished, now: now, clock: state.schedule.clock) {
            progress.replayDay = day
        }
    }
}
