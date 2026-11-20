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
        /// A slip already logged elsewhere (Today's use buttons, Siri, the widget): opens Jelli's if-then planner for the
        /// latest slip that has no plan yet (CLIN-10).
        case slipPlan
        var id: Self { self }
    }

    var page: Page?
    /// What opens once the menu sheet has gone (v5): the menu is a sheet over Today, the forms are full screen.
    var pending: Page?

    func open(_ page: Page = .menu) {
        self.page = page
    }

    /// From the menu to a form: the sheet goes down, then the form comes up full screen.
    func push(_ next: Page) {
        pending = next
        page = nil
    }

    /// The menu sheet's binding.
    var menuShown: Bool {
        get { page == .menu }
        set { if !newValue, page == .menu { page = nil } }
    }

    /// The full-screen form's binding.
    var form: Page? {
        get { page == .menu ? nil : page }
        set { page = newValue }
    }

    /// After the menu sheet is dismissed.
    func menuDismissed() {
        guard let next = pending else { return }
        pending = nil
        page = next
    }
}

/// One sheet for every log: a craving, or a one-tap use per product (S7.1, S7.2).
struct LogSheet: View {
    let profile: UserProfile?
    let start: LogRouter.Page
    /// From the menu to a form (the router takes the sheet down first).
    var onPush: ((LogRouter.Page) -> Void)?
    let onClose: () -> Void

