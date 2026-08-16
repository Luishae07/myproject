import SwiftUI

struct ProjectDetailView: View {
    let project: Project

    var body: some View {
        List {
            Section {
                NavigationLink {
                    FileBrowserView(project: project, path: "")
                } label: {
                    Label("Files", systemImage: "folder.fill")
                }
                NavigationLink {
                    TerminalView(project: project)
                } label: {
                    Label("Terminal", systemImage: "terminal.fill")
                }
                NavigationLink {
                    DeployView(project: project)
                } label: {
                    Label("Deploy", systemImage: "arrow.up.forward.app.fill")
                }
            }
            Section {
                NavigationLink {
                    ProjectSettingsView(project: project)
                } label: {
                    Label("Settings & Secrets", systemImage: "gearshape.fill")
                }
                NavigationLink {
                    JobsView(project: project)
                } label: {
                    Label("Scheduled Jobs", systemImage: "clock.arrow.circlepath")
                }
            }
        }
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
