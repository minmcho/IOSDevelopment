import SwiftUI

struct DietPlannerView: View {
    @StateObject private var viewModel = DietViewModel()
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var showingPlanCreation = false
    @State private var selectedDate = Date()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Title
                Text("Diet Planner")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Quick Actions
                quickActionsSection

                // Calendar View
                weekCalendarSection

                // Today's Meals
                if let mealPlan = viewModel.getMealPlanForDate(selectedDate) {
                    mealPlanSection(mealPlan)
                } else {
                    emptyStateView
                }

                // Shopping List
                if viewModel.currentPlan != nil {
                    shoppingListSection
                }

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
        .sheet(isPresented: $showingPlanCreation) {
            DietPlanCreationView(viewModel: viewModel)
        }
        .task {
            await loadMealPlans()
        }
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            Button(action: {
                showingPlanCreation = true
            }) {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Generate AI Plan")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
                .fontWeight(.semibold)
            }
        }
    }

    // MARK: - Week Calendar

    private var weekCalendarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Date")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<7) { offset in
                        let date = Calendar.current.date(byAdding: .day, value: offset, to: Date())!
                        DateCard(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                            hasMealPlan: viewModel.getMealPlanForDate(date) != nil
                        ) {
                            selectedDate = date
                        }
                    }
                }
            }
        }
    }

    // MARK: - Meal Plan Section

    private func mealPlanSection(_ mealPlan: MealPlan) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Nutrition Summary
            nutritionSummaryCard(mealPlan.totalNutrition)

            // Meals
            VStack(alignment: .leading, spacing: 12) {
                Text("Today's Meals")
                    .font(.headline)

                if let breakfast = mealPlan.breakfast {
                    MealCard(title: "Breakfast", recipe: breakfast, mealType: .breakfast)
                }

                if let lunch = mealPlan.lunch {
                    MealCard(title: "Lunch", recipe: lunch, mealType: .lunch)
                }

                if let dinner = mealPlan.dinner {
                    MealCard(title: "Dinner", recipe: dinner, mealType: .dinner)
                }

                if !mealPlan.snacks.isEmpty {
                    ForEach(mealPlan.snacks) { snack in
                        MealCard(title: "Snack", recipe: snack, mealType: .snack)
                    }
                }
            }

            // AI Notes
            if let notes = mealPlan.aiNotes {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.green)
                        Text("AI Recommendations")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }

                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No meal plan for this date")
                .font(.headline)

            Text("Generate a personalized meal plan to get started")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: {
                showingPlanCreation = true
            }) {
                Text("Create Meal Plan")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding(40)
    }

    // MARK: - Shopping List

    private var shoppingListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Shopping List")
                .font(.headline)

            if viewModel.shoppingListItems.isEmpty {
                Text("No items in shopping list")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(groupedShoppingItems.keys.sorted(), id: \.self) { category in
                    ShoppingCategorySection(
                        category: category,
                        items: groupedShoppingItems[category] ?? []
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5)
    }

    private var groupedShoppingItems: [String: [ShoppingListItem]] {
        Dictionary(grouping: viewModel.shoppingListItems) { $0.category }
    }

    // MARK: - Methods

    private func loadMealPlans() async {
        guard let userId = authViewModel.user?.id else { return }
        await viewModel.loadMealPlans(userId: userId)
    }
}

// MARK: - Supporting Views

struct DateCard: View {
    let date: Date
    let isSelected: Bool
    let hasMealPlan: Bool
    let action: () -> Void

    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(dayName)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .secondary)

                Text(dayNumber)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .primary)

                if hasMealPlan {
                    Circle()
                        .fill(isSelected ? Color.white : Color.green)
                        .frame(width: 6, height: 6)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(width: 60)
            .padding(.vertical, 12)
            .background(isSelected ? Color.green : Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

struct nutritionSummaryCard: View {
    let nutrition: NutritionalInfo

    init(_ nutrition: NutritionalInfo) {
        self.nutrition = nutrition
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Daily Nutrition")
                    .font(.headline)
                Spacer()
                Text("\(Int(nutrition.calories)) kcal")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
            }

            // Macros Bar
            HStack(spacing: 4) {
                MacroBar(
                    color: .blue,
                    percentage: nutrition.proteinPercentage / 100
                )

                MacroBar(
                    color: .orange,
                    percentage: nutrition.carbsPercentage / 100
                )

                MacroBar(
                    color: .purple,
                    percentage: nutrition.fatPercentage / 100
                )
            }
            .frame(height: 8)
            .cornerRadius(4)

            // Macro Details
            HStack(spacing: 20) {
                MacroDetail(
                    label: "Protein",
                    value: "\(Int(nutrition.proteinG))g",
                    color: .blue
                )

                MacroDetail(
                    label: "Carbs",
                    value: "\(Int(nutrition.carbsG))g",
                    color: .orange
                )

                MacroDetail(
                    label: "Fat",
                    value: "\(Int(nutrition.fatG))g",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5)
    }
}

struct MacroBar: View {
    let color: Color
    let percentage: Double

    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(color)
                .frame(width: geometry.size.width * percentage)
        }
    }
}

