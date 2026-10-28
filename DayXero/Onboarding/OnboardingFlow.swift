import DayXeroCore
import SwiftData
import SwiftUI

/// Hosts the onboarding steps with a shared top bar (back, progress, skip) and step transitions.
struct OnboardingFlow: View {
    @State private var model = OnboardingModel()
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("dx.underAge") private var underAge = false

    /// Called just before the profile is saved, so the app keeps showing onboarding until `onFinished`.
    var onSaving: () -> Void = {}
    let onFinished: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if showsTopBar {
                topBar
                    .padding(.horizontal, DX.Space.m)
                    .dxReadableColumn()
                    .padding(.top, DX.Space.xs)
            }
            ZStack {
                screen(for: model.step)
                    .id(model.step)
                    .transition(transition)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(alignment: .bottom) {
            if model.step == .welcome {
                // A flexible container is what stretches past the safe area; a fixed-height frame can't.
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    // 400 pt, or less on short windows such as iPhone Duo's cover (S18.13).
                    Hills().containerRelativeFrame(.vertical) { length, _ in min(400, length * 0.45) }
                }
                .ignoresSafeArea()
                .transition(.opacity)
                .accessibilityHidden(true)
            }
        }
        .dxCanvas()
        .animation(DX.Motion.animation(DX.Motion.glide, reduceMotion: reduceMotion), value: model.step)
        #if DEBUG
        .onAppear {
            if let key = UserDefaults.standard.string(forKey: "dx.onboardingStep") { model.loadSample(jumpingTo: key) }
        }
        #endif
        .onChange(of: model.step, initial: true) { _, step in
            Analytics.track(.onboardingStepViewed(step: step.key))
            if step == .underAge { underAge = true }
        }
    }

    private var showsTopBar: Bool {
        switch model.step {
        case .welcome, .building, .reveal: false
        default: true
        }
    }

    private var transition: AnyTransition {
        reduceMotion ? .opacity : .asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                               removal: .move(edge: .leading).combined(with: .opacity))
    }

    private var topBar: some View {
        HStack(spacing: DX.Space.s) {
            if model.canGoBack {
                Button { model.back() } label: {
                    Image(systemName: "chevron.left").font(.system(size: 14, weight: .semibold))
                        .frame(width: 36, height: 36)
                        .background(DX.Palette.surface1, in: Circle())
                        .overlay(Circle().strokeBorder(DX.Palette.hairline))
                        .foregroundStyle(DX.Palette.text)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Back"))
            }
            if model.step != .underAge {
                DXProgressBar(value: model.progress)
                    .frame(height: 4)
                    .accessibilityLabel(Text("Setup progress"))
            } else {
                Spacer()
            }
            if model.step.isSkippable {
                Button("Skip") { model.skip() }
                    .font(.custom(DX.Typeface.medium, size: 14, relativeTo: .subheadline))
                    .foregroundStyle(DX.Palette.text2)
                    .buttonStyle(.plain)
            }
        }
        .frame(minHeight: 44)
    }

    @ViewBuilder
    private func screen(for step: OnboardingStep) -> some View {
        switch step {
        case .welcome: WelcomeScreen(model: model)
        case .age: AgeScreen(model: model)
        case .underAge: UnderAgeScreen()
        case .name: NameScreen(model: model)
        case .products: ProductsScreen(model: model)
        case let .baseline(product): BaselineScreen(model: model, product: product)
        case .triggers: TriggersScreen(model: model)
        case .reasons: ReasonsScreen(model: model)
        case .pastAttempts: PastAttemptsScreen(model: model)
        case .quitDay: QuitDayScreen(model: model)
        case .nrt: NRTScreen(model: model)
        case .building: BuildingScreen(model: model)
        case .reveal: PlanRevealScreen(model: model) { saveAndContinue() }
        case .reminders: RemindersScreen(onDone: onFinished)
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

/// Standard step layout: title, subtitle, scrollable content, and a pinned footer.
struct OnboardingScaffold<Content: View, Footer: View>: View {
    let title: LocalizedStringKey
    var subtitle: LocalizedStringKey? = nil
    var eyebrow: LocalizedStringKey? = nil
    @ViewBuilder let content: () -> Content
    @ViewBuilder let footer: () -> Footer

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: DX.Space.xs) {
                    if let eyebrow { Text(eyebrow).dxText(.micro) }
                    Text(title).dxText(.title).fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    if let subtitle {
                        Text(subtitle).dxText(.subtitle).fixedSize(horizontal: false, vertical: true)
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        content()
                    }
                    .padding(.top, DX.Space.l)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, DX.Space.m)
                .dxReadableColumn()
                .padding(.top, DX.Space.m)
                .padding(.bottom, DX.Space.xl)
            }
            .scrollDismissesKeyboard(.interactively)
            VStack(spacing: DX.Space.xs) { footer() }
                .padding(.horizontal, DX.Space.m)
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
            .buttonStyle(.dxPrimary)
            .disabled(!model.canContinue)
    }
}
