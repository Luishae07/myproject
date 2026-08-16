import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            ProjectsView()
                .tabItem { Label("Projects", systemImage: "folder.fill") }
            GalleryView()
                .tabItem { Label("Gallery", systemImage: "sparkles") }
            AccountView()
                .tabItem { Label("Account", systemImage: "person.crop.circle") }
        }
    }
}
