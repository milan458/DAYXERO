import DayXeroCore
import Foundation
import Observation
import UserNotifications

/// Opens NRT setup and the pouch taper from Home, the slip talk-through and later Settings (S9).
@Observable @MainActor
final class NRTRouter {
    enum Sheet: String, Identifiable {
        case setup, taper
        var id: String { rawValue }
    }

    var sheet: Sheet?
}

/// Keeps NRT and taper reminders in step with the plans (S9.4). Daily reminders are scheduled two weeks ahead and
/// refreshed whenever the app becomes active or a plan changes.
@MainActor
enum NRTReminders {
    static func refresh(profile: UserProfile?, now: Date = .now) {
        var reminders: [NRTReminderPlan.Reminder] = []
        if let profile {
            let clock = DayClock(boundaryHour: profile.dayBoundaryHour)
            for plan in profile.nrtPlans { reminders += NRTReminderPlan.reminders(for: plan, now: now, clock: clock) }
            if let taper = profile.pouchTaper { reminders += NRTReminderPlan.reminders(for: taper, now: now, clock: clock) }
        }
        let wanted = reminders
        Task { await apply(wanted) }
    }

    static func requestPermissionIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        if await center.notificationSettings().authorizationStatus == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        }
    }

    private static func apply(_ reminders: [NRTReminderPlan.Reminder]) async {
        let center = UNUserNotificationCenter.current()
        let ours = await center.pendingNotificationRequests().map(\.identifier).filter { $0.hasPrefix("nrt.") || $0.hasPrefix("taper.") }
        center.removePendingNotificationRequests(withIdentifiers: ours)
        guard await center.notificationSettings().authorizationStatus != .denied else { return }
        for reminder in reminders {
            let content = UNMutableNotificationContent()
            content.title = reminder.title
            content.body = reminder.body
            content.sound = .default
            let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.date)
            let request = UNNotificationRequest(identifier: reminder.id, content: content,
                                                trigger: UNCalendarNotificationTrigger(dateMatching: parts, repeats: false))
            try? await center.add(request)
        }
    }
}
