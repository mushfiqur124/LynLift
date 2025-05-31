import SwiftUI

struct ActiveWorkoutView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var timer: Timer?
    @State private var currentTime = Date()
    @State private var pauseStartTime: Date?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Workout header with timer
                workoutHeaderView
                
                // Exercise list
                if viewModel.workoutExercises.isEmpty {
                    emptyWorkoutView
                } else {
                    workoutExercisesList
                }
            }
            .navigationTitle(viewModel.currentWorkout?.category ?? "Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Finish") {
                        Task {
                            await viewModel.endWorkout()
                            dismiss()
                        }
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.red)
                }
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .sheet(isPresented: $viewModel.showExerciseSelection) {
            ExerciseSelectionView(viewModel: viewModel)
        }
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    private var workoutHeaderView: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Button(action: {
                        viewModel.toggleWorkoutPause()
                    }) {
                        HStack(spacing: 8) {
                            Text(workoutDuration)
                                .font(.system(size: 28, weight: .bold, design: .monospaced))
                                .foregroundColor(.blue)
                            
                            Image(systemName: viewModel.isWorkoutPaused ? "play.circle.fill" : "pause.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.blue)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Text(pauseStatusText)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(viewModel.workoutExercises.count)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.blue)
                    
                    Text("Exercises")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            
            Button(action: {
                viewModel.showExerciseSelection = true
            }) {
                Label("Add Exercise", systemImage: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var emptyWorkoutView: some View {
        VStack(spacing: 20) {
            Image(systemName: "plus.circle.dashed")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No exercises yet")
                .font(.system(size: 18, weight: .semibold))
            
            Text("Add exercises to start tracking your sets")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var workoutExercisesList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.workoutExercises) { exerciseData in
                    WorkoutExerciseCard(
                        exerciseData: exerciseData,
                        onAddSet: {
                            viewModel.addSetToExercise(exerciseData.exercise.id)
                        },
                        onRemoveSet: { setIndex in
                            viewModel.removeSetFromExercise(exerciseData.exercise.id, at: setIndex)
                        },
                        onUpdateSet: { setIndex, weight, reps in
                            viewModel.updateSet(exerciseData.exercise.id, setIndex: setIndex, weight: weight, reps: reps)
                        },
                        onSaveSet: { setIndex in
                            Task {
                                await viewModel.saveSet(exerciseData.exercise.id, setIndex: setIndex)
                            }
                        }
                    )
                }
            }
            .padding()
        }
    }
    
    private var workoutDuration: String {
        guard let workout = viewModel.currentWorkout else { return "0:00" }
        
        let elapsed: TimeInterval
        if viewModel.isWorkoutPaused {
            // Show the time when it was paused
            elapsed = viewModel.pausedAtTime
        } else {
            // Show current elapsed time
            elapsed = currentTime.timeIntervalSince(workout.startedAt) - workout.pausedDuration
        }
        
        let hours = Int(elapsed) / 3600
        let minutes = (Int(elapsed) % 3600) / 60
        let seconds = Int(elapsed) % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    private var pauseStatusText: String {
        if viewModel.isWorkoutPaused {
            return "Workout Paused"
        } else {
            return "Workout Active"
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            currentTime = Date()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// Exercise Selection View for adding exercises during workout
struct ExerciseSelectionView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showAddExercise = false
    @State private var newExerciseName = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search exercises...", text: $viewModel.searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    if !viewModel.searchText.isEmpty {
                        Button(action: {
                            viewModel.searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding()
                
                // Exercise list
                if viewModel.filteredExercises.isEmpty && !viewModel.searchText.isEmpty {
                    // No results - show option to create new exercise
                    VStack(spacing: 16) {
                        Text("No exercises found")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            newExerciseName = viewModel.searchText
                            showAddExercise = true
                        }) {
                            Label("Create '\(viewModel.searchText)'", systemImage: "plus.circle.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                    .padding(.top, 40)
                } else {
                    List(viewModel.filteredExercises) { exercise in
                        Button(action: {
                            viewModel.addExerciseToWorkout(exercise)
                            dismiss()
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(exercise.name)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.primary)
                                    
                                    if let performance = viewModel.exercisePerformances[exercise.id] {
                                        Text("Last: \(performance.lastWorkoutSummary)")
                                            .font(.system(size: 14))
                                            .foregroundColor(.blue)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showAddExercise = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }
        }
        .sheet(isPresented: $showAddExercise) {
            AddExerciseSheet(
                exerciseName: $newExerciseName,
                onAdd: { name in
                    Task {
                        await viewModel.createAndAddExercise(name: name)
                        dismiss()
                    }
                }
            )
        }
    }
}

// Quick add exercise sheet
struct AddExerciseSheet: View {
    @Binding var exerciseName: String
    let onAdd: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Exercise Name")
                        .font(.system(size: 16, weight: .semibold))
                    
                    TextField("Enter exercise name", text: $exerciseName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.words)
                }
                .padding(.horizontal)
                .padding(.top)
                
                Button(action: {
                    let trimmedName = exerciseName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmedName.isEmpty {
                        onAdd(trimmedName)
                    }
                }) {
                    Text("Add Exercise")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(!exerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .blue : .gray)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(exerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.height(300)])
    }
}

#Preview {
    ActiveWorkoutView(viewModel: WorkoutViewModel())
} 