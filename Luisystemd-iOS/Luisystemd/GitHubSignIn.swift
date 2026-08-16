import AuthenticationServices
import UIKit

/// Drives the GitHub OAuth web flow in an ASWebAuthenticationSession and
/// hands back (username, apiKey) parsed from the `luisystemd://oauth-callback`
/// redirect the backend issues for `client=ios` (see APIClient.githubSignInURL).
@MainActor
final class GitHubSignIn: NSObject, ASWebAuthenticationPresentationContextProviding {
    private var session: ASWebAuthenticationSession?

    func signIn() async throws -> (username: String, apiKey: String) {
        try await withCheckedThrowingContinuation { continuation in
            let authSession = ASWebAuthenticationSession(
                url: APIClient.githubSignInURL,
                callbackURLScheme: "luisystemd"
            ) { callbackURL, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let callbackURL,
                      let fragment = callbackURL.fragment,
                      let result = Self.parse(fragment) else {
                    continuation.resume(throwing: APIError.badResponse)
                    return
                }
                continuation.resume(returning: result)
            }
            authSession.presentationContextProvider = self
            authSession.prefersEphemeralWebBrowserSession = false
            self.session = authSession
            authSession.start()
        }
    }

    private static func parse(_ fragment: String) -> (username: String, apiKey: String)? {
        var username: String?
        var apiKey: String?
        for pair in fragment.split(separator: "&") {
            let parts = pair.split(separator: "=", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { continue }
            let value = parts[1].removingPercentEncoding ?? parts[1]
            if parts[0] == "oauth_user" { username = value }
            if parts[0] == "oauth_key" { apiKey = value }
        }
        guard let username, let apiKey else { return nil }
        return (username, apiKey)
    }

    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first?.windows.first { $0.isKeyWindow } ?? ASPresentationAnchor()
        }
    }
}
