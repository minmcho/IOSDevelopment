import SwiftUI

struct MicronutrientView: View {
    @StateObject private var viewModel = MicronutrientViewModel()
    @EnvironmentObject var authViewModel: AuthenticationViewModel

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    if viewModel.isLoading {
                        ProgressView("Analyzing micronutrients...")
                            .padding()
                    } else if let error = viewModel.errorMessage {
                        ErrorView(message: error) {
                            viewModel.clearError()
                        }
                    } else if let analysis = viewModel.analysis {
                        analysisContent(analysis)
                    }
                }
                .padding()
            }
            .navigationTitle("Micronutrients")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await loadAnalysis()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .task {
                await loadAnalysis()
            }
        }
    }

    // MARK: - Analysis Content

    @ViewBuilder
    private func analysisContent(_ analysis: MicronutrientAnalysis) -> some View {
        // Deficiency Alerts
        if !analysis.deficiencies.isEmpty {
            deficiencyAlertsSection(analysis.deficiencies)
        }

        // Vitamins Section
        vitaminsSection(analysis)

        // Minerals Section
        mineralsSection(analysis)

        // AI Recommendations
        if !analysis.aiRecommendations.isEmpty {
            aiRecommendationsSection(analysis)
        }

        // Adequacies
        if !analysis.adequacies.isEmpty {
            adequaciesSection(analysis.adequacies)
        }

        // Dietary Adjustments
        if !analysis.dietaryAdjustments.isEmpty {
            dietaryAdjustmentsSection(analysis.dietaryAdjustments)
        }
    }

    // MARK: - Deficiency Alerts

    private func deficiencyAlertsSection(_ deficiencies: [MicronutrientDeficiency]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Nutrient Deficiencies Detected")
                    .font(.headline)
            }

            ForEach(deficiencies) { deficiency in
                DeficiencyCard(deficiency: deficiency)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Vitamins Section

    private func vitaminsSection(_ analysis: MicronutrientAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Vitamins")
                .font(.title2)
                .fontWeight(.bold)

            ForEach(Array(analysis.vitaminCompletionPercentages.sorted(by: { $0.key < $1.key })), id: \.key) { vitamin, percentage in
                NutrientProgressBar(
                    name: vitamin,
                    percentage: percentage,
                    color: colorForPercentage(percentage)
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5)
    }

    // MARK: - Minerals Section

    private func mineralsSection(_ analysis: MicronutrientAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Minerals")
                .font(.title2)
                .fontWeight(.bold)

            ForEach(Array(analysis.mineralCompletionPercentages.sorted(by: { $0.key < $1.key })), id: \.key) { mineral, percentage in
                NutrientProgressBar(
                    name: mineral,
                    percentage: percentage,
                    color: colorForPercentage(percentage)
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5)
    }

    // MARK: - AI Recommendations

    private func aiRecommendationsSection(_ analysis: MicronutrientAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.purple)
                Text("AI Recommendations")
                    .font(.headline)
            }

            Text(analysis.aiRecommendations)
                .font(.subheadline)
                .foregroundColor(.secondary)

            if !analysis.supplementSuggestions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Supplement Suggestions:")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    ForEach(analysis.supplementSuggestions, id: \.self) { suggestion in
                        HStack(alignment: .top) {
                            Image(systemName: "pill.fill")
                                .font(.caption)
                                .foregroundColor(.purple)
                            Text(suggestion)
                                .font(.caption)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Adequacies

    private func adequaciesSection(_ adequacies: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Meeting Goals")
                    .font(.headline)
            }

            FlowLayout(spacing: 8) {
                ForEach(adequacies, id: \.self) { nutrient in
                    Text(nutrient)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(16)
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Dietary Adjustments

    private func dietaryAdjustmentsSection(_ adjustments: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dietary Adjustments")
                .font(.headline)

            ForEach(adjustments, id: \.self) { adjustment in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "leaf.fill")
                        .foregroundColor(.green)
                        .font(.caption)

                    Text(adjustment)
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5)
    }

    // MARK: - Helper Methods

    private func colorForPercentage(_ percentage: Double) -> Color {
        if percentage >= 90 {
            return .green
        } else if percentage >= 70 {
            return .yellow
        } else if percentage >= 50 {
            return .orange
        } else {
            return .red
        }
    }

    private func loadAnalysis() async {
        guard let userId = authViewModel.user?.id else { return }
        await viewModel.loadAnalysis(userId: userId)
    }
}

// MARK: - Supporting Views

struct DeficiencyCard: View {
    let deficiency: MicronutrientDeficiency

    private var severityColor: Color {
        switch deficiency.severity {
        case "high": return .red
        case "moderate": return .orange
        default: return .yellow
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(deficiency.nutrientName)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Text("\(Int(deficiency.deficitPercentage))% below RDA")
                    .font(.caption)
                    .foregroundColor(severityColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(severityColor.opacity(0.2))
                    .cornerRadius(8)
            }

            Text("Current: \(String(format: "%.1f", deficiency.currentIntake)) | Goal: \(String(format: "%.1f", deficiency.recommendedIntake))")
                .font(.caption)
                .foregroundColor(.secondary)

            if !deficiency.healthImpacts.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Health Impacts:")
                        .font(.caption2)
                        .fontWeight(.semibold)

                    ForEach(deficiency.healthImpacts, id: \.self) { impact in
                        Text("• \(impact)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            if !deficiency.foodSources.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Food Sources:")
                        .font(.caption2)
                        .fontWeight(.semibold)

                    Text(deficiency.foodSources.joined(separator: ", "))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct NutrientProgressBar: View {
    let name: String
    let percentage: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(name)
                    .font(.subheadline)

                Spacer()

                Text("\(Int(percentage))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                        .cornerRadius(4)

                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * min(percentage / 100, 1.0), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - ViewModel

@MainActor
class MicronutrientViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var analysis: MicronutrientAnalysis?

    private let apiClient = APIClient.shared

    func loadAnalysis(userId: String, days: Int = 7) async {
        isLoading = true
        errorMessage = nil

        do {
            analysis = try await apiClient.analyzeMicronutrients(userId: userId, days: days)
            isLoading = false
        } catch {
            errorMessage = "Failed to load micronutrient analysis: \(error.localizedDescription)"
            isLoading = false
        }
    }

    func clearError() {
        errorMessage = nil
    }
}
