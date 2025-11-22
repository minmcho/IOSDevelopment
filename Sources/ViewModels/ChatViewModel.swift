import Foundation
import SwiftUI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiService = YogaAPIService.shared
    private var userId: String

    init(userId: String) {
        self.userId = userId
        addWelcomeMessage()
    }

    private func addWelcomeMessage() {
        let welcomeMessage = ChatMessage(
            userId: "system",
            message: "Hello! I'm your AI Yoga Assistant. Ask me anything about yoga poses, breathing techniques, or personalized guidance!",
            context: [:],
            isUser: false,
            timestamp: Date()
        )
        messages.append(welcomeMessage)
    }

    func sendMessage(_ text: String, context: [String: String] = [:]) async {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        // Add user message
        let userMessage = ChatMessage(
            userId: userId,
            message: text,
            context: context,
            isUser: true,
            timestamp: Date()
        )
        messages.append(userMessage)

        isLoading = true
        errorMessage = nil

        do {
            let response = try await apiService.sendChatMessage(
                userId: userId,
                message: text,
                context: context
            )

            // Add AI response
            let aiMessage = ChatMessage(
                userId: "ai",
                message: response,
                context: [:],
                isUser: false,
                timestamp: Date()
            )
            messages.append(aiMessage)
        } catch {
            errorMessage = "Failed to send message: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func clearChat() {
        messages.removeAll()
        addWelcomeMessage()
    }
}
