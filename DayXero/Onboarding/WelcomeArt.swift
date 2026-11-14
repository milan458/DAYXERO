import DayXeroCore
import SwiftUI

/// Welcome's paper scene (002), drawn on the kit's 390 × 450 frame and scaled to the width: a sky, the sun in two
/// soft rings, a pale far hill and the warm crest Xero stands on, waving, with "Hi, I'm Xero." beside his hand.
/// Dark: the launch night, an amber sun in a glow, flat navy hills feathered into the page.
struct WelcomeArt: View {
    let opened: Date
    @State private var up = false
    @State private var bubble = false
    @Environment(\.colorScheme) private var scheme
    private let motion = MotionPolicy()

    private static let back = "M0 262 C48 236 104 236 150 258 C200 282 250 250 300 220 C334 200 366 196 390 202 L390 450 L0 450 Z"
    private static let backEdge = "M0 262 C48 236 104 236 150 258 C200 282 250 250 300 220 C334 200 366 196 390 202"
    private static let crest = "M0 416 C36 390 92 362 158 360 C226 358 300 382 390 404 L390 450 L0 450 Z"
    private static let crestEdge = "M0 416 C36 390 92 362 158 360 C226 358 300 382 390 404"

    var body: some View {
        let dark = scheme == .dark
        let ground = DX.Ground.apricot.background
        let hBack = dark ? Color(hex: 0x36416C) : Color(hex: 0xFFDDB8)
        let hMid = dark ? Color(hex: 0x252F55) : Color(hex: 0xFFAE7A)
        let edge = dark ? Color(red: 190 / 255, green: 205 / 255, blue: 1).opacity(0.26) : Color.white.opacity(0.6)
        let lift = dark ? Color.black.opacity(0.45) : Color(red: 120 / 255, green: 44 / 255, blue: 20 / 255).opacity(0.18)
        GeometryReader { proxy in
            let s = proxy.size.width / 390
            ZStack(alignment: .topLeading) {
                // Sky.
                Group {
                    if dark {
                        LinearGradient(stops: [.init(color: Color(hex: 0x0B1020), location: 0), .init(color: Color(hex: 0x141C36), location: 0.45),
                                               .init(color: Color(hex: 0x222C55), location: 0.8)], startPoint: .top, endPoint: .bottom)
                    } else {
                        LinearGradient(stops: [.init(color: Color(hex: 0xFFC479), location: 0), .init(color: ground, location: 0.7)],
                                       startPoint: .top, endPoint: .bottom)
                    }
                }
                .frame(width: 390, height: 450)
                sun(dark: dark)
                    .offset(y: up || motion.reduce ? 0 : 60)
                    .animation(motion.reduce ? nil : .timingCurve(0.25, 0.75, 0.25, 1, duration: 1.2), value: up)
                hill(Self.back, Self.backEdge, fill: AnyShapeStyle(hBack), edge: edge)
                    .shadow(color: lift, radius: 5, y: -4)
                    .offset(y: up || motion.reduce ? 0 : 80)
                    .animation(motion.reduce ? nil : DX.Move.settle, value: up)
                hill(Self.crest, Self.crestEdge,
                     fill: AnyShapeStyle(LinearGradient(stops: [.init(color: hMid, location: 0), .init(color: hMid, location: 0.45),
                                                                .init(color: ground, location: 1)],
                                                        startPoint: UnitPoint(x: 0.5, y: 356 / 450), endPoint: .bottom)),
                     edge: edge)
                    .shadow(color: lift, radius: 6, y: -5)
                    .offset(y: up || motion.reduce ? 0 : 80)
                    .animation(motion.reduce ? nil : DX.Move.settle.delay(0.12), value: up)
                XeroView(mood: .hello, stage: 0, points: 152, pose: .wave, since: opened)
                    .offset(x: 82, y: 216)
                    .dxSettle(delay: 0.3)
                if dark {
                    // Feather the foot of the night hill into the page.
                    LinearGradient(stops: [.init(color: ground.opacity(0), location: 0), .init(color: ground.opacity(0.35), location: 0.3),
                                           .init(color: ground.opacity(0.75), location: 0.62), .init(color: ground, location: 0.92)],
                                   startPoint: .top, endPoint: .bottom)
                        .frame(width: 390, height: 96)
                        .offset(y: 450 - 96)
                }
                speechBubble
                    .offset(x: 238, y: 196)
                    .opacity(bubble || motion.reduce ? 1 : 0)
                    .offset(y: bubble || motion.reduce ? 0 : 18)
                    .animation(.timingCurve(0.2, 0.7, 0.2, 1, duration: 0.6), value: bubble)
            }
            .frame(width: 390, height: 450, alignment: .topLeading)
            .clipped()
            .scaleEffect(s, anchor: .topLeading)
        }
        .accessibilityElement()
        .accessibilityLabel(Text("Xero waves from a hill at sunrise and says: Hi, I'm Xero."))
        .task {
            up = true
            try? await Task.sleep(for: .seconds(1.1))
            bubble = true
        }
    }

