import Foundation

struct Campaign: Codable, Identifiable {
    let id: String
    var name: String
    var segmentId: String?
    var content: MessageContent
    var deeplink: String?
    var status: String
    var sentAt: Date?
    var sentBy: String?
    var messageCount: Int?
    var createdAt: Date

    var isDraft: Bool { status == "DRAFT" }
    var isSent: Bool { status == "SENT" }
}
