import Foundation
import Combine
import Supabase

@MainActor
class SupabaseService: ObservableObject {
    static let shared = SupabaseService()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    private let client: SupabaseClient
    
    private init() {
        guard let url = URL(string: SupabaseConfig.url) else {
            fatalError("Invalid Supabase URL")
        }
        
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: SupabaseConfig.anonKey
        )
        
        // Check for existing session
        Task {
            if let user = await getCurrentUser() {
                self.currentUser = user
                self.isAuthenticated = true
            }
        }
    }
    
    // MARK: - Authentication
    
    func signUp(email: String, password: String, firstName: String) async throws {
        let response = try await client.auth.signUp(
            email: email,
            password: password
        )
        
        guard let user = response.user else {
            throw SupabaseError.authenticationFailed
        }
        
        // Create user profile
        let userProfile = [
            "id": user.id.uuidString,
            "email": email,
            "first_name": firstName
        ]
        
        try await client
            .from("users")
            .insert(userProfile)
            .execute()
        
        await MainActor.run {
            self.currentUser = User(
                id: UUID(uuidString: user.id.uuidString) ?? UUID(),
                email: email,
                firstName: firstName,
                createdAt: Date()
            )
            self.isAuthenticated = true
        }
    }
    
    func signIn(email: String, password: String) async throws {
        let response = try await client.auth.signIn(
            email: email,
            password: password
        )
        
        guard let user = response.user else {
            throw SupabaseError.authenticationFailed
        }
        
        // Fetch user profile
        let userData: [String: Any] = try await client
            .from("users")
            .select("*")
            .eq("id", value: user.id)
            .single()
            .execute()
            .value
        
        await MainActor.run {
            self.currentUser = User(
                id: UUID(uuidString: user.id.uuidString) ?? UUID(),
                email: userData["email"] as? String ?? email,
                firstName: userData["first_name"] as? String ?? "",
                createdAt: parseDate(from: userData["created_at"] as? String) ?? Date()
            )
            self.isAuthenticated = true
        }
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
        await MainActor.run {
            self.isAuthenticated = false
            self.currentUser = nil
        }
    }
    
    func resetPassword(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email)
    }
    
    func getCurrentUser() async -> User? {
        guard let session = client.auth.session,
              let user = session.user else {
            return nil
        }
        
        do {
            let userData: [String: Any] = try await client
                .from("users")
                .select("*")
                .eq("id", value: user.id)
                .single()
                .execute()
                .value
            
            return User(
                id: UUID(uuidString: user.id.uuidString) ?? UUID(),
                email: userData["email"] as? String ?? "",
                firstName: userData["first_name"] as? String ?? "",
                createdAt: parseDate(from: userData["created_at"] as? String) ?? Date()
            )
        } catch {
            return nil
        }
    }
    
    // MARK: - Workouts
    
    func createWorkout(category: WorkoutCategory, customName: String? = nil) async throws -> Workout {
        guard let userId = client.auth.session?.user.id else {
            throw SupabaseError.notAuthenticated
        }
        
        let categoryName = category == .custom ? (customName ?? "Custom Workout") : category.rawValue
        
        let workoutData = [
            "user_id": userId.uuidString,
            "category": categoryName,
            "started_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        let response: [String: Any] = try await client
            .from("workouts")
            .insert(workoutData)
            .select()
            .single()
            .execute()
            .value
        
        return try parseWorkout(from: response)
    }
    
    func updateWorkout(_ workout: Workout) async throws {
        let workoutData: [String: Any] = [
            "category": workout.category.rawValue,
            "ended_at": workout.endedAt != nil ? ISO8601DateFormatter().string(from: workout.endedAt!) : nil,
            "paused_duration": formatInterval(workout.pausedDuration)
        ].compactMapValues { $0 }
        
        try await client
            .from("workouts")
            .update(workoutData)
            .eq("id", value: workout.id.uuidString)
            .execute()
    }
    
    func getWorkouts() async throws -> [Workout] {
        guard let userId = client.auth.session?.user.id else {
            throw SupabaseError.notAuthenticated
        }
        
        let response: [[String: Any]] = try await client
            .from("workouts")
            .select("*")
            .eq("user_id", value: userId)
            .order("started_at", ascending: false)
            .execute()
            .value
        
        return try response.map { try parseWorkout(from: $0) }
    }
    
    // MARK: - Exercises
    
    func createExercise(name: String) async throws -> Exercise {
        guard let userId = client.auth.session?.user.id else {
            throw SupabaseError.notAuthenticated
        }
        
        let exerciseData = [
            "user_id": userId.uuidString,
            "name": name
        ]
        
        let response: [String: Any] = try await client
            .from("exercises")
            .insert(exerciseData)
            .select()
            .single()
            .execute()
            .value
        
        return try parseExercise(from: response)
    }
    
    func getExercises() async throws -> [Exercise] {
        guard let userId = client.auth.session?.user.id else {
            throw SupabaseError.notAuthenticated
        }
        
        let response: [[String: Any]] = try await client
            .from("exercises")
            .select("*")
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return try response.map { try parseExercise(from: $0) }
    }
    
    func getExercisePerformance(exerciseId: UUID) async throws -> ExercisePerformance? {
        guard let userId = client.auth.session?.user.id else {
            throw SupabaseError.notAuthenticated
        }
        
        let response: [[String: Any]] = try await client
            .from("sets")
            .select("*, workouts!inner(*)")
            .eq("exercise_id", value: exerciseId.uuidString)
            .eq("workouts.user_id", value: userId)
            .not("workouts.ended_at", operator: .is, value: nil)
            .order("created_at", ascending: false)
            .limit(10)
            .execute()
            .value
        
        guard !response.isEmpty else { return nil }
        
        let sets = try response.map { try parseExerciseSet(from: $0) }
        let lastWorkoutSets = Array(sets.prefix(3)) // Get last 3 sets
        
        let exercise = try await getExercise(id: exerciseId)
        
        return ExercisePerformance(
            exerciseId: exerciseId,
            exerciseName: exercise?.name ?? "Unknown",
            lastWorkoutSets: lastWorkoutSets,
            lastWorkoutDate: sets.first?.createdAt
        )
    }
    
    func getExercise(id: UUID) async throws -> Exercise? {
        let response: [String: Any] = try await client
            .from("exercises")
            .select("*")
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
        
        return try parseExercise(from: response)
    }
    
    // MARK: - Exercise Sets
    
    func addExerciseSet(_ set: ExerciseSet) async throws {
        let setData = [
            "workout_id": set.workoutId.uuidString,
            "exercise_id": set.exerciseId.uuidString,
            "weight": set.weight,
            "reps": set.reps
        ]
        
        try await client
            .from("sets")
            .insert(setData)
            .execute()
    }
    
    func getExerciseSets(for workoutId: UUID) async throws -> [ExerciseSet] {
        let response: [[String: Any]] = try await client
            .from("sets")
            .select("*")
            .eq("workout_id", value: workoutId.uuidString)
            .order("created_at", ascending: true)
            .execute()
            .value
        
        return try response.map { try parseExerciseSet(from: $0) }
    }
    
    // MARK: - Body Weight
    
    func addBodyWeight(_ bodyWeight: BodyWeight) async throws {
        guard let userId = client.auth.session?.user.id else {
            throw SupabaseError.notAuthenticated
        }
        
        let weightData = [
            "user_id": userId.uuidString,
            "weight": bodyWeight.weight,
            "unit": bodyWeight.unit,
            "logged_at": ISO8601DateFormatter().string(from: bodyWeight.date)
        ]
        
        try await client
            .from("body_weights")
            .insert(weightData)
            .execute()
    }
    
    func getBodyWeights() async throws -> [BodyWeight] {
        guard let userId = client.auth.session?.user.id else {
            throw SupabaseError.notAuthenticated
        }
        
        let response: [[String: Any]] = try await client
            .from("body_weights")
            .select("*")
            .eq("user_id", value: userId)
            .order("logged_at", ascending: false)
            .execute()
            .value
        
        return try response.map { try parseBodyWeight(from: $0) }
    }
    
    // MARK: - Dashboard Stats
    
    func getDashboardStats() async throws -> DashboardStats {
        guard let userId = client.auth.session?.user.id else {
            throw SupabaseError.notAuthenticated
        }
        
        // Get workout counts
        let monthlyResponse: [[String: Any]] = try await client
            .from("workouts")
            .select("id")
            .eq("user_id", value: userId)
            .gte("started_at", value: startOfMonth())
            .not("ended_at", operator: .is, value: nil)
            .execute()
            .value
        
        let weeklyResponse: [[String: Any]] = try await client
            .from("workouts")
            .select("id")
            .eq("user_id", value: userId)
            .gte("started_at", value: startOfWeek())
            .not("ended_at", operator: .is, value: nil)
            .execute()
            .value
        
        let bodyWeights = try await getBodyWeights()
        let currentWeight = bodyWeights.first?.weight
        
        return DashboardStats(
            monthlyWorkouts: monthlyResponse.count,
            weeklyWorkouts: weeklyResponse.count,
            currentWeight: currentWeight
        )
    }
}

