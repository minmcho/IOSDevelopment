import Foundation

struct User: Identifiable, Codable {
    let id: String
    let email: String
    let name: String
    let provider: AuthProvider
    var profileImageURL: String?

    enum AuthProvider: String, Codable {
        case email = "email"
        case gmail = "gmail"
        case hotmail = "hotmail"
        case outlook = "outlook"

        var displayName: String {
            switch self {
            case .email:
                return "Email"
            case .gmail:
                return "Gmail"
            case .hotmail, .outlook:
                return "Hotmail/Outlook"
            }
        }
    }
}
