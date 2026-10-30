import Foundation

/// Demo mode, for showing and testing the app: everything unlocked, every program session open at any time,
/// and any Quit Day, past ones included. Only offered in TestFlight and debug builds, never in App Store ones.
enum DemoMode {
    static let key = "dx.demoMode"

    static var isAvailable: Bool {
        #if DEBUG
        true
        #else
        Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
        #endif
    }

    static var isOn: Bool { isAvailable && UserDefaults.standard.bool(forKey: key) }
}
