import DayXeroCore
import SwiftUI

/// "What's changing" (v5, 037): Day N and the product chips, then one card per change on a rail that runs solid
/// through what's done and dashed on to what's ahead. Each card has its paper-cut spot, the title and when; the change
/// under way leads with a warm tint and its bar. Sources once, small, at the bottom.
struct HealthTimelineView: View {
    let profile: UserProfile
    var onClose: (() -> Void)?

    @State private var product: Product
    @State private var open: HealthTimeline.Item?

    private let ground = DX.Ground.reading

    init(profile: UserProfile, onClose: (() -> Void)? = nil) {
        self.profile = profile
        self.onClose = onClose
        let product = profile.primaryProduct?.product ?? .cigarettes
        _product = State(initialValue: product)
        #if DEBUG
        // Screenshots of one change's full story: `-dx.openHealthItem lips`.
        if let id = UserDefaults.standard.string(forKey: "dx.openHealthItem") {
            _open = State(initialValue: HealthTimeline.bundled?.items(for: product).first { $0.id == id })
        }
        #endif
    }

    var body: some View {
        TimelineView(.everyMinute) { context in
            let clock = DayClock(boundaryHour: profile.dayBoundaryHour)
            let elapsed = HealthTimeline.elapsedHours(quitDay: profile.quitDay, now: context.date, clock: clock)
            let timeline = HealthTimeline.bundled
            let items = timeline?.items(for: product) ?? []
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if let onClose {
                        DXIconButton(.back, label: "Back", action: onClose)
                            .padding(.bottom, 14)
                    }
                    Text("What's changing")
                        .dxType(.large).foregroundStyle(ground.ink)
                        .accessibilityAddTraits(.isHeader)
                        .dxArrive(0, delay: 0)
                    Text(verbatim: subtitle(elapsed: elapsed, clock: clock, now: context.date))
                        .dxType(.footnote).foregroundStyle(ground.muted)
                        .padding(.top, 6)
                        .dxArrive(1, delay: 0)
                    if products.count > 1 {
                        switcher.padding(.top, 16).dxArrive(2, delay: 0)
                    }
                    VStack(spacing: 0) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                            let state = rowState(item, index: index, elapsed: elapsed)
                            let next = index + 1 < items.count ? rowState(items[index + 1], index: index + 1, elapsed: elapsed) : nil
                            HStack(alignment: .center, spacing: 10) {
                                HealthRailNode(state: state.node, above: index == 0 ? nil : state.node != .ahead,
                                               below: next.map { $0.node != .ahead }, past: index == 0 && state.node == .done,
                                               index: index, count: items.count)
                                    .frame(width: 20)
                                Button { open = item } label: { row(item, state: state, elapsed: elapsed) }
                                    .buttonStyle(.dxPress)
                            }
                            .padding(.vertical, 6)
                            .dxArrive(index + 3, delay: 0)
                        }
                    }
                    .padding(.top, 14)
                    sources(timeline)
                        .padding(.leading, 30)
                        .padding(.top, 16)
                        .dxArrive(items.count + 3, delay: 0)
                }
                .padding(.horizontal, DX.Layout.gutter)
                .dxReadableColumn()
                .padding(.top, DX.Space.xs)
                .padding(.bottom, DX.Space.xxl)
            }
        }
        .background(ground.background.ignoresSafeArea())
        .dxGround(.reading, paint: false)
        .fullScreenCover(item: $open) { item in
            HealthItemDetail(item: item, items: HealthTimeline.bundled?.items(for: product) ?? [],
                             quitDay: profile.quitDay, boundaryHour: profile.dayBoundaryHour,
                             timeline: HealthTimeline.bundled)
        }
    }

    private var products: [Product] {
        profile.products.sorted { ($0.isPrimary ? 0 : 1) < ($1.isPrimary ? 0 : 1) }.map(\.product)
    }

    private func subtitle(elapsed: Double, clock: DayClock, now: Date) -> String {
        if elapsed < 0 {
            let days = clock.days(from: now, toDate: profile.quitDay)
            return days == 1 ? String(localized: "Quit Day tomorrow · what changes from then")
                : String(localized: "Quit Day in \(days) days · what changes from then")
        }
        let day = clock.days(fromDate: profile.quitDay, to: now) + 1
        return String(localized: "Day \(day) · your body since Quit Day")
    }

    /// v5 (037): the products as kit chips.
    private var switcher: some View {
        HStack(spacing: 8) {
            ForEach(products, id: \.self) { p in
                DXChip(label(p), isOn: p == product, on: .reading) { product = p }
            }
        }
    }

    private func label(_ product: Product) -> LocalizedStringKey {
        switch product {
        case .cigarettes: "Smoking"
        case .vape: "Vaping"
        case .pouches: "Pouches"
        }
    }

    // MARK: Rows

    enum RowState: Equatable {
        case done, now(Double), first, ahead

        var node: HealthRailNode.Node {
            switch self {
            case .done: .done
            case .now, .first: .now
            case .ahead: .ahead
            }
        }
    }

    /// Before Quit Day the first change is raised as "From Quit Day"; after, the state from the timeline.
    private func rowState(_ item: HealthTimeline.Item, index: Int, elapsed: Double) -> RowState {
        if elapsed < 0 { return index == 0 ? .first : .ahead }
        switch HealthTimeline.state(of: item, elapsedHours: elapsed) {
        case .done: return .done
        case let .underWay(fraction): return .now(fraction)
        case .ahead: return .ahead
        }
    }

    /// One change (037): its spot, the title and when, a chevron. Done ones sit back on the ground, ahead ones on a
    /// card; the change under way leads with a warm tint, a little more height and its bar. What many people notice
    /// (CLIN-01) has no exact timing, so it never shows a bar.
    private func row(_ item: HealthTimeline.Item, state: RowState, elapsed: Double) -> some View {
        let status: String = switch state {
        case .first: String(localized: "From Quit Day")
        case .ahead where elapsed >= 0 && !item.isFelt: HealthItemDetail.about(hours: item.fromHours - elapsed)
        default: item.when
        }
        let isNow: Bool = if case .now = state { true } else { false }
        let fraction: Double? = if case let .now(f) = state, !item.isFelt { f } else { nil }
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)
        return HStack(spacing: 12) {
            HealthSpot(id: item.id)
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: item.title)
                    .dxFace(.display, isNow ? 18 : 17, weight: 700, tracking: -0.2)
                    .foregroundStyle(ground.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Text(verbatim: status).dxFont(14, weight: 600, style: .footnote)
                    .foregroundStyle(isNow ? ground.ink : ground.muted)
                if let fraction { NowBar(fraction: fraction).padding(.top, 6) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            DXIcon(.chev, size: 18).foregroundStyle(ground.muted)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, isNow ? 14 : 10)
        .background {
            if isNow {
                NowTint().clipShape(shape)
            } else if state == .ahead || state == .first {
                shape.fill(ground.card)
            }
        }
        .overlay(shape.strokeBorder(isNow ? Color(light: (0xE87846, 0.45), dark: (0xFFB27A, 0.7)) : ground.line, lineWidth: isNow ? 1.5 : 1))
        .shadow(color: isNow ? Color(light: (0x1E1A3A, 0.1), dark: (0x000000, 0.3)) : .clear, radius: 13, y: 12)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "\(item.title). \(status)"))
        .accessibilityValue(Text(accessibilityValue(state)))
        .accessibilityHint(Text("Opens the full story"))
    }

    private func accessibilityValue(_ state: RowState) -> String {
        switch state {
        case .done: String(localized: "Done")
        case let .now(fraction): String(localized: "Under way, \(Int((fraction * 100).rounded())) percent")
        case .first: String(localized: "Starts on Quit Day")
        case .ahead: String(localized: "Ahead")
        }
    }

    /// "Typical times, everyone is different. Sources: NHS, smokefree.gov", each source a link.
    private func sources(_ timeline: HealthTimeline?) -> some View {
        HealthSourcesLine(sources: timeline?.sources(for: product) ?? [])
    }
}

