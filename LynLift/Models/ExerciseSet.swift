import Foundation

struct ExerciseSet: Identifiable, Codable {
    let id: UUID
    let workoutId: UUID
    let exerciseId: UUID
    let weight: Double
    let reps: Int
    let createdAt: Date
    var isCompleted: Bool = true // Sets saved to database are completed by default
    
    init(id: UUID = UUID(), workoutId: UUID, exerciseId: UUID, weight: Double, reps: Int, createdAt: Date = Date(), isCompleted: Bool = true) {
        self.id = id
        self.workoutId = workoutId
        self.exerciseId = exerciseId
        self.weight = weight
        self.reps = reps
        self.createdAt = createdAt
        self.isCompleted = isCompleted
    }
    
    var volume: Double {
        return weight * Double(reps)
    }
    
    var displayText: String {
        let weightFormatted = weight.truncatingRemainder(dividingBy: 1) == 0 ? 
            String(format: "%.0f", weight) : String(format: "%.1f", weight)
        return "\(weightFormatted) × \(reps)"
    }
}

// For tracking sets during an active workout (before they're saved)
struct NewExerciseSet: Identifiable {
    let id = UUID()
    var weight: Double = 0
    var reps: Int = 0
    var isCompleted: Bool = false
    
    var isValid: Bool {
        weight > 0 && reps > 0
    }
    
    var displayText: String {
        guard isValid else { return "- × -" }
        let weightFormatted = weight.truncatingRemainder(dividingBy: 1) == 0 ? 
            String(format: "%.0f", weight) : String(format: "%.1f", weight)
        return "\(weightFormatted) × \(reps)"
    }
}

// For displaying previous workout performance
struct ExercisePerformance {
    let exerciseId: UUID
    let exerciseName: String
    let lastWorkoutSets: [ExerciseSet]
    let lastWorkoutDate: Date?
    
    var bestSetFromLastWorkout: ExerciseSet? {
        lastWorkoutSets.max { $0.volume < $1.volume }
    }
    
    var lastWorkoutSummary: String {
        guard !lastWorkoutSets.isEmpty else { return "No previous data" }
        
        if lastWorkoutSets.count == 1 {
            return lastWorkoutSets[0].displayText
        } else {
            let weights = lastWorkoutSets.map { $0.weight }
            let reps = lastWorkoutSets.map { $0.reps }
            
            if Set(weights).count == 1 && Set(reps).count == 1 {
                // All sets same weight and reps
                let weightFormatted = weights[0].truncatingRemainder(dividingBy: 1) == 0 ? 
                    String(format: "%.0f", weights[0]) : String(format: "%.1f", weights[0])
                return "\(weightFormatted) × \(reps[0]) × \(lastWorkoutSets.count)"
            } else {
                // Different weights/reps, show range or best set
                if let bestSet = bestSetFromLastWorkout {
                    return "\(bestSet.displayText) (best)"
                } else {
                    return "\(lastWorkoutSets.count) sets"
                }
            }
        }
    }
} 