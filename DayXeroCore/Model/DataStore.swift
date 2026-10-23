import Foundation
import SwiftData

/// The SwiftData store, kept in the App Group so the app and its widgets share it.
public enum DataStore {
    public static let appGroup = "group.in.dayxero.app"

    public static var schema: Schema {
        Schema([
            UserProfile.self, ProductUse.self, Reason.self,
            ProgramProgress.self, DayCompletion.self,
            LogEntry.self, Pledge.self, CheckIn.self,
            NRTPlan.self, NRTStep.self,
            IfThenPlan.self, WeeklyCheckIn.self,
        ])
    }

    /// - Parameter inMemory: true for previews and tests.
    public static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let configuration: ModelConfiguration
        if inMemory {
            configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        } else if FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) != nil {
            configuration = ModelConfiguration(schema: schema, groupContainer: .identifier(appGroup))
        } else {
            // Unsigned builds (CI, some simulator runs) have no App Group; keep the store in the app's own container.
            configuration = ModelConfiguration(schema: schema, groupContainer: .none)
        }
        return try ModelContainer(for: schema, configurations: configuration)
    }
}
