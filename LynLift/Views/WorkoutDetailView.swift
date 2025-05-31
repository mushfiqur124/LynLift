import SwiftUI

struct WorkoutDetailView: View {
    let workout: Workout
    @State private var editedWorkout: Workout
    @State private var isEditing = false
    @Environment(\.dismiss) private var dismiss
    
    init(workout: Workout) {
        self.workout = workout
        self._editedWorkout = State(initialValue: workout)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Workout header
                workoutHeaderSection
                
                // Exercise sections
                if editedWorkout.exercises.isEmpty {
                    emptyExercisesView
                } else {
                    ForEach(editedWorkout.exercises) { exercise in
                        ExerciseDetailSection(
                            exercise: exercise,
                            isEditing: isEditing,
                            onUpdateSet: { setIndex, weight, reps in
                                updateSet(exerciseId: exercise.id, setIndex: setIndex, weight: weight, reps: reps)
                            },
                            onRemoveSet: { setIndex in
                                removeSet(exerciseId: exercise.id, setIndex: setIndex)
                            },
                            onAddSet: {
                                addSet(exerciseId: exercise.id)
                            }
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle(editedWorkout.category)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        saveChanges()
                    }
                    isEditing.toggle()
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.blue)
            }
        }
    }
    
    private var workoutHeaderSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(editedWorkout.category)
                        .font(.system(size: 28, weight: .bold))
                    
                    Text(editedWorkout.startedAt, style: .date)
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Stats grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                StatBox(
                    title: "Duration",
                    value: editedWorkout.formattedDuration,
                    icon: "clock.fill",
                    color: .blue
                )
                
                StatBox(
                    title: "Exercises",
                    value: "\(editedWorkout.exercises.count)",
                    icon: "list.bullet",
                    color: .blue
                )
                
                StatBox(
                    title: "Total Sets",
                    value: "\(totalSets)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var emptyExercisesView: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No exercises recorded")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var totalSets: Int {
        editedWorkout.exercises.reduce(0) { $0 + $1.sets.count }
    }
    
    private func updateSet(exerciseId: UUID, setIndex: Int, weight: Double, reps: Int) {
        if let exerciseIndex = editedWorkout.exercises.firstIndex(where: { $0.id == exerciseId }),
           setIndex < editedWorkout.exercises[exerciseIndex].sets.count {
            editedWorkout.exercises[exerciseIndex].sets[setIndex] = ExerciseSet(
                id: editedWorkout.exercises[exerciseIndex].sets[setIndex].id,
                workoutId: editedWorkout.id,
                exerciseId: exerciseId,
                weight: weight,
                reps: reps,
                createdAt: editedWorkout.exercises[exerciseIndex].sets[setIndex].createdAt
            )
        }
    }
    
    private func removeSet(exerciseId: UUID, setIndex: Int) {
        if let exerciseIndex = editedWorkout.exercises.firstIndex(where: { $0.id == exerciseId }) {
            editedWorkout.exercises[exerciseIndex].sets.remove(at: setIndex)
        }
    }
    
    private func addSet(exerciseId: UUID) {
        if let exerciseIndex = editedWorkout.exercises.firstIndex(where: { $0.id == exerciseId }) {
            let newSet = ExerciseSet(
                workoutId: editedWorkout.id,
                exerciseId: exerciseId,
                weight: 0,
                reps: 0
            )
            editedWorkout.exercises[exerciseIndex].sets.append(newSet)
        }
    }
    
    private func saveChanges() {
        // In a real app, this would save to the database
        // For now, we'll just update the local copy
        // TODO: Implement actual save functionality
    }
}

struct ExerciseDetailSection: View {
    let exercise: WorkoutExercise
    let isEditing: Bool
    let onUpdateSet: (Int, Double, Int) -> Void
    let onRemoveSet: (Int) -> Void
    let onAddSet: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(exercise.exerciseName)
                    .font(.system(size: 20, weight: .bold))
                
                Spacer()
                
                if isEditing {
                    Button(action: onAddSet) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                    }
                }
            }
            
            if exercise.sets.isEmpty {
                Text("No sets recorded")
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
                        
                        Text("Weight")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                        
                        Text("Reps")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                        
                        Text("Volume")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                        
                        if isEditing {
                            Text("")
                                .frame(width: 40)
                        }
                    }
                    .padding(.horizontal, 12)
                    
                    ForEach(Array(exercise.sets.enumerated()), id: \.offset) { index, set in
                        ExerciseSetDetailRow(
                            setNumber: index + 1,
                            set: set,
                            isEditing: isEditing,
                            onUpdate: { weight, reps in
                                onUpdateSet(index, weight, reps)
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

struct ExerciseSetDetailRow: View {
    let setNumber: Int
    @State private var set: ExerciseSet
    let isEditing: Bool
    let onUpdate: (Double, Int) -> Void
    let onRemove: () -> Void
    
    @State private var weightText: String = ""
    @State private var repsText: String = ""
    
    init(setNumber: Int, set: ExerciseSet, isEditing: Bool, onUpdate: @escaping (Double, Int) -> Void, onRemove: @escaping () -> Void) {
        self.setNumber = setNumber
        self._set = State(initialValue: set)
        self.isEditing = isEditing
        self.onUpdate = onUpdate
        self.onRemove = onRemove
        
        let weightFormatted = set.weight.truncatingRemainder(dividingBy: 1) == 0 ? 
            String(format: "%.0f", set.weight) : String(format: "%.1f", set.weight)
        self._weightText = State(initialValue: set.weight > 0 ? weightFormatted : "")
        self._repsText = State(initialValue: set.reps > 0 ? "\(set.reps)" : "")
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Text("\(setNumber)")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .leading)
            
            if isEditing {
                TextField("Weight", text: $weightText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: .infinity)
                    .onChange(of: weightText) { newValue in
                        if let weight = Double(newValue), let reps = Int(repsText) {
                            onUpdate(weight, reps)
                        }
                    }
                
                TextField("Reps", text: $repsText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: .infinity)
                    .onChange(of: repsText) { newValue in
                        if let weight = Double(weightText), let reps = Int(newValue) {
                            onUpdate(weight, reps)
                        }
                    }
            } else {
                Text(set.weight > 0 ? set.displayText.components(separatedBy: " × ")[0] + " lbs" : "-")
                    .font(.system(size: 16))
                    .frame(maxWidth: .infinity)
                
                Text(set.reps > 0 ? "\(set.reps)" : "-")
                    .font(.system(size: 16))
                    .frame(maxWidth: .infinity)
            }
            
            Text(String(format: "%.0f lbs", set.volume))
                .font(.system(size: 16))
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
            
            if isEditing {
                Button(action: onRemove) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .frame(width: 40)
            }
        }
        .padding(.vertical, 4)
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    let sampleWorkout = Workout(
        id: UUID(),
        userId: UUID(),
        category: "Push Day",
        startedAt: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(),
        endedAt: Date()
    )
    
    return NavigationView {
        WorkoutDetailView(workout: sampleWorkout)
    }
} 