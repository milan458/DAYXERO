import DayXeroCore
import SwiftData
import SwiftUI
import UIKit

/// Numbers the moment and the share card can show. Only days clear is on a card by default (S13.4).
struct MilestoneStats: Equatable {
    var daysClear: Int
    var money: String
    var cravingsRiddenOut: Int
    /// The main product's counter, e.g. ("Puffs not taken", "1,400").
    var counterLabel: String
    var counterValue: String

    @MainActor
    init(profile: UserProfile, logs: [LogEntry], now: Date = .now) {
        let snap = HomeSnapshot(profile: profile, isPro: true, now: now)
        daysClear = snap.daysClear
        money = snap.moneyKept.formatted(.currency(code: snap.currencyCode))
        cravingsRiddenOut = logs.filter { $0.kind == .craving && $0.outcome == .passed }.count
        let counter = snap.counters.first
        counterValue = (counter?.avoided ?? 0).formatted()
        counterLabel = switch counter?.product {
        case .vape: String(localized: "Puffs not taken")
        case .pouches: String(localized: "Pouches not used")
        default: String(localized: "Cigarettes not smoked")
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

/// The full-screen moment on a milestone day (S13.2): rings and sparks for about a second, a success haptic,
/// two of your numbers, then Keep going or Share. Reduce Motion keeps everything still and fades the number in.
struct MilestoneMoment: View {
    let milestone: Milestone
    let stats: MilestoneStats
    let onClose: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    @State private var sharing = false

    var body: some View {
        VStack(spacing: DX.Space.s) {
            HStack {
                Spacer()
                Text("Milestone").dxText(.micro)
                Spacer()
            }
            .overlay(alignment: .trailing) {
                Button(action: onClose) { Image(systemName: "xmark") }.buttonStyle(.dxIcon).accessibilityLabel(Text("Close"))
            }
            .padding(.top, DX.Space.s)
            ScrollView {
                VStack(spacing: DX.Space.s) {
                    burst.padding(.top, DX.Space.l)
                    Text(verbatim: milestone.title).dxText(.title).multilineTextAlignment(.center)
                    Text(verbatim: milestone.line).dxText(.subtitle).multilineTextAlignment(.center)
                    if let id = milestone.sourceID, let source = HealthTimeline.bundled?.source(id) {
                        Link(destination: source.url) {
                            Text(verbatim: source.label).font(DX.TextStyle.subtitle.font).underline().foregroundStyle(DX.Palette.accentInk)
                        }
                    }
                    if milestone != .quitDay {
                        HStack(spacing: DX.Space.xs) {
                            stat(stats.counterLabel, stats.counterValue)
                            stat(String(localized: "Money kept"), stats.money)
                        }
                        .padding(.top, DX.Space.s)
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            Button("Keep going", action: onClose).buttonStyle(.dxPrimary)
            Button { sharing = true } label: { Label("Share", systemImage: "square.and.arrow.up").frame(maxWidth: .infinity) }
                .buttonStyle(.dxSecondary)
        }
        .padding(.horizontal, DX.Space.m)
        .dxReadableColumn()
        .padding(.bottom, DX.Space.xs)
        .background {
            ZStack {
                DX.Palette.canvas
                RadialGradient(colors: [DX.Palette.sage.opacity(0.3), .clear], center: UnitPoint(x: 0.5, y: 0.32), startRadius: 0, endRadius: 420)
            }
            .ignoresSafeArea()
        }
        .sensoryFeedback(DX.Haptic.commit, trigger: appeared)
        .onAppear {
            withAnimation(reduceMotion ? .easeIn(duration: 0.4) : .spring(response: 0.9, dampingFraction: 0.7)) { appeared = true }
        }
        .sheet(isPresented: $sharing) {
            ShareCardMaker(milestone: milestone, stats: stats).presentationDetents([.large])
        }
    }

    private var burst: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(DX.Palette.sage.opacity(0.5 - Double(i) * 0.15), lineWidth: 2)
                    .frame(width: 230 - CGFloat(i) * 44, height: 230 - CGFloat(i) * 44)
                    .scaleEffect(appeared || reduceMotion ? 1 : 0.6)
                    .opacity(appeared ? 1 : 0)
            }
            ForEach(Array(Self.sparks.enumerated()), id: \.offset) { _, spark in
                Circle().fill(DX.Palette.sage).frame(width: 8, height: 8)
                    .offset(x: appeared && !reduceMotion ? spark.x : spark.x * 0.4, y: appeared && !reduceMotion ? spark.y : spark.y * 0.4)
                    .opacity(appeared ? 0.4 + spark.o : 0)
            }
            VStack(spacing: 0) {
                Text(verbatim: "\(milestone.number)").font(.custom(DX.Typeface.bold, size: 88, relativeTo: .largeTitle))
                    .foregroundStyle(DX.Palette.text)
                Text(verbatim: milestone.caption.uppercased()).dxText(.micro, color: DX.Palette.accentInk)
            }
            .opacity(appeared ? 1 : 0)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
        .frame(width: 240, height: 240)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: milestone.title))
    }

    private static let sparks: [(x: CGFloat, y: CGFloat, o: Double)] = [
        (-80, -70, 0.4), (90, -95, 0.2), (-100, 40, 0.3), (95, 50, 0.5), (0, -118, 0.3), (50, 110, 0.2), (-55, 112, 0.4),
    ]

    private func stat(_ label: String, _ value: String) -> some View {
        DXCard(padding: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: value).font(.custom(DX.Typeface.bold, size: 18, relativeTo: .title3)).foregroundStyle(DX.Palette.text)
                Text(verbatim: label).dxText(.subtitle)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}

/// The card maker (S13.3, S13.4): Story (9:16) or Square, dark or sage, and only the numbers you switch on.
struct ShareCardMaker: View {
    let milestone: Milestone?
    let stats: MilestoneStats

    enum Format: String, CaseIterable { case story, square }
    enum Look: String, CaseIterable { case dark, sage }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.displayScale) private var displayScale
    @State private var format = Format.story
    @State private var look = Look.dark
    @State private var showMoney = false
    @State private var showCravings = false
    @State private var showCounter = false

    var body: some View {
        VStack(spacing: DX.Space.s) {
            HStack {
                Button { dismiss() } label: { Image(systemName: "xmark") }.buttonStyle(.dxIcon).accessibilityLabel(Text("Close"))
                Spacer()
                Text("Share card").dxText(.micro)
                Spacer()
                Color.clear.frame(width: DX.Size.iconButton, height: 1)
            }
            .padding(.top, DX.Space.s)
            ScrollView {
                VStack(spacing: DX.Space.s) {
                    ShareCard(days: days, extras: extras, look: look)
                        .frame(width: format == .story ? 1080 : 1080, height: format == .story ? 1920 : 1080)
                        .scaleEffect(previewScale, anchor: .topLeading)
                        .frame(width: 1080 * previewScale, height: (format == .story ? 1920 : 1080) * previewScale, alignment: .topLeading)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: DX.Palette.shadow, radius: 18, y: 10)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text("Card preview: \(days) days nicotine-free"))
                    HStack(spacing: DX.Space.xs) {
                        picker(Format.allCases, selection: $format) { $0 == .story ? "Story" : "Square" }
                        picker(Look.allCases, selection: $look) { $0 == .dark ? "Dark" : "Sage" }
                    }
                    VStack(spacing: 6) {
                        toggleRow("Days clear", detail: nil, isOn: .constant(true)).disabled(true)
                        toggleRow("Money kept", detail: stats.money, isOn: $showMoney)
                        toggleRow("Cravings ridden out", detail: stats.cravingsRiddenOut.formatted(), isOn: $showCravings)
                        toggleRow(LocalizedStringKey(stats.counterLabel), detail: stats.counterValue, isOn: $showCounter)
                    }
                    .tint(DX.Palette.sage)
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            if let image = rendered {
                ShareLink(item: image, preview: SharePreview("DayXero · \(days) days", image: image)) {
                    Text("Share").frame(maxWidth: .infinity)
                }
                .buttonStyle(.dxPrimary)
                .simultaneousGesture(TapGesture().onEnded {
                    Analytics.track(.shareCardShared(destination: format.rawValue))
                })
            }
        }
        .padding(.horizontal, DX.Space.m)
        .dxReadableColumn()
        .padding(.bottom, DX.Space.xs)
        .dxCanvas()
        .onAppear { Analytics.track(.shareCardCreated(milestone: milestone?.id ?? "days-\(stats.daysClear)")) }
    }

    private var days: Int { milestone?.number ?? stats.daysClear }

    private var previewScale: CGFloat { format == .story ? 0.15 : 0.2 }

    /// What's on the card besides the days. Nothing personal unless switched on.
    private var extras: [String] {
        var parts: [String] = []
        if showMoney { parts.append(String(localized: "\(stats.money) kept")) }
        if showCravings { parts.append(String(localized: "\(stats.cravingsRiddenOut) cravings ridden out")) }
        if showCounter { parts.append("\(stats.counterValue) \(stats.counterLabel.lowercased())") }
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
                    Text(title(option)).font(.custom(DX.Typeface.semibold, size: 12, relativeTo: .caption))
                        .foregroundStyle(on ? DX.Palette.onPrimary : DX.Palette.text2)
                        .padding(.vertical, 6).padding(.horizontal, 12)
                        .background(on ? DX.Palette.primary : .clear, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(3)
        .background(DX.Palette.surface2, in: Capsule())
    }

    private func toggleRow(_ title: LocalizedStringKey, detail: String?, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 6) {
                Text(title).font(.custom(DX.Typeface.semibold, size: 14, relativeTo: .subheadline)).foregroundStyle(DX.Palette.text)
                if let detail { Text(verbatim: detail).dxText(.subtitle) }
            }
        }
        .padding(.vertical, 8).padding(.horizontal, 12)
        .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(DX.Palette.hairline))
    }
}

