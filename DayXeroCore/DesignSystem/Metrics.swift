import SwiftUI

public extension DX {
    /// 4-point spacing scale.
    enum Space {
        public static let xxs: CGFloat = 4
        public static let xs: CGFloat = 8
        public static let s: CGFloat = 12
        public static let m: CGFloat = 16
        public static let l: CGFloat = 20
        public static let xl: CGFloat = 24
        public static let xxl: CGFloat = 32
        public static let xxxl: CGFloat = 48
    }

    /// No sharp corners anywhere: inputs 20, cards 28, hero cards 36, everything else a capsule.
    enum Radius {
        public static let input: CGFloat = 20
        public static let card: CGFloat = 28
        public static let hero: CGFloat = 36
    }

    enum Size {
        public static let buttonHeight: CGFloat = 56
        public static let compactButtonHeight: CGFloat = 48
        public static let iconButton: CGFloat = 48
        public static let fab: CGFloat = 52
        public static let tab: CGFloat = 48
        public static let tabActiveHeight: CGFloat = 64
        public static let inputHeight: CGFloat = 52
        public static let dayBubble: CGFloat = 40
        public static let progressHeight: CGFloat = 6
        /// The widest a column of cards or text gets. Wider windows (iPhone Duo's inner display, S18.13) centre it.
        public static let readableWidth: CGFloat = 600
    }
}
