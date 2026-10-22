import SwiftUI

/// Selectable capsule chip. Active is the primary colour; inactive is surface 2.
public struct DXChip: View {
    let title: LocalizedStringKey
    @Binding var isOn: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(_ title: LocalizedStringKey, isOn: Binding<Bool>) {
        self.title = title
        self._isOn = isOn
    }

    public var body: some View {
        Button {
            withAnimation(DX.Motion.animation(DX.Motion.morph, reduceMotion: reduceMotion)) { isOn.toggle() }
        } label: {
            Text(title)
                .font(.custom(isOn ? DX.Typeface.semibold : DX.Typeface.regular, size: 14, relativeTo: .subheadline))
                .foregroundStyle(isOn ? DX.Palette.onPrimary : DX.Palette.text2)
                .padding(.vertical, 9)
                .padding(.horizontal, 18)
                .background(isOn ? DX.Palette.primary : DX.Palette.surface2, in: Capsule())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(DX.Haptic.select, trigger: isOn)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}

/// Stadium text field with a sage focus ring.
public struct DXTextField: View {
    let label: LocalizedStringKey
    let prompt: LocalizedStringKey
    @Binding var text: String
    @FocusState private var focused: Bool

    public init(_ label: LocalizedStringKey, prompt: LocalizedStringKey, text: Binding<String>) {
        self.label = label
        self.prompt = prompt
        self._text = text
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DX.Space.xs) {
            Text(label).dxText(.micro)
            TextField("", text: $text, prompt: Text(prompt).foregroundStyle(DX.Palette.faint))
                .font(DX.TextStyle.body.font)
                .foregroundStyle(DX.Palette.text)
                .focused($focused)
                .padding(.horizontal, 18)
                .frame(minHeight: DX.Size.inputHeight)
                .background(DX.Palette.surface2, in: RoundedRectangle(cornerRadius: DX.Radius.input, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: DX.Radius.input, style: .continuous)
                        .strokeBorder(focused ? DX.Palette.sage.opacity(0.8) : DX.Palette.hairline)
                )
                .animation(DX.Motion.glide, value: focused)
                .accessibilityLabel(Text(label))
        }
    }
}

/// Thin progress track with a sage or primary fill.
public struct DXProgressBar: View {
    public enum Tint: Sendable { case accent, primary }
    let value: Double
    let tint: Tint
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(value: Double, tint: Tint = .accent) {
        self.value = min(max(value, 0), 1)
        self.tint = tint
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(DX.Palette.track)
                Capsule()
                    .fill(tint == .primary ? DX.Palette.primary : DX.Palette.accentInk)
                    .frame(width: geo.size.width * value)
            }
        }
        .frame(height: DX.Size.progressHeight)
        .animation(DX.Motion.animation(DX.Motion.glide, reduceMotion: reduceMotion), value: value)
        .accessibilityElement()
        .accessibilityValue(Text(value, format: .percent.precision(.fractionLength(0))))
    }
}

/// Micro label + value on one line, progress bar underneath.
public struct DXMetric: View {
    let label: LocalizedStringKey
    let value: String
    let progress: Double?
    let tint: DXProgressBar.Tint

    public init(_ label: LocalizedStringKey, value: String, progress: Double? = nil, tint: DXProgressBar.Tint = .accent) {
        self.label = label
        self.value = value
        self.progress = progress
        self.tint = tint
    }

    public var body: some View {
        VStack(spacing: DX.Space.xs) {
            HStack(alignment: .firstTextBaseline) {
                Text(label).dxText(.micro)
                Spacer()
                Text(value)
                    .font(.custom(DX.Typeface.semibold, size: 13, relativeTo: .footnote))
                    .monospacedDigit()
                    .foregroundStyle(DX.Palette.text)
            }
            if let progress {
                DXProgressBar(value: progress, tint: tint)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// Large fraction numeral: "3 / 7".
public struct DXFraction: View {
    let numerator: Int
    let denominator: Int?
    let unit: LocalizedStringKey?

    public init(_ numerator: Int, of denominator: Int? = nil, unit: LocalizedStringKey? = nil) {
        self.numerator = numerator
        self.denominator = denominator
        self.unit = unit
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(numerator, format: .number).dxText(.hero)
            if let denominator {
                Text("/ \(denominator)").dxText(.heroDenominator)
            }
            if let unit {
                Text(unit).dxText(.heroDenominator)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// Craving intensity 1–10. The track runs sage → amber → terracotta.
public struct DXCravingSlider: View {
    @Binding var value: Int
    @GestureState private var dragging = false

    public init(value: Binding<Int>) {
        self._value = value
    }

    public static func word(for value: Int) -> LocalizedStringKey {
        switch value {
        case ...3: "Mild"
        case 4...7: "Moderate"
        default: "Intense"
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DX.Space.s) {
            HStack {
                Text("How strong is it?").dxText(.micro)
                Spacer()
                Text(Self.word(for: value)).dxText(.subtitle)
            }
            DXFraction(value, of: 10)
            GeometryReader { geo in
                let thumb: CGFloat = 28
                let usable = geo.size.width - thumb
                let x = usable * CGFloat(value - 1) / 9
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(LinearGradient(colors: [DX.Palette.sage, DX.Palette.amber, DX.Palette.terracotta],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(height: DX.Size.progressHeight)
                        .padding(.horizontal, thumb / 2)
                    Circle()
                        .fill(Color.white)
                        .frame(width: thumb, height: thumb)
                        .shadow(color: .black.opacity(0.35), radius: 6, y: 4)
                        .scaleEffect(dragging ? 1.1 : 1)
                        .offset(x: x)
                }
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .updating($dragging) { _, state, _ in state = true }
                        .onChanged { g in
                            let raw = (g.location.x - thumb / 2) / max(usable, 1)
                            value = Int((min(max(raw, 0), 1) * 9).rounded()) + 1
                        }
                )
                .animation(DX.Motion.morph, value: value)
            }
            .frame(height: 44)
        }
        .sensoryFeedback(DX.Haptic.select, trigger: value)
        .accessibilityElement()
        .accessibilityLabel(Text("Craving intensity"))
        .accessibilityValue(Text("\(value) of 10, \(Text(Self.word(for: value)))"))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: value = min(value + 1, 10)
            case .decrement: value = max(value - 1, 1)
            @unknown default: break
            }
        }
    }
}
