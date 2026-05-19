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
    var senderId: String?
    var recipientId: UUID?
    var segmentTags: [String]?
    var content: MessageContent
    var status: String?
    var readAt: Date?
    var starred: Bool
    var createdAt: Date

    init(id: UUID = UUID(), type: MessageType, senderId: String? = nil, recipientId: UUID? = nil,
         segmentTags: [String]? = nil, content: MessageContent, status: String? = nil,
         readAt: Date? = nil, starred: Bool = false, createdAt: Date = Date()) {
        self.id = id
        self.type = type
        self.senderId = senderId
        self.recipientId = recipientId
        self.segmentTags = segmentTags
        self.content = content
        self.status = status
        self.readAt = readAt
        self.starred = starred
        self.createdAt = createdAt
    }

    var isRead: Bool {
        readAt != nil
    }
}

enum MessageType: String, Codable {
    case chat = "CHAT"
    case campaign = "CAMPAIGN"
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
