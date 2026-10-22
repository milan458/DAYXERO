import SwiftUI

/// Full-width primary capsule: "Commit to my Quit Day", "Start lesson".
public struct DXPrimaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        DXPressable(configuration: configuration) {
            configuration.label
                .dxText(.button, color: DX.Palette.onPrimary)
                .frame(maxWidth: .infinity, minHeight: DX.Size.buttonHeight)
                .padding(.horizontal, DX.Space.xl)
                .background(DX.Palette.primary, in: Capsule())
        }
    }
}

public enum DXSecondaryKind: Sendable {
    /// Dark or light surface pill: "Skip for now", "Try again".
    case surface
    /// Sage pill for positive outcomes: "It passed".
    case sage
    /// Text only: "Not now".
    case quiet
}

public struct DXSecondaryButtonStyle: ButtonStyle {
    let kind: DXSecondaryKind

    public init(_ kind: DXSecondaryKind = .surface) {
        self.kind = kind
    }

    public func makeBody(configuration: Configuration) -> some View {
        DXPressable(configuration: configuration) {
            configuration.label
                .dxText(.button, color: foreground)
                .font(.custom(DX.Typeface.semibold, size: 15, relativeTo: .callout))
                .frame(minHeight: kind == .quiet ? 44 : DX.Size.compactButtonHeight)
                .padding(.horizontal, DX.Space.xl)
                .background {
                    switch kind {
                    case .surface:
                        Capsule().fill(DX.Palette.surface2)
                            .overlay(Capsule().strokeBorder(DX.Palette.hairline))
                    case .sage:
                        Capsule().fill(DX.Palette.sage)
                    case .quiet:
                        Color.clear
                    }
                }
        }
    }

    private var foreground: Color {
        switch kind {
        case .surface: DX.Palette.text
        case .sage: DX.Palette.onAccent
        case .quiet: DX.Palette.text2
        }
    }
}

/// Circular 48pt icon button on surface 1.
public struct DXIconButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        DXPressable(configuration: configuration) {
            configuration.label
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(DX.Palette.text)
                .frame(width: DX.Size.iconButton, height: DX.Size.iconButton)
                .background(DX.Palette.surface1, in: Circle())
                .overlay(Circle().strokeBorder(DX.Palette.hairline))
        }
    }
}

/// Floating action button. `.sage` is the craving SOS button, the same in both themes.
public struct DXFABStyle: ButtonStyle {
    public enum Tint: Sendable { case primary, sage }
    let tint: Tint

    public init(_ tint: Tint = .primary) {
        self.tint = tint
    }

    public func makeBody(configuration: Configuration) -> some View {
        DXPressable(configuration: configuration) {
            configuration.label
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(tint == .sage ? DX.Palette.onAccent : DX.Palette.onPrimary)
                .frame(width: DX.Size.fab, height: DX.Size.fab)
                .background(tint == .sage ? DX.Palette.sage : DX.Palette.primary, in: Circle())
                .shadow(color: DX.Palette.shadow, radius: 12, y: 8)
        }
    }
}

/// Shared press feedback: scale to 0.97 with a spring, disabled styling, selection haptic.
struct DXPressable<Content: View>: View {
    let configuration: ButtonStyleConfiguration
    @ViewBuilder let content: () -> Content

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        content()
            .opacity(isEnabled ? 1 : 0.4)
            .saturation(isEnabled ? 1 : 0)
            .scaleEffect(configuration.isPressed && !reduceMotion ? DX.Motion.pressedScale : 1)
            .animation(DX.Motion.animation(DX.Motion.press, reduceMotion: reduceMotion), value: configuration.isPressed)
            .contentShape(Rectangle())
    }
}

public extension ButtonStyle where Self == DXPrimaryButtonStyle {
    static var dxPrimary: DXPrimaryButtonStyle { DXPrimaryButtonStyle() }
}

public extension ButtonStyle where Self == DXSecondaryButtonStyle {
    static var dxSecondary: DXSecondaryButtonStyle { DXSecondaryButtonStyle(.surface) }
    static var dxSage: DXSecondaryButtonStyle { DXSecondaryButtonStyle(.sage) }
    static var dxQuiet: DXSecondaryButtonStyle { DXSecondaryButtonStyle(.quiet) }
}

public extension ButtonStyle where Self == DXIconButtonStyle {
    static var dxIcon: DXIconButtonStyle { DXIconButtonStyle() }
}
