import SwiftUI

struct AccountView: View {
    @EnvironmentObject var session: SessionStore

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Username", value: session.username ?? "")
                    LabeledContent("Backend", value: URL(string: API.base)?.host ?? API.base)
                }
                Section {
                    Button("Log out", role: .destructive) {
                        session.logout()
                    }
                }
            }
            .navigationTitle("Account")
        }
    }
}
