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

        // v5 (kit.css "motion"): every move below has a modifier in V4/Motion5.swift.
        /// Settle rises 48 pt; stagger 120 ms.
        public static let settleRise: CGFloat = 48
        public static let settleStagger: Double = 0.12
        /// Pop: scale from 0.4 and -8°, spring (cubic-bezier .3,1.4,.5,1), 700 ms, 110 ms stagger. Celebrations only.
        public static let pop = Animation.timingCurve(0.3, 1.4, 0.5, 1, duration: 0.7)
        public static let popStagger: Double = 0.11
        /// Stamp: lands from 1.8× and -14°, 620 ms spring, 140 ms stagger. Badges and stamps.
        public static let stamp: Double = 0.62
        public static let stampStagger: Double = 0.14
        /// Ring sweep from empty: 1.4 s settle curve after 250 ms.
        public static let ring = Animation.timingCurve(0.2, 0.8, 0.2, 1, duration: 1.4).delay(0.25)
        /// Ambient bob: 6 pt over 5 s.
        public static let bob: Double = 5
        public static let bobRise: CGFloat = 6
        /// "+1" floats up 34 pt and fades over 1.4 s.
        public static let floatUp: Double = 1.4
        /// A light sweep across a newly earned item, 1.4 s.
        public static let shine: Double = 1.4
        /// A quick 1.18× bump, 520 ms spring.
        public static let bump: Double = 0.52
        /// A plain fade, 700 ms.
        public static let fade = Animation.timingCurve(0.2, 0.7, 0.2, 1, duration: 0.7)
        /// Draw (lines and ticks), 520 ms.
        public static let draw = Animation.timingCurve(0.2, 0.7, 0.2, 1, duration: 0.52)

        /// A button under the finger (v5: .98, kit `.btn:active`).
        public static let pressedScale: CGFloat = 0.98
        /// How fast an option dips under the finger.
        public static let press = Animation.easeOut(duration: 0.12)

        /// Numbers counting up: 850 ms, ease-out cubic.
        public static let count = Animation.timingCurve(0.33, 1, 0.68, 1, duration: 0.85)

        /// Breathing: 4 s in, 6 s out.
        public static let inhale: Double = 4
        public static let exhale: Double = 6

        /// Every press-and-hold commitment, in seconds: one duration across the app (S27.20, 1 Nov 2026), so a hold
        /// always feels the same. The fill runs linear, left to right.
        public static let hold: Double = 1.0

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

    /// v5 layout values (kit.css `--gutter --r-card --r-chip`, `.opt .field .tabbar .sheet`).
    enum Layout {
        public static let gutter: CGFloat = 22
        public static let buttonGutter: CGFloat = 22
        public static let touchTarget: CGFloat = 44
        /// The one button height (58; Metrics' 56 is gone).
        public static let buttonHeight: CGFloat = 58
        public static let smallButtonHeight: CGFloat = 44
        public static let cardRadius: CGFloat = 22
        /// Option rows.
        public static let smallCardRadius: CGFloat = 18
        public static let optionRadius: CGFloat = 18
        public static let fieldRadius: CGFloat = 16
        public static let answerChipRadius: CGFloat = 14
        public static let chipRadius: CGFloat = 14
        public static let tabBarRadius: CGFloat = 28
        public static let sheetRadius: CGFloat = 30
        /// The bottom fade over tab content: 150 pt, ground at 0, 85% at 30%, solid from 40%.
        public static let tabFadeHeight: CGFloat = 150
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
    private let motion = MotionPolicy()

    public func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown || motion.reduce ? 0 : DX.Move.arriveRise)
            .onAppear {
                let animation = motion.animation(DX.Move.arrive)
                withAnimation(animation.delay(motion.reduce ? 0 : Double(index) * DX.Move.arriveStagger)) {
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
