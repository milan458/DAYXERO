import SwiftUI

/// Standard card: surface 1, 28pt corners, hairline border.
public struct DXCard<Content: View>: View {
    let padding: CGFloat
    @ViewBuilder let content: () -> Content

    public init(padding: CGFloat = DX.Space.l, @ViewBuilder content: @escaping () -> Content) {
        self.padding = padding
        self.content = content
    }

    public var body: some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(padding)
            .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: DX.Radius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DX.Radius.card, style: .continuous)
                    .strokeBorder(DX.Palette.hairline)
            )
    }
}

/// Hero glass card: moss-tinted gradient, top-edge highlight, soft sage glow.
/// Falls back to a solid surface when Reduce Transparency is on.
public struct DXGlassCard<Content: View>: View {
    @ViewBuilder let content: () -> Content
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: DX.Radius.hero, style: .continuous)
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(22)
            .background {
                if reduceTransparency {
                    shape.fill(DX.Palette.surface1)
                } else {
                    ZStack {
                        shape.fill(.ultraThinMaterial)
                        shape.fill(
                            LinearGradient(
                                colors: [DX.Palette.glassStart, DX.Palette.glassEnd],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        RadialGradient(
                            colors: [DX.Palette.sage.opacity(0.18), .clear],
                            center: UnitPoint(x: 0.3, y: 1.1),
                            startRadius: 0,
                            endRadius: 260
                        )
                        .clipShape(shape)
                    }
                }
            }
            .overlay(
                shape.strokeBorder(
                    LinearGradient(
                        colors: [DX.Palette.glassHighlight, DX.Palette.hairline],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
            )
    }
}

/// Capsule-shaped row card, e.g. "Next milestone".
public struct DXCapsuleCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    public var body: some View {
        content()
            .padding(.vertical, DX.Space.s)
            .padding(.leading, 22)
            .padding(.trailing, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DX.Palette.surface1, in: Capsule())
            .overlay(Capsule().strokeBorder(DX.Palette.hairline))
    }
}

public extension View {
    /// Pure canvas background for every screen and sheet.
    func dxCanvas() -> some View {
        background(DX.Palette.canvas.ignoresSafeArea())
    }

    /// Keeps a column of content at a readable width and centres it in wider windows (S18.13). When iPhone Duo is
    /// half open like a book, the column moves to the leading side of the fold instead of straddling it (S18.14);
    /// a screen that splits itself around the fold passes `avoidingFold: false`.
    func dxReadableColumn(avoidingFold: Bool = true) -> some View {
        frame(maxWidth: DX.Size.readableWidth).frame(maxWidth: .infinity).modifier(AvoidFold(enabled: avoidingFold))
    }
}

/// Pads a full-width view's trailing side so its content stays clear of a fold running top to bottom.
/// The fold APIs only exist in the iOS 27.1 SDK; older builds lay out as before.
private struct AvoidFold: ViewModifier {
    let enabled: Bool
    @State private var trailing: CGFloat = 0

    func body(content: Content) -> some View {
        #if compiler(>=6.4)
        if enabled {
            if #available(iOS 27.1, *) {
                content
                    .padding(.trailing, trailing)
                    .background {
                        // Measured outside the padding, so the frame is the whole width either way.
                        GeometryReader { proxy in
                            Color.clear.onChange(of: Self.trailingInset(proxy), initial: true) { _, inset in trailing = inset }
                        }
                    }
            } else {
                content
            }
        } else {
            content
        }
        #else
        content
        #endif
    }

    #if compiler(>=6.4)
    @available(iOS 27.1, *)
    private static func trailingInset(_ proxy: GeometryProxy) -> CGFloat {
        guard let fold = proxy.reservedRegions(kind: .division).first(where: { $0.frame.height > $0.frame.width }) else { return 0 }
        return max(proxy.size.width - fold.frame.minX, 0)
    }
    #endif
}
