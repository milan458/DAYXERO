import DayXeroCore
import SwiftData
import SwiftUI

/// Hosts the onboarding steps with a shared top bar (back, progress) and step transitions.
struct OnboardingFlow: View {
    @State private var model = OnboardingModel()
    /// F01: one slow breath before any question. Shown once, before Welcome.
    @State private var breathed = false
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Called just before the profile is saved, so the app keeps showing onboarding until `onFinished`.
    var onSaving: () -> Void = {}
    let onFinished: () -> Void

    private var ground: DX.Ground { breathed ? Onb.ground(for: model.step) : .coral }

    var body: some View {
        VStack(spacing: 0) {
            if breathed && showsTopBar {
                topBar
                    .padding(.horizontal, DX.Layout.gutter)
                    .dxReadableColumn()
                    .padding(.top, DX.Space.xs)
            }
            ZStack {
                if breathed {
                    screen(for: model.step)
                        .id(model.step)
                        .transition(transition)
                } else {
                    BreatheScreen { breathed = true }
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .foregroundStyle(ground.ink)
        .background(ground.background.ignoresSafeArea())
        .animation(DX.Move.animation(DX.Move.settle, reduceMotion: reduceMotion), value: model.step)
        .animation(DX.Move.animation(.easeInOut(duration: 0.5), reduceMotion: reduceMotion), value: breathed)
        #if DEBUG
        .onAppear {
            if let key = UserDefaults.standard.string(forKey: "dx.onboardingStep") {
                if key != "breathe" {
                    breathed = true
                    model.loadSample(jumpingTo: key)
                }
            }
        }
        #endif
        .onChange(of: model.step, initial: true) { _, step in
            Analytics.track(.onboardingStepViewed(step: step.key))
        }
    }

    private var showsTopBar: Bool {
        switch model.step {
        case .welcome, .quitDay, .building, .reveal, .trial: false
        default: true
        }
    }

    private var transition: AnyTransition {
        reduceMotion ? .opacity : .asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                               removal: .move(edge: .leading).combined(with: .opacity))
    }

    /// F03 header: back, Xero's avatar and a green progress bar.
    private var topBar: some View {
        HStack(spacing: 12) {
            if model.canGoBack {
                Button { model.back() } label: {
                    Image(systemName: "chevron.left").font(.system(size: 16, weight: .bold))
                        .frame(width: 44, height: 44)
                        .background(DX.Fill.cardOnColour, in: Circle())
                        .foregroundStyle(ground.ink)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Back"))
            }
            XeroView(mood: .hello, stage: 1, size: .avatar, animate: false)
                .background(DX.Ground.apricot.background, in: Circle())
                .clipShape(Circle())
                .accessibilityHidden(true)
            OnbProgressBar(value: model.progress, ground: ground)
        }
        .frame(minHeight: 48)
    }

    @ViewBuilder
    private func screen(for step: OnboardingStep) -> some View {
        switch step {
        case .welcome: WelcomeScreen(model: model)
        case .products: ProductsScreen(model: model)
        case let .baseline(product): BaselineScreen(model: model, product: product)
        case .baselineSummary: BaselineSummaryScreen(model: model)
        case .triggers: TriggersScreen(model: model)
        case .personal: PersonalScreen(model: model)
        case .pastAttempts: PastAttemptsScreen(model: model)
        case .nrt: NRTScreen(model: model)
        case .quitDay: QuitDayScreen(model: model)
        case .building: BuildingScreen(model: model)
        case .reveal: PlanRevealScreen(model: model) { saveAndContinue() }
        case .trial: TrialScreen(name: model.name, quitDay: model.quitDay, dualUse: model.products.count > 1, onDone: onFinished)
        }
    }

    private func saveAndContinue() {
        do {
            onSaving()
            try model.save(into: context)
            model.next()
        } catch {
            // Saving locally essentially never fails; if it does, staying on the reveal lets them retry.
            assertionFailure("Onboarding save failed: \(error)")
        }
    }
}

/// Standard question layout (F03): Xero asks in a bubble, the controls sit in the answer tray,
/// and the footer is pinned. Lilac ground (talking with Xero).
struct OnboardingScaffold<Content: View, Footer: View>: View {
    let title: LocalizedStringKey
    var subtitle: LocalizedStringKey? = nil
    var eyebrow: LocalizedStringKey? = nil
    /// Xero's bubbles: card on colour on lilac; a surface fill and hairline on the cream reading ground.
    var bubbleFill: Color = DX.Fill.cardOnColour
    var bubbleBorder: Color = .clear
    @ViewBuilder let content: () -> Content
    @ViewBuilder let footer: () -> Footer

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if let eyebrow {
                        Text(eyebrow).dxType(.caption).textCase(.uppercase).foregroundStyle(DX.Ground.lilac.muted)
                            .dxArrive(0)
                    }
                    XeroBubble(text: Text(title), large: true, fill: bubbleFill, border: bubbleBorder)
                        .accessibilityAddTraits(.isHeader)
                        .dxArrive(0)
                    if let subtitle {
                        XeroBubble(text: Text(subtitle), fill: bubbleFill, border: bubbleBorder).dxArrive(1)
                    }
                    AnswerTrayCard {
                        VStack(alignment: .leading, spacing: 10) { content() }
                    }
                    .padding(.top, 8)
                    .dxArrive(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, DX.Layout.gutter)
                .dxReadableColumn()
                .padding(.top, DX.Space.m)
                .padding(.bottom, DX.Space.xl)
            }
            .scrollDismissesKeyboard(.interactively)
            VStack(spacing: DX.Space.xs) { footer() }
                .padding(.horizontal, DX.Layout.buttonGutter)
                .dxReadableColumn()
                .padding(.bottom, DX.Space.xs)
        }
    }
}

extension OnboardingScaffold where Footer == ContinueButton {
    init(title: LocalizedStringKey, subtitle: LocalizedStringKey? = nil, eyebrow: LocalizedStringKey? = nil,
         model: OnboardingModel, continueTitle: LocalizedStringKey = "Continue", @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.eyebrow = eyebrow
        self.content = content
        self.footer = { ContinueButton(title: continueTitle, model: model) }
    }
}

struct ContinueButton: View {
    let title: LocalizedStringKey
    let model: OnboardingModel

    var body: some View {
        Button(title) { model.next() }
            .buttonStyle(.dx(.primary, on: .lilac))
            .disabled(!model.canContinue)
    }
}
