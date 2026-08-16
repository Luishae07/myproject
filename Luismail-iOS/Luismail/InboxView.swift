import SwiftUI

struct InboxView: View {
    @EnvironmentObject var session: SessionStore
    @State private var searchText = ""
    @State private var selectedMessage: LuismailMessage?
    @State private var summary: String?
    @State private var isSummarizing = false

    var filtered: [LuismailMessage] {
        guard !searchText.isEmpty else { return session.messages }
        let q = searchText.lowercased()
        return session.messages.filter {
            $0.from.lowercased().contains(q) || $0.subject.lowercased().contains(q) || $0.body.lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if let summary {
                    Section {
                        Text(summary)
                            .font(.callout)
                    } header: {
                        Text("AI Summary")
                    }
                }

                ForEach(filtered) { message in
                    Button {
                        selectedMessage = message
                    } label: {
                        MessageRow(message: message)
                    }
                    .buttonStyle(.plain)
                    .swipeActions {
                        Button(role: .destructive) {
                            Task { await session.delete(id: message.id) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.plain)
            .searchable(text: $searchText, prompt: "Search inbox")
            .navigationTitle("Inbox")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        guard let address = session.address, let password = session.password else { return }
                        Task {
                            isSummarizing = true
                            do {
                                summary = try await APIClient.summarize(address: address, password: password)
                            } catch {
                                session.errorMessage = error.localizedDescription
                            }
                            isSummarizing = false
                        }
                    } label: {
                        if isSummarizing {
                            ProgressView()
                        } else {
                            Image(systemName: "sparkles")
                        }
                    }
                }
            }
            .refreshable { await session.refreshInbox() }
            .task { await session.refreshInbox() }
            .sheet(item: $selectedMessage) { message in
                MessageDetailView(message: message)
            }
            .overlay {
                if session.messages.isEmpty {
                    ContentUnavailableView("No messages yet", systemImage: "tray")
                }
            }
        }
    }
}

private struct MessageRow: View {
    let message: LuismailMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(message.from)
                    .font(.caption.monospaced())
                    .foregroundStyle(Color.accentColor)
                Spacer()
                Text(message.date, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 6) {
                if !message.read {
                    Circle().fill(Color.accentColor).frame(width: 6, height: 6)
                }
                Text(message.subject.isEmpty ? "(no subject)" : message.subject)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
            }
            let (cleanBody, _) = message.cleanBodyAndGmailMeta
            Text(cleanBody.hasPrefix(LuismailMessage.htmlBodyMarker) ? "[HTML email]" : cleanBody)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
}
