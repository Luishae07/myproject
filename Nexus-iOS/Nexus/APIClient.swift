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
            struct ErrorBody: Decodable { let error: String? }
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

    static func sendMessage(token: String, channelID: String, content: String) async throws -> NexusMessage {
        try await request("/api/nexus/messages", method: "POST", token: token, json: ["channel_id": channelID, "content": content])
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
