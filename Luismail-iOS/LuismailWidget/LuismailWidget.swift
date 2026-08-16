import WidgetKit
import SwiftUI

let appGroupID = "group.com.luishae.luismail"
let webbridgeBaseURL = "https://doctors-adequate-chem-area.trycloudflare.com"

struct WidgetMessage: Decodable {
    let from: String
    let subject: String
    let spam: Bool
}

struct InboxResponse: Decodable { let messages: [WidgetMessage] }

struct LuismailEntry: TimelineEntry {
    let date: Date
    let unreadCount: Int
    let latestFrom: String?
    let latestSubject: String?
    let loggedIn: Bool
}

struct LuismailProvider: TimelineProvider {
    func placeholder(in context: Context) -> LuismailEntry {
        LuismailEntry(date: .now, unreadCount: 3, latestFrom: "someone/luismail.pages.dev", latestSubject: "Welcome to Luismail", loggedIn: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (LuismailEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LuismailEntry>) -> Void) {
        Task {
            let entry = await fetchEntry()
            // Widgets can't hold a persistent connection -- refetch on a
            // short interval so the unread count/preview stay reasonably
            // fresh without the real-time WebSocket the main app uses.
            let next = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now.addingTimeInterval(900)
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }

    private func fetchEntry() async -> LuismailEntry {
        let defaults = UserDefaults(suiteName: appGroupID)
        guard let address = defaults?.string(forKey: "luismail.address"),
              let password = defaults?.string(forKey: "luismail.password") else {
            return LuismailEntry(date: .now, unreadCount: 0, latestFrom: nil, latestSubject: nil, loggedIn: false)
        }
        do {
            var req = URLRequest(url: URL(string: "\(webbridgeBaseURL)/api/inbox")!)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONSerialization.data(withJSONObject: ["address": address, "password": password])
            let (data, _) = try await URLSession.shared.data(for: req)
            let resp = try JSONDecoder().decode(InboxResponse.self, from: data)
            let inbox = resp.messages.filter { !$0.spam }
            return LuismailEntry(
                date: .now,
                unreadCount: inbox.count,
                latestFrom: inbox.first?.from,
                latestSubject: inbox.first?.subject,
                loggedIn: true
            )
        } catch {
            return LuismailEntry(date: .now, unreadCount: 0, latestFrom: nil, latestSubject: nil, loggedIn: true)
        }
    }
}

struct LuismailWidgetView: View {
    let entry: LuismailEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !entry.loggedIn {
                Spacer()
                Text("Log in to Luismail")
                    .font(.footnote.weight(.semibold))
                Spacer()
            } else {
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundStyle(Color.accentColor)
                    Text("Luismail")
                        .font(.footnote.weight(.semibold))
                    Spacer()
                    if entry.unreadCount > 0 {
                        Text("\(entry.unreadCount)")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 7).padding(.vertical, 2)
                            .background(Color.accentColor, in: .capsule)
                            .foregroundStyle(.white)
                    }
                }
                Spacer()
                if let from = entry.latestFrom, let subject = entry.latestSubject {
                    Text(from)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text(subject.isEmpty ? "(no subject)" : subject)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(2)
                } else {
                    Text("Inbox zero")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .containerBackground(for: .widget) { Color(.systemBackground) }
    }
}

struct LuismailWidget: Widget {
    let kind = "LuismailWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LuismailProvider()) { entry in
            LuismailWidgetView(entry: entry)
        }
        .configurationDisplayName("Luismail")
        .description("Shows your unread count and latest message.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct LuismailWidgetBundle: WidgetBundle {
    var body: some Widget {
        LuismailWidget()
    }
}
