import SwiftUI

/// Empty and error states share one layout: dashed ring icon, heading, one supportive line, optional action.
public struct DXStateView: View {
    public enum Kind: Sendable { case empty, error }

    let kind: Kind
    let systemImage: String
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let actionTitle: LocalizedStringKey?
    let action: (() -> Void)?

    public init(
        _ kind: Kind,
        systemImage: String,
        title: LocalizedStringKey,
        message: LocalizedStringKey,
        actionTitle: LocalizedStringKey? = nil,
        action: (() -> Void)? = nil
    ) {
        self.kind = kind
        self.systemImage = systemImage
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        let tint = kind == .error ? DX.Palette.amber : DX.Palette.accentInk
        VStack(spacing: DX.Space.s) {
            Image(systemName: systemImage)
                .font(.system(size: 20))
                .foregroundStyle(tint)
                .frame(width: 64, height: 64)
                .overlay(Circle().strokeBorder(tint, style: StrokeStyle(lineWidth: 1, dash: [3, 3])))
                .accessibilityHidden(true)
            Text(title).dxText(.cardHeading)
            Text(message).dxText(.subtitle)
            if let actionTitle, let action {
                Button(actionTitle, action: action).buttonStyle(.dxSecondary).padding(.top, DX.Space.xxs)
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, DX.Space.l)
    }
}

/// Shimmering placeholder capsule. Static when Reduce Motion is on.
public struct DXSkeleton: View {
    let width: CGFloat?
    let height: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = -1

    public init(width: CGFloat? = nil, height: CGFloat) {
        self.width = width
        self.height = height
    }

    public var body: some View {
        Capsule()
            .fill(DX.Palette.surface2)
            .overlay {
                if !reduceMotion {
                    GeometryReader { geo in
                        LinearGradient(colors: [.clear, DX.Palette.surface3, .clear], startPoint: .leading, endPoint: .trailing)
                            .frame(width: geo.size.width)
                            .offset(x: phase * geo.size.width)
                    }
                    .clipShape(Capsule())
                }
            }
            .frame(width: width, height: height)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: false)) { phase = 1 }
            }
            .accessibilityHidden(true)
    }
}
