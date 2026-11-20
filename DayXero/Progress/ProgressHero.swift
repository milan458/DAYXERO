import DayXeroCore
import SwiftUI

// MARK: - The hero card (v5, 036)

/// The sky and the days since Day Xero in one card, so the count is stated once: "7 days free", "$49.00 kept so
/// far", the sky's clarity tag and Xero on his hill; under the sky the Day Xero sun and a tick for each day since,
/// then "Each day free clears a little more of your sky."
struct ProgressHeroCard: View {
    let count: Int
    let countLabel: String
    let money: Double?
    let moneyFormat: (Double) -> String
    let moneyLabel: String
    let clarity: Int
    let quitDay: Date
    let today: Date
    let showsDays: Bool
    let note: String

    private let ground = DX.Ground.reading

    var body: some View {
        VStack(spacing: 0) {
            sky
            if showsDays {
                ProgressDayStrip(quitDay: quitDay, today: today)
                    .padding(EdgeInsets(top: 12, leading: 10, bottom: 12, trailing: 10))
            }
            Text(verbatim: note)
                .dxType(.caption).foregroundStyle(ground.muted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(EdgeInsets(top: 10, leading: 16, bottom: 13, trailing: 16))
                .overlay(alignment: .top) { Rectangle().fill(ground.line).frame(height: 1) }
                .dxFade(delay: 1.3)
        }
        .background(ground.card)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).strokeBorder(ground.line, lineWidth: 1))
    }

    private var sky: some View {
        ProgressSky()
            .frame(height: 178)
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        CountingText(Double(count), duration: 0.9) { String(Int($0.rounded())) }
                            .dxFace(.display, 60, weight: 800, tracking: -2.5)
                            .monospacedDigit()
                        Text(verbatim: countLabel).dxType(.headline)
                    }
                    .frame(height: 60)
                    if let money {
                        HStack(spacing: 0) {
                            CountingText(money, duration: 0.9, format: moneyFormat)
                            Text(verbatim: " " + moneyLabel)
                        }
                        .dxFont(15, weight: 600, style: .subheadline)
                        .padding(.top, 8)
                        .padding(.leading, 1)
                    }
                }
                .foregroundStyle(SkyInk.color)
                .padding(.leading, 20).padding(.top, 16)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(verbatim: "\(count) \(countLabel)" + (money.map { ". \(moneyFormat($0)) \(moneyLabel)" } ?? "")))
            }
            .overlay(alignment: .topLeading) {
                XeroView(mood: .cheer, stage: 0, points: 100)
                    .frame(width: 100, height: 100)
                    .dxBob()
                    .dxSettle(delay: 0.5)
                    .offset(x: 246, y: 52)
                    .accessibilityHidden(true)
            }
            .overlay(alignment: .bottomLeading) {
                ClearTag(clarity: clarity)
                    .padding(.leading, 14).padding(.bottom, 14)
                    .dxFade(delay: 1.0)
            }
            .clipped()
    }

    /// Ink on the sky: navy on the dawn, cream on the pre-dawn.
    private enum SkyInk {
        static let color = Color(light: 0x1E1A3A, dark: 0xFFF8EE)
    }
}

/// "☀ Sky 40% clear" on its cream pill.
private struct ClearTag: View {
    let clarity: Int

    var body: some View {
        HStack(spacing: 6) {
            DXIcon(.sun, size: 16, weight: 2)
            Text("Sky \(clarity)% clear").dxFont(13, weight: 600, style: .footnote)
        }
        .foregroundStyle(Color(light: 0x1E1A3A, dark: 0xFFF8EE))
        .padding(.leading, 8).padding(.trailing, 12)
        .frame(height: 30)
        .background(Color(light: (0xFFF8EE, 0.94), dark: (0x0E1322, 0.7)), in: Capsule())
        .overlay(Capsule().strokeBorder(Color(light: (0xFFFFFF, 0), dark: (0xFFFFFF, 0.16)), lineWidth: 1))
    }
}

