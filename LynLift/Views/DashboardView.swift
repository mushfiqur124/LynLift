import SwiftUI
import Charts

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Greeting Header
                    greetingSection
                    
                    // Quick Stats
                    if let stats = viewModel.workoutStats {
                        statsSection(stats)
                    }
                    
                    // Weight Progress Chart
                    if !viewModel.recentWeights.isEmpty {
                        weightProgressSection
                    }
                    
                    // Recent Workouts
                    recentWorkoutsSection
                    
                    // Quick Actions
                    quickActionsSection
                }
                .padding(.horizontal)
                .padding(.top)
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                viewModel.loadDashboardData()
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .sheet(isPresented: $viewModel.showWeightEntry) {
            weightEntrySheet
        }
    }
    
    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.greetingMessage)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    
                    Text(viewModel.lastWorkoutText)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Profile image placeholder
                Circle()
                    .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                    )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
    
    private func statsSection(_ stats: WorkoutStats) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This Month")
                .font(.system(size: 20, weight: .semibold))
            
            HStack(spacing: 12) {
                // Monthly workouts
                StatCard(
                    title: "Workouts",
                    value: "\(stats.monthlyCount)",
                    icon: "dumbbell.fill",
                    color: .blue
                )
                
                // Weekly workouts
                StatCard(
                    title: "This Week",
                    value: "\(stats.weeklyCount)",
                    icon: "calendar.badge.clock",
                    color: .green
                )
            }
            
            // Workout type breakdown
            if !stats.categoryBreakdown.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Workout Types")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                        ForEach(Array(stats.categoryBreakdown.keys), id: \.self) { category in
                            HStack {
                                Text(category)
                                    .font(.system(size: 14, weight: .medium))
                                
                                Spacer()
                                
                                Text("\(stats.categoryBreakdown[category] ?? 0)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.blue)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    private var weightProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Weight Progress")
                    .font(.system(size: 20, weight: .semibold))
                
                Spacer()
                
                if let latestWeight = viewModel.latestWeight {
                    Text(latestWeight.displayWeight)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                }
            }
            
            if viewModel.weightProgressData.count > 1 {
                Chart(viewModel.weightProgressData) { dataPoint in
                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Weight", dataPoint.weight)
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    PointMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Weight", dataPoint.weight)
                    )
                    .foregroundStyle(.blue)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                    }
                }
            } else {
                Text("Add more weight entries to see your progress")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(height: 100)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    private var recentWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Workouts")
                .font(.system(size: 20, weight: .semibold))
            
            if viewModel.recentWorkouts.isEmpty {
                Text("No workouts yet. Start your first workout!")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.recentWorkouts) { workout in
                        WorkoutRowView(workout: workout)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    private var quickActionsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(action: {
                    // TODO: Navigate to workout tab - needs to be handled at MainTabView level
                }) {
                    Label("Start Workout", systemImage: "plus.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Button(action: {
                    viewModel.showWeightEntry = true
                }) {
                    Label("Log Weight", systemImage: "scalemass.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding()
    }
    
    private var weightEntrySheet: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Log Your Weight")
                    .font(.system(size: 24, weight: .bold))
                    .padding(.top)
                
                VStack(spacing: 16) {
                    HStack {
                        TextField("Enter weight", text: $viewModel.newWeight)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Picker("Unit", selection: $viewModel.selectedUnit) {
                            ForEach(WeightUnit.allCases, id: \.self) { unit in
                                Text(unit.symbol).tag(unit)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 80)
                    }
                    
                    Button(action: {
                        Task {
                            await viewModel.logWeight()
                        }
                    }) {
                        Text("Save Weight")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(viewModel.canLogWeight ? .blue : .gray)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(!viewModel.canLogWeight)
                }
                .padding()
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.showWeightEntry = false
                    }
                }
            }
        }
        .presentationDetents([.height(300)])
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 16, weight: .semibold))
                
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}

struct WorkoutRowView: View {
    let workout: Workout
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.category)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(workout.startedAt, style: .date)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(workout.formattedDuration)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
                
                if workout.isActive {
                    Text("Active")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    DashboardView()
} 