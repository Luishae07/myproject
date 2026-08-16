import SwiftUI
import AVFoundation

struct AudioResultsView: View {
    let query: String
    @State private var results: [AudioResult] = []
    @State private var loading = true
    @State private var errorText: String?
    @State private var player: AVPlayer?
    @State private var playingID: Int?

    var body: some View {
        List {
            ForEach(results) { a in
                HStack(spacing: 10) {
                    Button {
                        toggle(a)
                    } label: {
                        Image(systemName: playingID == a.id ? "pause.circle.fill" : "play.circle.fill")
                            .font(.title2)
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(a.title ?? "Untitled")
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        HStack(spacing: 6) {
                            if let duration = a.duration { Text(duration) }
                            if let host = a.host { Text("· \(host)") }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            if loading {
                ProgressView().frame(maxWidth: .infinity)
            } else if let errorText {
                Text(errorText).foregroundStyle(.secondary)
            } else if results.isEmpty {
                Text("No audio found.").foregroundStyle(.secondary)
            }
        }
        .listStyle(.plain)
        .task(id: query) { await load() }
        .onDisappear { player?.pause() }
    }

    private func toggle(_ a: AudioResult) {
        if playingID == a.id {
            player?.pause()
            playingID = nil
            return
        }
        guard let url = URL(string: a.url) else { return }
        player = AVPlayer(url: url)
        player?.play()
        playingID = a.id
    }

    private func load() async {
        loading = true
        errorText = nil
        do {
            results = try await APIClient.searchAudio(query).results
        } catch APIError.rateLimited {
            errorText = "Rate limited -- try again shortly."
        } catch {
            errorText = "Audio search unavailable."
        }
        loading = false
    }
}
