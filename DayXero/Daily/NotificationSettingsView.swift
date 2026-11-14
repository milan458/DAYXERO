import DayXeroCore
import SwiftData
import SwiftUI
import UIKit
import UserNotifications

/// Reminders (v5, 062): gentle nudges, at most three a day. Every day (the pledge and the check-in each with a time
/// pill that opens the wheel, the daily lesson), the plan's own reminders, then quiet hours. Changes reschedule at once.
struct NotificationSettingsView: View {
    @AppStorage(DailyReminderSettings.pledgeKey) private var pledge = DailyReminderSettings.defaultPledge
    @AppStorage(DailyReminderSettings.lessonKey) private var lesson = DailyReminderSettings.offUntilChosen
    @AppStorage(DailyReminderSettings.checkInKey) private var checkIn = DailyReminderSettings.defaultCheckIn
    @AppStorage(DailyReminderSettings.milestoneKey) private var milestone = DailyReminderSettings.offUntilChosen
    @AppStorage(DailyReminderSettings.awayKey) private var away = true
    @AppStorage(DailyReminderSettings.nrtOnKey) private var nrt = true
    @AppStorage(DailyReminderSettings.weeklyKey) private var weekly = DailyReminderSettings.offUntilChosen
    @AppStorage(DailyReminderSettings.quietGraduationKey) private var quietGraduation = true
    @AppStorage(DailyReminderSettings.quietStartKey) private var quietStart = DailyReminderSettings.defaultQuietStart
    @AppStorage(DailyReminderSettings.quietEndKey) private var quietEnd = DailyReminderSettings.defaultQuietEnd
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @State private var denied = false
    @State private var picking: TimePick?
    private let ground = DX.Ground.reading

    var body: some View {
        SettingsPage("Reminders", lead: Text("Gentle nudges, at most three a day.")) {
            if denied {
                HStack(spacing: 12) {
                    Text("Notifications are off for DayXero in iPhone Settings.").dxType(.footnote).foregroundStyle(ground.ink)
                    Spacer(minLength: 8)
                    Button("Turn on") {
                        if let url = URL(string: UIApplication.openNotificationSettingsURLString) { UIApplication.shared.open(url) }
                    }
                    .buttonStyle(.dx(.small, on: .reading))
                    .fixedSize()
                }
                .dxCard(on: .reading, flat: true, tight: true)
                .padding(.top, 16)
            }
            SettingsSection("Every day", trailing: Text("\(used) of 3 used"), index: 2)
            DXList {
                timed("Morning pledge", icon: .sun, minute: $pledge, fallback: DailyReminderSettings.defaultPledge,
                      off: "Off. Pledge from Today")
                timed("Evening check-in", icon: .moon, minute: $checkIn, fallback: DailyReminderSettings.defaultCheckIn,
                      off: "Off. Check in from Today")
                timed("Daily lesson", icon: .note, minute: $lesson, fallback: DailyReminderSettings.defaultLesson,
                      off: "Off. You will find it on Today")
            }
            .disabled(denied)
            .dxArrive(3)
            SettingsSection("Along the way", index: 4)
            DXList {
                timed("Milestones", glyph: SettingsGlyph.flag, minute: $milestone, fallback: DailyReminderSettings.defaultMilestone,
                      off: "On the day you reach one")
                SettingsSwitchRow("NRT", icon: .patch, detail: Text("Patch changes and step-downs"), isOn: $nrt)
                SettingsSwitchRow("When you've been away", icon: .wave, detail: Text("Two gentle notes, then quiet"), isOn: $away)
                // CLIN-06: as cravings fade, the program steps back.
                SettingsSwitchRow("Quiet graduation", icon: .leaf, detail: Text("Fewer reminders from Week 3, as cravings fade"),
                                  isOn: $quietGraduation)
                // After the four weeks, Glim checks in once a week (S27.18). Off until chosen.
                timed("Weekly check-in", icon: .calendar, minute: $weekly, fallback: DailyReminderSettings.defaultWeekly,
                      off: "Sundays, after the four weeks")
            }
            .disabled(denied)
            .dxArrive(5)
            SettingsSection("Do not disturb", index: 6)
            DXList {
                NavigationLink(value: SettingsSheet.Page.quietHours) {
                    SettingsRow("Quiet hours", icon: .clock,
                                detail: quietStart < 0 ? Text("Off") : Text("\(settingsTime(quietStart)) to \(settingsTime(quietEnd))"),
                                minHeight: 66)
                }
                .buttonStyle(.dxPress)
            }
            .dxArrive(7)
        }
        .sheet(item: $picking) { TimeWheelSheet(pick: $0) }
        .animation(.easeInOut(duration: 0.3), value: [pledge, checkIn, lesson, milestone, weekly])
        .onChange(of: [pledge, lesson, checkIn, milestone, weekly, quietStart, quietEnd]) { refresh() }
        .onChange(of: away) { refresh() }
        .onChange(of: quietGraduation) { refresh() }
        .onChange(of: nrt) { refresh() }
        .onChange(of: scenePhase, initial: true) { _, phase in
            guard phase == .active else { return }
            Task { denied = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus == .denied }
        }
    }

