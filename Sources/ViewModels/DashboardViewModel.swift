import Foundation
import SwiftUI

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var dashboardData: DashboardData?

    private let apiClient = APIClient.shared

    // MARK: - Load Dashboard

    func loadDashboard(userId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            dashboardData = try await apiClient.getDashboard(userId: userId)
            isLoading = false
        } catch {
            errorMessage = "Failed to load dashboard: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - Computed Properties

    var yogaSessionsToday: Int {
        dashboardData?.today.yoga.sessions ?? 0
    }

    var yogaMinutesToday: Int {
        dashboardData?.today.yoga.minutes ?? 0
    }

    var yogaCaloriesToday: Double {
        dashboardData?.today.yoga.caloriesBurned ?? 0
    }

    var mealsLoggedToday: Int {
        dashboardData?.today.diet.mealsLogged ?? 0
    }

    var caloriesToday: Double {
        dashboardData?.today.diet.calories ?? 0
    }

    var weeklyYogaSessions: Int {
        dashboardData?.thisWeek.yoga.totalSessions ?? 0
    }

    var weeklyYogaMinutes: Int {
        dashboardData?.thisWeek.yoga.totalMinutes ?? 0
    }

    var weeklyMeals: Int {
        dashboardData?.thisWeek.diet.totalMeals ?? 0
    }

    var weeklyAvgCalories: Double {
        dashboardData?.thisWeek.diet.avgCalories ?? 0
    }

    var yogaStreak: Int {
        dashboardData?.streaks.yogaStreakDays ?? 0
    }

    var dietStreak: Int {
        dashboardData?.streaks.dietStreakDays ?? 0
    }

    var totalActiveStreak: Int {
        dashboardData?.streaks.totalActiveDays ?? 0
    }

    // MARK: - Helper Methods

    func clearError() {
        errorMessage = nil
    }

    func refresh(userId: String) async {
        await loadDashboard(userId: userId)
    }
}
