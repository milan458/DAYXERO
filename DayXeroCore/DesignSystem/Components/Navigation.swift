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
/// On iOS 26 the container is Liquid Glass; earlier it is a frosted bar. On iPhone Duo it can stand on its side
/// along the edge where the system puts vertical bars (S18.13).
public struct DXDock: View {
    let items: [DXDockItem]
    @Binding var selection: String
    let sosAction: () -> Void
    /// Where Craving SOS sits among the tabs; nil puts it at the end.
    let sosPosition: Int?
    let axis: Axis

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(items: [DXDockItem], selection: Binding<String>, sosPosition: Int? = nil, axis: Axis = .horizontal,
                sosAction: @escaping () -> Void) {
        self.items = items
        self._selection = selection
        self.sosPosition = sosPosition
        self.axis = axis
        self.sosAction = sosAction
    }

    /// The dock's thickness across its axis: its height lying down, its width standing up.
    public static let thickness = DX.Size.tabActiveHeight + DX.Space.m

    public var body: some View {
        let split = min(sosPosition ?? items.count, items.count)
        let layout = axis == .horizontal ? AnyLayout(HStackLayout(spacing: 10)) : AnyLayout(VStackLayout(spacing: 10))
        layout {
            ForEach(items.prefix(split)) { item in
                tab(item)
            }
            sosButton
                .padding(axis == .horizontal ? .horizontal : .vertical, sosPosition == nil ? 0 : 2)
                .padding(axis == .horizontal ? .leading : .top, sosPosition == nil ? 6 : 0)
            ForEach(items.dropFirst(split)) { item in
                tab(item)
            }
        }
        .padding(axis == .horizontal ? .vertical : .horizontal, DX.Space.xs)
        .padding(axis == .horizontal ? .horizontal : .vertical, DX.Space.s)
        .frame(width: axis == .vertical ? Self.thickness : nil, height: axis == .horizontal ? Self.thickness : nil)
        .modifier(DockBackground())
        .sensoryFeedback(DX.Haptic.select, trigger: selection)
    }

    /// The word "SOS" in a slowly sliding rainbow, on the same circle as a tab that isn't selected (S21.4):
    /// the flame read as confusing.
    private var sosButton: some View {
        Button(action: sosAction) {
            RainbowSOS()
                .frame(width: DX.Size.tab, height: DX.Size.tab)
                .background(DX.Palette.surface2, in: Circle())
                .overlay(Circle().strokeBorder(DX.Palette.hairline))
                .contentShape(Circle())
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("Craving SOS"))
        }
        .buttonStyle(.plain)
    }

    private func tab(_ item: DXDockItem) -> some View {
        let active = item.id == selection
        return Button {
            withAnimation(DX.Motion.animation(DX.Motion.morph, reduceMotion: reduceMotion)) {
                selection = item.id
            }
        } label: {
            Image(systemName: item.systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(active ? DX.Palette.onPrimary : DX.Palette.text2)
                .frame(width: active && axis == .vertical ? DX.Size.tabActiveHeight : DX.Size.tab,
                       height: active && axis == .horizontal ? DX.Size.tabActiveHeight : DX.Size.tab)
                .background(active ? DX.Palette.primary : DX.Palette.surface2, in: Capsule())
                .overlay(Capsule().strokeBorder(active ? .clear : DX.Palette.hairline))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(item.title))
        .accessibilityAddTraits(active ? [.isSelected, .isButton] : .isButton)
    }
}

/// "SOS" filled with a rainbow that slides across the word every three seconds; still with Reduce Motion.
/// Deeper colours in light mode so the word stays readable on the light dock.
private struct RainbowSOS: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let bright: [UInt32] = [0xFF6B6B, 0xFFB86B, 0xFFE36B, 0x7BE495, 0x6BC8FF, 0x9B8CFF, 0xFF7BD0]
    private static let deep: [UInt32] = [0xD7263D, 0xE4572E, 0xB88500, 0x16897C, 0x2667C9, 0x6C45CF, 0xB8236E]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion)) { timeline in
            let phase = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 3) / 3
            Text(verbatim: "SOS")
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .tracking(0.5)
                .foregroundStyle(rainbow(phase: phase))
                .dynamicTypeSize(.large)
        }
    }

    /// Two rainbows end to end across four widths of the word, shifted left by up to two widths: the pattern
    /// repeats every two widths, so the loop has no seam.
    private func rainbow(phase: Double) -> LinearGradient {
        let hexes = scheme == .dark ? Self.bright : Self.deep
        let colors = (hexes + hexes + [hexes[0]]).map { Color(hex: $0) }
        let start = -2 * phase
        return LinearGradient(colors: colors, startPoint: UnitPoint(x: start, y: 0.5), endPoint: UnitPoint(x: start + 4, y: 0.5))
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
