import Foundation

// Same tunnel URL the pages.dev frontend hardcodes -- rotates whenever the
// cloudflared quick tunnel restarts, same maintenance burden as every other
// Luishae product's mobile client.
enum API {
    static let base = "https://stevens-predictions-get-feet.trycloudflare.com"
}

struct WebResult: Identifiable, Decodable {
    var id: String { url }
    let url: String
    let title: String?
    let snippet: String?
}

struct WebSearchResponse: Decodable {
    let results: [WebResult]
    let did_you_mean: String?
    let direct_answer: String?
}

struct ImageResult: Identifiable, Decodable {
    var id: String { src }
    let src: String
    let page_url: String?
    let alt: String?
}

struct ImageSearchResponse: Decodable {
    let results: [ImageResult]
}

struct VideoResult: Identifiable, Decodable {
    var id: String { url }
    let url: String
    let title: String?
    let thumbnail: String?
    let duration: String?
    let channel: String?
    let platform: String?
    let description: String?
}

struct VideoSearchResponse: Decodable {
    let results: [VideoResult]
}

struct AudioResult: Identifiable, Decodable {
    let id: Int
    let title: String?
    let url: String
    let duration: String?
    let description: String?
    let host: String?
    let format: String?
}

struct AudioSearchResponse: Decodable {
    let results: [AudioResult]
}

struct DownloadResult: Identifiable, Decodable {
    var id: String { url }
    let url: String
    let title: String?
    let ext: String?
    let host: String?
    let size: Int?
    let category: String?
}

struct DownloadSearchResponse: Decodable {
    let results: [DownloadResult]
}

enum SearchTab: String, CaseIterable, Identifiable {
    case web = "Web"
    case images = "Images"
    case videos = "Videos"
    case audio = "Audio"
    case downloads = "Downloads"
    var id: String { rawValue }

    var icon: String {
        switch self {
        case .web: return "magnifyingglass"
        case .images: return "photo"
        case .videos: return "film"
        case .audio: return "waveform"
        case .downloads: return "arrow.down.circle"
        }
    }
}
