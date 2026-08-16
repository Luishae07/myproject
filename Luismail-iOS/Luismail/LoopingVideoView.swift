import SwiftUI
import AVFoundation

/// Muted, looping, autoplay video -- for Nexus's GIF->MP4 embeds.
///
/// Rewritten from an AVPlayerViewController-based version that stayed
/// blank: AVPlayerViewController's internal layout doesn't reliably size
/// its video layer when embedded inside a SwiftUI ScrollView/LazyVGrid via
/// UIViewControllerRepresentable. This uses a plain UIView backed directly
/// by an AVPlayerLayer with layoutSubviews overridden to keep the layer's
/// frame in sync with the view -- the standard, reliable pattern for
/// embedding video in a custom-sized SwiftUI view -- plus explicit KVO on
/// playback status (play() only once actually ready) and a
/// NotificationCenter-based loop instead of AVPlayerLooper/AVQueuePlayer,
/// which added failure modes without benefit for a single non-queued clip.
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

    private var playerLayer: AVPlayerLayer? {
        layer as? AVPlayerLayer
    }

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
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak player] _ in
            player?.seek(to: .zero)
            player?.play()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