/// The under-way card's warm tint: apricot through white in light, a warm navy in dark.
private struct NowTint: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        if scheme == .dark {
            DX.Ground.reading.card.overlay(Color(hex: 0xFFB27A).opacity(0.09))
        } else {
            Color.white.overlay(Color(hex: 0xFF9A5C).opacity(0.16))
        }
    }
}

/// The under-way bar: 4 pt, apricot, filling from empty at 0.7 s.
private struct NowBar: View {
    let fraction: Double
    @State private var shown = false
    private let motion = MotionPolicy()

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Color(light: (0xE87846, 0.2), dark: (0xFFB27A, 0.2)))
                Capsule().fill(Color(light: 0xF08A4B, dark: 0xFFB27A))
                    .frame(width: proxy.size.width * min(1, max(0, shown ? fraction : 0)))
            }
        }
        .frame(height: 4)
        .onAppear {
            if motion.reduce { shown = true; return }
            withAnimation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.9).delay(0.7)) { shown = true }
        }
    }
}

/// "Typical times, everyone is different. Sources: NHS, smokefree.gov" (037, 038), each source underlined and a link.
struct HealthSourcesLine: View {
    let sources: [HealthTimeline.Source]

    var body: some View {
        let names = Self.names(sources)
        let lead = String(localized: "Typical times, everyone is different.")
        let prefix = names.count == 1 ? String(localized: "Source:") : String(localized: "Sources:")
        var text = AttributedString(lead + (names.isEmpty ? "" : " " + prefix + " "))
        for (i, entry) in names.enumerated() {
            var link = AttributedString(entry.name)
            link.link = entry.url
            link.underlineStyle = .single
            text += link
            if i < names.count - 1 { text += AttributedString(", ") }
        }
        return Text(text)
            .dxFont(13, weight: 600, style: .footnote)
            .foregroundStyle(DX.Ground.reading.muted)
            .tint(DX.Ground.reading.muted)
            .fixedSize(horizontal: false, vertical: true)
    }