/// The clearing sky (036): two small paper clouds parting around the sun over three paper hills. Dark is the same
/// scene at pre-dawn: a navy sky, slate clouds, a low warm sun and a few stars.
struct ProgressSky: View {
    @Environment(\.colorScheme) private var scheme
    @State private var parted = false
    private let motion = MotionPolicy()

    var body: some View {
        let dark = scheme == .dark
        GeometryReader { proxy in
            let k = proxy.size.width / 346
            ZStack(alignment: .topLeading) {
                Canvas { ctx, _ in
                    ctx.scaleBy(x: k, y: k)
                    Self.back(&ctx, dark: dark)
                }
                cloud(x: 184, y: 40, k: 1.9, dark: dark).offset(x: parted ? 0 : 34 * k)
                cloud(x: 266, y: 10, k: 2.1, dark: dark).offset(x: parted ? 0 : -40 * k)
                Canvas { ctx, _ in
                    ctx.scaleBy(x: k, y: k)
                    Self.hills(&ctx, dark: dark)
                }
            }
            .scaleEffect(1, anchor: .topLeading)
        }
        .onAppear {
            guard !parted else { return }
            if motion.reduce { parted = true; return }
            withAnimation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.9).delay(0.25)) { parted = true }
        }
        .accessibilityHidden(true)
    }

    private static let cloudPath = "M2 12h20a5 5 0 000-10 7 7 0 00-13-1 5 5 0 00-7 4 3.5 3.5 0 000 7z"

    /// A two-tone paper cloud: a darker copy offset behind, the face on top, each with a soft drop shadow.
    private func cloud(x: Double, y: Double, k: Double, dark: Bool) -> some View {
        GeometryReader { proxy in
            let s = proxy.size.width / 346
            Canvas { ctx, _ in
                ctx.scaleBy(x: s, y: s)
                ctx.addFilter(.shadow(color: Color(hex: 0x1A0B2E).opacity(dark ? 0.5 : 0.14), radius: 2.4, x: 0, y: 2))
                let path = SVGPath.path(Self.cloudPath)
                ctx.fill(path.applying(CGAffineTransform(translationX: x + 3 * k, y: y + 2.4 * k).scaledBy(x: k, y: k)),
                         with: .color(Color(hex: dark ? 0x283A63 : 0xFBE6D6)))
                ctx.fill(path.applying(CGAffineTransform(translationX: x, y: y).scaledBy(x: k, y: k)),
                         with: .color(Color(hex: dark ? 0x33446F : 0xFFF8F0)))
            }
        }
    }

    private static func back(_ ctx: inout GraphicsContext, dark: Bool) {
        let rect = Path(CGRect(x: 0, y: 0, width: 346, height: 178))
        let sky = dark ? CalmPaint.vertical(0x0D1630, 0x1F2D55, 0x3F4A72) : CalmPaint.vertical(0xFFB98A, 0xFFD3AC, 0xFFE8CC)
        ctx.fill(rect, with: .linearGradient(sky, startPoint: .zero, endPoint: CGPoint(x: 0, y: 178)))
        if dark {
            for (i, p) in [(214.0, 22.0), (252, 44), (300, 18), (236, 70), (188, 50)].enumerated() {
                ctx.fill(CalmPaint.circle(p.0, p.1, i % 2 == 1 ? 1.1 : 1.5), with: .color(.white.opacity(i % 2 == 1 ? 0.5 : 0.85)))
            }
        }
        let sunY = dark ? 124.0 : 86
        ctx.fill(CalmPaint.circle(236, sunY, 76), with: .radialGradient(Gradient(stops: [
            .init(color: Color(hex: dark ? 0xFFB25E : 0xFFF6C8).opacity(dark ? 0.4 : 0.7), location: 0.2),
            .init(color: Color(hex: dark ? 0xFFB25E : 0xFFF6C8).opacity(0), location: 1),
        ]), center: CGPoint(x: 236, y: sunY), startRadius: 0, endRadius: 76))
        ctx.fill(CalmPaint.circle(236, sunY, dark ? 22 : 28), with: .color(Color(hex: dark ? 0xFFD27A : 0xFFD25E)))
    }

    private static func hills(_ ctx: inout GraphicsContext, dark: Bool) {
        let c: [UInt32] = dark ? [0x1E2B4A, 0x16233F, 0x0F1A31] : [0xFFAE73, 0xFF8A5E, 0xE8674A]
        ctx.addFilter(.shadow(color: Color(hex: 0x1A0B2E).opacity(dark ? 0.45 : 0.18), radius: 2.4, x: 0, y: -2))
        CalmPaint.fill(&ctx, "M0 142 C60 128 130 136 190 132 C250 128 300 116 346 120 V178 H0z", c[0])
        CalmPaint.fill(&ctx, "M150 178 C190 158 240 148 286 148 C316 148 336 152 346 156 V178z", c[1])
        CalmPaint.fill(&ctx, "M0 166 C50 160 110 166 160 170 C200 173 230 172 260 178 H0z", c[2])
    }
}

