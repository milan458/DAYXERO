import SwiftUI

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
