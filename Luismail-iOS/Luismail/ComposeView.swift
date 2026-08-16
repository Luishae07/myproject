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

                Section("Message") {
                    TextEditor(text: $messageBody)
                        .frame(minHeight: 220)
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
    }
}