/// The share card itself, laid out at 1080 points wide. Wordmark always; no name or photo (S13.4).
struct ShareCard: View {
    let days: Int
    let extras: [String]
    let look: ShareCardMaker.Look

    var body: some View {
        let ink = look == .dark ? Color.white : Color(hex: 0x11140A)
        ZStack(alignment: .topLeading) {
            if look == .dark {
                RadialGradient(colors: [Color(hex: 0x3A4719), Color(hex: 0x0A0C06)], center: UnitPoint(x: 0.5, y: 0.3), startRadius: 0, endRadius: 1300)
            } else {
                LinearGradient(colors: [Color(hex: 0xD6DBB0), Color(hex: 0xBCC388), Color(hex: 0x9AA36A)], startPoint: .top, endPoint: .bottom)
            }
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 16) {
                    Circle().fill(look == .dark ? DX.Palette.sage : ink).frame(width: 34, height: 34)
                    Text(verbatim: "DayXero").font(.custom(DX.Typeface.bold, size: 56, relativeTo: .title))
                }
                Spacer()
                Text(verbatim: "\(days)").font(.custom(DX.Typeface.bold, size: 420, relativeTo: .largeTitle)).tracking(-20)
                    .lineLimit(1).minimumScaleFactor(0.4)
                Text(days == 1 ? "day nicotine-free" : "days nicotine-free")
                    .font(.custom(DX.Typeface.semibold, size: 72, relativeTo: .title))
                if !extras.isEmpty {
                    Text(verbatim: extras.joined(separator: " · "))
                        .font(.custom(DX.Typeface.medium, size: 46, relativeTo: .title3))
                        .opacity(0.8)
                        .padding(.top, 40)
                }
            }
            .foregroundStyle(ink)
            .padding(110)
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
                Text("Milestones").dxText(.micro)
                Spacer()
                Text("\(Milestone.reached(daysClear: daysClear).count) of \(Milestone.all.count)").dxText(.subtitle)
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
            Text(verbatim: top).font(.custom(DX.Typeface.bold, size: 18, relativeTo: .headline))
            Text(verbatim: bottom).font(.custom(DX.Typeface.regular, size: 10, relativeTo: .caption2)).lineLimit(1).minimumScaleFactor(0.7)
        }
        .foregroundStyle(reached ? DX.Palette.onAccent : isNext ? DX.Palette.text : DX.Palette.muted)
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .background(reached ? DX.Palette.sage : .clear, in: Circle())
        .overlay {
            if isNext {
                Circle().strokeBorder(DX.Palette.accentInk, lineWidth: 2)
            } else if !reached {
                Circle().strokeBorder(DX.Palette.faint, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: m.title))
        .accessibilityValue(Text(reached ? "Reached" : isNext ? "Next, in \(m.reachedOnDay - daysClear) days" : "Ahead"))
    }
}
