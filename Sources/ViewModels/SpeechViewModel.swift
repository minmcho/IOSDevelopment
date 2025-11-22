import Foundation
import Speech

@MainActor
class SpeechViewModel: ObservableObject {
    @Published var selectedLanguage: SupportedLanguage = .english
    @Published var textToSpeak: String = ""
    @Published var recognizedText: String = ""
    @Published var isRecording: Bool = false
    @Published var isSpeaking: Bool = false
    @Published var errorMessage: String?
    @Published var speechAuthorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined

    let recognitionService = SpeechRecognitionService()
    let synthesisService = SpeechSynthesisService()
    let languageProvider = LanguageProvider.shared

    init() {
        setupBindings()
    }

    private func setupBindings() {
        Task {
            for await isRecording in recognitionService.$isRecording.values {
                self.isRecording = isRecording
            }
        }

        Task {
            for await text in recognitionService.$recognizedText.values {
                self.recognizedText = text
            }
        }

        Task {
            for await isSpeaking in synthesisService.$isSpeaking.values {
                self.isSpeaking = isSpeaking
            }
        }

        Task {
            for await status in recognitionService.$authorizationStatus.values {
                self.speechAuthorizationStatus = status
            }
        }

        Task {
            for await language in languageProvider.$selectedLanguage.values {
                self.selectedLanguage = language
            }
        }
    }

    func requestSpeechAuthorization() async {
        let authorized = await recognitionService.requestAuthorization()
        if !authorized {
            errorMessage = "Speech recognition permission denied. Please enable it in Settings."
        }
    }

    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    func startRecording() {
        do {
            try recognitionService.startRecording(language: selectedLanguage)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func stopRecording() {
        recognitionService.stopRecording()
    }

    func speak(text: String? = nil) {
        let textToUse = text ?? textToSpeak
        guard !textToUse.isEmpty else {
            errorMessage = "Please enter text to speak"
            return
        }

        synthesisService.speak(text: textToUse, language: selectedLanguage)
        errorMessage = nil
    }

    func speakRecognizedText() {
        guard !recognizedText.isEmpty else {
            errorMessage = "No recognized text to speak"
            return
        }
        synthesisService.speak(text: recognizedText, language: selectedLanguage)
    }

    func pauseSpeech() {
        synthesisService.pause()
    }

    func resumeSpeech() {
        synthesisService.resume()
    }

    func stopSpeech() {
        synthesisService.stop()
    }

    func setLanguage(_ language: SupportedLanguage) {
        selectedLanguage = language
        languageProvider.setLanguage(language)
        recognitionService.setupRecognizer(for: language)
    }

    func clearRecognizedText() {
        recognizedText = ""
    }

    func clearTextToSpeak() {
        textToSpeak = ""
    }

    func setSpeechRate(_ rate: Float) {
        synthesisService.setSpeechRate(rate)
    }

    func setSpeechPitch(_ pitch: Float) {
        synthesisService.setSpeechPitch(pitch)
    }

    func setSpeechVolume(_ volume: Float) {
        synthesisService.setSpeechVolume(volume)
    }
}