    private func hill(_ d: String, _ edgePath: String, fill: AnyShapeStyle, edge: Color) -> some View {
        ZStack {
            Grid390(d: d).fill(fill)
            Grid390(d: edgePath).stroke(edge, lineWidth: 2)
        }
        .frame(width: 390, height: 450)
    }

    /// The sun at (112, 232): two soft rings round a radial disc; dark, a glow and an amber core instead.
    private func sun(dark: Bool) -> some View {
        let sunA = dark ? Color(hex: 0xFFE2A0) : Color(hex: 0xFFF4C9)
        let sunB = dark ? Color(hex: 0xF3A14A) : Color(hex: 0xFFC93C)
        return ZStack {
            if dark {
                Circle()
                    .fill(RadialGradient(stops: [.init(color: Color(hex: 0xFFB862).opacity(0.7), location: 0),
                                                 .init(color: Color(hex: 0xF7A04E).opacity(0.32), location: 0.42),
                                                 .init(color: Color(hex: 0xE88A45).opacity(0.09), location: 0.72),
                                                 .init(color: Color(hex: 0xE07F40).opacity(0), location: 1)],
                                         center: .center, startRadius: 0, endRadius: 136))
                    .frame(width: 272, height: 272)
            } else {
                Circle().fill(Color(red: 1, green: 236 / 255, blue: 200 / 255).opacity(0.32)).frame(width: 208, height: 208)
                Circle().fill(Color(red: 1, green: 240 / 255, blue: 205 / 255).opacity(0.55)).frame(width: 160, height: 160)
            }
            Circle()
                .fill(RadialGradient(colors: [sunA, sunB], center: UnitPoint(x: 0.4, y: 0.34), startRadius: 0, endRadius: 0.72 * 108))
                .frame(width: 108, height: 108)
            if dark {
                Circle()
                    .fill(RadialGradient(stops: [.init(color: Color(hex: 0xFFE7A8), location: 0), .init(color: Color(hex: 0xFFC266), location: 0.6),
                                                 .init(color: Color(hex: 0xF49A45), location: 1)],
                                         center: UnitPoint(x: 0.5, y: 0.45), startRadius: 0, endRadius: 0.55 * 108))
                    .frame(width: 108, height: 108)
            }
        }
        .position(x: 112, y: 232)
        .frame(width: 390, height: 450)
    }

    /// Cream in both modes, the tail toward his waving hand.
    private var speechBubble: some View {
        Text("Hi, I'm Xero.")
            .dxFace(.display, 15, weight: 700)
            .foregroundStyle(DX.Fill.navy)
            .lineLimit(1)
            .fixedSize()
            .dynamicTypeSize(...DynamicTypeSize.large)
            .padding(.vertical, 11).padding(.horizontal, 12)
            .background(alignment: .bottomLeading) {
                ZStack(alignment: .bottomLeading) {
                    UnevenRoundedRectangle(topLeadingRadius: 18, bottomLeadingRadius: 6, bottomTrailingRadius: 18, topTrailingRadius: 18,
                                           style: .continuous)
                        .fill(DX.Fill.cream)
                    BubbleTail().fill(DX.Fill.cream).frame(width: 16, height: 12).offset(x: 4, y: 9)
                }
                .shadow(color: scheme == .dark ? .black.opacity(0.35) : Color(red: 90 / 255, green: 40 / 255, blue: 20 / 255).opacity(0.12),
                        radius: 9, y: 6)
            }
    }
}

/// The kit bubble's tail: `M2 0 L14 0 C10 4 5 8 0 12 C1 8 2 4 2 0 Z` on 16 × 12.
private struct BubbleTail: Shape {
    func path(in rect: CGRect) -> Path {
        SVGPath.path("M2 0 L14 0 C10 4 5 8 0 12 C1 8 2 4 2 0 Z")
            .applying(CGAffineTransform(scaleX: rect.width / 16, y: rect.height / 12))
            .offsetBy(dx: rect.minX, dy: rect.minY)
    }
}

/// A path on the welcome art's 390 × 450 frame, unscaled.
private struct Grid390: Shape {
    let d: String
    func path(in rect: CGRect) -> Path { SVGPath.path(d) }
}
