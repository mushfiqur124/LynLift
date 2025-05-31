import Foundation
import Combine

@MainActor
class SupabaseService: ObservableObject {
    static let shared = SupabaseService()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    private init() {
        // Mock authentication for development
        Task {
            await checkAuthStatus()
        }
    }
    
    // MARK: - Authentication
    
    func checkAuthStatus() async {
        // Mock implementation - in real app this would check Supabase auth
        await MainActor.run {
            // For development, start unauthenticated
            isAuthenticated = false
            currentUser = nil
        }
    }
    
    func signIn(email: String, password: String) async throws {
        // Mock implementation
        await MainActor.run {
            currentUser = User(
                id: UUID(),
                email: email,
                firstName: "Test User",
                createdAt: Date()
            )
            isAuthenticated = true
        }
    }
    
    func signUp(email: String, password: String, firstName: String) async throws {
        // Mock implementation
        await MainActor.run {
            currentUser = User(
                id: UUID(),
                email: email,
                firstName: firstName,
                createdAt: Date()
            )
            isAuthenticated = true
        }
    }
    
    func signOut() async throws {
        await MainActor.run {
            isAuthenticated = false
            currentUser = nil
        }
    }
    
    func resetPassword(email: String) async throws {
        // Mock implementation
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
    }
    
    // MARK: - Exercises
    
    func fetchExercises() async throws -> [Exercise] {
        guard let userId = currentUser?.id else { throw SupabaseError.userNotAuthenticated }
        
        // Enhanced mock data with more exercises
        return [
            Exercise(id: UUID(), userId: userId, name: "Bench Press", createdAt: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()),
            Exercise(id: UUID(), userId: userId, name: "Squat", createdAt: Calendar.current.date(byAdding: .day, value: -25, to: Date()) ?? Date()),
            Exercise(id: UUID(), userId: userId, name: "Deadlift", createdAt: Calendar.current.date(byAdding: .day, value: -20, to: Date()) ?? Date()),
            Exercise(id: UUID(), userId: userId, name: "Overhead Press", createdAt: Calendar.current.date(byAdding: .day, value: -15, to: Date()) ?? Date()),
            Exercise(id: UUID(), userId: userId, name: "Barbell Row", createdAt: Calendar.current.date(byAdding: .day, value: -10, to: Date()) ?? Date()),
            Exercise(id: UUID(), userId: userId, name: "Pull-ups", createdAt: Calendar.current.date(byAdding: .day, value: -8, to: Date()) ?? Date()),
            Exercise(id: UUID(), userId: userId, name: "Dips", createdAt: Calendar.current.date(byAdding: .day, value: -6, to: Date()) ?? Date()),
            Exercise(id: UUID(), userId: userId, name: "Bulgarian Split Squat", createdAt: Calendar.current.date(byAdding: .day, value: -4, to: Date()) ?? Date()),
            Exercise(id: UUID(), userId: userId, name: "Lat Pulldown", createdAt: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()),
            Exercise(id: UUID(), userId: userId, name: "Incline Dumbbell Press", createdAt: Date())
        ]
    }
    
    func createExercise(name: String) async throws -> Exercise {
        guard let userId = currentUser?.id else { throw SupabaseError.userNotAuthenticated }
        
        // Add a small delay to simulate network call
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        return Exercise(
            id: UUID(),
            userId: userId,
            name: name,
            createdAt: Date()
        )
    }
    
    func deleteExercise(exerciseId: UUID) async throws {
        guard currentUser != nil else { throw SupabaseError.userNotAuthenticated }
        
        // Add a small delay to simulate network call
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        // Mock implementation - in real app would delete from Supabase
    }
    
    // MARK: - Workouts
    
    func createWorkout(category: String) async throws -> Workout {
        guard let userId = currentUser?.id else { throw SupabaseError.userNotAuthenticated }
        
        return Workout(
            id: UUID(),
            userId: userId,
            category: category,
            startedAt: Date(),
            endedAt: nil
        )
    }
    
    func endWorkout(workoutId: UUID) async throws {
        // Mock implementation - would update the workout's endedAt time
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        // In a real implementation, this would update the workout in the database
        // For now, we'll ensure the workout gets an endedAt time
        // The mock data in fetchWorkouts already provides historical workouts
    }
    
    func fetchWorkouts(limit: Int = 50) async throws -> [Workout] {
        guard let userId = currentUser?.id else { throw SupabaseError.userNotAuthenticated }
        
        // Enhanced mock data with more workout history
        var workouts: [Workout] = []
        
        let categories = ["Push Day", "Pull Day", "Leg Day", "Cardio", "Full Body"]
        
        for i in 0..<15 {
            let startDate = Calendar.current.date(byAdding: .day, value: -i * 2, to: Date()) ?? Date()
            let endDate = Calendar.current.date(byAdding: .hour, value: 1, to: startDate)
            
            var workout = Workout(
                id: UUID(),
                userId: userId,
                category: categories[i % categories.count],
                startedAt: startDate,
                endedAt: endDate
            )
            
            // Add some mock exercises to workouts
            workout.exercises = generateMockWorkoutExercises(for: workout.category)
            
            workouts.append(workout)
        }
        
        return workouts
    }
    
    func fetchRecentWorkouts(limit: Int = 5) async throws -> [Workout] {
        let allWorkouts = try await fetchWorkouts()
        return Array(allWorkouts.prefix(limit))
    }
    