    @Environment(\.modelContext) private var context
    @Environment(SOSRouter.self) private var sos
    @Environment(\.colorScheme) private var scheme
    @State private var path: [LogRouter.Page] = []
    @State private var slip: LogEntry?
    /// The slip logged when the sheet opens straight to one (the widget's "Slipped? Log it").
    @State private var startSlip: LogEntry?
    @State private var logged = false
    @Query(filter: #Predicate<LogEntry> { $0.kindRaw != "craving" }) private var uses: [LogEntry]
    @Query(filter: #Predicate<LogEntry> { $0.kindRaw == "craving" }) private var cravings: [LogEntry]

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
    }

    /// What the sheet opens on. A craving or a slip opened from a widget, Siri or a link is the sheet's first page,
    /// not a push: pushing while the sheet was still presenting left the page blank (S18.18).
    @ViewBuilder
    private var root: some View {
        switch start {
        case .menu: menu
        case .craving: cravingForm
        case .slipPlan:
            if let entry = unplannedSlip {
                slipFlow(entry)
            } else {
                // Already planned, or too long ago: nothing to open.
                Color.clear.background(Read4.background.ignoresSafeArea()).onAppear(perform: onClose)
            }
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

    private var cravingForm: some View {
        CravingLogForm(profile: profile, onSaved: onClose, onClose: onClose, onSOS: {
            onClose()
            sos.open(source: "log")
        })
    }

    private func slipFlow(_ entry: LogEntry) -> some View {
        SlipFlow(entry: entry, profile: profile, onDone: onClose)
            .navigationBarBackButtonHidden()
            .toolbar(.hidden, for: .navigationBar)
    }

    /// v5 (041): "Log" and today's date; a craving with Jelli, then "Used nicotine?" with a quieter row per product,
    /// each ending in the same tonal plus; then the slip note.
    private var menu: some View {
        let ground = DX.Ground.reading
        return ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Log").dxType(.title).foregroundStyle(ground.ink).accessibilityAddTraits(.isHeader)
                    Spacer()
                    Text(verbatim: todayLabel).dxType(.footnote).foregroundStyle(ground.muted)
                }
                .padding(.bottom, 14)
                Button { open(.craving) } label: {
                    HStack(spacing: 14) {
                        JelliView(mood: .calm, stage: 1, points: 58)
                            .frame(width: 58, height: 58)
                            .padding(EdgeInsets(top: -4, leading: -4, bottom: -4, trailing: 0))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("A craving").dxFace(.display, 17, weight: 700, tracking: -0.2).foregroundStyle(ground.ink)
                            Text(verbatim: cravingLine).dxType(.footnote).foregroundStyle(ground.muted)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        AddDisc()
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .frame(minHeight: 78)
                    .background((scheme == .dark ? Color(hex: 0x1F2942) : ground.card), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(ground.line, lineWidth: 1))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.dxPress)
                .accessibilityLabel(Text("Log a craving"))
                .dxArrive(3, delay: 0)
                if !products.isEmpty {
                    Text("Used nicotine?").dxType(.headline).foregroundStyle(ground.ink)
                        .padding(.top, 22).padding(.bottom, 12)
                        .accessibilityAddTraits(.isHeader)
                        .dxArrive(4, delay: 0)
                    VStack(spacing: 0) {
                        ForEach(Array(products.enumerated()), id: \.element) { i, product in
                            Button { logUse(product) } label: {
                                HStack(spacing: 12) {
                                    PaperUseObject(product: product).frame(width: 34, height: 34)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(LogSheet.useTitle(product)).dxFont(16, weight: 600, style: .body).foregroundStyle(ground.ink)
                                        Text(verbatim: countLine(product)).dxFont(13, weight: 500, style: .caption1).foregroundStyle(ground.muted)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    AddDisc()
                                }
                                .padding(.horizontal, 16).padding(.vertical, 6)
                                .frame(minHeight: 56)
                                .overlay(alignment: .top) { if i > 0 { Rectangle().fill(ground.line).frame(height: 1) } }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.dxPress)
                            .accessibilityHint(Text(isSlip ? "Logs a slip. Nothing resets." : "Logs one now"))
                            // Home's prep rows share the name, so UI tests find the sheet's by this.
                            .accessibilityIdentifier("log.use.\(product.rawValue)")
                        }
                    }
                    .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(ground.line, lineWidth: 1))
                    .dxArrive(5, delay: 0)
                }
                if isSlip {
                    Text("A use after Day Xero is logged as a slip. Nothing resets.")
                        .dxType(.footnote).foregroundStyle(ground.muted)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 18)
                        .dxArrive(7, delay: 0)
                }
            }
            .padding(.top, 26).padding(.bottom, DX.Space.m).padding(.horizontal, DX.Layout.gutter)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background((scheme == .dark ? Color(hex: 0x172036) : ground.background).ignoresSafeArea())
        .dxGround(.reading, paint: false)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var todayLabel: String {
        String(localized: "Today, \(Date.now.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))")
    }

    /// "3 today, all ridden out", "1 today", or what the form asks.
    private var cravingLine: String {
        let clock = DayClock(boundaryHour: profile?.dayBoundaryHour ?? 4)
        let today = clock.day(containing: .now)
        let mine = cravings.filter { clock.day(containing: $0.timestamp) == today }
        guard !mine.isEmpty else { return String(localized: "How strong, what set it off") }
        let ridden = mine.filter { $0.outcome == .passed }.count
        if ridden == mine.count { return String(localized: "\(mine.count) today, all ridden out") }
        return String(localized: "\(mine.count) today")
    }

    private func countLine(_ product: Product) -> String {
        let n = todayCount(product)
        return n == 0 ? String(localized: "None logged today") : String(localized: "\(n) logged today")
    }

    private func open(_ page: LogRouter.Page) {
        if let onPush { onPush(page) } else { path.append(page) }
    }

    private var products: [Product] {
        (profile?.products ?? []).sorted { ($0.isPrimary ? 0 : 1) < ($1.isPrimary ? 0 : 1) }.map(\.product)
    }

    private var isSlip: Bool { UseLog.isSlip(profile: profile) }

    /// The latest slip with no plan for next time, from the last `SlipPlanRequest.window`.
    private var unplannedSlip: LogEntry? {
        uses.filter { $0.kind == .slip && $0.nextTime == nil && Date.now.timeIntervalSince($0.timestamp) < SlipPlanRequest.window }
            .max { $0.timestamp < $1.timestamp }
    }

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
            if let onPush { onPush(.slipPlan) } else { slip = entry }
        } else {
            onClose()
            NotificationCenter.default.post(name: .dxUseLogged, object: nil)
        }
    }

    static func useTitle(_ product: Product) -> LocalizedStringKey {
        switch product {
        case .cigarettes: "Cigarette"
        case .vape: "Puff"
        case .pouches: "Pouch"
        }
    }
}

/// The tonal plus every log row ends in (041): 44 pt, ink at 8% with a soft ring.
private struct AddDisc: View {
    var body: some View {
        let ink = DX.Ground.reading.ink
        DXIcon(.plus, size: 20)
            .foregroundStyle(ink)
            .frame(width: 44, height: 44)
            .background(ink.opacity(0.08), in: Circle())
            .overlay(Circle().strokeBorder(ink.opacity(0.18), lineWidth: 1.5))
            .accessibilityHidden(true)
    }
}

