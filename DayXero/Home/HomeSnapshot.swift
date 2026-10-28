import DayXeroCore
import Foundation

/// Placeholder lesson titles until the Flutter content is ported (S5.1).
enum LessonCatalog {
    static func title(for day: ProgramDayID) -> String {
        switch day.phase {
        case .prep: String(localized: "Prep day \(day.index)")
        case .quit: day.index == 1 ? String(localized: "Your Quit Day plan") : String(localized: "Day \(day.index)")
        case .maintenance: String(localized: "Week \(day.index + 1)")
        }
    }
}

/// Everything the Today tab shows, computed from the profile at a moment in time.
struct HomeSnapshot {
    enum Phase: Equatable {
        case prep(daysUntilQuitDay: Int)
        case quitDay
        case quitWeek(day: Int)
        case after(daysClear: Int)
    }

    struct Counter: Identifiable, Equatable {
        let product: Product
        let avoided: Int
        let perDayBefore: Int
        var id: Product { product }
    }

    struct Lesson: Equatable {
        let day: ProgramDayID
        let title: String
        let availability: ProgramSchedule.Availability
        /// e.g. "Prep day 4 of 7", "Day 3 of 7", "Week 2".
        let position: String
        let needsUpgrade: Bool
        /// Replaying the last finished day after a break (S5.7).
        var isReplay = false
        /// Step to resume at when the lesson was left part-way.
        var resumeStep = 0
        var placeholder = false
    }

    let phase: Phase
    let daysClear: Int
    let weekStrip: [DXWeekDay]
    let lesson: Lesson?
    /// The lesson finished most recently today, for the "done" state.
    let finishedToday: ProgramDayID?
    let counters: [Counter]
    let moneyKept: Decimal
    let moneyPerYear: Decimal
    let currencyCode: String
    let prepDone: Int
    let prepTotal: Int
    /// Which prep day today is on the calendar (Day 1 is the day onboarding finished).
    let prepDayNumber: Int
    let programFraction: Double
    /// Quit-week lessons done, out of seven.
    let quitWeekDone: Int
    let nextMilestone: Int?
    /// Progress from the previous milestone to the next, for the after-quit-week bar.
    let milestoneFraction: Double
    /// Program days done out of those due before today, 0...1 (S19.4).
    let adherence: Double
    /// Days in a row with a lesson done (S19.4).
    let lessonStreak: Int

    @MainActor
    init(profile: UserProfile, isPro: Bool, now: Date = .now, calendar: Calendar = .current) {
        let clock = DayClock(calendar: calendar, boundaryHour: profile.dayBoundaryHour)
        let stats = ProgressStats(quitDay: profile.quitDay, baselines: profile.products.map(\.baseline), clock: clock)
        let schedule = ProgramSchedule(startedOn: profile.createdAt, quitDay: profile.quitDay, clock: clock)
        let completions = profile.progress?.completions ?? []
        let completed = Set(completions.compactMap(\.dayID))
        let today = clock.day(containing: now)
        let quitDate = clock.startOfDate(profile.quitDay)

        daysClear = stats.daysClear(at: now)
        if stats.isPrep(at: now) {
            phase = .prep(daysUntilQuitDay: stats.daysUntilQuitDay(at: now))
        } else if daysClear == 1 {
            phase = .quitDay
        } else if daysClear <= ProgramSchedule.quitWeekDays {
            phase = .quitWeek(day: daysClear)
        } else {
            phase = .after(daysClear: daysClear)
        }

        // Prep: the next seven days from today. After that: the calendar week around today.
        let stripStart: Date
        if case .prep = phase {
            stripStart = today
        } else {
            stripStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        }
        weekStrip = (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: stripStart) else { return nil }
            let state: DXDayState
            if date == today { state = .today }
            else if date < quitDate { state = .prep }
            else if date < today { state = .clear }
            else { state = date == quitDate ? .quitDay : .upcoming }
            return DXWeekDay(date: date, state: state)
        }

        let program = ProgramState(profile: profile, isPro: isPro, now: now, calendar: calendar)
        if let replay = program.replayDay {
            let content = program.lesson(replay)
            lesson = Lesson(day: replay, title: content.title, availability: .available,
                            position: program.position(replay), needsUpgrade: false, isReplay: true,
                            resumeStep: ProgramState.savedStep(for: replay), placeholder: content.placeholder)
        } else if let day = schedule.featuredDay(completed: completed) {
            let content = program.lesson(day)
            lesson = Lesson(
                day: day,
                title: content.title,
                availability: schedule.availability(of: day, completed: completed, at: now),
                position: program.position(day),
                needsUpgrade: program.needsUpgrade(day) && schedule.engine.canStart(day, completed: completed),
                resumeStep: ProgramState.savedStep(for: day),
                placeholder: content.placeholder
            )
        } else {
            lesson = nil
        }
        finishedToday = completions
            .filter { clock.day(containing: $0.completedAt) == today }
            .max { $0.completedAt < $1.completedAt }?.dayID

        let avoided = stats.unitsAvoided(at: now)
        // Primary product first, then the others in their usual order.
        counters = profile.products
            .sorted { ($0.isPrimary ? 0 : 1, Product.allCases.firstIndex(of: $0.product)!) < ($1.isPrimary ? 0 : 1, Product.allCases.firstIndex(of: $1.product)!) }
            .map { Counter(product: $0.product, avoided: avoided[$0.product] ?? 0, perDayBefore: Int($0.unitsPerDay)) }
        moneyKept = stats.moneyKept(at: now)
        moneyPerYear = stats.moneyPerYear
        currencyCode = profile.currencyCode
        prepTotal = schedule.prepDays
        prepDone = completed.filter { $0.phase == .prep }.count
        prepDayNumber = (calendar.dateComponents([.day], from: clock.startOfDate(profile.createdAt), to: today).day ?? 0) + 1
        programFraction = schedule.engine.fractionComplete(completed: completed)
        quitWeekDone = completed.filter { $0.phase == .quit }.count
        nextMilestone = Milestones.next(after: daysClear)
        if let next = nextMilestone {
            let previous = Milestones.previous(atOrBefore: daysClear)
            milestoneFraction = Double(daysClear - previous) / Double(max(next - previous, 1))
        } else {
            milestoneFraction = 1
        }
        adherence = Adherence.fraction(schedule: schedule, startedOn: profile.createdAt, completed: completed, now: now)
        lessonStreak = Adherence.streak(completedAt: completions.map(\.completedAt), clock: clock, now: now)
    }

    static func greeting(at date: Date, calendar: Calendar = .current) -> String {
        switch calendar.component(.hour, from: date) {
        case 5..<12: String(localized: "Good morning")
        case 12..<17: String(localized: "Good afternoon")
        case 17..<22: String(localized: "Good evening")
        default: String(localized: "Hi")
        }
    }
}
