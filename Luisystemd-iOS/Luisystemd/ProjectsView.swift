import SwiftUI

struct ProjectsView: View {
    @EnvironmentObject var session: SessionStore
    @State private var projects: [Project] = []
    @State private var loading = true
    @State private var errorText: String?
    @State private var showingNewProject = false
    @State private var newProjectName = ""

    var body: some View {
        NavigationStack {
            Group {
                if loading {
                    ProgressView()
                } else if let errorText {
                    ContentUnavailableView(errorText, systemImage: "exclamationmark.triangle")
                } else if projects.isEmpty {
                    ContentUnavailableView("No projects yet", systemImage: "folder", description: Text("Tap + to create one."))
                } else {
                    List {
                        ForEach(projects) { project in
                            NavigationLink(value: project) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(project.name).font(.headline)
                                    if let updated = project.updated_at {
                                        Text("Updated \(updated)").font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .onDelete(perform: delete)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Projects")
            .navigationDestination(for: Project.self) { project in
                ProjectDetailView(project: project)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingNewProject = true } label: { Image(systemName: "plus") }
                }
            }
            .refreshable { await load() }
            .task { await load() }
            .alert("New project", isPresented: $showingNewProject) {
                TextField("Project name", text: $newProjectName)
                Button("Cancel", role: .cancel) { newProjectName = "" }
                Button("Create") { Task { await create() } }
            }
        }
    }

    private func load() async {
        guard let key = session.apiKey else { return }
        loading = true
        errorText = nil
        do {
            projects = try await APIClient.projects(apiKey: key)
        } catch {
            errorText = error.localizedDescription
        }
        loading = false
    }

    private func create() async {
        guard let key = session.apiKey, !newProjectName.isEmpty else { return }
        do {
            let project = try await APIClient.createProject(apiKey: key, name: newProjectName)
            projects.insert(project, at: 0)
        } catch {
            errorText = error.localizedDescription
        }
        newProjectName = ""
    }

    private func delete(at offsets: IndexSet) {
        guard let key = session.apiKey else { return }
        let toDelete = offsets.map { projects[$0] }
        projects.remove(atOffsets: offsets)
        Task {
            for project in toDelete {
                try? await APIClient.deleteProject(apiKey: key, projectId: project.id)
            }
        }
    }
}
