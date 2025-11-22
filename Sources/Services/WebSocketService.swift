import Foundation
import Combine

class WebSocketService: NSObject, ObservableObject {
    @Published var isConnected = false
    @Published var receivedMessage: WebSocketMessage?
    @Published var connectionError: Error?

    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession!

    private let baseURL = "ws://localhost:8000/ws"

    override init() {
        super.init()
        urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
    }

    // MARK: - Connect to WebSocket
    func connect(sessionId: String, userId: String) {
        let urlString = "\(baseURL)/pose-guidance/\(sessionId)/\(userId)"
        guard let url = URL(string: urlString) else {
            print("Invalid WebSocket URL")
            return
        }

        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        isConnected = true

        receiveMessage()
    }

    // MARK: - Disconnect
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        isConnected = false
    }

    // MARK: - Send Message
    func sendMessage(_ message: WebSocketMessage) {
        guard let webSocketTask = webSocketTask else {
            print("WebSocket not connected")
            return
        }

        do {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            let data = try encoder.encode(message)

            if let jsonString = String(data: data, encoding: .utf8) {
                let message = URLSessionWebSocketTask.Message.string(jsonString)

                webSocketTask.send(message) { error in
                    if let error = error {
                        print("WebSocket send error: \(error)")
                        DispatchQueue.main.async {
                            self.connectionError = error
                        }
                    }
                }
            }
        } catch {
            print("Failed to encode message: \(error)")
        }
    }

    // MARK: - Send Pose Frame
    func sendPoseFrame(image: String, poseName: String) {
        let message = WebSocketMessage(
            type: "pose_frame",
            message: nil,
            sessionId: nil,
            poseName: poseName,
            corrections: nil,
            accuracy: nil,
            timestamp: nil,
            image: image
        )
        sendMessage(message)
    }

    // MARK: - End Session
    func endSession() {
        let message = WebSocketMessage(
            type: "session_end",
            message: "Session completed",
            sessionId: nil,
            poseName: nil,
            corrections: nil,
            accuracy: nil,
            timestamp: nil,
            image: nil
        )
        sendMessage(message)
    }

    // MARK: - Receive Messages
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self?.handleReceivedText(text)
                case .data(let data):
                    self?.handleReceivedData(data)
                @unknown default:
                    break
                }

                // Continue receiving messages
                self?.receiveMessage()

            case .failure(let error):
                print("WebSocket receive error: \(error)")
                DispatchQueue.main.async {
                    self?.connectionError = error
                    self?.isConnected = false
                }
            }
        }
    }

    private func handleReceivedText(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        handleReceivedData(data)
    }

    private func handleReceivedData(_ data: Data) {
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let message = try decoder.decode(WebSocketMessage.self, from: data)

            DispatchQueue.main.async {
                self.receivedMessage = message
            }
        } catch {
            print("Failed to decode WebSocket message: \(error)")
        }
    }
}

// MARK: - URLSessionWebSocketDelegate
extension WebSocketService: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        DispatchQueue.main.async {
            self.isConnected = true
        }
        print("WebSocket connected")
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        DispatchQueue.main.async {
            self.isConnected = false
        }
        print("WebSocket disconnected")
    }
}
