import AVFoundation
import SwiftUI

struct CameraPermissionPromptView: View {
    var onAllow: () -> Void
    var onSkip: () -> Void

    var body: some View {
        KineticPermissionPromptView(
            icon: "camera.fill",
            title: "Enable Camera Access",
            message: "Nutriscope uses your camera to scan meals. Photos stay on your device unless you choose to export them.",
            primaryTitle: "Allow Camera",
            secondaryTitle: "Not now",
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
