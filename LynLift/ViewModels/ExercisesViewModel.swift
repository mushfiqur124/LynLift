import Foundation
import Combine

@MainActor
class ExercisesViewModel: ObservableObject {
    @Published var exercises: [Exercise] = []
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false
    @Published var showAddExercise = false
    @Published var newExerciseName = ""
    @Published var exercisePerformances: [UUID: ExercisePerformance] = [:]
    
    private let supabaseService = SupabaseService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadExercises()
        
        // Listen for authentication changes
        supabaseService.$isAuthenticated
            .sink { [weak self] isAuthenticated in
                if isAuthenticated {
                    self?.loadExercises()
                }
            }
            .store(in: &cancellables)
    }
    
    func loadExercises() {
        guard supabaseService.isAuthenticated else { return }
        
        isLoading = true
        
        Task {
            do {
                let fetchedExercises = try await supabaseService.getExercises()
                await MainActor.run {
                    self.exercises = fetchedExercises.sorted { $0.name < $1.name }
                    self.isLoading = false
                }
                
                // Load performance data for all exercises
                await loadAllExercisePerformances()
            } catch {
                await MainActor.run {
                    self.handleError(error)
                }
            }
        }
    }
    
    func loadAllExercisePerformances() async {
        var performances: [UUID: ExercisePerformance] = [:]
        
        for exercise in exercises {
            do {
                if let performance = try await supabaseService.getExercisePerformance(exerciseId: exercise.id) {
                    performances[exercise.id] = performance
                }
            } catch {
                // Don't show error for performance loading - it's not critical
                print("Failed to load performance for \(exercise.name): \(error)")
            }
        }
        
        await MainActor.run {
            self.exercisePerformances = performances
        }
    }
    
    func loadExercisePerformance(for exerciseId: UUID) {
        // Don't reload if we already have data
        guard exercisePerformances[exerciseId] == nil else { return }
        
        Task {
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
    }
    
    func getLastWorkoutForExercise(_ exerciseId: UUID) -> String? {
        guard let performance = exercisePerformances[exerciseId],
              let lastSet = performance.lastWorkoutSets.first else { return nil }
        
        let weightFormatted = lastSet.weight.truncatingRemainder(dividingBy: 1) == 0 ? 
            String(format: "%.0f", lastSet.weight) : String(format: "%.1f", lastSet.weight)
        
        return "\(weightFormatted) × \(lastSet.reps)"
    }
    
    func createExercise() async {
        let trimmedName = newExerciseName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = "Exercise name cannot be empty"
            showError = true
            return
        }
        
        // Check for duplicates
        if exercises.contains(where: { $0.name.lowercased() == trimmedName.lowercased() }) {
            errorMessage = "An exercise with this name already exists"
            showError = true
            return
        }
        
        do {
            let newExercise = try await supabaseService.createExercise(name: trimmedName)
            exercises.append(newExercise)
            exercises.sort { $0.name < $1.name }
            
            // Clear form and close sheet
            newExerciseName = ""
            showAddExercise = false
        } catch {
            handleError(error)
        }
    }
    
    func deleteExercise(_ exercise: Exercise) {
        // For now, just remove from local array
        // In real implementation, would call supabaseService.deleteExercise()
        exercises.removeAll { $0.id == exercise.id }
        // Also remove performance data
        exercisePerformances.removeValue(forKey: exercise.id)
    }
    
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
        isLoading = false
    }
}

// MARK: - Computed Properties
extension ExercisesViewModel {
    var filteredExercises: [Exercise] {
        if searchText.isEmpty {
            return exercises
        } else {
            return exercises.filter { exercise in
                exercise.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var canCreateExercise: Bool {
        !newExerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var exerciseCount: Int {
        exercises.count
    }
} 