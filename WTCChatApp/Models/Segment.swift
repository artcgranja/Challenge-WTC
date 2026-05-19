import Foundation

struct Segment: Codable, Identifiable {
    let id: String
    var name: String
    var description: String?
    var tags: [String]
    var createdBy: String?
    var createdAt: Date?
}
