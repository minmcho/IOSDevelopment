import Foundation
import Combine
import UIKit

class YogaAPIService: ObservableObject {
    static let shared = YogaAPIService()

    // Configure your backend URL
    private let baseURL = "http://localhost:8000/api/v1"
    private let wsBaseURL = "ws://localhost:8000/ws"

    private var cancellables = Set<AnyCancellable>()

    // MARK: - User Profile
    func createUserProfile(_ profile: YogaUserProfile) async throws -> Bool {
        let url = URL(string: "\(baseURL)/user/profile")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try encoder.encode(profile)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }

        return true
    }

    // MARK: - Yoga Plan Generation
    func generateYogaPlan(
        session: YogaSessionRequest,
        userProfile: YogaUserProfile
    ) async throws -> YogaPlanResponse {
        let url = URL(string: "\(baseURL)/yoga/plan")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "session": try session.asDictionary(),
            "user_profile": try userProfile.asDictionary()
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let plan = try decoder.decode(YogaPlanResponse.self, from: data)
        return plan
    }

    // MARK: - Pose Analysis
    func analyzePose(image: UIImage, poseName: String) async throws -> PoseCorrection {
        let url = URL(string: "\(baseURL)/pose/analyze?pose_name=\(poseName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // Create multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Add image data
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"image\"; filename=\"pose.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let correction = try decoder.decode(PoseCorrection.self, from: data)
        return correction
    }

    // MARK: - Chat with AI Agent
    func sendChatMessage(userId: String, message: String, context: [String: String] = [:]) async throws -> String {
        let url = URL(string: "\(baseURL)/chat")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "user_id": userId,
            "message": message,
            "context": context
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }

        let decoder = JSONDecoder()
        let chatResponse = try decoder.decode(ChatResponse.self, from: data)
        return chatResponse.response
    }

    // MARK: - Get Pose Library
    func getPoseLibrary(difficulty: String? = nil) async throws -> [YogaPose] {
        var urlString = "\(baseURL)/poses/library"
        if let difficulty = difficulty {
            urlString += "?difficulty=\(difficulty)"
        }

        let url = URL(string: urlString)!
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let result = try decoder.decode([String: [YogaPose]].self, from: data)
        return result["poses"] ?? []
    }

    // MARK: - Health Check
    func healthCheck() async throws -> Bool {
        let url = URL(string: "\(baseURL.replacingOccurrences(of: "/api/v1", with: ""))/health")!
        let (_, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            return false
        }

        return true
    }
}

// MARK: - API Errors
enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case encodingError
    case decodingError
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .encodingError:
            return "Failed to encode request"
        case .decodingError:
            return "Failed to decode response"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Encodable Extension
extension Encodable {
    func asDictionary() throws -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw APIError.encodingError
        }
        return dictionary
    }
}
