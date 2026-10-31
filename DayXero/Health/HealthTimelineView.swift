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
                                               isLast: index == path.count - 1)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    if let text = timeline?.note(for: product) { note(text) }
                    sources(timeline)
                }
                .padding(.horizontal, DX.Space.m)
                .dxReadableColumn()
                .padding(.top, DX.Space.s)
                .padding(.bottom, DX.Space.xxl)
            }
        }
        .background(Read4.background.ignoresSafeArea())
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
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                if elapsed < 0 {
                    let days = clock.days(from: now, toDate: profile.quitDay)
                    Text("Quit Day in \(days) days").v4Text(.micro)
                } else {
                    let day = clock.days(fromDate: profile.quitDay, to: now) + 1
                    Text("Day \(day) · since \(profile.quitDay.formatted(.dateTime.weekday(.abbreviated).day().month()))").v4Text(.micro)
                }
                Text("Your body").v4Text(.title).accessibilityAddTraits(.isHeader)
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
                    .background(Read4.card, in: Circle())
                    .padding(before ? 0 : 6)
                VStack(alignment: .leading, spacing: 4) {
                    Text(verbatim: eyebrow).v4Text(.micro, color: Read4.accent)
                    Text(verbatim: item.title)
                        .dxFont(19, weight: 600, style: .headline).foregroundStyle(Read4.ink)
                        .multilineTextAlignment(.leading)
                    if before {
                        Text("Your timeline starts on Quit Day, \(profile.quitDay.formatted(.dateTime.weekday(.abbreviated).day().month())).")
                            .v4Text(.subtitle).multilineTextAlignment(.leading)
                    } else if case let .underWay(fraction) = state {
                        V4ProgressBar(value: fraction).padding(.top, 4)
                        Text("\(Int((fraction * 100).rounded()))% · done \(TodayView.relative(hours: item.toHours - elapsed))")
                            .v4Text(.subtitle)
                    } else if !item.line.isEmpty {
                        Text(verbatim: item.line).v4Text(.subtitle).multilineTextAlignment(.leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(DX.Space.m)
            .background(LinearGradient(colors: [Read4.accentSoft, Read4.card], startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(Read4.hairline))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint(Text("Opens the full story"))
    }

    private var switcher: some View {
        HStack(spacing: 0) {
            ForEach(products, id: \.self) { p in
                let on = p == product
                Button { product = p } label: {
                    Text(label(p))
                        .dxFont(12, weight: 600, style: .caption1)
                        .foregroundStyle(on ? Read4.onInk : Read4.muted)
                        .padding(.vertical, 6).padding(.horizontal, 14)
                        .background(on ? Read4.ink : .clear, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(3)
        .background(Read4.surface, in: Capsule())
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

    /// Sources once, under the timeline, instead of on every card.
    @ViewBuilder
    private func sources(_ timeline: HealthTimeline?) -> some View {
        let list = timeline?.sources(for: product) ?? []
        let looks = timeline?.items(for: product).contains(where: \.isLooks) ?? false
        VStack(alignment: .leading, spacing: 6) {
            Text("Sources").v4Text(.micro)
            ForEach(list, id: \.url) { source in
                Link(destination: source.url) {
                    Text(verbatim: source.title).dxFont(12, weight: 400, style: .caption1)
                        .underline().foregroundStyle(Read4.accent).multilineTextAlignment(.leading)
                }
            }
            if looks {
                Text("Looks changes (lips, skin, hair, taste, breath, sleep) are general wellness information about how nicotine and smoke affect blood flow and skin.")
                    .dxFont(12, weight: 400, style: .caption1).foregroundStyle(Read4.muted)
            }
            Text("Everyone's body moves at its own pace, and a slip doesn't undo what's already healed. Not medical advice.")
                .dxFont(12, weight: 400, style: .caption1).foregroundStyle(Read4.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, DX.Space.m)
        .padding(.horizontal, DX.Space.xxs)
    }

    private func note(_ text: String) -> some View {
        Text(verbatim: text)
            .v4Text(.subtitle)
            .padding(DX.Space.s)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Read4.faint, style: StrokeStyle(lineWidth: 1, dash: [4, 4])))
            .padding(.vertical, DX.Space.xxs)
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
                .buttonStyle(.dxIcon).accessibilityLabel(Text("Close"))
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
