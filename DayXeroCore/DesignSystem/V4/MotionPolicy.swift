import SwiftUI

/// One switch for motion. Views hold `private let motion = MotionPolicy()` rather than reading
/// `accessibilityReduceMotion` themselves, so Reduce Motion (or a forced value set with `.dxReduceMotion(_:)`, for
/// previews, screenshots and tests) changes every move in one place.
///
/// With motion reduced: presses don't scale, numbers land on their final value, breathing stops moving (haptics and
/// words carry the rhythm), and anything that still animates uses `DX.Move.reduced`, a short fade.
public struct MotionPolicy: DynamicProperty {
    @Environment(\.accessibilityReduceMotion) private var system
    @Environment(\.dxReduceMotionOverride) private var forced

    public init() {}

    /// True when motion should be reduced.
    @MainActor public var reduce: Bool { forced ?? system }

    /// The animation to use, or the short reduced fade.
    @MainActor public func animation(_ animation: Animation) -> Animation {
        DX.Move.animation(animation, reduceMotion: reduce)
    }

    /// A press under the finger: 0.97 for 120 ms. No scale with motion reduced.
    @MainActor public var pressedScale: CGFloat { reduce ? 1 : DX.Move.pressedScale }
    @MainActor public var press: Animation? { reduce ? nil : DX.Move.press }

    /// Counts up and breathing rings move only with full motion.
    @MainActor public var counts: Bool { !reduce }
    @MainActor public var breathes: Bool { !reduce }
}

private struct ReduceMotionOverrideKey: EnvironmentKey {
    static let defaultValue: Bool? = nil
}

public extension EnvironmentValues {
    /// Forces Reduce Motion on or off below this point; nil follows the system setting.
    var dxReduceMotionOverride: Bool? {
        get { self[ReduceMotionOverrideKey.self] }
        set { self[ReduceMotionOverrideKey.self] = newValue }
    }
}

public extension View {
    /// Forces Reduce Motion for everything below (nil follows the system).
    func dxReduceMotion(_ reduce: Bool?) -> some View {
        environment(\.dxReduceMotionOverride, reduce)
    }
}

/// Feedback for anything tapped to choose (option cards, chips, segments, days): it dips to 0.97 for 120 ms under
/// the finger. Haptics stay with the control, so each one decides when a choice is made.
public struct DXPressStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        DXPressBody(label: configuration.label, pressed: configuration.isPressed)
    }
}

private struct DXPressBody: View {
    let label: ButtonStyleConfiguration.Label
    let pressed: Bool
    private let motion = MotionPolicy()

    var body: some View {
        label
            .scaleEffect(pressed ? motion.pressedScale : 1)
            .animation(motion.press, value: pressed)
    }
}

public extension ButtonStyle where Self == DXPressStyle {
    static var dxPress: DXPressStyle { DXPressStyle() }
}
