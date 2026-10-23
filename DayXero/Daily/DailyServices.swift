import DayXeroCore
import Foundation
import SwiftData
import UIKit
import UserNotifications

/// Notification settings (S14.2), kept on the device. Times are minutes after midnight; -1 means off.
enum DailyReminderSettings {
    static let pledgeKey = "dx.pledgeReminderMinute"
    static let checkInKey = "dx.checkInReminderMinute"
    static let lessonKey = "dx.lessonReminderMinute"
    static let milestoneKey = "dx.milestoneReminderMinute"
    static let awayKey = "dx.awayNotes"
    static let quietStartKey = "dx.quietStart"
    static let quietEndKey = "dx.quietEnd"
    static let nrtThroughQuietKey = "dx.nrtThroughQuiet"
    static let nrtOnKey = "dx.nrtNotifications"

    static let defaultPledge = 8 * 60
    static let defaultCheckIn = 21 * 60
    static let defaultLesson = 12 * 60
    static let defaultMilestone = 9 * 60
    static let defaultQuietStart = 22 * 60 + 30
    static let defaultQuietEnd = 7 * 60 + 30

    static var pledgeMinute: Int? { minute(pledgeKey, defaultPledge) }
    static var checkInMinute: Int? { minute(checkInKey, defaultCheckIn) }

    static var plan: NotificationPlan.Settings {
        var s = NotificationPlan.Settings()
        s.pledge = minute(pledgeKey, defaultPledge)
        s.checkIn = minute(checkInKey, defaultCheckIn)
        s.lesson = minute(lessonKey, defaultLesson)
        s.milestone = minute(milestoneKey, defaultMilestone)
        s.awayOn = flag(awayKey)
        s.quietStart = minute(quietStartKey, defaultQuietStart)
        s.quietEnd = minute(quietEndKey, defaultQuietEnd)
        return s
    }

    static var nrtOn: Bool { flag(nrtOnKey) }
    static var nrtThroughQuiet: Bool { flag(nrtThroughQuietKey) }

    private static func minute(_ key: String, _ fallback: Int) -> Int? {
        let stored = UserDefaults.standard.object(forKey: key) as? Int ?? fallback
        return stored < 0 ? nil : stored
    }

    /// On unless switched off.
    private static func flag(_ key: String) -> Bool {
        UserDefaults.standard.object(forKey: key) as? Bool ?? true
    }
}

/// Schedules the program's notifications from the plan (S14.1): today and tomorrow's reminders, lesson and
/// milestone days, then two gentle away notes. Refreshed every time the app opens or something is done.
@MainActor
enum DailyReminders {
    /// Last known Pro status, so a locked lesson is never announced as ready.
    static var isPro = false

    static func refresh(in context: ModelContext, now: Date = .now) {
        guard let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first else { return }
        let clock = DayClock(boundaryHour: profile.dayBoundaryHour)
        let rhythm = DailyRhythm(clock: clock)
        let pledges = (try? context.fetch(FetchDescriptor<Pledge>()))?.map(\.day) ?? []
        let checkIns = (try? context.fetch(FetchDescriptor<CheckIn>()))?.map(\.day) ?? []
        let inputs = NotificationPlan.Inputs(
            now: now,
            pledgedToday: rhythm.hasPledged(pledges, at: now),
            checkedInToday: rhythm.hasCheckedIn(checkIns, at: now),
            lessons: lessons(profile: profile, clock: clock, now: now),
            milestones: milestones(profile: profile, clock: clock),
            replayName: profile.progress?.lastCompleted.map(name),
            nextLessonName: nextLesson(profile: profile, clock: clock).map(name)
        )
        let wanted = NotificationPlan.plan(DailyReminderSettings.plan, inputs: inputs, calendar: .current)
        Task { await apply(wanted) }
    }

    /// The day a lesson becomes available (or today, if it's waiting), within the next two days.
    private static func lessons(profile: UserProfile, clock: DayClock, now: Date) -> [(day: Date, name: String, minutes: Int)] {
        guard let day = nextLesson(profile: profile, clock: clock) else { return [] }
        let schedule = ProgramSchedule(startedOn: profile.createdAt, quitDay: profile.quitDay, clock: clock)
        let completed = profile.progress?.completedDayIDs ?? []
        let minutes = LessonLibrary.lesson(for: day, product: profile.primaryProduct?.product ?? .cigarettes).minutes
        if !isPro && !FreeTier.isFree(day, in: schedule.engine.outline) { return [] }
        switch schedule.availability(of: day, completed: completed, at: now) {
        case .available: return [(clock.day(containing: now), name(day), minutes)]
        case let .opensOn(date): return [(date, name(day), minutes)]
        case .completed, .locked: return []
        }
    }

    private static func nextLesson(profile: UserProfile, clock: DayClock) -> ProgramDayID? {
        let schedule = ProgramSchedule(startedOn: profile.createdAt, quitDay: profile.quitDay, clock: clock)
        return schedule.featuredDay(completed: profile.progress?.completedDayIDs ?? [])
    }

    private static func milestones(profile: UserProfile, clock: DayClock) -> [(day: Date, title: String)] {
        let quit = clock.startOfDate(profile.quitDay)
        return Milestone.all.compactMap { m in
            clock.calendar.date(byAdding: .day, value: m.reachedOnDay - 1, to: quit).map { ($0, m.title) }
        }
    }

    private static func name(_ day: ProgramDayID) -> String {
        switch day.phase {
        case .prep: String(localized: "Prep day \(day.index)")
        case .quit: String(localized: "Day \(day.index)")
        case .maintenance: String(localized: "Week \(day.index + 1)")
        }
    }

    private static func apply(_ notifications: [NotificationPlan.Notification]) async {
        let center = UNUserNotificationCenter.current()
        // "daily." ids are from before Section 14; clear them too.
        let ours = await center.pendingNotificationRequests().map(\.identifier).filter { $0.hasPrefix("prog.") || $0.hasPrefix("daily.") }
        center.removePendingNotificationRequests(withIdentifiers: ours)
        guard await center.notificationSettings().authorizationStatus != .denied else { return }
        for n in notifications {
            let content = UNMutableNotificationContent()
            content.title = n.title
            content.body = n.body
            content.userInfo = ["kind": n.kind.rawValue]
            let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: n.date)
            try? await center.add(UNNotificationRequest(identifier: n.id, content: content,
                                                        trigger: UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)))
        }
    }
}
