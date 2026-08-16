import SwiftUI

extension Color {
    /// Deterministic per-username color (matches the spirit of the web
    /// frontend's per-user color chips) so avatars are visually distinct
    /// without needing a real avatar image.
    static func forUsername(_ name: String) -> Color {
        let hash = abs(name.hashValue)
        let hue = Double(hash % 360) / 360.0
        return Color(hue: hue, saturation: 0.55, brightness: 0.85)
    }
}

struct AvatarView: View {
    let username: String
    let avatarURL: String?
    var size: CGFloat = 36

    var body: some View {
        Group {
            if let avatarURL, avatarURL.hasPrefix("http"), let url = URL(string: avatarURL) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    initialCircle
                }
            } else {
                initialCircle
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var initialCircle: some View {
        Circle()
            .fill(Color.forUsername(username).gradient)
            .overlay {
                Text(String(username.prefix(1)).uppercased())
                    .font(.system(size: size * 0.42, weight: .bold))
                    .foregroundStyle(.white)
            }
    }
}

/// Nexus timestamps come back as SQLite `TIMESTAMP DEFAULT CURRENT_TIMESTAMP`
/// strings ("YYYY-MM-DD HH:MM:SS"), not ISO8601 -- parse leniently and fall
/// back to the raw string rather than showing nothing.
enum NexusDate {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f
    }()

    static func short(_ raw: String?) -> String {
        guard let raw, let date = formatter.date(from: raw) else { return raw ?? "" }
        if Calendar.current.isDateInToday(date) {
            return timeFormatter.string(from: date)
        }
        let df = DateFormatter()
        df.dateFormat = "MMM d"
        return df.string(from: date)
    }
}