    func fetchExercisePerformances() async throws -> [ExercisePerformance] {
        guard let userId = currentUser?.id else { throw SupabaseError.userNotAuthenticated }
        
        // Mock performance data
        let exercises = try await fetchExercises()
        var performances: [ExercisePerformance] = []
        
        for exercise in exercises.prefix(5) { // Only provide performance for some exercises
            let mockSets = [
                ExerciseSet(id: UUID(), workoutId: UUID(), exerciseId: exercise.id, weight: 135, reps: 10),
                ExerciseSet(id: UUID(), workoutId: UUID(), exerciseId: exercise.id, weight: 135, reps: 8),
                ExerciseSet(id: UUID(), workoutId: UUID(), exerciseId: exercise.id, weight: 125, reps: 12)
            ]
            
            let performance = ExercisePerformance(
                exerciseId: exercise.id,
                exerciseName: exercise.name,
                lastWorkoutSets: mockSets,
                lastWorkoutDate: Calendar.current.date(byAdding: .day, value: -3, to: Date())
            )
            
            performances.append(performance)
        }
        
        return performances
    }
    
    private func generateMockWorkoutExercises(for category: String) -> [WorkoutExercise] {
        let exerciseNames: [String]
        
        switch category {
        case "Push Day":
            exerciseNames = ["Bench Press", "Overhead Press", "Dips"]
        case "Pull Day":
            exerciseNames = ["Pull-ups", "Barbell Row", "Lat Pulldown"]
        case "Leg Day":
            exerciseNames = ["Squat", "Deadlift", "Bulgarian Split Squat"]
        case "Cardio":
            exerciseNames = ["Treadmill", "Bike"]
        default:
            exerciseNames = ["Bench Press", "Squat", "Pull-ups"]
        }
        
        return exerciseNames.map { name in
            let sets = [
                ExerciseSet(id: UUID(), workoutId: UUID(), exerciseId: UUID(), weight: Double.random(in: 100...200), reps: Int.random(in: 6...12)),
                ExerciseSet(id: UUID(), workoutId: UUID(), exerciseId: UUID(), weight: Double.random(in: 100...200), reps: Int.random(in: 6...12)),
                ExerciseSet(id: UUID(), workoutId: UUID(), exerciseId: UUID(), weight: Double.random(in: 100...200), reps: Int.random(in: 6...12))
            ]
            
            return WorkoutExercise(
                id: UUID(),
                exerciseId: UUID(),
                exerciseName: name,
                sets: sets
            )
        }
    }
    
    func fetchWorkoutStats() async throws -> WorkoutStats {
        guard currentUser != nil else { throw SupabaseError.userNotAuthenticated }
        
        // Mock data
        return WorkoutStats(
            monthlyCount: 12,
            weeklyCount: 3,
            categoryBreakdown: [
                "Push Day": 4,
                "Pull Day": 4,
                "Leg Day": 3,
                "Cardio": 1
            ]
        )
    }
    
    // MARK: - Sets
    
    func createSet(workoutId: UUID, exerciseId: UUID, weight: Double, reps: Int) async throws -> ExerciseSet {
        return ExerciseSet(
            id: UUID(),
            workoutId: workoutId,
            exerciseId: exerciseId,
            weight: weight,
            reps: reps,
            createdAt: Date()
        )
    }
    
    func fetchExerciseHistory(exerciseId: UUID, limit: Int = 10) async throws -> [ExerciseSet] {
        // Mock data
        return [
            ExerciseSet(id: UUID(), workoutId: UUID(), exerciseId: exerciseId, weight: 135, reps: 10, createdAt: Date()),
            ExerciseSet(id: UUID(), workoutId: UUID(), exerciseId: exerciseId, weight: 140, reps: 8, createdAt: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()),
            ExerciseSet(id: UUID(), workoutId: UUID(), exerciseId: exerciseId, weight: 130, reps: 12, createdAt: Calendar.current.date(byAdding: .day, value: -4, to: Date()) ?? Date())
        ]
    }
    
    // MARK: - Body Weight
    
    func logBodyWeight(weight: Double, unit: WeightUnit) async throws -> BodyWeight {
        guard let userId = currentUser?.id else { throw SupabaseError.userNotAuthenticated }
        
        return BodyWeight(
            id: UUID(),
            userId: userId,
            weight: weight,
            unit: unit,
            loggedAt: Date()
        )
    }
    
    func fetchBodyWeights(limit: Int = 30) async throws -> [BodyWeight] {
        guard let userId = currentUser?.id else { throw SupabaseError.userNotAuthenticated }
        
        // Mock data with some progression
        var weights: [BodyWeight] = []
        for i in 0..<10 {
            let date = Calendar.current.date(byAdding: .day, value: -i * 3, to: Date()) ?? Date()
            let weight = 180.0 + Double.random(in: -2...2) - Double(i) * 0.5 // Slight downward trend
            weights.append(BodyWeight(
                id: UUID(),
                userId: userId,
                weight: weight,
                unit: .lb,
                loggedAt: date
            ))
        }
        return weights
    }
}

// MARK: - Supporting Types

struct WorkoutStats {
    let monthlyCount: Int
    let weeklyCount: Int
    let categoryBreakdown: [String: Int]
}

enum SupabaseError: LocalizedError {
    case userNotAuthenticated
    case createFailed
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User not authenticated"
        case .createFailed:
            return "Failed to create record"
        }
    }
} 