# Multilingual Speech Setup Guide

This project includes comprehensive multilingual speech-to-text and text-to-speech support for 7 languages:

- 🇲🇲 Myanmar (Burmese)
- 🇺🇸 English
- 🇹🇭 Thai
- 🇰🇷 Korean
- 🇯🇵 Japanese
- 🇩🇪 German
- 🇨🇳 Chinese

## Required Permissions

To use the speech features, you need to add the following permissions to your Xcode project's `Info.plist`:

### 1. Microphone Usage (for Speech-to-Text)
```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs access to your microphone to convert speech to text in multiple languages.</string>
```

### 2. Speech Recognition Usage (for Speech-to-Text)
```xml
<key>NSSpeechRecognitionUsageDescription</key>
<string>This app uses speech recognition to convert your speech into text in Myanmar, English, Thai, Korean, Japanese, German, and Chinese.</string>
```

## Adding to Xcode Project

1. Open your project in Xcode
2. Select your app target
3. Go to the "Info" tab
4. Add the following custom keys:
   - `Privacy - Microphone Usage Description`
   - `Privacy - Speech Recognition Usage Description`
5. Provide appropriate descriptions for each

Or you can copy the contents of `Info.plist.example` into your project's Info.plist.

## Features

### Text-to-Speech (TTS)
- Convert text to speech in any of the 7 supported languages
- Adjustable speech rate, pitch, and volume
- Pause, resume, and stop controls
- Natural-sounding voices using Apple's AVSpeechSynthesizer

### Speech-to-Text (STT)
- Real-time speech recognition
- Support for all 7 languages
- Live transcription display
- Ability to speak the recognized text

### User Interface
- Language selector with flag emojis
- Clean, intuitive SwiftUI interface
- Settings panel for fine-tuning speech parameters
- Error handling and permission management

## Usage

1. Log in to the app
2. Tap the "Multilingual Speech" button on the home screen
3. Select your desired language from the dropdown
4. For Text-to-Speech:
   - Enter text in the text field
   - Tap "Speak" to hear it
   - Use Pause/Resume/Stop controls as needed
5. For Speech-to-Text:
   - Tap "Start Recording"
   - Speak in the selected language
   - Tap "Stop Recording" to finish
   - Optionally tap "Speak Recognized Text" to hear it back

## Technical Details

### Architecture
- **MVVM Pattern**: Clean separation of concerns
- **Combine Framework**: Reactive state management
- **SwiftUI**: Modern declarative UI
- **AVFoundation**: Text-to-speech synthesis
- **Speech Framework**: Speech recognition

### Files Added
```
Sources/
├── Services/
│   ├── LanguageProvider.swift           # Language configuration
│   ├── SpeechRecognitionService.swift   # Speech-to-text service
│   └── SpeechSynthesisService.swift     # Text-to-speech service
├── ViewModels/
│   └── SpeechViewModel.swift            # Speech state management
└── Views/
    └── SpeechView.swift                 # Speech UI components
```

## Requirements
- iOS 15.0+
- Xcode 14.0+
- Swift 5.7+
- Device with microphone (for speech-to-text)

## Notes
- Speech recognition requires an internet connection for some languages
- First-time users will be prompted for microphone and speech recognition permissions
- Text-to-speech works offline for all supported languages
- Myanmar language support may vary by iOS version and device