    static func names(_ sources: [HealthTimeline.Source]) -> [(name: String, url: URL)] {
        var seen: [(String, URL)] = []
        for s in sources {
            let name = s.label.hasPrefix("Source: ") ? String(s.label.dropFirst("Source: ".count)) : s.label
            if !seen.contains(where: { $0.0 == name }) { seen.append((name, s.url)) }
        }
        return seen.map { (name: $0.0, url: $0.1) }
    }
}

/// The rail beside each card (037): one continuous line through the node centres, solid through today and dashed on
/// to what's ahead, drawn top to bottom. A grey dot for the first change once it's passed, a green tick for done, a
/// half-filled node with a soft pulse for the change under way, an open ring ahead.
struct HealthRailNode: View {
    enum Node { case done, now, ahead }
    let state: Node
    /// The line above the node: nil for none, true solid, false dashed.
    let above: Bool?
    let below: Bool?
    let past: Bool
    let index: Int
    let count: Int
    @State private var drawn = false
    @State private var pulse = false
    private let motion = MotionPolicy()

    var body: some View {
        let ink = DX.Ground.reading.ink
        let rail = Color(light: (0x1E1A3A, 0.5), dark: (0xFFF8EE, 0.34))
        ZStack {
            GeometryReader { proxy in
                let x = proxy.size.width / 2, mid = proxy.size.height / 2
                if let above { segment(x: x, from: -6, to: mid, solid: above).stroke(rail, style: style(solid: above)) }
                if let below { segment(x: x, from: mid, to: proxy.size.height + 6, solid: below).stroke(rail, style: style(solid: below)) }
            }
            .mask(alignment: .top) {
                GeometryReader { proxy in
                    Rectangle().frame(height: drawn ? proxy.size.height + 12 : 0).offset(y: -6)
                }
            }
            node(ink: ink)
        }
        .onAppear {
            if motion.reduce { drawn = true; return }
            let step = 0.9 / Double(max(count, 1))
            withAnimation(.linear(duration: step).delay(0.3 + step * Double(index))) { drawn = true }
            if state == .now, motion.breathes {
                withAnimation(.easeOut(duration: 2.4).repeatForever(autoreverses: false).delay(1.2)) { pulse = true }
            }
        }
        .accessibilityHidden(true)
    }

