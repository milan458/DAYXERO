#if DEBUG
import DayXeroCore
import Foundation
import SwiftData
import UIKit

/// Sample people at different points in the program, for CI screenshots
/// (`-dx.homeScenario prep|quitday|day3|done|day12|free|returning`). Seeds an in-memory store only.
enum DebugScenario: String {
    case prep, quitday, day3, done, day12, free
    /// Back after a 4-day break: the program owes a replay (S5.7).
    case returning

    static var current: DebugScenario? {
        UserDefaults.standard.string(forKey: "dx.homeScenario").flatMap(DebugScenario.init(rawValue:))
    }

    @MainActor
    func seed(into container: ModelContainer, now: Date = .now, calendar: Calendar = .current) {
        let today = calendar.startOfDay(for: now)
        func day(_ offset: Int) -> Date { calendar.date(byAdding: .day, value: offset, to: today) ?? today }

        // (started onboarding, Quit Day) relative to today
        let (start, quit): (Int, Int) = switch self {
        case .prep: (-3, 4)
        case .quitday: (-7, 0)
        case .day3, .done: (-9, -2)
        case .day12: (-18, -11)
        case .free: (-1, 5)
        case .returning: (-13, -6)
        }

        let context = ModelContext(container)
        let profile = UserProfile(name: "Milan", quitDay: day(quit), currencyCode: "USD", createdAt: day(start).addingTimeInterval(9 * 3600))
        context.insert(profile)
        profile.products.append(ProductUse(product: .vape, isPrimary: true, unitsPerDay: 200, pricePerPurchase: 8.5, unitsPerPurchase: 600))
        if self != .free {
            profile.products.append(ProductUse(product: .cigarettes, isPrimary: false, unitsPerDay: 6, pricePerPurchase: 15, unitsPerPurchase: 20))
        }
        let reasonsAt = day(start).addingTimeInterval(9 * 3600)
        if UserDefaults.standard.bool(forKey: "dx.seedPouches") {
            profile.products.append(ProductUse(product: .pouches, isPrimary: false, unitsPerDay: 8, pricePerPurchase: 6,
                                               unitsPerPurchase: 20, strengthMg: 6))
        }
        // A patch plan from the 10-week US label, started on Quit Day (S9).
        if UserDefaults.standard.bool(forKey: "dx.seedNRT") {
            profile.nrtInterest = .using
            profile.nrtPlans.append(NRTPlan(type: .patch, startDate: day(quit),
                                            steps: [PlanStep(strengthMg: 21, weeks: 6), PlanStep(strengthMg: 14, weeks: 2), PlanStep(strengthMg: 7, weeks: 2)],
                                            presetID: "us-patch-10", dailyReminderMinute: 450))
        }
        profile.reasons.append(Reason(text: "Run with Aria without stopping to catch my breath", createdAt: reasonsAt))
        if self != .free {
            profile.reasons.append(Reason(text: "Save for the trip to Lisbon", createdAt: reasonsAt.addingTimeInterval(1)))
            profile.reasons.append(Reason(text: "Be there for Aria's big days", photo: Self.samplePhoto(),
                                          createdAt: reasonsAt.addingTimeInterval(2)))
        }
        profile.triggers = [.coffee, .stress]
        // Day 12 has a few weeks of logs, so Progress shows real insights (S7.3).
        if self == .day12 { Self.seedLogs(into: context, from: day(start), to: now, quitDay: day(quit), calendar: calendar) }
        // Prep has a few uses logged today and yesterday (S7.1).
        if self == .prep {
            for (offset, hour, product) in [(-1, 8, Product.vape), (-1, 9, .vape), (-1, 13, .cigarettes), (0, 8, .vape), (0, 9, .vape), (0, 7, .cigarettes)] {
                let when = day(offset).addingTimeInterval(Double(hour) * 3600)
                if when < now { context.insert(LogEntry(kind: .use, product: product, timestamp: when)) }
            }
        }
        // Pledged an hour ago, for the "Pledged at" card (S11.1).
        if UserDefaults.standard.bool(forKey: "dx.seedPledge") {
            context.insert(Pledge(day: DayClock(calendar: calendar, boundaryHour: 4).day(containing: now), madeAt: now.addingTimeInterval(-3600)))
        }
        // Check-ins earlier this week, for the week row after checking in (S11.2).
        if self == .day12 {
            for back in 1...3 {
                context.insert(CheckIn(day: day(-back), mood: .good, cravingCount: 2, madeAt: day(-back).addingTimeInterval(21 * 3600)))
            }
        }
        // A slip this morning, talked through, so Home shows today's plan (S8.3).
        if UserDefaults.standard.bool(forKey: "dx.seedSlip"), now.timeIntervalSince(calendar.startOfDay(for: now)) > 3600 {
            let slip = LogEntry(kind: .slip, product: .vape, timestamp: now.addingTimeInterval(-1800), trigger: .coffee, mood: .meh)
            slip.nextTime = "take a short walk"
            context.insert(slip)
            context.insert(IfThenPlan(situation: "after coffee", action: "take a short walk", createdAt: now.addingTimeInterval(-1700)))
        }
        // A few cravings ridden out earlier today, for "That's 4 this week" in Craving SOS.
        if self == .day3 {
            for hours in 1...3 {
                let entry = LogEntry(kind: .craving, timestamp: now.addingTimeInterval(Double(-hours) * 3600))
                entry.outcome = .passed
                entry.sosDurationSeconds = 180
                context.insert(entry)
            }
        }
        let progress = ProgramProgress()
        profile.progress = progress

        let prepDays = -start + quit
        var done: [ProgramDayID] = []
        switch self {
        case .prep: done = (1...3).map { ProgramDayID(phase: .prep, index: $0) }
        case .quitday: done = (1...prepDays).map { ProgramDayID(phase: .prep, index: $0) }
        case .day3: done = (1...prepDays).map { ProgramDayID(phase: .prep, index: $0) } + (1...2).map { ProgramDayID(phase: .quit, index: $0) }
        case .done: done = (1...prepDays).map { ProgramDayID(phase: .prep, index: $0) } + (1...3).map { ProgramDayID(phase: .quit, index: $0) }
        case .day12: done = (1...prepDays).map { ProgramDayID(phase: .prep, index: $0) } + (1...7).map { ProgramDayID(phase: .quit, index: $0) }
        case .free: done = [ProgramDayID(phase: .prep, index: 1)]
        case .returning: done = (1...prepDays).map { ProgramDayID(phase: .prep, index: $0) } + (1...3).map { ProgramDayID(phase: .quit, index: $0) }
        }
        for id in done {
            // Each lesson finished at 10am on its own day; for "done" the last one was ten minutes ago.
            let offset = id.phase == .prep ? start + id.index - 1 : quit + id.index - 1
            var when = day(offset).addingTimeInterval(10 * 3600)
            if self == .done, id == done.last { when = now.addingTimeInterval(-600) }
            progress.completions.append(DayCompletion(day: id, completedAt: min(when, now)))
        }
        // Everyone except "returning" opened the app within the last hour, so no pause is due.
        progress.lastActiveAt = self == .returning ? progress.completions.map(\.completedAt).max() : now.addingTimeInterval(-3600)
        try? context.save()
    }

