import SwiftUI
import UIKit

/// v5 components, ported from cook/site/kit/kit.css. One chip, one option row, one toggle, one card, one list row,
/// one field; every colour comes from the ground's tokens (`DX.Ground.tokens(dark:)`), so dark mode is automatic.

// MARK: - Faces

/// A face at an explicit family, size and weight that still follows Dynamic Type (for kit sizes between the seven
/// steps: the 17 pt button label, 15 pt chips, 12 pt tab labels).
public struct DXFaceModifier: ViewModifier {
    let family: DX.TypeStep.Family
    let size: CGFloat
    let weight: CGFloat
    let tracking: CGFloat
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public func body(content: Content) -> some View {
        let traits = UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(dynamicTypeSize))
        let scaled = UIFontMetrics(forTextStyle: .body).scaledValue(for: size, compatibleWith: traits)
        content
            .font(Font(DX.Typeface4.font(family, size: scaled, weight: weight) as CTFont))
            .tracking(tracking)
    }
}

public extension View {
    func dxFace(_ family: DX.TypeStep.Family, _ size: CGFloat, weight: CGFloat, tracking: CGFloat = 0) -> some View {
        modifier(DXFaceModifier(family: family, size: size, weight: weight, tracking: tracking))
    }
}

// MARK: - Icons

public extension DX {
    /// The kit's line icons (kit.js `P`), drawn on a 24 × 24 grid with round caps.
    enum Icon: String, CaseIterable, Sendable {
        case back, close, check, plus, minus, chev, down, play, pause, lock, gear, share, bell, wave, drop, moon, sun, leaf, home,
             path, chart, heart, lungs, cig, vape, pouch, patch, calendar, clock, headphones, note, star, flame, shield, hand,
             eye, globe, card, text, people, sparkle, search, medal, trophy

