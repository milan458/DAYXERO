import DayXeroCore
import SwiftUI

// MARK: - Page

/// A settings page (v5, 062-070): the round back button, the large title with its quiet lead, then the page on the
/// reading ground. The page's own nav bar stays hidden; the dock, when there is one, sits over the bottom fade.
struct SettingsPage<Content: View, Dock: View>: View {
    let title: LocalizedStringKey
    let lead: Text?
    let leading: DX.Icon
    let onLeading: (() -> Void)?
    let content: Content
    let dock: Dock
    @Environment(\.dismiss) private var dismiss
    private let ground = DX.Ground.reading

    init(_ title: LocalizedStringKey, lead: Text? = nil, leading: DX.Icon = .back, onLeading: (() -> Void)? = nil,
         @ViewBuilder content: () -> Content, @ViewBuilder dock: () -> Dock) {
        self.title = title
        self.lead = lead
        self.leading = leading
        self.onLeading = onLeading
        self.content = content()
        self.dock = dock()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(title).dxType(.large).foregroundStyle(ground.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .dxArrive(0)
                if let lead {
                    lead.dxType(.footnote).foregroundStyle(ground.muted)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 6)
                        .dxArrive(1)
                }
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DX.Layout.gutter)
            .padding(.top, 6)
            .padding(.bottom, 28)
            .dxReadableColumn()
        }
        .scrollIndicators(.hidden)
        .safeAreaInset(edge: .top, spacing: 0) {
            HStack {
                DXIconButton(leading, label: leading == .close ? "Close" : "Back") {
                    if let onLeading { onLeading() } else { dismiss() }
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .padding(.top, 8)
            .background(ground.background.ignoresSafeArea(edges: .top))
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { dock }
        .background(ground.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .dxGround(.reading)
        .toggleStyle(.dx)
    }
}

extension SettingsPage where Dock == EmptyView {
    init(_ title: LocalizedStringKey, lead: Text? = nil, leading: DX.Icon = .back, onLeading: (() -> Void)? = nil,
         @ViewBuilder content: () -> Content) {
        self.init(title, lead: lead, leading: leading, onLeading: onLeading, content: content) { EmptyView() }
    }
}

// MARK: - Section label

/// A group's label (kit `.sec`): 14 pt semibold in the muted ink, an optional note on the right ("3 of 3 used").
struct SettingsSection: View {
    let title: LocalizedStringKey
    var trailing: Text?
    var top: CGFloat = 24
    var index = 0

    init(_ title: LocalizedStringKey, trailing: Text? = nil, top: CGFloat = 24, index: Int = 0) {
        self.title = title
        self.trailing = trailing
        self.top = top
        self.index = index
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).dxFont(14, weight: 600, style: .footnote)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 8)
            if let trailing { trailing.dxFont(13, weight: 600, style: .caption1).monospacedDigit() }
        }
        .foregroundStyle(DX.Ground.reading.muted)
        .padding(.horizontal, 4)
        .padding(.top, top)
        .padding(.bottom, 8)
        .dxArrive(index)
    }
}

// MARK: - Rows

/// The settings icon tile (061): 32 pt, radius 11, on card-2, the ink glyph at 19 pt.
struct SettingsTile: View {
    let d: String
    var size: CGFloat = 32

    var body: some View {
        DXIconShape(d: d)
            .stroke(DX.Ground.reading.ink, style: StrokeStyle(lineWidth: 2.2 * 19 / 24, lineCap: .round, lineJoin: .round))
            .frame(width: 19 * size / 32, height: 19 * size / 32)
            .frame(width: size, height: size)
            .background(DX.Ground.reading.card2, in: RoundedRectangle(cornerRadius: 11 * size / 32, style: .continuous))
            .accessibilityHidden(true)
    }
}

/// Glyphs the kit has no icon for, in its line style.
enum SettingsGlyph {
    static let help = "M12 21a9 9 0 100-18 9 9 0 000 18zM9.6 9.6a2.5 2.5 0 114.3 1.8c-.9.8-1.9 1.3-1.9 2.6M12 17v.1"
    static let info = "M12 21a9 9 0 100-18 9 9 0 000 18zM12 11v5.5M12 7.8v.1"
    static let mail = "M3.5 6h17v12h-17zM3.5 7l8.5 6 8.5-6"
    static let display = "M12 21a9 9 0 100-18 9 9 0 000 18zM12 3v18M12 7h5M12 11h7M12 15h6"
    static let flag = "M6 21V4M6 4h11l-2 4 2 4H6"
    static let doc = "M6 3.5h9l3 3V20.5H6zM9 11h6M9 15h6"
    static let star = "M12 3.5l2.6 5.4 5.9.8-4.3 4.1 1 5.8L12 16.9l-5.2 2.7 1-5.8-4.3-4.1 5.9-.8z"
}

/// One settings row (061): the tile, the title (16 pt semibold) with an optional line under it, a muted value and the
/// chevron. 45 pt minimum on the home list; taller where the row carries a line.
struct SettingsRow: View {
    let icon: String?
    let title: Text
    var detail: Text?
    var value: Text?
    var chevron = true
    var minHeight: CGFloat = 45

