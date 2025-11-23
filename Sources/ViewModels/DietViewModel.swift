import Foundation
import SwiftUI

@MainActor
class DietViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentPlan: DietPlanResponse?
    @Published var mealPlans: [MealPlan] = []
    @Published var progress: [DietProgress] = []
    @Published var selectedDietType: DietType = .balanced
    @Published var dailyCalorieTarget: Int = 2000
    @Published var numDays: Int = 7
    @Published var mealsPerDay: Int = 3
    @Published var allergies: [String] = []
    @Published var dislikedFoods: [String] = []
    @Published var selectedGoals: [GoalType] = []

    private let apiClient = APIClient.shared

    // MARK: - Generate Diet Plan

    func generateDietPlan(userId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let request = DietPlanRequest(
                userId: userId,
                dietType: selectedDietType,
                dailyCalorieTarget: dailyCalorieTarget,
                numDays: numDays,
                mealsPerDay: mealsPerDay,
                allergies: allergies,
                dislikedFoods: dislikedFoods,
                goals: selectedGoals
            )

            currentPlan = try await apiClient.createDietPlan(request: request)
            mealPlans = currentPlan?.mealPlans ?? []
            isLoading = false
        } catch {
            errorMessage = "Failed to generate diet plan: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - Load Meal Plans

    func loadMealPlans(userId: String, days: Int = 7) async {
        isLoading = true
        errorMessage = nil

        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: days, to: startDate)!

        do {
            mealPlans = try await apiClient.getMealPlans(
                userId: userId,
                startDate: startDate,
                endDate: endDate
            )
            isLoading = false
        } catch {
            errorMessage = "Failed to load meal plans: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - Load Progress

    func loadProgress(userId: String, days: Int = 30) async {
        isLoading = true
        errorMessage = nil

        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate)!

        do {
            progress = try await apiClient.getDietProgress(
                userId: userId,
                startDate: startDate,
                endDate: endDate
            )
            isLoading = false
        } catch {
            errorMessage = "Failed to load progress: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - Get Meal Plan for Date

    func getMealPlanForDate(_ date: Date) -> MealPlan? {
        let calendar = Calendar.current
        return mealPlans.first { calendar.isDate($0.date, inSameDayAs: date) }
    }

    // MARK: - Computed Properties

    var averageDailyCalories: Double {
        guard !progress.isEmpty else { return 0 }
        let total = progress.reduce(0.0) { $0 + $1.caloriesConsumed }
        return total / Double(progress.count)
    }

    var averageProtein: Double {
        guard !progress.isEmpty else { return 0 }
        let total = progress.reduce(0.0) { $0 + $1.proteinG }
        return total / Double(progress.count)
    }

    var averageCarbs: Double {
        guard !progress.isEmpty else { return 0 }
        let total = progress.reduce(0.0) { $0 + $1.carbsG }
        return total / Double(progress.count)
    }

    var averageFat: Double {
        guard !progress.isEmpty else { return 0 }
        let total = progress.reduce(0.0) { $0 + $1.fatG }
        return total / Double(progress.count)
    }

    var totalMealsLogged: Int {
        progress.reduce(0) { $0 + $1.mealsLogged }
    }

    var trackingStreak: Int {
        guard !progress.isEmpty else { return 0 }

        let sortedProgress = progress.sorted { $0.date > $1.date }
        var streak = 0

        for (index, dayProgress) in sortedProgress.enumerated() {
            if dayProgress.mealsLogged > 0 {
                streak += 1
            } else if index > 0 {
                break
            }
        }

        return streak
    }

    var shoppingListItems: [ShoppingListItem] {
        guard let plan = currentPlan else { return [] }

        return plan.shoppingList.map { item in
            ShoppingListItem(
                item: item["item"] ?? "",
                amount: item["total_amount"] ?? "",
                unit: item["unit"] ?? "",
                category: item["category"] ?? "other"
            )
        }
    }

    // MARK: - Helper Methods

    func resetPlanSettings() {
        selectedDietType = .balanced
        dailyCalorieTarget = 2000
        numDays = 7
        mealsPerDay = 3
        allergies = []
        dislikedFoods = []
        selectedGoals = []
    }

    func addAllergy(_ allergy: String) {
        if !allergies.contains(allergy) {
            allergies.append(allergy)
        }
    }

    func removeAllergy(_ allergy: String) {
        allergies.removeAll { $0 == allergy }
    }

    func addDislikedFood(_ food: String) {
        if !dislikedFoods.contains(food) {
            dislikedFoods.append(food)
        }
    }

    func removeDislikedFood(_ food: String) {
        dislikedFoods.removeAll { $0 == food }
    }

    func clearError() {
        errorMessage = nil
    }
}
