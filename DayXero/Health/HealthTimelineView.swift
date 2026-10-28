import DayXeroCore
import SwiftUI

/// "Your body" (S10.1, S10.2): what changes after stopping, counted from Quit Day, one timeline per product.
/// Laid out as the signed-off timeline path (S21.7): the change happening now (or, before Quit Day, the first one)
/// featured on top, then every change as a stop on a path whose line turns solid as you reach it.
struct HealthTimelineView: View {
    let profile: UserProfile
    var onClose: (() -> Void)?

    @State private var product: Product
    @State private var open: HealthTimeline.Item?

    init(profile: UserProfile, onClose: (() -> Void)? = nil) {
        self.profile = profile
        self.onClose = onClose
        _product = State(initialValue: profile.primaryProduct?.product ?? .cigarettes)
    }

    var body: some View {
        TimelineView(.everyMinute) { context in
            let clock = DayClock(boundaryHour: profile.dayBoundaryHour)
            let elapsed = HealthTimeline.elapsedHours(quitDay: profile.quitDay, now: context.date, clock: clock)
            let timeline = HealthTimeline.bundled
            ScrollView {
                VStack(alignment: .leading, spacing: DX.Space.xs) {
                    header(elapsed: elapsed, clock: clock, now: context.date)
                    if products.count > 1 { switcher }
                    let items = timeline?.items(for: product) ?? []
                    let (current, next) = HealthTimeline.nowAndNext(items, elapsedHours: elapsed)
                    if let featured = current ?? next ?? items.last {
                        featuredCard(featured, elapsed: elapsed)
                            .padding(.bottom, DX.Space.xs)
                    }
                    // Before Quit Day the first change is the featured one, so the path starts at the second.
                    let path = elapsed < 0 ? Array(items.dropFirst()) : items
                    VStack(spacing: 0) {
                        ForEach(Array(path.enumerated()), id: \.element.id) { index, item in
                            Button { open = item } label: {
                                HealthPathStop(item: item, state: HealthTimeline.state(of: item, elapsedHours: elapsed),
                                               source: timeline?.source(item.source), isLast: index == path.count - 1)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    if let text = timeline?.note(for: product) { note(text) }
                }
                .padding(.horizontal, DX.Space.m)
                .dxReadableColumn()
                .padding(.top, DX.Space.s)
                .padding(.bottom, DX.Space.xxl)
            }
        }
        .dxCanvas()
        .sheet(item: $open) { item in
            HealthItemDetail(item: item, source: HealthTimeline.bundled?.source(item.source))
                .presentationDetents([.medium, .large])
        }
    }

    private var products: [Product] {
        profile.products.sorted { ($0.isPrimary ? 0 : 1) < ($1.isPrimary ? 0 : 1) }.map(\.product)
    }

    private func header(elapsed: Double, clock: DayClock, now: Date) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                if elapsed < 0 {
                    let days = clock.days(from: now, toDate: profile.quitDay)
                    Text("Quit Day in \(days) days").dxText(.micro)
                } else {
                    let day = clock.days(fromDate: profile.quitDay, to: now) + 1
                    Text("Day \(day) · since \(profile.quitDay.formatted(.dateTime.weekday(.abbreviated).day().month()))").dxText(.micro)
                }
                Text("Your body").dxText(.title).accessibilityAddTraits(.isHeader)
            }
            Spacer()
            if let onClose {
                Button(action: onClose) { Image(systemName: "xmark") }
                    .buttonStyle(.dxIcon).accessibilityLabel(Text("Close"))
            }
        }
        .padding(.bottom, DX.Space.xxs)
    }

