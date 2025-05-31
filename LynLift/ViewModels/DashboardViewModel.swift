import Foundation
import Combine

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var workoutStats: WorkoutStats?
    @Published var recentWorkouts: [Workout] = []
    @Published var recentWeights: [BodyWeight] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false
    
    // Weight entry
    @Published var showWeightEntry = false
    @Published var newWeight = ""
    @Published var selectedUnit: WeightUnit = .kg
    
    private let supabaseService = SupabaseService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadDashboardData()
        
        // Listen for authentication changes
        supabaseService.$isAuthenticated
            .sink { [weak self] isAuthenticated in
                if isAuthenticated {
                    self?.loadDashboardData()
                }
            }
            .store(in: &cancellables)
    }
    
    func loadDashboardData() {
        guard supabaseService.isAuthenticated else { return }
        
        isLoading = true
        
        Task {
            do {
                async let statsTask = supabaseService.fetchWorkoutStats()
                async let workoutsTask = supabaseService.fetchRecentWorkouts(limit: 5)
                async let weightsTask = supabaseService.fetchBodyWeights(limit: 10)
                
                let (stats, workouts, weights) = await (
                    try statsTask,
                    try workoutsTask,
                    try weightsTask
                )
                
                await MainActor.run {
                    self.workoutStats = stats
                    self.recentWorkouts = workouts
                    self.recentWeights = weights
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.handleError(error)
                }
            }
        }
    }
    
    func logWeight() async {
        guard let weight = Double(newWeight), weight > 0 else {
            errorMessage = "Please enter a valid weight"
            showError = true
            return
        }
        
        do {
            let newBodyWeight = try await supabaseService.logBodyWeight(weight: weight, unit: selectedUnit)
            recentWeights.insert(newBodyWeight, at: 0)
            if recentWeights.count > 10 {
                recentWeights.removeLast()
            }
            
            // Clear form and close sheet
            newWeight = ""
            showWeightEntry = false
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
extension DashboardViewModel {
    var greetingMessage: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let greeting: String
        
        switch hour {
        case 5..<12:
            greeting = "Good morning"
        case 12..<17:
            greeting = "Good afternoon"
        case 17..<22:
            greeting = "Good evening"
        default:
            greeting = "Good night"
        }
        
        if let firstName = supabaseService.currentUser?.firstName, !firstName.isEmpty {
            return "\(greeting), \(firstName)!"
        } else {
            return "\(greeting)!"
        }
    }
    
    var lastWorkoutText: String {
        guard let lastWorkout = recentWorkouts.first else {
            return "No workouts yet"
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        let relativeDate = formatter.localizedString(for: lastWorkout.startedAt, relativeTo: Date())
        
        return "Last workout: \(lastWorkout.category) • \(relativeDate)"
    }
    
    var weightProgressData: [WeightDataPoint] {
        return recentWeights
            .sorted { $0.loggedAt < $1.loggedAt }
            .map { WeightDataPoint(date: $0.loggedAt, weight: $0.weight, unit: $0.unit) }
    }
    
    var latestWeight: BodyWeight? {
        return recentWeights.first
    }
    
    var canLogWeight: Bool {
        guard let weight = Double(newWeight) else { return false }
        return weight > 0
    }
}

// Supporting types for charts
struct WeightDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let weight: Double
    let unit: WeightUnit
} 