import SwiftUI

struct Customer: Codable, Identifiable {
    let id: String
    var userId: String
    var tags: [String]
    var score: Int
    var status: String
    var notes: [CustomerNote]?
    var segmentIds: [String]?
    var fullName: String?
    var email: String?
    var phone: String?
    var avatarUrl: String?
    var createdAt: Date?

    var displayName: String {
        fullName ?? email ?? "Cliente"
    }

    var initials: String {
        let parts = (fullName ?? "").split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        }
        return String((fullName ?? "?").prefix(1)).uppercased()
    }

    var statusColor: Color {
        switch status.uppercased() {
        case "ACTIVE": return Color(red: 0.13, green: 0.77, blue: 0.37)
        case "INACTIVE": return Color(red: 0.58, green: 0.64, blue: 0.72)
        case "PENDING": return Theme.warning
        default: return Color(red: 0.58, green: 0.64, blue: 0.72)
        }
    }

    var scoreColor: Color {
        if score >= 70 { return Theme.success }
        if score >= 40 { return Theme.warning }
        return Theme.danger
    }
}

struct CustomerNote: Codable, Identifiable {
    let text: String
    let createdBy: String
    let createdAt: String

    var id: String { "note-\(createdAt)-\(text.prefix(10))" }
}

struct TimelineResponse: Codable {
    let customer: Customer
    let messages: [Message]
    let notes: [CustomerNote]?
}

enum TimelineEntry: Identifiable {
    case message(Message)
    case note(CustomerNote)

    var id: String {
        switch self {
        case .message(let m): return m.id.uuidString
        case .note(let n): return n.id
        }
    }

    var date: Date {
        switch self {
        case .message(let m): return m.createdAt
        case .note(let n):
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return formatter.date(from: n.createdAt)
                ?? ISO8601DateFormatter().date(from: n.createdAt)
                ?? Date.distantPast
        }
    }

    var title: String {
        switch self {
        case .message(let m): return m.content.title
        case .note: return "Nota do operador"
        }
    }

    var subtitle: String {
        switch self {
        case .message(let m): return m.isRead ? "Recebida e lida" : "Recebida"
        case .note(let n): return n.text
        }
    }

    var icon: String {
        switch self {
        case .message(let m):
            return m.type == .campaign ? "megaphone.fill" : "message.fill"
        case .note: return "note.text"
        }
    }

    var iconColor: Color {
        switch self {
        case .message: return Theme.primary
        case .note: return Theme.warning
        }
    }
}