/// Day Xero's sun, then a tick for each day since, today's ringed (036). Past a week, the last seven days.
struct ProgressDayStrip: View {
    let quitDay: Date
    let today: Date
    private let ground = DX.Ground.reading

    var body: some View {
        let cal = Calendar.current
        let start = cal.startOfDay(for: quitDay)
        let since = max(0, cal.dateComponents([.day], from: start, to: cal.startOfDay(for: today)).day ?? 0)
        let first = max(1, since - 6)
        let days = (0..<7).map { first + $0 }
        HStack(spacing: 0) {
            cell(label: String(localized: "Day Xero"), bold: true) {
                Circle().fill(Color(hex: 0xFFD966))
                    .overlay(DXIcon(.sun, size: 14, weight: 2.4).foregroundStyle(Color(hex: 0x1E1A3A)))
            }
            .frame(width: 60)
            .overlay(alignment: .trailing) {
                Rectangle().fill(ground.line).frame(width: 1, height: 20).offset(x: 0, y: -9)
            }
            .dxFade(delay: 0.7)
            ForEach(Array(days.enumerated()), id: \.offset) { i, n in
                let date = cal.date(byAdding: .day, value: n, to: start) ?? start
                let letter = date.formatted(.dateTime.weekday(.narrow))
                let isToday = n == since
                let future = n > since
                cell(label: letter, bold: isToday) {
                    if isToday {
                        Circle().fill(ground.card)
                            .overlay(Circle().strokeBorder(ground.ink, lineWidth: 2))
                            .overlay(DXIcon(.check, size: 14, weight: 3).foregroundStyle(ground.ink))
                    } else if future {
                        Circle().strokeBorder(ground.line, lineWidth: 2)
                    } else {
                        Circle().fill(Color(hex: 0xFFC38A))
                            .overlay(DXIcon(.check, size: 14, weight: 2.6).foregroundStyle(Color(hex: 0x1E1A3A)))
                    }
                }
                .frame(maxWidth: .infinity)
                .dxFade(delay: 0.7 + Double(i + 1) * 0.07)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Day Xero, \(quitDay.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())), then every day free to today"))
    }

    private func cell<Disc: View>(label: String, bold: Bool, @ViewBuilder disc: () -> Disc) -> some View {
        VStack(spacing: 5) {
            disc().frame(width: 26, height: 26)
            Text(verbatim: label)
                .dxFont(12, weight: bold ? 700 : 600, style: .caption2)
                .foregroundStyle(bold ? ground.ink : ground.muted)
                .lineLimit(1).fixedSize()
        }
    }
}

// MARK: - The badge shelf (036)

/// "Badges · See all", then the last three day badges earned and the next one with its ring part-filled, each with
/// only its date under it ("Today" in bold).
struct ProgressBadgeShelf: View {
    let quitDay: Date
    let daysClear: Int
    let now: Date
    let onSeeAll: () -> Void
    let onOpen: (Milestone) -> Void
    private let ground = DX.Ground.reading

