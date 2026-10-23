import DayXeroCore
import Foundation
import SwiftData
import UserNotifications

/// Pledge and check-in reminder settings (S11.4). On by default after onboarding; minutes after midnight, -1 for off.
enum DailyReminderSettings {
    static let pledgeKey = "dx.pledgeReminderMinute"
    static let checkInKey = "dx.checkInReminderMinute"
    static let defaultPledge = 8 * 60
    static let defaultCheckIn = 21 * 60

    static var pledgeMinute: Int? { value(pledgeKey, default: defaultPledge) }
    static var checkInMinute: Int? { value(checkInKey, default: defaultCheckIn) }

    private static func value(_ key: String, default fallback: Int) -> Int? {
        let stored = UserDefaults.standard.object(forKey: key) as? Int ?? fallback
        return stored < 0 ? nil : stored
    }
}

/// Schedules the coming week's pledge and check-in reminders, skipping today's once it's done.
@MainActor
enum DailyReminders {
    static func refresh(in context: ModelContext, now: Date = .now) {
        let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first
        guard let profile else { return }
        let rhythm = DailyRhythm(clock: DayClock(boundaryHour: profile.dayBoundaryHour))
        let pledges = (try? context.fetch(FetchDescriptor<Pledge>()))?.map(\.day) ?? []
        let checkIns = (try? context.fetch(FetchDescriptor<CheckIn>()))?.map(\.day) ?? []
        let wanted = rhythm.reminders(pledgeMinute: DailyReminderSettings.pledgeMinute,
                                      checkInMinute: DailyReminderSettings.checkInMinute,
                                      pledgedToday: rhythm.hasPledged(pledges, at: now),
                                      checkedInToday: rhythm.hasCheckedIn(checkIns, at: now), now: now)
        Task { await apply(wanted) }
    }

    private static func apply(_ reminders: [DailyRhythm.Reminder]) async {
        let center = UNUserNotificationCenter.current()
        let ours = await center.pendingNotificationRequests().map(\.identifier).filter { $0.hasPrefix("daily.") }
        center.removePendingNotificationRequests(withIdentifiers: ours)
        guard await center.notificationSettings().authorizationStatus != .denied else { return }
        for reminder in reminders {
            let content = UNMutableNotificationContent()
            content.title = reminder.title
            content.body = reminder.body
            let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.date)
            try? await center.add(UNNotificationRequest(identifier: reminder.id, content: content,
                                                        trigger: UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)))
        }
    }
}
