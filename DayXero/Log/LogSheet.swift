import DayXeroCore
import SwiftData
import SwiftUI

/// Opens the log sheet from Home, Progress, the widget and Siri (S7.1).
@Observable @MainActor
final class LogRouter {
    enum Page: Hashable, Identifiable {
        case menu, craving
        /// "Slipped? Log it" from the widget: logs a slip of the main product and opens the talk-through.
        case slip
        var id: Self { self }
    }

    var page: Page?
    /// The sheet's height. Set before the sheet opens, so a craving or a slip opens full height straight away
    /// instead of growing mid-presentation.
    var detent = PresentationDetent.medium

    func open(_ page: Page = .menu) {
        detent = page == .menu ? .medium : .large
        self.page = page
    }
}

/// One sheet for every log: a craving, or a one-tap use per product (S7.1, S7.2).
struct LogSheet: View {
    let profile: UserProfile?
    let start: LogRouter.Page
    @Binding var detent: PresentationDetent
    let onClose: () -> Void

    @Environment(\.modelContext) private var context
    @Environment(SOSRouter.self) private var sos
    @State private var path: [LogRouter.Page] = []
    @State private var slip: LogEntry?
    /// The slip logged when the sheet opens straight to one (the widget's "Slipped? Log it").
    @State private var startSlip: LogEntry?
    @State private var logged = false
    @Query(filter: #Predicate<LogEntry> { $0.kindRaw != "craving" }) private var uses: [LogEntry]

    var body: some View {
        NavigationStack(path: $path) {
            root
                .navigationDestination(for: LogRouter.Page.self) { _ in cravingForm }
                .navigationDestination(item: $slip) { entry in slipFlow(entry) }
        }
        .sensoryFeedback(DX.Haptic.commit, trigger: logged)
        .onAppear {
            if start == .slip, startSlip == nil, let product = products.first {
                startSlip = UseLog.log(product, in: context)
                Analytics.track(.slipLogged(source: "widget"))
            }
        }
        // The menu fits half the screen; the craving form and the slip screen get the full height.
        .onChange(of: path) { detent = fullHeight ? .large : .medium }
        .onChange(of: slip) { detent = fullHeight ? .large : .medium }
    }

    /// What the sheet opens on. A craving or a slip opened from a widget, Siri or a link is the sheet's first page,
    /// not a push: pushing while the sheet was still presenting left the page blank (S18.18).
    @ViewBuilder
    private var root: some View {
        switch start {
        case .menu: menu
        case .craving: cravingForm
        case .slip:
            if let startSlip {
                slipFlow(startSlip)
            } else if products.isEmpty {
                menu
            } else {
                // For the moment before the slip is saved on appear.
                Color.clear.background(Read4.background.ignoresSafeArea())
            }
        }
    }

    private var fullHeight: Bool { start != .menu || !path.isEmpty || slip != nil }

    private var cravingForm: some View {
        CravingLogForm(profile: profile, onSaved: onClose, onSOS: {
            onClose()
            sos.open(source: "log")
        })
    }

    private func slipFlow(_ entry: LogEntry) -> some View {
        SlipFlow(entry: entry, profile: profile, onDone: onClose)
            .navigationBarBackButtonHidden()
            .toolbar(.hidden, for: .navigationBar)
    }

    private var menu: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DX.Space.xs) {
                Text("Log").v4Text(.title).padding(.bottom, DX.Space.xs)
                NavigationLink(value: LogRouter.Page.craving) {
                    LogRow(title: "A craving", detail: "How strong, what set it off", systemImage: "flame", accent: true)
                }
                .buttonStyle(.plain)
                Text("I used").v4Text(.micro).padding(.top, DX.Space.s)
                ForEach(products, id: \.self) { product in
                    Button { logUse(product) } label: {
                        // How many today, rather than the product's name a second time (S18.10).
                        LogRow(title: LogSheet.useTitle(product), detail: "\(todayCount(product)) today",
                               systemImage: LogSheet.icon(product), accent: false)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(Text(isSlip ? "Logs a slip. Nothing resets." : "Logs one now"))
                    // Home's prep rows share the name, so UI tests find the sheet's by this.
                    .accessibilityIdentifier("log.use.\(product.rawValue)")
                }
                if isSlip {
                    Text("A use after Quit Day is logged as a slip. Nothing resets.")
                        .v4Text(.subtitle)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .padding(.top, DX.Space.xs)
                }
            }
            .padding(DX.Space.m)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(Read4.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var products: [Product] {
        (profile?.products ?? []).sorted { ($0.isPrimary ? 0 : 1) < ($1.isPrimary ? 0 : 1) }.map(\.product)
    }

    private var isSlip: Bool { UseLog.isSlip(profile: profile) }

    private func todayCount(_ product: Product) -> Int {
        let clock = DayClock(boundaryHour: profile?.dayBoundaryHour ?? 4)
        let today = clock.day(containing: .now)
        return uses.filter { $0.product == product && clock.day(containing: $0.timestamp) == today }.count
    }

    private func logUse(_ product: Product) {
        let entry = UseLog.log(product, in: context)
        logged.toggle()
        if entry.kind == .slip {
            Analytics.track(.slipLogged(source: "log"))
            slip = entry
        } else {
            onClose()
            NotificationCenter.default.post(name: .dxUseLogged, object: nil)
        }
    }

    static func useTitle(_ product: Product) -> LocalizedStringKey {
        switch product {
        case .cigarettes: "Cigarette"
        case .vape: "Vaped"
        case .pouches: "Pouch"
        }
    }

    static func icon(_ product: Product) -> String {
        switch product {
        case .cigarettes: "smoke"
        case .vape: "wind"
        case .pouches: "circle.grid.2x1"
        }
    }
}

private struct LogRow: View {
    let title: LocalizedStringKey
    let detail: LocalizedStringKey
    let systemImage: String
    let accent: Bool

    var body: some View {
        HStack(spacing: DX.Space.s) {
            Image(systemName: systemImage)
                .font(.system(size: 18))
                .foregroundStyle(accent ? Read4.accent : Read4.ink)
                .frame(width: 42, height: 42)
                .background(accent ? Read4.accentSoft : Read4.surface, in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text(title).dxFont(16, weight: 600, style: .body).foregroundStyle(Read4.ink)
                Text(detail).v4Text(.subtitle)
            }
            Spacer(minLength: DX.Space.xs)
            Image(systemName: "plus")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Read4.onInk)
                .frame(width: 40, height: 40)
                .background(Read4.ink, in: Circle())
        }
        .padding(.vertical, DX.Space.s)
        .padding(.horizontal, 14)
        .background(Read4.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Read4.hairline))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// Log a craving without starting a session (S7.2). Also used to add details to a logged use.
struct CravingLogForm: View {
    let profile: UserProfile?
    /// Adds details to this entry instead of logging a new craving.
    var editing: LogEntry?
    let onSaved: () -> Void
    var onSOS: (() -> Void)?

    @Environment(\.modelContext) private var context
    @State private var strength = 5
    @State private var trigger: Trigger?
    @State private var mood: Mood?
    @State private var place: Place?
    @State private var saved = false
    private let openedAt = Date.now

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: DX.Space.s) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(editing == nil ? LocalizedStringKey("A craving") : LocalizedStringKey("Add details")).v4Text(.title)
                        Text(verbatim: openedAt.formatted(.dateTime.weekday(.abbreviated).day().month().hour().minute()))
                            .v4Text(.subtitle)
                    }
                    if editing == nil || editing?.kind == .craving {
                        DXCravingSlider(value: $strength).frame(height: 110)
                    }
                    section("What set it off?") {
                        DXFlowLayout {
                            ForEach(orderedTriggers, id: \.self) { t in
                                V4SetChip(t.title, value: t, selection: single($trigger))
                            }
                        }
                    }
                    section("Mood", optional: true) {
                        HStack(spacing: 6) {
                            ForEach(Mood.allCases, id: \.self) { m in moodButton(m) }
                        }
                    }
                    section("Where?", optional: true) {
                        DXFlowLayout {
                            ForEach(Place.allCases, id: \.self) { p in
                                V4SetChip(p.title, value: p, selection: single($place))
                            }
                        }
                    }
                }
                .padding(DX.Space.m)
            }
            .scrollBounceBehavior(.basedOnSize)
            VStack(spacing: DX.Space.xxs) {
                Button("Save", action: save).buttonStyle(.dx(.primary, on: .reading))
                if let onSOS {
                    Button("Ride it out with SOS instead", action: onSOS).buttonStyle(.dx(.quiet, on: .reading))
                }
            }
            .padding(.horizontal, DX.Space.m)
            .dxReadableColumn()
            .padding(.bottom, DX.Space.xs)
        }
        .background(Read4.background.ignoresSafeArea())
        .sensoryFeedback(DX.Haptic.commit, trigger: saved)
        .onAppear {
            guard let editing else { return }
            trigger = editing.trigger
            mood = editing.mood
            place = editing.place
            if let i = editing.intensity { strength = i }
        }
    }

    private func section(_ title: LocalizedStringKey, optional: Bool = false, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: DX.Space.xs) {
            if optional {
                Text("\(Text(title)) \(Text("· optional").foregroundStyle(Read4.faint))").v4Text(.micro)
            } else {
                Text(title).v4Text(.micro)
            }
            content()
        }
        .padding(.top, DX.Space.xs)
    }

    private func moodButton(_ m: Mood) -> some View {
        let on = mood == m
        return Button { mood = on ? nil : m } label: {
            VStack(spacing: 4) {
                Circle().fill(on ? Read4.accent : Read4.track).frame(width: 22, height: 22)
                Text(m.title).dxFont(12, weight: 500, style: .caption2)
                    .foregroundStyle(on ? Read4.ink : Read4.muted)
                    .lineLimit(1).minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DX.Space.xs)
            .background(Read4.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(on ? Read4.accent : Read4.hairline, lineWidth: on ? 1.5 : 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(m.title))
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private var orderedTriggers: [Trigger] {
        let mine = profile?.triggers ?? []
        return mine + Trigger.allCases.filter { !mine.contains($0) }
    }

    private func single<T: Hashable>(_ value: Binding<T?>) -> Binding<Set<T>> {
        Binding(
            get: { value.wrappedValue.map { [$0] } ?? [] },
            set: { new in
                let old = value.wrappedValue
                value.wrappedValue = new.first { $0 != old } ?? (old.map(new.contains) == true ? old : nil)
            }
        )
    }

    private func save() {
        let entry = editing ?? {
            let new = LogEntry(kind: .craving, timestamp: openedAt)
            context.insert(new)
            return new
        }()
        if entry.kind == .craving { entry.intensity = strength }
        entry.triggerRaw = trigger?.rawValue
        entry.mood = mood
        entry.place = place
        try? context.save()
        saved.toggle()
        onSaved()
    }
}
