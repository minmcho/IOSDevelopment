import SwiftUI
import AVFoundation

struct PoseGuidanceView: View {
    @ObservedObject var viewModel: YogaViewModel
    @ObservedObject var wsService: WebSocketService
    let currentPose: YogaPose?

    @Environment(\.dismiss) var dismiss
    @StateObject private var cameraManager = CameraManager()

    @State private var showingCorrections = false
    @State private var latestCorrections: [String] = []
    @State private var accuracyScore: Double = 0.0

    var body: some View {
        NavigationView {
            ZStack {
                // Camera Preview
                CameraPreview(camera: cameraManager)
                    .ignoresSafeArea()

                VStack {
                    Spacer()

                    // Pose Information Overlay
                    if let pose = currentPose {
                        poseInfoOverlay(pose)
                    }

                    // Real-time Feedback
                    if wsService.isConnected {
                        realTimeFeedbackOverlay
                    }

                    // Controls
                    controlsOverlay
                }
            }
            .navigationTitle("AI Pose Guidance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        wsService.endSession()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    connectionIndicator
                }
            }
            .onAppear {
                cameraManager.checkPermission()
            }
            .onReceive(wsService.$receivedMessage) { message in
                handleWebSocketMessage(message)
            }
        }
    }

    // MARK: - Pose Info Overlay
    private func poseInfoOverlay(_ pose: YogaPose) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(pose.name)
                .font(.headline)
                .foregroundColor(.white)

            HStack {
                Image(systemName: "target")
                    .foregroundColor(.green)
                Text("Hold for \(pose.duration)s")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
        }
        .padding()
        .background(Color.black.opacity(0.7))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    // MARK: - Real-time Feedback Overlay
    private var realTimeFeedbackOverlay: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("AI Analysis")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                // Accuracy Score
                HStack(spacing: 4) {
                    Image(systemName: accuracyScore > 0.8 ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundColor(accuracyScore > 0.8 ? .green : .orange)

                    Text("\(Int(accuracyScore * 100))%")
                        .font(.subheadline)
                        .bold()
                        .foregroundColor(.white)
                }
            }

            if !latestCorrections.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(latestCorrections.prefix(3), id: \.self) { correction in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "arrow.right.circle.fill")
                                .foregroundColor(.blue)
                                .font(.caption)

                            Text(correction)
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.7))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    // MARK: - Controls Overlay
    private var controlsOverlay: some View {
        HStack(spacing: 30) {
            // Capture Frame Button
            Button(action: captureAndAnalyzePose) {
                VStack(spacing: 4) {
                    Image(systemName: "camera.circle.fill")
                        .font(.system(size: 50))
                    Text("Analyze Pose")
                        .font(.caption)
                }
                .foregroundColor(.white)
            }

            // Toggle Corrections
            Button(action: { showingCorrections.toggle() }) {
                VStack(spacing: 4) {
                    Image(systemName: "list.bullet.circle.fill")
                        .font(.system(size: 40))
                    Text("Tips")
                        .font(.caption)
                }
                .foregroundColor(.white)
            }
        }
        .padding(.bottom, 40)
    }

    // MARK: - Connection Indicator
    private var connectionIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(wsService.isConnected ? Color.green : Color.red)
                .frame(width: 8, height: 8)

            Text(wsService.isConnected ? "Live" : "Offline")
                .font(.caption)
        }
    }

    // MARK: - Actions
    private func captureAndAnalyzePose() {
        guard let pose = currentPose,
              let image = cameraManager.captureFrame() else {
            return
        }

        // Convert image to base64 for transmission
        if let imageData = image.jpegData(compressionQuality: 0.7) {
            let base64String = imageData.base64EncodedString()

            // Send via WebSocket for real-time analysis
            wsService.sendPoseFrame(image: base64String, poseName: pose.name)

            // Also send to REST API for detailed analysis
            Task {
                await viewModel.analyzePose(image: image, poseName: pose.name)
            }
        }
    }

    private func handleWebSocketMessage(_ message: WebSocketMessage?) {
        guard let message = message else { return }

        switch message.type {
        case "connection":
            print("Connected to pose guidance")

        case "pose_feedback":
            if let corrections = message.corrections {
                latestCorrections = corrections
            }
            if let accuracy = message.accuracy {
                withAnimation {
                    accuracyScore = accuracy
                }
            }

        case "session_complete":
            dismiss()

        default:
            break
        }
    }
}

// MARK: - Camera Manager
class CameraManager: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var output = AVCapturePhotoOutput()
    @Published var preview: AVCaptureVideoPreviewLayer!
    @Published var isAuthorized = false

    private var captureCompletion: ((UIImage?) -> Void)?

    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setUp()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] status in
                if status {
                    DispatchQueue.main.async {
                        self?.setUp()
                    }
                }
            }
        default:
            break
        }
    }

    func setUp() {
        do {
            session.beginConfiguration()

            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
                return
            }

            let input = try AVCaptureDeviceInput(device: device)

            if session.canAddInput(input) {
                session.addInput(input)
            }

            if session.canAddOutput(output) {
                session.addOutput(output)
            }

            session.commitConfiguration()

            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.startRunning()
            }

            DispatchQueue.main.async {
                self.isAuthorized = true
            }
        } catch {
            print("Camera setup error: \(error.localizedDescription)")
        }
    }

    func captureFrame() -> UIImage? {
        guard let connection = output.connection(with: .video),
              connection.isEnabled,
              connection.isActive else {
            return nil
        }

        // For real implementation, use AVCapturePhotoOutput
        // This is a simplified version
        return UIImage(systemName: "person.fill") // Placeholder
    }
}

// MARK: - Camera Preview
struct CameraPreview: UIViewRepresentable {
    @ObservedObject var camera: CameraManager

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)

        camera.preview = AVCaptureVideoPreviewLayer(session: camera.session)
        camera.preview.frame = view.frame
        camera.preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(camera.preview)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
    }
}
