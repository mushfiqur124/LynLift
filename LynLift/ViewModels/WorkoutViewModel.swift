import Foundation
import Combine

@MainActor
class WorkoutViewModel: ObservableObject {
    @Published var currentWorkout: Workout?
    @Published var workoutExercises: [WorkoutExerciseData] = []
    @Published var showCategorySelection = false
    @Published var showExerciseSelection = false
    @Published var showCustomWorkoutNaming = false
    @Published var selectedCategory: WorkoutCategory = .push
    @Published var customWorkoutName = ""
    @Published var availableExercises: [Exercise] = []
    @Published var exercisePerformances: [UUID: ExercisePerformance] = [:]
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false
    @Published var isWorkoutPaused = false
    @Published var pausedAtTime: TimeInterval = 0 // Track the time when paused
    
    private let supabaseService = SupabaseService.shared
    private var cancellables = Set<AnyCancellable>()
    private var pauseStartTime: Date?
    
    init() {
        // Listen for authentication changes
        supabaseService.$isAuthenticated
            .sink { [weak self] isAuthenticated in
                if isAuthenticated {
                    self?.loadExercises()
                }
            }
            .store(in: &cancellables)
    }
    
    func startWorkout(category: WorkoutCategory) async {
        do {
            let workout = try await supabaseService.createWorkout(category: category, customName: category == .custom ? customWorkoutName : nil)
            currentWorkout = workout
            workoutExercises = []
            isWorkoutPaused = false
            pausedAtTime = 0
            showCategorySelection = false
            showCustomWorkoutNaming = false
            
            // Load exercise performances for this category
            await loadExercisePerformances()
        } catch {
            handleError(error)
        }
    }
    
    func startCustomWorkout(name: String) async {
        do {
            let workout = try await supabaseService.createWorkout(category: .custom, customName: name)
            currentWorkout = workout
            workoutExercises = []
            isWorkoutPaused = false
            pausedAtTime = 0
            showCategorySelection = false
            showCustomWorkoutNaming = false
            
            // Load exercise performances
            await loadExercisePerformances()
        } catch {
            handleError(error)
        }
    }
    
    func endWorkout() async {
        guard var workout = currentWorkout else { return }
        
        do {
            // Update workout with final pause duration if paused
            if isWorkoutPaused, let pauseStart = pauseStartTime {
                workout.pausedDuration += Date().timeIntervalSince(pauseStart)
            }
            
            // Set the ended time
            workout.endedAt = Date()
            
            try await supabaseService.updateWorkout(workout)
            currentWorkout = nil
            workoutExercises = []
            exercisePerformances = [:]
            isWorkoutPaused = false
            pauseStartTime = nil
            pausedAtTime = 0
            
            // Notify that a workout was completed to refresh history
            NotificationCenter.default.post(name: .workoutCompleted, object: nil)
        } catch {
            handleError(error)
        }
    }
    
    func toggleWorkoutPause() {
        guard let workout = currentWorkout else { return }
        
        if isWorkoutPaused {
            // Resuming workout
            if let pauseStart = pauseStartTime {
                currentWorkout?.pausedDuration += Date().timeIntervalSince(pauseStart)
                pauseStartTime = nil
            }
            isWorkoutPaused = false
        } else {
            // Pausing workout
            pausedAtTime = Date().timeIntervalSince(workout.startedAt) - workout.pausedDuration
            pauseStartTime = Date()
            isWorkoutPaused = true
        }
    }
    
    func loadExercises() {
        Task {
            do {
                let exercises = try await supabaseService.getExercises()
                await MainActor.run {
                    self.availableExercises = exercises
                }
            } catch {
                await MainActor.run {
                    self.handleError(error)
                }
            }
        }
    }
    
    func loadExercisePerformances() async {
        do {
            // Load performance for each available exercise
            var performances: [UUID: ExercisePerformance] = [:]
            
            for exercise in availableExercises {
                if let performance = try await supabaseService.getExercisePerformance(exerciseId: exercise.id) {
                    performances[exercise.id] = performance
                }
            }
            
            await MainActor.run {
                self.exercisePerformances = performances
            }
        } catch {
            // Don't show error for performance loading - it's not critical
            print("Failed to load exercise performances: \(error)")
        }
    }
    
