import SwiftUI

struct WebResultsView: View {
    let query: String
    @State private var results: [WebResult] = []
    @State private var didYouMean: String?
    @State private var loading = true
    @State private var errorText: String?

    var body: some View {
        List {
            if let didYouMean {
                Text("Did you mean: \(didYouMean)?")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            ForEach(results) { r in
                Link(destination: URL(string: r.url) ?? URL(string: "https://\(API.base)")!) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(r.title ?? r.url)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(r.url)
                            .font(.caption)
                            .foregroundStyle(.green)
                            .lineLimit(1)
                        if let snippet = r.snippet, !snippet.isEmpty {
                            Text(snippet)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(3)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            if loading {
                ProgressView().frame(maxWidth: .infinity)
            } else if let errorText {
                Text(errorText).foregroundStyle(.secondary)
            } else if results.isEmpty {
                Text("No results.").foregroundStyle(.secondary)
            }
        }
        .listStyle(.plain)
        .task(id: query) { await load() }
    }

    private func load() async {
        loading = true
        errorText = nil
        do {
            let resp = try await APIClient.searchWeb(query)
            results = resp.results
            didYouMean = resp.did_you_mean
        } catch APIError.rateLimited {
            errorText = "Rate limited -- try again shortly."
        } catch {
            errorText = "Search unavailable."
        }
        loading = false
    }
}
