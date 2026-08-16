import SwiftUI
import AVKit

struct GifPickerView: View {
    let onPick: (Attachment) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var gifs: [NexusGif] = []
    @State private var loading = true

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 6)]

    var body: some View {
        NavigationStack {
            ScrollView {
                if loading {
                    ProgressView().padding(40)
                } else if gifs.isEmpty {
                    ContentUnavailableView("No GIFs found", systemImage: "photo.on.rectangle").padding(40)
                } else {
                    LazyVGrid(columns: columns, spacing: 6) {
                        ForEach(gifs) { gif in
                            Button {
                                onPick(Attachment(type: "video", url: gif.vid.hasPrefix("http") ? gif.vid : API.base + gif.vid))
                                dismiss()
                            } label: {
                                if let url = gif.resolvedURL {
                                    LoopingVideoView(url: url)
                                        .frame(height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(6)
                }
            }
            .navigationTitle("GIFs")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "Search GIFs")
            .onSubmit(of: .search) { Task { await load() } }
            .task { await load() }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func load() async {
        loading = true
        gifs = (try? await APIClient.searchGifs(query: query)) ?? []
        loading = false
    }
}

/// Muted, looping, autoplay video -- same reliable AVPlayerLayer-backed
/// pattern used for Luismail's GIF-as-MP4 embeds (AVPlayerViewController's
/// layout doesn't reliably size inside SwiftUI grids/scroll views).
struct LoopingVideoView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.configure(url: url)
        return view
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        if uiView.currentURL != url {
            uiView.configure(url: url)
        }
    }
}

final class PlayerContainerView: UIView {
    private var player: AVPlayer?
    private var statusObservation: NSKeyValueObservation?
    private(set) var currentURL: URL?

    private var playerLayer: AVPlayerLayer? { layer as? AVPlayerLayer }
    override class var layerClass: AnyClass { AVPlayerLayer.self }

    func configure(url: URL) {
        currentURL = url
        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        player.isMuted = true
        player.automaticallyWaitsToMinimizeStalling = false
        self.player = player
        playerLayer?.player = player
        playerLayer?.videoGravity = .resizeAspectFill

        statusObservation = item.observe(\.status, options: [.new]) { [weak player] item, _ in
            guard item.status == .readyToPlay else { return }
            player?.play()
        }

        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main
        ) { [weak player] _ in
            player?.seek(to: .zero)
            player?.play()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
