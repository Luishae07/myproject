import SwiftUI

struct TerminalView: View {
    let project: Project
    @EnvironmentObject var session: SessionStore
    @State private var command = ""
    @State private var lines: [String] = []
    @State private var running = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        ForEach(Array(lines.enumerated()), id: \.offset) { i, line in
                            Text(line)
                                .font(.system(.footnote, design: .monospaced))
                                .foregroundStyle(.green)
                                .id(i)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                }
                .background(Color.black)
                .onChange(of: lines.count) {
                    if let last = lines.indices.last {
                        proxy.scrollTo(last, anchor: .bottom)
                    }
                }
            }

            HStack(spacing: 8) {
                TextField("Run a command", text: $command)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(10)
                    .glassEffect(in: .rect(cornerRadius: 10))
                    .onSubmit { Task { await run() } }
                Button {
                    Task { await run() }
                } label: {
                    Image(systemName: running ? "stop.fill" : "play.fill")
                }
                .buttonStyle(.glassProminent)
                .disabled(command.isEmpty || running)
            }
            .padding(10)
        }
        .navigationTitle("Terminal")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func run() async {
        guard let key = session.apiKey, !command.isEmpty else { return }
        lines.append("$ \(command)")
        running = true
        let cmd = command
        command = ""
        do {
            for try await event in APIClient.terminalStream(apiKey: key, projectId: project.id, command: cmd) {
                if event.type == "line", let text = event.t {
                    lines.append(text)
                } else if event.type == "exit" {
                    lines.append("[exited with code \(event.code ?? 0)]")
                }
            }
        } catch {
            lines.append("[error: \(error.localizedDescription)]")
        }
        running = false
    }
}
