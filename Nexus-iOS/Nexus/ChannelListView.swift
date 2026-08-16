import SwiftUI

struct ChannelListView: View {
    let server: NexusServer
    @EnvironmentObject var session: SessionStore
    @State private var channels: [NexusChannel] = []
    @State private var loading = true
    @State private var errorText: String?
    @State private var showingMembers = false

    var body: some View {
        Group {
            if loading {
                ProgressView()
            } else if let errorText {
                ContentUnavailableView(errorText, systemImage: "exclamationmark.triangle")
            } else {
                List(channels) { channel in
                    NavigationLink(value: channel) {
                        Label(channel.name, systemImage: channel.iconName)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(server.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: NexusChannel.self) { channel in
            ChannelMessagesView(channel: channel)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingMembers = true } label: { Image(systemName: "person.2.fill") }
            }
        }
        .sheet(isPresented: $showingMembers) {
            MembersView(server: server)
        }
        .task { await load() }
    }

    private func load() async {
        guard let token = session.token else { return }
        loading = true
        errorText = nil
        do {
            channels = try await APIClient.channels(token: token, serverID: server.id)
        } catch {
            errorText = error.localizedDescription
        }
        loading = false
    }
}
