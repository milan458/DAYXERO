import DayXeroCore
import SwiftData
import SwiftUI
import UIKit

/// The morning pledge (S11.1): one of your reasons and its photo, then press and hold to pledge.
struct PledgeView: View {
    let profile: UserProfile
    let onDone: () -> Void

    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var progress = 0.0
    @State private var pledged = false
    @State private var pressing = false

    var body: some View {
        let clock = DayClock(boundaryHour: profile.dayBoundaryHour)
        let day = clock.days(fromDate: profile.quitDay, to: .now) + 1
        let reason = todaysReason(dayNumber: day)
        ZStack {
            background(reason)
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(day > 0 ? "Day \(day) · \(Date.now.formatted(.dateTime.weekday(.wide)))" : "\(Date.now.formatted(.dateTime.weekday(.wide)))")
                        .dxText(.micro, color: .white.opacity(0.75))
                    Spacer()
                    Button(action: onDone) {
                        Image(systemName: "xmark").font(.system(size: 13, weight: .semibold)).foregroundStyle(.white)
                            .frame(width: 36, height: 36).background(.white.opacity(0.18), in: Circle())
                    }
                    .accessibilityLabel(Text("Close"))
                }
                Spacer()
                Text(pledged ? "Pledged. Have a good day." : "Today, I won't use nicotine.")
                    .font(.custom(DX.Typeface.bold, size: 30, relativeTo: .largeTitle))
                    .foregroundStyle(.white)
                    .contentTransition(.opacity)
                if let reason {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Because").dxText(.micro, color: .white.opacity(0.7))
                        Text(verbatim: reason.text).font(.custom(DX.Typeface.regular, size: 16, relativeTo: .body)).foregroundStyle(.white.opacity(0.9))
                    }
                    .padding(.top, DX.Space.s)
                }
                holdButton
                    .frame(maxWidth: .infinity)
                    .padding(.top, DX.Space.xl)
            }
            .padding(.horizontal, DX.Space.l)
            .padding(.top, DX.Space.s)
            .padding(.bottom, DX.Space.l)
        }
        .sensoryFeedback(.impact(flexibility: .soft, intensity: 0.4), trigger: pressing)
        .sensoryFeedback(DX.Haptic.commit, trigger: pledged)
        .preferredColorScheme(.dark)
    }

    private var holdButton: some View {
        VStack(spacing: DX.Space.xs) {
            ZStack {
                Circle().stroke(.white.opacity(0.2), lineWidth: 4)
                Circle().trim(from: 0, to: pledged ? 1 : progress)
                    .stroke(DX.Palette.sage, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: pledged ? "checkmark" : "hand.raised")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(DX.Palette.onAccent)
                    .frame(width: 72, height: 72)
                    .background(DX.Palette.sage, in: Circle())
                    .scaleEffect(pressing && !reduceMotion ? 0.94 : 1)
            }
            .frame(width: 96, height: 96)
            .contentShape(Circle())
            .onLongPressGesture(minimumDuration: 1.0, maximumDistance: 40) {
                pledge()
            } onPressingChanged: { isPressing in
                guard !pledged else { return }
                pressing = isPressing
                if isPressing {
                    withAnimation(reduceMotion ? nil : .linear(duration: 1.0)) { progress = 1 }
                } else if !pledged {
                    withAnimation(.easeOut(duration: 0.2)) { progress = 0 }
                }
            }
            .accessibilityElement()
            .accessibilityLabel(Text(pledged ? "Pledged" : "Pledge"))
            .accessibilityHint(Text("Double-tap to pledge"))
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { pledge() }
            Text(pledged ? " " : "Press and hold to pledge").dxText(.subtitle, color: .white.opacity(0.75))
        }
        .disabled(pledged)
    }

    private func background(_ reason: Reason?) -> some View {
        ZStack {
            if let data = reason?.photo, let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                LinearGradient(colors: [Color(hex: 0x5F7C52), Color(hex: 0x2F4A30), Color(hex: 0x111A0F)],
                               startPoint: .top, endPoint: .bottom)
            }
            LinearGradient(colors: [.black.opacity(0.35), .black.opacity(0.2), .black.opacity(0.85)],
                           startPoint: .top, endPoint: .bottom)
        }
        .ignoresSafeArea()
    }

    private func todaysReason(dayNumber: Int) -> Reason? {
        let reasons = profile.reasons.sorted { $0.createdAt < $1.createdAt }
        return DailyRhythm.reasonIndex(hasPhoto: reasons.map { $0.photo != nil }, dayNumber: dayNumber).map { reasons[$0] }
    }

    private func pledge() {
        guard !pledged else { return }
        let clock = DayClock(boundaryHour: profile.dayBoundaryHour)
        context.insert(Pledge(day: clock.day(containing: .now)))
        try? context.save()
        withAnimation(DX.Motion.animation(DX.Motion.glide, reduceMotion: reduceMotion)) { pledged = true }
        DailyReminders.refresh(in: context)
        Task {
            try? await Task.sleep(for: .seconds(1.4))
            onDone()
        }
    }
}
