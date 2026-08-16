import SwiftUI

struct SearchView: View {
    @State private var query = ""
    @State private var submittedQuery = ""
    @State private var tab: SearchTab = .web

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search Luisearch", text: $query)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .submitLabel(.search)
                        .onSubmit { submittedQuery = query }
                }
                .padding(12)
                .glassEffect(in: .rect(cornerRadius: 14))
                .padding(.horizontal)
                .padding(.top, 8)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(SearchTab.allCases) { t in
                            Button {
                                tab = t
                            } label: {
                                Label(t.rawValue, systemImage: t.icon)
                                    .font(.subheadline.weight(tab == t ? .semibold : .regular))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                            }
                            .buttonStyle(.glass)
                            .tint(tab == t ? Color.accentColor : .clear)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
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
            .navigationTitle("Luisearch")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
