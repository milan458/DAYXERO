import AppIntents

/// Siri and Shortcuts phrases (S6.5). Apple requires the app name in each phrase.
struct DayXeroShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartCravingSOSIntent(),
            phrases: [
                "I'm having a craving in \(.applicationName)",
                "\(.applicationName) SOS",
                "Start Craving SOS in \(.applicationName)",
            ],
            shortTitle: "Craving SOS",
            systemImageName: "flame"
        )
        AppShortcut(
            intent: LogUseIntent(),
            phrases: [
                "Log a \(\.$product) in \(.applicationName)",
                "Log \(\.$product) in \(.applicationName)",
            ],
            shortTitle: "Log a use",
            systemImageName: "plus.circle"
        )
        AppShortcut(
            intent: LogWaterIntent(),
            phrases: ["Log water in \(.applicationName)", "Log a glass of water in \(.applicationName)"],
            shortTitle: "Log water",
            systemImageName: "drop"
        )
        AppShortcut(
            intent: StartBreathingIntent(),
            phrases: ["Breathe with \(.applicationName)"],
            shortTitle: "Breathe",
            systemImageName: "circle.circle"
        )
        AppShortcut(
            intent: LogCravingIntent(),
            phrases: ["Log a craving in \(.applicationName)"],
            shortTitle: "Log a craving",
            systemImageName: "square.and.pencil"
        )
    }
}
