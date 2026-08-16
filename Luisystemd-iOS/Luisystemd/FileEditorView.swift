import SwiftUI

struct FileEditorView: View {
    let project: Project
    let path: String
    @EnvironmentObject var session: SessionStore
    @State private var content = ""
    @State private var loading = true
    @State private var saving = false
    @State private var errorText: String?
    @State private var dirty = false

    var body: some View {
        Group {
            if loading {
                ProgressView()
            } else if let errorText {
                ContentUnavailableView(errorText, systemImage: "exclamationmark.triangle")
            } else {
                TextEditor(text: $content)
                    .font(.system(.footnote, design: .monospaced))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onChange(of: content) { dirty = true }
            }
        }
        .navigationTitle((path as NSString).lastPathComponent)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await save() }
                } label: {
                    if saving { ProgressView() } else { Text(dirty ? "Save" : "Saved") }
                }
                .disabled(!dirty || saving)
            }
        }
        .task { await load() }
    }

    private func load() async {
        guard let key = session.apiKey else { return }
        loading = true
        errorText = nil
        do {
            content = try await APIClient.fsRead(apiKey: key, projectId: project.id, path: path)
            dirty = false
        } catch {
            errorText = error.localizedDescription
        }
        loading = false
    }

    private func save() async {
        guard let key = session.apiKey else { return }
        saving = true
        do {
            try await APIClient.fsWrite(apiKey: key, projectId: project.id, path: path, content: content)
            dirty = false
        } catch {
            errorText = error.localizedDescription
        }
        saving = false
    }
}
