//
//  Notification.swift
//  WTCChatApp
//
//  Created by WTC Challenge
//

import Foundation

struct AppNotification: Codable, Identifiable {
    let id: UUID
    var userId: UUID
    var title: String
    var body: String
    var type: String
    var read: Bool
    var messageId: UUID?
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case body
        case type
        case read
        case messageId = "message_id"
        case createdAt = "created_at"
    }

    init(id: UUID = UUID(), userId: UUID, title: String, body: String,
         type: String = "message", read: Bool = false, messageId: UUID? = nil,
         createdAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.title = title
        self.body = body
        self.type = type
        self.read = read
        self.messageId = messageId
        self.createdAt = createdAt
    }
}
