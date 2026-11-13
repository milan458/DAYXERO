import DayXeroCore
import SwiftData
import SwiftUI
import UIKit

/// Numbers the moment and the share card can show. Only days clear is on a card by default (S13.4).
struct MilestoneStats: Equatable {
    var daysClear: Int
    var money: String
    var cravingsRiddenOut: Int
    /// The main product's counter, e.g. ("Puffs not taken", "1,400"), singular for one ("Puff not taken", "1").
    var counterLabel: String
    var counterValue: String
    /// The counter as one phrase: "362 puffs not taken", "1 puff not taken".
    var counterPhrase: String

    @MainActor
    init(profile: UserProfile, logs: [LogEntry], now: Date = .now) {
        let snap = HomeSnapshot(profile: profile, isPro: true, now: now)
        daysClear = snap.daysClear
        money = snap.moneyKept.formatted(.currency(code: snap.currencyCode))
        cravingsRiddenOut = logs.filter { $0.kind == .craving && $0.outcome == .passed }.count
        let counter = snap.counters.first
        let avoided = counter?.avoided ?? 0
        counterValue = avoided.formatted()
        counterLabel = switch counter?.product {
        case .vape: avoided == 1 ? String(localized: "Puff not taken") : String(localized: "Puffs not taken")
        case .pouches: avoided == 1 ? String(localized: "Pouch not used") : String(localized: "Pouches not used")
        default: avoided == 1 ? String(localized: "Cigarette not smoked") : String(localized: "Cigarettes not smoked")
        }
        counterPhrase = switch counter?.product {
        case .vape: String(localized: "\(avoided) puffs not taken")
        case .pouches: String(localized: "\(avoided) pouches not used")
        default: String(localized: "\(avoided) cigarettes not smoked")
        }
    }
}

/// Which milestones have been celebrated, so each one shows once (S13.2).
enum CelebratedMilestones {
    static let key = "dx.celebratedMilestones"

    static var ids: Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: key) ?? [])
    }

    /// Marks everything reached so far, so earlier milestones missed during a break aren't celebrated one by one.
    static func markReached(daysClear: Int) {
        let all = ids.union(Milestone.reached(daysClear: daysClear).map(\.id))
        UserDefaults.standard.set(Array(all), forKey: key)
    }
}

/// The full-screen moment on a milestone day (S13.2), on the sun ground. A milestone is one of the three places
/// Celebrate motion is allowed: Xero springs in and cheers, the number counts up. No confetti (finale only).
struct MilestoneMoment: View {
    let milestone: Milestone
    let stats: MilestoneStats
    let onClose: () -> Void

    private let motion = MotionPolicy()
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var appeared = false
    @State private var sharing = false

