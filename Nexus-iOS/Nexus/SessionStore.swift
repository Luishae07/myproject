import Foundation

@MainActor
final class SessionStore: ObservableObject {
    @Published var username: String?
    @Published var token: String?

    private let usernameKey = "nexus.username"
    private let tokenKey = "nexus.token"

    init() {
        username = UserDefaults.standard.string(forKey: usernameKey)
        token = UserDefaults.standard.string(forKey: tokenKey)
    }

    var isLoggedIn: Bool { token != nil }

    func setSession(username: String, token: String) {
        self.username = username
        self.token = token
        UserDefaults.standard.set(username, forKey: usernameKey)
        UserDefaults.standard.set(token, forKey: tokenKey)
    }

    func logout() {
        username = nil
        token = nil
        UserDefaults.standard.removeObject(forKey: usernameKey)
        UserDefaults.standard.removeObject(forKey: tokenKey)
    }
}
