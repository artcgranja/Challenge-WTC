//
//  Message.swift
//  WTCChatApp
//
//  Created by WTC Challenge
//

import Foundation

struct Message: Codable, Identifiable {
    let id: UUID
    var type: MessageType
    var recipientId: UUID?
    var segmentTags: [String]?
    var content: MessageContent
    var readAt: Date?
    var starred: Bool
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case recipientId = "recipient_id"
        case segmentTags = "segment_tags"
        case content
        case readAt = "read_at"
        case starred
        case createdAt = "created_at"
    }

    init(id: UUID = UUID(), type: MessageType, recipientId: UUID? = nil,
         segmentTags: [String]? = nil, content: MessageContent,
         readAt: Date? = nil, starred: Bool = false, createdAt: Date = Date()) {
        self.id = id
        self.type = type
        self.recipientId = recipientId
        self.segmentTags = segmentTags
        self.content = content
        self.readAt = readAt
        self.starred = starred
        self.createdAt = createdAt
    }

    var isRead: Bool {
        readAt != nil
    }
}

enum MessageType: String, Codable {
    case chat
    case campaign
}

struct MessageContent: Codable {
    var title: String
    var body: String
    var imageUrl: String?
    var buttons: [ActionButton]?

    init(title: String, body: String, imageUrl: String? = nil, buttons: [ActionButton]? = nil) {
        self.title = title
        self.body = body
        self.imageUrl = imageUrl
        self.buttons = buttons
    }
}

struct ActionButton: Codable, Identifiable {
    var id: UUID = UUID()
    var label: String
    var action: String

    enum CodingKeys: String, CodingKey {
        case label
        case action
    }

    init(label: String, action: String) {
        self.label = label
        self.action = action
    }
}
