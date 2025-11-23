import Foundation

// MARK: - Enums

enum DietType: String, Codable, CaseIterable {
    case balanced
    case vegan
    case vegetarian
    case keto
    case paleo
    case mediterranean
    case lowCarb = "low_carb"
    case highProtein = "high_protein"

    var displayName: String {
        switch self {
        case .balanced: return "Balanced"
        case .vegan: return "Vegan"
        case .vegetarian: return "Vegetarian"
        case .keto: return "Keto"
        case .paleo: return "Paleo"
        case .mediterranean: return "Mediterranean"
        case .lowCarb: return "Low Carb"
        case .highProtein: return "High Protein"
        }
    }
}

enum MealType: String, Codable, CaseIterable {
    case breakfast
    case lunch
    case dinner
    case snack

    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Nutritional Info

struct NutritionalInfo: Codable {
    let calories: Double
    let proteinG: Double
    let carbsG: Double
    let fatG: Double
    let fiberG: Double?
    let sugarG: Double?
    let sodiumMg: Double?
    let vitamins: [String: String]?

    enum CodingKeys: String, CodingKey {
        case calories, vitamins
        case proteinG = "protein_g"
        case carbsG = "carbs_g"
        case fatG = "fat_g"
        case fiberG = "fiber_g"
        case sugarG = "sugar_g"
        case sodiumMg = "sodium_mg"
    }

    var proteinPercentage: Double {
        (proteinG * 4 / calories) * 100
    }

    var carbsPercentage: Double {
        (carbsG * 4 / calories) * 100
    }

    var fatPercentage: Double {
        (fatG * 9 / calories) * 100
    }
}

// MARK: - Recipe

struct Recipe: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let mealType: MealType
    let ingredients: [[String: String]]
    let instructions: [String]
    let prepTimeMinutes: Int
    let cookTimeMinutes: Int
    let servings: Int
    let nutrition: NutritionalInfo
    let tags: [String]
    let dietType: [String]
    let imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, name, description, ingredients, instructions, servings, nutrition, tags, imageUrl
        case mealType = "meal_type"
        case prepTimeMinutes = "prep_time_minutes"
        case cookTimeMinutes = "cook_time_minutes"
        case dietType = "diet_type"
    }

    var totalTimeMinutes: Int {
        prepTimeMinutes + cookTimeMinutes
    }
}

// MARK: - Meal Plan

struct MealPlan: Codable, Identifiable {
    let id: String
    let userId: String
    let date: Date
    let breakfast: Recipe?
    let lunch: Recipe?
    let dinner: Recipe?
    let snacks: [Recipe]
    let totalNutrition: NutritionalInfo
    let createdAt: Date
    let aiNotes: String?

    enum CodingKeys: String, CodingKey {
        case id, date, breakfast, lunch, dinner, snacks
        case userId = "user_id"
        case totalNutrition = "total_nutrition"
        case createdAt = "created_at"
        case aiNotes = "ai_notes"
    }
}

// MARK: - Diet Plan Request

struct DietPlanRequest: Codable {
    let userId: String
    let dietType: DietType
    let dailyCalorieTarget: Int
    let numDays: Int
    let mealsPerDay: Int
    let allergies: [String]
    let dislikedFoods: [String]
    let goals: [GoalType]

    enum CodingKeys: String, CodingKey {
        case dietType, allergies, goals
        case userId = "user_id"
        case dailyCalorieTarget = "daily_calorie_target"
        case numDays = "num_days"
        case mealsPerDay = "meals_per_day"
        case dislikedFoods = "disliked_foods"
    }
}

// MARK: - Diet Plan Response

struct DietPlanResponse: Codable {
    let mealPlans: [MealPlan]
    let aiRecommendations: String
    let weeklyNutritionSummary: NutritionalInfo
    let shoppingList: [[String: String]]

    enum CodingKeys: String, CodingKey {
        case shoppingList
        case mealPlans = "meal_plans"
        case aiRecommendations = "ai_recommendations"
        case weeklyNutritionSummary = "weekly_nutrition_summary"
    }
}

// MARK: - Diet Progress

struct DietProgress: Codable, Identifiable {
    var id: String { "\(userId)_\(date)" }
    let userId: String
    let date: Date
    let mealsLogged: Int
    let caloriesConsumed: Double
    let proteinG: Double
    let carbsG: Double
    let fatG: Double
    let waterMl: Double?
    let weight: Double?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case date, notes, weight
        case userId = "user_id"
        case mealsLogged = "meals_logged"
        case caloriesConsumed = "calories_consumed"
        case proteinG = "protein_g"
        case carbsG = "carbs_g"
        case fatG = "fat_g"
        case waterMl = "water_ml"
    }
}

// MARK: - Shopping List Item

struct ShoppingListItem: Identifiable {
    let id = UUID()
    let item: String
    let amount: String
    let unit: String
    let category: String
    var isPurchased: Bool = false
}
