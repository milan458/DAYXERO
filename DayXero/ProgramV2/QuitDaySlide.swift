import DayXeroCore
import Foundation
import SwiftData

/// Day Xero follows prep (19 Nov 2026). Prep runs one session a day and Day Xero comes the day after the last one,
/// so when someone falls behind, the saved Day Xero moves back to the earliest date prep allows
/// (`ProgramUnlock.earliestDayXero`). Everything that reads `profile.quitDay` (Today's countdown, the widgets,
/// reminders) then agrees with what the program will open. It only ever moves the date later, and never once
/// Day Xero has been started.
enum QuitDaySlide {
    private static let movedToKey = "dx.quitDayMovedTo"
    private static let movedOnKey = "dx.quitDayMovedOn"

    /// The earliest Day Xero prep allows right now, nil when nothing holds it.
    @MainActor
    static func earliest(_ profile: UserProfile, in context: ModelContext, now: Date = .now) -> Date? {
        let store = ProgramStore(context: context, profile: profile)
        return store.unlock()?.earliestDayXero(records: store.unlockRecords(), quitTimestamp: profile.progress?.quitTimestamp, now: now)
    }

    /// Moves the Day Xero back if prep has fallen behind. Returns whether it moved.
    @MainActor
    @discardableResult
    static func apply(_ profile: UserProfile, in context: ModelContext, now: Date = .now) -> Bool {
        guard !DemoMode.isOn else { return false }
        #if DEBUG
        // Seeded screenshot scenarios keep the dates they were built with.
        if UserDefaults.standard.string(forKey: "dx.homeScenario") != nil { return false }
        #endif
        let clock = DayClock(boundaryHour: profile.dayBoundaryHour)
        guard let date = Self.earliest(profile, in: context, now: now), date > clock.startOfDate(profile.quitDay) else { return false }
        profile.quitDay = date
        try? context.save()
        UserDefaults.standard.set(date.timeIntervalSinceReferenceDate, forKey: movedToKey)
        UserDefaults.standard.set(clock.day(containing: now).timeIntervalSinceReferenceDate, forKey: movedOnKey)
        return true
    }

    /// Today's line on the day the date moved: "Your Day Xero moved to Fri, 27 Nov, so you get every prep session."
    static func note(now: Date = .now, clock: DayClock) -> String? {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: movedToKey) != nil, defaults.object(forKey: movedOnKey) != nil else { return nil }
        let movedOn = Date(timeIntervalSinceReferenceDate: defaults.double(forKey: movedOnKey))
        guard movedOn == clock.day(containing: now) else { return nil }
        let date = Date(timeIntervalSinceReferenceDate: defaults.double(forKey: movedToKey))
        return String(localized: "Your Day Xero moved to \(date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))), so you get every prep session.")
    }
}
