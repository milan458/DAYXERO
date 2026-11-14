import DayXeroCore
import SwiftData
import SwiftUI

/// Calm done (v5, 060): Jelli cheering in the sea disc, the tool and its minutes, Nicely done, today's minutes of calm
/// and an optional Feeling calmer?, then Back to my day.
///
/// Motion (060): the sea disc fades in, Jelli settles into it cheering (250 ms), then the small apricot check pops in front
/// of the done line and its tick draws (success haptic); the headline with its drawn underline and the line arrive; the
/// minutes row counts up at 1.2 s with a +N floating up and the +N just now tag fading in beside it; the three feeling
/// chips arrive last with none selected (tapping one fills it with the warm selection and a selection haptic).
struct CalmDoneView: View {
    let tool: CalmTool
    var fromSOS = false
    let use: ToolUse?
    /// true when the person chose to go back to (or start) Craving SOS.
    let onDone: (Bool) -> Void

    private let ground = DX.Ground.reading
    private let motion = MotionPolicy()
    @Environment(\.modelContext) private var context
    @Query private var uses: [ToolUse]
    @State private var feeling: Int?
    @State private var float = 0

    private static let feelings: [(LocalizedStringKey, Bool)] = [("Much calmer", true), ("A bit", true), ("Not really", false)]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                DXIconButton(.close, label: "Close") { onDone(false) }
                Spacer()
            }
            .frame(height: 52)
            .padding(.horizontal, -6)
            ScrollView {
                VStack(spacing: 0) {
                    top
                    minutesRow.padding(.top, 20).dxArrive(4)
                    feel.padding(.top, 20)
                }
                .padding(.horizontal, DX.Layout.gutter)
                .padding(.bottom, DX.Space.m)
            }
            .padding(.horizontal, -DX.Layout.gutter)
            .scrollBounceBehavior(.basedOnSize)
            VStack(spacing: 4) {
                Button("Back to my day") { onDone(false) }
                    .buttonStyle(.dx(.primary, on: ground))
                    .dxArrive(7)
                Button(fromSOS ? "Back to Craving SOS" : "Still craving? Open Craving SOS") { onDone(true) }
                    .buttonStyle(.dx(.quiet, on: ground))
                    .dxArrive(8)
            }
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        }
        .sensoryFeedback(.selection, trigger: feeling)
    }

    private var top: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topLeading) {
                CalmSea()
                    .frame(width: 200, height: 200)
                    .clipShape(Circle())
                    .offset(x: 20, y: 6)
                    .dxFade()
                JelliView(mood: .cheer, stage: 1, points: 180, animate: motion.breathes)
                    .offset(x: 30, y: 2)
                    .dxSettle(0, delay: 0.25)
            }
            .frame(width: 240, height: 206, alignment: .topLeading)
            .accessibilityHidden(true)
            .padding(.top, 34)
            HStack(spacing: 7) {
                DXCheck(size: 18, color: Color(hex: 0xFFAE73), tick: Color(hex: 0x1E1A3A), delay: 0.5)
                Text(verbatim: "\(String(localized: tool.title)) · \(String(localized: "\(tool.minutes) min"))")
                    .dxType(.caption).foregroundStyle(ground.muted)
            }
            .padding(.top, 6)
            .padding(.bottom, 8)
            .dxArrive(1)
            MarkedTitle(String(localized: "Nicely "), marking: String(localized: "done"), color: Color(hex: 0xFF7A55))
                .dxType(.large).foregroundStyle(ground.ink)
                .dxArrive(2)
            Text(line).dxType(.body).foregroundStyle(ground.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .dxArrive(3)
        }
        .frame(maxWidth: .infinity)
        .sensoryFeedback(.success, trigger: true)
    }

    private var line: LocalizedStringKey {
        switch tool {
        case .noticeAndName: "One minute, and the urge got smaller.\nThat is a skill you just practised."
        case .boxBreathing: "Four slow rounds, and your breath is yours again.\nThat is a skill you just practised."
        case .grounding: "Five senses, and you're back in the room.\nThat is a skill you just practised."
        case .longerOutBreath: "Five slow minutes.\nLet sleep come when it does."
        case .dropAnchor: "Feet down, and back in the room.\nThat is a skill you just practised."
        }
    }

    /// Today's minutes of calm, counting up to include this one.
    private var minutesRow: some View {
        let today = Calendar.current.startOfDay(for: .now)
        let total = CalmTool.minutes(in: uses.filter { $0.startedAt >= today })
        let gain = tool.minutes
        return HStack(spacing: 12) {
            DXIcon(.wave, size: 22)
                .foregroundStyle(Color(hex: 0x1E1A3A))
                .frame(width: 40, height: 40)
                .background(Color(hex: 0xFFC38A), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                CountingText(Double(total), from: Double(max(total - gain, 0)), delay: 1.2) { v in "\(Int(v.rounded()))" }
                    .dxFace(.display, 26, weight: 800)
                Text(" min of calm today").dxType(.footnote)
            }
            .foregroundStyle(ground.ink)
            .lineLimit(1).minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity, alignment: .leading)
            Text("+\(gain) just now")
                .dxFace(.body, 13, weight: 600).foregroundStyle(ground.ink)
                .padding(.horizontal, 11)
                .frame(height: 30)
                .background(ground.card2, in: Capsule())
                .dxFade(delay: 1.3)
        }
        .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 12))
        .background(ground.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(ground.line, lineWidth: 1))
        .overlay(alignment: .topLeading) {
            // The +N floats up at 1.3 s and fades as it goes.
            Text(verbatim: "+\(gain)")
                .dxFace(.display, 18, weight: 800).foregroundStyle(DX.Fill.done)
                .offset(x: 40, y: float == 2 ? -34 : -6)
                .opacity(float == 1 ? 1 : 0)
                .task {
                    guard !motion.reduce, float == 0 else { return }
                    try? await Task.sleep(for: .milliseconds(1300))
                    float = 1
                    try? await Task.sleep(for: .milliseconds(30))
                    withAnimation(.easeOut(duration: DX.Move.floatUp)) { float = 2 }
                }
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(total) min of calm today, \(gain) just now"))
    }

    private var feel: some View {
        VStack(alignment: .leading, spacing: 10) {
            (Text("Feeling calmer?").dxRun(15, weight: 600).foregroundColor(ground.ink)
                + Text(" ") + Text("Optional").dxRun(15, weight: 500).foregroundColor(ground.muted))
                .dxArrive(5)
            HStack(spacing: 8) {
                ForEach(Self.feelings.indices, id: \.self) { i in
                    let on = feeling == i
                    Button {
                        feeling = i
                        use?.calmer = Self.feelings[i].1
                        try? context.save()
                    } label: {
                        Text(Self.feelings[i].0)
                            .dxFace(.body, 15, weight: 600)
                            .foregroundStyle(on ? ground.selFg : ground.ink)
                            .lineLimit(1)
                            .padding(.horizontal, 16)
                            .frame(minHeight: 48)
                            .background(on ? ground.sel : ground.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(on ? .clear : ground.ink.opacity(0.2), lineWidth: 1.5))
                    }
                    .buttonStyle(.dxPress)
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
            }
            .dxArrive(6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
