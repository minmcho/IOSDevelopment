import SwiftUI
import Speech

struct SpeechView: View {
    @StateObject private var viewModel = SpeechViewModel()
    @State private var showingSettings = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    languageSelector

                    textToSpeechSection

                    speechToTextSection

                    if let errorMessage = viewModel.errorMessage {
                        errorView(message: errorMessage)
                    }
                }
                .padding()
            }
            .navigationTitle("Multilingual Speech")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings.toggle() }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SpeechSettingsView(viewModel: viewModel)
            }
            .task {
                await viewModel.requestSpeechAuthorization()
            }
        }
    }

    private var languageSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Language")
                .font(.headline)

            Picker("Language", selection: $viewModel.selectedLanguage) {
                ForEach(SupportedLanguage.allCases) { language in
                    Text(language.displayName)
                        .tag(language)
                }
            }
            .pickerStyle(.menu)
            .onChange(of: viewModel.selectedLanguage) { newLanguage in
                viewModel.setLanguage(newLanguage)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var textToSpeechSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Text to Speech")
                .font(.title2)
                .fontWeight(.bold)

            VStack(spacing: 12) {
                TextField("Enter text to speak", text: $viewModel.textToSpeak, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(5...10)

                HStack(spacing: 12) {
                    Button(action: { viewModel.speak() }) {
                        Label("Speak", systemImage: "speaker.wave.2.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.textToSpeak.isEmpty || viewModel.isSpeaking)

                    if viewModel.isSpeaking {
                        if viewModel.synthesisService.isPaused {
                            Button(action: { viewModel.resumeSpeech() }) {
                                Label("Resume", systemImage: "play.fill")
                            }
                            .buttonStyle(.bordered)
                        } else {
                            Button(action: { viewModel.pauseSpeech() }) {
                                Label("Pause", systemImage: "pause.fill")
                            }
                            .buttonStyle(.bordered)
                        }

                        Button(action: { viewModel.stopSpeech() }) {
                            Label("Stop", systemImage: "stop.fill")
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }
                }

                if !viewModel.textToSpeak.isEmpty {
                    Button(action: { viewModel.clearTextToSpeak() }) {
                        Label("Clear", systemImage: "trash")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    private var speechToTextSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Speech to Text")
                .font(.title2)
                .fontWeight(.bold)

            VStack(spacing: 12) {
                recordingButton

                if !viewModel.recognizedText.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Recognized Text:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Spacer()

                            Button(action: { viewModel.clearRecognizedText() }) {
                                Label("Clear", systemImage: "trash")
                                    .font(.caption)
                            }
                            .buttonStyle(.borderless)
                            .foregroundColor(.red)
                        }

                        Text(viewModel.recognizedText)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)

                        Button(action: { viewModel.speakRecognizedText() }) {
                            Label("Speak Recognized Text", systemImage: "speaker.wave.2.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(viewModel.isSpeaking)
                    }
                }

                if viewModel.speechAuthorizationStatus != .authorized {
                    authorizationWarning
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    private var recordingButton: some View {
        Button(action: { viewModel.toggleRecording() }) {
            HStack {
                Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "mic.fill")
                    .font(.title2)
                Text(viewModel.isRecording ? "Stop Recording" : "Start Recording")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.isRecording ? Color.red : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(viewModel.speechAuthorizationStatus != .authorized)
    }

    private var authorizationWarning: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title)
                .foregroundColor(.orange)

            Text("Speech recognition permission required")
                .font(.subheadline)
                .multilineTextAlignment(.center)

            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }

    private func errorView(message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.red)
            Text(message)
                .font(.subheadline)
            Spacer()
            Button(action: { viewModel.errorMessage = nil }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }
}

struct SpeechSettingsView: View {
    @ObservedObject var viewModel: SpeechViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("Speech Rate") {
                    HStack {
                        Image(systemName: "tortoise.fill")
                        Slider(
                            value: Binding(
                                get: { viewModel.synthesisService.speechRate },
                                set: { viewModel.setSpeechRate($0) }
                            ),
                            in: 0.0...1.0
                        )
                        Image(systemName: "hare.fill")
                    }
                }

                Section("Speech Pitch") {
                    HStack {
                        Image(systemName: "arrow.down")
                        Slider(
                            value: Binding(
                                get: { viewModel.synthesisService.speechPitch },
                                set: { viewModel.setSpeechPitch($0) }
                            ),
                            in: 0.5...2.0
                        )
                        Image(systemName: "arrow.up")
                    }
                }

                Section("Speech Volume") {
                    HStack {
                        Image(systemName: "speaker.fill")
                        Slider(
                            value: Binding(
                                get: { viewModel.synthesisService.speechVolume },
                                set: { viewModel.setSpeechVolume($0) }
                            ),
                            in: 0.0...1.0
                        )
                        Image(systemName: "speaker.wave.3.fill")
                    }
                }

                Section("Supported Languages") {
                    ForEach(SupportedLanguage.allCases) { language in
                        HStack {
                            Text(language.displayName)
                            Spacer()
                            Text(language.code)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Speech Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SpeechView()
}
