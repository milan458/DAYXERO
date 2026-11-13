import SwiftUI

/// v4 buttons (design doc §6, patterns 1 and 2). A button takes its colours from the
/// ground it sits on, so colour follows the character.
public extension DX {
    /// v5: `primary` is the one button; `small` the 44 pt one inside cards; `ghost` (and `secondary`, its old name)
    /// the outlined second choice; `quiet` the text link.
    enum ButtonKind: Sendable { case primary, secondary, quiet, ghost, small }

    /// Primary and secondary colours per ground and appearance (tokens.json → "buttons").
    struct ButtonColors: Sendable {
        public let background: UInt32?
        public let foreground: UInt32
        /// The hold button's progress fill.
        public let fill: UInt32
        public let lip: Bool

        /// Destructive text for quiet and secondary buttons. tokens.json has no red yet, so these are
        /// proposed values: #B3261E clears 4.5:1 on reading, surface and raised in light; #FF8A80 clears
        /// it on every dark ground. `V4TokenTests` checks both.
        public static let destructiveLight: UInt32 = 0xB3261E
        public static let destructiveDark: UInt32 = 0xFF8A80
        /// A destructive primary button is filled red (S27.20): iOS's higher-contrast system red, #D70015 with white
        /// words in light (5.6:1) and #FF6961 with navy words in dark (6.4:1). `V4TokenTests` checks both.
        public static let destructiveFillLight: UInt32 = 0xD70015
        public static let destructiveFillDark: UInt32 = 0xFF6961

        /// The destructive red for a ground, or the ground's ink where the red would fall under 4.5:1
        /// (light coral, ocean, violet and other saturated grounds).
        public static func destructiveForeground(on ground: Ground, dark: Bool) -> UInt32 {
            let s = ground.spec
            let red = dark ? destructiveDark : destructiveLight
            let background = dark ? s.dark : s.light
            return Contrast.ratio(red, background) >= 4.5 ? red : (dark ? s.inkDark : s.inkLight)
        }

        /// `destructive` (Button(role: .destructive)) fills a primary button red and turns quiet and outlined
        /// secondary buttons' words red (S27.20).
        public static func make(_ kind: ButtonKind, on ground: Ground, dark: Bool, destructive: Bool) -> ButtonColors {
            let base = make(kind, on: ground, dark: dark)
            if destructive, kind == .primary || kind == .small {
                return ButtonColors(background: dark ? destructiveFillDark : destructiveFillLight,
                                    foreground: dark ? 0x1E1A3A : 0xFFFFFF, fill: dark ? 0xFF8A80 : 0xA8000F, lip: false)
            }
            guard destructive, base.background == nil else { return base }
            return ButtonColors(background: nil, foreground: destructiveForeground(on: ground, dark: dark), fill: 0, lip: false)
        }

        public static func make(_ kind: ButtonKind, on ground: Ground, dark: Bool) -> ButtonColors {
            // A retired ground (S27.13) draws its survivor's buttons too.
            let ground = ground.resolved
            let s = ground.spec
            switch (kind, dark) {
            case (.primary, _), (.small, _):
                // v5: one button. `--btn` on `--btn-fg` from the ground's tokens (ink on light grounds, cream on dark,
                // cream on ocean, parchment on night); the fill is the label colour at 22% (kit `.btn .fill`).
                let t = ground.tokens(dark: dark)
                return ButtonColors(background: t.btn, foreground: t.btnFg, fill: DX.Ground.mix(t.btnFg, 0.22, over: t.btn), lip: false)
            case (.secondary, _), (.ghost, _):
                return ButtonColors(background: nil, foreground: dark ? s.inkDark : s.inkLight, fill: 0, lip: false)
            case (.quiet, _):
                return ButtonColors(background: nil, foreground: dark ? s.inkDark : s.inkLight, fill: 0, lip: false)
            }
        }
    }
}

/// Full-width pill, 58 pt, with a lip shadow on colour grounds. Use with `.buttonStyle(.dx(.primary, on: .apricot))`.
public struct V4ButtonStyle: ButtonStyle {
    let kind: DX.ButtonKind
    let ground: DX.Ground

    public init(_ kind: DX.ButtonKind = .primary, on ground: DX.Ground) {
        self.kind = kind
        self.ground = ground
    }

    public func makeBody(configuration: Configuration) -> some View {
        V4ButtonBody(label: configuration.label, pressed: configuration.isPressed, kind: kind, ground: ground,
                     destructive: configuration.role == .destructive)
    }
}

public extension ButtonStyle where Self == V4ButtonStyle {
    static func dx(_ kind: DX.ButtonKind = .primary, on ground: DX.Ground) -> V4ButtonStyle {
        V4ButtonStyle(kind, on: ground)
    }
}

private struct V4ButtonBody<Label: View>: View {
    let label: Label
    let pressed: Bool
    let kind: DX.ButtonKind
    let ground: DX.Ground
    let destructive: Bool
    @Environment(\.colorScheme) private var scheme
    @Environment(\.isEnabled) private var enabled
    private let motion = MotionPolicy()

