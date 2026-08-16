import Foundation

/// Thin wrapper over URLSessionWebSocketTask against /api/nexus/ws -- the
/// real-time transport this backend deliberately moved to from SSE/long-poll
/// specifically because cloudflared quick tunnels buffer whole SSE bodies
/// but let WebSocket frames stream through untouched (same reasoning as
/// Luismail's realtime and Nexus's own JS frontend).
@MainActor
final class NexusSocket: ObservableObject {
    @Published var lastEvent: WSEvent?
    @Published var onlineUsers: Set<String> = []

    private var task: URLSessionWebSocketTask?
    private var listenTask: Task<Void, Never>?
    private var reconnectTask: Task<Void, Never>?
    private var token: String?

    func connect(token: String) {
        self.token = token
        guard let url = URL(string: "\(API.wsBase)/api/nexus/ws?token=\(token)") else { return }
        let socketTask = URLSession.shared.webSocketTask(with: url)
        self.task = socketTask
        socketTask.resume()
        listen()
    }

    func disconnect() {
        reconnectTask?.cancel()
        listenTask?.cancel()
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
    }

    private func listen() {
        listenTask?.cancel()
        listenTask = Task {
            guard let task else { return }
            while !Task.isCancelled {
                do {
                    let message = try await task.receive()
                    switch message {
                    case .string(let text):
                        handle(text)
                    case .data(let data):
                        if let text = String(data: data, encoding: .utf8) { handle(text) }
                    @unknown default:
                        break
                    }
                } catch {
                    scheduleReconnect()
                    return
                }
            }
        }
    }

    private func handle(_ text: String) {
        guard let data = text.data(using: .utf8),
              let event = try? JSONDecoder().decode(WSEvent.self, from: data) else { return }
        if event.type == "presence", let online = event.online {
            onlineUsers = Set(online)
        }
        lastEvent = event
    }

    private func scheduleReconnect() {
        guard let token else { return }
        reconnectTask?.cancel()
        reconnectTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled else { return }
            connect(token: token)
        }
    }
}
