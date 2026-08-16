import Foundation

enum API {
    static let base = "https://shoes-predicted-wanted-sets.trycloudflare.com"
}

struct Project: Identifiable, Decodable, Hashable {
    let id: String
    let name: String
    let created_at: String?
    let updated_at: String?
    let is_owner: Bool?
}

struct ProjectsResponse: Decodable { let projects: [Project] }

struct FSItem: Identifiable, Decodable, Hashable {
    var id: String { name }
    let name: String
    let is_dir: Bool
    let size: Int
}

struct FSListResponse: Decodable { let items: [FSItem]?; let error: String? }
struct FSReadResponse: Decodable { let content_b64: String?; let error: String? }
struct OKResponse: Decodable { let ok: Bool?; let error: String? }

struct DeployLogResponse: Decodable { let log: String? }
struct DeployResponse: Decodable { let url: String?; let runtime: String?; let error: String? }

struct GalleryProject: Identifiable, Decodable {
    let id: String
    let gallery_title: String?
    let gallery_description: String?
    let owner: String?
    let like_count: Int?
    let deploy_url: String?
}
struct GalleryResponse: Decodable { let projects: [GalleryProject]? }

struct ProjectSettings: Decodable {
    let env: [String: String]?
    let auto_restart: Bool?
    let disable_canvas_support: Bool?
}

struct SecretsResponse: Decodable { let secrets: [String: String]? }

struct ScheduledJob: Identifiable, Decodable {
    let id: String
    let command: String
    let interval_minutes: Int?
    let created_at: String?
}
struct JobsResponse: Decodable { let jobs: [ScheduledJob]? }
