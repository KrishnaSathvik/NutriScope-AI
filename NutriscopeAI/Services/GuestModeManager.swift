import Foundation

enum GuestModeManager {
    private static let key = "isGuestMode"

    static var isGuest: Bool {
        get { UserDefaults.standard.bool(forKey: key) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }
}
