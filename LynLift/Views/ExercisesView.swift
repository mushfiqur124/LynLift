import SwiftUI

struct ExercisesView: View {
    @StateObject private var viewModel = ExercisesViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                searchSection
                
                // Content
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.filteredExercises.isEmpty && viewModel.searchText.isEmpty {
                    emptyStateView
                } else if viewModel.filteredExercises.isEmpty {
                    noResultsView
                } else {
                    exercisesList
                }
            }
            .navigationTitle("Exercises")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.showAddExercise = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }
            .refreshable {
                viewModel.loadExercises()
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .sheet(isPresented: $viewModel.showAddExercise) {
            addExerciseSheet
        }
    }
    
    private var searchSection: some View {
        VStack(spacing: 0) {
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
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            // Exercise count
            HStack {
                Text("\(viewModel.exerciseCount) exercises")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }
    
    private var exercisesList: some View {
        List {
            ForEach(viewModel.filteredExercises) { exercise in
                ExerciseRowView(exercise: exercise) {
                    // TODO: Navigate to exercise detail/history
                }
            }
            .onDelete(perform: deleteExercises)
        }
        .listStyle(PlainListStyle())
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading exercises...")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("No Exercises Yet")
                .font(.system(size: 24, weight: .bold))
            
            Text("Start building your exercise library by adding your first exercise")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: {
                viewModel.showAddExercise = true
            }) {
                Label("Add Exercise", systemImage: "plus.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 200, height: 50)
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No Results")
                .font(.system(size: 20, weight: .semibold))
            
            Text("No exercises found for '\(viewModel.searchText)'")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var addExerciseSheet: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Exercise Name")
                        .font(.system(size: 16, weight: .semibold))
                    
                    TextField("Enter exercise name", text: $viewModel.newExerciseName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.words)
                }
                .padding(.horizontal)
                .padding(.top)
                
                Button(action: {
                    Task {
                        await viewModel.createExercise()
                    }
                }) {
                    Text("Add Exercise")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(viewModel.canCreateExercise ? .blue : .gray)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!viewModel.canCreateExercise)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.newExerciseName = ""
                        viewModel.showAddExercise = false
                    }
                }
            }
        }
        .presentationDetents([.height(300)])
    }
    
    private func deleteExercises(at offsets: IndexSet) {
        for index in offsets {
            let exercise = viewModel.filteredExercises[index]
            viewModel.deleteExercise(exercise)
        }
    }
}

// MARK: - Supporting Views

struct ExerciseRowView: View {
    let exercise: Exercise
    let onTap: () -> Void
    @StateObject private var viewModel = ExercisesViewModel()
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text("Added \(exercise.createdAt, style: .date)")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        // Show last workout data if available
                        if let lastWorkout = viewModel.getLastWorkoutForExercise(exercise.id) {
                            Text("•")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                            
                            Text("Last: \(lastWorkout)")
                                .font(.system(size: 14))
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            viewModel.loadExerciseHistory(for: exercise.id)
        }
    }
}

#Preview {
    ExercisesView()
} 