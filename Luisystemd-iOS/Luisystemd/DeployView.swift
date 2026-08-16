import SwiftUI

struct DeployView: View {
    let project: Project
    @EnvironmentObject var session: SessionStore
    @State private var deploying = false
    @State private var url: String?
    @State private var logs = ""
    @State private var errorText: String?

    var body: some View {
        Form {
            Section {
                if let url {
                    Link(url, destination: URL(string: url) ?? URL(string: API.base)!)
                        .font(.footnote.monospaced())
                }
                Button {
                    Task { await deploy() }
                } label: {
                    Text(deploying ? "Deploying..." : "Deploy")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .disabled(deploying)

                Button(role: .destructive) {
                    Task { await undeploy() }
                } label: {
                    Text("Stop").frame(maxWidth: .infinity)
                }
                .disabled(deploying)

                if let errorText {
                    Text(errorText).font(.footnote).foregroundStyle(.red)
                }
            }

            Section("Logs") {
                Text(logs.isEmpty ? "No logs yet." : logs)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
            }
        }
        .navigationTitle("Deploy")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await refreshLogs() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .task { await refreshLogs() }
    }

    private func deploy() async {
        guard let key = session.apiKey else { return }
        deploying = true
        errorText = nil
        do {
            let resp = try await APIClient.deploy(apiKey: key, projectId: project.id)
            if let error = resp.error {
                errorText = error
            } else {
                url = resp.url
            }
        } catch {
            errorText = error.localizedDescription
        }
        deploying = false
        await refreshLogs()
    }

    private func undeploy() async {
        guard let key = session.apiKey else { return }
        do {
            try await APIClient.undeploy(apiKey: key, projectId: project.id)
            url = nil
        } catch {
            errorText = error.localizedDescription
        }
    }

    private func refreshLogs() async {
        guard let key = session.apiKey else { return }
        logs = (try? await APIClient.deployLogs(apiKey: key, projectId: project.id)) ?? ""
    }
}
