import SwiftUI

public extension DX {
    /// Motion tokens. Always go through `animation(_:reduceMotion:)` so Reduce Motion
    /// swaps travel and scale for a short cross-fade.
    enum Motion {
        /// Dock tab, chips, selection.
        public static let morph = Animation.interpolatingSpring(stiffness: 350, damping: 28)
        /// Progress fills, sheets, page transitions.
        public static let glide = Animation.timingCurve(0.16, 1, 0.3, 1, duration: 0.5)
        /// Press feedback on every tappable surface.
        public static let press = Animation.spring(response: 0.25, dampingFraction: 0.7)
        /// Replacement for all of the above when Reduce Motion is on.
        public static let reduced = Animation.easeInOut(duration: 0.2)

        public static let pressedScale: CGFloat = 0.97

        public static func animation(_ animation: Animation, reduceMotion: Bool) -> Animation {
            reduceMotion ? reduced : animation
        }
    }
}

public extension DX {
    /// Haptic tokens. A slip never uses the error haptic.
    enum Haptic {
        /// Tabs, chips, slider steps.
        public static let select = SensoryFeedback.selection
        /// Lesson done, "It passed", pledge made.
        public static let commit = SensoryFeedback.success
        /// Slip logged.
        public static let gentle = SensoryFeedback.impact(flexibility: .soft, intensity: 0.5)
    }
}
