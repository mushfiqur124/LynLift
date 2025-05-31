import SwiftUI

struct ProfileView: View {
    @ObservedObject private var supabaseService = SupabaseService.shared
    @State private var showLogoutAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // User section
                Section {
                    HStack {
                        Circle()
                            .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(supabaseService.currentUser?.displayName ?? "User")
                                .font(.system(size: 18, weight: .semibold))
                            
                            Text(supabaseService.currentUser?.email ?? "")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                // Settings section
                Section("Settings") {
                    Label("Weight Unit", systemImage: "scalemass.fill")
                    Label("Theme", systemImage: "paintbrush.fill")
                    Label("Notifications", systemImage: "bell.fill")
                }
                
                // Data section
                Section("Data") {
                    Label("Export Data", systemImage: "square.and.arrow.up.fill")
                    Label("Import Data", systemImage: "square.and.arrow.down.fill")
                }
                
                // About section
                Section("About") {
                    Label("Privacy Policy", systemImage: "hand.raised.fill")
                    Label("Terms of Service", systemImage: "doc.text.fill")
                    Label("App Version", systemImage: "info.circle.fill")
                }
                
                // Logout section
                Section {
                    Button(action: {
                        showLogoutAlert = true
                    }) {
                        Label("Sign Out", systemImage: "arrow.right.square.fill")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
        .alert("Sign Out", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                Task {
                    try? await supabaseService.signOut()
                }
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
}

#Preview {
    ProfileView()
} 