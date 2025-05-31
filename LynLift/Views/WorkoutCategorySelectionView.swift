import SwiftUI

struct WorkoutCategorySelectionView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Choose Workout Type")
                    .font(.system(size: 24, weight: .bold))
                    .padding(.top, 10)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    ForEach(simplifiedWorkoutCategories, id: \.self) { category in
                        CategoryCard(
                            category: category,
                            isSelected: viewModel.selectedCategory == category
                        ) {
                            if category == .custom {
                                viewModel.showCustomWorkoutNaming = true
                            } else {
                                viewModel.selectedCategory = category
                                Task {
                                    await viewModel.startWorkout(category: category)
                                    dismiss()
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .presentationDetents([.height(500)])
        .sheet(isPresented: $viewModel.showCustomWorkoutNaming) {
            CustomWorkoutNamingSheet(viewModel: viewModel, onDismiss: {
                dismiss()
            })
        }
    }
    
    private var simplifiedWorkoutCategories: [WorkoutCategory] {
        [.push, .pull, .legs, .shoulders, .custom]
    }
}

struct CategoryCard: View {
    let category: WorkoutCategory
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Image(systemName: category.icon)
                    .font(.system(size: 30))
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(category.rawValue)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
            }
            .frame(height: 100)
            .frame(maxWidth: .infinity)
            .background(isSelected ? .blue : Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CustomWorkoutNamingSheet: View {
    @ObservedObject var viewModel: WorkoutViewModel
    let onDismiss: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var customWorkoutName = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Custom Workout Name")
                        .font(.system(size: 16, weight: .semibold))
                    
                    TextField("Enter workout name", text: $customWorkoutName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.words)
                }
                .padding(.horizontal)
                .padding(.top)
                
                Button(action: {
                    viewModel.selectedCategory = .custom
                    viewModel.customWorkoutName = customWorkoutName.trimmingCharacters(in: .whitespacesAndNewlines)
                    Task {
                        await viewModel.startCustomWorkout(name: customWorkoutName.trimmingCharacters(in: .whitespacesAndNewlines))
                        dismiss()
                        onDismiss()
                    }
                }) {
                    Text("Start Workout")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(!customWorkoutName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .blue : .gray)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(customWorkoutName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Custom Workout")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .presentationDetents([.height(300)])
    }
}

#Preview {
    WorkoutCategorySelectionView(viewModel: WorkoutViewModel())
} 