    init(_ title: LocalizedStringKey, icon: DX.Icon?, detail: Text? = nil, value: Text? = nil, chevron: Bool = true, minHeight: CGFloat = 45) {
        self.init(Text(title), icon: icon?.d, detail: detail, value: value, chevron: chevron, minHeight: minHeight)
    }

    init(_ title: Text, icon: String?, detail: Text? = nil, value: Text? = nil, chevron: Bool = true, minHeight: CGFloat = 45) {
        self.title = title
        self.icon = icon
        self.detail = detail
        self.value = value
        self.chevron = chevron
        self.minHeight = minHeight
    }

    var body: some View {
        let g = DX.Ground.reading
        HStack(spacing: 12) {
            if let icon { SettingsTile(d: icon) }
            VStack(alignment: .leading, spacing: 2) {
                title.dxFont(16, weight: 600, style: .body).foregroundStyle(g.ink)
                if let detail { detail.dxType(.footnote).foregroundStyle(g.muted).fixedSize(horizontal: false, vertical: true) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)
            if let value {
                value.dxFont(15, weight: 500, style: .subheadline).foregroundStyle(g.muted).lineLimit(1)
            }
            if chevron { DXIcon(.chev, size: 18).foregroundStyle(g.muted).padding(.leading, -4) }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, detail == nil ? 4 : 10)
        .frame(minHeight: minHeight)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// The kit switch on its own (52 × 32, coral when on), for rows that hold more than a label.
struct DXSwitch: View {
    @Binding var isOn: Bool
    var enabled = true
    private let motion = MotionPolicy()

    var body: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule().fill(isOn ? Color(hex: 0xF26A45) : DX.Ground.reading.ink.opacity(0.3))
            Circle().fill(.white)
                .shadow(color: .black.opacity(0.3), radius: 1.5, x: 0, y: 1)
                .frame(width: 26, height: 26)
                .padding(3)
        }
        .frame(width: 52, height: 32)
        .opacity(enabled ? 1 : 0.4)
        .contentShape(Capsule())
        .onTapGesture { if enabled { isOn.toggle() } }
        .animation(motion.animation(DX.Move.settle.speed(3)), value: isOn)
        .sensoryFeedback(DX.Haptic.select, trigger: isOn)
    }
}

/// A row with a switch (062, 069, 070): the tile, the title and its line, the switch level with the first line.
struct SettingsSwitchRow<Below: View>: View {
    let icon: String?
    let title: Text
    var detail: Text?
    @Binding var isOn: Bool
    let below: Below

    init(_ title: LocalizedStringKey, icon: DX.Icon?, detail: Text? = nil, isOn: Binding<Bool>, @ViewBuilder below: () -> Below) {
        self.title = Text(title)
        self.icon = icon?.d
        self.detail = detail
        self._isOn = isOn
        self.below = below()
    }

    init(_ title: LocalizedStringKey, glyph: String, detail: Text? = nil, isOn: Binding<Bool>, @ViewBuilder below: () -> Below) {
        self.title = Text(title)
        self.icon = glyph
        self.detail = detail
        self._isOn = isOn
        self.below = below()
    }

    var body: some View {
        let g = DX.Ground.reading
        HStack(alignment: .top, spacing: 12) {
            if let icon { SettingsTile(d: icon).padding(.top, -4) }
            VStack(alignment: .leading, spacing: 2) {
                title.dxFont(16, weight: 600, style: .body).foregroundStyle(g.ink)
                if let detail {
                    detail.dxType(.footnote).foregroundStyle(g.muted).fixedSize(horizontal: false, vertical: true)
                        .contentTransition(.opacity)
                }
                below
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .contain)
            DXSwitch(isOn: $isOn)
                .padding(.top, -4)
                .accessibilityElement()
                .accessibilityLabel(title)
                .accessibilityValue(isOn ? Text("On") : Text("Off"))
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { isOn.toggle() }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .frame(minHeight: 66)
    }
}

extension SettingsSwitchRow where Below == EmptyView {
    init(_ title: LocalizedStringKey, icon: DX.Icon?, detail: Text? = nil, isOn: Binding<Bool>) {
        self.init(title, icon: icon, detail: detail, isOn: isOn) { EmptyView() }
    }

    init(_ title: LocalizedStringKey, glyph: String, detail: Text? = nil, isOn: Binding<Bool>) {
        self.init(title, glyph: glyph, detail: detail, isOn: isOn) { EmptyView() }
    }
}

// MARK: - Time

/// Minutes after midnight as a time ("8:00 AM").
func settingsTime(_ minute: Int) -> String {
    (Calendar.current.date(bySettingHour: max(minute, 0) / 60 % 24, minute: max(minute, 0) % 60, second: 0, of: .now) ?? .now)
        .formatted(date: .omitted, time: .shortened)
}

/// The time pill (062): outlined, a small chevron; it opens the wheel.
struct TimePill: View {
    let minute: Int
    let action: () -> Void

