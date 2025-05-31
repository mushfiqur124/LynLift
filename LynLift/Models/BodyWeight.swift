import Foundation

struct BodyWeight: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let weight: Double
    let unit: WeightUnit
    let loggedAt: Date
    
    init(id: UUID = UUID(), userId: UUID, weight: Double, unit: WeightUnit = .lb, loggedAt: Date = Date()) {
        self.id = id
        self.userId = userId
        self.weight = weight
        self.unit = unit
        self.loggedAt = loggedAt
    }
    
    var displayWeight: String {
        let weightFormatted = weight.truncatingRemainder(dividingBy: 1) == 0 ? 
            String(format: "%.0f", weight) : String(format: "%.1f", weight)
        return "\(weightFormatted) \(unit.symbol)"
    }
    
    // Convert weight to specified unit
    func convertedWeight(to targetUnit: WeightUnit) -> Double {
        switch (unit, targetUnit) {
        case (.lb, .kg):
            return weight * 0.453592
        case (.kg, .lb):
            return weight * 2.20462
        case (.lb, .lb), (.kg, .kg):
            return weight
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case weight
        case unit
        case loggedAt = "logged_at"
    }
}

enum WeightUnit: String, CaseIterable, Codable {
    case lb = "lb"
    case kg = "kg"
    
    var symbol: String {
        switch self {
        case .lb: return "lbs"
        case .kg: return "kg"
        }
    }
    
    var displayName: String {
        switch self {
        case .lb: return "Pounds"
        case .kg: return "Kilograms"
        }
    }
    
    // Conversion functions
    func convert(weight: Double, to unit: WeightUnit) -> Double {
        if self == unit {
            return weight
        }
        
        switch (self, unit) {
        case (.kg, .lb):
            return weight * 2.20462
        case (.lb, .kg):
            return weight / 2.20462
        default:
            return weight
        }
    }
}

// MARK: - Chart Data
struct WeightProgressData: Identifiable {
    let id = UUID()
    let date: Date
    let weight: Double
    
    init(date: Date, weight: Double) {
        self.date = date
        self.weight = weight
    }
} 