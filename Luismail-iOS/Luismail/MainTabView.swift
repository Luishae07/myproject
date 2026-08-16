import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var session: SessionStore

    var body: some View {
        TabView {
            Tab("Inbox", systemImage: "tray.fill") {
                InboxView()
            }
            Tab("Compose", systemImage: "square.and.pencil") {
                ComposeView()
            }
            Tab("Spam", systemImage: "xmark.shield.fill") {
                SpamView()
            }
            .badge(session.spamCount)
            Tab("Settings", systemImage: "gearshape.fill") {
                SettingsView()
            }
        }
        // iOS 26 TabView already renders its bar with Liquid Glass by
        // default -- no extra modifiers needed for that part.
    }
}
