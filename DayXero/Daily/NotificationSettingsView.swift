import DayXeroCore
import SwiftData
import SwiftUI
import UIKit
import UserNotifications

/// Every notification in one place (S14.2): grouped as your day and your plan, each with its own switch and time,
/// plus quiet hours. Changes reschedule straight away.
struct NotificationSettingsView: View {
    @AppStorage(DailyReminderSettings.pledgeKey) private var pledge = DailyReminderSettings.defaultPledge
    @AppStorage(DailyReminderSettings.lessonKey) private var lesson = DailyReminderSettings.defaultLesson
    @AppStorage(DailyReminderSettings.checkInKey) private var checkIn = DailyReminderSettings.defaultCheckIn
    @AppStorage(DailyReminderSettings.milestoneKey) private var milestone = DailyReminderSettings.defaultMilestone
    @AppStorage(DailyReminderSettings.awayKey) private var away = true
    @AppStorage(DailyReminderSettings.nrtOnKey) private var nrt = true
    @AppStorage(DailyReminderSettings.quietStartKey) private var quietStart = DailyReminderSettings.defaultQuietStart
    @AppStorage(DailyReminderSettings.quietEndKey) private var quietEnd = DailyReminderSettings.defaultQuietEnd
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @State private var denied = false

    var body: some View {
        List {
            if denied {
                Section {
                    HStack(spacing: DX.Space.s) {
                        Text("Notifications are off for DayXero in iPhone Settings.").dxFont(14, weight: 400, style: .footnote)
                        Spacer(minLength: DX.Space.xs)
                        Button("Turn on") {
                            if let url = URL(string: UIApplication.openNotificationSettingsURLString) { UIApplication.shared.open(url) }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Read4.ink)
                    }
                }
                .listRowBackground(Read4.amber.opacity(0.14))
            }
            Section("Your day") {
                row("Morning pledge", detail: "Skipped once you've pledged", systemImage: "sun.max", minute: $pledge, fallback: DailyReminderSettings.defaultPledge)
                row("Lesson ready", detail: "When a new day opens", systemImage: "book.closed", minute: $lesson, fallback: DailyReminderSettings.defaultLesson)
                row("Evening check-in", detail: "Skipped once you've checked in", systemImage: "moon", minute: $checkIn, fallback: DailyReminderSettings.defaultCheckIn)
                row("Milestones", detail: "On the day", systemImage: "flag", minute: $milestone, fallback: DailyReminderSettings.defaultMilestone)
            }
            .disabled(denied)
            Section {
                Toggle(isOn: $nrt) { label("NRT", detail: "Patch changes and step-downs", systemImage: "bandage") }
                Toggle(isOn: $away) { label("When you've been away", detail: "Two gentle notes, then quiet", systemImage: "water.waves") }
            } header: {
                Text("Your plan")
            }
            .disabled(denied)
            Section {
                NavigationLink(value: SettingsSheet.Page.quietHours) {
                    LabeledContent {
                        Text(quietStart < 0 ? String(localized: "Off") : "\(time(quietStart)) – \(time(quietEnd))")
                    } label: {
                        label("Quiet hours", detail: "Nothing between these times", systemImage: "clock")
                    }
                }
            } header: {
                Text("Quiet hours")
            } footer: {
                Text("At most three a day from the program. NRT reminders you set always arrive.")
            }
        }
        .tint(Read4.accent)
        .navigationTitle("Notifications")
        .onChange(of: [pledge, lesson, checkIn, milestone, quietStart, quietEnd]) { refresh() }
        .onChange(of: away) { refresh() }
        .onChange(of: nrt) { refresh() }
        .onChange(of: scenePhase, initial: true) { _, phase in
            guard phase == .active else { return }
            Task { denied = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus == .denied }
        }
    }

    private func refresh() {
        DailyReminders.refresh(in: context)
        NRTReminders.refresh(profile: try? context.fetch(FetchDescriptor<UserProfile>()).first)
    }

    private func label(_ title: LocalizedStringKey, detail: LocalizedStringKey, systemImage: String) -> some View {
        HStack(spacing: DX.Space.s) {
            Image(systemName: systemImage).font(.system(size: 14)).foregroundStyle(Read4.accent)
                .frame(width: 30, height: 30).background(Read4.accentSoft, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text(title).dxFont(16, weight: 600, style: .body)
                Text(detail).v4Text(.subtitle)
            }
        }
    }

    private func row(_ title: LocalizedStringKey, detail: LocalizedStringKey, systemImage: String, minute: Binding<Int>, fallback: Int) -> some View {
        VStack(alignment: .leading, spacing: DX.Space.xs) {
            Toggle(isOn: Binding(get: { minute.wrappedValue >= 0 }, set: { minute.wrappedValue = $0 ? fallback : -1 })) {
                label(title, detail: detail, systemImage: systemImage)
            }
            if minute.wrappedValue >= 0 {
                DatePicker("Time", selection: Self.timeBinding(minute), displayedComponents: .hourAndMinute)
                    .dxFont(14, weight: 400, style: .footnote)
            }
        }
    }