// MARK: - Parsing Helpers

private extension SupabaseService {
    func parseWorkout(from data: [String: Any]) throws -> Workout {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let categoryString = data["category"] as? String,
              let startedAtString = data["started_at"] as? String,
              let startedAt = parseDate(from: startedAtString) else {
            throw SupabaseError.invalidData
        }
        
        let category = WorkoutCategory(rawValue: categoryString) ?? .custom
        let endedAt = parseDate(from: data["ended_at"] as? String)
        let pausedDuration = parseInterval(from: data["paused_duration"] as? String) ?? 0
        
        return Workout(
            id: id,
            category: category,
            startedAt: startedAt,
            endedAt: endedAt,
            pausedDuration: pausedDuration
        )
    }
    
    func parseExercise(from data: [String: Any]) throws -> Exercise {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let name = data["name"] as? String else {
            throw SupabaseError.invalidData
        }
        
        return Exercise(id: id, name: name)
    }
    
    func parseExerciseSet(from data: [String: Any]) throws -> ExerciseSet {
        guard let idString = data["id"] as? String,
              let id = UUID(uuidString: idString),
              let workoutIdString = data["workout_id"] as? String,
              let workoutId = UUID(uuidString: workoutIdString),
              let exerciseIdString = data["exercise_id"] as? String,
              let exerciseId = UUID(uuidString: exerciseIdString),
              let weight = data["weight"] as? Double,
              let reps = data["reps"] as? Int else {
            throw SupabaseError.invalidData
        }
        
        let createdAt = parseDate(from: data["created_at"] as? String) ?? Date()
        
        return ExerciseSet(
            id: id,
            workoutId: workoutId,
            exerciseId: exerciseId,
            weight: weight,
            reps: reps,
            createdAt: createdAt
        )
    }
    
