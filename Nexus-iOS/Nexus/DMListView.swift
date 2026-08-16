import SwiftUI

struct DMListView: View {
    @EnvironmentObject var session: SessionStore
    @State private var dms: [DMConversation] = []
    @State private var loading = true

    var body: some View {
        NavigationStack {
            Group {
                if loading {
                    ProgressView()
                } else if dms.isEmpty {
                    ContentUnavailableView("No direct messages yet", systemImage: "bubble.left")
                } else {
                    List(dms) { dm in
                        NavigationLink {
                            ChannelMessagesView(channel: NexusChannel(id: dm.channel_id, name: dm.user, topic: nil, position: nil, type: "dm"))
                        } label: {
                            HStack(spacing: 12) {
                                ServerIconView(icon: dm.avatar, name: dm.user, size: 40)
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 6) {
                                        Text(dm.user).font(.subheadline.weight(.semibold))
                                        if dm.online == true {
                                            Circle().fill(.green).frame(width: 8, height: 8)
                                        }
                                    }
                                    if let last = dm.last, !last.isEmpty {
                                        Text(last).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Direct Messages")
            .refreshable { await load() }
            .task { await load() }
        }
    }

    private func load() async {
        guard let token = session.token else { return }
        loading = true
        dms = (try? await APIClient.dms(token: token)) ?? []
        loading = false
    }
}