    private func time(_ minute: Int) -> String {
        (Calendar.current.date(bySettingHour: minute / 60, minute: minute % 60, second: 0, of: .now) ?? .now)
            .formatted(date: .omitted, time: .shortened)
    }

    static func timeBinding(_ minute: Binding<Int>) -> Binding<Date> {
        Binding(
            get: { Calendar.current.date(bySettingHour: max(minute.wrappedValue, 0) / 60, minute: max(minute.wrappedValue, 0) % 60, second: 0, of: .now) ?? .now },
            set: { minute.wrappedValue = Calendar.current.component(.hour, from: $0) * 60 + Calendar.current.component(.minute, from: $0) }
        )
    }
}

/// Quiet hours (S14.2): a from/until pair with a 24-hour strip of today's notifications against the quiet band.
struct QuietHoursView: View {
    @AppStorage(DailyReminderSettings.quietStartKey) private var start = DailyReminderSettings.defaultQuietStart
    @AppStorage(DailyReminderSettings.quietEndKey) private var end = DailyReminderSettings.defaultQuietEnd
    @AppStorage(DailyReminderSettings.nrtThroughQuietKey) private var nrtThrough = true
    @AppStorage(DailyReminderSettings.pledgeKey) private var pledge = DailyReminderSettings.defaultPledge
    @AppStorage(DailyReminderSettings.lessonKey) private var lesson = DailyReminderSettings.defaultLesson
    @AppStorage(DailyReminderSettings.checkInKey) private var checkIn = DailyReminderSettings.defaultCheckIn
    @Environment(\.modelContext) private var context

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DX.Space.s) {
                Text("Nothing arrives between these times. Anything due waits until they end.").v4Text(.subtitle)
                Toggle("Quiet hours", isOn: Binding(get: { start >= 0 }, set: {
                    start = $0 ? DailyReminderSettings.defaultQuietStart : -1
                    end = $0 ? DailyReminderSettings.defaultQuietEnd : -1
                }))
                .dxFont(16, weight: 600, style: .body)
                if start >= 0 {
                    HStack(spacing: DX.Space.xs) {
                        timeCard("From", minute: $start)
                        timeCard("Until", minute: $end)
                    }
                    strip
                    Text("Grey is quiet. Sage marks are your daily notifications.").v4Text(.subtitle)
                }
                Toggle(isOn: $nrtThrough) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Let my NRT times through").dxFont(16, weight: 600, style: .body)
                        Text("Times you set yourself").v4Text(.subtitle)
                    }
                }
                .padding(.top, DX.Space.s)
            }
            .padding(DX.Space.m)
        }
        .tint(Read4.accent)
        .background(Read4.background.ignoresSafeArea())
        .navigationTitle("Quiet hours")
        .onChange(of: [start, end]) { refresh() }
        .onChange(of: nrtThrough) { refresh() }
    }

    private func refresh() {
        DailyReminders.refresh(in: context)
        NRTReminders.refresh(profile: try? context.fetch(FetchDescriptor<UserProfile>()).first)
    }

    private func timeCard(_ title: LocalizedStringKey, minute: Binding<Int>) -> some View {
        V4Card(padding: 14) {
            VStack(spacing: 4) {
                Text(title).v4Text(.micro)
                DatePicker(title, selection: NotificationSettingsView.timeBinding(minute), displayedComponents: .hourAndMinute)
                    .labelsHidden()
            }
            .frame(maxWidth: .infinity)
        }
    }

    /// 24 hours, quiet band in grey, today's notifications as sage marks.
    private var strip: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let x = { (m: Int) in w * CGFloat(m) / 1440 }
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Read4.card)
                if start > end {
                    Rectangle().fill(Read4.track).frame(width: x(end))
                    Rectangle().fill(Read4.track).frame(width: w - x(start)).offset(x: x(start))
                } else {
                    Rectangle().fill(Read4.track).frame(width: x(end) - x(start)).offset(x: x(start))
                }
                ForEach([pledge, lesson, checkIn].filter { $0 >= 0 }, id: \.self) { m in
                    RoundedRectangle(cornerRadius: 3).fill(Read4.accent).frame(width: 6, height: 14).offset(x: x(m) - 3)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .frame(height: 34)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Quiet from \(time(start)) until \(time(end))"))
    }

    private func time(_ minute: Int) -> String {
        (Calendar.current.date(bySettingHour: max(minute, 0) / 60, minute: max(minute, 0) % 60, second: 0, of: .now) ?? .now)
            .formatted(date: .omitted, time: .shortened)
    }
}
