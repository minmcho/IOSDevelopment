import Foundation
import SwiftUI

@MainActor
class YogaViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentSession: YogaPlanResponse?
    @Published var sessions: [YogaSession] = []
    @Published var progress: [YogaProgress] = []
    @Published var selectedLevel: YogaLevel = .beginner
    @Published var selectedStyle: YogaStyle = .hatha
    @Published var sessionDuration: Int = 30
    @Published var focusAreas: [String] = []
    @Published var selectedGoals: [GoalType] = []

    private let apiClient = APIClient.shared

    // MARK: - Generate Yoga Plan

    func generateYogaPlan(userId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let request = YogaPlanRequest(
                userId: userId,
                level: selectedLevel,
                style: selectedStyle,
                durationMinutes: sessionDuration,
                focusAreas: focusAreas,
                goals: selectedGoals,
                avoidPoses: []
            )

            currentSession = try await apiClient.createYogaPlan(request: request)
            isLoading = false
        } catch {
            errorMessage = "Failed to generate yoga plan: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - Load Sessions

    func loadSessions(userId: String) async {
        isLoading = true
        errorMessage = nil

        do {
            sessions = try await apiClient.getUserYogaSessions(userId: userId)
            isLoading = false
        } catch {
            errorMessage = "Failed to load sessions: \(error.localizedDescription)"
            isLoading = false
        }
    }

    // MARK: - Complete Session

    func completeSession(_ session: YogaSession, userId: String, notes: String? = nil) async {
        isLoading = true
        errorMessage = nil

        do {
            try await apiClient.completeYogaSession(
                sessionId: session.id,
                userId: userId,
                notes: notes
            )

            // Reload sessions
            await loadSessions(userId: userId)
            isLoading = false
        } catch {
            errorMessage = "Failed to complete session: \(error.localizedDescription)"
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
            progress = try await apiClient.getYogaProgress(
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

    // MARK: - Computed Properties

    var totalSessionsCompleted: Int {
        progress.reduce(0) { $0 + $1.sessionsCompleted }
    }

    var totalMinutesPracticed: Int {
        progress.reduce(0) { $0 + $1.totalMinutes }
    }

    var totalCaloriesBurned: Double {
        progress.reduce(0.0) { $0 + $1.caloriesBurned }
    }

    var uniquePosesMastered: Int {
        let allPoses = progress.flatMap { $0.posesMastered }
        return Set(allPoses).count
    }

    var currentStreak: Int {
        guard !progress.isEmpty else { return 0 }

        let sortedProgress = progress.sorted { $0.date > $1.date }
        var streak = 0

        for (index, dayProgress) in sortedProgress.enumerated() {
            if dayProgress.sessionsCompleted > 0 {
                streak += 1
            } else if index > 0 {
                break
            }
        }

        return streak
    }

    // MARK: - Helper Methods

    func resetPlanSettings() {
        selectedLevel = .beginner
        selectedStyle = .hatha
        sessionDuration = 30
        focusAreas = []
        selectedGoals = []
    }

    func clearError() {
        errorMessage = nil
    }
}
