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

/// Floating navigation dock (S24), laid out like the Home mockup and behaving like iOS 26 tab bars (WhatsApp's):
/// one glass bar of hollow icons; the selected tab sits in a dark pill, its icon filled in sage and its name beside
/// it; Craving SOS is in the middle. Touch the bar and the pill swells into a clear glass lens, taller than the bar,
/// that follows the finger, magnifies the icons under it and splits light into a rainbow at its rim; let go and it
/// settles back into the pill, on the tab nearest the finger. With Reduce Motion the pill simply moves. On iPhone
/// Duo the dock can stand on its side along the edge where the system puts vertical bars (S18.13), icons only and
/// without the lens.
public struct DXDock: View {
    let items: [DXDockItem]
    @Binding var selection: String
    let sosAction: () -> Void
    /// Where Craving SOS sits among the tabs; nil puts it at the end.
    let sosPosition: Int?
    let axis: Axis

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Tab and SOS frames, and the bar's size, in the bar's own space.
    @State private var frames: [String: CGRect] = [:]
    @State private var barSize: CGSize = .zero
    /// The lens's centre while a finger is on the bar; nil when nothing touches it.
    @State private var lensX: CGFloat?
    /// The tab nearest the lens, for a tick as the lens passes each one.
    @State private var hovered: String?

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

    private static let space = "dx.dock"
    private static let sosID = "dx.dock.sos"
    /// The lens is about two tabs wide and rises 11 pt above and below the bar, like WhatsApp's.
    private static let lensSize = CGSize(width: 2 * DX.Size.tab, height: thickness + 22)
    private static let magnification: CGFloat = 1.28

    /// At rest the pill is black at 55% on the dark bar, like WhatsApp's; a faint grey on the light one.
    private static let pillFill = Color(light: (0x11140A, 0.09), dark: (0x000000, 0.55))

    private var lensShown: Bool { lensX != nil }

    public var body: some View {
        bar(interactive: true)
            .background(alignment: .topLeading) { pill }
            .overlay(alignment: .topLeading) {
                if let lensX { magnifier(at: lensX) }
            }
            .coordinateSpace(.named(Self.space))
            .onGeometryChange(for: CGSize.self) { $0.size } action: { barSize = $0 }
            .modifier(DockBackground())
            .simultaneousGesture(touch, including: axis == .horizontal && !reduceMotion ? .all : .none)
            .dynamicTypeSize(...DynamicTypeSize.xLarge)
            .sensoryFeedback(DX.Haptic.select, trigger: hovered) { old, new in old != nil && new != nil }
            .sensoryFeedback(DX.Haptic.select, trigger: selection)
    }

    // MARK: Items

    /// The tabs and SOS, padded to the bar's size. Drawn twice while touched: once to use, once magnified in the lens.
    private func bar(interactive: Bool) -> some View {
        let split = min(sosPosition ?? items.count, items.count)
        let layout = axis == .horizontal ? AnyLayout(HStackLayout(spacing: 4)) : AnyLayout(VStackLayout(spacing: 4))
        return layout {
            ForEach(items.prefix(split)) { tab($0, interactive: interactive) }
            sos(interactive: interactive)
            ForEach(items.dropFirst(split)) { tab($0, interactive: interactive) }
        }
        .padding(DX.Space.xs)
        .frame(width: axis == .vertical ? Self.thickness : nil, height: axis == .horizontal ? Self.thickness : nil)
    }

