import SwiftUI
import WebKit
import AVKit

struct MessageDetailView: View {
    let message: LuismailMessage
    @EnvironmentObject var session: SessionStore
    @Environment(\.dismiss) private var dismiss
    @State private var showingReply = false
    @State private var showingGmailReply = false

    var body: some View {
        let (cleanBody, gmailMeta) = message.cleanBodyAndGmailMeta
        let isHTML = cleanBody.hasPrefix(LuismailMessage.htmlBodyMarker)

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(message.from)
                            .font(.footnote.monospaced())
                            .foregroundStyle(Color.accentColor)
                        Spacer()
                        Text(message.date, style: .date)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Text(message.subject.isEmpty ? "(no subject)" : message.subject)
                        .font(.title3.weight(.bold))

                    if isHTML {
                        // Untrusted sender HTML -- rendered in a locked-down
                        // WKWebView with JS disabled, mirroring the sandboxed
                        // iframe approach on the web frontend.
                        SandboxedHTMLView(html: String(cleanBody.dropFirst(LuismailMessage.htmlBodyMarker.count)))
                            .frame(minHeight: 400)
                    } else {
                        RichBodyView(raw: cleanBody)
                    }
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                GlassEffectContainer(spacing: 10) {
                    HStack(spacing: 10) {
                        Button {
                            showingReply = true
                        } label: {
                            Label("Reply", systemImage: "arrowshape.turn.up.left.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.glass)

                        if gmailMeta != nil {
                            Button {
                                showingGmailReply = true
                            } label: {
                                Label("Reply via Gmail", systemImage: "envelope.badge.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.glass)
                        }
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showingReply) {
            ComposeView(prefillTo: message.from, prefillSubject: replySubject)
        }
        .sheet(isPresented: $showingGmailReply) {
            if let gmailMeta {
                GmailReplyView(meta: gmailMeta)
            }
        }
    }

    private var replySubject: String {
        message.subject.lowercased().hasPrefix("re:") ? message.subject : "Re: \(message.subject)"
    }
}

/// Renders **bold** (native SwiftUI markdown) and inline ![alt](url) image
/// or GIF markers -- mirrors the web frontend's renderBody(). GIF markers
/// point at /api/gifvid (Nexus's GIF->looping-MP4 pipeline), so those play
/// as a muted looping video instead of a static image.
struct RichBodyView: View {
    let raw: String

    private enum Segment {
        case text(String)
        case media(alt: String, url: URL)
    }

    private var segments: [Segment] {
        var result: [Segment] = []
        let pattern = #"!\[([^\]]*)\]\(([^)\s]+)\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [.text(raw)] }
        let ns = raw as NSString
        var lastEnd = 0
        regex.enumerateMatches(in: raw, range: NSRange(location: 0, length: ns.length)) { match, _, _ in
            guard let match else { return }
            if match.range.location > lastEnd {
                result.append(.text(ns.substring(with: NSRange(location: lastEnd, length: match.range.location - lastEnd))))
            }
            let alt = ns.substring(with: match.range(at: 1))
            let urlStr = ns.substring(with: match.range(at: 2))
            if let url = URL(string: urlStr), urlStr.hasPrefix("http") {
                result.append(.media(alt: alt, url: url))
            } else {
                result.append(.text(ns.substring(with: match.range)))
            }
            lastEnd = match.range.location + match.range.length
        }
        if lastEnd < ns.length {
            result.append(.text(ns.substring(from: lastEnd)))
        }
        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                switch segment {
                case .text(let s):
                    if !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text((try? AttributedString(markdown: s)) ?? AttributedString(s))
                            .font(.body)
                            .textSelection(.enabled)
                    }
                case .media(_, let url):
                    if url.absoluteString.contains("/api/gifvid") {
                        LoopingVideoView(url: url)
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        AsyncImage(url: url) { image in
                            image.resizable().aspectRatio(contentMode: .fit)
                        } placeholder: {
                            ProgressView().frame(height: 120)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
    }
}

/// Muted, looping, autoplay video -- for Nexus's GIF->MP4 embeds. AVPlayer
/// rather than a real GIF decoder since the source is already an MP4.
struct LoopingVideoView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let player = AVQueuePlayer()
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        let item = AVPlayerItem(url: url)
        let looper = AVPlayerLooper(player: player, templateItem: item)
        context.coordinator.looper = looper
        player.isMuted = true
        player.play()
        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }
    class Coordinator { var looper: AVPlayerLooper? }
}

/// Locked-down HTML renderer for untrusted sender content -- JavaScript
/// disabled, no navigation delegate allowed, no network-triggered loads
/// beyond the initial `loadHTMLString`.
struct SandboxedHTMLView: UIViewRepresentable {
    let html: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = false
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .white
        webView.scrollView.isScrollEnabled = true
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(html, baseURL: nil)
    }
}

private struct GmailReplyView: View {
    let meta: GmailReplyMeta
    @EnvironmentObject var session: SessionStore
    @Environment(\.dismiss) private var dismiss
    @State private var replyText = ""
    @State private var isSending = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("To: \(meta.to)")
                    .font(.footnote.monospaced())
                    .foregroundStyle(.secondary)
                TextEditor(text: $replyText)
                    .glassEffect(in: .rect(cornerRadius: 12))
                    .frame(minHeight: 200)
                if let errorMessage {
                    Text(errorMessage).font(.footnote).foregroundStyle(.red)
                }
                Button {
                    Task {
                        guard let address = session.address, let password = session.password else { return }
                        isSending = true
                        do {
                            try await APIClient.gmailReply(address: address, password: password, meta: meta, body: replyText)
                            dismiss()
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                        isSending = false
                    }
                } label: {
                    Text(isSending ? "Sending..." : "Send via Gmail")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)
                .disabled(replyText.isEmpty || isSending)
            }
            .padding()
            .navigationTitle("Reply via Gmail")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
