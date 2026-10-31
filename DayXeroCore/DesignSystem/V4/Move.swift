import SwiftUI

/// v4 motion (tokens.json → "motion"). Arrive, Settle and Celebrate are the only three
/// moves; Celebrate is used only on Passed, milestones and the finale.
/// With Reduce Motion on, every move renders its final state with a short fade.
public extension DX {
    enum Move {
        /// Content entering a screen: rise 18 pt and fade, 90 ms stagger.
        public static let arrive = Animation.timingCurve(0.2, 0.7, 0.2, 1, duration: 0.6)
        public static let arriveRise: CGFloat = 18
        public static let arriveStagger: Double = 0.09

        /// A character or card coming to rest. No overshoot.
        public static let settle = Animation.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.9)

        /// Passed, milestones and the finale only.
        public static let celebrate = Animation.timingCurve(0.3, 1.4, 0.5, 1, duration: 0.7)
        public static let celebrateFromScale: CGFloat = 0.6

        /// Numbers counting up.
        public static let count = Animation.easeOut(duration: 0.85)

        /// Breathing: 4 s in, 6 s out.
        public static let inhale: Double = 4
        public static let exhale: Double = 6

        /// Press-and-hold commitments, in seconds. The fill runs linear, left to right.
        public enum Hold {
            public static let quitDay: Double = 1.5
            public static let pledge: Double = 1.0
            public static let dayXeroCommit: Double = 3.0
        }

        public static let reduced = Animation.easeInOut(duration: 0.2)

        public static func animation(_ animation: Animation, reduceMotion: Bool) -> Animation {
            reduceMotion ? reduced : animation
        }

        /// Breath phase (0 empty, 1 full) at a time into the cycle; used by Jelli and the breathing ring.
        public static func breath(at elapsed: Double) -> Double {
            let cycle = inhale + exhale
            let t = elapsed.truncatingRemainder(dividingBy: cycle)
            let p = t < inhale ? t / inhale : 1 - (t - inhale) / exhale
            // Ease in and out so the turn at each end is soft.
            return 0.5 - 0.5 * cos(.pi * max(0, min(1, p)))
        }
    }

    /// v4 layout values (tokens.json → "layout", "characterSizes").
    enum Layout {
        public static let gutter: CGFloat = 20
        public static let buttonGutter: CGFloat = 22
        public static let touchTarget: CGFloat = 44
        public static let buttonHeight: CGFloat = 58
        public static let cardRadius: CGFloat = 24
        public static let smallCardRadius: CGFloat = 18
        public static let answerChipRadius: CGFloat = 14
    }

    /// The four character sizes; at most two illustrations on a screen.
    enum CharacterSize: CGFloat, CaseIterable, Sendable {
        case avatar = 40, card = 88, scene = 140, hero = 200
        public static let maxPerScreen = 2
    }
}

/// Arrive: rise and fade in, staggered by index. Reduce Motion shows it in place.
public struct ArriveModifier: ViewModifier {
    let index: Int
    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : DX.Move.arriveRise)
            .onAppear {
                let animation = DX.Move.animation(DX.Move.arrive, reduceMotion: reduceMotion)
                withAnimation(animation.delay(reduceMotion ? 0 : Double(index) * DX.Move.arriveStagger)) {
                    shown = true
                }
            }
    }
}

public extension View {
    func dxArrive(_ index: Int = 0) -> some View {
        modifier(ArriveModifier(index: index))
    }
}