    /// The daily three that are on.
    private var used: Int { [pledge, checkIn, lesson].filter { $0 >= 0 }.count }

    private func refresh() {
        DailyReminders.refresh(in: context)
        NRTReminders.refresh(profile: try? context.fetch(FetchDescriptor<UserProfile>()).first)
    }

    private func timed(_ title: LocalizedStringKey, icon: DX.Icon, minute: Binding<Int>, fallback: Int, off: LocalizedStringKey) -> some View {
        timed(title, glyph: icon.d, minute: minute, fallback: fallback, off: off)
    }

    /// A reminder with its time: on, the pill under the title; off, the line saying where to find it.
    private func timed(_ title: LocalizedStringKey, glyph: String, minute: Binding<Int>, fallback: Int, off: LocalizedStringKey) -> some View {
        let on = Binding(get: { minute.wrappedValue >= 0 }, set: { minute.wrappedValue = $0 ? fallback : -1 })
        return SettingsSwitchRow(title, glyph: glyph, detail: on.wrappedValue ? nil : Text(off), isOn: on) {
            if on.wrappedValue {
                TimePill(minute: minute.wrappedValue) {
                    picking = TimePick(id: "\(title)", title: title, minute: minute)
                }
                .padding(.top, 6)
                .transition(.opacity)
            }
        }
    }

    static func timeBinding(_ minute: Binding<Int>) -> Binding<Date> {
        Binding(
            get: { Calendar.current.date(bySettingHour: max(minute.wrappedValue, 0) / 60, minute: max(minute.wrappedValue, 0) % 60, second: 0, of: .now) ?? .now },
            set: { minute.wrappedValue = Calendar.current.component(.hour, from: $0) * 60 + Calendar.current.component(.minute, from: $0) }
        )
    }
}

/// Quiet hours (v5, 064): a 24-hour dial from the moon handle round to the sun handle, sleeping Glim and the hours in
/// the middle; From and Until tiles; what still arrives. Either handle drags in 15-minute steps.
struct QuietHoursView: View {
    @AppStorage(DailyReminderSettings.quietStartKey) private var start = DailyReminderSettings.defaultQuietStart
    @AppStorage(DailyReminderSettings.quietEndKey) private var end = DailyReminderSettings.defaultQuietEnd
    @AppStorage(DailyReminderSettings.nrtThroughQuietKey) private var nrtThrough = true
    @Environment(\.modelContext) private var context
    @State private var picking: TimePick?
    @State private var drawn = false
    private let ground = DX.Ground.reading
    private let motion = MotionPolicy()

