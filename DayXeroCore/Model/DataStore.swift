import Foundation
import SwiftData

/// The SwiftData store, kept in the App Group so the app and its widgets share it.
public enum DataStore {
    public static let appGroup = "group.app.dayxero"

    public static var schema: Schema {
        Schema([
            UserProfile.self, ProductUse.self, Reason.self,
            ProgramProgress.self, DayCompletion.self,
            LogEntry.self, Pledge.self, CheckIn.self,
            NRTPlan.self, NRTStep.self,
        ])
    }

    /// - Parameter inMemory: true for previews and tests.
    public static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let configuration: ModelConfiguration
        if inMemory {
            configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        } else {
            configuration = ModelConfiguration(schema: schema, groupContainer: .identifier(appGroup))
        }
        return try ModelContainer(for: schema, configurations: configuration)
    }
}