    var body: some View {
        let g = DX.Ground.reading
        Button(action: action) {
            HStack(spacing: 4) {
                Text(verbatim: settingsTime(minute)).dxFont(15, weight: 600, style: .subheadline).monospacedDigit()
                    .foregroundStyle(g.ink)
                DXIcon(.down, size: 14, weight: 2.6).foregroundStyle(g.muted)
            }
            .padding(.leading, 11)
            .padding(.trailing, 8)
            .frame(height: 32)
            .background(g.card2, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(g.ink.opacity(0.18), lineWidth: 1.5)
            }
        }
        .buttonStyle(.dxPress)
        .accessibilityLabel(Text("Change time, \(settingsTime(minute))"))
    }
}

/// Which time a wheel is open for.
struct TimePick: Identifiable {
    let id: String
    let title: LocalizedStringKey
    let minute: Binding<Int>
}

/// The wheel picker sheet (062, 064): the time settles into its pill when it closes.
struct TimeWheelSheet: View {
    let pick: TimePick
    @State private var date: Date
    @Environment(\.dismiss) private var dismiss

    init(pick: TimePick) {
        self.pick = pick
        let m = max(pick.minute.wrappedValue, 0)
        _date = State(initialValue: Calendar.current.date(bySettingHour: m / 60 % 24, minute: m % 60, second: 0, of: .now) ?? .now)
    }

    var body: some View {
        let g = DX.Ground.reading
        VStack(spacing: 8) {
            Text(pick.title).dxType(.headline).foregroundStyle(g.ink).padding(.top, 22)
            DatePicker("", selection: $date, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
            Button("Done") {
                let c = Calendar.current.dateComponents([.hour, .minute], from: date)
                pick.minute.wrappedValue = (c.hour ?? 0) * 60 + (c.minute ?? 0)
                dismiss()
            }
            .buttonStyle(.dx(.primary, on: .reading))
            .padding(.horizontal, DX.Layout.gutter)
        }
        .frame(maxWidth: .infinity)
        .background(g.background.ignoresSafeArea())
        .presentationDetents([.height(360)])
        .presentationCornerRadius(32)
        .dxGround(.reading)
    }
}

// MARK: - Dawn window

/// The small dawn window (061, 068, 069): a warm sky (pre-dawn in dark), one soft glow round the sun, a hill, and Xero
/// settling onto it.
struct SettingsDawn: View {
    var size: CGFloat = 72
    var height: CGFloat?
    var xero: CGFloat = 46
    var corner: CGFloat = 18
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack(alignment: .topLeading) {
            Canvas { ctx, sz in
                let dark = scheme == .dark
                let s = sz.width / 72
                ctx.scaleBy(x: s, y: sz.height / 72)
                let rect = Path(CGRect(x: 0, y: 0, width: 72, height: 72))
                let sky: [Color] = dark ? [Color(hex: 0x0D1630), Color(hex: 0x22325A), Color(hex: 0x3C4A78)]
                                        : [Color(hex: 0xFFE6BF), Color(hex: 0xFFC994)]
                ctx.fill(rect, with: .linearGradient(Gradient(colors: sky), startPoint: .zero, endPoint: CGPoint(x: 0, y: 72)))
                if dark {
                    for (x, y, r, o) in [(12.0, 12.0, 0.9, 0.8), (34, 7, 0.7, 0.5), (64, 14, 0.9, 0.7)] {
                        ctx.fill(CalmPaint.circle(x, y, r), with: .color(.white.opacity(o)))
                    }
                }
                let glow = Color(hex: dark ? 0xFFB06A : 0xFFEFC6)
                ctx.fill(rect, with: .radialGradient(Gradient(stops: [
                    .init(color: Color(hex: dark ? 0xFFC27A : 0xFFF4D2).opacity(dark ? 0.55 : 0.9), location: 0),
                    .init(color: glow.opacity(dark ? 0.24 : 0.5), location: 0.35),
                    .init(color: glow.opacity(dark ? 0.07 : 0.15), location: 0.7),
                    .init(color: glow.opacity(0), location: 1),
                ]), center: CGPoint(x: 55, y: 22), startRadius: 0, endRadius: 34))
                ctx.fill(CalmPaint.circle(55, 22, 8.5), with: .color(Color(hex: dark ? 0xFFC27A : 0xFFD966)))
                let hill = SVGPath.path("M0 72 V60 C16 56 30 54 42 55 C54 56 64 59 72 62 V72Z")
                ctx.fill(hill, with: .linearGradient(Gradient(colors: dark ? [Color(hex: 0x24365E), Color(hex: 0x16243F)]
                                                                             : [Color(hex: 0xFFA27A), Color(hex: 0xF0794F)]),
                                                     startPoint: CGPoint(x: 0, y: 54), endPoint: CGPoint(x: 0, y: 72)))
            }
            XeroView(mood: .hello, stage: 0, points: xero, animate: false)
                .offset(x: 8 * size / 72, y: 13 * size / 72 + ((height ?? size) - size) * 0.7)
                .dxSettle(0, delay: 0.45)
        }
        .frame(width: size, height: height ?? size)
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
        .accessibilityHidden(true)
    }
}
