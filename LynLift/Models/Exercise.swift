import Foundation

struct Exercise: Identifiable, Codable, Hashable {
    let id: UUID
    let userId: UUID
    let name: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case createdAt = "created_at"
    }
}

// Extension for display and search
extension Exercise {
    var searchableText: String {
        return name.lowercased()
    }
} 