    /// v5 (039): milestones celebrate on Xero's apricot, the earned badge stamping into its rays.
    private let ground = DX.Ground.apricot

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 10) {
                    HStack {
                        DXIconButton(.close, label: "Close", action: onClose)
                        Spacer()
                    }
                    .environment(\.dxGround, ground)
                    // The earned badge in its rays; the company (Xero, then Jelli, then the crew) cheers beside it.
                    ZStack(alignment: .bottomTrailing) {
                        MilestoneRays()
                            .frame(width: 300, height: 300)
                            .frame(maxWidth: .infinity)
                            .dxFade(delay: 0.5)
                        Group {
                            switch milestone {
                            case .quitDay: DXBadge(.xero, size: 160)
                            case .days(365): DXBadge(.day, n: "1y", size: 160)
                            case let .days(n): DXBadge(.day, n: n, size: 160, liftNumeral: true)
                            }
                        }
                        .shadow(color: Color(light: (0x963214, 0.25), dark: (0x000000, 0.45)), radius: 8, y: 8)
                        .dxShine(delay: 1.2)
                        .dxStamp(delay: 0.3)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 70)
                        company
                            .scaleEffect(0.62, anchor: .bottomTrailing)
                            .scaleEffect(appeared || motion.reduce ? 1 : DX.Move.celebrateFromScale, anchor: .bottom)
                            .opacity(appeared ? 1 : 0)
                            .accessibilityHidden(true)
                    }
                    .frame(height: 300)
                    .accessibilityHidden(true)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        CountingText(Double(milestone.number), format: { String(Int($0.rounded())) })
                            .dxType(.headline).monospacedDigit()
                        Text(verbatim: milestone.caption).dxType(.footnote)
                    }
                    .foregroundStyle(ground.ink)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(verbatim: milestone.title))
                    .accessibilityAddTraits(.isHeader)
                    Text(verbatim: milestone.title).dxType(.large).foregroundStyle(ground.ink).multilineTextAlignment(.center)
                        .dxArrive(2, delay: 0.6)
                    if !milestone.line.isEmpty {
                        Text(verbatim: milestone.line).dxType(.body).foregroundStyle(ground.muted)
                            .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                    }
                    if let id = milestone.sourceID, let source = HealthTimeline.bundled?.source(id) {
                        Link(destination: source.url) {
                            Text(verbatim: source.label).dxType(.caption).underline().foregroundStyle(ground.muted)
                        }
                    }
                    if milestone != .quitDay {
                        // Side by side, or stacked at accessibility text sizes so nothing overflows (S27.20).
                        let tiles = typeSize.isAccessibilitySize
                            ? AnyLayout(VStackLayout(spacing: 8)) : AnyLayout(HStackLayout(spacing: 8))
                        tiles {
                            tile(stats.counterValue, stats.counterLabel.lowercased())
                            tile(stats.money, String(localized: "kept"))
                        }
                        .padding(.top, 6)
                    }
                }
                .padding(.horizontal, DX.Layout.gutter)
                .padding(.bottom, DX.Space.m)
            }
            .scrollBounceBehavior(.basedOnSize)
            VStack(spacing: 4) {
                Button("Keep going", action: onClose).buttonStyle(.dx(.primary, on: ground))
                Button { sharing = true } label: { Label("Share my card", systemImage: "square.and.arrow.up") }
                    .buttonStyle(.dx(.quiet, on: ground))
            }
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .padding(.horizontal, DX.Layout.buttonGutter)
            .padding(.bottom, DX.Space.xs)
        }
        .dxReadableColumn()
        .background(ground.background.ignoresSafeArea())
        .sensoryFeedback(DX.Haptic.commit, trigger: appeared)
        .onAppear {
            withAnimation(motion.animation(DX.Move.celebrate)) { appeared = true }
        }
        .sheet(isPresented: $sharing) {
            ShareCardMaker(milestone: milestone, stats: stats).presentationDetents([.large])
        }
    }

    /// Who comes to celebrate (S27.16): Xero alone, then Jelli from one month, the whole crew from three months.
    @ViewBuilder
    private var company: some View {
        let stage = CrewGrowth.stage(daysClear: stats.daysClear)
        let mood: CrewMood = appeared ? .cheer : .hello
        HStack(alignment: .bottom, spacing: 4) {
            switch milestone.company {
            case .xero:
                XeroView(mood: mood, stage: stage, size: .hero)
            case .xeroAndJelli:
                JelliView(mood: mood, stage: stage, points: 100)
                XeroView(mood: mood, stage: stage, points: 170)
            case .crew:
                JelliView(mood: mood, stage: stage, points: 88)
                XeroView(mood: mood, stage: stage, points: 140)
                GlimView(mood: mood, stage: stage, points: 88)
            }
        }
    }

    private func tile(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: value).dxType(.title).foregroundStyle(ground.ink).lineLimit(1).minimumScaleFactor(0.6)
            Text(verbatim: label).dxType(.caption).foregroundStyle(ground.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .dxCardOnColour(on: ground)
        .accessibilityElement(children: .combine)
    }
}

/// The card maker (S13.3, S13.4): Story (9:16) or Square, dark or sage, and only the numbers you switch on.
struct ShareCardMaker: View {
    let milestone: Milestone?
    let stats: MilestoneStats

