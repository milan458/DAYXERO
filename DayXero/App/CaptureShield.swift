import DayXeroCore
import SwiftUI
import UIKit

/// Keeps a screen out of screenshots, screen recordings and mirroring.
///
/// iOS has no switch for this. The system does blank whatever is drawn inside a secure text field, so the
/// content is hosted in that field's own drawing view. A screenshot or recording shows `CaptureShieldNote`
/// in its place; on the phone itself nothing changes. If a future iOS lays the field out differently and the
/// drawing view can't be found, the content is shown unprotected rather than not at all.
extension View {
    /// Program sessions use this. Off in debug builds, so UI tests and the screenshot tooling still see them.
    @ViewBuilder
    func captureShielded() -> some View {
        if CaptureShield.isOn {
            CaptureShieldHost(content: self)
        } else {
            self
        }
    }
}

enum CaptureShield {
    static let isOn: Bool = {
        #if DEBUG
        false
        #else
        true
        #endif
    }()
}

extension Notification.Name {
    /// Posted when the screen starts or stops being recorded, mirrored or shown over AirPlay.
    static let dxCaptureChanged = Notification.Name("dxCaptureChanged")
}

/// Whether the screen is being recorded, mirrored or shown over AirPlay right now.
///
/// The shield keeps the picture of a program session out of a recording, but iOS has no way to keep the app's
/// sound out of one, so the lesson audio waits while a recording runs (`LessonNarrator`). Screenshots carry no
/// sound and don't count.
@MainActor @Observable
final class CaptureWatch {
    static let shared = CaptureWatch()
    private(set) var capturing = false
    @ObservationIgnored private var observers: [NSObjectProtocol] = []

    private init() {
        // Recording from Control Centre fires the screen's notification even while the phone is locked with a
        // lesson playing; coming back to the app reads the state again in case a change was missed.
        let names = [UIScreen.capturedDidChangeNotification, UIScene.didActivateNotification,
                     UIScene.willEnterForegroundNotification]
        observers = names.map { name in
            NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { _ in
                MainActor.assumeIsolated { CaptureWatch.shared.refresh() }
            }
        }
        capturing = Self.read()
    }

    func refresh() {
        let now = Self.read()
        guard now != capturing else { return }
        capturing = now
        NotificationCenter.default.post(name: .dxCaptureChanged, object: nil)
    }

    private static func read() -> Bool {
        UIApplication.shared.connectedScenes.contains { scene in
            (scene as? UIWindowScene)?.traitCollection.sceneCaptureState == .active
        }
    }
}

/// Reads the whole environment where the shield sits and hands it on: a hosting controller starts a new
/// hierarchy, which would otherwise lose the model context, the entitlement and the rest.
private struct CaptureShieldHost<Content: View>: View {
    let content: Content
    @Environment(\.self) private var environment

    var body: some View {
        CaptureShieldBridge(content: AnyView(content.environment(\.self, environment)))
            .ignoresSafeArea()
    }
}

private struct CaptureShieldBridge: UIViewControllerRepresentable {
    let content: AnyView

    func makeUIViewController(context: Context) -> CaptureShieldController {
        CaptureShieldController(content: content)
    }

    func updateUIViewController(_ controller: CaptureShieldController, context: Context) {
        controller.host.rootView = content
    }
}

final class CaptureShieldController: UIViewController {
    let host: UIHostingController<AnyView>
    /// Kept alive for as long as the screen is: its drawing view only stays secure while the field exists.
    private let field = UITextField()

    init(content: AnyView) {
        host = UIHostingController(rootView: content)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        // A recording started or stopped while the session is on screen reaches the scene's traits first.
        CaptureWatch.shared.refresh()
        registerForTraitChanges([UITraitSceneCaptureState.self]) { (_: CaptureShieldController, _: UITraitCollection) in
            CaptureWatch.shared.refresh()
        }

        // What a screenshot or a recording shows: it sits behind the content, which the system leaves out.
        let note = UIHostingController(rootView: CaptureShieldNote())
        embed(note, in: view)

        field.isSecureTextEntry = true
        let secure = field.subviews.first { String(describing: type(of: $0)).contains("CanvasView") }
            ?? field.layer.sublayers?.first?.delegate as? UIView
        let container: UIView
        if let secure {
            secure.subviews.forEach { $0.removeFromSuperview() }
            secure.isUserInteractionEnabled = true
            secure.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(secure)
            pin(secure, to: view)
            container = secure
        } else {
            container = view
        }
        host.view.backgroundColor = .clear
        embed(host, in: container)
    }

    private func embed(_ child: UIViewController, in container: UIView) {
        addChild(child)
        child.view.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(child.view)
        pin(child.view, to: container)
        child.didMove(toParent: self)
    }

    private func pin(_ inner: UIView, to outer: UIView) {
        NSLayoutConstraint.activate([
            inner.topAnchor.constraint(equalTo: outer.topAnchor),
            inner.bottomAnchor.constraint(equalTo: outer.bottomAnchor),
            inner.leadingAnchor.constraint(equalTo: outer.leadingAnchor),
            inner.trailingAnchor.constraint(equalTo: outer.trailingAnchor),
        ])
    }
}

/// Seen only in a screenshot or a recording, where the session itself is left out.
private struct CaptureShieldNote: View {
    var body: some View {
        ZStack {
            Color(hex: 0x0E1322).ignoresSafeArea()
            VStack(spacing: 10) {
                Text("DayXero")
                    .font(.title2.weight(.semibold))
                Text("Program sessions can't be captured in screenshots or screen recordings.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .opacity(0.75)
            }
            .foregroundStyle(.white)
            .padding(32)
        }
        .accessibilityHidden(true)
    }
}
