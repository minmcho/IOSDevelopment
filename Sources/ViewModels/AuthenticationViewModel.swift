import SwiftUI
import AuthenticationServices

@MainActor
class AuthenticationViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    @Published var user: User?

    // MARK: - Traditional Email/Password Login
    func login(email: String, password: String) async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both email and password"
            return
        }

        guard isValidEmail(email) else {
            errorMessage = "Please enter a valid email address"
            return
        }

        isLoading = true
        errorMessage = nil

        // Simulate API call
        do {
            try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds

            // TODO: Replace with actual authentication API call
            // Example:
            // let response = try await authService.login(email: email, password: password)

            // For demonstration purposes
            if email.lowercased().contains("test") && password.count >= 6 {
                user = User(
                    id: UUID().uuidString,
                    email: email,
                    name: "Test User",
                    provider: .email
                )
                isAuthenticated = true
                errorMessage = nil
            } else {
                throw AuthenticationError.invalidCredentials
            }
        } catch {
            handleError(error)
        }

        isLoading = false
    }

    // MARK: - Gmail Sign In
    func signInWithGmail() async {
        isLoading = true
        errorMessage = nil

        do {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

            // TODO: Implement Google Sign-In
            // You'll need to:
            // 1. Add GoogleSignIn-iOS package via SPM
            // 2. Configure OAuth client ID in Google Cloud Console
            // 3. Add URL schemes to Info.plist
            // 4. Use GIDSignIn to handle authentication

            // Example implementation:
            /*
            import GoogleSignIn

            guard let presentingViewController = await UIApplication.shared.windows.first?.rootViewController else {
                throw AuthenticationError.unknownError
            }

            let result = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: presentingViewController
            )

            let user = result.user
            let emailAddress = user.profile?.email ?? ""
            let fullName = user.profile?.name ?? ""
            */

            // For demonstration purposes
            user = User(
                id: UUID().uuidString,
                email: "user@gmail.com",
                name: "Gmail User",
                provider: .gmail
            )
            isAuthenticated = true
            errorMessage = nil

        } catch {
            handleError(error)
        }

        isLoading = false
    }

    // MARK: - Hotmail/Outlook Sign In
    func signInWithHotmail() async {
        isLoading = true
        errorMessage = nil

        do {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

            // TODO: Implement Microsoft Sign-In
            // You'll need to:
            // 1. Add MSAL (Microsoft Authentication Library) package
            // 2. Register app in Azure AD
            // 3. Configure redirect URI
            // 4. Use MSAL to handle authentication

            // Example implementation:
            /*
            import MSAL

            let config = MSALPublicClientApplicationConfig(clientId: "your-client-id")
            let application = try MSALPublicClientApplication(configuration: config)

            let webViewParameters = MSALWebviewParameters(authPresentationViewController: viewController)
            let interactiveParameters = MSALInteractiveTokenParameters(
                scopes: ["user.read"],
                webviewParameters: webViewParameters
            )

            let result = try await application.acquireToken(with: interactiveParameters)
            */

            // For demonstration purposes
            user = User(
                id: UUID().uuidString,
                email: "user@hotmail.com",
                name: "Hotmail User",
                provider: .hotmail
            )
            isAuthenticated = true
            errorMessage = nil

        } catch {
            handleError(error)
        }

        isLoading = false
    }

    // MARK: - Sign Out
    func signOut() {
        user = nil
        isAuthenticated = false
        errorMessage = nil
    }

    // MARK: - Helper Methods
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    private func handleError(_ error: Error) {
        if let authError = error as? AuthenticationError {
            errorMessage = authError.localizedDescription
        } else {
            errorMessage = "An unexpected error occurred. Please try again."
        }
    }
}

// MARK: - Supporting Types

enum AuthenticationError: LocalizedError {
    case invalidCredentials
    case networkError
    case unknownError

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .networkError:
            return "Network error. Please check your connection."
        case .unknownError:
            return "An unknown error occurred"
        }
    }
}
