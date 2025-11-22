import Foundation

enum SupportedLanguage: String, CaseIterable, Identifiable {
    case myanmar = "Myanmar"
    case english = "English"
    case thai = "Thai"
    case korean = "Korean"
    case japanese = "Japanese"
    case german = "German"
    case chinese = "Chinese"

    var id: String { rawValue }

    var code: String {
        switch self {
        case .myanmar: return "my-MM"
        case .english: return "en-US"
        case .thai: return "th-TH"
        case .korean: return "ko-KR"
        case .japanese: return "ja-JP"
        case .german: return "de-DE"
        case .chinese: return "zh-CN"
        }
    }

    var locale: Locale {
        Locale(identifier: code)
    }

    var voiceIdentifier: String {
        switch self {
        case .myanmar: return "com.apple.ttsbundle.Siri_female_my-MM_compact"
        case .english: return "com.apple.ttsbundle.Samantha-compact"
        case .thai: return "com.apple.ttsbundle.Kanya-compact"
        case .korean: return "com.apple.ttsbundle.Yuna-compact"
        case .japanese: return "com.apple.ttsbundle.Kyoko-compact"
        case .german: return "com.apple.ttsbundle.Anna-compact"
        case .chinese: return "com.apple.ttsbundle.Ting-Ting-compact"
        }
    }

    var flag: String {
        switch self {
        case .myanmar: return "🇲🇲"
        case .english: return "🇺🇸"
        case .thai: return "🇹🇭"
        case .korean: return "🇰🇷"
        case .japanese: return "🇯🇵"
        case .german: return "🇩🇪"
        case .chinese: return "🇨🇳"
        }
    }

    var displayName: String {
        "\(flag) \(rawValue)"
    }
}

class LanguageProvider: ObservableObject {
    @Published var selectedLanguage: SupportedLanguage = .english

    static let shared = LanguageProvider()

    private init() {}

    func setLanguage(_ language: SupportedLanguage) {
        selectedLanguage = language
    }

    var allLanguages: [SupportedLanguage] {
        SupportedLanguage.allCases
    }
}
