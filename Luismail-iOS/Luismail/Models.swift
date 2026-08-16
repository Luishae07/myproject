import Foundation

// Addresses look like "user/domain" -- not "user@domain". See LSAD protocol
// docs in the main Luismail repo (lsad_server_go / webbridge.py).
let luismailDomain = "luismail.pages.dev"

// Same webbridge/WS-bridge/Nexus tunnel URLs the web frontend uses -- all
// rotate if their cloudflared process restarts, same caveat as everywhere
// else in this project.
let webbridgeBaseURL = "https://doctors-adequate-chem-area.trycloudflare.com"
let wsBaseURL = "wss://respected-character-football-instead.trycloudflare.com"
let nexusBaseURL = "https://stevens-predictions-get-feet.trycloudflare.com"

struct LuismailMessage: Identifiable, Decodable {
    let id: Int
    let from: String
    let subject: String
    let body: String
    let ts: Double
    let read: Bool
    let spam: Bool

    var date: Date { Date(timeIntervalSince1970: ts) }

    /// Gmail-bridged messages carry a hidden trailer with the original
    /// Gmail thread/message id + sender, used to send a real threaded
    /// reply back through Gmail. Stripped before display.
    var cleanBodyAndGmailMeta: (String, GmailReplyMeta?) {
        let marker = "<!--LUISMAIL_GMAIL_META-->"
        let parts = body.components(separatedBy: marker)
        guard parts.count >= 3,
              let data = parts[1].data(using: .utf8),
              let meta = try? JSONDecoder().decode(GmailReplyMeta.self, from: data) else {
            return (body, nil)
        }
        let clean = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
        return (clean, meta)
    }

    static let htmlBodyMarker = "LUISMAIL_HTML_V1"
}

struct GmailReplyMeta: Decodable {
    let threadId: String
    let messageId: String
    let to: String
    let subject: String
}

struct InboxResponse: Decodable {
    let ok: Bool
    let messages: [LuismailMessage]
    let error: String?
}

struct SimpleOKResponse: Decodable {
    let ok: Bool
    let error: String?
}

struct SummaryResponse: Decodable {
    let ok: Bool
    let summary: String?
    let error: String?
}

struct GmailConnectResponse: Decodable {
    let ok: Bool
    let url: String?
    let error: String?
}

// ---- Nexus GIF picker (same crawled-GIF backend the web frontend uses) ----
struct NexusGif: Decodable, Identifiable {
    let alt: String
    let vid: String
    var id: String { vid }
    var fullURL: URL? { URL(string: nexusBaseURL + vid) }
}

struct NexusGifResponse: Decodable {
    let gifs: [NexusGif]
}

// ---- WebSocket push payloads from the WS bridge ----
struct WSInboxPayload: Decodable {
    let type: String
    let messages: [LuismailMessage]?
    let error: String?
}