    /// Cravings and uses with a clear shape: weekday mornings with coffee, weekend evenings with friends,
    /// some stress in the afternoons, easing off after Quit Day.
    private static func seedLogs(into context: ModelContext, from start: Date, to now: Date, quitDay: Date, calendar: Calendar) {
        var seed: UInt64 = 42
        func roll() -> Double {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            return Double(seed >> 33) / Double(1 << 31)
        }
        var day = start
        while day <= now {
            let weekday = calendar.component(.weekday, from: day)
            let weekend = weekday == 1 || weekday == 7
            let afterQuit = day >= quitDay
            let ease = afterQuit ? max(0.35, 1 - Double(calendar.dateComponents([.day], from: quitDay, to: day).day ?? 0) * 0.06) : 1
            var moments: [(Double, Trigger)] = []
            if !weekend { moments.append((8.2, .coffee)) }
            if roll() < 0.5 { moments.append((15.3, .stress)) }
            if weekend { moments.append((19.6, .social)) }
            if roll() < 0.35 { moments.append((12.8, .meals)) }
            if roll() < 0.15 { moments.append((7.6, .driving)) }
            for (hour, trigger) in moments where roll() < ease {
                let when = day.addingTimeInterval(hour * 3600 + roll() * 1800)
                guard when < now else { continue }
                if afterQuit {
                    let entry = LogEntry(kind: .craving, timestamp: when, intensity: Int(3 + roll() * 6), trigger: trigger)
                    if roll() < 0.8 {
                        entry.outcome = .passed
                        entry.sosDurationSeconds = 180
                    }
                    context.insert(entry)
                } else {
                    context.insert(LogEntry(kind: .use, product: roll() < 0.7 ? .vape : .cigarettes, timestamp: when, trigger: trigger))
                    if roll() < 0.6 { context.insert(LogEntry(kind: .craving, timestamp: when.addingTimeInterval(-600), trigger: trigger)) }
                }
            }
            day = calendar.date(byAdding: .day, value: 1, to: day) ?? now
        }
    }

    /// A stand-in photo for a reason: soft hills under an evening sky.
    private static func samplePhoto() -> Data? {
        let size = CGSize(width: 600, height: 520)
        let image = UIGraphicsImageRenderer(size: size).image { ctx in
            let cg = ctx.cgContext
            let sky = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                 colors: [UIColor(red: 0.85, green: 0.78, blue: 0.6, alpha: 1).cgColor,
                                          UIColor(red: 0.55, green: 0.66, blue: 0.5, alpha: 1).cgColor] as CFArray,
                                 locations: [0, 1])!
            cg.drawLinearGradient(sky, start: .zero, end: CGPoint(x: 0, y: size.height * 0.6), options: [.drawsAfterEndLocation])
            for (i, shade) in [(0.37, 0.5, 0.33), (0.25, 0.38, 0.24), (0.16, 0.26, 0.16)].enumerated() {
                let y = size.height * (0.5 + 0.13 * Double(i))
                let path = UIBezierPath()
                path.move(to: CGPoint(x: 0, y: y))
                path.addCurve(to: CGPoint(x: size.width, y: y - 40), controlPoint1: CGPoint(x: size.width * 0.3, y: y - 90),
                              controlPoint2: CGPoint(x: size.width * 0.6, y: y + 60))
                path.addLine(to: CGPoint(x: size.width, y: size.height))
                path.addLine(to: CGPoint(x: 0, y: size.height))
                path.close()
                UIColor(red: shade.0, green: shade.1, blue: shade.2, alpha: 1).setFill()
                path.fill()
            }
        }
        return image.jpegData(compressionQuality: 0.8)
    }
}
#endif
