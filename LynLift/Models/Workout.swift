import Foundation

struct Workout: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let category: String
    let startedAt: Date
    var endedAt: Date?
    var isPaused: Bool = false
    var pausedDuration: TimeInterval = 0 // Total time paused
    var exercises: [WorkoutExercise] = [] // Exercises performed in this workout
    
    init(id: UUID = UUID(), userId: UUID, category: String, startedAt: Date = Date(), endedAt: Date? = nil) {
        self.id = id
        self.userId = userId
        self.category = category
        self.startedAt = startedAt
        self.endedAt = endedAt
    }
    
    var isActive: Bool {
        endedAt == nil
    }
    
    var actualDuration: TimeInterval {
        let endTime = endedAt ?? Date()
        return endTime.timeIntervalSince(startedAt) - pausedDuration
    }
    
    var formattedDuration: String {
        let duration = actualDuration
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    var exerciseSummary: String {
        let uniqueExercises = Set(exercises.map { $0.exerciseName })
        let exerciseCount = uniqueExercises.count
        let totalSets = exercises.reduce(0) { $0 + $1.sets.count }
        
        if exerciseCount == 0 {
            return "No exercises"
        } else if exerciseCount == 1 {
            return "1 exercise, \(totalSets) sets"
        } else {
            return "\(exerciseCount) exercises, \(totalSets) sets"
        }
    }
}

// New model to track exercises within a workout
struct WorkoutExercise: Identifiable, Codable {
    let id: UUID
    let exerciseId: UUID
    let exerciseName: String
    var sets: [ExerciseSet]
    let addedAt: Date
    
    init(id: UUID = UUID(), exerciseId: UUID, exerciseName: String, sets: [ExerciseSet] = [], addedAt: Date = Date()) {
        self.id = id
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.sets = sets
        self.addedAt = addedAt
    }
}

// Predefined workout categories
enum WorkoutCategory: String, CaseIterable {
    case push = "Push Day"
    case pull = "Pull Day"
    case legs = "Leg Day"
    case shoulders = "Shoulder Day"
    case custom = "Custom"
    
    var icon: String {
        switch self {
        case .push: return "figure.strengthtraining.traditional"
        case .pull: return "figure.climbing"
        case .legs: return "figure.run"
        case .shoulders: return "figure.flexibility"
        case .custom: return "star.fill"
        }
    }
} 