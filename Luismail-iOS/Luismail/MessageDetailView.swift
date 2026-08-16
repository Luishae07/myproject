import SwiftUI
import WebKit

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
                        Text(cleanBody)
                            .font(.body)
                            .textSelection(.enabled)
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
