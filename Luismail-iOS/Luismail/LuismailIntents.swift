import AppIntents
import Foundation

/// Shortcuts/Siri integration. Reads the same persisted address/password
/// SessionStore uses (UserDefaults) -- these intents run in-process, no App
/// Group or extension needed, so no extra signing/entitlement beyond what
/// the app itself already has.
private func storedCredentials() -> (address: String, password: String)? {
    guard let address = UserDefaults.standard.string(forKey: "luismail_address"),
          let password = UserDefaults.standard.string(forKey: "luismail_password") else {
        return nil
    }
    return (address, password)
}

struct GetUnreadCountIntent: AppIntent {
    static var title: LocalizedStringResource { "Get Luismail Unread Count" }
    static var description: IntentDescription { IntentDescription("Returns how many unread, non-spam messages are in your Luismail inbox.") }

    func perform() async throws -> some IntentResult & ReturnsValue<Int> {
        guard let creds = storedCredentials() else {
            throw LuismailIntentError.notLoggedIn
        }
        let messages = try await APIClient.inbox(address: creds.address, password: creds.password)
        let unread = messages.filter { !$0.read && !$0.spam }.count
        return .result(value: unread)
    }
}

struct GetLatestMessageIntent: AppIntent {
    static var title: LocalizedStringResource { "Get Latest Luismail Message" }
    static var description: IntentDescription { IntentDescription("Returns the sender and subject of your most recent Luismail message.") }

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        guard let creds = storedCredentials() else {
            throw LuismailIntentError.notLoggedIn
        }
        let messages = try await APIClient.inbox(address: creds.address, password: creds.password)
        guard let latest = messages.filter({ !$0.spam }).max(by: { $0.ts < $1.ts }) else {
            return .result(value: "No messages")
        }
        let subject = latest.subject.isEmpty ? "(no subject)" : latest.subject
        return .result(value: "\(latest.from): \(subject)")
    }
}

struct SendLuismailIntent: AppIntent {
    static var title: LocalizedStringResource { "Send Luismail" }
    static var description: IntentDescription { IntentDescription("Sends a message through your Luismail account.") }

    @Parameter(title: "To", description: "e.g. bob/luismail.pages.dev")
    var to: String

    @Parameter(title: "Subject", default: "")
    var subject: String

    @Parameter(title: "Message")
    var body: String

    static var parameterSummary: some ParameterSummary {
        Summary("Send \(\.$body) to \(\.$to)")
    }

    func perform() async throws -> some IntentResult {
        guard let creds = storedCredentials() else {
            throw LuismailIntentError.notLoggedIn
        }
        try await APIClient.send(address: creds.address, password: creds.password, to: to, subject: subject, body: body)
        return .result()
    }
}

enum LuismailIntentError: Swift.Error, CustomLocalizedStringResourceConvertible {
    case notLoggedIn

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .notLoggedIn: return "Open Luismail and log in first."
        }
    }
}

struct LuismailShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetUnreadCountIntent(),
            phrases: ["How many unread Luismail messages do I have", "Check my \(.applicationName) unread count"],
            shortTitle: "Unread Count",
            systemImageName: "envelope.badge"
        )
        AppShortcut(
            intent: GetLatestMessageIntent(),
            phrases: ["What's my latest \(.applicationName) message"],
            shortTitle: "Latest Message",
            systemImageName: "envelope"
        )
        AppShortcut(
            intent: SendLuismailIntent(),
            phrases: ["Send a message with \(.applicationName)"],
            shortTitle: "Send Message",
            systemImageName: "paperplane"
        )
    }
}
