import SwiftUI

struct FileBrowserView: View {
    let project: Project
    let path: String
    @EnvironmentObject var session: SessionStore
    @State private var items: [FSItem] = []
    @State private var loading = true
    @State private var errorText: String?
    @State private var showingNewFile = false
    @State private var showingNewFolder = false
    @State private var newName = ""

    var body: some View {
        Group {
            if loading {
                ProgressView()
            } else if let errorText {
                ContentUnavailableView(errorText, systemImage: "exclamationmark.triangle")
            } else if items.isEmpty {
                ContentUnavailableView("Empty folder", systemImage: "folder")
            } else {
                List {
                    ForEach(items) { item in
                        if item.is_dir {
                            NavigationLink {
                                FileBrowserView(project: project, path: joined(item.name))
                            } label: {
                                Label(item.name, systemImage: "folder.fill")
                            }
                        } else {
                            NavigationLink {
                                FileEditorView(project: project, path: joined(item.name))
                            } label: {
                                HStack {
                                    Label(item.name, systemImage: "doc.text")
                                    Spacer()
                                    Text(ByteCountFormatter.string(fromByteCount: Int64(item.size), countStyle: .file))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .onDelete(perform: delete)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(path.isEmpty ? "Files" : (path as NSString).lastPathComponent)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("New file") { showingNewFile = true }
                    Button("New folder") { showingNewFolder = true }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task { await load() }
        .alert("New file", isPresented: $showingNewFile) {
            TextField("filename.py", text: $newName)
            Button("Cancel", role: .cancel) { newName = "" }
            Button("Create") { Task { await createFile() } }
        }
        .alert("New folder", isPresented: $showingNewFolder) {
            TextField("folder name", text: $newName)
            Button("Cancel", role: .cancel) { newName = "" }
            Button("Create") { Task { await createFolder() } }
        }
    }

    private func joined(_ name: String) -> String {
        path.isEmpty ? name : "\(path)/\(name)"
    }

    private func load() async {
        guard let key = session.apiKey else { return }
        loading = true
        errorText = nil
        do {
            items = try await APIClient.fsList(apiKey: key, projectId: project.id, path: path)
        } catch {
            errorText = error.localizedDescription
        }
        loading = false
    }

    private func createFile() async {
        guard let key = session.apiKey, !newName.isEmpty else { return }
        do {
            try await APIClient.fsWrite(apiKey: key, projectId: project.id, path: joined(newName), content: "")
            await load()
        } catch {
            errorText = error.localizedDescription
        }
        newName = ""
    }

    private func createFolder() async {
        guard let key = session.apiKey, !newName.isEmpty else { return }
        do {
            try await APIClient.fsMkdir(apiKey: key, projectId: project.id, path: joined(newName))
            await load()
        } catch {
            errorText = error.localizedDescription
        }
        newName = ""
    }

    private func delete(at offsets: IndexSet) {
        guard let key = session.apiKey else { return }
        let toDelete = offsets.map { items[$0] }
        items.remove(atOffsets: offsets)
        Task {
            for item in toDelete {
                try? await APIClient.fsDelete(apiKey: key, projectId: project.id, path: joined(item.name))
            }
        }
    }
}