    func parseBodyWeight(from data: [String: Any]) throws -> BodyWeight {
        guard let weight = data["weight"] as? Double,
              let unit = data["unit"] as? String,
              let loggedAtString = data["logged_at"] as? String,
              let loggedAt = parseDate(from: loggedAtString) else {
            throw SupabaseError.invalidData
        }
        
        return BodyWeight(weight: weight, unit: unit, date: loggedAt)
    }
    
    func parseDate(from string: String?) -> Date? {
        guard let string = string else { return nil }
        return ISO8601DateFormatter().date(from: string)
    }
    
    func parseInterval(from string: String?) -> TimeInterval? {
        // Parse PostgreSQL interval format (e.g., "00:05:30")
        guard let string = string else { return nil }
        let components = string.components(separatedBy: ":")
        guard components.count >= 3,
              let hours = Double(components[0]),
              let minutes = Double(components[1]),
              let seconds = Double(components[2]) else {
            return nil
        }
        return hours * 3600 + minutes * 60 + seconds
    }
    
    func formatInterval(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    func startOfMonth() -> String {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
        return ISO8601DateFormatter().string(from: startOfMonth)
    }
    
    func startOfWeek() -> String {
        let calendar = Calendar.current
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return ISO8601DateFormatter().string(from: startOfWeek)
    }
}

// MARK: - Custom Errors

enum SupabaseError: Error, LocalizedError {
    case notAuthenticated
    case authenticationFailed
    case invalidData
    case networkError
    case userNotAuthenticated
    case createFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated, .userNotAuthenticated:
            return "User not authenticated"
        case .authenticationFailed:
            return "Authentication failed"
        case .invalidData:
            return "Invalid data format"
        case .networkError:
            return "Network error occurred"
        case .createFailed:
            return "Failed to create record"
        }
    }
}

// MARK: - Dashboard Stats Model

struct DashboardStats {
    let monthlyWorkouts: Int
    let weeklyWorkouts: Int
    let currentWeight: Double?
}

// MARK: - Exercise Performance Model

struct ExercisePerformance {
    let exerciseId: UUID
    let exerciseName: String
    let lastWorkoutSets: [ExerciseSet]
    let lastWorkoutDate: Date?
} 
} 