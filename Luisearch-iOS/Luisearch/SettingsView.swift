import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("defaultTab") private var defaultTabRaw: String = SearchTab.web.rawValue

    var body: some View {
        NavigationStack {
            Form {
                Section("Search") {
                    Picker("Default tab", selection: $defaultTabRaw) {
                        ForEach(SearchTab.allCases) { t in
                            Label(t.rawValue, systemImage: t.icon).tag(t.rawValue)
                        }
                    }
                }

                Section {
                    LabeledContent("Backend", value: URL(string: API.base)?.host ?? API.base)
                } header: {
                    Text("Connection")
                } footer: {
                    Text("Luisearch connects over a Cloudflare tunnel that rotates periodically -- if search stops responding, the app may need an update with a fresh tunnel URL.")
                }

                Section("About") {
                    LabeledContent("App", value: "Luisearch")
                    LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                    Text("Web, image, video, audio, and download search, native on iOS.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
