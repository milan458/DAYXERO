#if DEBUG
import DayXeroCore
import Foundation
import SwiftData

/// Sample people at different points in the program, for CI screenshots
/// (`-dx.homeScenario prep|quitday|day3|done|day12|free`). Seeds an in-memory store only.
enum DebugScenario: String {
    case prep, quitday, day3, done, day12, free

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
        }

        let context = ModelContext(container)
        let profile = UserProfile(name: "Milan", quitDay: day(quit), currencyCode: "USD", createdAt: day(start).addingTimeInterval(9 * 3600))
        context.insert(profile)
        profile.products.append(ProductUse(product: .vape, isPrimary: true, unitsPerDay: 200, pricePerPurchase: 8.5, unitsPerPurchase: 600))
        if self != .free {
            profile.products.append(ProductUse(product: .cigarettes, isPrimary: false, unitsPerDay: 6, pricePerPurchase: 15, unitsPerPurchase: 20))
        }
        profile.reasons.append(Reason(text: "Run with Aria without stopping to catch my breath"))
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
        }
        for (i, id) in done.enumerated() {
            // The last completion lands today for "done", earlier otherwise.
            let when = (self == .done && i == done.count - 1) ? now.addingTimeInterval(-600) : day(-30).addingTimeInterval(Double(i) * 3600)
            progress.completions.append(DayCompletion(day: id, completedAt: when))
        }
        try? context.save()
    }
}
#endif
