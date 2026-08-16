import Foundation

enum APIError: Error { case rateLimited, badResponse }

enum APIClient {
    private static func get<T: Decodable>(_ path: String, query: String) async throws -> T {
        guard let url = URL(string: "\(API.base)\(path)?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") else {
            throw APIError.badResponse
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse else { throw APIError.badResponse }
        if http.statusCode == 418 { throw APIError.rateLimited }
        guard http.statusCode == 200 else { throw APIError.badResponse }
        return try JSONDecoder().decode(T.self, from: data)
    }

    static func searchWeb(_ q: String) async throws -> WebSearchResponse {
        try await get("/api/search", query: q)
    }

    static func searchImages(_ q: String) async throws -> ImageSearchResponse {
        try await get("/api/image-search", query: q)
    }

    static func searchVideos(_ q: String) async throws -> VideoSearchResponse {
        try await get("/api/video-search", query: q)
    }

    static func searchAudio(_ q: String) async throws -> AudioSearchResponse {
        try await get("/api/audio-search", query: q)
    }

    static func searchDownloads(_ q: String, category: String? = nil) async throws -> DownloadSearchResponse {
        guard let encoded = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw APIError.badResponse
        }
        var urlStr = "\(API.base)/api/download-search?q=\(encoded)"
        if let category {
            urlStr += "&category=\(category)"
        }
        guard let url = URL(string: urlStr) else { throw APIError.badResponse }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse else { throw APIError.badResponse }
        if http.statusCode == 418 { throw APIError.rateLimited }
        guard http.statusCode == 200 else { throw APIError.badResponse }
        return try JSONDecoder().decode(DownloadSearchResponse.self, from: data)
    }
}
