import Foundation
import Combine

@MainActor
class AuthenticationViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var firstName = ""
    @Published var confirmPassword = ""
    
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showError = false
    @Published var isSignUpMode = false
    @Published var showForgotPassword = false
    
    private let supabaseService = SupabaseService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Listen to authentication state changes
        supabaseService.$isAuthenticated
            .sink { [weak self] isAuthenticated in
                if isAuthenticated {
                    self?.clearForm()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Validation
    
    var isEmailValid: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    var isPasswordValid: Bool {
        return password.count >= 6
    }
    
    var isFirstNameValid: Bool {
        return !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var passwordsMatch: Bool {
        return password == confirmPassword
    }
    
    var canSignIn: Bool {
        return isEmailValid && isPasswordValid && !isLoading
    }
    
    var canSignUp: Bool {
        return isEmailValid && isPasswordValid && isFirstNameValid && passwordsMatch && !isLoading
    }
    
    // MARK: - Actions
    
    func signIn() async {
        guard canSignIn else { return }
        
        isLoading = true
        errorMessage = ""
        showError = false
        
        do {
            try await supabaseService.signIn(email: email, password: password)
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func signUp() async {
        guard canSignUp else { return }
        
        isLoading = true
        errorMessage = ""
        showError = false
        
        do {
            try await supabaseService.signUp(
                email: email,
                password: password,
                firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func resetPassword() async {
        guard isEmailValid else {
            errorMessage = "Please enter a valid email address"
            showError = true
            return
        }
        
        isLoading = true
        errorMessage = ""
        showError = false
        
        do {
            try await supabaseService.resetPassword(email: email)
            errorMessage = "Password reset email sent!"
            showError = true
            showForgotPassword = false
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    func toggleMode() {
        isSignUpMode.toggle()
        clearForm()
    }
    
    func toggleForgotPassword() {
        showForgotPassword.toggle()
        errorMessage = ""
        showError = false
    }
    
    private func clearForm() {
        email = ""
        password = ""
        firstName = ""
        confirmPassword = ""
        errorMessage = ""
        showError = false
    }
    
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
    }
} 