import DayXeroCore
import Foundation
import SwiftData
import WidgetKit

/// Builds the widget snapshot from the store and reloads only the widgets whose data changed (S17.1).
/// RootView calls `refresh` after every save and when the app comes and goes.
@MainActor
enum WidgetSync {
    static let privacyKey = "dx.widgetPrivacy"
    static let privacyHomeKey = "dx.widgetPrivacyHome"

    static func refresh(in context: ModelContext, isPro: Bool, now: Date = .now) {
        guard let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first else { return }
        let snapshot = make(profile: profile, context: context, isPro: isPro, now: now)
        let old = WidgetSnapshot.load()
        snapshot.save()
        for kind in changedKinds(old, snapshot) {
            WidgetCenter.shared.reloadTimelines(ofKind: kind)
        }
    }

    static func make(profile: UserProfile, context: ModelContext, isPro: Bool, now: Date) -> WidgetSnapshot {
        let clock = DayClock(boundaryHour: profile.dayBoundaryHour)
        let stats = ProgressStats(quitDay: profile.quitDay, baselines: profile.products.map(\.baseline), clock: clock)
        let home = HomeSnapshot(profile: profile, isPro: isPro, now: now)
        let today = clock.day(containing: now)
        let nextDay = clock.calendar.date(byAdding: .day, value: 1, to: today) ?? today
        // The day boundary shifts the day's start (e.g. 4am), which is when "into the day" starts counting.
        let dayStart = clock.calendar.date(byAdding: .hour, value: profile.dayBoundaryHour, to: today) ?? today
        let nextDayStart = clock.calendar.date(byAdding: .hour, value: profile.dayBoundaryHour, to: nextDay) ?? nextDay

        let logs = (try? context.fetch(FetchDescriptor<LogEntry>())) ?? []
        let ridden = logs.filter { $0.kind == .craving && $0.outcome == .passed }.count
        let isPrep = stats.isPrep(at: now)
        let predictorEvents = logs
            .filter { $0.kind == .craving || $0.kind == .slip || (isPrep && $0.kind == .use) }
            .map { CravingPredictor.Event(date: $0.timestamp, trigger: $0.trigger) }

        let water = WaterDay.entries((try? context.fetch(FetchDescriptor<WaterEntry>())) ?? [], on: today, clock: clock)
        let waterGoal = (try? context.fetch(FetchDescriptor<WaterProfile>()).first)?.effectiveGoalMl ?? WaterGoal.skippedMl

        let phase: WidgetSnapshot.Phase
        let store = ProgramStore(context: context, profile: profile)
        if store.records().allSatisfy({ $0.completedAt == nil }), isPrep {
            phase = .beforeDay1
        } else if isPrep {
            phase = .prep
        } else if stats.daysClear(at: now) > ProgramSchedule.quitWeekDays + 28 {
            phase = .after
        } else {
            phase = .quit
        }
        // The program session open now, if any.
        let lesson: WidgetSnapshot.Lesson? = store.current(now: now).flatMap { current in
            guard current.state == .available || current.state == .inProgress, let session = store.content?.session(current.id) else { return nil }
            return WidgetSnapshot.Lesson(title: session.title.resolve(store.variant) ?? "", minutes: session.durationMinutes)
        }
        let defaults = UserDefaults.standard
        return WidgetSnapshot(
            phase: phase,
            quitDate: profile.quitDay,
            prepDay: home.prepDayNumber,
            daysUntilQuitDay: isPrep ? stats.daysUntilQuitDay(at: now) : 0,
            daysFree: isPrep ? 0 : stats.daysClear(at: now),
            currentDayStart: dayStart,
            nextDayStart: nextDayStart,
            moneyKept: NSDecimalNumber(decimal: stats.moneyKept(at: now)).doubleValue,
            currencyCode: profile.currencyCode,
            cravingsRidden: ridden,
            waterCountedMl: water.reduce(0) { $0 + $1.countedMl },
            waterGoalMl: waterGoal,
            lastDrinkId: water.last?.drinkId ?? Drink.glass.rawValue,
            nextWindow: CravingPredictor.nextWindow(events: predictorEvents, now: now),
            nextLesson: lesson,
            nextMilestone: home.nextMilestone,
            privacyMode: defaults.bool(forKey: privacyKey),
            privacyOnHomeScreen: defaults.bool(forKey: privacyHomeKey),
            updatedAt: now
        )
    }

    /// Which widgets need a reload, so a water log doesn't reload the day counter.
    private static func changedKinds(_ old: WidgetSnapshot?, _ new: WidgetSnapshot) -> [String] {
        guard let old else { return WidgetSnapshot.Kind.all }
        typealias K = WidgetSnapshot.Kind
        var kinds = Set<String>()
        if old.phase != new.phase || old.daysFree != new.daysFree || old.daysUntilQuitDay != new.daysUntilQuitDay
            || old.privacyMode != new.privacyMode || old.privacyOnHomeScreen != new.privacyOnHomeScreen {
            kinds.formUnion(K.all)
        }
        if Int(old.moneyKept) != Int(new.moneyKept) { kinds.formUnion([K.days, K.today]) }
        if old.cravingsRidden != new.cravingsRidden || old.nextLesson != new.nextLesson { kinds.insert(K.today) }
        if old.waterCountedMl != new.waterCountedMl || old.waterGoalMl != new.waterGoalMl || old.lastDrinkId != new.lastDrinkId {
            kinds.formUnion([K.water, K.today])
        }
        if old.nextWindow != new.nextWindow { kinds.formUnion([K.forecast, K.today]) }
        return Array(kinds)
    }
}
