import DayXeroCore
import SwiftUI

/// The v4 reading tier (cream in light, navy #0E0B2B in dark): lessons, Program and Progress.
/// Every app screen on the reading ground uses these (the old palette was removed in Phase 8).
enum Read4 {
    static let ground = DX.Ground.reading
    static let background = DX.Ground.reading.background
    static let ink = DX.Ground.reading.ink
    static let muted = DX.Ground.reading.muted
    /// Decorative only (unselected rings, dividers); never for text.
    static let faint = Color(light: (0x1E1A3A, 0.38), dark: (0xFFF8EE, 0.38))
    static let hairline = Color(light: (0x1E1A3A, 0.12), dark: (0xFFFFFF, 0.14))
    static let track = Color(light: (0x1E1A3A, 0.12), dark: (0xFFFFFF, 0.16))
    /// Cards on the reading ground.
    static let card = DX.Fill.raised
    /// Inset fills: chips, fields, quiet rows.
    static let surface = DX.Fill.surface
    static let accent = DX.Fill.green
    static let accentSoft = Color(light: (0x0F6E43, 0.12), dark: (0x2FD08A, 0.16))
    /// Text on an ink fill.
    static let onInk = DX.Ground.reading.background
    /// Warnings and "coming soon": 5.1:1 on cream, 8.6:1 on navy.
    static let amber = Color(light: 0x8A5E0E, dark: 0xE5A93C)
}

extension View {
    /// The old text styles mapped onto the seven v4 steps, in reading colours.
    func v4Text(_ style: DX.TextStyle, color: Color? = nil) -> some View {
        modifier(V4TextModifier(style: style, color: color))
    }

    /// A card on the reading ground: raised fill, radius 18 (or as given), no outline.
    func v4Card(padding: CGFloat = DX.Space.m, radius: CGFloat = DX.Layout.smallCardRadius) -> some View {
        self.padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Read4.card, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

private struct V4TextModifier: ViewModifier {
    let style: DX.TextStyle
    let color: Color?

    func body(content: Content) -> some View {
        switch style {
        case .hero: content.dxType(.display).foregroundStyle(color ?? Read4.ink).monospacedDigit()
        case .title: content.dxType(.title).foregroundStyle(color ?? Read4.ink)
        case .cardHeading, .button: content.dxType(.headline).foregroundStyle(color ?? Read4.ink)
        case .body: content.dxType(.body).foregroundStyle(color ?? Read4.ink)
        case .subtitle: content.dxType(.footnote).foregroundStyle(color ?? Read4.muted)
        case .micro: content.dxType(.caption).textCase(.uppercase).foregroundStyle(color ?? Read4.muted)
        case .heroDenominator: content.dxType(.headline).foregroundStyle(color ?? Read4.muted).monospacedDigit()
        }
    }
}

/// `DXCard`'s v4 replacement with the same shape of call.
struct V4Card<Content: View>: View {
    var padding: CGFloat = DX.Space.l
    @ViewBuilder let content: () -> Content

    var body: some View {
        content().v4Card(padding: padding)
    }
}

/// The v4 secondary on the reading ground: a surface pill with ink text, 58 pt.
struct V4SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .dxFont(16, weight: 600, style: .body)
            .foregroundStyle(Read4.ink)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, minHeight: DX.Layout.buttonHeight)
            .background(Read4.surface, in: Capsule())
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

extension ButtonStyle where Self == V4SecondaryButtonStyle {
    static var v4Secondary: V4SecondaryButtonStyle { V4SecondaryButtonStyle() }
}

/// The v4 progress bar on the reading ground: green on a soft track, 8 pt.
struct V4ProgressBar: View {
    let value: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Read4.track)
                Capsule().fill(Read4.accent).frame(width: proxy.size.width * min(1, max(0, value)))
            }
        }
        .frame(height: 8)
        .accessibilityElement()
        .accessibilityValue(Text("\(Int((min(1, max(0, value)) * 100).rounded())) percent"))
    }
}

