import Foundation

@MainActor
final class SessionStore: ObservableObject {
    @Published var address: String?
    @Published var password: String?
    @Published var messages: [LuismailMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    var isLoggedIn: Bool { address != nil && password != nil }

    private let addressKey = "luismail_address"
    private let passwordKey = "luismail_password"

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
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func logout() {
        address = nil
        password = nil
        messages = []
        UserDefaults.standard.removeObject(forKey: addressKey)
        UserDefaults.standard.removeObject(forKey: passwordKey)
    }

    func refreshInbox() async {
        guard let address, let password else { return }
        do {
            messages = try await APIClient.inbox(address: address, password: password).sorted { $0.ts > $1.ts }
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
    }
}
