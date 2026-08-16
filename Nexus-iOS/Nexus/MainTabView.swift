import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var session: SessionStore
    @StateObject private var socket = NexusSocket()

    var body: some View {
        TabView {
            ServerListView()
                .tabItem { Label("Servers", systemImage: "server.rack") }
            DMListView()
                .tabItem { Label("DMs", systemImage: "bubble.left.fill") }
            AccountView()
                .tabItem { Label("Account", systemImage: "person.crop.circle") }
        }
        .environmentObject(socket)
        .onAppear {
            if let token = session.token { socket.connect(token: token) }
        }
        .onDisappear { socket.disconnect() }
    }
}