    func addExerciseToWorkout(_ exercise: Exercise) {
        // Check if exercise is already in workout
        if !workoutExercises.contains(where: { $0.exercise.id == exercise.id }) {
            let workoutExercise = WorkoutExerciseData(
                exercise: exercise,
                sets: [NewExerciseSet()],
                performance: exercisePerformances[exercise.id]
            )
            // Add to beginning of list (newest at top)
            workoutExercises.insert(workoutExercise, at: 0)
        }
        showExerciseSelection = false
    }
    
    func createAndAddExercise(name: String) async {
        do {
            let newExercise = try await supabaseService.createExercise(name: name)
            availableExercises.append(newExercise)
            
            // Load performance data for the new exercise if available
            await loadExercisePerformanceForExercise(newExercise.id)
            
            addExerciseToWorkout(newExercise)
        } catch {
            handleError(error)
        }
    }
    
    func loadExercisePerformanceForExercise(_ exerciseId: UUID) async {
        do {
            if let performance = try await supabaseService.getExercisePerformance(exerciseId: exerciseId) {
                await MainActor.run {
                    self.exercisePerformances[exerciseId] = performance
                }
            }
        } catch {
            // Don't show error for performance loading - it's not critical
            print("Failed to load exercise performance: \(error)")
        }
    }
    
    func addSetToExercise(_ exerciseId: UUID) {
        if let index = workoutExercises.firstIndex(where: { $0.exercise.id == exerciseId }) {
            workoutExercises[index].sets.append(NewExerciseSet())
        }
    }
    
    func removeSetFromExercise(_ exerciseId: UUID, at setIndex: Int) {
        if let exerciseIndex = workoutExercises.firstIndex(where: { $0.exercise.id == exerciseId }) {
            workoutExercises[exerciseIndex].sets.remove(at: setIndex)
        }
    }
    
    func updateSet(_ exerciseId: UUID, setIndex: Int, weight: Double, reps: Int) {
        if let exerciseIndex = workoutExercises.firstIndex(where: { $0.exercise.id == exerciseId }) {
            workoutExercises[exerciseIndex].sets[setIndex].weight = weight
            workoutExercises[exerciseIndex].sets[setIndex].reps = reps
        }
    }
    
    func saveSet(_ exerciseId: UUID, setIndex: Int) async {
        guard let workout = currentWorkout,
              let exerciseIndex = workoutExercises.firstIndex(where: { $0.exercise.id == exerciseId }),
              setIndex < workoutExercises[exerciseIndex].sets.count else { return }
        
        let set = workoutExercises[exerciseIndex].sets[setIndex]
        
        do {
            let exerciseSet = ExerciseSet(
                id: UUID(),
                workoutId: workout.id,
                exerciseId: exerciseId,
                weight: set.weight,
                reps: set.reps,
                createdAt: Date()
            )
            
            try await supabaseService.addExerciseSet(exerciseSet)
            
            // Mark set as completed
            workoutExercises[exerciseIndex].sets[setIndex].isCompleted = true
        } catch {
            handleError(error)
        }
    }
    
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
        isLoading = false
    }
}

// MARK: - Computed Properties
extension WorkoutViewModel {
    var filteredExercises: [Exercise] {
        if searchText.isEmpty {
            return availableExercises
        } else {
            return availableExercises.filter { exercise in
                exercise.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var workoutDuration: String {
        guard let workout = currentWorkout else { return "0:00" }
        
        let elapsed = Date().timeIntervalSince(workout.startedAt) - workout.pausedDuration
        let hours = Int(elapsed) / 3600
        let minutes = (Int(elapsed) % 3600) / 60
        let seconds = Int(elapsed) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    var totalSetsCompleted: Int {
        workoutExercises.reduce(0) { total, exercise in
            total + exercise.sets.filter { $0.isCompleted }.count
        }
    }
    
    var totalSets: Int {
        workoutExercises.reduce(0) { total, exercise in
            total + exercise.sets.count
        }
    }
    
    var hasActiveWorkout: Bool {
        currentWorkout != nil
    }
}

// MARK: - Supporting Types
struct WorkoutExerciseData: Identifiable {
    let exercise: Exercise
    var sets: [NewExerciseSet]
    let performance: ExercisePerformance?
    
    var id: UUID { exercise.id }
}

// MARK: - Notifications
extension Notification.Name {
    static let workoutCompleted = Notification.Name("workoutCompleted")
} 