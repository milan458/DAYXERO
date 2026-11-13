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
                Text("How strong is it?").dxType(.headline).foregroundStyle(DX.Ground.reading.ink)
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
                // v5 (042): the track with coral to the thumb, ten ticks under it, a white thumb with a coral ring.
                ZStack(alignment: .leading) {
                    Capsule().fill(DX.Ground.reading.track)
                        .frame(height: 6)
                        .padding(.horizontal, thumb / 2)
                    Capsule().fill(Color(hex: 0xF26A45))
                        .frame(width: x + thumb / 2, height: 6)
                        .padding(.leading, thumb / 2)
                    HStack(spacing: 0) {
                        ForEach(0..<10, id: \.self) { i in
                            Rectangle().fill(DX.Ground.reading.ink.opacity(0.25)).frame(width: 1.5, height: 8)
                            if i < 9 { Spacer(minLength: 0) }
                        }
                    }
                    .padding(.horizontal, thumb / 2)
                    .offset(y: 14)
                    Circle()
                        .fill(Color.white)
                        .overlay(Circle().strokeBorder(Color(hex: 0xFF9A6B), lineWidth: 4))
                        .frame(width: thumb, height: thumb)
                        .shadow(color: .black.opacity(0.25), radius: 4, y: 2)
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
