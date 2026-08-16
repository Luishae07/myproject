import SwiftUI

@main
struct LuismailApp: App {
    @StateObject private var session = SessionStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
                .onAppear {
                    NotificationManager.requestAuthorization()
                    session.resumeIfLoggedIn()
                }
        }
    }
}
