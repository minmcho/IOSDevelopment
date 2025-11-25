import Foundation

class APIClient {
    static let shared = APIClient()

    private let baseURL: String
    private let session: URLSession

    private init() {
        // Configure your backend URL here
        self.baseURL = "http://localhost:8000"  // Change for production
        self.session = URLSession.shared
    }

    // MARK: - Generic Request

    func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Data? = nil
    ) async throws -> T {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body = body {
            request.httpBody = body
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            print("Decoding error: \(error)")
            throw APIError.decodingError(error)
        }
    }

    // MARK: - Yoga Endpoints

    func createYogaPlan(request: YogaPlanRequest) async throws -> YogaPlanResponse {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let body = try encoder.encode(request)

        return try await self.request(
            endpoint: "/api/yoga/plan",
            method: "POST",
            body: body
        )
    }

    func getUserYogaSessions(userId: String, limit: Int = 10) async throws -> [YogaSession] {
        return try await request(
            endpoint: "/api/yoga/sessions/\(userId)?limit=\(limit)"
        )
    }

    func completeYogaSession(sessionId: String, userId: String, notes: String? = nil) async throws {
        var endpoint = "/api/yoga/sessions/\(sessionId)/complete?user_id=\(userId)"
        if let notes = notes {
            endpoint += "&notes=\(notes.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        }

        let _: [String: String] = try await request(endpoint: endpoint, method: "POST")
    }

    func getYogaProgress(userId: String, startDate: Date, endDate: Date) async throws -> [YogaProgress] {
        let formatter = ISO8601DateFormatter()
        let start = formatter.string(from: startDate)
        let end = formatter.string(from: endDate)

        return try await request(
            endpoint: "/api/yoga/progress/\(userId)?start_date=\(start)&end_date=\(end)"
        )
    }

    // MARK: - Diet Endpoints

    func createDietPlan(request: DietPlanRequest) async throws -> DietPlanResponse {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let body = try encoder.encode(request)

        return try await self.request(
            endpoint: "/api/diet/plan",
            method: "POST",
            body: body
        )
    }

    func getMealPlan(userId: String, date: Date) async throws -> MealPlan {
        let formatter = ISO8601DateFormatter()
        let dateStr = formatter.string(from: date)

        return try await request(
            endpoint: "/api/diet/meal-plan/\(userId)/\(dateStr)"
        )
    }

    func getMealPlans(userId: String, startDate: Date, endDate: Date) async throws -> [MealPlan] {
        let formatter = ISO8601DateFormatter()
        let start = formatter.string(from: startDate)
        let end = formatter.string(from: endDate)

        return try await request(
            endpoint: "/api/diet/meal-plans/\(userId)?start_date=\(start)&end_date=\(end)"
        )
    }

    func getDietProgress(userId: String, startDate: Date, endDate: Date) async throws -> [DietProgress] {
        let formatter = ISO8601DateFormatter()
        let start = formatter.string(from: startDate)
        let end = formatter.string(from: endDate)

        return try await request(
            endpoint: "/api/diet/progress/\(userId)?start_date=\(start)&end_date=\(end)"
        )
    }

    // MARK: - Micronutrient Endpoints

    func getMicronutrientGoals(userId: String) async throws -> MicronutrientGoals {
        return try await request(endpoint: "/api/micronutrients/goals/\(userId)")
    }

    func analyzeMicronutrients(
        userId: String,
        days: Int = 7,
        includeAI: Bool = true
    ) async throws -> MicronutrientAnalysis {
        return try await request(
            endpoint: "/api/micronutrients/analyze/\(userId)?days=\(days)&include_ai=\(includeAI)"
        )
    }

    func getMicronutrientDeficiencies(userId: String, days: Int = 14) async throws -> [String: Any] {
        return try await request(
            endpoint: "/api/micronutrients/deficiencies/\(userId)?days=\(days)"
        )
    }

    func getMicronutrientSummary(userId: String) async throws -> [String: Any] {
        return try await request(
            endpoint: "/api/micronutrients/summary/\(userId)"
        )
    }

    // MARK: - Analytics Endpoints

    func getDashboard(userId: String) async throws -> DashboardData {
        return try await request(endpoint: "/api/analytics/dashboard/\(userId)")
    }
}

// MARK: - API Errors

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let code):
            return "Server error: \(code)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}

// MARK: - Dashboard Data

struct DashboardData: Codable {
    let today: TodayStats
    let thisWeek: WeekStats
    let streaks: StreakData
    let date: String

    enum CodingKeys: String, CodingKey {
        case today, date
        case thisWeek = "this_week"
        case streaks
    }
}

struct TodayStats: Codable {
    let yoga: YogaDayStats
    let diet: DietDayStats
}

struct YogaDayStats: Codable {
    let sessions: Int
    let minutes: Int
    let caloriesBurned: Double

    enum CodingKeys: String, CodingKey {
        case sessions, minutes
        case caloriesBurned = "calories_burned"
    }
}

struct DietDayStats: Codable {
    let mealsLogged: Int
    let calories: Double

    enum CodingKeys: String, CodingKey {
        case calories
        case mealsLogged = "meals_logged"
    }
}

struct WeekStats: Codable {
    let yoga: YogaWeekStats
    let diet: DietWeekStats
}

struct YogaWeekStats: Codable {
    let totalSessions: Int
    let totalMinutes: Int
    let totalCaloriesBurned: Double

    enum CodingKeys: String, CodingKey {
        case totalSessions = "total_sessions"
        case totalMinutes = "total_minutes"
        case totalCaloriesBurned = "total_calories_burned"
    }
}

struct DietWeekStats: Codable {
    let totalMeals: Int
    let avgCalories: Double

    enum CodingKeys: String, CodingKey {
        case totalMeals = "total_meals"
        case avgCalories = "avg_calories"
    }
}

struct StreakData: Codable {
    let yogaStreakDays: Int
    let dietStreakDays: Int
    let totalActiveDays: Int

    enum CodingKeys: String, CodingKey {
        case yogaStreakDays = "yoga_streak_days"
        case dietStreakDays = "diet_streak_days"
        case totalActiveDays = "total_active_days"
    }
}
