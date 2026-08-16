import SwiftUI

struct ComposeView: View {
    var prefillTo: String = ""
    var prefillSubject: String = ""

    @EnvironmentObject var session: SessionStore
    @Environment(\.dismiss) private var dismiss
    @State private var to = ""
    @State private var subject = ""
    @State private var messageBody = ""
    @State private var isSending = false
    @State private var errorMessage: String?
    @State private var sentConfirmation = false
    @State private var showingGifPicker = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("bob/\(luismailDomain)", text: $to)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Subject", text: $subject)
                } header: {
                    Text("To")
                }

                Section {
                    TextEditor(text: $messageBody)
                        .frame(minHeight: 220)
                    Button {
                        showingGifPicker = true
                    } label: {
                        Label("Add GIF", systemImage: "photo.badge.plus")
                    }
                } header: {
                    Text("Message")
                } footer: {
                    Text("**bold** works. GIFs via Nexus.")
                }

                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                }
                if sentConfirmation {
                    Text("Sent").foregroundStyle(Color.accentColor)
                }
            }
            .navigationTitle("Compose")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            isSending = true
                            errorMessage = nil
                            do {
                                try await session.send(to: to, subject: subject, body: messageBody)
                                sentConfirmation = true
                                to = ""; subject = ""; messageBody = ""
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                            isSending = false
                        }
                    } label: {
                        if isSending { ProgressView() } else { Text("Send") }
                    }
                    .buttonStyle(.glass)
                    .disabled(to.isEmpty || messageBody.isEmpty || isSending)
                }
            }
        }
        .onAppear {
            if to.isEmpty { to = prefillTo }
            if subject.isEmpty { subject = prefillSubject }
        }
        .sheet(isPresented: $showingGifPicker) {
            GifPickerView { gif in
                let insert = "![\(gif.alt)](\(nexusBaseURL)\(gif.vid))"
                messageBody = messageBody.isEmpty ? insert : messageBody + "\n" + insert
            }
        }
    }
}

/// Nexus GIF search -- same crawled-GIF backend the web frontend's picker
/// uses.
struct GifPickerView: View {
    let onPick: (NexusGif) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var gifs: [NexusGif] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    ProgressView().frame(maxHeight: .infinity)
                } else if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red).frame(maxHeight: .infinity)
                } else if gifs.isEmpty {
                    ContentUnavailableView("No GIFs found", systemImage: "photo").frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(gifs) { gif in
                                if let url = gif.fullURL {
                                    LoopingVideoView(url: url)
                                        .frame(height: 90)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .onTapGesture {
                                            onPick(gif)
                                            dismiss()
                                        }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .searchable(text: $query, prompt: "Search GIFs")
            .onSubmit(of: .search) { search() }
            .navigationTitle("Add GIF")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .task { search() }
        }
    }

    private func search() {
        Task {
            isLoading = true
            errorMessage = nil
            do {
                gifs = try await APIClient.searchGifs(query: query)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