    private func style(solid: Bool) -> StrokeStyle {
        StrokeStyle(lineWidth: 2, lineCap: solid ? .butt : .round, dash: solid ? [] : [3, 5])
    }

    private func segment(x: CGFloat, from: CGFloat, to: CGFloat, solid: Bool) -> Path {
        Path { p in
            p.move(to: CGPoint(x: x, y: from))
            p.addLine(to: CGPoint(x: x, y: to))
        }
    }

    @ViewBuilder
    private func node(ink: Color) -> some View {
        let g = DX.Ground.reading.background
        switch state {
        case .done where past:
            ZStack {
                Circle().fill(g).frame(width: 20, height: 20)
                Circle().fill(DX.Ground.reading.muted).frame(width: 12, height: 12)
            }
        case .done:
            ZStack {
                Circle().fill(DX.Fill.done).frame(width: 20, height: 20)
                DXIcon(.check, size: 12, weight: 3.2).foregroundStyle(.white)
            }
        case .now:
            ZStack {
                Circle().stroke(ink, lineWidth: 2).frame(width: 30, height: 30)
                    .scaleEffect(pulse ? 1.25 : 0.7).opacity(pulse ? 0 : 0.35)
                Circle().fill(g).frame(width: 20, height: 20)
                HalfDisc().fill(ink).frame(width: 20, height: 20)
                Circle().strokeBorder(ink, lineWidth: 2.5).frame(width: 20, height: 20)
            }
        case .ahead:
            ZStack {
                Circle().fill(g).frame(width: 20, height: 20)
                Circle().strokeBorder(DX.Ground.reading.muted, lineWidth: 2.5).frame(width: 20, height: 20)
            }
        }
    }

    /// The right half of a disc.
    private struct HalfDisc: Shape {
        func path(in rect: CGRect) -> Path {
            Path { p in
                p.move(to: CGPoint(x: rect.midX, y: rect.minY))
                p.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: rect.width / 2, startAngle: .degrees(-90), endAngle: .degrees(90), clockwise: false)
                p.closeSubpath()
            }
        }
    }
}

/// One stop on the path: the change's illustration on the line, and its card. The line above a stop is solid once
/// the change has started; below it, once it's done.
struct HealthPathStop: View {
    let item: HealthTimeline.Item
    let state: HealthTimeline.State
    let isLast: Bool

    private static let node: CGFloat = 48
    private static let nodeTop: CGFloat = 12

