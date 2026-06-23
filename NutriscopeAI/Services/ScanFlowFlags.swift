import Foundation

enum ScanFlowFlags {
    private static let tutorialKey = "hasSeenFirstScanTutorial"
    private static let cameraPromptKey = "hasSeenCameraPrompt"
    private static let microphonePromptKey = "hasSeenMicrophonePrompt"

    static var hasSeenFirstScanTutorial: Bool {
        get { UserDefaults.standard.bool(forKey: tutorialKey) }
        set { UserDefaults.standard.set(newValue, forKey: tutorialKey) }
    }

    static var hasSeenCameraPrompt: Bool {
        get { UserDefaults.standard.bool(forKey: cameraPromptKey) }
        set { UserDefaults.standard.set(newValue, forKey: cameraPromptKey) }
    }

    static var hasSeenMicrophonePrompt: Bool {
        get { UserDefaults.standard.bool(forKey: microphonePromptKey) }
        set { UserDefaults.standard.set(newValue, forKey: microphonePromptKey) }
    }
}