/// Log a craving without starting a session (v5, 042). Also used to add details to a logged use.
struct CravingLogForm: View {
    let profile: UserProfile?
    /// Adds details to this entry instead of logging a new craving.
    var editing: LogEntry?
    let onSaved: () -> Void
    var onClose: (() -> Void)?
    var onSOS: (() -> Void)?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(filter: #Predicate<LogEntry> { $0.kindRaw == "craving" }) private var cravings: [LogEntry]
    @State private var strength = 5
    @State private var trigger: Trigger?
    @State private var mood: CheckInMood?
    @State private var note = ""
    @State private var showAllTriggers = false
    @State private var saved = false
    @State private var savedCount = 0
    @FocusState private var noteFocused: Bool
    private let openedAt = Date.now
    private let ground = DX.Ground.reading

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                DXIconButton(.close, label: "Close") { if let onClose { onClose() } else { dismiss() } }
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 12) {
                        JelliView(mood: .calm, stage: 1, points: 64)
                            .frame(width: 64, height: 64)
                            .dxSettle(delay: 0.12)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(editing == nil ? LocalizedStringKey("A craving") : LocalizedStringKey("Add details"))
                                .dxType(.title).foregroundStyle(ground.ink)
                                .accessibilityAddTraits(.isHeader)
                                .dxArrive(0, delay: 0)
                            // Adding details shows when the use was logged, not when this form opened.
                            Text(verbatim: whenLabel).dxType(.footnote).foregroundStyle(ground.muted)
                                .dxArrive(1, delay: 0)
                        }
                    }
                    if editing == nil || editing?.kind == .craving {
                        VStack(alignment: .leading, spacing: 0) {
                            CravingStrengthSlider(value: $strength)
                            if let onSOS {
                                Button(action: onSOS) {
                                    HStack(spacing: 8) {
                                        DXIcon(.wave, size: 16, weight: 2.4).foregroundStyle(Color(hex: 0xFFF8EE))
                                            .frame(width: 26, height: 26)
                                            .background(Color(hex: 0x1F3C8C), in: Circle())
                                        Text("Too strong?").dxFont(15, weight: 500, style: .subheadline).foregroundStyle(ground.muted)
                                        Text("Ride it out with SOS").dxFont(15, weight: 700, style: .subheadline).foregroundStyle(ground.ink)
                                        DXIcon(.chev, size: 16, weight: 2.4).foregroundStyle(ground.muted)
                                    }
                                    .frame(minHeight: 44)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .padding(.top, 4)
                            }
                        }
                        .padding(.top, 18)
                        .dxArrive(2, delay: 0)
                    }
                    section("What set it off?") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                            ForEach(shownTriggers, id: \.self) { t in triggerChip(t) }
                        }
                    }
                    .dxArrive(3, delay: 0)
                    section("Mood", trailing: String(localized: "Optional")) {
                        HStack(spacing: 8) {
                            ForEach(CheckInMood.allCases, id: \.self) { m in moodButton(m) }
                        }
                    }
                    .dxArrive(4, delay: 0)
                    noteField
                        .padding(.top, 24)
                        .dxArrive(5, delay: 0)
                }
                .padding(.horizontal, DX.Layout.gutter)
                .padding(.top, 0).padding(.bottom, DX.Space.m)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.interactively)
            saveButton
                .padding(.horizontal, DX.Layout.buttonGutter)
                .padding(.bottom, DX.Space.xs)
                .dxArrive(6, delay: 0)
        }
        .dxReadableColumn()
        .background(ground.background.ignoresSafeArea())
        .dxGround(.reading, paint: false)
        .toolbar(.hidden, for: .navigationBar)
        .sensoryFeedback(DX.Haptic.commit, trigger: saved)
        .onAppear {
            guard let editing else { return }
            trigger = editing.trigger
            mood = editing.mood.map(Self.face)
            note = editing.note ?? ""
            if let i = editing.intensity { strength = i }
        }
    }

    private var whenLabel: String {
        let date = editing?.timestamp ?? openedAt
        let time = date.formatted(date: .omitted, time: .shortened)
        if Calendar.current.isDateInToday(date) { return String(localized: "Today, \(time)") }
        return date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute())
    }

    private func section(_ title: LocalizedStringKey, trailing: String? = nil, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).dxType(.headline).foregroundStyle(ground.ink).accessibilityAddTraits(.isHeader)
                Spacer()
                if let trailing { Text(verbatim: trailing).dxType(.footnote).foregroundStyle(ground.muted) }
            }
            content()
        }
        .padding(.top, 24)
    }

    /// Five triggers (yours first) and Other; Other opens the rest.
    private var shownTriggers: [Trigger] {
        let mine = profile?.triggers ?? []
        var first: [Trigger] = []
        for t in mine + [.coffee, .stress, .morning, .meals, .driving] where t != .other && !first.contains(t) { first.append(t) }
        let head = Array(first.prefix(5))
        if showAllTriggers {
            return head + Trigger.allCases.filter { !head.contains($0) && $0 != .other } + [.other]
        }
        if let trigger, !head.contains(trigger), trigger != .other { return head + [trigger, .other] }
        return head + [.other]
    }

    private func triggerChip(_ t: Trigger) -> some View {
        let on = trigger == t
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        return Button {
            if t == .other, !showAllTriggers {
                withAnimation(DX.Move.settle) { showAllTriggers = true }
            }
            trigger = on ? nil : t
        } label: {
            Text(t == .other ? LocalizedStringResource("Other") : t.title)
                .dxFont(15, weight: 600, style: .subheadline).foregroundStyle(ground.ink)
                .lineLimit(2).minimumScaleFactor(0.8).multilineTextAlignment(.center)
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity, minHeight: 46)
                .background(on ? ground.selTint : ground.card, in: shape)
                .overlay(shape.strokeBorder(on ? ground.selEdge : ground.line, lineWidth: on ? 2 : 1))
                .contentShape(shape)
        }
        .buttonStyle(.dxPress)
        .sensoryFeedback(DX.Haptic.select, trigger: on)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private func moodButton(_ m: CheckInMood) -> some View {
        let on = mood == m
        let shape = RoundedRectangle(cornerRadius: 20, style: .continuous)
        return Button { mood = on ? nil : m } label: {
            VStack(spacing: 7) {
                MoodMoon(mood: m).frame(width: 35, height: 35)
                Text(verbatim: m.label).dxFont(15, weight: 600, style: .subheadline).foregroundStyle(ground.ink)
                    .lineLimit(1).minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(on ? ground.selTint : ground.card, in: shape)
            .overlay(shape.strokeBorder(on ? ground.selEdge : ground.line, lineWidth: on ? 2 : 1))
            .contentShape(shape)
        }
        .buttonStyle(.dxPress)
        .sensoryFeedback(DX.Haptic.select, trigger: on)
        .accessibilityLabel(Text(verbatim: m.label))
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private var noteField: some View {
        HStack(alignment: .top, spacing: 10) {
            DXIcon(.note, size: 18).foregroundStyle(ground.muted).padding(.top, 3)
            TextField(String(localized: "Add a note, if it helps"), text: $note, axis: .vertical)
                .dxType(.body)
                .foregroundStyle(ground.ink)
                .lineLimit(2...6)
                .focused($noteFocused)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .frame(maxWidth: .infinity, minHeight: 80, alignment: .topLeading)
        .background(ground.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(ground.ink.opacity(0.16), lineWidth: 1))
        .contentShape(Rectangle())
        .onTapGesture { noteFocused = true }
    }

    /// Save rests until tapped, then turns into its done state: "✓ Saved · 4 today", and the form closes after 1.2 s.
    private var saveButton: some View {
        Button(action: save) {
            HStack(spacing: 8) {
                if saved {
                    DXIcon(.check, size: 20, weight: 3)
                    Text("Saved · \(Text(verbatim: "\(savedCount)").contentTransition(.numericText())) today")
                } else {
                    Text("Save")
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.dx(.primary, on: .reading))
        .disabled(saved)
        .animation(DX.Move.settle, value: saved)
    }

    private static func face(_ mood: Mood) -> CheckInMood {
        switch mood {
        case .low, .meh: .rough
        case .okay: .okay
        case .good: .good
        case .great: .proud
        }
    }

    private static func stored(_ mood: CheckInMood) -> Mood {
        switch mood {
        case .rough: .low
        case .okay: .okay
        case .good: .good
        case .proud: .great
        }
    }

    private func save() {
        let entry = editing ?? {
            let new = LogEntry(kind: .craving, timestamp: openedAt)
            context.insert(new)
            return new
        }()
        if entry.kind == .craving { entry.intensity = strength }
        entry.triggerRaw = trigger?.rawValue
        entry.mood = mood.map(Self.stored)
        entry.note = note.isEmpty ? nil : note
        try? context.save()
        let clock = DayClock(boundaryHour: profile?.dayBoundaryHour ?? 4)
        let today = clock.day(containing: .now)
        savedCount = cravings.filter { clock.day(containing: $0.timestamp) == today }.count
        saved = true
        Task {
            try? await Task.sleep(for: .milliseconds(1200))
            onSaved()
        }
    }
}
