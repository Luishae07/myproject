import Foundation
import UserNotifications

/// Local notifications only -- real APNs push needs the aps-environment
/// entitlement, which needs a signed provisioning profile. This build ships
/// unsigned (sideloaded via iLoader) specifically to avoid that whole
/// signing chain, so there's no push here. Local notifications fire
/// whenever the WebSocket delivers new mail while the app is running (even
/// briefly backgrounded) -- they won't wake the app from fully-terminated,
/// which only real push can do.
enum NotificationManager {
    static func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    static func notifyNewMail(_ message: LuismailMessage) {
        let content = UNMutableNotificationContent()
        content.title = message.from
        content.body = message.subject.isEmpty ? "(no subject)" : message.subject
        content.sound = .default

        let request = UNNotificationRequest(identifier: "luismail-\(message.id)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    static func updateBadge(_ count: Int) {
        UNUserNotificationCenter.current().setBadgeCount(count)
    }
}
