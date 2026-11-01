import DayXeroCore
import SwiftUI

/// "What's changing" (decision 31): what changes after stopping, counted from Quit Day, one timeline per
/// product, on lime. A rail runs down the side: done changes are ticked on a solid line, the ones under way
/// are raised cards with a coral bar, the rest wait on a dotted line. Every change has its own illustration
/// from the kit; sources are listed once, small, at the bottom.
struct HealthTimelineView: View {
    let profile: UserProfile
    var onClose: (() -> Void)?

    @State private var product: Product
    @State private var open: HealthTimeline.Item?

    private let ground = DX.Ground.lime
    private let card = Color(light: 0xFFF8EE, dark: 0x16382D)
    private let coralInk = Color(light: 0xB2361C, dark: 0xFFB59E)

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
                VStack(alignment: .leading, spacing: DX.Space.s) {
                    header(elapsed: elapsed, clock: clock, now: context.date)
                    if products.count > 1 { switcher }
                    VStack(spacing: 0) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                            let state = rowState(item, index: index, elapsed: elapsed)
                            let next = index + 1 < items.count ? rowState(items[index + 1], index: index + 1, elapsed: elapsed) : nil
                            Button { open = item } label: { row(item, state: state, next: next, isLast: index == items.count - 1) }
                                .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, DX.Space.xs)
                    if let text = timeline?.note(for: product) { note(text) }
                    sources(timeline)
                }
                .padding(.horizontal, DX.Space.m)
                .dxReadableColumn()
                .padding(.top, DX.Space.s)
                .padding(.bottom, DX.Space.xxl)
            }
        }
        .background(ground.background.ignoresSafeArea())
        .sheet(item: $open) { item in
            let elapsed = HealthTimeline.elapsedHours(quitDay: profile.quitDay, now: .now,
                                                      clock: DayClock(boundaryHour: profile.dayBoundaryHour))
            HealthItemDetail(item: item, elapsedHours: elapsed, source: HealthTimeline.bundled?.source(item.source))
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private var products: [Product] {
        profile.products.sorted { ($0.isPrimary ? 0 : 1) < ($1.isPrimary ? 0 : 1) }.map(\.product)
    }

    private func header(elapsed: Double, clock: DayClock, now: Date) -> some View {
        HStack(alignment: .center, spacing: DX.Space.xs) {
            VStack(alignment: .leading, spacing: 4) {
                Group {
                    if elapsed < 0 {
                        let days = clock.days(from: now, toDate: profile.quitDay)
                        if days == 1 { Text("Quit Day tomorrow") } else { Text("Quit Day in \(days) days") }
                    } else {
                        let day = clock.days(fromDate: profile.quitDay, to: now) + 1
                        Text("Day \(day) · \(now.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))")
                    }
                }
                .dxType(.footnote).foregroundStyle(ground.muted)
                MarkedTitle(String(localized: "What's"), marking: String(localized: "changing"),
                            color: DX.Mark.color(on: ground), stacked: true)
                    .dxType(.large).foregroundStyle(ground.ink)
            }
            Spacer(minLength: 0)
            PersonFigure(.cheer, height: 108, shirt: 0xFF7A55)
                .frame(width: 128, height: 128)
                .background(Color(light: (0xFFFFFF, 0.45), dark: (0xFFFFFF, 0.08)), in: Circle())
        }
        .overlay(alignment: .topTrailing) {
            if let onClose {
                Button(action: onClose) { Image(systemName: "xmark") }
                    .buttonStyle(.v4Icon).accessibilityLabel(Text("Close"))
            }
        }
    }

    private var switcher: some View {
        HStack(spacing: 0) {
            ForEach(products, id: \.self) { p in
                let on = p == product
                Button { product = p } label: {
                    Text(label(p))
                        .dxFont(14, weight: 700, style: .footnote)
                        .foregroundStyle(on ? DX.Ground.reading.background : ground.ink)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(on ? ground.ink : .clear, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? [.isButton, .isSelected] : .isButton)
            }
        }
        .padding(4)
        .background(Color(light: (0x1E1A3A, 0.08), dark: (0xFFFFFF, 0.08)), in: Capsule())
        .sensoryFeedback(DX.Haptic.select, trigger: product)
    }

    private func label(_ product: Product) -> LocalizedStringKey {
        switch product {
        case .cigarettes: "Smoking"
        case .vape: "Vaping"
        case .pouches: "Pouches"
        }
    }

    // MARK: Rows

    private enum RowState: Equatable { case done, now(Double), first, ahead }

    /// Before Quit Day the first change is raised as "From Quit Day"; after, the state from the timeline.
    private func rowState(_ item: HealthTimeline.Item, index: Int, elapsed: Double) -> RowState {
        if elapsed < 0 { return index == 0 ? .first : .ahead }
        switch HealthTimeline.state(of: item, elapsedHours: elapsed) {
        case .done: return .done
        case let .underWay(fraction): return .now(fraction)
        case .ahead: return .ahead
        }
    }

    private func row(_ item: HealthTimeline.Item, state: RowState, next: RowState?, isLast: Bool) -> some View {
        let raised: Bool = switch state {
        case .now, .first: true
        case .done, .ahead: false
        }
        let solid: Bool = {
            switch (state, next) {
            case (.done, .done?), (.done, .now?), (.now, .done?), (.now, .now?): return true
            default: return false
            }
        }()
        let kicker: String = switch state {
        case .now: String(localized: "Under way · \(item.when)")
        case .first: String(localized: "From Quit Day")
        default: item.when
        }
        return HStack(alignment: .top, spacing: 12) {
            ZStack(alignment: .top) {
                if !isLast {
                    Rectangle().fill(.clear).frame(width: 3)
                        .overlay {
                            if solid {
                                Rectangle().fill(DX.Fill.green)
                            } else {
                                Line().stroke(ground.ink, style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [1, 6]))
                            }
                        }
                        .padding(.top, 14)
                        .padding(.bottom, -14)
                }
                node(state).padding(.top, raised ? 30 : 10)
            }
            .frame(width: 26)
            .frame(maxHeight: .infinity, alignment: .top)
            .accessibilityHidden(true)

            HStack(spacing: 12) {
                KitArt(HealthArt.kind(for: item.id), cornerRadius: raised ? 18 : 14)
                    .frame(width: raised ? 64 : 48, height: raised ? 64 : 48)
                VStack(alignment: .leading, spacing: 3) {
                    Text(verbatim: kicker.uppercased()).dxType(.caption).foregroundStyle(raised ? coralInk : ground.muted)
                    Text(verbatim: item.title)
                        .dxFont(raised ? 18 : 16, weight: raised ? 800 : 700, style: raised ? .headline : .body)
                        .foregroundStyle(raised ? DX.Ground.reading.ink : ground.ink)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    if case let .now(fraction) = state {
                        GeometryReader { proxy in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color(light: 0xEDE6DA, dark: 0x2A4A3E))
                                Capsule().fill(Color(hex: 0xFF7A55)).frame(width: proxy.size.width * min(1, max(0, fraction)))
                            }
                        }
                        .frame(height: 8)
                        .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(raised ? 12 : 0)
            .background {
                if raised {
                    RoundedRectangle(cornerRadius: 20, style: .continuous).fill(card)
                        .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.bottom, 12)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "\(item.when). \(item.title)"))
        .accessibilityValue(Text(accessibilityValue(state)))
        .accessibilityHint(Text("Opens the full story"))
    }

    private func accessibilityValue(_ state: RowState) -> String {
        switch state {
        case .done: String(localized: "Done")
        case let .now(fraction): String(localized: "Under way, \(Int((fraction * 100).rounded())) percent")
        case .first: String(localized: "Starts on Quit Day")
        case .ahead: ""
        }
    }

    @ViewBuilder
    private func node(_ state: RowState) -> some View {
        switch state {
        case .done:
            Image(systemName: "checkmark").font(.system(size: 11, weight: .heavy)).foregroundStyle(DX.Ground.reading.background)
                .frame(width: 26, height: 26).background(DX.Fill.green, in: Circle())
        case .now, .first:
            Circle().fill(Color(hex: 0xFF7A55)).frame(width: 26, height: 26)
                .background(Circle().fill(Color(hex: 0xFF7A55).opacity(0.25)).padding(-6))
        case .ahead:
            Circle().strokeBorder(ground.ink, lineWidth: 3).background(Circle().fill(ground.background)).frame(width: 26, height: 26)
        }
    }

    /// Sources once, small, under the timeline.
    @ViewBuilder
    private func sources(_ timeline: HealthTimeline?) -> some View {
        let list = timeline?.sources(for: product) ?? []
        let looks = timeline?.items(for: product).contains(where: \.isLooks) ?? false
        VStack(alignment: .leading, spacing: 4) {
            ForEach(list, id: \.url) { source in
                Link(destination: source.url) {
                    Text(verbatim: looks ? String(localized: "\(source.label) (health changes)") : source.label)
                        .dxFont(12, weight: 600, style: .caption1).underline().foregroundStyle(ground.ink)
                        .multilineTextAlignment(.leading)
                }
            }
            Text("General information, not medical advice. Everyone's body moves at its own pace.")
                .dxFont(12, weight: 400, style: .caption1).foregroundStyle(ground.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, DX.Space.s)
    }

    private func note(_ text: String) -> some View {
        Text(verbatim: text)
            .dxType(.footnote).foregroundStyle(ground.muted)
            .padding(DX.Space.s)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(ground.muted, style: StrokeStyle(lineWidth: 1, dash: [4, 4])))
    }
}

/// A vertical line for the dotted rail.
private struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return p
    }
}

