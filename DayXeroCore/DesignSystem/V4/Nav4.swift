import CoreText
import SwiftUI

/// The five tabs (v5, kit.js `tabbar`): Today · Program · SOS (raised) · Calm · Progress. Was four (S27.11); Calm
/// came back as a tab so the calm tools are one tap away, and SOS still opens Craving SOS rather than a tab.
public enum V4Tab: String, CaseIterable, Sendable {
    case today, program, sos, calm, progress

    public var label: String {
        switch self {
        case .today: "Today"
        case .program: "Program"
        case .sos: "SOS / Breathe"
        case .calm: "Calm"
        case .progress: "Progress"
        }
    }

    /// The kit's line icons.
    var kitIcon: DX.Icon {
        switch self {
        case .today: .home
        case .program: .path
        case .sos: .wave
        case .calm: .leaf
        case .progress: .chart
        }
    }
}

/// A 24 × 24 SVG icon path scaled to its frame.
struct IconShape: Shape {
    let d: String
    func path(in rect: CGRect) -> Path {
        SVGPath.path(d).applying(CGAffineTransform(scaleX: rect.width / 24, y: rect.height / 24))
            .offsetBy(dx: rect.minX, dy: rect.minY)
    }
}

/// The floating tab bar (kit `.tabbar`): a 70 pt rounded panel (radius 28) on the ground's card at 96% with a blur,
/// a soft shadow and a hairline, inset 14 pt from the sides. Icons are the kit's line icons (2.6 pt on the selected
/// tab, 2.1 off) over 12 pt labels; the selected tab is the ink, the others the ink at 72%.
///
/// SOS is a raised 58 pt ocean circle (#1F3C8C) with the wave, its label under it, lifted 44 pt so it breaks the
/// bar's top edge. Its glow breathes at 0.1 Hz with Jelli (4 in, 6 out); with Reduce Motion it stays still.
public struct V4TabBar: View {
    /// The bar's height, without the raised SOS button.
    public static let height: CGFloat = 70
    /// How far the SOS button rises above the bar's top edge (58 pt circle, 44 pt negative margin, centred row).
    public static let sosRise: CGFloat = 20
    /// The space tab content keeps clear at the bottom (kit `.scroll.with-tabs`: 120 pt from the screen's bottom).
    public static let contentInset: CGFloat = height + sosRise + DX.Space.xxs + DX.Space.m

    @Binding var selection: V4Tab
    let ground: DX.Ground?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dxGround) private var envGround

    public init(selection: Binding<V4Tab>, ground: DX.Ground? = nil) {
        _selection = selection
        self.ground = ground
    }

    public var body: some View {
        let g = (ground ?? envGround).resolved
        let dark = scheme == .dark
        let shape = RoundedRectangle(cornerRadius: DX.Layout.tabBarRadius, style: .continuous)
        HStack(spacing: 0) {
            ForEach(V4Tab.allCases, id: \.self) { tab in
                if tab == .sos {
                    sosButton(g)
                } else {
                    tabButton(tab, g)
                }
            }
        }
        .frame(height: Self.height)
        .background {
            ZStack {
                shape.fill(.ultraThinMaterial)
                shape.fill(g.card.opacity(0.96))
            }
            .shadow(color: dark ? .black.opacity(0.45) : Color(hex: 0x1E1A3A).opacity(0.18), radius: 15, x: 0, y: 10)
        }
        .overlay(shape.strokeBorder(g.line, lineWidth: 1))
        .padding(.horizontal, 14)
        .sensoryFeedback(DX.Haptic.select, trigger: selection)
    }

    private func tabButton(_ tab: V4Tab, _ g: DX.Ground) -> some View {
        let on = tab == selection
        let color = on ? g.ink : g.ink.opacity(0.72)
        return Button { selection = tab } label: {
            VStack(spacing: 4) {
                DXIcon(tab.kitIcon, size: 24, weight: on ? 2.6 : 2.1)
                Text(tab.label)
                    .font(DX.Typeface4.font(.body, size: 12, weight: on ? 700 : 600).swiftUI)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, minHeight: 58)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.label)
        .accessibilityAddTraits(on ? [.isSelected] : [])
        // Labels stay 12 pt like the system tab bar; long-press shows them large at accessibility sizes.
        .accessibilityShowsLargeContentViewer()
    }

    /// The raised SOS button: a 58 pt ocean circle with the wave, lifted above the bar, its name under it.
    private func sosButton(_ g: DX.Ground) -> some View {
        let ocean = Color(hex: 0x1F3C8C)
        let circle: CGFloat = 58
        return Button { selection = .sos } label: {
            VStack(spacing: 3) {
                ZStack {
                    SOSBreathGlow(color: Color(hex: 0x3A68C8), diameter: circle)
                    Circle().fill(ocean)
                        .shadow(color: ocean.opacity(0.4), radius: 10, x: 0, y: 8)
                    DXIcon(.wave, size: 26, weight: 2.4)
                        .foregroundStyle(Color(hex: 0xFFF8EE))
                }
                .frame(width: circle, height: circle)
                Text(V4Tab.sos.label)
                    .font(DX.Typeface4.font(.body, size: 12, weight: 600).swiftUI)
                    .foregroundStyle(g.muted)
                    .lineLimit(1)
                    .fixedSize()
            }
            .frame(maxWidth: .infinity)
            .offset(y: -Self.sosRise)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        // UI tests and VoiceOver find it by this name; the hint says what it does.
        .accessibilityLabel(String(localized: "Craving SOS"))
        .accessibilityHint(String(localized: "Breathe through a craving with Jelli"))
        .accessibilityShowsLargeContentViewer()
    }
}

