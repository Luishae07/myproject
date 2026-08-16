import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            Tab("Inbox", systemImage: "tray.fill") {
                InboxView()
            }
            Tab("Compose", systemImage: "square.and.pencil") {
                ComposeView()
            }
            Tab("Settings", systemImage: "gearshape.fill") {
                SettingsView()
            }
        }
        // iOS 26 TabView already renders its bar with Liquid Glass by
        // default -- no extra modifiers needed for that part.
    }
}
