import Foundation

/// Whether there's an active plan, shared with the widget extension and Siri (the hard paywall, 16 Nov 2026).
/// The app writes it whenever the answer changes; actions that work without opening the app read it, so they
/// can't be used without a plan either. Unset means no plan.
public enum PlanGate {
    private static let key = "dx.planActive"
    private static var defaults: UserDefaults { UserDefaults(suiteName: DataStore.appGroup) ?? .standard }

    public static var isActive: Bool {
        get { defaults.bool(forKey: key) }
        set { defaults.set(newValue, forKey: key) }
    }
}
