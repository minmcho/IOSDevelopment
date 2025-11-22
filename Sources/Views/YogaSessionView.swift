import SwiftUI

struct YogaSessionView: View {
    @ObservedObject var viewModel: YogaViewModel
    @StateObject private var wsService = WebSocketService()
    @Environment(\.dismiss) var dismiss

    @State private var showingCamera = false
    @State private var showingPoseGuidance = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress Bar
                progressBar

                ScrollView {
                    VStack(spacing: 24) {
                        // Session Info
                        sessionInfoCard

                        // Current Pose
                        if let pose = viewModel.currentPose {
                            currentPoseCard(pose)
                        }

                        // Pose Instructions
                        if let pose = viewModel.currentPose {
                            poseInstructionsCard(pose)
                        }

                        // Controls
                        sessionControls
                    }
                    .padding()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack {
                    Text("Yoga Session")
                        .font(.headline)
                    if let plan = viewModel.currentPlan {
                        Text(plan.sessionId)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingCamera = true }) {
                    Image(systemName: "camera.fill")
                }
            }
        }
        .onAppear {
            if viewModel.sessionState == .notStarted {
                viewModel.startSession()
            }
            connectWebSocket()
        }
        .onDisappear {
            viewModel.pauseSession()
            wsService.disconnect()
        }
        .sheet(isPresented: $showingCamera) {
            PoseGuidanceView(
                viewModel: viewModel,
                wsService: wsService,
                currentPose: viewModel.currentPose
            )
        }
        .alert("Session Complete!", isPresented: .constant(viewModel.sessionState == .completed)) {
            Button("Done") {
                dismiss()
            }
        } message: {
            if let plan = viewModel.currentPlan {
                Text("Great job! You completed \(plan.poses.count) poses in \(plan.durationMinutes) minutes.")
            }
        }
    }

    // MARK: - Progress Bar
    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))

                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * viewModel.progress)
            }
        }
        .frame(height: 4)
    }

    // MARK: - Session Info Card
    private var sessionInfoCard: some View {
        HStack(spacing: 20) {
            VStack(spacing: 4) {
                Text("\(viewModel.currentPoseIndex + 1)")
                    .font(.title)
                    .bold()
                Text("of \(viewModel.currentPlan?.poses.count ?? 0)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            VStack(spacing: 4) {
                Text(formatTime(viewModel.remainingTime))
                    .font(.title)
                    .bold()
                    .monospacedDigit()
                Text("remaining")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            VStack(spacing: 4) {
                Image(systemName: stateIcon)
                    .font(.title2)
                    .foregroundColor(stateColor)
                Text(stateText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }

    // MARK: - Current Pose Card
    private func currentPoseCard(_ pose: YogaPose) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(pose.name)
                .font(.title2)
                .bold()

            Text(pose.category.capitalized)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(categoryColor(pose.category))
                .foregroundColor(.white)
                .cornerRadius(8)

            Divider()

            // Benefits
            VStack(alignment: .leading, spacing: 8) {
                Label("Benefits", systemImage: "heart.fill")
                    .font(.subheadline)
                    .foregroundColor(.red)

                ForEach(pose.benefits, id: \.self) { benefit in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text(benefit)
                            .font(.subheadline)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }

    // MARK: - Pose Instructions Card
    private func poseInstructionsCard(_ pose: YogaPose) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("How to Perform", systemImage: "list.bullet")
                .font(.headline)

            Text(pose.instructions)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Label("Key Points", systemImage: "star.fill")
                    .font(.subheadline)
                    .foregroundColor(.orange)

                ForEach(pose.keyPoints, id: \.self) { point in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "star")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text(point)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }

    // MARK: - Session Controls
    private var sessionControls: some View {
        VStack(spacing: 16) {
            // Play/Pause and Navigation
            HStack(spacing: 20) {
                Button(action: { viewModel.previousPose() }) {
                    Image(systemName: "backward.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.blue.opacity(viewModel.currentPoseIndex > 0 ? 1 : 0.3))
                        .clipShape(Circle())
                }
                .disabled(viewModel.currentPoseIndex == 0)

                Button(action: {
                    if viewModel.sessionState == .inProgress {
                        viewModel.pauseSession()
                    } else {
                        viewModel.resumeSession()
                    }
                }) {
                    Image(systemName: viewModel.sessionState == .inProgress ? "pause.fill" : "play.fill")
                        .font(.title)
                        .foregroundColor(.white)
                        .frame(width: 80, height: 80)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                }

                Button(action: { viewModel.nextPose() }) {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
            }

            // AI Pose Guidance
            Button(action: { showingCamera = true }) {
                HStack {
                    Image(systemName: "camera.viewfinder")
                    Text("AI Pose Guidance")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .cornerRadius(12)
            }

            // End Session
            Button(action: {
                viewModel.endSession()
            }) {
                Text("End Session")
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
            }
        }
    }

    // MARK: - Helper Properties
    private var stateIcon: String {
        switch viewModel.sessionState {
        case .notStarted: return "circle"
        case .inProgress: return "play.circle.fill"
        case .paused: return "pause.circle.fill"
        case .completed: return "checkmark.circle.fill"
        }
    }

    private var stateColor: Color {
        switch viewModel.sessionState {
        case .notStarted: return .gray
        case .inProgress: return .green
        case .paused: return .orange
        case .completed: return .blue
        }
    }

    private var stateText: String {
        switch viewModel.sessionState {
        case .notStarted: return "Ready"
        case .inProgress: return "Active"
        case .paused: return "Paused"
        case .completed: return "Done"
        }
    }

    private func categoryColor(_ category: String) -> Color {
        switch category.lowercased() {
        case "strength": return .red
        case "flexibility": return .blue
        case "balance": return .purple
        case "relaxation": return .green
        default: return .gray
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }

    private func connectWebSocket() {
        guard let plan = viewModel.currentPlan,
              let profile = viewModel.userProfile else { return }

        wsService.connect(sessionId: plan.sessionId, userId: profile.id)
    }
}