struct MacroDetail: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)

            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
        }
    }
}

struct MealCard: View {
    let title: String
    let recipe: Recipe
    let mealType: MealType
    @State private var showingDetail = false

    private var mealIcon: String {
        switch mealType {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .snack: return "leaf.fill"
        }
    }

    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: mealIcon)
                        .foregroundColor(.green)
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(recipe.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                HStack {
                    Label("\(recipe.totalTimeMinutes) min", systemImage: "clock")
                    Spacer()
                    Label("\(Int(recipe.nutrition.calories)) kcal", systemImage: "flame")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .sheet(isPresented: $showingDetail) {
            RecipeDetailView(recipe: recipe)
        }
    }
}

struct ShoppingCategorySection: View {
    let category: String
    let items: [ShoppingListItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(category.capitalized)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.green)

            ForEach(items) { item in
                HStack {
                    Image(systemName: "circle")
                        .font(.caption)
                        .foregroundColor(.gray)

                    Text(item.item)
                        .font(.caption)

                    Spacer()

                    Text("\(item.amount) \(item.unit)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Diet Plan Creation View

struct DietPlanCreationView: View {
    @ObservedObject var viewModel: DietViewModel
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("Diet Type") {
                    Picker("Type", selection: $viewModel.selectedDietType) {
                        ForEach(DietType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }

                Section("Calorie Target") {
                    Stepper("\(viewModel.dailyCalorieTarget) kcal/day",
                            value: $viewModel.dailyCalorieTarget,
                            in: 1200...5000,
                            step: 100)
                }

                Section("Plan Duration") {
                    Stepper("\(viewModel.numDays) days",
                            value: $viewModel.numDays,
                            in: 1...30)
                }

                Section("Meals Per Day") {
                    Stepper("\(viewModel.mealsPerDay) meals",
                            value: $viewModel.mealsPerDay,
                            in: 2...6)
                }

                Section("Goals") {
                    ForEach(GoalType.allCases, id: \.self) { goal in
                        Toggle(goal.displayName, isOn: Binding(
                            get: { viewModel.selectedGoals.contains(goal) },
                            set: { isOn in
                                if isOn {
                                    viewModel.selectedGoals.append(goal)
                                } else {
                                    viewModel.selectedGoals.removeAll { $0 == goal }
                                }
                            }
                        ))
                    }
                }
            }
            .navigationTitle("Create Diet Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Generate") {
                        Task {
                            await generatePlan()
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
    }

    private func generatePlan() async {
        guard let userId = authViewModel.user?.id else { return }
        await viewModel.generateDietPlan(userId: userId)
        if viewModel.errorMessage == nil {
            dismiss()
        }
    }
}

// MARK: - Recipe Detail View

struct RecipeDetailView: View {
    let recipe: Recipe
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(recipe.name)
                            .font(.title)
                            .fontWeight(.bold)

                        Text(recipe.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        HStack {
                            Label("\(recipe.prepTimeMinutes) min prep", systemImage: "clock")
                            Label("\(recipe.cookTimeMinutes) min cook", systemImage: "flame")
                            Label("\(recipe.servings) servings", systemImage: "person.2")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }

                    Divider()

                    // Nutrition
                    nutritionSummaryCard(recipe.nutrition)

                    // Ingredients
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ingredients")
                            .font(.headline)

                        ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { _, ingredient in
                            HStack {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .foregroundColor(.green)

                                Text("\(ingredient["amount"] ?? "") \(ingredient["unit"] ?? "") \(ingredient["item"] ?? "")")
                                    .font(.subheadline)
                            }
                        }
                    }

                    Divider()

                    // Instructions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Instructions")
                            .font(.headline)

                        ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, instruction in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.headline)
                                    .foregroundColor(.green)
                                    .frame(width: 24)

                                Text(instruction)
                                    .font(.subheadline)
                            }
                        }
                    }
                }
                .padding()
            }
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
}
