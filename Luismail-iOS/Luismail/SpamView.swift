import SwiftUI

struct SpamView: View {
    @EnvironmentObject var session: SessionStore
    @State private var selectedMessage: LuismailMessage?

    var spamMessages: [LuismailMessage] {
        session.messages.filter { $0.spam }
    }

    var body: some View {
        NavigationStack {
            List {
                if spamMessages.isEmpty {
                    ContentUnavailableView("No spam", systemImage: "checkmark.shield", description: Text("Nothing's been flagged."))
                        .listRowSeparator(.hidden)
                } else {
                    ForEach(spamMessages) { message in
                        Button {
                            selectedMessage = message
                        } label: {
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
                                Text(message.subject.isEmpty ? "(no subject)" : message.subject)
                                    .font(.subheadline.weight(.semibold))
                                    .lineLimit(1)
                                let (cleanBody, _) = message.cleanBodyAndGmailMeta
                                Text(cleanBody.hasPrefix(LuismailMessage.htmlBodyMarker) ? "[HTML email]" : cleanBody)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                        .swipeActions {
                            Button(role: .destructive) {
                                Task { await session.delete(id: message.id) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            Button {
                                Task { await session.unspam(id: message.id) }
                            } label: {
                                Label("Not spam", systemImage: "checkmark.shield")
                            }
                            .tint(.accentColor)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Spam")
            .refreshable { await session.refreshInbox() }
            .sheet(item: $selectedMessage) { message in
                MessageDetailView(message: message)
            }
        }
    }
}
