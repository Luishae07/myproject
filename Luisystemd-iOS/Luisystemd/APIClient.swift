import Foundation

enum APIError: Error, LocalizedError {
    case server(String)
    case badResponse

    var errorDescription: String? {
        switch self {
        case .server(let msg): return msg
        case .badResponse: return "Unexpected response."
        }
    }
}

enum APIClient {
    // MARK: - low level

    private static func request<T: Decodable>(
        _ path: String, method: String = "GET", apiKey: String? = nil, json body: [String: Any]? = nil, query: [String: String] = [:]
    ) async throws -> T {
        var comps = URLComponents(string: API.base + path)!
        if !query.isEmpty {
            comps.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        var req = URLRequest(url: comps.url!)
        req.httpMethod = method
        if let apiKey { req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization") }
        if let body {
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else { throw APIError.badResponse }
        if http.statusCode >= 400 {
            if let obj = try? JSONDecoder().decode(ErrorBody.self, from: data) {
                throw APIError.server(obj.error ?? "Request failed (\(http.statusCode))")
            }
            throw APIError.server("Request failed (\(http.statusCode))")
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private struct ErrorBody: Decodable { let error: String? }

    // MARK: - account

    struct LoginResponse: Decodable { let username: String; let key: String }

    static func login(username: String, password: String) async throws -> LoginResponse {
        try await request("/api/account/login", method: "POST", json: ["username": username, "password": password])
    }

    static func signup(username: String, password: String) async throws -> LoginResponse {
        try await request("/api/account/signup", method: "POST", json: ["username": username, "password": password])
    }

    /// The real GitHub sign-in URL, same web OAuth flow the desktop/mobile
    /// frontends use -- `client=ios` tells the backend to bounce back via
    /// the app's custom URL scheme instead of redirecting to the pages.dev
    /// frontend (see GitHubSignInView for the ASWebAuthenticationSession
    /// side of this).
    static var githubSignInURL: URL {
        URL(string: "\(API.base)/api/oauth/github/start?client=ios")!
    }

    // MARK: - projects

    static func projects(apiKey: String) async throws -> [Project] {
        let r: ProjectsResponse = try await request("/api/projects", apiKey: apiKey)
        return r.projects
    }

    static func createProject(apiKey: String, name: String) async throws -> Project {
        struct Resp: Decodable { let id: String; let name: String }
        let r: Resp = try await request("/api/project/create", method: "POST", apiKey: apiKey, json: ["name": name])
        return Project(id: r.id, name: r.name, created_at: nil, updated_at: nil, is_owner: true)
    }

    static func deleteProject(apiKey: String, projectId: String) async throws {
        let _: OKResponse = try await request("/api/project/delete", method: "POST", apiKey: apiKey, json: ["project_id": projectId])
    }

    // MARK: - filesystem

    static func fsList(apiKey: String, projectId: String, path: String) async throws -> [FSItem] {
        let r: FSListResponse = try await request("/api/fs/list", method: "POST", apiKey: apiKey, json: ["project_id": projectId, "rel": path])
        if let error = r.error { throw APIError.server(error) }
        return r.items ?? []
    }

    static func fsRead(apiKey: String, projectId: String, path: String) async throws -> String {
        let r: FSReadResponse = try await request("/api/fs/read", method: "POST", apiKey: apiKey, json: ["project_id": projectId, "path": path])
        if let error = r.error { throw APIError.server(error) }
        guard let b64 = r.content_b64, let data = Data(base64Encoded: b64) else { throw APIError.badResponse }
        return String(data: data, encoding: .utf8) ?? ""
    }

    static func fsWrite(apiKey: String, projectId: String, path: String, content: String) async throws {
        let r: OKResponse = try await request("/api/fs/write", method: "POST", apiKey: apiKey, json: ["project_id": projectId, "path": path, "content": content])
        if let error = r.error { throw APIError.server(error) }
    }

    static func fsDelete(apiKey: String, projectId: String, path: String) async throws {
        let r: OKResponse = try await request("/api/fs/delete", method: "POST", apiKey: apiKey, json: ["project_id": projectId, "path": path])
        if let error = r.error { throw APIError.server(error) }
    }

    static func fsMkdir(apiKey: String, projectId: String, path: String) async throws {
        let r: OKResponse = try await request("/api/fs/mkdir", method: "POST", apiKey: apiKey, json: ["project_id": projectId, "rel": path])
        if let error = r.error { throw APIError.server(error) }
    }

    // MARK: - deploy

    static func deploy(apiKey: String, projectId: String) async throws -> DeployResponse {
        try await request("/api/deploy", method: "POST", apiKey: apiKey, json: ["project_id": projectId])
    }

    static func undeploy(apiKey: String, projectId: String) async throws {
        let _: OKResponse = try await request("/api/undeploy", method: "POST", apiKey: apiKey, json: ["project_id": projectId])
    }

    static func deployLogs(apiKey: String, projectId: String) async throws -> String {
        let r: DeployLogResponse = try await request("/api/deploy/logs", method: "POST", apiKey: apiKey, json: ["project_id": projectId])
        return r.log ?? ""
    }

    // MARK: - gallery

    static func gallery(q: String = "", sort: String = "new") async throws -> [GalleryProject] {
        let r: GalleryResponse = try await request("/api/gallery", query: ["q": q, "sort": sort])
        return r.projects ?? []
    }

    // MARK: - settings / secrets

    static func settingsGet(apiKey: String, projectId: String) async throws -> ProjectSettings {
        try await request("/api/project/settings/get", method: "POST", apiKey: apiKey, json: ["project_id": projectId])
    }

    static func settingsSet(apiKey: String, projectId: String, env: [String: String], autoRestart: Bool) async throws {
        let _: OKResponse = try await request("/api/project/settings/set", method: "POST", apiKey: apiKey, json: [
            "project_id": projectId, "env": env, "auto_restart": autoRestart,
        ])
    }

    static func secretsGet(apiKey: String, projectId: String) async throws -> [String: String] {
        let r: SecretsResponse = try await request("/api/project/secrets/get", method: "POST", apiKey: apiKey, json: ["project_id": projectId])
        return r.secrets ?? [:]
    }

    static func secretsSet(apiKey: String, projectId: String, secrets: [String: String]) async throws {
        let _: OKResponse = try await request("/api/project/secrets/set", method: "POST", apiKey: apiKey, json: ["project_id": projectId, "secrets": secrets])
    }

    // MARK: - jobs

    static func jobsList(apiKey: String, projectId: String) async throws -> [ScheduledJob] {
        let r: JobsResponse = try await request("/api/jobs/list", method: "POST", apiKey: apiKey, json: ["project_id": projectId])
        return r.jobs ?? []
    }

    static func jobsCreate(apiKey: String, projectId: String, command: String, intervalMinutes: Int) async throws {
        struct Resp: Decodable { let id: String }
        let _: Resp = try await request("/api/jobs/create", method: "POST", apiKey: apiKey, json: [
            "project_id": projectId, "command": command, "interval_minutes": intervalMinutes,
        ])
    }

    static func jobsDelete(apiKey: String, jobId: String) async throws {
        let _: OKResponse = try await request("/api/jobs/delete", method: "POST", apiKey: apiKey, json: ["id": jobId])
    }

    // MARK: - terminal (server-sent events)

    /// The backend streams `/api/terminal` as an SSE response (one JSON
    /// object per `data:` line) that ends on its own after the command
    /// finishes -- same shape as Luismail's realtime WebSocket handling,
    /// just SSE instead of a socket. URLSession's `.bytes` async sequence
    /// gives us the raw stream to split on newlines ourselves since
    /// Foundation has no built-in SSE parser.
    static func terminalStream(apiKey: String, projectId: String, command: String) -> AsyncThrowingStream<TerminalEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    var req = URLRequest(url: URL(string: API.base + "/api/terminal")!)
                    req.httpMethod = "POST"
                    req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    req.httpBody = try JSONSerialization.data(withJSONObject: ["project_id": projectId, "command": command])

                    let (bytes, response) = try await URLSession.shared.bytes(for: req)
                    guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                        throw APIError.server("Terminal request failed")
                    }
                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let jsonStr = String(line.dropFirst(6))
                        guard let data = jsonStr.data(using: .utf8),
                              let event = try? JSONDecoder().decode(TerminalEvent.self, from: data) else { continue }
                        continuation.yield(event)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

struct TerminalEvent: Decodable {
    let type: String?
    let t: String?
    let code: Int?
}
