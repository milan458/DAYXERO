import CoreText
import SwiftUI

/// The four tabs (S27.11, 1 Nov 2026): Today · Program · SOS · Progress. Evening folded into Today's evening and
/// night states; Me became Progress, with Settings behind its gear. Was five (decision 21).
public enum V4Tab: String, CaseIterable, Sendable {
    case today, program, sos, progress

    public var label: String {
        switch self {
        case .today: "Today"
        case .program: "Program"
        case .sos: "SOS / Breathe"
        case .progress: "Progress"
        }
    }

    /// Monochrome outline icons (24 × 24), like the system tab bar's SF Symbols.
    var icon: String {
        switch self {
        case .today: "M3 11.5 12 4l9 7.5V20a1 1 0 0 1-1 1h-5v-6h-6v6H4a1 1 0 0 1-1-1z"
        case .program: "M12 21V11 M12 13C6 13 4 9 4 5c5 0 8 3 8 8Z M12 11c0-4 3-7 8-7 0 4-3 7-8 7Z"
        // SOS draws the lungs symbol in its raised button instead (UX-10); this wave is only a fallback.
        case .sos: "M3 12c3-4 6-4 9 0s6 4 9 0"
        case .progress: "M5 20V11 M12 20V5 M19 20v-6"
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

/// The floating tab bar (S27.11): a translucent glass capsule with monochrome outline icons and a soft lozenge
/// behind the selected tab, in the spirit of iOS 26's tab bar. It stays custom rather than `TabView` because SOS
/// opens Craving SOS instead of switching tabs, and iPhone Duo stands the dock on its side edge.
///
/// SOS (UX-10, 2 Nov 2026) is a solid ocean button with the lungs symbol, raised 6 pt above the bar and labelled
/// "SOS / Breathe", so it can be found in a hurry. Its glow breathes at 0.1 Hz, on the same 4 in, 6 out rhythm Jelli
/// breathes in Craving SOS; with Reduce Motion it stays still.
public struct V4TabBar: View {
    /// The bar's height, without the raised SOS button.
    public static let height: CGFloat = 70
    /// How far the SOS button rises above the bar's top edge.
    public static let sosRise: CGFloat = 6
    /// The space tab content keeps clear at the bottom so the bar never covers the last card (UX-11): the bar, the
    /// raised button, the gap under the bar, and 16 pt of breathing room.
    public static let contentInset: CGFloat = height + sosRise + DX.Space.xxs + DX.Space.m

    @Binding var selection: V4Tab
    @Environment(\.colorScheme) private var scheme

    public init(selection: Binding<V4Tab>) {
        _selection = selection
    }

    public var body: some View {
        let dark = scheme == .dark
        HStack(spacing: 0) {
            ForEach(V4Tab.allCases, id: \.self) { tab in
                if tab == .sos {
                    sosButton(dark: dark)
                } else {
                    tabButton(tab, dark: dark)
                }
            }
        }
        .padding(.horizontal, 6)
        .frame(height: Self.height)
        .background {
            // Glass: content shows through, softened, instead of an opaque white pill.
            Capsule().fill(.regularMaterial)
                .shadow(color: dark ? Color.black.opacity(0.45) : Color(hex: 0x1E1A3A).opacity(0.12), radius: 14, x: 0, y: 10)
        }
        .overlay(Capsule().strokeBorder(dark ? Color.white.opacity(0.14) : Color(hex: 0x1E1A3A).opacity(0.10), lineWidth: 1))
        .padding(.horizontal, 12)
        .sensoryFeedback(DX.Haptic.select, trigger: selection)
    }

    private func tabButton(_ tab: V4Tab, dark: Bool) -> some View {
        let on = tab == selection
        let color: Color = on ? Color(hex: dark ? 0xFFF8EE : 0x1E1A3A) : Color(hex: dark ? 0xB8B3D9 : 0x5E5975)
        return Button { selection = tab } label: {
            VStack(spacing: 3) {
                IconShape(d: tab.icon)
                    .stroke(color, style: StrokeStyle(lineWidth: on ? 2.4 : 2, lineCap: .round, lineJoin: .round))
                    .frame(width: 22, height: 22)
                Text(tab.label)
                    .font(DX.Typeface4.font(.body, size: 12, weight: on ? 700 : 600).swiftUI)
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 58)
            .background(on ? (dark ? Color.white.opacity(0.12) : Color(hex: 0x1E1A3A).opacity(0.07)) : .clear, in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.label)
        .accessibilityAddTraits(on ? [.isSelected] : [])
        // Labels stay 12 pt like the system tab bar; long-press shows them large at accessibility sizes.
        .accessibilityShowsLargeContentViewer()
    }

    /// The raised SOS button: a 46 pt ocean circle with the lungs symbol, its top 6 pt above the bar, and
    /// "SOS / Breathe" under it on the same line as the other tabs' names.
    private func sosButton(dark: Bool) -> some View {
        let ocean = Color(hex: dark ? 0x3D66F0 : 0x2A52DB)
        let ink = Color(hex: dark ? 0x9CC0FF : 0x2A52DB)
        let circle: CGFloat = 46
        return Button { selection = .sos } label: {
            VStack(spacing: 2) {
                ZStack {
                    SOSBreathGlow(color: ocean, diameter: circle)
                    Circle().fill(ocean)
                        .shadow(color: ocean.opacity(0.35), radius: 6, x: 0, y: 3)
                    Image(systemName: "lungs.fill")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(Color(hex: 0xFFF8EE))
                }
                .frame(width: circle, height: circle)
                Text(V4Tab.sos.label)
                    .font(DX.Typeface4.font(.body, size: 11, weight: 800).swiftUI)
                    .foregroundStyle(ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity)
            // Centred in the 70 pt bar the stack would start 4 pt down; lift it so the circle's top sits 6 pt above.
            .offset(y: -(Self.sosRise + 4))
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { timeline in
            let breath = reduceMotion ? 0.3 : DX.Move.breath(at: timeline.date.timeIntervalSinceReferenceDate)
            Circle()
                .fill(color.opacity(0.28 - 0.14 * breath))
                .frame(width: diameter, height: diameter)
                .scaleEffect(1 + 0.32 * breath)
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
        .background(Color(hex: scheme == .dark ? 0x2A255F : 0xFFFFFF),
                    in: UnevenRoundedRectangle(topLeadingRadius: 28, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 28, style: .continuous))
        .sensoryFeedback(DX.Haptic.select, trigger: selection)
    }
}