        public var d: String {
            switch self {
            case .back: "M15 5l-7 7 7 7"
            case .close: "M6 6l12 12M18 6L6 18"
            case .check: "M5 12.5l4.5 4.5L19 7.5"
            case .plus: "M12 5v14M5 12h14"
            case .minus: "M5 12h14"
            case .chev: "M9 6l6 6-6 6"
            case .down: "M6 9l6 6 6-6"
            case .play: "M8 5.5v13l11-6.5z"
            case .pause: "M8 5v14M16 5v14"
            case .lock: "M7 11V8a5 5 0 0110 0v3M5.5 11h13v9h-13z"
            case .gear: "M12 15.2a3.2 3.2 0 100-6.4 3.2 3.2 0 000 6.4zM19.4 13.5l1.6 1.2-2 3.4-1.9-.7a7.4 7.4 0 01-1.9 1.1L15 20.5h-4l-.3-2a7.4 7.4 0 01-1.9-1.1l-1.9.7-2-3.4 1.6-1.2a7.6 7.6 0 010-2.9L4.9 9.4l2-3.4 1.9.7a7.4 7.4 0 011.9-1.1l.3-2h4l.3 2a7.4 7.4 0 011.9 1.1l1.9-.7 2 3.4-1.6 1.2a7.6 7.6 0 010 2.9z"
            case .share: "M12 15V4M7.5 8.5L12 4l4.5 4.5M5 13v6h14v-6"
            case .bell: "M6 16V11a6 6 0 0112 0v5l1.5 2h-15zM10 20.5h4"
            case .wave: "M3 14c2.5-3 5-3 7.5 0s5 3 7.5 0 2.5-1.5 3-1.5M3 9c2.5-3 5-3 7.5 0s5 3 7.5 0"
            case .drop: "M12 3.5c3 4 6 7.2 6 10.5a6 6 0 01-12 0c0-3.3 3-6.5 6-10.5z"
            case .moon: "M19 14.5A7.5 7.5 0 019.5 5a7.5 7.5 0 109.5 9.5z"
            case .sun: "M12 16a4 4 0 100-8 4 4 0 000 8zM12 2.5v2M12 19.5v2M2.5 12h2M19.5 12h2M5.3 5.3l1.4 1.4M17.3 17.3l1.4 1.4M5.3 18.7l1.4-1.4M17.3 6.7l1.4-1.4"
            case .leaf: "M5 19c0-8 5-13 14-14 0 9-5 14-13 14zM5 19l7-7"
            case .home: "M4 10.5L12 4l8 6.5V20h-5.5v-6h-5v6H4z"
            case .path: "M9 4.5L3.5 6.8v12.7L9 17.2l6 2.3 5.5-2.3V4.5L15 6.8zM9 4.5v12.7M15 6.8v12.7"
            case .chart: "M5 20V10M12 20V4M19 20v-7"
            case .heart: "M12 20s-7-4.4-7-10a4 4 0 017-2.6A4 4 0 0119 10c0 5.6-7 10-7 10z"
            case .lungs: "M12 4v7M12 11c-2 0-3-1.5-4.5-1.5C5 9.5 4 13 4 16c0 2 1 3.5 3 3.5 2.5 0 5-2 5-6zM12 11c2 0 3-1.5 4.5-1.5C19 9.5 20 13 20 16c0 2-1 3.5-3 3.5-2.5 0-5-2-5-6z"
            case .cig: "M3 14h14v4H3zM17 14h4v4h-4zM18 11c0-2 2-2 2-4"
            case .vape: "M9 3h6v4H9zM8 7h8v14H8zM11 11h2"
            case .pouch: "M5 8h14v10a2 2 0 01-2 2H7a2 2 0 01-2-2zM8 8V6a4 4 0 018 0v2"
            case .patch: "M5 5h14v14H5zM9 9h6v6H9z"
            case .calendar: "M4 6h16v14H4zM4 10h16M8 3.5v4M16 3.5v4"
            case .clock: "M12 21a9 9 0 100-18 9 9 0 000 18zM12 7v5l3 2"
            case .headphones: "M4 15v-3a8 8 0 0116 0v3M4 15h3v5H5a1 1 0 01-1-1zM20 15h-3v5h2a1 1 0 001-1z"
            case .note: "M6 3.5h9l3 3V20.5H6zM9 11h6M9 15h6"
            case .star: "M12 3.5l2.6 5.4 5.9.8-4.3 4.1 1 5.8L12 16.8l-5.2 2.8 1-5.8-4.3-4.1 5.9-.8z"
            case .flame: "M12 21c-4 0-6.5-2.6-6.5-6 0-4 4-6 4-10 2 1 6 4 6 8.5 1-1 1.5-2 1.5-3 1.5 1.5 1.5 3 1.5 4.5 0 3.4-2.5 6-6.5 6z"
            case .shield: "M12 3l7 3v6c0 4.5-3 7.5-7 9-4-1.5-7-4.5-7-9V6z"
            case .hand: "M8 13V6.5a1.5 1.5 0 013 0V12M11 11V5a1.5 1.5 0 013 0v6M14 11V6.5a1.5 1.5 0 013 0V14c0 4-2.5 7-6 7-2.5 0-4-1.2-5.5-3.5L4 15a1.5 1.5 0 012.5-1.6L8 15"
            case .eye: "M2.5 12S6 5.5 12 5.5 21.5 12 21.5 12 18 18.5 12 18.5 2.5 12 2.5 12zM12 15a3 3 0 100-6 3 3 0 000 6z"
            case .globe: "M12 21a9 9 0 100-18 9 9 0 000 18zM3 12h18M12 3c3 3 3 15 0 18M12 3c-3 3-3 15 0 18"
            case .card: "M3.5 6h17v12h-17zM3.5 10h17"
            case .text: "M5 6h14M5 11h14M5 16h9"
            case .people: "M9 11a3.5 3.5 0 100-7 3.5 3.5 0 000 7zM2.5 20c0-3.6 2.9-6 6.5-6s6.5 2.4 6.5 6M16 4.5a3.5 3.5 0 010 6.5M18 14c2 .6 3.5 2.6 3.5 6"
            case .sparkle: "M12 3v5M12 16v5M3 12h5M16 12h5"
            case .search: "M10.5 17a6.5 6.5 0 100-13 6.5 6.5 0 000 13zM15.5 15.5L20 20"
            case .medal: "M12 21a6 6 0 100-12 6 6 0 000 12zM9 9.5L6 3h4l2 4 2-4h4l-3 6.5"
            case .trophy: "M7 4h10v5a5 5 0 01-10 0zM7 6H4c0 3 1.5 4.5 3.5 4.5M17 6h3c0 3-1.5 4.5-3.5 4.5M12 14v4M8 20.5h8"
            }
        }
    }
}