/// Each change's illustration from the kit (decision 31).
enum HealthArt {
    static func kind(for id: String) -> KitArt.Kind {
        switch id {
        case "heart-rate", "heart-disease": .heart
        case "carbon-monoxide", "nicotine-gone": .clouds
        case "taste": .berry
        case "fresh-breath", "mood": .sparkle
        case "circulation", "cravings-fade": .breath
        case "lips": .lips
        case "skin-glow": .dawn
        case "coughing", "lung-cancer": .lungs
        case "hair": .sprout
        case "even-tone": .flower
        case "heart-attack", "mouth-cancer": .shield
        case "withdrawal-start": .sea
        case "withdrawal-peak": .peak
        case "sleep": .night
        default: .dawn
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
            if case let .underWay(fraction) = state {
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
            .textCase(.uppercase)
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
        case .underWay: "Under way"
        case .ahead: "Ahead"
        }
    }
}

/// The full story of one change (S25): its illustration, where it's up to, a warm longer read, what you might notice,
/// what helps, and the source in small print at the bottom.
struct HealthItemDetail: View {
    let item: HealthTimeline.Item
    let elapsedHours: Double
    let source: HealthTimeline.Source?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let state = HealthTimeline.state(of: item, elapsedHours: elapsedHours)
        ScrollView {
            VStack(alignment: .leading, spacing: DX.Space.m) {
                hero(state)
                VStack(spacing: 6) {
                    Text(verbatim: eyebrow(state)).v4Text(.micro, color: state == .ahead ? Read4.muted : Read4.accent)
                    Text(verbatim: item.title).v4Text(.title).multilineTextAlignment(.center)
                    if let status = status(state) {
                        Text(verbatim: status).v4Text(.subtitle).multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
                ForEach(item.paragraphs, id: \.self) { paragraph in
                    Text(verbatim: paragraph)
                        .dxFont(16, weight: 400, style: .body).lineSpacing(5)
                        .foregroundStyle(Read4.ink.opacity(0.86))
                }
                if let notice = item.notice, !notice.isEmpty {
                    VStack(alignment: .leading, spacing: DX.Space.s) {
                        Text("What you might notice").v4Text(.micro)
                        ForEach(notice, id: \.self) { line in
                            HStack(spacing: DX.Space.s) {
                                Image(systemName: "sparkle").font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Read4.accent)
                                    .frame(width: 34, height: 34)
                                    .background(HealthBadge.tint(for: item.id), in: Circle())
                                    .accessibilityHidden(true)
                                Text(verbatim: line).dxFont(16, weight: 400, style: .body)
                                    .foregroundStyle(Read4.ink)
                            }
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
                if let helps = item.helps {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Help it along").v4Text(.micro, color: Read4.accent)
                        Text(verbatim: helps).dxFont(16, weight: 400, style: .body)
                            .foregroundStyle(Read4.ink)
                    }
                    .padding(DX.Space.m)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Read4.accentSoft, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .accessibilityElement(children: .combine)
                }
                footer
            }
            .padding(.horizontal, DX.Space.l)
            .dxReadableColumn()
            .padding(.bottom, DX.Space.l)
        }
        .background(Read4.background.ignoresSafeArea())
    }

    private func hero(_ state: HealthTimeline.State) -> some View {
        ZStack(alignment: .topTrailing) {
            HealthBadge(id: item.id, state: state, size: 150)
                .padding(.vertical, DX.Space.l)
                .frame(maxWidth: .infinity)
                .background(RadialGradient(colors: [HealthBadge.tint(for: item.id), .clear], center: .center,
                                           startRadius: 40, endRadius: 190))
            Button { dismiss() } label: { Image(systemName: "xmark") }
                .buttonStyle(.v4Icon).accessibilityLabel(Text("Close"))
                .padding(.top, DX.Space.s)
        }
    }

    private func eyebrow(_ state: HealthTimeline.State) -> String {
        switch state {
        case .done: String(localized: "Reached · \(item.when)")
        case .underWay: String(localized: "Happening now · \(item.when)")
        case .ahead: String(localized: "Ahead · \(item.when)")
        }
    }

    private func status(_ state: HealthTimeline.State) -> String? {
        switch state {
        case let .underWay(fraction):
            String(localized: "\(Int((fraction * 100).rounded()))% of the way · done \(TodayView.relative(hours: item.toHours - elapsedHours))")
        case .ahead where elapsedHours >= 0:
            String(localized: "Starts \(TodayView.relative(hours: item.fromHours - elapsedHours))")
        case .ahead:
            String(localized: "Counts from Quit Day")
        case .done:
            nil
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let source {
                Link(destination: source.url) {
                    Text(verbatim: source.title).dxFont(12, weight: 400, style: .caption1)
                        .underline().foregroundStyle(Read4.accent).multilineTextAlignment(.leading)
                }
            } else if item.isLooks {
                Text("General wellness information.").dxFont(12, weight: 400, style: .caption1)
                    .foregroundStyle(Read4.muted)
            }
            Text("Everyone's body moves at its own pace, and a slip doesn't undo what's already healed. Not medical advice.")
                .dxFont(12, weight: 400, style: .caption1).foregroundStyle(Read4.muted)
        }
        .padding(.top, DX.Space.xs)
    }
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
