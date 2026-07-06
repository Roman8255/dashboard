import AuthenticationServices
import Foundation

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var isLoading = false
    @Published var errorMessage: String?

    private init() {}

    func handleAuthorization(_ result: Result<ASAuthorization, Error>) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = "Nepodarilo sa získať Apple prihlásenie"
                return
            }

            let appleUserId = credential.user
            let displayName: String = {
                if let name = credential.fullName {
                    let parts = [name.givenName, name.familyName].compactMap { $0 }
                    if !parts.isEmpty { return parts.joined(separator: " ") }
                }
                return KeychainHelper.load(for: AuthKeys.displayName) ?? "Používateľ"
            }()

            KeychainHelper.save(appleUserId, for: AuthKeys.appleUserId)
            KeychainHelper.save(displayName, for: AuthKeys.displayName)

            guard let tokenData = credential.identityToken,
                  let identityToken = String(data: tokenData, encoding: .utf8) else {
                errorMessage = "Chýba Apple identity token"
                return
            }

            do {
                let user = try await BackendAuthService.shared.exchangeAppleToken(
                    identityToken: identityToken,
                    displayName: displayName
                )
                if let serverUserId = user.serverUserId {
                    KeychainHelper.save(serverUserId, for: AuthKeys.serverUserId)
                }
                await AppState.shared.setAuthenticated(user: user)
            } catch {
                errorMessage = error.localizedDescription
            }

        case .failure(let error):
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                errorMessage = error.localizedDescription
            }
        }
    }

    func checkCredentialState(for userId: String) async -> Bool {
        await withCheckedContinuation { continuation in
            ASAuthorizationAppleIDProvider().getCredentialState(forUserID: userId) { state, _ in
                continuation.resume(returning: state == .authorized)
            }
        }
    }
}