/// The SOS button's glow: a soft ring that swells on the in-breath and settles on the out-breath, one breath every
/// 10 seconds (0.1 Hz), in step with Jelli. Still, and a little visible, with Reduce Motion.
struct SOSBreathGlow: View {
    let color: Color
    let diameter: CGFloat
    private let motion = MotionPolicy()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: !motion.breathes)) { timeline in
            let breath = motion.breathes ? DX.Move.breath(at: timeline.date.timeIntervalSinceReferenceDate) : 0.3
            Circle()
                .fill(color.opacity(0.28 - 0.14 * breath))
                .frame(width: diameter, height: diameter)
                .scaleEffect(1 + 0.22 * breath)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

extension UIFont {
    var swiftUI: Font { Font(self as CTFont) }
}

/// Chat pieces (design doc §6, patterns 3–5).

/// Reply bubble: right-aligned, radius 20 20 4 20, ink fill, with an Edit link under it.
public struct ReplyBubble: View {
    let text: String
    let ground: DX.Ground
    let onEdit: (() -> Void)?

    public init(_ text: String, ground: DX.Ground = .lilac, onEdit: (() -> Void)? = nil) {
        self.text = text
        self.ground = ground
        self.onEdit = onEdit
    }

    public var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(text)
                .dxType(.body)
                .foregroundStyle(ground.background)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(ground.ink, in: UnevenRoundedRectangle(topLeadingRadius: 20, bottomLeadingRadius: 20,
                                                                  bottomTrailingRadius: 4, topTrailingRadius: 20, style: .continuous))
            if let onEdit {
                Button("Edit", action: onEdit)
                    .dxType(.footnote)
                    .foregroundStyle(ground.muted)
                    .frame(minHeight: DX.Layout.touchTarget)
                    .accessibilityLabel("Edit answer")
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

/// Typing dots: three 8 pt dots at 0.6, 0.4 and 0.25 opacity.
public struct TypingDots: View {
    let ground: DX.Ground
    public init(ground: DX.Ground = .lilac) { self.ground = ground }

    public var body: some View {
        HStack(spacing: 5) {
            ForEach([0.6, 0.4, 0.25], id: \.self) { o in
                Circle().fill(ground.ink.opacity(o)).frame(width: 8, height: 8)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(DX.Fill.cardOnColour, in: Capsule())
        .accessibilityLabel("Typing")
    }
}

/// Answer tray: a sheet at the bottom of chat with a "YOUR ANSWER" caption, a two-column
/// grid of 48 pt chips, an optional "More…" chip and "Next · n of 3".
public struct AnswerTray: View {
    let options: [String]
    @Binding var selection: Set<String>
    let multiple: Bool
    let step: Int
    let of: Int
    let onMore: (() -> Void)?
    let onNext: () -> Void
    @Environment(\.colorScheme) private var scheme

    public init(options: [String], selection: Binding<Set<String>>, multiple: Bool, step: Int, of: Int,
                onMore: (() -> Void)? = nil, onNext: @escaping () -> Void) {
        self.options = options
        _selection = selection
        self.multiple = multiple
        self.step = step
        self.of = of
        self.onMore = onMore
        self.onNext = onNext
    }

    public var body: some View {
        let ink = DX.Ground.reading.ink
        VStack(alignment: .leading, spacing: 12) {
            Text("YOUR ANSWER").dxType(.caption).dxInk(.reading, muted: true)
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                ForEach(options, id: \.self) { option in
                    let on = selection.contains(option)
                    Button {
                        if multiple {
                            if on { selection.remove(option) } else { selection.insert(option) }
                        } else {
                            selection = [option]
                        }
                    } label: {
                        Text(option)
                            .dxType(.footnote)
                            .foregroundStyle(on ? DX.Ground.reading.background : ink)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(on ? ink : DX.Fill.surface, in: RoundedRectangle(cornerRadius: DX.Layout.answerChipRadius, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(on ? [.isSelected] : [])
                }
                if let onMore {
                    Button("More…", action: onMore)
                        .dxType(.footnote)
                        .foregroundStyle(ink)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(RoundedRectangle(cornerRadius: DX.Layout.answerChipRadius, style: .continuous).strokeBorder(ink.opacity(0.3), lineWidth: 1.5))
                        .buttonStyle(.plain)
                }
            }
            Button("Next · \(step) of \(of)", action: onNext)
                .buttonStyle(.dx(.primary, on: .reading))
                .disabled(selection.isEmpty)
        }
        .padding(.horizontal, DX.Layout.gutter)
        .padding(.top, 18)
        .padding(.bottom, 8)
        .background(Color(hex: scheme == .dark ? 0x182034 : 0xFFFFFF),
                    in: UnevenRoundedRectangle(topLeadingRadius: 28, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 28, style: .continuous))
        .sensoryFeedback(DX.Haptic.select, trigger: selection)
    }
}
