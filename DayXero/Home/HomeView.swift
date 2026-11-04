import DayXeroCore
import SwiftData
import SwiftUI

/// The app after onboarding: four tabs, Today · Program · SOS · Progress (S27.11, 1 Nov 2026). Evening folded into
/// Today's evening and night states; Me became Progress, with Settings behind its gear. On iPhone Duo with vertical
/// bars, the older dock stands on the side edge.
struct HomeView: View {
    let profile: UserProfile
    @State private var tab = UserDefaults.standard.string(forKey: "dx.tab") ?? "today"
    @Environment(SOSRouter.self) private var sos
    @Environment(Entitlement.self) private var entitlement
    @Environment(\.scenePhase) private var scenePhase
    /// Where iPhone Duo puts vertical bars right now; nil on other iPhones and where it doesn't (S18.13).
    @State private var barEdge: HorizontalEdge?

    var body: some View {
        // Today goes fully dark at night, even in light mode (Milan, 4 Nov 2026): the night sky, its cards and the tab
        // bar all turn together. The other tabs keep the phone's own setting.
        TimelineView(.everyMinute) { timeline in
            home.preferredColorScheme(isTodayTab && TodayClock.isNight(at: timeline.date) ? .dark : nil)
        }
    }

    private var isTodayTab: Bool {
        !["program", "progress", "me"].contains(tab)
    }

    private var home: some View {
        GeometryReader { geo in
            let edge = dockEdge(in: geo.size)
            let alignment: Alignment = edge == nil ? .bottom : edge == .leading ? .leading : .trailing
            let dockPadding: Edge.Set = edge == nil ? .bottom : edge == .leading ? .leading : .trailing
            ZStack(alignment: alignment) {
                tabContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    // Every tab scrolls clear of the dock, on whichever edge it stands (S18.13). The inset covers the
                    // raised SOS button too, with room to spare, so the bar never sits over the last card (UX-11).
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        if edge == nil { Color.clear.frame(height: V4TabBar.contentInset) }
                    }
                    .safeAreaInset(edge: edge ?? .trailing, spacing: 0) {
                        if edge != nil { Color.clear.frame(width: DXDock.thickness + DX.Space.xs) }
                    }
                if edge == nil {
                    // S27.11: Today · Program · SOS · Progress.
                    V4TabBar(selection: v4Selection)
                        .padding(.bottom, DX.Space.xxs)
                } else {
                    dock(axis: .vertical)
                        .padding(dockPadding, DX.Space.xxs)
                }
            }
        }
        .readVerticalBarEdge($barEdge)
        .background(DX.Ground.reading.background.ignoresSafeArea())
        // Program v2 missions ask their quick question after a logged use or an SOS session (handoff 4.4).
        .modifier(MissionPrompts(profile: profile))
    }
}

extension HomeView {
    @ViewBuilder
    private var tabContent: some View {
        switch tab {
        case "program":
            ProgramView(profile: profile)
        case "progress", "me":
            // Progress, with Settings behind its gear (S27.11). "me" is the old tab id.
            ProgressTab(profile: profile)
        default:
            // "evening", "toolkit" and "water" are old tab ids: their content now lives on Today (S27.11, S27.12).
            TodayView(profile: profile)
        }
    }

    /// The v4 tab bar's selection. SOS opens Craving SOS rather than switching tabs: straight into Jelli's breathing
    /// session, never Glim's calm tools list (UX-03). The calm tools are one step further, behind "Still strong".
    private var v4Selection: Binding<V4Tab> {
        Binding(
            get: {
                switch tab {
                case "program": .program
                case "progress", "me": .progress
                default: .today
                }
            },
            set: { new in
                switch new {
                case .sos: sos.open(source: "dock")
                case .today: tab = "today"
                case .program: tab = "program"
                case .progress: tab = "progress"
                }
            }
        )
    }

    private func dock(axis: Axis) -> some View {
        DXDock(
            items: [
                DXDockItem(id: "today", title: "Today", systemImage: "house"),
                DXDockItem(id: "program", title: "Program", systemImage: "book.closed"),
                DXDockItem(id: "progress", title: "Progress", systemImage: "chart.bar"),
            ],
            selection: Binding(get: {
                switch tab {
                case "water", "evening", "toolkit": "today"
                case "me": "progress"
                default: tab
                }
            }, set: { tab = $0 }),
            // The same order as the tab bar (S27.11): Today, Program, Craving SOS, Progress.
            sosPosition: 2,
            axis: axis,
            sosAction: { sos.open(source: "dock") }
        )
    }

    /// The dock stands on the edge where iPhone Duo puts vertical bars; in a window wider than it is tall it
    /// stands on the trailing edge anyway, so it never eats into a short screen's height.
    private func dockEdge(in size: CGSize) -> HorizontalEdge? {
        if let barEdge { return barEdge }
        return size.width > size.height ? .trailing : nil
    }
}

/// Stand-in for tabs and steps that later sections fill in.
struct ComingSoon: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(title).v4Text(.title).padding(.top, DX.Space.xl)
            Spacer()
            V4StateView(.empty, systemImage: systemImage, title: "Coming soon", message: message)
            Spacer()
        }
        .padding(.horizontal, DX.Space.m)
        .dxReadableColumn()
        .background(Read4.background.ignoresSafeArea())
    }
}

/// "Start my prep week" queues Prep 1, which opens once Home has faded in after onboarding (S22, QW1): the person
/// chose to start, so the first thing after setting up is the program working, not a dashboard. Prep 1 to 3 are free;
/// the trial is offered at Prep 4 (MON-01).
enum FirstLesson {
    static let key = "dx.openFirstLesson"
}