    @ViewBuilder
    private func tab(_ item: DXDockItem, interactive: Bool) -> some View {
        let active = item.id == selection
        let label = tabLabel(item, active: active)
        if interactive {
            Button { select(item.id) } label: { label }
                .buttonStyle(.plain)
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(Self.space)) } action: { frames[item.id] = $0 }
                .accessibilityLabel(Text(item.title))
                .accessibilityAddTraits(active ? [.isSelected, .isButton] : .isButton)
        } else {
            label
        }
    }

    private func tabLabel(_ item: DXDockItem, active: Bool) -> some View {
        let labelled = active && axis == .horizontal
        return HStack(spacing: 6) {
            Image(systemName: item.systemImage)
                // Hollow until chosen, then filled in the brand colour; items pass the outline symbol.
                .symbolVariant(active ? .fill : .none)
                .font(.system(size: 18, weight: active ? .bold : .semibold))
            if labelled {
                Text(item.title)
                    .font(.custom(DX.Typeface.semibold, size: 15, relativeTo: .subheadline))
                    .lineLimit(1)
                    .fixedSize()
                    .transition(.opacity.combined(with: .scale(scale: 0.7, anchor: .leading)))
            }
        }
        .foregroundStyle(active ? DX.Palette.accentInk : DX.Palette.text.opacity(0.85))
        .padding(.horizontal, labelled ? DX.Space.m : 0)
        .frame(minWidth: DX.Size.tab, minHeight: DX.Size.tab)
        .frame(maxHeight: DX.Size.tab)
        .contentShape(Capsule())
    }

    /// The word "SOS" in a slowly sliding rainbow (S21.4).
    @ViewBuilder
    private func sos(interactive: Bool) -> some View {
        let label = RainbowSOS()
            .frame(width: DX.Size.tab, height: DX.Size.tab)
            .contentShape(Circle())
        if interactive {
            Button(action: sosAction) { label }
                .buttonStyle(.plain)
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(Self.space)) } action: { frames[Self.sosID] = $0 }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("Craving SOS"))
                .accessibilityAddTraits(.isButton)
        } else {
            label
        }
    }

    private func select(_ id: String) {
        withAnimation(reduceMotion ? DX.Motion.reduced : Self.settle) {
            selection = id
        }
    }

    private static let settle = Animation.spring(response: 0.42, dampingFraction: 0.72)

    // MARK: Pill and lens

    /// At rest, the dark pill under the selected tab. While touched it swells into the lens's clear body, centred on
    /// the finger, and springs back into the pill when the finger lifts.
    private var pill: some View {
        let rest = frames[selection] ?? .zero
        let size = lensShown ? Self.lensSize : rest.size
        let center = lensX.map { CGPoint(x: $0, y: barSize.height / 2) } ?? CGPoint(x: rest.midX, y: rest.midY)
        return Capsule()
            .fill(lensShown ? DX.Palette.text.opacity(0.04) : Self.pillFill)
            .frame(width: size.width, height: size.height)
            .shadow(color: .black.opacity(lensShown ? 0.28 : 0), radius: 14, y: 6)
            .offset(x: center.x - size.width / 2, y: center.y - size.height / 2)
            .opacity(frames[selection] == nil ? 0 : 1)
            .allowsHitTesting(false)
    }

    /// The bar again, larger, seen through the lens: magnified in the middle and stretched a little more at the rim,
    /// where real glass bends light most, with the rainbow edge on top.
    private func magnifier(at x: CGFloat) -> some View {
        let size = Self.lensSize
        let origin = CGPoint(x: x - size.width / 2, y: barSize.height / 2 - size.height / 2)
        let anchor = UnitPoint(x: barSize.width > 0 ? x / barSize.width : 0.5, y: 0.5)
        let lens = Capsule().frame(width: size.width, height: size.height).offset(x: origin.x, y: origin.y)
        let rim = Capsule()
            .strokeBorder(lineWidth: 12)
            .blur(radius: 4)
            .frame(width: size.width, height: size.height)
            .offset(x: origin.x, y: origin.y)
        return ZStack(alignment: .topLeading) {
            bar(interactive: false)
                .scaleEffect(Self.magnification, anchor: anchor)
                .mask(alignment: .topLeading) { lens }
            bar(interactive: false)
                .scaleEffect(Self.magnification * 1.14, anchor: anchor)
                .blur(radius: 1.2)
                .mask(alignment: .topLeading) { rim.mask(alignment: .topLeading) { lens } }
            LensRim(phase: Double(x))
                .frame(width: size.width, height: size.height)
                .offset(x: origin.x, y: origin.y)
        }
        .frame(width: barSize.width, height: barSize.height, alignment: .topLeading)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .transition(.opacity.combined(with: .scale(scale: 0.7, anchor: anchor)))
    }

    /// The lens follows the finger along the bar; letting go after a drag picks the nearest tab. A tap without a drag
    /// belongs to the button under it: the lens swells, then settles on whatever the tap chose.
    private var touch: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named(Self.space))
            .onChanged { value in
                let centres = frames.values.map(\.midX)
                guard let first = centres.min(), let last = centres.max() else { return }
                let x = min(max(value.location.x, first), last)
                withAnimation(lensX == nil ? Animation.spring(response: 0.3, dampingFraction: 0.66)
                                           : Animation.interactiveSpring(response: 0.18, dampingFraction: 0.86)) {
                    lensX = x
                }
                hovered = nearestTab(to: x)
            }
            .onEnded { value in
                if abs(value.translation.width) > 10, let target = nearestTab(to: lensX ?? value.location.x) {
                    select(target)
                }
                withAnimation(Self.settle) { lensX = nil }
                hovered = nil
            }
    }

    private func nearestTab(to x: CGFloat) -> String? {
        items.compactMap { item in frames[item.id].map { (item.id, abs($0.midX - x)) } }.min { $0.1 < $1.1 }?.0
    }
}

/// The lens's edge, as in WhatsApp's: a thin dark outline, light split into a rainbow that is strongest at the two
/// ends, and a white highlight along the top. The colours turn as the lens moves.
private struct LensRim: View {
    let phase: Double

    private static let spectrum: [Color] = ([0xFF4D6D, 0xFFA94D, 0xFFF06B, 0x6BFFA8, 0x4DD2FF, 0x7A6BFF, 0xFF4DDB, 0xFF4D6D] as [UInt32])
        .map { Color(hex: $0) }

    var body: some View {
        ZStack {
            Capsule()
                .strokeBorder(AngularGradient(colors: Self.spectrum, center: .center, angle: .degrees(phase * 0.8)), lineWidth: 4)
                .blur(radius: 2)
                .mask(LinearGradient(stops: [.init(color: .white, location: 0), .init(color: .white.opacity(0.3), location: 0.3),
                                             .init(color: .white.opacity(0.3), location: 0.7), .init(color: .white, location: 1)],
                                     startPoint: .leading, endPoint: .trailing))
            // A fainter second band inside, as light bends again on its way out of the glass.
            Capsule()
                .inset(by: 4)
                .strokeBorder(AngularGradient(colors: Self.spectrum.reversed(), center: .center, angle: .degrees(-phase * 0.5)),
                              lineWidth: 2)
                .blur(radius: 2.5)
                .opacity(0.4)
            Capsule()
                .strokeBorder(LinearGradient(colors: [.white.opacity(0.7), .white.opacity(0.05), .white.opacity(0.2)],
                                             startPoint: .top, endPoint: .bottom), lineWidth: 1)
            Capsule()
                .strokeBorder(.black.opacity(0.45), lineWidth: 0.6)
        }
        .compositingGroup()
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
