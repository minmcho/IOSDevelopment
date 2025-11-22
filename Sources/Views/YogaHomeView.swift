import SwiftUI

struct YogaHomeView: View {
    @StateObject private var yogaViewModel = YogaViewModel()
    @State private var selectedDuration = 30
    @State private var selectedDifficulty = "beginner"
    @State private var selectedFocusAreas: Set<FocusArea> = []
    @State private var selectedSessionType: SessionType = .morning
    @State private var showingPlanSheet = false
    @State private var showingProfileSheet = false

    let durations = [15, 30, 45, 60]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerView

                    if yogaViewModel.userProfile == nil {
                        setupProfileView
                    } else {
                        // Session Planning
                        sessionPlanningView

                        // Current Plan
                        if let plan = yogaViewModel.currentPlan {
                            currentPlanView(plan: plan)
                        }

                        // Session History
                        if !yogaViewModel.sessionHistory.isEmpty {
                            sessionHistoryView
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("AI Yoga Planner")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: ChatView(userId: yogaViewModel.userProfile?.id ?? "default")) {
                        Image(systemName: "message.fill")
                    }
                }
            }
            .sheet(isPresented: $showingProfileSheet) {
                ProfileSetupView(viewModel: yogaViewModel)
            }
            .alert("Error", isPresented: .constant(yogaViewModel.errorMessage != nil)) {
                Button("OK") {
                    yogaViewModel.errorMessage = nil
                }
            } message: {
                Text(yogaViewModel.errorMessage ?? "")
            }
        }
    }

    // MARK: - Header View
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome to AI Yoga Planner")
                .font(.title2)
                .bold()

            if let profile = yogaViewModel.userProfile {
                Text("Hello, \(profile.name)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Setup Profile View
    private var setupProfileView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("Create Your Profile")
                .font(.title3)
                .bold()

            Text("Get personalized yoga sessions tailored to your needs")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: { showingProfileSheet = true }) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    // MARK: - Session Planning View
    private var sessionPlanningView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Plan Your Session")
                .font(.headline)

            // Duration Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Duration")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Picker("Duration", selection: $selectedDuration) {
                    ForEach(durations, id: \.self) { duration in
                        Text("\(duration) min").tag(duration)
                    }
                }
                .pickerStyle(.segmented)
            }

            // Difficulty
            VStack(alignment: .leading, spacing: 8) {
                Text("Difficulty")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Picker("Difficulty", selection: $selectedDifficulty) {
                    Text("Beginner").tag("beginner")
                    Text("Intermediate").tag("intermediate")
                    Text("Advanced").tag("advanced")
                }
                .pickerStyle(.segmented)
            }

            // Session Type
            VStack(alignment: .leading, spacing: 8) {
                Text("Session Type")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(SessionType.allCases, id: \.self) { type in
                            sessionTypeButton(type)
                        }
                    }
                }
            }

            // Focus Areas
            VStack(alignment: .leading, spacing: 8) {
                Text("Focus Areas")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(FocusArea.allCases, id: \.self) { area in
                        focusAreaButton(area)
                    }
                }
            }

            // Generate Plan Button
            Button(action: generatePlan) {
                if yogaViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else {
                    Text("Generate AI Plan")
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(selectedFocusAreas.isEmpty ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .disabled(selectedFocusAreas.isEmpty || yogaViewModel.isLoading)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    private func sessionTypeButton(_ type: SessionType) -> some View {
        Button(action: { selectedSessionType = type }) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.title2)
                Text(type.displayName)
                    .font(.caption)
            }
            .frame(width: 80, height: 80)
            .background(selectedSessionType == type ? Color.blue.opacity(0.2) : Color(.systemGray5))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selectedSessionType == type ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .foregroundColor(.primary)
    }

    private func focusAreaButton(_ area: FocusArea) -> some View {
        Button(action: {
            if selectedFocusAreas.contains(area) {
                selectedFocusAreas.remove(area)
            } else {
                selectedFocusAreas.insert(area)
            }
        }) {
            HStack {
                Image(systemName: area.icon)
                Text(area.displayName)
                    .font(.subheadline)
                Spacer()
                if selectedFocusAreas.contains(area) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(selectedFocusAreas.contains(area) ? Color.blue.opacity(0.1) : Color(.systemGray5))
            .cornerRadius(10)
        }
        .foregroundColor(.primary)
    }

    // MARK: - Current Plan View
    private func currentPlanView(plan: YogaPlanResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Your AI-Generated Plan")
                    .font(.headline)
                Spacer()
                Text("\(plan.poses.count) poses")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(plan.instructions)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)

            HStack {
                Label("\(plan.durationMinutes) min", systemImage: "clock")
                Spacer()
                Label("\(plan.estimatedCalories) cal", systemImage: "flame")
            }
            .font(.caption)
            .foregroundColor(.secondary)

            NavigationLink(destination: YogaSessionView(viewModel: yogaViewModel)) {
                Text("Start Session")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(16)
    }

    // MARK: - Session History
    private var sessionHistoryView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Sessions")
                .font(.headline)

            ForEach(yogaViewModel.sessionHistory.prefix(3), id: \.sessionId) { session in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(session.poses.count) poses")
                            .font(.subheadline)
                            .bold()
                        Text("\(session.durationMinutes) min · \(session.estimatedCalories) cal")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
            }
        }
    }

    // MARK: - Actions
    private func generatePlan() {
        Task {
            await yogaViewModel.generateYogaPlan(
                duration: selectedDuration,
                difficulty: selectedDifficulty,
                focusAreas: selectedFocusAreas.map { $0.rawValue },
                sessionType: selectedSessionType.rawValue
            )
        }
    }
}

// MARK: - Profile Setup View
struct ProfileSetupView: View {
    @ObservedObject var viewModel: YogaViewModel
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var experienceLevel: YogaUserProfile.ExperienceLevel = .beginner
    @State private var selectedGoals: Set<String> = []

    let availableGoals = ["Flexibility", "Strength", "Balance", "Stress Relief", "Weight Loss", "Mindfulness"]

    var body: some View {
        NavigationView {
            Form {
                Section("Personal Information") {
                    TextField("Name", text: $name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }

                Section("Experience Level") {
                    Picker("Level", selection: $experienceLevel) {
                        ForEach(YogaUserProfile.ExperienceLevel.allCases, id: \.self) { level in
                            Text(level.displayName).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Your Goals") {
                    ForEach(availableGoals, id: \.self) { goal in
                        Button(action: {
                            if selectedGoals.contains(goal) {
                                selectedGoals.remove(goal)
                            } else {
                                selectedGoals.insert(goal)
                            }
                        }) {
                            HStack {
                                Text(goal)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedGoals.contains(goal) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Setup Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProfile()
                    }
                    .disabled(name.isEmpty || email.isEmpty || selectedGoals.isEmpty)
                }
            }
        }
    }

    private func saveProfile() {
        Task {
            await viewModel.createUserProfile(
                userId: UUID().uuidString,
                name: name,
                email: email,
                experienceLevel: experienceLevel,
                goals: Array(selectedGoals)
            )
            dismiss()
        }
    }
}
