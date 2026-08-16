import Foundation

enum APIError: Error, LocalizedError {
    case server(String)
    case badResponse
    var errorDescription: String? {
        switch self {
        case .server(let msg): return msg
        case .badResponse: return "Unexpected response."
        }
    }
}

private struct ErrorBody: Decodable { let error: String? }

enum APIClient {
    private static func request<T: Decodable>(
        _ path: String, method: String = "GET", token: String? = nil, json body: [String: Any]? = nil
    ) async throws -> T {
        var req = URLRequest(url: URL(string: API.base + path)!)
        req.httpMethod = method
        if let token { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        if let body {
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw APIError.badResponse }
        if http.statusCode >= 400 {
            if let obj = try? JSONDecoder().decode(ErrorBody.self, from: data) {
                throw APIError.server(obj.error ?? "Request failed (\(http.statusCode))")
            }
            throw APIError.server("Request failed (\(http.statusCode))")
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    static func signup(username: String, password: String) async throws -> LoginResponse {
        try await request("/api/vn/signup", method: "POST", json: ["username": username, "password": password])
    }

    static func login(username: String, password: String) async throws -> LoginResponse {
        try await request("/api/vn/login", method: "POST", json: ["username": username, "password": password])
    }

    static func servers(token: String) async throws -> [NexusServer] {
        let r: ServersResponse = try await request("/api/nexus/servers", token: token)
        return r.servers
    }

    static func channels(token: String, serverID: String) async throws -> [NexusChannel] {
        let r: ChannelsResponse = try await request("/api/nexus/channels/\(serverID)", token: token)
        return r.channels
    }

    static func messages(token: String, channelID: String) async throws -> [NexusMessage] {
        let r: MessagesResponse = try await request("/api/nexus/messages/\(channelID)", token: token)
        return r.messages
    }

    static func sendMessage(token: String, channelID: String, content: String, attachments: [Attachment] = []) async throws -> NexusMessage {
        var body: [String: Any] = ["channel_id": channelID, "content": content]
        if !attachments.isEmpty {
            body["attachments"] = attachments.map { ["type": $0.type, "url": $0.url] }
        }
        return try await request("/api/nexus/messages", method: "POST", token: token, json: body)
    }

    static func react(token: String, messageID: String, emoji: String) async throws -> [Reaction] {
        let r: ReactResponse = try await request("/api/nexus/react", method: "POST", token: token, json: ["message_id": messageID, "emoji": emoji])
        return r.reactions
    }

    static func createPoll(token: String, channelID: String, question: String, options: [String]) async throws -> NexusMessage {
        try await request("/api/nexus/poll/create", method: "POST", token: token, json: ["channel_id": channelID, "question": question, "options": options])
    }

    static func votePoll(token: String, pollID: String, optionIndex: Int) async throws -> Poll {
        try await request("/api/nexus/poll/vote", method: "POST", token: token, json: ["poll_id": pollID, "option_index": optionIndex])
    }

    static func searchGifs(query: String) async throws -> [NexusGif] {
        var comps = URLComponents(string: API.base + "/api/nexus/gifs")!
        comps.queryItems = query.isEmpty ? nil : [URLQueryItem(name: "q", value: query)]
        let (data, _) = try await URLSession.shared.data(from: comps.url!)
        return try JSONDecoder().decode(GifsResponse.self, from: data).gifs
    }

    static func members(token: String, serverID: String) async throws -> [NexusMember] {
        let r: MembersResponse = try await request("/api/nexus/members/\(serverID)", token: token)
        return r.members
    }

    static func dms(token: String) async throws -> [DMConversation] {
        let r: DMsResponse = try await request("/api/nexus/dms", token: token)
        return r.dms
    }
}
