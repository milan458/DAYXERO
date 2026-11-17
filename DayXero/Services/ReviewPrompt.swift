import DayXeroCore
import StoreKit
import SwiftUI

/// Asks for an App Store rating at the moments in `ReviewAsk`, and remembers which have been used.
@MainActor
enum ReviewPrompt {
    private static let askedKey = "dx.review.asked"
    private static let lastKey = "dx.review.lastAskedAt"

    /// Call when the moment has just happened and its screen is closing. The sheet comes up a moment later, over
    /// whatever screen is underneath. Does nothing under tests and in the scripted demo launches, where the
    /// system's sheet (always shown in development builds) would cover the screen.
    static func ask(_ moment: ReviewMoment, joined: Date, request: RequestReviewAction, defaults: UserDefaults = .standard, now: Date = .now) {
        let info = ProcessInfo.processInfo
        guard info.environment["XCTestConfigurationFilePath"] == nil, !info.arguments.contains(where: { $0.hasPrefix("-dx.") }) else { return }
        let asked = Set((defaults.stringArray(forKey: askedKey) ?? []).compactMap(ReviewMoment.init(rawValue:)))
        let last = defaults.object(forKey: lastKey) as? Date
        guard ReviewAsk.shouldAsk(moment, asked: asked, lastAsked: last, joined: joined, now: now) else { return }
        defaults.set(asked.union([moment]).map(\.rawValue).sorted(), forKey: askedKey)
        defaults.set(now, forKey: lastKey)
        Analytics.track(.reviewRequested(moment: moment.rawValue))
        Task {
            try? await Task.sleep(for: .seconds(0.9))
            request()
        }
    }
}
