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

/// Floating navigation dock (S24): one glass bar, laid out like the Home mockup. The selected tab is a white pill with
/// its icon and name; the others are icons on faint glass circles, with Craving SOS in the middle. The pill slides
/// between tabs and stretches as it goes, and a finger dragged along the bar carries it, like iOS 26's tab bars.
/// On iOS 26 the bar is Liquid Glass; earlier it is a frosted bar. On iPhone Duo it can stand on its side along
/// the edge where the system puts vertical bars (S18.13), showing icons only.
public struct DXDock: View {
    let items: [DXDockItem]
    @Binding var selection: String
    let sosAction: () -> Void
    /// Where Craving SOS sits among the tabs; nil puts it at the end.
    let sosPosition: Int?
    let axis: Axis

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var lens
    /// The tab under a finger dragged along the bar; the pill follows it until the finger lifts.
    @State private var dragTarget: String?
    @State private var frames: [String: CGRect] = [:]
    /// The pill's squash and stretch as it lands.
    @State private var stretched = false

    public init(items: [DXDockItem], selection: Binding<String>, sosPosition: Int? = nil, axis: Axis = .horizontal,
                sosAction: @escaping () -> Void) {
        self.items = items
        self._selection = selection
        self.sosPosition = sosPosition
        self.axis = axis
        self.sosAction = sosAction
    }

    /// The dock's thickness across its axis: its height lying down, its width standing up.
    public static let thickness = DX.Size.tab + 2 * DX.Space.xs

    private var shown: String { dragTarget ?? selection }

    public var body: some View {
        let split = min(sosPosition ?? items.count, items.count)
        let layout = axis == .horizontal ? AnyLayout(HStackLayout(spacing: 6)) : AnyLayout(VStackLayout(spacing: 6))
        layout {
            ForEach(items.prefix(split)) { item in
                tab(item)
            }
            sosButton
            ForEach(items.dropFirst(split)) { item in
                tab(item)
            }
        }
        .padding(DX.Space.xs)
        .frame(width: axis == .vertical ? Self.thickness : nil, height: axis == .horizontal ? Self.thickness : nil)
        .coordinateSpace(.named(Self.space))
        .modifier(DockBackground())
        .simultaneousGesture(drag)
        .dynamicTypeSize(...DynamicTypeSize.xLarge)
        .sensoryFeedback(DX.Haptic.select, trigger: shown)
    }

    private static let space = "dx.dock"

    /// The word "SOS" in a slowly sliding rainbow, on the same faint circle as a tab that isn't selected (S21.4).
    private var sosButton: some View {
        Button(action: sosAction) {
            RainbowSOS()
                .frame(width: DX.Size.tab, height: DX.Size.tab)
                .background(DX.Palette.text.opacity(0.07), in: Circle())
                .contentShape(Circle())
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("Craving SOS"))
        }
        .buttonStyle(DockPress())
    }

    private func tab(_ item: DXDockItem) -> some View {
        let active = item.id == shown
        let labelled = active && axis == .horizontal
        return Button { select(item.id) } label: {
            HStack(spacing: 6) {
                Image(systemName: item.systemImage)
                    .font(.system(size: 18, weight: .semibold))
                if labelled {
                    Text(item.title)
                        .font(.custom(DX.Typeface.semibold, size: 15, relativeTo: .subheadline))
                        .lineLimit(1)
                        .fixedSize()
                        .transition(.opacity.combined(with: .scale(scale: 0.7, anchor: .leading)))
                }
            }
            .foregroundStyle(active ? DX.Palette.onPrimary : DX.Palette.text.opacity(0.85))
            .padding(.horizontal, labelled ? DX.Space.m : 0)
            .frame(minWidth: DX.Size.tab, minHeight: DX.Size.tab)
            .frame(maxHeight: DX.Size.tab)
            .background {
                if active {
                    Capsule()
                        .fill(DX.Palette.primary)
                        .shadow(color: DX.Palette.shadow, radius: dragTarget == nil ? 6 : 14, y: 4)
                        .matchedGeometryEffect(id: "lens", in: lens)
                        .scaleEffect(x: stretched ? 1.1 : (dragTarget == nil ? 1 : 1.06),
                                     y: stretched ? 0.9 : (dragTarget == nil ? 1 : 1.06))
                } else {
                    Circle().fill(DX.Palette.text.opacity(0.07))
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(DockPress())
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(Self.space)) } action: { frames[item.id] = $0 }
        .accessibilityLabel(Text(item.title))
        .accessibilityAddTraits(active ? [.isSelected, .isButton] : .isButton)
    }

    private func select(_ id: String) {
        let changed = id != selection
        withAnimation(reduceMotion ? DX.Motion.reduced : .spring(response: 0.42, dampingFraction: 0.7)) {
            selection = id
        }
        guard changed, !reduceMotion else { return }
        // Squash as it lands, then settle with a little wobble.
        withAnimation(.easeOut(duration: 0.12)) { stretched = true }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(140))
            withAnimation(.spring(response: 0.32, dampingFraction: 0.45)) { stretched = false }
        }
    }

    /// Drag along the bar and the pill follows the finger; lift to choose that tab.
    private var drag: some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .named(Self.space))
            .onChanged { value in
                let hit = frames.first { $0.value.insetBy(dx: -3, dy: -16).contains(value.location) }?.key
                guard let hit, hit != dragTarget else { return }
                withAnimation(reduceMotion ? DX.Motion.reduced : .spring(response: 0.3, dampingFraction: 0.75)) { dragTarget = hit }
            }
            .onEnded { _ in
                guard let target = dragTarget else { return }
                select(target)
                dragTarget = nil
            }
    }
}

/// A press that sinks a little, like the glass giving under a finger.
private struct DockPress: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.92 : 1)
            .animation(DX.Motion.press, value: configuration.isPressed)
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
            content.glassEffect(.regular.interactive(), in: Capsule())
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
