import Foundation
import SwiftUI
import Combine

@MainActor
class YogaViewModel: ObservableObject {
    @Published var userProfile: YogaUserProfile?
    @Published var currentPlan: YogaPlanResponse?
    @Published var currentPoseIndex = 0
    @Published var sessionState: SessionState = .notStarted
    @Published var remainingTime: Int = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var poseCorrections: [PoseCorrection] = []
    @Published var sessionHistory: [YogaPlanResponse] = []

    private let apiService = YogaAPIService.shared
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - User Profile Management
    func createUserProfile(
        userId: String,
        name: String,
        email: String,
        experienceLevel: YogaUserProfile.ExperienceLevel,
        goals: [String],
        healthConditions: [String] = []
    ) async {
        isLoading = true
        errorMessage = nil

        let profile = YogaUserProfile(
            id: userId,
            name: name,
            email: email,
            experienceLevel: experienceLevel,
            goals: goals,
            healthConditions: healthConditions,
            preferences: [:]
        )

        do {
            let success = try await apiService.createUserProfile(profile)
            if success {
                self.userProfile = profile
            }
        } catch {
            errorMessage = "Failed to create profile: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Generate Yoga Plan
    func generateYogaPlan(
        duration: Int,
        difficulty: String,
        focusAreas: [String],
        sessionType: String
    ) async {
        guard let userProfile = userProfile else {
            errorMessage = "Please create a user profile first"
            return
        }

        isLoading = true
        errorMessage = nil

        let sessionRequest = YogaSessionRequest(
            userId: userProfile.id,
            durationMinutes: duration,
            difficulty: difficulty,
            focusAreas: focusAreas,
            sessionType: sessionType
        )

        do {
            let plan = try await apiService.generateYogaPlan(
                session: sessionRequest,
                userProfile: userProfile
            )
            self.currentPlan = plan
            self.currentPoseIndex = 0
            self.sessionState = .notStarted

            // Add to history
            sessionHistory.insert(plan, at: 0)
        } catch {
            errorMessage = "Failed to generate plan: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Session Control
    func startSession() {
        guard let plan = currentPlan, !plan.poses.isEmpty else { return }

        sessionState = .inProgress
        currentPoseIndex = 0
        startPoseTimer()
    }

    func pauseSession() {
        sessionState = .paused
        timer?.invalidate()
    }

    func resumeSession() {
        sessionState = .inProgress
        startPoseTimer()
    }

    func endSession() {
        sessionState = .completed
        timer?.invalidate()
        remainingTime = 0
    }

    func nextPose() {
        guard let plan = currentPlan else { return }

        if currentPoseIndex < plan.poses.count - 1 {
            currentPoseIndex += 1
            startPoseTimer()
        } else {
            endSession()
        }
    }

    func previousPose() {
        if currentPoseIndex > 0 {
            currentPoseIndex -= 1
            startPoseTimer()
        }
    }

    private func startPoseTimer() {
        timer?.invalidate()

        guard let plan = currentPlan,
              currentPoseIndex < plan.poses.count else { return }

        let currentPose = plan.poses[currentPoseIndex]
        remainingTime = currentPose.duration

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            Task { @MainActor in
                if self.remainingTime > 0 {
                    self.remainingTime -= 1
                } else {
                    self.nextPose()
                }
            }
        }
    }

    // MARK: - Pose Analysis
    func analyzePose(image: UIImage, poseName: String) async {
        do {
            let correction = try await apiService.analyzePose(image: image, poseName: poseName)
            poseCorrections.append(correction)
        } catch {
            errorMessage = "Failed to analyze pose: \(error.localizedDescription)"
        }
    }

    // MARK: - Current Pose
    var currentPose: YogaPose? {
        guard let plan = currentPlan,
              currentPoseIndex < plan.poses.count else { return nil }
        return plan.poses[currentPoseIndex]
    }

    var progress: Double {
        guard let plan = currentPlan, !plan.poses.isEmpty else { return 0 }
        return Double(currentPoseIndex + 1) / Double(plan.poses.count)
    }

    // MARK: - Cleanup
    func cleanup() {
        timer?.invalidate()
        timer = nil
    }
}
