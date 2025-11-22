import Foundation
import AVFoundation

@MainActor
class SpeechSynthesisService: NSObject, ObservableObject {
    @Published var isSpeaking = false
    @Published var isPaused = false
    @Published var speechRate: Float = 0.5
    @Published var speechPitch: Float = 1.0
    @Published var speechVolume: Float = 1.0

    private let synthesizer = AVSpeechSynthesizer()
    private var currentLanguage: SupportedLanguage = .english

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(text: String, language: SupportedLanguage) {
        if synthesizer.isSpeaking {
            stop()
        }

        currentLanguage = language
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = getVoice(for: language)
        utterance.rate = speechRate
        utterance.pitchMultiplier = speechPitch
        utterance.volume = speechVolume

        synthesizer.speak(utterance)
    }

    func pause() {
        synthesizer.pauseSpeaking(at: .word)
        isPaused = true
    }

    func resume() {
        synthesizer.continueSpeaking()
        isPaused = false
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        isPaused = false
    }

    private func getVoice(for language: SupportedLanguage) -> AVSpeechSynthesisVoice? {
        let languageCode = language.code
        let voices = AVSpeechSynthesisVoice.speechVoices()

        let voiceForLanguage = voices.first { voice in
            voice.language.hasPrefix(languageCode.prefix(2))
        }

        return voiceForLanguage ?? AVSpeechSynthesisVoice(language: languageCode)
    }

    func getAvailableVoices(for language: SupportedLanguage) -> [AVSpeechSynthesisVoice] {
        let languageCode = language.code
        return AVSpeechSynthesisVoice.speechVoices().filter { voice in
            voice.language.hasPrefix(languageCode.prefix(2))
        }
    }

    func setSpeechRate(_ rate: Float) {
        speechRate = min(max(rate, AVSpeechUtteranceMinimumSpeechRate), AVSpeechUtteranceMaximumSpeechRate)
    }

    func setSpeechPitch(_ pitch: Float) {
        speechPitch = min(max(pitch, 0.5), 2.0)
    }

    func setSpeechVolume(_ volume: Float) {
        speechVolume = min(max(volume, 0.0), 1.0)
    }
}

extension SpeechSynthesisService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = true
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.isPaused = false
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.isPaused = false
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isPaused = true
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isPaused = false
        }
    }
}
