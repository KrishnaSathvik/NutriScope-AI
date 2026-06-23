import AuthenticationServices
import CryptoKit
import SwiftData
import SwiftUI
import UIKit

struct SignInWithAppleButton: View {
    var onSuccess: () -> Void
    var onError: (String) -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var coordinator = SignInWithAppleCoordinator()

    var body: some View {
        SignInWithAppleButtonView(
            onRequest: { request in
                coordinator.configure(request: request)
            },
            onCompletion: { result in
                Task {
                    await handle(result)
                }
            }
        )
        .signInWithAppleButtonStyle(.black)
        .frame(height: 50)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func handle(_ result: Result<ASAuthorization, Error>) async {
        do {
            let credential = try coordinator.credential(from: result)
            _ = try await SupabaseAuthClient.signInWithApple(
                identityToken: credential.identityToken,
                nonce: credential.nonce
            )

            let email = credential.email ?? SupabaseAuthClient.currentSession?.email ?? "apple@privaterelay.appleid.com"
            let displayName = credential.displayName.isEmpty ? "Apple User" : credential.displayName

            AuthSessionManager.applyAppleSignIn(email: email, displayName: displayName)

            let settings = try? modelContext.fetch(FetchDescriptor<UserSettings>()).first
            await IOSUserProfileSyncService.upsertAfterAuthentication(settings: settings)

            onSuccess()
        } catch {
            onError((error as? LocalizedError)?.errorDescription ?? error.localizedDescription)
        }
    }
}

private struct SignInWithAppleButtonView: UIViewRepresentable {
    var onRequest: (ASAuthorizationAppleIDRequest) -> Void
    var onCompletion: (Result<ASAuthorization, Error>) -> Void

    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let button = ASAuthorizationAppleIDButton(type: .signIn, style: .black)
        button.addTarget(context.coordinator, action: #selector(Coordinator.tapped), for: .touchUpInside)
        return button
    }

    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onRequest: onRequest, onCompletion: onCompletion)
    }

    final class Coordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
        let onRequest: (ASAuthorizationAppleIDRequest) -> Void
        let onCompletion: (Result<ASAuthorization, Error>) -> Void
        private var controller: ASAuthorizationController?

        init(
            onRequest: @escaping (ASAuthorizationAppleIDRequest) -> Void,
            onCompletion: @escaping (Result<ASAuthorization, Error>) -> Void
        ) {
            self.onRequest = onRequest
            self.onCompletion = onCompletion
        }

        @objc func tapped() {
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            onRequest(request)
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            self.controller = controller
            controller.performRequests()
        }

        func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
            onCompletion(.success(authorization))
        }

        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            onCompletion(.failure(error))
        }

        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = scene.windows.first
            else {
                return ASPresentationAnchor()
            }
            return window
        }
    }
}

@Observable
final class SignInWithAppleCoordinator {
    private var currentNonce: String?

    func configure(request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonce()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    struct AppleCredential {
        let identityToken: String
        let nonce: String
        let email: String?
        let displayName: String
    }

    func credential(from result: Result<ASAuthorization, Error>) throws -> AppleCredential {
        switch result {
        case .failure(let error):
            throw error
        case .success(let authorization):
            guard
                let appleID = authorization.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = appleID.identityToken,
                let identityToken = String(data: tokenData, encoding: .utf8),
                let nonce = currentNonce
            else {
                throw SupabaseAuthError.invalidResponse
            }

            let name = [appleID.fullName?.givenName, appleID.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")

            return AppleCredential(
                identityToken: identityToken,
                nonce: nonce,
                email: appleID.email,
                displayName: name
            )
        }
    }

    private func randomNonce(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in UInt8.random(in: 0...255) }
            for random in randoms where remaining > 0 {
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remaining -= 1
                }
            }
        }
        return result
    }

    private func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