    var body: some View {
        HStack(alignment: .top, spacing: DX.Space.s) {
            HealthBadge(id: item.id, state: state, size: Self.node)
                .padding(.top, Self.nodeTop)
                .frame(width: Self.node + 8)
                .frame(maxHeight: .infinity, alignment: .top)
                .background { rail }
            HealthItemCard(item: item, state: state)
                .padding(.bottom, isLast ? 0 : DX.Space.s)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var rail: some View {
        GeometryReader { geo in
            let x = geo.size.width / 2, centre = Self.nodeTop + Self.node / 2
            segment(x: x, from: 0, to: centre, solid: state != .ahead)
            if !isLast { segment(x: x, from: centre, to: geo.size.height, solid: state == .done) }
        }
        .accessibilityHidden(true)
    }

    private func segment(x: CGFloat, from: CGFloat, to: CGFloat, solid: Bool) -> some View {
        Path { p in
            p.move(to: CGPoint(x: x, y: from))
            p.addLine(to: CGPoint(x: x, y: to))
        }
        .stroke(solid ? Read4.accent : Read4.faint,
                style: StrokeStyle(lineWidth: solid ? 3 : 2.5, lineCap: .round, dash: solid ? [] : [0.5, 7]))
    }
}

/// One change, as a stadium card: done, under way (with a bar), or ahead.
struct HealthItemCard: View {
    let item: HealthTimeline.Item
    let state: HealthTimeline.State

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .center) {
                Text(verbatim: item.when).v4Text(.micro)
                Spacer(minLength: DX.Space.xs)
                badge
            }
            Text(verbatim: item.title).dxFont(16, weight: 600, style: .body).foregroundStyle(Read4.ink)
                .multilineTextAlignment(.leading)
            if !item.line.isEmpty {
                Text(verbatim: item.line).v4Text(.subtitle).multilineTextAlignment(.leading)
            }
            if case let .underWay(fraction) = state, !item.isFelt {
                V4ProgressBar(value: fraction).padding(.top, 4)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, DX.Space.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Read4.card, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous)
            .strokeBorder(state == .done ? Read4.accent.opacity(0.45) : Read4.hairline))
        .opacity(state == .ahead ? 0.62 : 1)
        .accessibilityElement(children: .combine)
        .accessibilityValue(Text(stateText))
        .accessibilityHint(Text("Opens the full story"))
    }

    private var badge: some View {
        Text(stateText)
            .dxFont(12, weight: 700, style: .caption2)
            .tracking(0.6)
            
            .lineLimit(1)
            .foregroundStyle(state == .done ? DX.Fill.cream : isUnderWay ? Read4.onInk : Read4.muted)
            .padding(.vertical, 3).padding(.horizontal, 8)
            .background(state == .done ? Read4.accent : isUnderWay ? Read4.ink : Read4.track, in: Capsule())
            .fixedSize()
    }

    private var isUnderWay: Bool {
        if case .underWay = state { return true }
        return false
    }

    private var stateText: LocalizedStringKey {
        switch state {
        case .done: "Done"
        case .underWay where item.isFelt: "Around now"
        case .underWay: "Under way"
        case .ahead: "Ahead"
        }
    }
}

/// The full story of one change (v5, 038): its paper-cut scene with Xero, the title, where you're up to on a ring
/// ("Starts in about a week · Around Day 14. You are on Day 7"), the read, what you might notice, the next change,
/// and the source in small print.
struct HealthItemDetail: View {
    let items: [HealthTimeline.Item]
    let quitDay: Date
    let boundaryHour: Int
    let timeline: HealthTimeline?
    @State private var item: HealthTimeline.Item
    @Environment(\.dismiss) private var dismiss
    private let ground = DX.Ground.reading

    init(item: HealthTimeline.Item, items: [HealthTimeline.Item], quitDay: Date, boundaryHour: Int, timeline: HealthTimeline?) {
        self.items = items
        self.quitDay = quitDay
        self.boundaryHour = boundaryHour
        self.timeline = timeline
        _item = State(initialValue: item)
    }