    var body: some View {
        let colors = DX.ButtonColors.make(kind, on: ground, dark: scheme == .dark, destructive: destructive)
        let g = ground.resolved
        let quiet = kind == .quiet
        let small = kind == .small
        let outlined = kind == .secondary || kind == .ghost
        let height: CGFloat = quiet ? 40 : small ? DX.Layout.smallButtonHeight : DX.Layout.buttonHeight
        let fill = colors.background.map { Color(hex: $0) }
        label
            // kit `.btn`: 700 17 display; `.small` 15; `.link` 600 15 body at 85%.
            .dxFace(quiet ? .body : .display, quiet || small ? 15 : 17, weight: quiet ? 600 : 700, tracking: quiet ? 0 : -0.1)
            .foregroundStyle(Color(hex: colors.foreground).opacity(quiet ? 0.85 : 1))
            .multilineTextAlignment(.center)
            .frame(maxWidth: quiet || small ? nil : .infinity, minHeight: height)
            .padding(.horizontal, quiet ? 8 : small ? 18 : 24)
            .background {
                if let fill, !outlined {
                    Capsule().fill(fill)
                        .shadow(color: fill.opacity(pressed ? 0.18 : 0.22), radius: pressed ? 4 : small ? 6 : 9, x: 0, y: pressed ? 2 : small ? 4 : 6)
                } else if outlined {
                    Capsule().strokeBorder(g.line, lineWidth: 2)
                }
            }
            // kit `.btn[disabled]`: 38% and no shadow.
            .opacity(enabled ? 1 : 0.38)
            .contentShape(Capsule())
            .scaleEffect(pressed ? motion.pressedScale : 1)
            .animation(motion.animation(.timingCurve(0.2, 0.7, 0.2, 1, duration: 0.15)), value: pressed)
    }
}

/// Press and hold to commit, always `DX.Move.hold` (1 s, S27.20). The fill runs left
/// to right while held and resets if released early. While held, a Core Haptics crescendo builds from a soft hum to
/// a firm one (CHAR-04, 2 Nov 2026), then the commit lands with its own tap. VoiceOver users double-tap instead:
/// the default accessibility action completes it.
public struct HoldButton: View {
    let label: String
    let doneLabel: String
    let duration: Double
    let ground: DX.Ground
    let action: () -> Void

    @State private var progress: CGFloat = 0
    @State private var done = false
    @State private var haptics = HapticPlayer()
    @Environment(\.colorScheme) private var scheme

    public init(_ label: String, done doneLabel: String, duration: Double, on ground: DX.Ground, action: @escaping () -> Void) {
        self.label = label
        self.doneLabel = doneLabel
        self.duration = duration
        self.ground = ground
        self.action = action
    }

    public var body: some View {
        let colors = DX.ButtonColors.make(.primary, on: ground, dark: scheme == .dark)
        let bg = Color(hex: colors.background ?? 0x1E1A3A)
        ZStack(alignment: .leading) {
            Capsule().fill(bg)
                .shadow(color: bg.opacity(0.22), radius: 9, x: 0, y: 6)
            // kit: the fill is the label colour at 22%, left to right; it fades once done (the button keeps its colour).
            GeometryReader { proxy in
                Rectangle()
                    .fill(Color(hex: colors.foreground).opacity(0.22))
                    .frame(width: proxy.size.width * progress)
                    .opacity(done ? 0 : 1)
                    .animation(.easeOut(duration: 0.3), value: done)
            }
            .clipShape(Capsule())
            HStack(spacing: 8) {
                if done {
                    // The done state: a green disc with a white tick, then the done label.
                    DXIconShape(d: DX.Icon.check.d)
                        .stroke(.white, style: StrokeStyle(lineWidth: 3 * 18 / 24, lineCap: .round, lineJoin: .round))
                        .frame(width: 18, height: 18)
                        .padding(3)
                        .background(DX.Fill.done, in: Circle())
                        .transition(.scale(scale: 0.4).combined(with: .opacity))
                        .accessibilityHidden(true)
                }
                Text(done ? doneLabel : label)
                    .dxFace(.display, 17, weight: 700, tracking: -0.1)
            }
            .foregroundStyle(Color(hex: colors.foreground))
            .frame(maxWidth: .infinity)
        }
        .frame(height: DX.Layout.buttonHeight)
        .contentShape(Capsule())
        .onLongPressGesture(minimumDuration: duration, maximumDistance: 40) {
            complete()
        } onPressingChanged: { pressing in
            guard !done else { return }
            if pressing {
                withAnimation(.linear(duration: duration)) { progress = 1 }
                haptics.crescendo(duration: duration)
            } else {
                withAnimation(.easeOut(duration: 0.2)) { progress = 0 }
                haptics.stop()
            }
        }
        .onDisappear { haptics.shutDown() }
        .sensoryFeedback(DX.Haptic.commit, trigger: done) { _, isDone in isDone }
        .accessibilityElement()
        .accessibilityLabel(done ? doneLabel : label)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(done ? "" : "Double-tap to confirm.")
        .accessibilityAction { complete() }
        .disabled(done)
    }

    private func complete() {
        guard !done else { return }
        haptics.stop()
        withAnimation(DX.Move.pop) { done = true }
        action()
    }
}

public extension View {
    /// Says why a button can't be used yet (S27.20): a short line under it while `shown` is true, which VoiceOver
    /// reads as the button's hint. Apply it to the button, alongside its own `.disabled(_:)`.
    func dxDisabledReason(_ reason: LocalizedStringKey, shown: Bool, on ground: DX.Ground = .reading) -> some View {
        VStack(spacing: 6) {
            self.accessibilityHint(shown ? Text(reason) : Text(verbatim: ""))
            if shown {
                Text(reason)
                    .dxType(.caption)
                    .foregroundStyle(ground.resolved.muted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityHidden(true)
            }
        }
    }
}