    enum Format: String, CaseIterable { case story, square }
    enum Look: String, CaseIterable { case dawn, night }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.displayScale) private var displayScale
    @State private var format = Format.story
    @State private var look = Look.dawn
    @State private var showMoney = false
    @State private var showCravings = false
    @State private var showCounter = false

    var body: some View {
        VStack(spacing: DX.Space.s) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 16, weight: .bold)).foregroundStyle(Read4.ink)
                        .frame(width: 44, height: 44).background(Read4.surface, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Close"))
                Spacer()
                Text("Share card").v4Text(.micro)
                Spacer()
                Color.clear.frame(width: 44, height: 1)
            }
            .padding(.top, DX.Space.s)
            ScrollView {
                VStack(spacing: DX.Space.s) {
                    ShareCard(days: days, extras: extras, look: look)
                        .frame(width: format == .story ? 1080 : 1080, height: format == .story ? 1920 : 1080)
                        .scaleEffect(previewScale, anchor: .topLeading)
                        .frame(width: 1080 * previewScale, height: (format == .story ? 1920 : 1080) * previewScale, alignment: .topLeading)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: .black.opacity(0.18), radius: 18, y: 10)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text("Card preview: \(days) days into my quit"))
                    HStack(spacing: DX.Space.xs) {
                        picker(Format.allCases, selection: $format) { $0 == .story ? "Story" : "Square" }
                        picker(Look.allCases, selection: $look) { $0 == .dawn ? "Dawn" : "Night" }
                    }
                    VStack(spacing: 6) {
                        toggleRow("Days since Quit Day", detail: nil, isOn: .constant(true)).disabled(true)
                        toggleRow("Money kept", detail: stats.money, isOn: $showMoney)
                        toggleRow("Cravings ridden out", detail: stats.cravingsRiddenOut.formatted(), isOn: $showCravings)
                        toggleRow(LocalizedStringKey(stats.counterLabel), detail: stats.counterValue, isOn: $showCounter)
                    }
                    .tint(Read4.accent)
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            if let image = rendered {
                ShareLink(item: image, preview: SharePreview("DayXero · \(days) days", image: image)) {
                    Text("Share").frame(maxWidth: .infinity)
                }
                .buttonStyle(.dx(.primary, on: .reading))
                .simultaneousGesture(TapGesture().onEnded {
                    Analytics.track(.shareCardShared(destination: format.rawValue))
                })
            }
        }
        .padding(.horizontal, DX.Space.m)
        .dxReadableColumn()
        .padding(.bottom, DX.Space.xs)
        .background(Read4.background.ignoresSafeArea())
        .onAppear { Analytics.track(.shareCardCreated(milestone: milestone?.id ?? "days-\(stats.daysClear)")) }
    }

    private var days: Int { milestone?.number ?? stats.daysClear }

    private var previewScale: CGFloat { format == .story ? 0.15 : 0.2 }

    /// What's on the card besides the days. Nothing personal unless switched on.
    private var extras: [String] {
        var parts: [String] = []
        if showMoney { parts.append(String(localized: "\(stats.money) kept")) }
        if showCravings { parts.append(String(localized: "\(stats.cravingsRiddenOut) cravings ridden out")) }
        if showCounter { parts.append(stats.counterPhrase) }
        return parts
    }

    /// The card drawn at full size: 1080 × 1920 for Stories, 1080 × 1080 square.
    private var rendered: Image? {
        let renderer = ImageRenderer(content: ShareCard(days: days, extras: extras, look: look)
            .frame(width: 1080, height: format == .story ? 1920 : 1080))
        renderer.scale = 1
        return renderer.uiImage.map(Image.init(uiImage:))
    }

    private func picker<T: Hashable>(_ options: [T], selection: Binding<T>, title: @escaping (T) -> LocalizedStringKey) -> some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                let on = selection.wrappedValue == option
                Button { selection.wrappedValue = option } label: {
                    // Each option is at least 44 pt tall (S27.20).
                    Text(title(option)).dxFont(14, weight: 600, style: .subheadline)
                        .foregroundStyle(on ? Read4.onInk : Read4.muted)
                        .padding(.horizontal, 16)
                        .frame(minHeight: DX.Layout.touchTarget)
                        .background(on ? Read4.ink : .clear, in: Capsule())
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(3)
        .background(Read4.surface, in: Capsule())
    }

    private func toggleRow(_ title: LocalizedStringKey, detail: String?, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 6) {
                Text(title).dxFont(14, weight: 600, style: .subheadline).foregroundStyle(Read4.ink)
                if let detail { Text(verbatim: detail).v4Text(.subtitle) }
            }
        }
        .padding(.vertical, 8).padding(.horizontal, 12)
        .background(Read4.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Read4.hairline))
    }
}

/// The share card itself, laid out at 1080 points wide. Wordmark always; no name or photo (S13.4).
/// Dawn: Xero cheering on the apricot morning. Night: Glim on violet.
struct ShareCard: View {
    let days: Int
    let extras: [String]
    let look: ShareCardMaker.Look

