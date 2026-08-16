import SwiftUI

/// Native port of frontend/mobile/info.html -- the "About Luismail" page,
/// explaining LSAD, the privacy pitch vs. Gmail, and account recovery.
struct InfoView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header

                InfoCard(title: "What is LSAD?") {
                    Text("**Luismail Secure Address Delivery** — a small protocol built from scratch to not be SMTP. Addresses look like `you/domain` instead of `you@domain`, and every message is TLS 1.3-only: there's no plaintext fallback or optional STARTTLS to downgrade.")
                    Text("Message bodies are also encrypted per-recipient before they ever reach the server, so even direct database access wouldn't reveal what you wrote.")
                }

                factsCard

                InfoCard(title: "Why choose this over Gmail?") {
                    Text("**Encryption Gmail doesn't have.** Google can read your Gmail — that's how spam filtering, search, and ad-relevance scanning work. Here, message bodies are encrypted per-recipient before they leave your device; the server only ever stores ciphertext.")
                    Text("**No STARTTLS downgrade.** SMTP's encryption is opportunistic and can silently fall back to plaintext between servers. LSAD is TLS 1.3-only — there's no unencrypted mode to fall back to.")
                    Text("**Not a walled garden.** The Gmail bridge means you don't have to choose — keep your Gmail address working exactly as it does today, with new mail also landing here, encrypted, and repliable from either side.")
                    Text("**Built for depth, not scale — yet.** Luismail runs lean by design today, with lightweight spam detection rather than a hyperscale reputation network. As the user base grows, so does the infrastructure behind it. Right now, think of it as the privacy layer alongside your existing mail.")
                }

                InfoCard(title: "Account recovery") {
                    Text("Your encryption key is derived deterministically from your address and password (scrypt), not randomly generated — so logging in on a new device recovers the same key and message history instead of losing it. There's no separate recovery code to lose.")
                }

                Text("Built by the Luishae family of products.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color.accentColor)
            Text("Luismail")
                .font(.system(.title2, design: .serif, weight: .semibold))
            Text("LSAD protocol · not SMTP")
                .font(.footnote.monospaced())
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                Image(systemName: "lock.shield.fill").font(.caption2)
                Text("Version 1.0").font(.caption.weight(.semibold))
            }
            .foregroundStyle(Color.accentColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .glassEffect(.regular.tint(Color.accentColor.opacity(0.15)), in: .capsule)
            .padding(.top, 4)
        }
        .padding(.top, 12)
    }

    private var facts: [(icon: String, label: String, desc: String)] {
        [
            ("lock.shield.fill", "Encrypted per-recipient, always", "Not optional STARTTLS — there's no plaintext mode at all."),
            ("xmark.circle", "No port 25, no relay", "No open-relay abuse vector, nothing exposed on a well-known mail port."),
            ("bolt.fill", "Real-time delivery", "A single persistent WebSocket, not a polling timer."),
            ("envelope.badge.fill", "Gmail bridge", "Read-only by default; reply via Gmail sends a real threaded reply through your actual account."),
        ]
    }

    private var factsCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(facts.enumerated()), id: \.offset) { index, fact in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: fact.icon)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 30, height: 30)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(fact.label).font(.subheadline.weight(.semibold))
                        Text(fact.desc).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 10)
                if index < facts.count - 1 {
                    Divider()
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct InfoCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline.weight(.semibold))
            VStack(alignment: .leading, spacing: 8) {
                content
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    NavigationStack { InfoView() }
}
