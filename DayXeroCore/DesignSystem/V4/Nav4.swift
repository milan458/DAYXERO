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
        case .sos: "SOS"
        case .progress: "Progress"
        }
    }

    /// Monochrome outline icons (24 × 24), like the system tab bar's SF Symbols.
    var icon: String {
        switch self {
        case .today: "M3 11.5 12 4l9 7.5V20a1 1 0 0 1-1 1h-5v-6h-6v6H4a1 1 0 0 1-1-1z"
        case .program: "M12 21V11 M12 13C6 13 4 9 4 5c5 0 8 3 8 8Z M12 11c0-4 3-7 8-7 0 4-3 7-8 7Z"
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
/// behind the selected tab, in the spirit of iOS 26's tab bar. SOS is always ocean so it can be found in a hurry.
/// It stays custom rather than `TabView` because SOS opens Craving SOS instead of switching tabs, and iPhone Duo
/// stands the dock on its side edge.
public struct V4TabBar: View {
    @Binding var selection: V4Tab
    @Environment(\.colorScheme) private var scheme

    public init(selection: Binding<V4Tab>) {
        _selection = selection
    }

    public var body: some View {
        let dark = scheme == .dark
        HStack(spacing: 0) {
            ForEach(V4Tab.allCases, id: \.self) { tab in
                let on = tab == selection
                let color: Color = tab == .sos
                    ? Color(hex: dark ? 0x7FB0FF : 0x2A52DB)
                    : (on ? Color(hex: dark ? 0xFFF8EE : 0x1E1A3A) : Color(hex: dark ? 0xB8B3D9 : 0x5E5975))
                Button { selection = tab } label: {
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
                .accessibilityLabel(tab == .sos ? String(localized: "Craving SOS") : tab.label)
                .accessibilityAddTraits(on ? [.isSelected] : [])
                // Labels stay 12 pt like the system tab bar; long-press shows them large at accessibility sizes.
                .accessibilityShowsLargeContentViewer()
            }
        }
        .padding(.horizontal, 6)
        .frame(height: 70)
        .background {
            // Glass: content shows through, softened, instead of an opaque white pill.
            Capsule().fill(.regularMaterial)
                .shadow(color: dark ? Color.black.opacity(0.45) : Color(hex: 0x1E1A3A).opacity(0.12), radius: 14, x: 0, y: 10)
        }
        .overlay(Capsule().strokeBorder(dark ? Color.white.opacity(0.14) : Color(hex: 0x1E1A3A).opacity(0.10), lineWidth: 1))
        .padding(.horizontal, 12)
        .sensoryFeedback(DX.Haptic.select, trigger: selection)
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
