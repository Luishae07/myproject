import Foundation

@MainActor
final class SessionStore: ObservableObject {
    @Published var username: String?
    @Published var apiKey: String?

    private let usernameKey = "luisystemd.username"
    private let apiKeyKey = "luisystemd.apiKey"

    init() {
        username = UserDefaults.standard.string(forKey: usernameKey)
        apiKey = UserDefaults.standard.string(forKey: apiKeyKey)
    }

    var isLoggedIn: Bool { apiKey != nil }

    func setSession(username: String, apiKey: String) {
        self.username = username
        self.apiKey = apiKey
        UserDefaults.standard.set(username, forKey: usernameKey)
        UserDefaults.standard.set(apiKey, forKey: apiKeyKey)
    }

    func logout() {
        username = nil
        apiKey = nil
        UserDefaults.standard.removeObject(forKey: usernameKey)
        UserDefaults.standard.removeObject(forKey: apiKeyKey)
    }
}
