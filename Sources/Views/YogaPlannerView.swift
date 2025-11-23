import SwiftUI

struct YogaPlannerView: View {
    @StateObject private var viewModel = YogaViewModel()
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var showingSessionDetail = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Title
                Text("Yoga Planner")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Plan Settings
                planSettingsSection

                // Generate Button
                generateButton

                // Current Session
                if let session = viewModel.currentSession {
                    currentSessionSection(session)
                }

                // Recent Sessions
                recentSessionsSection

                // Error Message
                if let error = viewModel.errorMessage {
                    ErrorView(message: error) {
                        viewModel.clearError()
                    }
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadSessions()
        }
    }

    // MARK: - Plan Settings Section

    private var planSettingsSection: some View {
        VStack(spacing: 16) {
            Text("Customize Your Session")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Level Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Level")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Picker("Level", selection: $viewModel.selectedLevel) {
                    ForEach(YogaLevel.allCases, id: \.self) { level in
                        Text(level.displayName).tag(level)
                    }
                }
                .pickerStyle(.segmented)
            }

            // Style Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Style")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Picker("Style", selection: $viewModel.selectedStyle) {
                    ForEach(YogaStyle.allCases, id: \.self) { style in
                        Text(style.displayName).tag(style)
                    }
                }
                .pickerStyle(.menu)
            }

            // Duration
            VStack(alignment: .leading, spacing: 8) {
                Text("Duration: \(viewModel.sessionDuration) minutes")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Slider(value: Binding(
                    get: { Double(viewModel.sessionDuration) },
                    set: { viewModel.sessionDuration = Int($0) }
                ), in: 10...120, step: 5)
            }

            // Goals
            VStack(alignment: .leading, spacing: 8) {
                Text("Goals")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                FlowLayout(spacing: 8) {
                    ForEach(GoalType.allCases, id: \.self) { goal in
                        GoalChip(
                            goal: goal,
                            isSelected: viewModel.selectedGoals.contains(goal)
                        ) {
                            toggleGoal(goal)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5)
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        Button(action: {
            Task {
                await generatePlan()
            }
        }) {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "sparkles")
                    Text("Generate AI Yoga Plan")
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.purple)
            .foregroundColor(.white)
            .cornerRadius(12)
            .fontWeight(.semibold)
        }
        .disabled(viewModel.isLoading)
    }

    // MARK: - Current Session Section

    private func currentSessionSection(_ response: YogaPlanResponse) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Personalized Session")
                .font(.headline)

            // Session Card
            SessionCard(session: response.session) {
                showingSessionDetail = true
            }

            // AI Recommendations
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.purple)
                    Text("AI Recommendations")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Text(response.aiRecommendations)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.purple.opacity(0.1))
            .cornerRadius(8)

            // Benefits & Calories
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Estimated Calories")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(response.estimatedCaloriesBurned)) kcal")
                        .font(.headline)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Benefits")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(response.benefits.count) key benefits")
                        .font(.headline)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5)
        .sheet(isPresented: $showingSessionDetail) {
            SessionDetailView(response: response, viewModel: viewModel)
        }
    }

    // MARK: - Recent Sessions Section

    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Sessions")
                .font(.headline)

            if viewModel.sessions.isEmpty {
                Text("No sessions yet. Generate your first yoga plan!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(viewModel.sessions.prefix(5)) { session in
                    SessionRow(session: session)
                }
            }
        }
    }

    // MARK: - Methods

    private func loadSessions() async {
        guard let userId = authViewModel.user?.id else { return }
        await viewModel.loadSessions(userId: userId)
    }

    private func generatePlan() async {
        guard let userId = authViewModel.user?.id else { return }
        await viewModel.generateYogaPlan(userId: userId)
    }

    private func toggleGoal(_ goal: GoalType) {
        if let index = viewModel.selectedGoals.firstIndex(of: goal) {
            viewModel.selectedGoals.remove(at: index)
        } else {
            viewModel.selectedGoals.append(goal)
        }
    }
}

// MARK: - Supporting Views

struct SessionCard: View {
    let session: YogaSession
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("\(session.style.displayName) • \(session.level.displayName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Label("\(session.durationMinutes) min", systemImage: "clock")
                    Spacer()
                    Label("\(session.poses.count) poses", systemImage: "figure.yoga")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }
}

struct SessionRow: View {
    let session: YogaSession

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(session.style.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if session.completed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Image(systemName: "circle")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct GoalChip: View {
    let goal: GoalType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(goal.displayName)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.purple : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrangeSubviews(proposal: proposal, subviews: subviews)
        let height = rows.reduce(0) { $0 + $1.height + spacing }
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrangeSubviews(proposal: proposal, subviews: subviews)
        var y = bounds.minY

        for row in rows {
            var x = bounds.minX
            for subview in row.subviews {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> [(subviews: [LayoutSubviews.Element], height: CGFloat)] {
        var rows: [(subviews: [LayoutSubviews.Element], height: CGFloat)] = []
        var currentRow: [LayoutSubviews.Element] = []
        var currentRowWidth: CGFloat = 0
        var currentRowHeight: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentRowWidth + size.width > maxWidth && !currentRow.isEmpty {
                rows.append((currentRow, currentRowHeight))
                currentRow = []
                currentRowWidth = 0
                currentRowHeight = 0
            }

            currentRow.append(subview)
            currentRowWidth += size.width + spacing
            currentRowHeight = max(currentRowHeight, size.height)
        }

        if !currentRow.isEmpty {
            rows.append((currentRow, currentRowHeight))
        }

        return rows
    }
}

struct SessionDetailView: View {
    let response: YogaPlanResponse
    @ObservedObject var viewModel: YogaViewModel
    @Environment(\.dismiss) var dismiss
    @State private var sessionNotes = ""
    @EnvironmentObject var authViewModel: AuthenticationViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Warm Up
                    if !response.session.warmUp.isEmpty {
                        poseSection(title: "Warm Up", poses: response.session.warmUp)
                    }

                    // Main Poses
                    poseSection(title: "Main Sequence", poses: response.session.poses)

                    // Cool Down
                    if !response.session.coolDown.isEmpty {
                        poseSection(title: "Cool Down", poses: response.session.coolDown)
                    }

                    // Complete Session Button
                    if !response.session.completed {
                        Button(action: {
                            Task {
                                await completeSession()
                            }
                        }) {
                            Text("Complete Session")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .fontWeight(.semibold)
                        }
                        .padding()
                    }
                }
                .padding()
            }
            .navigationTitle(response.session.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func poseSection(title: String, poses: [YogaPose]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            ForEach(poses) { pose in
                PoseCard(pose: pose)
            }
        }
    }

    private func completeSession() async {
        guard let userId = authViewModel.user?.id else { return }
        await viewModel.completeSession(response.session, userId: userId, notes: sessionNotes.isEmpty ? nil : sessionNotes)
        dismiss()
    }
}

struct PoseCard: View {
    let pose: YogaPose

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(pose.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                if let sanskrit = pose.sanskritName {
                    Text("(\(sanskrit))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text(pose.description)
                .font(.caption)
                .foregroundColor(.secondary)

            if !pose.instructions.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(pose.instructions.enumerated()), id: \.offset) { index, instruction in
                        Text("\(index + 1). \(instruction)")
                            .font(.caption2)
                    }
                }
            }

            HStack {
                Label("\(pose.durationSeconds)s", systemImage: "timer")
                Spacer()
                Text(pose.difficulty.displayName)
            }
            .font(.caption2)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}
