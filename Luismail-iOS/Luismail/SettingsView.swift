import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var session: SessionStore
    @State private var showDeleteConfirm = false
    @State private var gmailConnecting = false
    @State private var gmailError: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Address")
                        Spacer()
                        Text(session.address ?? "")
                            .font(.footnote.monospaced())
                            .foregroundStyle(.secondary)
                    }
                    Button {
                        UIPasteboard.general.string = session.address
                    } label: {
                        Label("Copy address", systemImage: "doc.on.doc")
                    }
                }

                Section {
                    Label("End-to-end encrypted", systemImage: "lock.shield.fill")
                        .foregroundStyle(Color.accentColor)
                } footer: {
                    Text("Every message is encrypted per-recipient over TLS 1.3 via LSAD.")
                }

                Section("Gmail") {
                    Button {
                        Task {
                            guard let address = session.address, let password = session.password else { return }
                            gmailConnecting = true
                            gmailError = nil
                            do {
                                let url = try await APIClient.connectGmail(address: address, password: password)
                                await UIApplication.shared.open(url)
                            } catch {
                                gmailError = error.localizedDescription
                            }
                            gmailConnecting = false
                        }
                    } label: {
                        if gmailConnecting {
                            ProgressView()
                        } else {
                            Label("Connect Gmail", systemImage: "envelope.badge.fill")
                        }
                    }
                    if let gmailError {
                        Text(gmailError).font(.footnote).foregroundStyle(.red)
                    }
                } footer: {
                    Text("Read-only by default; new mail is delivered into this inbox tagged [Gmail]. Reply via Gmail sends a real threaded reply through your actual account.")
                }

                Section {
                    Button(role: .destructive) {
                        session.logout()
                    } label: {
                        Label("Log out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete account", systemImage: "trash")
                    }
                } footer: {
                    Text("Permanently deletes your address and all mail. Cannot be undone.")
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "Delete \(session.address ?? "this account") and all its mail?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    Task { await session.deleteAccount() }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}
