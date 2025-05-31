import Foundation

struct User: Identifiable, Codable {
    let id: UUID
    let email: String
    let firstName: String
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case firstName = "first_name"
        case createdAt = "created_at"
    }
}

// Extension for computed properties
extension User {
    var displayName: String {
        return firstName.isEmpty ? email : firstName
    }
} 