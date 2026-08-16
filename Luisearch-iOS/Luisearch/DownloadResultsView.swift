import SwiftUI

struct DownloadResultsView: View {
    let query: String
    @State private var results: [DownloadResult] = []
    @State private var loading = true
    @State private var errorText: String?

    private func icon(for category: String?) -> String {
        switch category {
        case "document": return "doc.fill"
        case "archive": return "archivebox.fill"
        case "image": return "photo.fill"
        case "video": return "film.fill"
        case "audio": return "waveform"
        case "software": return "shippingbox.fill"
        default: return "doc.fill"
        }
    }

    private func sizeString(_ bytes: Int?) -> String? {
        guard let bytes else { return nil }
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }

    var body: some View {
        List {
            ForEach(results) { d in
                Link(destination: URL(string: "\(API.base)/api/dl-cache?u=\(d.url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")!) {
                    HStack(spacing: 10) {
                        Image(systemName: icon(for: d.category))
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(d.title ?? "Untitled")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            HStack(spacing: 6) {
                                if let ext = d.ext { Text(ext.uppercased()) }
                                if let host = d.host { Text("· \(host)") }
                                if let size = sizeString(d.size) { Text("· \(size)") }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "arrow.down.circle")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            if loading {
                ProgressView().frame(maxWidth: .infinity)
            } else if let errorText {
                Text(errorText).foregroundStyle(.secondary)
            } else if results.isEmpty {
                Text("No downloads found.").foregroundStyle(.secondary)
            }
        }
        .listStyle(.plain)
        .task(id: query) { await load() }
    }

    private func load() async {
        loading = true
        errorText = nil
        do {
            results = try await APIClient.searchDownloads(query).results
        } catch APIError.rateLimited {
            errorText = "Rate limited -- try again shortly."
        } catch {
            errorText = "Downloads unavailable."
        }
        loading = false
    }
}
