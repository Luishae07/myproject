import SwiftUI

struct GalleryView: View {
    @State private var items: [GalleryProject] = []
    @State private var loading = true
    @State private var query = ""

    var body: some View {
        NavigationStack {
            Group {
                if loading {
                    ProgressView()
                } else if items.isEmpty {
                    ContentUnavailableView("Nothing published yet", systemImage: "sparkles")
                } else {
                    List(items) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.gallery_title ?? "Untitled").font(.headline)
                            if let desc = item.gallery_description, !desc.isEmpty {
                                Text(desc).font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
                            }
                            HStack(spacing: 10) {
                                if let owner = item.owner { Text("by \(owner)") }
                                Label("\(item.like_count ?? 0)", systemImage: "heart.fill")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Gallery")
            .searchable(text: $query)
            .onSubmit(of: .search) { Task { await load() } }
            .task { await load() }
        }
    }

    private func load() async {
        loading = true
        items = (try? await APIClient.gallery(q: query)) ?? []
        loading = false
    }
}
