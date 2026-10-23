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
        profile.reasons.append(Reason(text: "Run with Aria without stopping to catch my breath", createdAt: reasonsAt))
        if self != .free {
            profile.reasons.append(Reason(text: "Save for the trip to Lisbon", createdAt: reasonsAt.addingTimeInterval(1)))
            profile.reasons.append(Reason(text: "Be there for Aria's big days", photo: Self.samplePhoto(),
                                          createdAt: reasonsAt.addingTimeInterval(2)))
        }
        profile.triggers = [.coffee, .stress]
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
