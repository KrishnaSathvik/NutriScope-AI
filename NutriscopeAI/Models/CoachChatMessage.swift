import Foundation

enum CoachChatRole: String, Codable {
    case coach
    case user
    case suggestion
}

struct CoachChatMessage: Identifiable, Equatable {
    let id: UUID
    let role: CoachChatRole
    let text: String
    var suggestionProtein: Int?
    let sentAt: Date

    init(
        id: UUID = UUID(),
        role: CoachChatRole,
        text: String,
        suggestionProtein: Int? = nil,
        sentAt: Date = .now
    ) {
        self.id = id
        self.role = role
        self.text = text
        self.suggestionProtein = suggestionProtein
        self.sentAt = sentAt
    }
}
