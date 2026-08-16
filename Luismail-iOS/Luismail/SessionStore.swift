import Foundation
import WidgetKit

@MainActor
final class SessionStore: ObservableObject {
    @Published var address: String?
    @Published var password: String?
    @Published var messages: [LuismailMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    var isLoggedIn: Bool { address != nil && password != nil }
    var unreadCount: Int { messages.filter { !$0.read && !$0.spam }.count }
    var spamCount: Int { messages.filter { $0.spam }.count }

    private let addressKey = "luismail_address"
    private let passwordKey = "luismail_password"
    // Widget extensions run in a separate process and can't see the app's
    // UserDefaults.standard -- an App Group suite is the shared storage
    // both processes can read/write.
    private let appGroupID = "group.com.luishae.luismail"
    private var sharedDefaults: UserDefaults? { UserDefaults(suiteName: appGroupID) }

    private var webSocketTask: URLSessionWebSocketTask?
    private var wsReconnectTask: Task<Void, Never>?

    init() {
        // Simple UserDefaults persistence for now -- a production build
        // should move this to the Keychain instead.
        address = UserDefaults.standard.string(forKey: addressKey)
        password = UserDefaults.standard.string(forKey: passwordKey)
    }

    func login(username: String, password: String) async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        let fullAddress = "\(username)/\(luismailDomain)"
        do {
            try await APIClient.login(address: fullAddress, password: password)
            persist(address: fullAddress, password: password)
            await refreshInbox()
            connectRealtime()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func register(username: String, password: String) async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        let fullAddress = "\(username)/\(luismailDomain)"
        do {
            try await APIClient.register(address: fullAddress, password: password)
            persist(address: fullAddress, password: password)
            await refreshInbox()
            connectRealtime()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Called once at app launch if a session was already persisted, so a
    /// relaunch reconnects the WebSocket without requiring a fresh login.
    func resumeIfLoggedIn() {
        guard isLoggedIn else { return }
        Task {
            await refreshInbox()
            connectRealtime()
        }
    }

    func logout() {
        disconnectRealtime()
        address = nil
        password = nil
        messages = []
        UserDefaults.standard.removeObject(forKey: addressKey)
        UserDefaults.standard.removeObject(forKey: passwordKey)
        sharedDefaults?.removeObject(forKey: "luismail.address")
        sharedDefaults?.removeObject(forKey: "luismail.password")
        WidgetCenter.shared.reloadAllTimelines()
    }

    func refreshInbox() async {
        guard let address, let password else { return }
        do {
            messages = try await APIClient.inbox(address: address, password: password).sorted { $0.ts > $1.ts }
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func send(to: String, subject: String, body: String) async throws {
        guard let address, let password else { return }
        try await APIClient.send(address: address, password: password, to: to, subject: subject, body: body)
    }

    func delete(id: Int) async {
        guard let address, let password else { return }
        do {
            try await APIClient.deleteMessage(address: address, password: password, id: id)
            messages.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func unspam(id: Int) async {
        guard let address, let password else { return }
        do {
            try await APIClient.unspam(address: address, password: password, id: id)
            if let idx = messages.firstIndex(where: { $0.id == id }) {
                let m = messages[idx]
                messages[idx] = LuismailMessage(id: m.id, from: m.from, subject: m.subject, body: m.body, ts: m.ts, read: m.read, spam: false)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteAccount() async {
        guard let address, let password else { return }
        do {
            try await APIClient.deleteAccount(address: address, password: password)
            logout()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func persist(address: String, password: String) {
        self.address = address
        self.password = password
        UserDefaults.standard.set(address, forKey: addressKey)
        UserDefaults.standard.set(password, forKey: passwordKey)
        sharedDefaults?.set(address, forKey: "luismail.address")
        sharedDefaults?.set(password, forKey: "luismail.password")
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Real-time (WebSocket, mirrors the web frontend's ws_bridge client)

    func connectRealtime() {
        disconnectRealtime()
        guard let address, let password, let url = URL(string: wsBaseURL) else { return }

        let task = URLSession.shared.webSocketTask(with: url)
        webSocketTask = task
        task.resume()

        let authMsg = (try? JSONSerialization.data(withJSONObject: ["address": address, "password": password]))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        task.send(.string(authMsg)) { _ in }

        listenForRealtimeMessages()
    }

    private func listenForRealtimeMessages() {
        webSocketTask?.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure:
                Task { @MainActor in self.scheduleReconnect() }
            case .success(let message):
                if case .string(let text) = message, let data = text.data(using: .utf8),
                   let payload = try? JSONDecoder().decode(WSInboxPayload.self, from: data),
                   payload.type == "inbox", let newMessages = payload.messages {
                    Task { @MainActor in
                        let previousIds = Set(self.messages.map { $0.id })
                        let genuinelyNew = newMessages.filter { !previousIds.contains($0.id) && !$0.spam }
                        self.messages = newMessages.sorted { $0.ts > $1.ts }
                        for m in genuinelyNew { NotificationManager.notifyNewMail(m) }
                        NotificationManager.updateBadge(self.unreadCount)
                    }
                }
                Task { @MainActor in self.listenForRealtimeMessages() }
            }
        }
    }

    private func scheduleReconnect() {
        guard isLoggedIn else { return }
        wsReconnectTask?.cancel()
        wsReconnectTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled else { return }
            connectRealtime()
        }
    }

    private func disconnectRealtime() {
        wsReconnectTask?.cancel()
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
    }
}
