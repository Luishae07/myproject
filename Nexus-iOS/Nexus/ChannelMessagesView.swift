import SwiftUI

struct ChannelMessagesView: View {
    let channel: NexusChannel
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var socket: NexusSocket
    @State private var messages: [NexusMessage] = []
    @State private var draft = ""
    @State private var loading = true
    @State private var errorText: String?

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        if loading {
                            ProgressView().frame(maxWidth: .infinity).padding()
                        } else if let errorText {
                            Text(errorText).foregroundStyle(.secondary).padding()
                        } else if messages.isEmpty {
                            Text("No messages yet -- say hi.").foregroundStyle(.secondary).padding()
                        }
                        ForEach(messages) { message in
                            MessageRow(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .onChange(of: messages.count) {
                    if let last = messages.last?.id {
                        withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                    }
                }
            }

            HStack(spacing: 8) {
                TextField("Message #\(channel.name)", text: $draft, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(10)
                    .glassEffect(in: .rect(cornerRadius: 12))
                Button {
                    Task { await send() }
                } label: {
                    Image(systemName: "arrow.up.circle.fill").font(.title2)
                }
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(10)
        }
        .navigationTitle(channel.name)
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .onChange(of: socket.lastEvent?.channel_id) { _, _ in
            guard let event = socket.lastEvent, event.type == "message",
                  event.channel_id == channel.id, let message = event.message else { return }
            if !messages.contains(where: { $0.id == message.id }) {
                messages.append(message)
            }
        }
    }

    private func load() async {
        guard let token = session.token else { return }
        loading = true
        errorText = nil
        do {
            messages = try await APIClient.messages(token: token, channelID: channel.id)
        } catch {
            errorText = error.localizedDescription
        }
        loading = false
    }

    private func send() async {
        guard let token = session.token else { return }
        let content = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        draft = ""
        do {
            let message = try await APIClient.sendMessage(token: token, channelID: channel.id, content: content)
            if !messages.contains(where: { $0.id == message.id }) {
                messages.append(message)
            }
        } catch {
            errorText = error.localizedDescription
        }
    }
}

private struct MessageRow: View {
    let message: NexusMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Text(message.author)
                    .font(.subheadline.weight(.semibold))
                if let created = message.created_at {
                    Text(created)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            if let content = message.content, !content.isEmpty {
                Text(content)
                    .font(.body)
                    .textSelection(.enabled)
            }
            ForEach(message.attachmentList, id: \.url) { att in
                if let url = URL(string: att.url) {
                    AsyncImage(url: url) { image in
                        image.resizable().aspectRatio(contentMode: .fit)
                    } placeholder: {
                        ProgressView().frame(height: 100)
                    }
                    .frame(maxHeight: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }
}
