import SwiftUI

struct SearchView: View {
    @AppStorage("defaultTab") private var defaultTabRaw: String = SearchTab.web.rawValue
    @State private var query = ""
    @State private var submittedQuery = ""
    @State private var tab: SearchTab = .web
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 14) {
                    Text("Luisearch")
                        .font(.system(.largeTitle, design: .serif).weight(.bold))
                        .foregroundStyle(
                            LinearGradient(colors: [.accentColor, .cyan], startPoint: .leading, endPoint: .trailing)
                        )
                        .padding(.top, 4)

                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search Luisearch", text: $query)
                            .textFieldStyle(.plain)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .submitLabel(.search)
                            .onSubmit { submittedQuery = query }
                        if !query.isEmpty {
                            Button {
                                query = ""
                                submittedQuery = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(12)
                    .glassEffect(in: .rect(cornerRadius: 14))
                }
                .padding(.horizontal)
                .padding(.top, 6)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(SearchTab.allCases) { t in
                            TabPill(tab: t, isSelected: tab == t) {
                                tab = t
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }

                Group {
                    if submittedQuery.isEmpty {
                        ContentUnavailableView("Search the web, images, video, audio, and downloads", systemImage: "magnifyingglass")
                    } else {
                        switch tab {
                        case .web: WebResultsView(query: submittedQuery)
                        case .images: ImageResultsView(query: submittedQuery)
                        case .videos: VideoResultsView(query: submittedQuery)
                        case .audio: AudioResultsView(query: submittedQuery)
                        case .downloads: DownloadResultsView(query: submittedQuery)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .onAppear {
                if let restored = SearchTab(rawValue: defaultTabRaw) {
                    tab = restored
                }
            }
        }
    }
}

private struct TabPill: View {
    let tab: SearchTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(tab.rawValue, systemImage: tab.icon)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background {
                    if isSelected {
                        Capsule().fill(Color.accentColor)
                    } else {
                        Capsule().fill(.thinMaterial)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}
