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

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var appeared = false
    @State private var sharing = false

    private let ground = DX.Ground.sun

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 10) {
                    // S27.16: each milestone has its own sky, token and company, and Xero grows with the stage.
                    ZStack(alignment: .bottom) {
                        HeroScene(milestone.scene, clarity: CrewGrowth.clarity(daysClear: stats.daysClear), height: 280, edge: ground.background)
                        company
                            .scaleEffect(appeared || reduceMotion ? 1 : DX.Move.celebrateFromScale, anchor: .bottom)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: -6)
                            .accessibilityHidden(true)
                    }
                    .overlay(alignment: .topLeading) {
                        // The milestone's token, pinned to the sky like a sticker.
                        KitArt(milestone.token, cornerRadius: 18, animate: false)
                            .frame(width: 60, height: 60)
                            .shadow(color: Color(hex: 0x1A0B2E).opacity(0.18), radius: 8, y: 6)
                            .rotationEffect(.degrees(-8))
                            .padding(.leading, 22 + DX.Layout.gutter)
                            .padding(.top, 70)
                            .accessibilityHidden(true)
                    }
                    .overlay(alignment: .topTrailing) {
                        Button(action: onClose) {
                            Image(systemName: "xmark").font(.system(size: 18, weight: .bold)).foregroundStyle(DX.Fill.navy)
                                .frame(width: 44, height: 44)
                                .background(DX.Fill.cream.opacity(0.85), in: Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text("Close"))
                        .padding(.trailing, 10).padding(.top, 50)
                    }
                    .padding(.horizontal, -DX.Layout.gutter)
                    .ignoresSafeArea(edges: .top)
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        CountingText(Double(milestone.number), format: { String(Int($0.rounded())) })
                            .dxType(.display).monospacedDigit()
                        Text(verbatim: milestone.caption).dxType(.headline)
                    }
                    .foregroundStyle(ground.ink)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(verbatim: milestone.title))
                    .accessibilityAddTraits(.isHeader)
                    Text(verbatim: milestone.title).dxType(.title).foregroundStyle(ground.ink).multilineTextAlignment(.center)
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
            withAnimation(DX.Move.animation(DX.Move.celebrate, reduceMotion: reduceMotion)) { appeared = true }
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
        let background = Color(hex: dawn ? 0xFFC38A : 0x4A3596)
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
        VStack(alignment: .leading, spacing: DX.Space.xs) {
            HStack(alignment: .firstTextBaseline) {
                Text("Milestones").v4Text(.micro)
                Spacer()
                Text("\(Milestone.reached(daysClear: daysClear).count) of \(Milestone.all.count)").v4Text(.subtitle)
            }
            .accessibilityAddTraits(.isHeader)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DX.Space.xs), count: 4), spacing: DX.Space.xs) {
                ForEach(Milestone.all) { milestone in
                    let reached = milestone.isReached(daysClear: daysClear)
                    Button { if reached { onOpen(milestone) } } label: {
                        badge(milestone, reached: reached, isNext: milestone == next)
                    }
                    .buttonStyle(.plain)
                    .disabled(!reached)
                }
            }
        }
        .padding(.top, DX.Space.s)
    }

    private func badge(_ m: Milestone, reached: Bool, isNext: Bool) -> some View {
        let top: String = switch m {
        case .quitDay: "QD"
        case .days(365): "1y"
        case let .days(n): "\(n)"
        }
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
        return VStack(spacing: 0) {
            Text(verbatim: top).dxType(.headline)
            Text(verbatim: bottom).dxType(.caption).lineLimit(1).minimumScaleFactor(0.7)
        }
        .foregroundStyle(reached ? DX.Fill.cream : isNext ? Read4.ink : Read4.muted)
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .background(reached ? DX.Fill.green : .clear, in: Circle())
        .overlay {
            if isNext {
                Circle().strokeBorder(Read4.ink, lineWidth: 2)
            } else if !reached {
                Circle().strokeBorder(Read4.faint, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: m.title))
        .accessibilityValue(Text(reached ? "Reached" : isNext ? "Next, in \(m.reachedOnDay - daysClear) days" : "Ahead"))
    }
}
