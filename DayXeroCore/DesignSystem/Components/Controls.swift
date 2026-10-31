import SwiftUI

/// Craving intensity 1–10. The track runs green → amber → terracotta.
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
                Text("How strong is it?").dxType(.caption).textCase(.uppercase).foregroundStyle(DX.Ground.reading.muted)
                Spacer()
                Text(Self.word(for: value)).dxType(.footnote).foregroundStyle(DX.Ground.reading.muted)
            }
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(verbatim: "\(value)").dxType(.large).foregroundStyle(DX.Ground.reading.ink).monospacedDigit()
                Text(verbatim: "/ 10").dxType(.headline).foregroundStyle(DX.Ground.reading.muted)
            }
            .accessibilityElement(children: .combine)
            GeometryReader { geo in
                let thumb: CGFloat = 28
                let usable = geo.size.width - thumb
                let x = usable * CGFloat(value - 1) / 9
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(LinearGradient(colors: [DX.Fill.green, Color(hex: 0xE5A93C), Color(hex: 0xC85A54)],
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
                .animation(DX.Move.settle, value: value)
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
