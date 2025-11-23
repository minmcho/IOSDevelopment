import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @EnvironmentObject var authViewModel: AuthenticationViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.isLoading {
                        ProgressView("Loading dashboard...")
                            .padding()
                    } else if let error = viewModel.errorMessage {
                        ErrorView(message: error) {
                            viewModel.clearError()
                        }
                    } else {
                        // Header
                        headerSection

                        // Today's Stats
                        todayStatsSection

                        // This Week
                        weekStatsSection

                        // Streaks
                        streaksSection

                        // Quick Actions
                        quickActionsSection
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await refreshDashboard()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .task {
                await loadDashboard()
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome back, \(authViewModel.user?.name ?? "User")!")
                .font(.title)
                .fontWeight(.bold)

            Text("Here's your wellness summary")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var todayStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today")
                .font(.headline)

            HStack(spacing: 16) {
                StatCard(
                    title: "Yoga",
                    value: "\(viewModel.yogaSessionsToday)",
                    subtitle: "\(viewModel.yogaMinutesToday) min",
                    icon: "figure.yoga",
                    color: .purple
                )

                StatCard(
                    title: "Meals",
                    value: "\(viewModel.mealsLoggedToday)",
                    subtitle: "\(Int(viewModel.caloriesToday)) kcal",
                    icon: "fork.knife",
                    color: .green
                )
            }
        }
    }

    private var weekStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.headline)

            VStack(spacing: 12) {
                WeekStatRow(
                    icon: "figure.yoga",
                    title: "Yoga Sessions",
                    value: "\(viewModel.weeklyYogaSessions)",
                    detail: "\(viewModel.weeklyYogaMinutes) minutes total",
                    color: .purple
                )

                WeekStatRow(
                    icon: "fork.knife",
                    title: "Meals Logged",
                    value: "\(viewModel.weeklyMeals)",
                    detail: "\(Int(viewModel.weeklyAvgCalories)) kcal avg/day",
                    color: .green
                )
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5)
        }
    }

    private var streaksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Streaks 🔥")
                .font(.headline)

            HStack(spacing: 16) {
                StreakCard(
                    title: "Yoga",
                    days: viewModel.yogaStreak,
                    color: .purple
                )

                StreakCard(
                    title: "Nutrition",
                    days: viewModel.dietStreak,
                    color: .green
                )
            }
        }
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)

            HStack(spacing: 16) {
                NavigationLink(destination: YogaPlannerView()) {
                    QuickActionCard(
                        icon: "figure.yoga",
                        title: "New Yoga Session",
                        color: .purple
                    )
                }

                NavigationLink(destination: DietPlannerView()) {
                    QuickActionCard(
                        icon: "fork.knife",
                        title: "View Meal Plan",
                        color: .green
                    )
                }
            }
        }
    }

    // MARK: - Methods

    private func loadDashboard() async {
        guard let userId = authViewModel.user?.id else { return }
        await viewModel.loadDashboard(userId: userId)
    }

    private func refreshDashboard() async {
        guard let userId = authViewModel.user?.id else { return }
        await viewModel.refresh(userId: userId)
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Text(value)
                .font(.title)
                .fontWeight(.bold)

            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5)
    }
}

struct WeekStatRow: View {
    let icon: String
    let title: String
    let value: String
    let detail: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
        }
    }
}

struct StreakCard: View {
    let title: String
    let days: Int
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 4) {
                Text("\(days)")
                    .font(.title)
                    .fontWeight(.bold)
                Text("days")
                    .font(.caption)
            }
            .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct QuickActionCard: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ErrorView: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.red)

            Text(message)
                .multilineTextAlignment(.center)

            Button("Dismiss", action: onDismiss)
                .buttonStyle(.bordered)
        }
        .padding()
    }
}