    var body: some View {
        TimelineView(.everyMinute) { context in
            let clock = DayClock(boundaryHour: boundaryHour)
            let elapsed = HealthTimeline.elapsedHours(quitDay: quitDay, now: context.date, clock: clock)
            let today = clock.days(fromDate: quitDay, to: context.date) + 1
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    DXIconButton(.close, label: "Close") { dismiss() }
                        .padding(.bottom, 8)
                    HealthScene(id: item.id)
                        .frame(height: 194)
                        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                        .dxArrive(0, delay: 0)
                    Text(verbatim: item.title)
                        .dxType(.title).foregroundStyle(ground.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 14)
                        .accessibilityAddTraits(.isHeader)
                        .dxArrive(1, delay: 0)
                    whenCard(elapsed: elapsed, today: today)
                        .padding(.top, 10)
                        .dxArrive(2, delay: 0)
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(item.paragraphs.enumerated()), id: \.offset) { i, paragraph in
                            Text(verbatim: paragraph)
                                .dxType(.body).foregroundStyle(ground.ink)
                                .fixedSize(horizontal: false, vertical: true)
                                .dxArrive(3 + i, delay: 0)
                        }
                    }
                    .padding(.top, 10)
                    if let notice = item.notice, !notice.isEmpty {
                        Text("What you might notice").dxType(.headline).foregroundStyle(ground.ink)
                            .accessibilityAddTraits(.isHeader)
                            .padding(.top, 12)
                            .dxArrive(5, delay: 0)
                        VStack(spacing: 0) {
                            ForEach(Array(notice.enumerated()), id: \.offset) { i, line in
                                Text(verbatim: line).dxFont(15, weight: 500, style: .subheadline).foregroundStyle(ground.ink)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.vertical, 7)
                                    .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
                                    .padding(.horizontal, 16)
                                    .overlay(alignment: .top) { if i > 0 { Rectangle().fill(ground.line).frame(height: 1) } }
                            }
                        }
                        .dxCardChrome(on: .reading)
                        .padding(.top, 6)
                        .dxArrive(6, delay: 0)
                    }
                    if let next = nextItem {
                        Button { withAnimation(.easeInOut(duration: 0.3)) { item = next } } label: {
                            HStack(spacing: 14) {
                                VStack(alignment: .leading, spacing: 0) {
                                    Text("Next change").dxType(.footnote).foregroundStyle(ground.muted)
                                    Text(verbatim: next.title).dxFace(.display, 17, weight: 700, tracking: -0.2).foregroundStyle(ground.ink)
                                        .multilineTextAlignment(.leading)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                DXIcon(.chev, size: 18).foregroundStyle(ground.muted)
                            }
                            .padding(.horizontal, 16).padding(.vertical, 7)
                            .frame(minHeight: 56)
                            .dxCardChrome(on: .reading)
                        }
                        .buttonStyle(.dxPress)
                        .padding(.top, 8)
                        .dxArrive(7, delay: 0)
                    }
                    HealthSourcesLine(sources: source.map { [$0] } ?? [])
                        .padding(.top, 12)
                        .dxArrive(8, delay: 0)
                }
                .id(item.id)
                .padding(.horizontal, DX.Layout.gutter)
                .dxReadableColumn()
                .padding(.top, DX.Space.xs)
                .padding(.bottom, DX.Space.l)
            }
        }
        .background(ground.background.ignoresSafeArea())
        .dxGround(.reading, paint: false)
    }

    private var source: HealthTimeline.Source? { timeline?.source(item.source) }

    private var nextItem: HealthTimeline.Item? {
        guard let i = items.firstIndex(where: { $0.id == item.id }), i + 1 < items.count else { return nil }
        return items[i + 1]
    }

    /// Where you're up to: the day on a ring toward the change, and one line on when.
    private func whenCard(elapsed: Double, today: Int) -> some View {
        let state = HealthTimeline.state(of: item, elapsedHours: elapsed)
        let startDay = Int(item.fromHours / 24) + 1
        let endDay = Int(item.toHours / 24) + 1
        let (title, line, p): (String, String, Double) = {
            if elapsed < 0 { return (String(localized: "Counts from Quit Day"), item.when, 0) }
            if item.isFelt {
                return (item.when, String(localized: "Timing varies a lot. You are on Day \(today)"), min(1, Double(today) / Double(max(endDay, 1))))
            }
            switch state {
            case .done:
                return (String(localized: "Done"), String(localized: "Around Day \(endDay). You are on Day \(today)"), 1)
            case let .underWay(fraction):
                return (String(localized: "Happening now"), String(localized: "Usually done by Day \(endDay). You are on Day \(today)"), fraction)
            case .ahead:
                return (String(localized: "Starts \(Self.about(hours: item.fromHours - elapsed).lowercasedFirst)"),
                        String(localized: "Around Day \(startDay). You are on Day \(today)"), Double(today) / Double(max(startDay, 1)))
            }
        }()
        return HStack(spacing: 14) {
            ZStack {
                DXRing(p: p, size: 52, stroke: 5.5, color: ground.ink, track: ground.track)
                Text(verbatim: "\(max(0, today))").dxFace(.display, 20, weight: 800)
                    .foregroundStyle(ground.ink)
            }
            .frame(width: 52, height: 52)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: title).dxFace(.display, 17, weight: 700, tracking: -0.2).foregroundStyle(ground.ink)
                Text(verbatim: line).dxType(.footnote).foregroundStyle(ground.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .dxCardChrome(on: .reading)
        .accessibilityElement(children: .combine)
    }

    /// "In about a week", "In about 3 days", "In about 2 months".
    static func about(hours: Double) -> String {
        let days = Int((max(hours, 0) / 24).rounded())
        if days <= 1 { return String(localized: "In about a day") }
        if days < 5 { return String(localized: "In about \(days) days") }
        if days < 11 { return String(localized: "In about a week") }
        if days < 60 { return String(localized: "In about \(Int((Double(days) / 7).rounded())) weeks") }
        if days < 730 { return String(localized: "In about \(Int((Double(days) / 30.4).rounded())) months") }
        return String(localized: "In about \(Int((Double(days) / 365).rounded())) years")
    }
}

