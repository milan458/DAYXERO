import DayXeroCore
import SwiftUI

/// "Your body" (S10.1, S10.2): what changes after stopping, counted from Quit Day, one timeline per product.
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
                    if elapsed < 0 {
                        note("Your timeline starts on Quit Day, \(profile.quitDay.formatted(.dateTime.weekday(.abbreviated).day().month())). Here's what's ahead.")
                    }
                    ForEach(timeline?.items(for: product) ?? []) { item in
                        Button { open = item } label: {
                            HealthItemCard(item: item, state: HealthTimeline.state(of: item, elapsedHours: elapsed),
                                           source: timeline?.source(item.source))
                        }
                        .buttonStyle(.plain)
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
                Image(systemName: "heart").font(.system(size: 17)).foregroundStyle(DX.Palette.accentInk)
                    .frame(width: 40, height: 40).background(DX.Palette.accentSoft, in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: (current ?? next ?? items.last)?.title ?? "")
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
