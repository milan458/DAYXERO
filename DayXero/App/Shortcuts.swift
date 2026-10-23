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
    }
}