/// A kit icon: the 24 × 24 path scaled to `size`, stroked at `weight` (kit default 2.2), or filled.
public struct DXIcon: View {
    let icon: DX.Icon
    let size: CGFloat
    let weight: CGFloat
    let filled: Bool

    public init(_ icon: DX.Icon, size: CGFloat = 24, weight: CGFloat = 2.2, filled: Bool = false) {
        self.icon = icon
        self.size = size
        self.weight = weight
        self.filled = filled
    }

    public var body: some View {
        let shape = DXIconShape(d: icon.d)
        ZStack {
            if filled { shape.fill() }
            shape.stroke(style: StrokeStyle(lineWidth: weight * size / 24, lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// A 24 × 24 SVG path scaled to its frame.
public struct DXIconShape: Shape {
    let d: String
    public init(d: String) { self.d = d }
    public func path(in rect: CGRect) -> Path {
        SVGPath.path(d).applying(CGAffineTransform(scaleX: rect.width / 24, y: rect.height / 24))
            .offsetBy(dx: rect.minX, dy: rect.minY)
    }
}

// MARK: - Ground environment

private struct DXGroundKey: EnvironmentKey {
    static let defaultValue: DX.Ground = .reading
}

public extension EnvironmentValues {
    /// The ground the content below sits on; v5 components read their tokens from it.
    var dxGround: DX.Ground {
        get { self[DXGroundKey.self] }
        set { self[DXGroundKey.self] = newValue }
    }
}

public extension View {
    /// Paints a ground behind this view (edge to edge) and tells v5 components below which ground they sit on.
    func dxGround(_ ground: DX.Ground, paint: Bool = true) -> some View {
        environment(\.dxGround, ground)
            .foregroundStyle(ground.resolved.ink)
            .background {
                if paint {
                    if ground.resolved == .ocean {
                        DX.Ground.oceanGradient.ignoresSafeArea()
                    } else {
                        ground.background.ignoresSafeArea()
                    }
                }
            }
    }
}

// MARK: - Cards

/// A card (kit `.card`): the ground's card fill, radius 22, padding 18. Hairline on reading, table and every dark
/// ground. `flat` uses card-2 with no line; `tight` pads 14 × 16.
public struct DXCardModifier: ViewModifier {
    let flat: Bool
    let tight: Bool
    let radius: CGFloat
    let ground: DX.Ground?
    @Environment(\.dxGround) private var envGround
    @Environment(\.colorScheme) private var scheme

    public func body(content: Content) -> some View {
        let g = (ground ?? envGround).resolved
        let t = g.tokens(dark: scheme == .dark)
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        content
            .padding(.vertical, tight ? 14 : 18)
            .padding(.horizontal, tight ? 16 : 18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(flat ? g.card2 : g.card, in: shape)
            .overlay { if t.hairline && !flat { shape.strokeBorder(g.line, lineWidth: 1) } }
    }
}

public extension View {
    func dxCard(on ground: DX.Ground? = nil, flat: Bool = false, tight: Bool = false, radius: CGFloat = DX.Layout.cardRadius) -> some View {
        modifier(DXCardModifier(flat: flat, tight: tight, radius: radius, ground: ground))
    }
}

/// `DXCard { ... }`: the card as a container.
public struct DXCard<Content: View>: View {
    let flat: Bool
    let tight: Bool
    let ground: DX.Ground?
    let content: Content

    public init(on ground: DX.Ground? = nil, flat: Bool = false, tight: Bool = false, @ViewBuilder content: () -> Content) {
        self.ground = ground
        self.flat = flat
        self.tight = tight
        self.content = content()
    }

    public var body: some View {
        content.dxCard(on: ground, flat: flat, tight: tight)
    }
}

// MARK: - Chip

/// The one chip (kit `.chip`): 44 pt high, radius 14, 15 pt semibold on the card; selected is the warm tint with a
/// 2 pt edge and bold words.
public struct DXChip<Label: View>: View {
    let isOn: Bool
    let ground: DX.Ground?
    let action: () -> Void
    let label: Label
    @Environment(\.dxGround) private var envGround
    @Environment(\.colorScheme) private var scheme

    public init(isOn: Bool, on ground: DX.Ground? = nil, action: @escaping () -> Void, @ViewBuilder label: () -> Label) {
        self.isOn = isOn
        self.ground = ground
        self.action = action
        self.label = label()
    }

    public var body: some View {
        let g = (ground ?? envGround).resolved
        let t = g.tokens(dark: scheme == .dark)
        let shape = RoundedRectangle(cornerRadius: DX.Layout.chipRadius, style: .continuous)
        Button(action: action) {
            label
                .dxFace(.body, 15, weight: isOn ? 700 : 600)
                .foregroundStyle(g.ink)
                .padding(.horizontal, 16)
                .frame(minHeight: 44)
                .background(isOn ? g.selTint : g.card, in: shape)
                .overlay {
                    if isOn {
                        shape.strokeBorder(g.selEdge, lineWidth: 2)
                    } else if t.hairline {
                        shape.strokeBorder(g.line, lineWidth: 1)
                    }
                }
                .contentShape(shape)
                .animation(DX.Move.arrive.speed(2.4), value: isOn)
        }
        .buttonStyle(.dxPress)
        .sensoryFeedback(DX.Haptic.select, trigger: isOn)
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
    }
}

public extension DXChip where Label == Text {
    init(_ title: LocalizedStringKey, isOn: Bool, on ground: DX.Ground? = nil, action: @escaping () -> Void) {
        self.init(isOn: isOn, on: ground, action: action) { Text(title) }
    }

    init(verbatim title: String, isOn: Bool, on ground: DX.Ground? = nil, action: @escaping () -> Void) {
        self.init(isOn: isOn, on: ground, action: action) { Text(verbatim: title) }
    }
}

// MARK: - Option row

/// The one option row (kit `.opt`): 64 pt minimum, radius 18, a hairline; a radio on the right (a rounded square for
/// `multi`). Selected: the warm tint, a 2 pt edge, and the radio fills with a tick.
public struct DXOptionRow<Leading: View>: View {
    let title: Text
    let detail: Text?
    let isOn: Bool
    let multi: Bool
    let ground: DX.Ground?
    let action: () -> Void
    let leading: Leading
    @Environment(\.dxGround) private var envGround

    public init(_ title: Text, detail: Text? = nil, isOn: Bool, multi: Bool = false, on ground: DX.Ground? = nil,
                action: @escaping () -> Void, @ViewBuilder leading: () -> Leading) {
        self.title = title
        self.detail = detail
        self.isOn = isOn
        self.multi = multi
        self.ground = ground
        self.action = action
        self.leading = leading()
    }

    public var body: some View {
        let g = (ground ?? envGround).resolved
        let shape = RoundedRectangle(cornerRadius: DX.Layout.optionRadius, style: .continuous)
        Button(action: action) {
            HStack(spacing: 14) {
                leading
                VStack(alignment: .leading, spacing: 2) {
                    title.dxFace(.display, 17, weight: 700).foregroundStyle(g.ink)
                    if let detail { detail.dxType(.footnote).foregroundStyle(g.muted) }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                DXRadio(isOn: isOn, multi: multi, ground: g)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 64)
            .background(isOn ? g.selTint : g.card, in: shape)
            .overlay { shape.strokeBorder(isOn ? g.selEdge : g.line, lineWidth: isOn ? 2 : 1) }
            .contentShape(shape)
            .animation(DX.Move.arrive.speed(2.4), value: isOn)
        }
        .buttonStyle(.dxPress)
        .sensoryFeedback(DX.Haptic.select, trigger: isOn)
        .accessibilityAddTraits(isOn ? [.isSelected] : [])
    }
}

public extension DXOptionRow where Leading == EmptyView {
    init(_ title: Text, detail: Text? = nil, isOn: Bool, multi: Bool = false, on ground: DX.Ground? = nil, action: @escaping () -> Void) {
        self.init(title, detail: detail, isOn: isOn, multi: multi, on: ground, action: action) { EmptyView() }
    }
}

/// The option row's radio: a 24 pt ring at 38% ink; on, a solid `--sel` disc (or rounded square) with a tick.
public struct DXRadio: View {
    let isOn: Bool
    let multi: Bool
    let ground: DX.Ground

    public init(isOn: Bool, multi: Bool = false, ground: DX.Ground) {
        self.isOn = isOn
        self.multi = multi
        self.ground = ground
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: multi ? 7 : 12, style: .continuous)
        ZStack {
            if isOn {
                shape.fill(ground.sel)
                DXIconShape(d: DX.Icon.check.d)
                    .stroke(ground.selFg, style: StrokeStyle(lineWidth: 3 * 14 / 24, lineCap: .round, lineJoin: .round))
                    .frame(width: 14, height: 14)
            } else {
                shape.strokeBorder(ground.ink.opacity(0.38), lineWidth: 2)
            }
        }
        .frame(width: 24, height: 24)
        .accessibilityHidden(true)
    }
}

// MARK: - Toggle

/// The kit toggle: 52 × 32, coral #F26A45 when on, the ink at 30% when off, a white 26 pt knob.
public struct DXToggleStyle: ToggleStyle {
    @Environment(\.dxGround) private var envGround
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        DXToggleBody(configuration: configuration)
    }
}

private struct DXToggleBody: View {
    let configuration: ToggleStyleConfiguration
    @Environment(\.dxGround) private var ground
    private let motion = MotionPolicy()

    var body: some View {
        HStack(spacing: 12) {
            configuration.label.frame(maxWidth: .infinity, alignment: .leading)
            ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                Capsule().fill(configuration.isOn ? Color(hex: 0xF26A45) : ground.resolved.ink.opacity(0.3))
                Circle().fill(.white)
                    .shadow(color: .black.opacity(0.3), radius: 1.5, x: 0, y: 1)
                    .frame(width: 26, height: 26)
                    .padding(3)
            }
            .frame(width: 52, height: 32)
            .animation(motion.animation(DX.Move.settle.speed(3)), value: configuration.isOn)
            .onTapGesture { configuration.isOn.toggle() }
        }
        .contentShape(Rectangle())
        .sensoryFeedback(DX.Haptic.select, trigger: configuration.isOn)
        .accessibilityElement(children: .combine)
        .accessibilityValue(configuration.isOn ? Text("On") : Text("Off"))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { configuration.isOn.toggle() }
    }
}

public extension ToggleStyle where Self == DXToggleStyle {
    static var dx: DXToggleStyle { DXToggleStyle() }
}

// MARK: - List and rows

/// A grouped list (kit `.list`): the card fill, radius 22, rows split by hairlines.
public struct DXList<Content: View>: View {
    let ground: DX.Ground?
    let content: Content
    @Environment(\.dxGround) private var envGround
    @Environment(\.colorScheme) private var scheme

    public init(on ground: DX.Ground? = nil, @ViewBuilder content: () -> Content) {
        self.ground = ground
        self.content = content()
    }

    public var body: some View {
        let g = (ground ?? envGround).resolved
        let shape = RoundedRectangle(cornerRadius: DX.Layout.cardRadius, style: .continuous)
        Group(subviews: content) { rows in
            VStack(spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    if index > 0 { Rectangle().fill(g.line).frame(height: 1) }
                    row
                }
            }
        }
            .background(g.card, in: shape)
            .overlay { if g.tokens(dark: scheme == .dark).hairline { shape.strokeBorder(g.line, lineWidth: 1) } }
            .clipShape(shape)
    }
}

/// A list row (kit `.row`): a 40 pt icon tile (radius 12, card-2), a title and detail, a trailing accessory or a
/// chevron. 56 pt minimum, padded 10 × 16.
public struct DXRow<Trailing: View>: View {
    let icon: DX.Icon?
    let title: Text
    let detail: Text?
    let chevron: Bool
    let trailing: Trailing
    @Environment(\.dxGround) private var ground

    public init(_ title: Text, detail: Text? = nil, icon: DX.Icon? = nil, chevron: Bool = true, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.detail = detail
        self.icon = icon
        self.chevron = chevron
        self.trailing = trailing()
    }

    public var body: some View {
        let g = ground.resolved
        HStack(spacing: 14) {
            if let icon {
                DXIcon(icon, size: 22)
                    .foregroundStyle(g.ink)
                    .frame(width: 40, height: 40)
                    .background(g.card2, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            VStack(alignment: .leading, spacing: 3) {
                title.dxFace(.display, 16, weight: 700).foregroundStyle(g.ink)
                if let detail { detail.dxType(.caption).foregroundStyle(g.muted) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            trailing
            if chevron {
                DXIcon(.chev, size: 18).foregroundStyle(g.muted)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(minHeight: 56)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

public extension DXRow where Trailing == EmptyView {
    init(_ title: Text, detail: Text? = nil, icon: DX.Icon? = nil, chevron: Bool = true) {
        self.init(title, detail: detail, icon: icon, chevron: chevron) { EmptyView() }
    }
}

// MARK: - Field

/// The kit field: 52 pt minimum, radius 16, card-2, 16 pt medium words.
public struct DXFieldStyle: TextFieldStyle {
    @Environment(\.dxGround) private var ground
    public init() {}

    public func _body(configuration: TextField<Self._Label>) -> some View {
        configuration.modifier(DXFieldChrome())
    }
}

/// The field's look, for a `TextField` (via `.textFieldStyle(.dx)`) or anything field-shaped (`.dxField()`).
public struct DXFieldChrome: ViewModifier {
    @Environment(\.dxGround) private var ground
    public init() {}

    public func body(content: Content) -> some View {
        content
            .dxFace(.body, 16, weight: 500)
            .foregroundStyle(ground.resolved.ink)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(minHeight: 52)
            .background(ground.resolved.card2, in: RoundedRectangle(cornerRadius: DX.Layout.fieldRadius, style: .continuous))
    }
}

public extension TextFieldStyle where Self == DXFieldStyle {
    static var dx: DXFieldStyle { DXFieldStyle() }
}

// MARK: - Nav row

/// The 44 pt round icon button (kit `.icon-btn`): card-2 disc, 20 pt icon.
public struct DXIconButton: View {
    let icon: DX.Icon
    let label: LocalizedStringKey
    let action: () -> Void
    @Environment(\.dxGround) private var ground

    public init(_ icon: DX.Icon, label: LocalizedStringKey, action: @escaping () -> Void) {
        self.icon = icon
        self.label = label
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            DXIcon(icon, size: 20)
                .foregroundStyle(ground.resolved.ink)
                .frame(width: 44, height: 44)
                .background(ground.resolved.card2, in: Circle())
        }
        .buttonStyle(.dxPress)
        .accessibilityLabel(Text(label))
    }
}

/// The nav row (kit `.nav`): the leading control on the left, a centred title or progress, an optional trailing
/// item. 52 pt high, padded 16.
public struct DXNavRow<Center: View, Trailing: View>: View {
    let leading: DX.Icon?
    let leadingLabel: LocalizedStringKey
    let onLeading: () -> Void
    let center: Center
    let trailing: Trailing

    public init(leading: DX.Icon? = .back, label: LocalizedStringKey = "Back", onLeading: @escaping () -> Void = {},
                @ViewBuilder center: () -> Center, @ViewBuilder trailing: () -> Trailing) {
        self.leading = leading
        self.leadingLabel = label
        self.onLeading = onLeading
        self.center = center()
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(spacing: 12) {
            if let leading {
                DXIconButton(leading, label: leadingLabel, action: onLeading)
            } else {
                Color.clear.frame(width: 44, height: 44)
            }
            center.frame(maxWidth: .infinity)
            ZStack { Color.clear.frame(width: 44, height: 44); trailing }
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
    }
}

public extension DXNavRow where Trailing == EmptyView {
    init(leading: DX.Icon? = .back, label: LocalizedStringKey = "Back", onLeading: @escaping () -> Void = {}, @ViewBuilder center: () -> Center) {
        self.init(leading: leading, label: label, onLeading: onLeading, center: center) { EmptyView() }
    }
}

public extension DXNavRow where Center == Text, Trailing == EmptyView {
    init(_ title: LocalizedStringKey, leading: DX.Icon? = .back, label: LocalizedStringKey = "Back", onLeading: @escaping () -> Void = {}) {
        self.init(leading: leading, label: label, onLeading: onLeading) { Text(title) }
    }
}

// MARK: - Progress

/// The kit progress bar: 8 pt on the track, filled in the ink; `sun` rides a 14 pt amber dot with a rim on the end
/// (the onboarding pattern). The fill moves on the settle curve.
public struct DXProgress: View {
    let value: Double
    let sun: Bool
    @Environment(\.dxGround) private var ground
    private let motion = MotionPolicy()

    public init(_ value: Double, sun: Bool = false) {
        self.value = value
        self.sun = sun
    }

    public var body: some View {
        let g = ground.resolved
        let p = min(1, max(0, value))
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(g.track)
                Capsule().fill(g.ink).frame(width: max(8, proxy.size.width * p))
                if sun {
                    Circle()
                        .fill(Color(hex: 0xFFC93C))
                        .overlay(Circle().strokeBorder(Color(hex: 0xF29A2E), lineWidth: 2))
                        .background(Circle().fill(g.background).padding(-2))
                        .shadow(color: Color(hex: 0xFFC93C).opacity(0.5), radius: 5)
                        .frame(width: 14, height: 14)
                        .offset(x: max(8, proxy.size.width * p) - 7)
                }
            }
            .animation(motion.animation(DX.Move.settle), value: p)
        }
        .frame(height: 8)
        .accessibilityElement()
        .accessibilityValue(Text("\(Int((p * 100).rounded())) percent"))
    }
}

/// Step dots (kit `.steps`): one 6 pt bar per step, filled when done, 45% for the current one.
public struct DXSteps: View {
    let count: Int
    let current: Int
    @Environment(\.dxGround) private var ground

    public init(count: Int, current: Int) {
        self.count = count
        self.current = current
    }

    public var body: some View {
        let g = ground.resolved
        HStack(spacing: 5) {
            ForEach(0..<count, id: \.self) { i in
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(g.track)
                        Capsule().fill(g.ink).frame(width: i < current ? proxy.size.width : i == current ? proxy.size.width * 0.45 : 0)
                    }
                }
                .frame(height: 6)
            }
        }
        .accessibilityElement()
        .accessibilityValue(Text("Step \(current + 1) of \(count)"))
    }
}

// MARK: - Dock and tab fade

/// The bottom fade (kit `.dock`): from clear to the ground at 34%, under the primary button area. Content above never
/// looks clipped.
public struct DXActionDock<Content: View>: View {
    let content: Content
    @Environment(\.dxGround) private var ground

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        VStack(spacing: 10) { content }
            .padding(.horizontal, DX.Layout.gutter)
            .padding(.top, 36)
            .padding(.bottom, 12)
            .background {
                LinearGradient(stops: [
                    .init(color: ground.resolved.background.opacity(0), location: 0),
                    .init(color: ground.resolved.background, location: 0.34),
                ], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .bottom)
            }
    }
}

/// The fade under the tab bar (kit `.tabfade`): 150 pt, the ground at 0, 85% at 30%, solid from 40%.
public struct DXTabFade: View {
    let color: Color

    public init(_ color: Color) { self.color = color }

    public var body: some View {
        LinearGradient(stops: [
            .init(color: color.opacity(0), location: 0),
            .init(color: color.opacity(0.85), location: 0.3),
            .init(color: color, location: 0.4),
        ], startPoint: .top, endPoint: .bottom)
        .frame(height: DX.Layout.tabFadeHeight)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Toast and sheet grab

/// A toast (kit `.toast`): ink in light, cream in dark, radius 20, 15 pt semibold.
public struct DXToast<Leading: View>: View {
    let text: Text
    let leading: Leading

    public init(_ text: Text, @ViewBuilder leading: () -> Leading) {
        self.text = text
        self.leading = leading()
    }

    public var body: some View {
        HStack(spacing: 12) {
            leading
            text.dxFace(.body, 15, weight: 600).frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(Color(light: 0xFFF8EE, dark: 0x1E1A3A))
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(light: 0x1E1A3A, dark: 0xFFF8EE), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.25), radius: 15, x: 0, y: 12)
    }
}

/// The sheet's grab handle: 40 × 5 on the track.
public struct DXGrab: View {
    @Environment(\.dxGround) private var ground
    public init() {}
    public var body: some View {
        Capsule().fill(ground.resolved.track).frame(width: 40, height: 5).accessibilityHidden(true)
    }
}
