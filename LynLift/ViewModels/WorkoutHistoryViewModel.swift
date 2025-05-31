import Foundation
import Combine

@MainActor
class WorkoutHistoryViewModel: ObservableObject {
    @Published var workouts: [Workout] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false
    
    private let supabaseService = SupabaseService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadWorkouts()
        
        // Listen for authentication changes
        supabaseService.$isAuthenticated
            .sink { [weak self] isAuthenticated in
                if isAuthenticated {
                    self?.loadWorkouts()
                }
            }
            .store(in: &cancellables)
        
        // Listen for workout completion notifications
        NotificationCenter.default.publisher(for: .workoutCompleted)
            .sink { [weak self] _ in
                self?.refreshWorkouts()
            }
            .store(in: &cancellables)
    }
    
    func loadWorkouts() {
        guard supabaseService.isAuthenticated else { return }
        
        isLoading = true
        
        Task {
            do {
                let fetchedWorkouts = try await supabaseService.getWorkouts()
                await MainActor.run {
                    self.workouts = fetchedWorkouts.sorted { $0.startedAt > $1.startedAt }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.handleError(error)
                }
            }
        }
    }
    
    func refreshWorkouts() {
        // Force refresh the workouts list - useful after completing a workout
        loadWorkouts()
    }
    
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
        isLoading = false
    }
}

// MARK: - Computed Properties
extension WorkoutHistoryViewModel {
    var workoutCount: Int {
        workouts.count
    }
    
    var thisWeekWorkouts: [Workout] {
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        
        return workouts.filter { workout in
            workout.startedAt >= startOfWeek
        }
    }
    
    var thisMonthWorkouts: [Workout] {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        return workouts.filter { workout in
            workout.startedAt >= startOfMonth
        }
    }
} 