private extension String {
    var lowercasedFirst: String { prefix(1).lowercased() + dropFirst() }
}

/// "Your body" on Progress: what's under way, how many are done, and what's next.
struct HealthSummaryCard: View {
    let profile: UserProfile
    let now: Date
    let action: () -> Void

    var body: some View {
        let product = profile.primaryProduct?.product ?? .cigarettes
        let items = HealthTimeline.bundled?.items(for: product) ?? []
        let elapsed = HealthTimeline.elapsedHours(quitDay: profile.quitDay, now: now,
                                                 clock: DayClock(boundaryHour: profile.dayBoundaryHour))
        let states = items.map { HealthTimeline.state(of: $0, elapsedHours: elapsed) }
        let done = states.filter { $0 == .done }.count
        let (current, next) = HealthTimeline.nowAndNext(items, elapsedHours: elapsed)
        Button(action: action) {
            HStack(spacing: DX.Space.s) {
                let featured = current ?? next ?? items.last
                HealthBadge(id: featured?.id ?? "",
                            state: current.map { HealthTimeline.state(of: $0, elapsedHours: elapsed) } ?? (next == nil ? .done : .underWay(0)),
                            size: 44, showsRing: current != nil)
                    .padding(current != nil ? 4 : 0)
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: featured?.title ?? "")
                        .dxFont(16, weight: 600, style: .body).foregroundStyle(Read4.ink)
                        .multilineTextAlignment(.leading)
                    if elapsed < 0 {
                        Text("What changes in your body, from Quit Day").v4Text(.subtitle)
                    } else if let next {
                        Text("\(done) done · next: \(next.title.prefix(1).lowercased() + String(next.title.dropFirst()))").v4Text(.subtitle)
                            .multilineTextAlignment(.leading)
                    } else {
                        Text("\(done) done").v4Text(.subtitle)
                    }
                }
                Spacer(minLength: DX.Space.xs)
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(Read4.muted)
            }
            .padding(14)
            .background(Read4.card, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(Read4.hairline))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}
