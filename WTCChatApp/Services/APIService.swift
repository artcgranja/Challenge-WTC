//
//  APIService.swift
//  WTCChatApp
//
//  Created by WTC Challenge — Sprint 2
//

import Foundation

struct AuthResponse: Codable {
    let token: String
    let refreshToken: String
    let userId: String
    let email: String
    let fullName: String
    let role: String
    let tags: [String]?
    let status: String?
    let avatarUrl: String?
    let phone: String?
}

class APIService {
    static let shared = APIService()

    private var accessToken: String? {
        didSet { UserDefaults.standard.set(accessToken, forKey: Constants.UserDefaultsKeys.accessToken) }
    }
    private var refreshToken: String? {
        didSet { UserDefaults.standard.set(refreshToken, forKey: Constants.UserDefaultsKeys.refreshToken) }
    }
    private(set) var currentUserId: String? {
        didSet { UserDefaults.standard.set(currentUserId, forKey: Constants.UserDefaultsKeys.userId) }
    }

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)
            if let date = ISO8601DateFormatter().date(from: str) { return date }
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            if let date = formatter.date(from: str) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(str)")
        }
        return d
    }()

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        return e
    }()

    private init() {
        self.accessToken = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.accessToken)
        self.refreshToken = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.refreshToken)
        self.currentUserId = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.userId)
    }

    var isLoggedIn: Bool {
        accessToken != nil && currentUserId != nil
    }

    // MARK: - Auth

    func login(email: String, password: String) async throws -> AuthResponse {
        let body: [String: String] = ["email": email, "password": password]
        let response: AuthResponse = try await request("POST", path: "/auth/login", body: body)
        storeAuth(response)
        return response
    }

    func register(email: String, password: String, fullName: String, phone: String? = nil) async throws -> AuthResponse {
        var body: [String: Any] = ["email": email, "password": password, "full_name": fullName, "role": "CLIENT"]
        if let phone = phone { body["phone"] = phone }
        let response: AuthResponse = try await requestRaw("POST", path: "/auth/register", jsonBody: body)
        storeAuth(response)
        return response
    }

    func logout() {
        accessToken = nil
        refreshToken = nil
        currentUserId = nil
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.accessToken)
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.refreshToken)
        UserDefaults.standard.removeObject(forKey: Constants.UserDefaultsKeys.userId)
    }

    private func storeAuth(_ response: AuthResponse) {
        accessToken = response.token
        refreshToken = response.refreshToken
        currentUserId = response.userId
    }

    // MARK: - Profile

    func fetchProfile() async throws -> Profile {
        guard let userId = currentUserId else { throw APIError.notAuthenticated }
        let response: AuthResponse = try await request("POST", path: "/auth/refresh",
                                                        body: ["refresh_token": refreshToken ?? ""])
        storeAuth(response)
        return Profile(
            id: UUID(uuidString: response.userId) ?? UUID(),
            fullName: response.fullName,
            email: response.email,
            phone: response.phone,
            avatarUrl: response.avatarUrl,
            tags: response.tags ?? [],
            status: response.status ?? "active",
            role: response.role,
            createdAt: Date()
        )
    }

    // MARK: - Messages

    func fetchMessages() async throws -> [Message] {
        guard let userId = currentUserId else { throw APIError.notAuthenticated }
        return try await request("GET", path: "/inbox/\(userId)")
    }

    func markMessageAsRead(messageId: UUID) async throws {
        let _: Message = try await request("PUT", path: "/messages/\(messageId.uuidString)/read")
    }

    func toggleMessageStar(messageId: UUID, starred: Bool) async throws {
        let _: Message = try await request("PUT", path: "/messages/\(messageId.uuidString)/star")
    }

    // MARK: - Notifications

    func fetchNotifications() async throws -> [AppNotification] {
        return try await request("GET", path: "/notifications")
    }

    func markNotificationAsRead(notificationId: UUID) async throws {
        let _: EmptyResponse = try await requestNoContent("PUT", path: "/notifications/\(notificationId.uuidString)/read")
    }

    func markAllNotificationsAsRead() async throws {
        let _: EmptyResponse = try await requestNoContent("PUT", path: "/notifications/read-all")
    }

    // MARK: - Customers (OPERATOR)

    func fetchCustomers() async throws -> [Customer] {
        return try await request("GET", path: "/customers")
    }

    func fetchCustomer(id: String) async throws -> Customer {
        return try await request("GET", path: "/customers/\(id)")
    }

    func fetchTimeline(customerId: String) async throws -> TimelineResponse {
        return try await request("GET", path: "/customers/\(customerId)/timeline")
    }

    func addNote(customerId: String, text: String) async throws {
        let body = ["text": text]
        let _: Customer = try await request("POST", path: "/customers/\(customerId)/notes", body: body)
    }

    // MARK: - Messages (OPERATOR)

    func sendOperatorMessage(type: String = "chat", recipientId: String? = nil, segmentTags: [String]? = nil, content: MessageContent) async throws -> Message {
        var body: [String: Any] = [
            "type": type,
            "content": [
                "title": content.title,
                "body": content.body
            ] as [String: Any]
        ]
        if let recipientId = recipientId { body["recipient_id"] = recipientId }
        if let segmentTags = segmentTags { body["segment_tags"] = segmentTags }
        if let imageUrl = content.imageUrl {
            var contentDict = body["content"] as! [String: Any]
            contentDict["image_url"] = imageUrl
            body["content"] = contentDict
        }
        if let buttons = content.buttons {
            var contentDict = body["content"] as! [String: Any]
            contentDict["buttons"] = buttons.map { ["label": $0.label, "action": $0.action] }
            body["content"] = contentDict
        }
        return try await requestRaw("POST", path: "/messages", jsonBody: body)
    }

    func fetchSentMessages() async throws -> [Message] {
        guard let userId = currentUserId else { throw APIError.notAuthenticated }
        return try await request("GET", path: "/messages/sent/\(userId)")
    }

    // MARK: - Campaigns (OPERATOR)

    func fetchCampaigns() async throws -> [Campaign] {
        return try await request("GET", path: "/campaigns")
    }

    func createCampaign(name: String, segmentId: String, content: MessageContent, deeplink: String? = nil) async throws -> Campaign {
        var body: [String: Any] = [
            "name": name,
            "segment_id": segmentId,
            "content": [
                "title": content.title,
                "body": content.body
            ] as [String: Any]
        ]
        if let deeplink = deeplink { body["deeplink"] = deeplink }
        if let imageUrl = content.imageUrl {
            var contentDict = body["content"] as! [String: Any]
            contentDict["image_url"] = imageUrl
            body["content"] = contentDict
        }
        return try await requestRaw("POST", path: "/campaigns", jsonBody: body)
    }

    func sendCampaign(id: String) async throws -> Campaign {
        return try await request("POST", path: "/campaigns/\(id)/send")
    }

    // MARK: - Segments (OPERATOR)

    func fetchSegments() async throws -> [Segment] {
        return try await request("GET", path: "/segments")
    }

    // MARK: - Network Layer

    private func request<T: Decodable>(_ method: String, path: String, body: Encodable? = nil) async throws -> T {
        var urlRequest = try buildRequest(method, path: path)

        if let body = body {
            urlRequest.httpBody = try encoder.encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(httpResponse.statusCode, String(data: data, encoding: .utf8))
        }

        return try decoder.decode(T.self, from: data)
    }

    private func requestRaw<T: Decodable>(_ method: String, path: String, jsonBody: [String: Any]) async throws -> T {
        var urlRequest = try buildRequest(method, path: path)
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: jsonBody)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }

        return try decoder.decode(T.self, from: data)
    }

    private func requestNoContent(_ method: String, path: String) async throws -> EmptyResponse {
        var urlRequest = try buildRequest(method, path: path)

        let (_, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }

        return EmptyResponse()
    }

    private func buildRequest(_ method: String, path: String) throws -> URLRequest {
        guard let url = URL(string: Constants.apiBaseURL + path) else {
            throw APIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = accessToken {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return urlRequest
    }
}

struct EmptyResponse: Decodable {}

enum APIError: LocalizedError {
    case notAuthenticated
    case invalidURL
    case invalidResponse
    case httpError(Int, String?)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "Usuário não autenticado"
        case .invalidURL: return "URL inválida"
        case .invalidResponse: return "Resposta inválida do servidor"
        case .httpError(let code, let body): return "Erro HTTP \(code): \(body ?? "")"
        }
    }
}
