import SwiftUI

struct VideoResultsView: View {
    let query: String
    @State private var results: [VideoResult] = []
    @State private var loading = true
    @State private var errorText: String?

    var body: some View {
        List {
            ForEach(results) { v in
                Link(destination: URL(string: v.url)!) {
                    HStack(alignment: .top, spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8).fill(.quaternary)
                            if let thumb = v.thumbnail, let url = URL(string: thumb) {
                                AsyncImage(url: url) { image in
                                    image.resizable().aspectRatio(contentMode: .fill)
                                } placeholder: { Color.clear }
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            } else {
                                Image(systemName: "film").foregroundStyle(.secondary)
                            }
                        }
                        .frame(width: 120, height: 68)
                        .overlay(alignment: .bottomTrailing) {
                            if let duration = v.duration {
                                Text(duration)
                                    .font(.caption2.weight(.semibold))
                                    .padding(.horizontal, 4).padding(.vertical, 2)
                                    .background(.black.opacity(0.7), in: .rect(cornerRadius: 4))
                                    .foregroundStyle(.white)
                                    .padding(4)
                            }
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(v.title ?? "Untitled")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                            if let channel = v.channel {
                                Text(channel).font(.caption).foregroundStyle(.secondary)
                            }
                            Text(v.platform ?? (URL(string: v.url)?.host ?? ""))
                                .font(.caption2).foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            if loading {
                ProgressView().frame(maxWidth: .infinity)
            } else if let errorText {
                Text(errorText).foregroundStyle(.secondary)
            } else if results.isEmpty {
                Text("No videos found. The video index is still being built.").foregroundStyle(.secondary)
            }
        }
        .listStyle(.plain)
        .task(id: query) { await load() }
    }

    private func load() async {
        loading = true
        errorText = nil
        do {
            results = try await APIClient.searchVideos(query).results
        } catch APIError.rateLimited {
            errorText = "Rate limited -- try again shortly."
        } catch {
            errorText = "Video search unavailable."
        }
        loading = false
    }
}
