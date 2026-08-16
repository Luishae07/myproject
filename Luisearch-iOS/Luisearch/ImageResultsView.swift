import SwiftUI

struct ImageResultsView: View {
    let query: String
    @State private var results: [ImageResult] = []
    @State private var loading = true
    @State private var errorText: String?

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 6)]

    var body: some View {
        ScrollView {
            if loading {
                ProgressView().padding(40)
            } else if let errorText {
                Text(errorText).foregroundStyle(.secondary).padding(40)
            } else if results.isEmpty {
                Text("No images found.").foregroundStyle(.secondary).padding(40)
            } else {
                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(results) { img in
                        Link(destination: URL(string: img.page_url ?? "") ?? img.resolvedURL ?? URL(string: API.base)!) {
                            AsyncImage(url: img.resolvedURL) { image in
                                image.resizable().aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle().fill(.quaternary)
                            }
                            .frame(height: 110)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .padding(6)
            }
        }
        .task(id: query) { await load() }
    }

    private func load() async {
        loading = true
        errorText = nil
        do {
            results = try await APIClient.searchImages(query).results
        } catch APIError.rateLimited {
            errorText = "Rate limited -- try again shortly."
        } catch {
            errorText = "Image search unavailable."
        }
        loading = false
    }
}