    var body: some View {
        let dawn = look == .dawn
        let background = Color(hex: dawn ? 0xFFC38A : 0x0F1B33)
        let ink = Color(hex: dawn ? 0x1E1A3A : 0xFFF8EE)
        ZStack(alignment: .top) {
            background
            VStack(spacing: 0) {
                HorizonScene(dawn ? .dawn : .night, clarity: CrewGrowth.clarity(daysClear: days), fit: .bottom, animate: false)
                    .frame(height: 760)
                Spacer(minLength: 0)
            }
            VStack(alignment: .leading, spacing: 0) {
                Text(verbatim: "DayXero").font(DX.Typeface4.swiftUIFont(.display, size: 64, weight: 800))
                Spacer()
                Group {
                    if dawn {
                        XeroView(mood: .cheer, stage: CrewGrowth.stage(daysClear: days), points: 420, animate: false)
                    } else {
                        GlimView(mood: .calm, stage: CrewGrowth.stage(daysClear: days), points: 420, animate: false)
                    }
                }
                .frame(maxWidth: .infinity)
                Text(verbatim: "\(days)").font(DX.Typeface4.swiftUIFont(.display, size: 380, weight: 800))
                    .lineLimit(1).minimumScaleFactor(0.4)
                Text(days == 1 ? "day into my quit" : "days into my quit")
                    .font(DX.Typeface4.swiftUIFont(.display, size: 72, weight: 700))
                if !extras.isEmpty {
                    Text(verbatim: extras.joined(separator: " · "))
                        .font(DX.Typeface4.swiftUIFont(.body, size: 46, weight: 500))
                        .opacity(0.85)
                        .padding(.top, 36)
                }
            }
            .foregroundStyle(ink)
            .padding(100)
        }
        .environment(\.dynamicTypeSize, .large)
    }
}

/// Milestones on the Progress tab (S13.1): reached in sage, the next outlined with a countdown, the rest dashed.
struct MilestonesRow: View {
    let daysClear: Int
    let onOpen: (Milestone) -> Void

    var body: some View {
        let next = Milestone.next(daysClear: daysClear)
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Milestones").dxType(.headline).foregroundStyle(Read4.ink)
                Spacer()
                Text("\(Milestone.reached(daysClear: daysClear).count) of \(Milestone.all.count)").v4Text(.subtitle)
            }
            .accessibilityAddTraits(.isHeader)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 14) {
                ForEach(Milestone.all) { milestone in
                    let reached = milestone.isReached(daysClear: daysClear)
                    Button { if reached { onOpen(milestone) } } label: {
                        badge(milestone, reached: reached, isNext: milestone == next)
                    }
                    .buttonStyle(.plain)
                    .disabled(!reached)
                }
            }
            .padding(14)
            .dxCard(on: .reading)
        }
        .padding(.top, DX.Space.s)
    }

    /// v5 (036): the kit medallions. Quit Day is the Day Xero coin, the days their day badges; reached ones earned,
    /// the next one with its ring toward it, the rest locked.
    private func badge(_ m: Milestone, reached: Bool, isNext: Bool) -> some View {
        let bottom: String = if isNext {
            String(localized: "in \(m.reachedOnDay - daysClear) days")
        } else {
            switch m {
            case .quitDay: String(localized: "Quit Day")
            case .days(1): String(localized: "day")
            case .days(365): String(localized: "year")
            case .days: String(localized: "days")
            }
        }
        let state: DXBadge.Status = reached ? .earned : isNext ? .next(nextFraction(m)) : .locked
        return VStack(spacing: 6) {
            Group {
                switch m {
                case .quitDay: DXBadge(.xero, state: state, size: 64)
                case .days(365): DXBadge(.day, n: "1y", state: state, size: 64)
                case let .days(n): DXBadge(.day, n: n, state: state, size: 64)
                }
            }
            Text(verbatim: bottom).dxType(.caption).lineLimit(1).minimumScaleFactor(0.7)
                .foregroundStyle(isNext ? Read4.ink : Read4.muted)
        }
        .frame(maxWidth: .infinity)
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: m.title))
        .accessibilityValue(Text(reached ? "Reached" : isNext ? "Next, in \(m.reachedOnDay - daysClear) days" : "Ahead"))
    }

    /// How far toward the next milestone, from the one before it.
    private func nextFraction(_ m: Milestone) -> Double {
        let before = Milestone.all.last { $0.reachedOnDay < m.reachedOnDay }?.reachedOnDay ?? 0
        let span = Double(max(m.reachedOnDay - before, 1))
        return min(1, max(0, Double(daysClear - before) / span))
    }
}

/// The milestone's rays (v5, 039): sixteen soft paper rays fanning round the badge in two warm tones.
struct MilestoneRays: View {
    var body: some View {
        ZStack {
            ForEach(0..<16, id: \.self) { i in
                Capsule()
                    .fill(Color(hex: i.isMultiple(of: 2) ? 0xFFE7B0 : 0xFFA477).opacity(i.isMultiple(of: 2) ? 0.9 : 0.7))
                    .frame(width: i.isMultiple(of: 2) ? 14 : 10, height: i.isMultiple(of: 2) ? 56 : 36)
                    .offset(y: i.isMultiple(of: 2) ? -122 : -112)
                    .rotationEffect(.degrees(Double(i) * 22.5))
            }
        }
        .accessibilityHidden(true)
    }
}