    var body: some View {
        let on = start >= 0
        SettingsPage("Quiet hours", lead: Text("Only what you allow arrives in these hours.")) {
            dial
                .frame(maxWidth: .infinity)
                .padding(.top, 46)
                .padding(.bottom, 46)
                .opacity(on ? 1 : 0.4)
                .allowsHitTesting(on)
                .dxArrive(2)
            HStack(spacing: 10) {
                tile("From", icon: .moon, minute: $start)
                tile("Until", icon: .sun, minute: $end)
            }
            .opacity(on ? 1 : 0.4)
            .allowsHitTesting(on)
            .dxArrive(3)
            HStack(spacing: 10) {
                DXIcon(.bell, size: 20).foregroundStyle(ground.muted)
                Text(on ? "Nudges wait until \(settingsTime(end))." : "Quiet hours are off.")
                    .dxType(.footnote).foregroundStyle(ground.muted)
            }
            .padding(.horizontal, 4)
            .padding(.top, 14)
            .dxArrive(4)
            DXList {
                SettingsSwitchRow("Quiet hours", icon: .moon, detail: Text("Hold reminders overnight"),
                                  isOn: Binding(get: { start >= 0 }, set: {
                                      start = $0 ? DailyReminderSettings.defaultQuietStart : -1
                                      end = $0 ? DailyReminderSettings.defaultQuietEnd : -1
                                  }))
                SettingsSwitchRow("NRT reminders", icon: .patch, detail: Text("Your NRT times still arrive"), isOn: $nrtThrough)
            }
            .padding(.top, 14)
            .dxArrive(5)
        }
        .sheet(item: $picking) { TimeWheelSheet(pick: $0) }
        .onChange(of: [start, end]) { refresh() }
        .onChange(of: nrtThrough) { refresh() }
        .onAppear {
            if motion.reduce { drawn = true } else { withAnimation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 1.4).delay(0.3)) { drawn = true } }
        }
    }

    private func refresh() {
        DailyReminders.refresh(in: context)
        NRTReminders.refresh(profile: try? context.fetch(FetchDescriptor<UserProfile>()).first)
    }

    private var span: Int { start < 0 ? 0 : (end - start + 1440) % 1440 }

    /// 12 AM at the top, round clockwise through the day.
    private var dial: some View {
        let size: CGFloat = 244
        let ring: CGFloat = 26
        let r = (size - ring) / 2
        let s = Double(max(start, 0)) / 1440
        let f = Double(span) / 1440
        let navy = Color(light: 0x1E1A3A, dark: 0xFFF6EA)
        return ZStack {
            Circle().stroke(Color(light: 0xE6DCCB, dark: 0x32364A), lineWidth: ring).frame(width: 2 * r, height: 2 * r)
            Circle()
                .trim(from: 0, to: drawn ? f : 0)
                .stroke(navy, style: StrokeStyle(lineWidth: ring, lineCap: .round))
                .frame(width: 2 * r, height: 2 * r)
                .rotationEffect(.degrees(-90 + s * 360))
            ForEach(0..<4, id: \.self) { i in
                Circle().fill(ground.muted.opacity(0.6)).frame(width: 4, height: 4)
                    .offset(y: -(r - ring / 2 - 16))
                    .rotationEffect(.degrees(Double(i) * 90))
            }
            VStack(spacing: 0) {
                GlimView(mood: .sleepy, stage: 1, points: 66)
                    .dxFade(delay: 0.5)
                Text(verbatim: hoursText).dxFace(.display, 44, weight: 800, tracking: -1).foregroundStyle(ground.ink)
                    .contentTransition(.numericText())
                Text("quiet hours").dxType(.footnote).foregroundStyle(ground.muted)
            }
            handle(.moon, minute: $start, radius: r).dxPop(0, delay: 0.15)
            handle(.sun, minute: $end, radius: r).opacity(drawn ? 1 : 0)
            hour("12 AM", angle: 0, distance: size / 2 + 22)
            hour("6 AM", angle: 90, distance: size / 2 + 30)
            hour("12 PM", angle: 180, distance: size / 2 + 22)
            hour("6 PM", angle: 270, distance: size / 2 + 30)
        }
        .frame(width: size, height: size)
        .coordinateSpace(.named("dial"))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Quiet from \(settingsTime(start)) until \(settingsTime(end)), \(hoursText) hours"))
    }

    private var hoursText: String {
        let h = Double(span) / 60
        return h == h.rounded() ? "\(Int(h))" : h.formatted(.number.precision(.fractionLength(1)))
    }

    private func hour(_ text: LocalizedStringKey, angle: Double, distance: CGFloat) -> some View {
        let a = angle * .pi / 180
        return Text(text).dxType(.caption).foregroundStyle(ground.muted).fixedSize()
            .offset(x: distance * sin(a), y: -distance * cos(a))
    }

    private func handle(_ icon: DX.Icon, minute: Binding<Int>, radius: CGFloat) -> some View {
        let a = Double(max(minute.wrappedValue, 0)) / 1440 * 2 * .pi
        return DXIcon(icon, size: 23)
            .foregroundStyle(ground.ink)
            .frame(width: 46, height: 46)
            .background(ground.card, in: Circle())
            .overlay(Circle().strokeBorder(Color(light: 0x1E1A3A, dark: 0xE9E1D3), lineWidth: 3))
            .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
            .offset(x: radius * sin(a), y: -radius * cos(a))
            .gesture(
                DragGesture(coordinateSpace: .named("dial"))
                    .onChanged { g in
                        let dx = g.location.x - 122, dy = g.location.y - 122
                        var angle = atan2(dx, -dy)
                        if angle < 0 { angle += 2 * .pi }
                        let m = Int((angle / (2 * .pi) * 1440 / 15).rounded()) * 15 % 1440
                        if m != minute.wrappedValue { minute.wrappedValue = m }
                    }
            )
            .sensoryFeedback(DX.Haptic.select, trigger: minute.wrappedValue)
            .accessibilityHidden(true)
    }

    private func tile(_ title: LocalizedStringKey, icon: DX.Icon, minute: Binding<Int>) -> some View {
        Button { picking = TimePick(id: "\(title)", title: title, minute: minute) } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    DXIcon(icon, size: 15)
                    Text(title)
                    Spacer(minLength: 4)
                    DXIcon(.down, size: 14, weight: 2.6)
                        .frame(width: 24, height: 24)
                        .background(ground.card2, in: Circle())
                }
                .dxType(.footnote).foregroundStyle(ground.muted)
                Text(verbatim: settingsTime(minute.wrappedValue)).dxFace(.display, 24, weight: 800, tracking: -0.4)
                    .foregroundStyle(ground.ink)
                    .monospacedDigit()
                    .lineLimit(1).minimumScaleFactor(0.7)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .dxCardChrome(on: .reading)
        }
        .buttonStyle(.dxPress)
        .accessibilityLabel(Text("\(Text(title)), \(settingsTime(minute.wrappedValue))"))
    }
}