    /// The change happening now, with how far it's got; before Quit Day, the first change and when it starts.
    private func featuredCard(_ item: HealthTimeline.Item, elapsed: Double) -> some View {
        let before = elapsed < 0
        let state = HealthTimeline.state(of: item, elapsedHours: elapsed)
        let eyebrow: String = if before {
            String(localized: "First · \(item.when)")
        } else {
            switch state {
            case .underWay: String(localized: "Happening now · \(item.when)")
            case .ahead: String(localized: "Next · \(TodayView.relative(hours: item.fromHours - elapsed))")
            case .done: String(localized: "Reached · \(item.when)")
            }
        }
        return Button { open = item } label: {
            HStack(spacing: DX.Space.m) {
                HealthBadge(id: item.id, state: before ? .underWay(0) : state, size: 80, showsRing: !before)
                    .padding(8)
                    .background(DX.Palette.surface1, in: Circle())
                    .padding(before ? 0 : 6)
                VStack(alignment: .leading, spacing: 4) {
                    Text(verbatim: eyebrow).dxText(.micro, color: DX.Palette.accentInk)
                    Text(verbatim: item.title)
                        .font(.custom(DX.Typeface.semibold, size: 18, relativeTo: .headline)).foregroundStyle(DX.Palette.text)
                        .multilineTextAlignment(.leading)
                    if before {
                        Text("Your timeline starts on Quit Day, \(profile.quitDay.formatted(.dateTime.weekday(.abbreviated).day().month())).")
                            .dxText(.subtitle).multilineTextAlignment(.leading)
                    } else if case let .underWay(fraction) = state {
                        DXProgressBar(value: fraction).padding(.top, 4)
                        Text("\(Int((fraction * 100).rounded()))% · done \(TodayView.relative(hours: item.toHours - elapsed))")
                            .dxText(.subtitle)
                    } else if !item.line.isEmpty {
                        Text(verbatim: item.line).dxText(.subtitle).multilineTextAlignment(.leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(DX.Space.m)
            .background(LinearGradient(colors: [DX.Palette.accentSoft, DX.Palette.surface1], startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(DX.Palette.hairline))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint(Text("Opens the detail and its source"))
    }

    private var switcher: some View {
        HStack(spacing: 0) {
            ForEach(products, id: \.self) { p in
                let on = p == product
                Button { product = p } label: {
                    Text(label(p))
                        .font(.custom(DX.Typeface.semibold, size: 12, relativeTo: .caption))
                        .foregroundStyle(on ? DX.Palette.onPrimary : DX.Palette.text2)
                        .padding(.vertical, 6).padding(.horizontal, 14)
                        .background(on ? DX.Palette.primary : .clear, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(3)
        .background(DX.Palette.surface2, in: Capsule())
        .padding(.bottom, DX.Space.xs)
        .sensoryFeedback(DX.Haptic.select, trigger: product)
    }

    private func label(_ product: Product) -> LocalizedStringKey {
        switch product {
        case .cigarettes: "Smoking"
        case .vape: "Vaping"
        case .pouches: "Pouches"
        }
    }

    private func note(_ text: String) -> some View {
        Text(verbatim: text)
            .dxText(.subtitle)
            .padding(DX.Space.s)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(DX.Palette.faint, style: StrokeStyle(lineWidth: 1, dash: [4, 4])))
            .padding(.vertical, DX.Space.xxs)
    }
}

/// One stop on the path: the change's illustration on the line, and its card. The line above a stop is solid once
/// the change has started; below it, once it's done.
struct HealthPathStop: View {
    let item: HealthTimeline.Item
    let state: HealthTimeline.State
    let source: HealthTimeline.Source?
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
            HealthItemCard(item: item, state: state, source: source)
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
        .stroke(solid ? DX.Palette.sage : DX.Palette.faint,
                style: StrokeStyle(lineWidth: solid ? 3 : 2.5, lineCap: .round, dash: solid ? [] : [0.5, 7]))
    }
}

/// One change, as a stadium card: done, under way (with a bar), or ahead.
struct HealthItemCard: View {
    let item: HealthTimeline.Item
    let state: HealthTimeline.State
    let source: HealthTimeline.Source?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .center) {
                Text(verbatim: item.when).dxText(.micro)
                Spacer(minLength: DX.Space.xs)
                badge
            }
            Text(verbatim: item.title).font(.custom(DX.Typeface.semibold, size: 15, relativeTo: .body)).foregroundStyle(DX.Palette.text)
                .multilineTextAlignment(.leading)
            if !item.line.isEmpty {
                Text(verbatim: item.line).dxText(.subtitle).multilineTextAlignment(.leading)
            }
            if case let .underWay(fraction) = state {
                DXProgressBar(value: fraction).padding(.top, 4)
            }
            if let source {
                Text(verbatim: source.label).font(DX.TextStyle.subtitle.font).underline().foregroundStyle(DX.Palette.accentInk)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, DX.Space.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous)
            .strokeBorder(state == .done ? DX.Palette.sage.opacity(0.45) : DX.Palette.hairline))
        .opacity(state == .ahead ? 0.62 : 1)
        .accessibilityElement(children: .combine)
        .accessibilityValue(Text(stateText))
        .accessibilityHint(Text("Opens the detail and its source"))
    }

    private var badge: some View {
        Text(stateText)
            .font(.custom(DX.Typeface.bold, size: 10, relativeTo: .caption2))
            .tracking(0.6)
            .textCase(.uppercase)
            .lineLimit(1)
            .foregroundStyle(state == .done ? DX.Palette.onAccent : isUnderWay ? DX.Palette.onPrimary : DX.Palette.muted)
            .padding(.vertical, 3).padding(.horizontal, 8)
            .background(state == .done ? DX.Palette.sage : isUnderWay ? DX.Palette.primary : DX.Palette.track, in: Capsule())
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

/// The claim in a little more depth, the source in full, and the disclaimer on every item (S10.2).
struct HealthItemDetail: View {
    let item: HealthTimeline.Item
    let source: HealthTimeline.Source?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DX.Space.s) {
                Text(verbatim: item.when).dxText(.micro).padding(.top, DX.Space.l)
                Text(verbatim: item.title).dxText(.title)
                Text(verbatim: item.detail).font(DX.TextStyle.body.font).foregroundStyle(DX.Palette.text2)
                if let source {
                    DXCard(padding: 14) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Source").dxText(.subtitle)
                            Text(verbatim: source.title).font(DX.TextStyle.subtitle.font).foregroundStyle(DX.Palette.text)
                            Link(destination: source.url) {
                                Text("Open \(source.url.host()?.replacingOccurrences(of: "www.", with: "") ?? "source")")
                                    .font(DX.TextStyle.subtitle.font).underline().foregroundStyle(DX.Palette.accentInk)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                Text("These changes assume you've stayed smoke-free; a slip doesn't undo your progress. Health information, not medical advice. Everyone's body is different.")
                    .dxText(.subtitle)
            }
            .padding(.horizontal, DX.Space.m)
            .dxReadableColumn()
            .padding(.bottom, DX.Space.l)
        }
        .dxCanvas()
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
                        .font(.custom(DX.Typeface.semibold, size: 15, relativeTo: .body)).foregroundStyle(DX.Palette.text)
                        .multilineTextAlignment(.leading)
                    if elapsed < 0 {
                        Text("What changes in your body, from Quit Day").dxText(.subtitle)
                    } else if let next {
                        Text("\(done) done · next: \(next.title.prefix(1).lowercased() + String(next.title.dropFirst()))").dxText(.subtitle)
                            .multilineTextAlignment(.leading)
                    } else {
                        Text("\(done) done").dxText(.subtitle)
                    }
                }
                Spacer(minLength: DX.Space.xs)
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(DX.Palette.muted)
            }
            .padding(14)
            .background(DX.Palette.surface1, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(DX.Palette.hairline))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}
