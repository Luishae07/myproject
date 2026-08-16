import SwiftUI

struct ProjectSettingsView: View {
    let project: Project
    @EnvironmentObject var session: SessionStore
    @State private var env: [KeyValue] = []
    @State private var secrets: [KeyValue] = []
    @State private var autoRestart = false
    @State private var loading = true
    @State private var saving = false
    @State private var errorText: String?

    struct KeyValue: Identifiable { let id = UUID(); var key: String; var value: String }

    var body: some View {
        Form {
            if loading {
                ProgressView()
            } else {
                Section("Environment variables") {
                    ForEach($env) { $kv in
                        HStack {
                            TextField("KEY", text: $kv.key).font(.system(.footnote, design: .monospaced))
                            TextField("value", text: $kv.value).font(.system(.footnote, design: .monospaced))
                        }
                    }
                    .onDelete { env.remove(atOffsets: $0) }
                    Button("Add variable") { env.append(KeyValue(key: "", value: "")) }
                }

                Section("Secrets") {
                    ForEach($secrets) { $kv in
                        HStack {
                            TextField("KEY", text: $kv.key).font(.system(.footnote, design: .monospaced))
                            SecureField("value", text: $kv.value).font(.system(.footnote, design: .monospaced))
                        }
                    }
                    .onDelete { secrets.remove(atOffsets: $0) }
                    Button("Add secret") { secrets.append(KeyValue(key: "", value: "")) }
                }

                Section {
                    Toggle("Auto-restart on crash", isOn: $autoRestart)
                }

                if let errorText {
                    Text(errorText).font(.footnote).foregroundStyle(.red)
                }

                Button {
                    Task { await save() }
                } label: {
                    Text(saving ? "Saving..." : "Save")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .disabled(saving)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private func load() async {
        guard let key = session.apiKey else { return }
        loading = true
        do {
            let settings = try await APIClient.settingsGet(apiKey: key, projectId: project.id)
            env = (settings.env ?? [:]).map { KeyValue(key: $0.key, value: $0.value) }
            autoRestart = settings.auto_restart ?? false
            let secretsDict = try await APIClient.secretsGet(apiKey: key, projectId: project.id)
            secrets = secretsDict.map { KeyValue(key: $0.key, value: $0.value) }
        } catch {
            errorText = error.localizedDescription
        }
        loading = false
    }

    private func save() async {
        guard let key = session.apiKey else { return }
        saving = true
        errorText = nil
        do {
            let envDict = Dictionary(uniqueKeysWithValues: env.filter { !$0.key.isEmpty }.map { ($0.key, $0.value) })
            try await APIClient.settingsSet(apiKey: key, projectId: project.id, env: envDict, autoRestart: autoRestart)
            let secretsDict = Dictionary(uniqueKeysWithValues: secrets.filter { !$0.key.isEmpty && !$0.value.contains("\u{2022}") }.map { ($0.key, $0.value) })
            if !secretsDict.isEmpty {
                try await APIClient.secretsSet(apiKey: key, projectId: project.id, secrets: secretsDict)
            }
        } catch {
            errorText = error.localizedDescription
        }
        saving = false
    }
}
