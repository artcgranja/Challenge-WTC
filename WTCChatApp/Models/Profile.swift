//
//  Profile.swift
//  WTCChatApp
//
//  Created by WTC Challenge
//

import Foundation

struct Profile: Codable, Identifiable {
    let id: UUID
    var fullName: String
    var email: String
    var phone: String?
    var avatarUrl: String?
    var tags: [String]
    var status: String
    var role: String
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case email
        case phone
        case avatarUrl = "avatar_url"
        case tags
        case status
        case role
        case createdAt = "created_at"
    }

    init(id: UUID = UUID(), fullName: String, email: String, phone: String? = nil,
         avatarUrl: String? = nil, tags: [String] = [], status: String = "active",
         role: String = "CLIENT", createdAt: Date = Date()) {
        self.id = id
        self.fullName = fullName
        self.email = email
        self.phone = phone
        self.avatarUrl = avatarUrl
        self.tags = tags
        self.status = status
        self.role = role
        self.createdAt = createdAt
    }

    var isOperator: Bool { role == "OPERATOR" }
}
