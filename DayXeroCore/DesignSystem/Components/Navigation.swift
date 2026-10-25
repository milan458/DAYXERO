import SwiftUI

public struct DXDockItem: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: LocalizedStringResource
    public let systemImage: String

    public init(id: String, title: LocalizedStringResource, systemImage: String) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
    }

    public static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// Floating navigation dock. The active tab morphs from a 48pt circle into a 64pt capsule.
/// On iOS 26 the container is Liquid Glass; earlier it is a frosted bar.
public struct DXDock: View {
    let items: [DXDockItem]
    @Binding var selection: String
    let sosAction: () -> Void
    /// Where Craving SOS sits among the tabs; nil puts it at the end.
    let sosPosition: Int?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(items: [DXDockItem], selection: Binding<String>, sosPosition: Int? = nil, sosAction: @escaping () -> Void) {
        self.items = items
        self._selection = selection
        self.sosPosition = sosPosition
        self.sosAction = sosAction
    }

    public var body: some View {
        let split = min(sosPosition ?? items.count, items.count)
        HStack(spacing: 10) {
            ForEach(items.prefix(split)) { item in
                tab(item)
            }
            sosButton
                .padding(.horizontal, sosPosition == nil ? 0 : 2)
                .padding(.leading, sosPosition == nil ? 6 : 0)
            ForEach(items.dropFirst(split)) { item in
                tab(item)
            }
        }
        .padding(.vertical, DX.Space.xs)
        .padding(.horizontal, DX.Space.s)
        .frame(height: DX.Size.tabActiveHeight + DX.Space.m)
        .modifier(DockBackground())
        .sensoryFeedback(DX.Haptic.select, trigger: selection)
    }

    private var sosButton: some View {
        Button(action: sosAction) {
            Image(systemName: "flame")
                .accessibilityLabel(Text("Craving SOS"))
        }
        .buttonStyle(DXFABStyle(.sage))
    }

    private func tab(_ item: DXDockItem) -> some View {
        let active = item.id == selection
        return Button {
            withAnimation(DX.Motion.animation(DX.Motion.morph, reduceMotion: reduceMotion)) {
                selection = item.id
            }
        } label: {
            Image(systemName: item.systemImage)
                .font(.system(size: 18, weight: active ? .semibold : .regular))
                .foregroundStyle(active ? DX.Palette.onPrimary : DX.Palette.muted)
                .frame(width: DX.Size.tab, height: active ? DX.Size.tabActiveHeight : DX.Size.tab)
                .background(active ? DX.Palette.primary : DX.Palette.surface2, in: Capsule())
                .overlay(Capsule().strokeBorder(active ? .clear : DX.Palette.hairline))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(item.title))
        .accessibilityAddTraits(active ? [.isSelected, .isButton] : .isButton)
    }
}

private struct DockBackground: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26, *), !reduceTransparency {
            content.glassEffect(.regular, in: Capsule())
        } else {
            fallback(content)
        }
        #else
        fallback(content)
        #endif
    }

    private func fallback(_ content: Content) -> some View {
        content
            .background {
                if reduceTransparency {
                    Capsule().fill(DX.Palette.surface1)
                } else {
                    Capsule().fill(.ultraThinMaterial)
                }
            }
            .overlay(Capsule().strokeBorder(DX.Palette.hairline))
            .shadow(color: DX.Palette.shadow, radius: 12, y: 8)
    }
}

/// In-app timer pill that mirrors the craving Live Activity. Dark in both themes, like the Dynamic Island.
public struct DXTimerBanner: View {
    let title: LocalizedStringKey
    let endDate: Date

    public init(_ title: LocalizedStringKey, endDate: Date) {
        self.title = title
        self.endDate = endDate
    }

    public var body: some View {
        HStack(spacing: DX.Space.s) {
            Circle().fill(DX.Palette.sage).frame(width: 10, height: 10)
            Text(title)
            Text(timerInterval: Date.now...max(endDate, .now), countsDown: true)
                .font(.custom(DX.Typeface.semibold, size: 14, relativeTo: .subheadline))
                .monospacedDigit()
            Text("left").foregroundStyle(.white.opacity(0.6))
        }
        .font(.custom(DX.Typeface.regular, size: 14, relativeTo: .subheadline))
        .foregroundStyle(.white)
        .padding(.vertical, 10)
        .padding(.leading, 12)
        .padding(.trailing, DX.Space.m)
        .background(Color(light: 0x11140A, dark: 0x000000), in: Capsule())
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.14)))
        .accessibilityElement(children: .combine)
    }
}
