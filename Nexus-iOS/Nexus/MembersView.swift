import SwiftUI

struct MembersView: View {
    let server: NexusServer
    @EnvironmentObject var session: SessionStore
    @Environment(\.dismiss) private var dismiss
    @State private var members: [NexusMember] = []
    @State private var loading = true

    var body: some View {
        NavigationStack {
            Group {
                if loading {
                    ProgressView()
                } else {
                    List(members) { member in
                        HStack(spacing: 12) {
                            AvatarView(username: member.username, avatarURL: member.avatar, size: 36)
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(member.username).font(.subheadline.weight(.medium))
                                    if member.online == true {
                                        Circle().fill(.green).frame(width: 8, height: 8)
                                    }
                                }
                                if let role = member.role, role != "member" {
                                    Text(role.capitalized).font(.caption2).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Members")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task { await load() }
        }
    }

    private func load() async {
        guard let token = session.token else { return }
        loading = true
        members = (try? await APIClient.members(token: token, serverID: server.id)) ?? []
        loading = false
    }
}
