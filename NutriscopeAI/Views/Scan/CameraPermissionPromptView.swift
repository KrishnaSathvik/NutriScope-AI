import AVFoundation
import SwiftUI

struct CameraPermissionPromptView: View {
    var onAllow: () -> Void
    var onSkip: () -> Void

    var body: some View {
        IOSNativePermissionScreen(
            icon: "camera.viewfinder",
            title: "Enable Camera for\nAI Scanning",
            message: "Scan your meals in seconds to track protein and get instant coaching. We never store photos without your permission.",
            primaryTitle: "Allow Camera Access",
            secondaryTitle: "Maybe Later",
            onPrimary: onAllow,
            onSecondary: onSkip
        )
    }

    static func requestAccess() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            return false
        }
    }
}

#Preview {
    CameraPermissionPromptView(onAllow: {}, onSkip: {})
}
