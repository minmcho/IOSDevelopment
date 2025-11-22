import Foundation

// MARK: - User Profile
struct YogaUserProfile: Codable, Identifiable {
    let id: String
    var name: String
    var email: String
    var experienceLevel: ExperienceLevel
    var goals: [String]
    var healthConditions: [String]
    var preferences: [String: String]

    enum ExperienceLevel: String, Codable, CaseIterable {
        case beginner = "beginner"
        case intermediate = "intermediate"
        case advanced = "advanced"

        var displayName: String {
            rawValue.capitalized
        }
    }

    enum CodingKeys: String, CodingKey {
        case id = "user_id"
        case name, email
        case experienceLevel = "experience_level"
        case goals
        case healthConditions = "health_conditions"
        case preferences
    }
}

// MARK: - Yoga Session Request
struct YogaSessionRequest: Codable {
    let userId: String
    let durationMinutes: Int
    let difficulty: String
    let focusAreas: [String]
    let sessionType: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case durationMinutes = "duration_minutes"
        case difficulty
        case focusAreas = "focus_areas"
        case sessionType = "session_type"
    }
}

// MARK: - Yoga Pose
struct YogaPose: Codable, Identifiable {
    let id = UUID()
    let name: String
    let duration: Int
    let category: String
    let instructions: String
    let benefits: [String]
    let keyPoints: [String]

    enum CodingKeys: String, CodingKey {
        case name, duration, category, instructions, benefits
        case keyPoints = "key_points"
    }
}

// MARK: - Yoga Plan Response
struct YogaPlanResponse: Codable {
    let sessionId: String
    let poses: [YogaPose]
    let durationMinutes: Int
    let instructions: String
    let tips: [String]
    let estimatedCalories: Int

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case poses
        case durationMinutes = "duration_minutes"
        case instructions, tips
        case estimatedCalories = "estimated_calories"
    }
}

// MARK: - Pose Correction
struct PoseCorrection: Codable, Identifiable {
    let id = UUID()
    let poseName: String
    let timestamp: String
    let corrections: [String]
    let accuracyScore: Double
    let imageData: String?

    enum CodingKeys: String, CodingKey {
        case poseName = "pose_name"
        case timestamp, corrections
        case accuracyScore = "accuracy_score"
        case imageData = "image_data"
    }
}

// MARK: - Chat Message
struct ChatMessage: Codable, Identifiable {
    let id = UUID()
    let userId: String
    let message: String
    let context: [String: String]
    let isUser: Bool
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case message, context
    }
}

// MARK: - Chat Response
struct ChatResponse: Codable {
    let status: String
    let response: String
    let timestamp: String
}

// MARK: - Session State
enum SessionState {
    case notStarted
    case inProgress
    case paused
    case completed
}

// MARK: - WebSocket Message
struct WebSocketMessage: Codable {
    let type: String
    let message: String?
    let sessionId: String?
    let poseName: String?
    let corrections: [String]?
    let accuracy: Double?
    let timestamp: String?
    let image: String?

    enum CodingKeys: String, CodingKey {
        case type, message
        case sessionId = "session_id"
        case poseName = "pose_name"
        case corrections, accuracy, timestamp, image
    }
}

// MARK: - Focus Area
enum FocusArea: String, CaseIterable {
    case flexibility = "flexibility"
    case strength = "strength"
    case balance = "balance"
    case relaxation = "relaxation"

    var icon: String {
        switch self {
        case .flexibility: return "figure.flexibility"
        case .strength: return "figure.strengthtraining.traditional"
        case .balance: return "figure.mind.and.body"
        case .relaxation: return "figure.cooldown"
        }
    }

    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - Session Type
enum SessionType: String, CaseIterable {
    case morning = "morning"
    case evening = "evening"
    case quick = "quick"
    case full = "full"

    var icon: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .evening: return "sunset.fill"
        case .quick: return "bolt.fill"
        case .full: return "star.fill"
        }
    }

    var displayName: String {
        rawValue.capitalized
    }
}
