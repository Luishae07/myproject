import SwiftUI

struct ServerListView: View {
    @EnvironmentObject var session: SessionStore
    @State private var servers: [NexusServer] = []
    @State private var loading = true
    @State private var errorText: String?

    var body: some View {
        NavigationStack {
            Group {
                if loading {
                    ProgressView()
                } else if let errorText {
                    ContentUnavailableView(errorText, systemImage: "exclamationmark.triangle")
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(servers) { server in
                                NavigationLink(value: server) {
                                    HStack(spacing: 14) {
                                        ServerIconView(icon: server.icon, name: server.name)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(server.name)
                                                .font(.headline)
                                                .foregroundStyle(.primary)
                                            if server.id == "lobby" {
                                                Text("Default").font(.caption).foregroundStyle(.secondary)
                                            }
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundStyle(.tertiary)
                                    }
                                    .padding(12)
                                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Servers")
            .navigationDestination(for: NexusServer.self) { server in
                ChannelListView(server: server)
            }
            .refreshable { await load() }
            .task { await load() }
        }
    }

    private func load() async {
        guard let token = session.token else { return }
        loading = true
        errorText = nil
        do {
            servers = try await APIClient.servers(token: token)
        } catch {
            errorText = error.localizedDescription
        }
        loading = false
    }
}

/// Server icon -- a Discord-style avatar that's either a small emoji, a
/// full image URL, or (fallback) the server's initial letter, matching
/// what the web frontend's icon field can hold.
struct ServerIconView: View {
    let icon: String?
    let name: String
    var size: CGFloat = 44

    var body: some View {
        Group {
            if let icon, icon.hasPrefix("http"), let url = URL(string: icon) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    fallback
                }
            } else if let icon, !icon.isEmpty {
                Text(icon).font(.system(size: size * 0.5))
            } else {
                fallback
            }
        }
        .frame(width: size, height: size)
        .background(Color.accentColor.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: size * 0.3))
    }

    private var fallback: some View {
        Text(String(name.prefix(1)).uppercased())
            .font(.system(size: size * 0.4, weight: .bold))
            .foregroundStyle(Color.accentColor)
    }
}
