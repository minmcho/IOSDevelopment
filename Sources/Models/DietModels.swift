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

// MARK: - Micronutrients

struct Vitamins: Codable {
    let vitaminAMcg: Double?
    let vitaminCMg: Double?
    let vitaminDMcg: Double?
    let vitaminEMg: Double?
    let vitaminKMcg: Double?
    let vitaminB1ThiaminMg: Double?
    let vitaminB2RiboflavinMg: Double?
    let vitaminB3NiacinMg: Double?
    let vitaminB6Mg: Double?
    let vitaminB9FolateMcg: Double?
    let vitaminB12Mcg: Double?
    let cholineMg: Double?

    enum CodingKeys: String, CodingKey {
        case vitaminAMcg = "vitamin_a_mcg"
        case vitaminCMg = "vitamin_c_mg"
        case vitaminDMcg = "vitamin_d_mcg"
        case vitaminEMg = "vitamin_e_mg"
        case vitaminKMcg = "vitamin_k_mcg"
        case vitaminB1ThiaminMg = "vitamin_b1_thiamin_mg"
        case vitaminB2RiboflavinMg = "vitamin_b2_riboflavin_mg"
        case vitaminB3NiacinMg = "vitamin_b3_niacin_mg"
        case vitaminB6Mg = "vitamin_b6_mg"
        case vitaminB9FolateMcg = "vitamin_b9_folate_mcg"
        case vitaminB12Mcg = "vitamin_b12_mcg"
        case cholineMg = "choline_mg"
    }
}

struct Minerals: Codable {
    let calciumMg: Double?
    let ironMg: Double?
    let magnesiumMg: Double?
    let phosphorusMg: Double?
    let potassiumMg: Double?
    let sodiumMg: Double?
    let zincMg: Double?
    let copperMg: Double?
    let manganeseMg: Double?
    let seleniumMcg: Double?
    let iodineMcg: Double?

    enum CodingKeys: String, CodingKey {
        case calciumMg = "calcium_mg"
        case ironMg = "iron_mg"
        case magnesiumMg = "magnesium_mg"
        case phosphorusMg = "phosphorus_mg"
        case potassiumMg = "potassium_mg"
        case sodiumMg = "sodium_mg"
        case zincMg = "zinc_mg"
        case copperMg = "copper_mg"
        case manganeseMg = "manganese_mg"
        case seleniumMcg = "selenium_mcg"
        case iodineMcg = "iodine_mcg"
    }
}

struct Micronutrients: Codable {
    let vitamins: Vitamins
    let minerals: Minerals
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
    let saturatedFatG: Double?
    let transFatG: Double?
    let cholesterolMg: Double?
    let micronutrients: Micronutrients?
    let vitamins: [String: String]?  // Legacy support

    enum CodingKeys: String, CodingKey {
        case calories, vitamins, micronutrients
        case proteinG = "protein_g"
        case carbsG = "carbs_g"
        case fatG = "fat_g"
        case fiberG = "fiber_g"
        case sugarG = "sugar_g"
        case sodiumMg = "sodium_mg"
        case saturatedFatG = "saturated_fat_g"
        case transFatG = "trans_fat_g"
        case cholesterolMg = "cholesterol_mg"
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

// MARK: - Micronutrient Analysis

struct MicronutrientGoals: Codable {
    let userId: String
    let age: Int
    let gender: String

    // Vitamin goals
    let vitaminAMcg: Double
    let vitaminCMg: Double
    let vitaminDMcg: Double
    let vitaminEMg: Double
    let vitaminKMcg: Double
    let vitaminB1Mg: Double
    let vitaminB2Mg: Double
    let vitaminB3Mg: Double
    let vitaminB6Mg: Double
    let vitaminB9Mcg: Double
    let vitaminB12Mcg: Double

    // Mineral goals
    let calciumMg: Double
    let ironMg: Double
    let magnesiumMg: Double
    let potassiumMg: Double
    let sodiumMg: Double
    let zincMg: Double
    let seleniumMcg: Double

    enum CodingKeys: String, CodingKey {
        case age, gender
        case userId = "user_id"
        case vitaminAMcg = "vitamin_a_mcg"
        case vitaminCMg = "vitamin_c_mg"
        case vitaminDMcg = "vitamin_d_mcg"
        case vitaminEMg = "vitamin_e_mg"
        case vitaminKMcg = "vitamin_k_mcg"
        case vitaminB1Mg = "vitamin_b1_mg"
        case vitaminB2Mg = "vitamin_b2_mg"
        case vitaminB3Mg = "vitamin_b3_mg"
        case vitaminB6Mg = "vitamin_b6_mg"
        case vitaminB9Mcg = "vitamin_b9_mcg"
        case vitaminB12Mcg = "vitamin_b12_mcg"
        case calciumMg = "calcium_mg"
        case ironMg = "iron_mg"
        case magnesiumMg = "magnesium_mg"
        case potassiumMg = "potassium_mg"
        case sodiumMg = "sodium_mg"
        case zincMg = "zinc_mg"
        case seleniumMcg = "selenium_mcg"
    }
}

struct MicronutrientDeficiency: Codable, Identifiable {
    var id: String { nutrientName }
    let nutrientName: String
    let currentIntake: Double
    let recommendedIntake: Double
    let deficitPercentage: Double
    let healthImpacts: [String]
    let foodSources: [String]
    let severity: String

    enum CodingKeys: String, CodingKey {
        case severity
        case nutrientName = "nutrient_name"
        case currentIntake = "current_intake"
        case recommendedIntake = "recommended_intake"
        case deficitPercentage = "deficit_percentage"
        case healthImpacts = "health_impacts"
        case foodSources = "food_sources"
    }

    var severityColor: String {
        switch severity {
        case "high": return "red"
        case "moderate": return "orange"
        default: return "yellow"
        }
    }
}

struct MicronutrientAnalysis: Codable {
    let userId: String
    let period: String
    let startDate: Date
    let endDate: Date

    let avgVitamins: Vitamins
    let avgMinerals: Minerals
    let goals: MicronutrientGoals

    let deficiencies: [MicronutrientDeficiency]
    let adequacies: [String]
    let excesses: [String]

    let aiRecommendations: String
    let supplementSuggestions: [String]
    let dietaryAdjustments: [String]

    let vitaminCompletionPercentages: [String: Double]
    let mineralCompletionPercentages: [String: Double]

    enum CodingKeys: String, CodingKey {
        case period, deficiencies, adequacies, excesses
        case userId = "user_id"
        case startDate = "start_date"
        case endDate = "end_date"
        case avgVitamins = "avg_vitamins"
        case avgMinerals = "avg_minerals"
        case goals
        case aiRecommendations = "ai_recommendations"
        case supplementSuggestions = "supplement_suggestions"
        case dietaryAdjustments = "dietary_adjustments"
        case vitaminCompletionPercentages = "vitamin_completion_percentages"
        case mineralCompletionPercentages = "mineral_completion_percentages"
    }
}
