import Foundation

enum AppTab: String, CaseIterable, Identifiable {
    case today
    case meals
    case scan
    case coach
    case profile

    var id: String { rawValue }

    /// Tabs rendered in the bottom navigation (scan uses a dedicated action).
    static var navigationTabs: [AppTab] {
        [.today, .meals, .scan, .coach, .profile]
    }

    var title: String {
        switch self {
        case .today: "Today"
        case .meals: "Meals"
        case .scan: "Scan"
        case .coach: "Coach"
        case .profile: "Profile"
        }
    }

    var systemImage: String {
        switch self {
        case .today: "calendar"
        case .meals: "fork.knife"
        case .scan: "camera.viewfinder"
        case .coach: "brain.head.profile"
        case .profile: "person"
        }
    }
}
