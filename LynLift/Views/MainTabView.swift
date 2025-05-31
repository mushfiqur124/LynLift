import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @StateObject private var workoutViewModel = WorkoutViewModel()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                    .tag(0)
                
                WorkoutHistoryView()
                    .tabItem {
                        Image(systemName: "clock.fill")
                        Text("History")
                    }
                    .tag(1)
                
                // Empty view for middle tab (handled by floating button)
                Color.clear
                    .tabItem {
                        Image(systemName: "")
                        Text("")
                    }
                    .tag(2)
                
                ExercisesView()
                    .tabItem {
                        Image(systemName: "list.bullet.clipboard.fill")
                        Text("Exercises")
                    }
                    .tag(3)
                
                ProfileView()
                    .tabItem {
                        Image(systemName: "person.fill")
                        Text("Profile")
                    }
                    .tag(4)
            }
            .accentColor(.blue) // Changed from orange to match app theme
            
            // Floating Start Workout Button
            Button(action: {
                workoutViewModel.showCategorySelection = true
            }) {
                ZStack {
                    Circle()
                        .fill(.blue) // Changed from orange to blue
                        .frame(width: 64, height: 64)
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .offset(y: -25) // Move up to overlap tab bar
            .sheet(isPresented: $workoutViewModel.showCategorySelection) {
                WorkoutCategorySelectionView(viewModel: workoutViewModel)
            }
            .fullScreenCover(isPresented: .constant(workoutViewModel.hasActiveWorkout)) {
                ActiveWorkoutView(viewModel: workoutViewModel)
            }
        }
    }
}

// New view for workout history (replaces main WorkoutView)
struct WorkoutHistoryView: View {
    @StateObject private var viewModel = WorkoutHistoryViewModel()
    @StateObject private var workoutViewModel = WorkoutViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.workouts.isEmpty {
                    emptyStateView
                } else {
                    workoutHistoryList
                }
            }
            .navigationTitle("Workout History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        workoutViewModel.showCategorySelection = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                }
            }
            .refreshable {
                viewModel.loadWorkouts()
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .sheet(isPresented: $workoutViewModel.showCategorySelection) {
            WorkoutCategorySelectionView(viewModel: workoutViewModel)
        }
        .fullScreenCover(isPresented: .constant(workoutViewModel.hasActiveWorkout)) {
            ActiveWorkoutView(viewModel: workoutViewModel)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("No Workouts Yet")
                .font(.system(size: 24, weight: .bold))
            
            Text("Start your fitness journey by logging your first workout")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                workoutViewModel.showCategorySelection = true
            }) {
                Label("Start Your First Workout", systemImage: "plus.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 250, height: 50)
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var workoutHistoryList: some View {
        List {
            ForEach(viewModel.workouts) { workout in
                NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                    WorkoutHistoryCardView(workout: workout)
                }
            }
        }
        .listStyle(PlainListStyle())
    }
}

#Preview {
    MainTabView()
} 