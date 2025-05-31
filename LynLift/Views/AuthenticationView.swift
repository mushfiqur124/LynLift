import SwiftUI

struct AuthenticationView: View {
    @StateObject private var viewModel = AuthenticationViewModel()
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Header
                    headerSection
                        .frame(height: geometry.size.height * 0.3)
                    
                    // Form
                    formSection
                        .frame(maxHeight: .infinity)
                }
            }
            .ignoresSafeArea(.all, edges: .top)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
    
    private var headerSection: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [.blue, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 16) {
                // App icon/logo
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(.white)
                
                Text("LynLift")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Track your fitness journey")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
    
    private var formSection: some View {
        VStack(spacing: 24) {
            // Mode toggle
            Picker("Mode", selection: $viewModel.isSignUpMode) {
                Text("Sign In").tag(false)
                Text("Sign Up").tag(true)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            // Form fields
            VStack(spacing: 16) {
                if viewModel.showForgotPassword {
                    forgotPasswordForm
                } else if viewModel.isSignUpMode {
                    signUpForm
                } else {
                    signInForm
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding(.top, 32)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
        )
    }
    
    private var signInForm: some View {
        VStack(spacing: 16) {
            // Email field
            CustomTextField(
                title: "Email",
                text: $viewModel.email,
                keyboardType: .emailAddress,
                icon: "envelope.fill"
            )
            
            // Password field
            CustomSecureField(
                title: "Password",
                text: $viewModel.password,
                icon: "lock.fill"
            )
            
            // Sign in button
            Button(action: {
                Task {
                    await viewModel.signIn()
                }
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("Sign In")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(viewModel.canSignIn ? .blue : .gray)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!viewModel.canSignIn)
            
            // Forgot password button
            Button("Forgot Password?") {
                viewModel.toggleForgotPassword()
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.blue)
        }
    }
    
    private var signUpForm: some View {
        VStack(spacing: 16) {
            // First name field
            CustomTextField(
                title: "First Name",
                text: $viewModel.firstName,
                icon: "person.fill"
            )
            
            // Email field
            CustomTextField(
                title: "Email",
                text: $viewModel.email,
                keyboardType: .emailAddress,
                icon: "envelope.fill"
            )
            
            // Password field
            CustomSecureField(
                title: "Password",
                text: $viewModel.password,
                icon: "lock.fill"
            )
            
            // Confirm password field
            CustomSecureField(
                title: "Confirm Password",
                text: $viewModel.confirmPassword,
                icon: "lock.fill"
            )
            
            // Sign up button
            Button(action: {
                Task {
                    await viewModel.signUp()
                }
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("Create Account")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(viewModel.canSignUp ? .blue : .gray)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!viewModel.canSignUp)
        }
    }
    
    private var forgotPasswordForm: some View {
        VStack(spacing: 16) {
            Text("Reset Password")
                .font(.system(size: 20, weight: .semibold))
                .padding(.bottom, 8)
            
            Text("Enter your email address and we'll send you a link to reset your password.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 16)
            
            // Email field
            CustomTextField(
                title: "Email",
                text: $viewModel.email,
                keyboardType: .emailAddress,
                icon: "envelope.fill"
            )
            
            // Reset button
            Button(action: {
                Task {
                    await viewModel.resetPassword()
                }
            }) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("Send Reset Link")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(viewModel.isEmailValid ? .blue : .gray)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!viewModel.isEmailValid || viewModel.isLoading)
            
            // Back button
            Button("Back to Sign In") {
                viewModel.toggleForgotPassword()
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.blue)
        }
    }
}

// MARK: - Custom Components

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                TextField(title, text: $text)
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct CustomSecureField: View {
    let title: String
    @Binding var text: String
    let icon: String
    @State private var isSecure = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                if isSecure {
                    SecureField(title, text: $text)
                } else {
                    TextField(title, text: $text)
                }
                
                Button(action: {
                    isSecure.toggle()
                }) {
                    Image(systemName: isSecure ? "eye.slash" : "eye")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

#Preview {
    AuthenticationView()
} 