    var body: some View {
        let dayMilestones = Milestone.all.filter { if case .days = $0 { true } else { false } }
        let earned = dayMilestones.filter { $0.isReached(daysClear: daysClear) }.suffix(3)
        let next = Milestone.next(daysClear: daysClear)
        let shown = Array(earned) + (next.map { [$0] } ?? [])
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Badges").dxType(.headline).foregroundStyle(ground.ink)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button(action: onSeeAll) {
                    Text("See all").dxFont(15, weight: 700, style: .subheadline)
                        .underline().foregroundStyle(ground.ink)
                        .frame(minHeight: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 10)
            .dxArrive(4, delay: 0)
            HStack(spacing: 0) {
                ForEach(Array(shown.enumerated()), id: \.element.id) { i, m in
                    let reached = m.isReached(daysClear: daysClear)
                    Button { if reached { onOpen(m) } } label: { badge(m, reached: reached, index: i, isLatest: reached && m == earned.last) }
                        .buttonStyle(.plain)
                        .allowsHitTesting(reached)
                        .frame(maxWidth: .infinity)
                }
                ForEach(shown.count..<4, id: \.self) { _ in Color.clear.frame(maxWidth: .infinity, maxHeight: 1) }
            }
            .padding(EdgeInsets(top: 16, leading: 6, bottom: 14, trailing: 6))
            .dxCardChrome(on: .reading)
            .dxArrive(5, delay: 0)
        }
    }

    private func date(of m: Milestone) -> Date {
        let cal = Calendar.current
        return cal.date(byAdding: .day, value: m.reachedOnDay - 1, to: cal.startOfDay(for: quitDay)) ?? quitDay
    }

    @ViewBuilder
    private func badge(_ m: Milestone, reached: Bool, index: Int, isLatest: Bool) -> some View {
        let day = date(of: m)
        let isToday = Calendar.current.isDate(day, inSameDayAs: now)
        let label = isToday ? String(localized: "Today") : day.formatted(.dateTime.month(.abbreviated).day())
        let n: Int = if case let .days(v) = m { v } else { 0 }
        let fraction = Double(daysClear - previousReachedDay(before: m)) / Double(max(1, m.reachedOnDay - previousReachedDay(before: m)))
        VStack(spacing: 8) {
            Group {
                if reached {
                    DXBadge(.day, n: n, state: .earned, size: 70)
                        .modifier(ShineIf(on: isLatest, delay: 1.2))
                        .dxStamp(index, delay: 0.5)
                } else {
                    DXBadge(.day, n: n, state: .next(min(1, max(0, fraction))), size: 70)
                        .dxFade(delay: 0.9 + Double(index) * 0.08)
                }
            }
            Text(verbatim: label)
                .dxFont(13, weight: isToday ? 700 : 500, style: .footnote)
                .foregroundStyle(isToday ? ground.ink : ground.muted)
                .lineLimit(1).minimumScaleFactor(0.8)
        }
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "\(m.title), \(label)"))
    }

    private func previousReachedDay(before m: Milestone) -> Int {
        let all = Milestone.all
        guard let i = all.firstIndex(of: m), i > 0 else { return 0 }
        return all[i - 1].reachedOnDay
    }
}

private struct ShineIf: ViewModifier {
    let on: Bool
    let delay: Double

    func body(content: Content) -> some View {
        if on { content.clipShape(Circle()).dxShine(delay: delay) } else { content }
    }
}

/// All the milestones, from "See all".
struct MilestonesSheet: View {
    let daysClear: Int
    let onOpen: (Milestone) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                DXIconButton(.close, label: "Close") { dismiss() }
                Text("Badges").dxType(.large).foregroundStyle(DX.Ground.reading.ink)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.top, 6)
                MilestonesRow(daysClear: daysClear, onOpen: onOpen)
            }
            .padding(.horizontal, DX.Layout.gutter)
            .padding(.top, DX.Space.m)
            .padding(.bottom, DX.Space.l)
        }
        .background(DX.Ground.reading.background.ignoresSafeArea())
        .dxGround(.reading, paint: false)
    }
}
