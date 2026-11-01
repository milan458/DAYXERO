import SwiftUI

/// v4 buttons (design doc §6, patterns 1 and 2). A button takes its colours from the
/// ground it sits on, so colour follows the character.
public extension DX {
    enum ButtonKind: Sendable { case primary, secondary, quiet }

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
            if destructive, kind == .primary {
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
            case (.primary, false):
                switch ground {
                case .ocean, .violet: return ButtonColors(background: 0xFFF8EE, foreground: s.light, fill: 0xE3EAFF, lip: true)
                case .reading: return ButtonColors(background: 0x1E1A3A, foreground: 0xFFF8EE, fill: 0x3A3460, lip: false)
                default: return ButtonColors(background: 0x1E1A3A, foreground: 0xFFF8EE, fill: 0x3A3460, lip: true)
                }
            case (.primary, true):
                switch ground {
                // Warm grounds go plum in dark; the button keeps the ground's own hue.
                case .apricot, .coral, .sun: return ButtonColors(background: s.light, foreground: s.dark, fill: 0xFFD9B0, lip: false)
                default: return ButtonColors(background: 0xFFF8EE, foreground: s.dark, fill: 0xE3DCF5, lip: false)
                }
            case (.secondary, _):
                if ground == .ocean {
                    return ButtonColors(background: dark ? 0x1B2C66 : 0x1D3A9E, foreground: 0xFFF8EE, fill: 0x2A52DB, lip: false)
                }
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var enabled

    var body: some View {
        let colors = DX.ButtonColors.make(kind, on: ground, dark: scheme == .dark, destructive: destructive)
        let height: CGFloat = kind == .quiet ? DX.Layout.touchTarget : DX.Layout.buttonHeight
        // Disabled stays legible (S27.20): a card fill, the ground's muted words and a hairline, never a 50% fade.
        let disabledFilled = !enabled && kind != .quiet
        label
            .dxType(kind == .quiet ? .footnote : .headline)
            .foregroundStyle(enabled ? Color(hex: colors.foreground) : ground.resolved.muted)
            .frame(maxWidth: kind == .quiet ? nil : .infinity, minHeight: height)
            .padding(.horizontal, kind == .quiet ? 8 : 24)
            .background {
                if disabledFilled {
                    Capsule().fill(ground.resolved == .reading ? DX.Fill.surface : DX.Fill.onColourCard(for: ground.resolved))
                        .overlay(Capsule().strokeBorder(DX.Fill.hairline, lineWidth: 1))
                } else if let bg = colors.background {
                    Capsule().fill(Color(hex: bg))
                        .shadow(color: .black.opacity(colors.lip && !pressed ? 0.2 : 0), radius: 0, x: 0, y: 6)
                } else if kind == .secondary {
                    Capsule().strokeBorder(Color(hex: colors.foreground), lineWidth: 2)
                }
            }
            .contentShape(Capsule())
            .offset(y: pressed && colors.lip ? 3 : 0)
            .scaleEffect(pressed && !reduceMotion ? DX.Move.pressedScale : 1)
            .animation(DX.Move.animation(DX.Move.settle, reduceMotion: reduceMotion), value: pressed)
    }
}

/// Press and hold to commit, always `DX.Move.hold` (1 s, S27.20). The fill runs left
/// to right while held and resets if released early. VoiceOver users double-tap instead:
/// the default accessibility action completes it.
public struct HoldButton: View {
    let label: String
    let doneLabel: String
    let duration: Double
    let ground: DX.Ground
    let action: () -> Void

    @State private var progress: CGFloat = 0
    @State private var done = false
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
        ZStack(alignment: .leading) {
            Capsule().fill(Color(hex: colors.background ?? 0x1E1A3A))
                .shadow(color: .black.opacity(colors.lip ? 0.2 : 0), radius: 0, x: 0, y: 6)
            GeometryReader { proxy in
                Rectangle()
                    .fill(Color(hex: colors.fill))
                    .frame(width: proxy.size.width * (done ? 1 : progress))
            }
            .clipShape(Capsule())
            HStack(spacing: 8) {
                Text(done ? doneLabel : label)
                    .dxType(.headline)
                if done {
                    Image(systemName: "checkmark")
                        .font(.headline.weight(.bold))
                        .accessibilityHidden(true)
                }
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
            } else {
                withAnimation(.easeOut(duration: 0.2)) { progress = 0 }
            }
        }
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
        done = true
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
