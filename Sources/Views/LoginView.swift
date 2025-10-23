import SwiftUI

struct LoginView: View {
    @EnvironmentObject var viewModel: AuthenticationViewModel
    @State private var email = ""
    @State private var password = ""
    @FocusState private var focusedField: Field?

    enum Field {
        case email, password
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.white
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    Spacer()

                    // Logo or App Title
                    VStack(spacing: 10) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.blue)

                        Text("Welcome Back")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Sign in to continue")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.bottom, 30)

                    // Email Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)

                        TextField("Enter your email", text: $email)
                            .textFieldStyle(CustomTextFieldStyle())
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .email)
                            .submitLabel(.next)
                            .onSubmit {
                                focusedField = .password
                            }
                    }
                    .padding(.horizontal, 30)

                    // Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.gray)

                        SecureField("Enter your password", text: $password)
                            .textFieldStyle(CustomTextFieldStyle())
                            .focused($focusedField, equals: .password)
                            .submitLabel(.done)
                            .onSubmit {
                                Task {
                                    await viewModel.login(email: email, password: password)
                                }
                            }
                    }
                    .padding(.horizontal, 30)

                    // Forgot Password
                    HStack {
                        Spacer()
                        Button("Forgot Password?") {
                            // Handle forgot password
                        }
                        .font(.footnote)
                        .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, -10)

                    // Login Button
                    Button(action: {
                        Task {
                            await viewModel.login(email: email, password: password)
                        }
                    }) {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Sign In")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, 30)
                    .padding(.top, 10)
                    .disabled(viewModel.isLoading || email.isEmpty || password.isEmpty)

                    // Divider
                    HStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)

                        Text("OR")
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 10)

                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 10)

                    // Gmail Sign In Button
                    Button(action: {
                        Task {
                            await viewModel.signInWithGmail()
                        }
                    }) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.red)
                            Text("Continue with Gmail")
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SocialButtonStyle())
                    .padding(.horizontal, 30)
                    .disabled(viewModel.isLoading)

                    // Hotmail Sign In Button
                    Button(action: {
                        Task {
                            await viewModel.signInWithHotmail()
                        }
                    }) {
                        HStack {
                            Image(systemName: "envelope.badge.fill")
                                .foregroundColor(.blue)
                            Text("Continue with Hotmail")
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SocialButtonStyle())
                    .padding(.horizontal, 30)
                    .disabled(viewModel.isLoading)

                    // Error Message
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }

                    Spacer()

                    // Sign Up Link
                    HStack {
                        Text("Don't have an account?")
                            .foregroundColor(.gray)
                        Button("Sign Up") {
                            // Handle sign up
                        }
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                    }
                    .font(.footnote)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// Custom Text Field Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
    }
}

// Primary Button Style
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(configuration.isPressed ? Color.blue.opacity(0.8) : Color.blue)
            )
    }
}

// Social Button Style
struct SocialButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthenticationViewModel())
}
