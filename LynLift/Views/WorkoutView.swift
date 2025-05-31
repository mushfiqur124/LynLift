import SwiftUI

struct WorkoutView: View {
    @StateObject private var viewModel = WorkoutViewModel()
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.hasActiveWorkout {
                    activeWorkoutView
                } else {
                    workoutStartView
                }
            }
            .navigationTitle("Workout")
            .navigationBarTitleDisplayMode(.large)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .sheet(isPresented: $viewModel.showCategorySelection) {
            WorkoutCategorySelectionView(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showExerciseSelection) {
            exerciseSelectionSheet
        }
    }
    
    private var workoutStartView: some View {
        VStack(spacing: 30) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            VStack(spacing: 12) {
                Text("Ready to Workout?")
                    .font(.system(size: 28, weight: .bold))
                
                Text("Choose a workout category to get started")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                viewModel.showCategorySelection = true
            }) {
                Label("Start Workout", systemImage: "plus.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .padding()
    }
    
    private var activeWorkoutView: some View {
        VStack(spacing: 0) {
            // Workout header
            workoutHeaderView
            
            // Exercise list
            if viewModel.workoutExercises.isEmpty {
                emptyWorkoutView
            } else {
                workoutExercisesList
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Finish Workout") {
                    Task {
                        await viewModel.endWorkout()
                    }
                }
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .semibold))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.red)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
    
    private var workoutHeaderView: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.currentWorkout?.category ?? "Workout")
                        .font(.system(size: 24, weight: .bold))
                    
                    Text("Duration: \(viewModel.workoutDuration)")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(viewModel.workoutExercises.count)")
                        .font(.system(size: 20, weight: .bold))
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
                ForEach(viewModel.workoutExercises) { exerciseData in // Show exercises in order (newest at top)
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
    
    private var exerciseSelectionSheet: some View {
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
                List(viewModel.filteredExercises) { exercise in
                    Button(action: {
                        viewModel.addExerciseToWorkout(exercise)
                    }) {
                        HStack {
                            Text(exercise.name)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                            
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
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.showExerciseSelection = false
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct WorkoutExerciseCard: View {
    let exerciseData: WorkoutExerciseData
    let onAddSet: () -> Void
    let onRemoveSet: (Int) -> Void
    let onUpdateSet: (Int, Double, Int) -> Void
    let onSaveSet: (Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Exercise header with performance
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(exerciseData.exercise.name)
                        .font(.system(size: 20, weight: .bold))
                    
                    Spacer()
                    
                    Button(action: onAddSet) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                    }
                }
                
                // Show previous performance if available
                if let performance = exerciseData.performance {
                    HStack {
                        Text("Last workout:")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        Text(performance.lastWorkoutSummary)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.blue)
                        
                        Spacer()
                        
                        if let lastDate = performance.lastWorkoutDate {
                            Text(lastDate, style: .relative)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            
            // Sets
            if exerciseData.sets.isEmpty {
                Text("No sets yet")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                VStack(spacing: 8) {
                    // Header row
                    HStack {
                        Text("Set")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(width: 40, alignment: .leading)
                        
                        Text("Weight (lbs)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                        
                        Text("Reps")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                        
                        Text("")
                            .frame(width: 60)
                    }
                    .padding(.horizontal, 12)
                    
                    ForEach(Array(exerciseData.sets.enumerated()), id: \.offset) { index, set in
                        SetRowView(
                            setNumber: index + 1,
                            set: set,
                            onUpdate: { weight, reps in
                                onUpdateSet(index, weight, reps)
                            },
                            onSave: {
                                onSaveSet(index)
                            },
                            onRemove: {
                                onRemoveSet(index)
                            }
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}

struct SetRowView: View {
    let setNumber: Int
    @State private var set: NewExerciseSet
    let onUpdate: (Double, Int) -> Void
    let onSave: () -> Void
    let onRemove: () -> Void
    
    @State private var weightText: String = ""
    @State private var repsText: String = ""
    @FocusState private var isWeightFocused: Bool
    @FocusState private var isRepsFocused: Bool
    
    init(setNumber: Int, set: NewExerciseSet, onUpdate: @escaping (Double, Int) -> Void, onSave: @escaping () -> Void, onRemove: @escaping () -> Void) {
        self.setNumber = setNumber
        self._set = State(initialValue: set)
        self.onUpdate = onUpdate
        self.onSave = onSave
        self.onRemove = onRemove
        self._weightText = State(initialValue: set.weight > 0 ? "\(set.weight)" : "")
        self._repsText = State(initialValue: set.reps > 0 ? "\(set.reps)" : "")
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Text("\(setNumber)")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .leading)
            
            TextField("0", text: $weightText)
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(maxWidth: .infinity)
                .focused($isWeightFocused)
                .onChange(of: weightText) { newValue in
                    if let weight = Double(newValue), let reps = Int(repsText) {
                        onUpdate(weight, reps)
                    }
                }
            
            TextField("0", text: $repsText)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(maxWidth: .infinity)
                .focused($isRepsFocused)
                .onChange(of: repsText) { newValue in
                    if let weight = Double(weightText), let reps = Int(newValue) {
                        onUpdate(weight, reps)
                    }
                }
            
            if set.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .frame(width: 60)
            } else if !weightText.isEmpty && !repsText.isEmpty {
                Button(action: {
                    onSave()
                    // Clear focus after saving
                    isWeightFocused = false
                    isRepsFocused = false
                }) {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.blue)
                }
                .frame(width: 60)
            } else {
                Button(action: onRemove) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .frame(width: 60)
            }
        }
        .opacity(set.isCompleted ? 0.6 : 1.0)
    }
}

#Preview {
    WorkoutView()
} 