/// A 44 pt round icon button on the reading ground (replaces the old `.dxIcon`).
struct V4IconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(Read4.ink)
            .frame(width: 44, height: 44)
            .background(Read4.surface, in: Circle())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

extension ButtonStyle where Self == V4IconButtonStyle {
    static var v4Icon: V4IconButtonStyle { V4IconButtonStyle() }
}

/// An on/off chip with the old `DXChip` call shape.
struct V4ToggleChip: View {
    let title: LocalizedStringKey
    @Binding var isOn: Bool

    init(_ title: LocalizedStringKey, isOn: Binding<Bool>) {
        self.title = title
        _isOn = isOn
    }

    var body: some View {
        Button { isOn.toggle() } label: {
            Text(title)
                .dxFont(16, weight: isOn ? 700 : 600, style: .body)
                .foregroundStyle(isOn ? Read4.onInk : Read4.ink)
                .padding(.horizontal, 14)
                .frame(minHeight: 44)
                .background(isOn ? Read4.ink : Read4.surface, in: RoundedRectangle(cornerRadius: DX.Layout.answerChipRadius, style: .continuous))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(DX.Haptic.select, trigger: isOn)
        .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
    }
}

/// A chip in a set, with the old `DXSetChip` call shape.
struct V4SetChip<Value: Hashable>: View {
    let title: LocalizedStringResource
    let value: Value
    @Binding var selection: Set<Value>

    init(_ title: LocalizedStringResource, value: Value, selection: Binding<Set<Value>>) {
        self.title = title
        self.value = value
        _selection = selection
    }

    var body: some View {
        let on = selection.contains(value)
        return V4ToggleChip(LocalizedStringKey(String(localized: title)), isOn: Binding(
            get: { on },
            set: { if $0 { selection.insert(value) } else { selection.remove(value) } }
        ))
    }
}

/// A labelled text field on the reading ground, with the old `DXTextField` call shape.
struct V4TextField: View {
    let label: LocalizedStringKey
    let prompt: LocalizedStringKey
    @Binding var text: String

    init(_ label: LocalizedStringKey, prompt: LocalizedStringKey, text: Binding<String>) {
        self.label = label
        self.prompt = prompt
        _text = text
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).dxType(.caption).textCase(.uppercase).foregroundStyle(Read4.muted)
            TextField("", text: $text, prompt: Text(prompt).foregroundStyle(Read4.muted))
                .dxType(.body)
                .foregroundStyle(Read4.ink)
                .padding(.horizontal, 14)
                .frame(minHeight: 48)
                .background(Read4.surface, in: RoundedRectangle(cornerRadius: DX.Layout.answerChipRadius, style: .continuous))
                .accessibilityLabel(Text(label))
        }
    }
}

/// An empty or error state on the reading ground, with the old `DXStateView` call shape.
struct V4StateView: View {
    enum Kind { case empty, error }
    let kind: Kind
    let systemImage: String
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    var actionTitle: LocalizedStringKey?
    var action: (() -> Void)?

    init(_ kind: Kind, systemImage: String, title: LocalizedStringKey, message: LocalizedStringKey,
         actionTitle: LocalizedStringKey? = nil, action: (() -> Void)? = nil) {
        self.kind = kind
        self.systemImage = systemImage
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage).font(.system(size: 26, weight: .semibold))
                .foregroundStyle(kind == .error ? Read4.amber : Read4.accent)
                .frame(width: 64, height: 64)
                .background(kind == .error ? Read4.amber.opacity(0.12) : Read4.accentSoft, in: Circle())
                .accessibilityHidden(true)
            Text(title).dxType(.title).foregroundStyle(Read4.ink).multilineTextAlignment(.center)
            Text(message).dxType(.body).foregroundStyle(Read4.muted).multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(actionTitle, action: action).buttonStyle(.dx(.primary, on: .reading)).padding(.top, 6)
            }
        }
        .padding(DX.Space.l)
        .frame(maxWidth: .infinity)
    }
}
