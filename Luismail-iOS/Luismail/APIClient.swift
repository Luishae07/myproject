import Foundation

/// Thin JSON client for the webbridge -- same REST surface the web frontend
/// uses (register/login/send/inbox/delete/summarize/gmail). The webbridge
/// (not this app) speaks the real LSAD protocol to the Go server and
/// handles the X25519 decryption server-side using the password sent with
/// each request, same trust model as the browser client.
enum APIError: Error, LocalizedError {
    case server(String)
    case decode

    var errorDescription: String? {
        switch self {
        case .server(let msg): return msg
        case .decode: return "Couldn't parse server response"
        }
    }
}

enum APIClient {
    private static func post<T: Decodable>(_ path: String, body: [String: Any]) async throws -> T {
        guard let url = URL(string: webbridgeBaseURL + path) else { throw APIError.server("bad URL") }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: req)
        guard let decoded = try? JSONDecoder().decode(T.self, from: data) else {
            throw APIError.decode
        }
        return decoded
    }

    static func register(address: String, password: String) async throws {
        let resp: SimpleOKResponse = try await post("/api/register", body: ["address": address, "password": password])
        if !resp.ok { throw APIError.server(resp.error ?? "register failed") }
    }

    static func login(address: String, password: String) async throws {
        let resp: SimpleOKResponse = try await post("/api/login", body: ["address": address, "password": password])
        if !resp.ok { throw APIError.server(resp.error ?? "login failed") }
    }

    static func inbox(address: String, password: String) async throws -> [LuismailMessage] {
        let resp: InboxResponse = try await post("/api/inbox", body: ["address": address, "password": password])
        if !resp.ok { throw APIError.server(resp.error ?? "fetch failed") }
        return resp.messages
    }

    static func send(address: String, password: String, to: String, subject: String, body: String) async throws {
        let resp: SimpleOKResponse = try await post("/api/send", body: [
            "address": address, "password": password, "to": to, "subject": subject, "body": body,
        ])
        if !resp.ok { throw APIError.server(resp.error ?? "send failed") }
    }

    static func deleteMessage(address: String, password: String, id: Int) async throws {
        let resp: SimpleOKResponse = try await post("/api/delete_message", body: ["address": address, "password": password, "id": id])
        if !resp.ok { throw APIError.server(resp.error ?? "delete failed") }
    }

    static func deleteAccount(address: String, password: String) async throws {
        let resp: SimpleOKResponse = try await post("/api/delete_account", body: ["address": address, "password": password])
        if !resp.ok { throw APIError.server(resp.error ?? "delete account failed") }
    }

    static func summarize(address: String, password: String) async throws -> String {
        let resp: SummaryResponse = try await post("/api/summarize", body: ["address": address, "password": password])
        if !resp.ok { throw APIError.server(resp.error ?? "summarize failed") }
        return resp.summary ?? ""
    }

    static func gmailReply(address: String, password: String, meta: GmailReplyMeta, body: String) async throws {
        let resp: SimpleOKResponse = try await post("/api/gmail/reply", body: [
            "address": address, "password": password,
            "threadId": meta.threadId, "messageId": meta.messageId,
            "to": meta.to, "subject": meta.subject, "body": body,
        ])
        if !resp.ok { throw APIError.server(resp.error ?? "gmail reply failed") }
    }

    static func connectGmail(address: String, password: String) async throws -> URL {
        let resp: GmailConnectResponse = try await post("/api/gmail/connect", body: ["address": address, "password": password])
        guard resp.ok, let urlStr = resp.url, let url = URL(string: urlStr) else {
            throw APIError.server(resp.error ?? "gmail connect failed")
        }
        return url
    }

    static func unspam(address: String, password: String, id: Int) async throws {
        let resp: SimpleOKResponse = try await post("/api/unspam", body: ["address": address, "password": password, "id": id])
        if !resp.ok { throw APIError.server(resp.error ?? "unspam failed") }
    }

    /// Nexus's crawled-GIF search -- same endpoint the web frontend's GIF
    /// picker uses. No auth needed, it's a public read-only search.
    static func searchGifs(query: String) async throws -> [NexusGif] {
        var comps = URLComponents(string: nexusBaseURL + "/api/nexus/gifs")!
        comps.queryItems = [URLQueryItem(name: "q", value: query)]
        guard let url = comps.url else { throw APIError.server("bad URL") }
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let decoded = try? JSONDecoder().decode(NexusGifResponse.self, from: data) else {
            throw APIError.decode
        }
        return decoded.gifs
    }
}
