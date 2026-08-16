import SwiftUI

private let quickReactions = ["👍", "❤️", "😂", "🎉", "😮", "😢"]

struct ChannelMessagesView: View {
    let channel: NexusChannel
    @EnvironmentObject var session: SessionStore
    @EnvironmentObject var socket: NexusSocket
    @State private var messages: [NexusMessage] = []
    @State private var draft = ""
    @State private var loading = true
    @State private var errorText: String?
    @State private var showingGifPicker = false
    @State private var showingPollComposer = false

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
                            MessageRow(message: message, onReact: { emoji in
                                Task { await react(to: message, emoji: emoji) }
                            }, onVote: { index in
                                Task { await vote(on: message, optionIndex: index) }
                            })
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
                Button {
                    showingGifPicker = true
                } label: {
                    Image(systemName: "photo.on.rectangle.angled")
                }
                Button {
                    showingPollComposer = true
                } label: {
                    Image(systemName: "chart.bar.fill")
                }
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
        .sheet(isPresented: $showingGifPicker) {
            GifPickerView { attachment in
                Task { await sendAttachment(attachment) }
            }
        }
        .sheet(isPresented: $showingPollComposer) {
            PollComposerView { question, options in
                Task { await createPoll(question: question, options: options) }
            }
        }
        .onChange(of: socket.lastEvent?.id) { _, _ in
            handleIncomingEvent()
        }
    }

    private func handleIncomingEvent() {
        guard let event = socket.lastEvent?.event, event.channel_id == channel.id else { return }
        switch event.type {
        case "message":
            guard let message = event.message else { return }
            if !messages.contains(where: { $0.id == message.id }) {
                messages.append(message)
            }
        case "reaction":
            guard let mid = event.message_id, let idx = messages.firstIndex(where: { $0.id == mid }) else { return }
            messages[idx].reactions = event.reactions
        case "poll_update":
            guard let pid = event.poll_id, let idx = messages.firstIndex(where: { $0.poll?.id == pid }) else { return }
            messages[idx].poll = event.poll
        default:
            break
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

    private func sendAttachment(_ attachment: Attachment) async {
        guard let token = session.token else { return }
        do {
            let message = try await APIClient.sendMessage(token: token, channelID: channel.id, content: "", attachments: [attachment])
            if !messages.contains(where: { $0.id == message.id }) {
                messages.append(message)
            }
        } catch {
            errorText = error.localizedDescription
        }
    }

    private func createPoll(question: String, options: [String]) async {
        guard let token = session.token else { return }
        do {
            let message = try await APIClient.createPoll(token: token, channelID: channel.id, question: question, options: options)
            if !messages.contains(where: { $0.id == message.id }) {
                messages.append(message)
            }
        } catch {
            errorText = error.localizedDescription
        }
    }

    private func react(to message: NexusMessage, emoji: String) async {
        guard let token = session.token else { return }
        do {
            let reactions = try await APIClient.react(token: token, messageID: message.id, emoji: emoji)
            if let idx = messages.firstIndex(where: { $0.id == message.id }) {
                messages[idx].reactions = reactions
            }
        } catch {
            errorText = error.localizedDescription
        }
    }

    private func vote(on message: NexusMessage, optionIndex: Int) async {
        guard let token = session.token, let pollID = message.poll?.id else { return }
        do {
            let poll = try await APIClient.votePoll(token: token, pollID: pollID, optionIndex: optionIndex)
            if let idx = messages.firstIndex(where: { $0.id == message.id }) {
                messages[idx].poll = poll
            }
        } catch {
            errorText = error.localizedDescription
        }
    }
}

private struct MessageRow: View {
    let message: NexusMessage
    let onReact: (String) -> Void
    let onVote: (Int) -> Void
    @State private var showingReactionPicker = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            AvatarView(username: message.author, avatarURL: nil, size: 36)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(message.author)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.forUsername(message.author))
                    Text(NexusDate.short(message.created_at))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                if let content = message.content, !content.isEmpty {
                    Text(content)
                        .font(.body)
                        .textSelection(.enabled)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
                }

                ForEach(message.attachmentList, id: \.url) { att in
                    if let url = URL(string: att.url) {
                        if att.type == "video" {
                            LoopingVideoView(url: url)
                                .frame(height: 180)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            AsyncImage(url: url) { image in
                                image.resizable().aspectRatio(contentMode: .fit)
                            } placeholder: {
                                ProgressView().frame(height: 100)
                            }
                            .frame(maxHeight: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }

                if let poll = message.poll {
                    PollView(poll: poll, onVote: onVote)
                }

                if let reactions = message.reactions, !reactions.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(reactions, id: \.emoji) { r in
                            Button {
                                onReact(r.emoji)
                            } label: {
                                Text("\(r.emoji) \(r.count)")
                                    .font(.caption)
                                    .padding(.horizontal, 8).padding(.vertical, 3)
                                    .background(.thinMaterial, in: .capsule)
                            }
                            .buttonStyle(.plain)
                        }
                        reactButton
                    }
                } else {
                    reactButton
                }
            }
        }
        .contextMenu {
            ForEach(quickReactions, id: \.self) { emoji in
                Button(emoji) { onReact(emoji) }
            }
        }
    }

    private var reactButton: some View {
        Button {
            showingReactionPicker = true
        } label: {
            Image(systemName: "face.smiling").font(.caption)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .popover(isPresented: $showingReactionPicker) {
            HStack(spacing: 10) {
                ForEach(quickReactions, id: \.self) { emoji in
                    Button {
                        onReact(emoji)
                        showingReactionPicker = false
                    } label: {
                        Text(emoji).font(.title2)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .presentationCompactAdaptation(.popover)
        }
    }
}

private struct PollView: View {
    let poll: Poll
    let onVote: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(poll.question).font(.subheadline.weight(.semibold))
            ForEach(Array(poll.options.enumerated()), id: \.offset) { index, option in
                Button {
                    onVote(index)
                } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(option.text).font(.caption)
                            Spacer()
                            Text("\(option.votes)").font(.caption2).foregroundStyle(.secondary)
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(.quaternary)
                                Capsule().fill(poll.my_vote == index ? Color.accentColor : Color.accentColor.opacity(0.5))
                                    .frame(width: geo.size.width * fraction(option.votes))
                            }
                        }
                        .frame(height: 6)
                    }
                }
                .buttonStyle(.plain)
            }
            Text("\(poll.total_votes) vote\(poll.total_votes == 1 ? "" : "s")")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(10)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }

    private func fraction(_ votes: Int) -> CGFloat {
        guard poll.total_votes > 0 else { return 0 }
        return CGFloat(votes) / CGFloat(poll.total_votes)
    }
}
