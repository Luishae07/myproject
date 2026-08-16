import Foundation

enum API {
    static let base = "https://stevens-predictions-get-feet.trycloudflare.com"
    static var wsBase: String { base.replacingOccurrences(of: "https://", with: "wss://") }
}

struct NexusServer: Identifiable, Decodable, Hashable {
    let id: String
    let name: String
    let icon: String?
    let invite: String?
    let owner: String?
}
struct ServersResponse: Decodable { let servers: [NexusServer] }

struct NexusChannel: Identifiable, Decodable, Hashable {
    let id: String
    let name: String
    let topic: String?
    let position: Int?
    let type: String?

    var iconName: String {
        switch type {
        case "announcement": return "megaphone.fill"
        case "forum": return "bubble.left.and.bubble.right.fill"
        case "voice": return "speaker.wave.2.fill"
        default: return "number"
        }
    }
}
struct ChannelsResponse: Decodable { let channels: [NexusChannel] }

struct Attachment: Decodable, Hashable {
    let type: String
    let url: String
}

struct NexusMessage: Identifiable, Decodable, Hashable {
    let id: String
    let author: String
    let content: String?
    let attachments: String?
    let created_at: String?
    let edited: Int?

    var attachmentList: [Attachment] {
        guard let attachments, let data = attachments.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([Attachment].self, from: data)) ?? []
    }
}
struct MessagesResponse: Decodable { let messages: [NexusMessage] }

struct NexusMember: Identifiable, Decodable, Hashable {
    var id: String { username }
    let username: String
    let role: String?
    let avatar: String?
    let color: String?
    let bio: String?
    let status: String?
    let pronouns: String?
    let online: Bool?
}
struct MembersResponse: Decodable { let members: [NexusMember] }

struct DMConversation: Identifiable, Decodable, Hashable {
    var id: String { channel_id }
    let channel_id: String
    let user: String
    let last: String?
    let avatar: String?
    let color: String?
    let online: Bool?
}
struct DMsResponse: Decodable { let dms: [DMConversation] }

struct LoginResponse: Decodable { let token: String; let username: String }

// MARK: - WebSocket event envelope (a loose bag of fields since event
// shape varies by `type` -- message/presence/typing/dm/ready -- mirrors
// how the JS frontend just switches on `type` and reads what it needs).
struct WSEvent: Decodable {
    let type: String
    let channel_id: String?
    let message: NexusMessage?
    let online: [String]?
}
