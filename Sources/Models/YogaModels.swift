import Foundation

// MARK: - Enums

enum YogaLevel: String, Codable, CaseIterable {
    case beginner
    case intermediate
    case advanced
    case expert

    var displayName: String {
        rawValue.capitalized
    }
}

enum YogaStyle: String, Codable, CaseIterable {
    case hatha
    case vinyasa
    case ashtanga
    case bikram
    case yin
    case restorative
    case power
    case kundalini

    var displayName: String {
        rawValue.capitalized
    }
}

enum GoalType: String, Codable, CaseIterable {
    case weightLoss = "weight_loss"
    case muscleGain = "muscle_gain"
    case flexibility
    case stressRelief = "stress_relief"
    case generalHealth = "general_health"
    case athleticPerformance = "athletic_performance"

    var displayName: String {
        switch self {
        case .weightLoss: return "Weight Loss"
        case .muscleGain: return "Muscle Gain"
        case .flexibility: return "Flexibility"
        case .stressRelief: return "Stress Relief"
        case .generalHealth: return "General Health"
        case .athleticPerformance: return "Athletic Performance"
        }
    }
}

// MARK: - Yoga Pose

struct YogaPose: Codable, Identifiable {
    let id: String
    let name: String
    let sanskritName: String?
    let description: String
    let benefits: [String]
    let difficulty: YogaLevel
    let durationSeconds: Int
    let instructions: [String]
    let precautions: [String]
    let imageUrl: String?
    let videoUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, name, description, benefits, difficulty, instructions, precautions
        case sanskritName = "sanskrit_name"
        case durationSeconds = "duration_seconds"
        case imageUrl = "image_url"
        case videoUrl = "video_url"
    }
}

// MARK: - Yoga Session

struct YogaSession: Codable, Identifiable {
    let id: String
    let userId: String
    let title: String
    let style: YogaStyle
    let level: YogaLevel
    let durationMinutes: Int
    let poses: [YogaPose]
    let warmUp: [YogaPose]
    let coolDown: [YogaPose]
    let createdAt: Date
    var completed: Bool
    var completedAt: Date?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case id, title, style, level, poses, completed, notes
        case userId = "user_id"
        case durationMinutes = "duration_minutes"
        case warmUp = "warm_up"
        case coolDown = "cool_down"
        case createdAt = "created_at"
        case completedAt = "completed_at"
    }
}

// MARK: - Yoga Plan Request

struct YogaPlanRequest: Codable {
    let userId: String
    let level: YogaLevel
    let style: YogaStyle
    let durationMinutes: Int
    let focusAreas: [String]
    let goals: [GoalType]
    let avoidPoses: [String]

    enum CodingKeys: String, CodingKey {
        case level, style, goals
        case userId = "user_id"
        case durationMinutes = "duration_minutes"
        case focusAreas = "focus_areas"
        case avoidPoses = "avoid_poses"
    }
}

// MARK: - Yoga Plan Response

struct YogaPlanResponse: Codable {
    let session: YogaSession
    let aiRecommendations: String
    let estimatedCaloriesBurned: Double
    let benefits: [String]

    enum CodingKeys: String, CodingKey {
        case session, benefits
        case aiRecommendations = "ai_recommendations"
        case estimatedCaloriesBurned = "estimated_calories_burned"
    }
}

// MARK: - Yoga Progress

struct YogaProgress: Codable, Identifiable {
    var id: String { "\(userId)_\(date)" }
    let userId: String
    let date: Date
    let sessionsCompleted: Int
    let totalMinutes: Int
    let caloriesBurned: Double
    let posesMastered: [String]
    let flexibilityScore: Double?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case date, notes
        case userId = "user_id"
        case sessionsCompleted = "sessions_completed"
        case totalMinutes = "total_minutes"
        case caloriesBurned = "calories_burned"
        case posesMastered = "poses_mastered"
        case flexibilityScore = "flexibility_score"
    }
}
