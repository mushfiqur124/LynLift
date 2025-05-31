import SwiftUI

struct WorkoutHistoryCardView: View {
    let workout: Workout
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.category)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(workout.startedAt, style: .date)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(workout.formattedDuration)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                    
                    if workout.isActive {
                        Text("Active")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(.green.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    } else {
                        Text("Completed")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Exercise summary
            if !workout.exercises.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(workout.exerciseSummary)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    // Show first few exercises
                    let displayExercises = Array(workout.exercises.prefix(3))
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: min(displayExercises.count, 3)), spacing: 8) {
                        ForEach(displayExercises, id: \.id) { exercise in
                            HStack {
                                Text(exercise.exerciseName)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Text("\(exercise.sets.count)")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.blue)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                    
                    if workout.exercises.count > 3 {
                        Text("+ \(workout.exercises.count - 3) more exercises")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
            } else {
                Text("No exercises recorded")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}

#Preview {
    let sampleWorkout = Workout(
        id: UUID(),
        userId: UUID(),
        category: "Push Day",
        startedAt: Calendar.current.date(byAdding: .hour, value: -1, to: Date()) ?? Date(),
        endedAt: Date()
    )
    
    return WorkoutHistoryCardView(workout: sampleWorkout)
        .padding()
} 