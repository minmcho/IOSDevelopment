import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthenticationViewModel()

    var body: some View {
        Group {
            if authViewModel.isAuthenticated, let user = authViewModel.user {
                HomeView(user: user, authViewModel: authViewModel)
            } else {
                LoginView()
                    .environmentObject(authViewModel)
            }
        }
    }
}

struct HomeView: View {
    let user: User
    @ObservedObject var authViewModel: AuthenticationViewModel

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()

                // Profile Section
                VStack(spacing: 15) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 120, height: 120)
                        .foregroundColor(.blue)

                    Text("Welcome!")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text(user.name)
                        .font(.title2)
                        .foregroundColor(.gray)

                    Text(user.email)
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    Text("Signed in with \(user.provider.displayName)")
                        .font(.footnote)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.1))
                        )
                }
                .padding()

                Spacer()

                // Sign Out Button
                Button(action: {
                    authViewModel.signOut()
                }) {
                    Text("Sign Out")
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.red, lineWidth: 2)
                        )
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
            }
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    ContentView()
}
