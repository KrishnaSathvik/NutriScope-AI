import Foundation
import SwiftData

@Model
final class WeightLog {
    @Attribute(.unique) var id: UUID
    var weightKg: Double
    var loggedAt: Date
    var note: String

    init(weightKg: Double, loggedAt: Date = .now, note: String = "") {
        id = UUID()
        self.weightKg = weightKg
        self.loggedAt = loggedAt
        self.note = note
    }
}
