import Foundation

@MainActor
final class BackendAuthService {
    static let shared = BackendAuthService()

    private init() {}

    struct AuthResponse: Decodable {
        let accessToken: String
        let refreshToken: String
        let user: RemoteUser
    }

    struct RemoteUser: Decodable {
        let id: String
        let appleUserId: String
        let displayName: String
        let email: String?
    }

    func exchangeAppleToken(identityToken: String, displayName: String) async throws -> LocalUser {
        struct Body: Encodable {
            let identityToken: String
            let displayName: String
        }

        let response: AuthResponse = try await APIClient.shared.request(
            "/api/app/auth/apple",
            method: "POST",
            body: Body(identityToken: identityToken, displayName: displayName),
            authorized: false
        )

        persistTokens(access: response.accessToken, refresh: response.refreshToken)
        return LocalUser(
            appleUserId: response.user.appleUserId,
            displayName: response.user.displayName,
            serverUserId: response.user.id,
            email: response.user.email
        )
    }

    @discardableResult
    func refreshSession() async throws -> Bool {
        guard let refreshToken = KeychainHelper.load(for: AuthKeys.refreshToken) else {
            return false
        }

        struct Body: Encodable { let refreshToken: String }

        do {
            let response: AuthResponse = try await APIClient.shared.request(
                "/api/app/auth/refresh",
                method: "POST",
                body: Body(refreshToken: refreshToken),
                authorized: false
            )
            persistTokens(access: response.accessToken, refresh: response.refreshToken)
            return true
        } catch {
            return false
        }
    }

    func restoreBackendSession(displayName: String, appleUserId: String) async throws -> LocalUser {
        if KeychainHelper.load(for: AuthKeys.accessToken) != nil {
            struct MeResponse: Decodable { let user: RemoteUser }
            do {
                let me: MeResponse = try await APIClient.shared.request("/api/app/me")
                return LocalUser(
                    appleUserId: me.user.appleUserId,
                    displayName: me.user.displayName,
                    serverUserId: me.user.id,
                    email: me.user.email
                )
            } catch {
                let refreshed = try await refreshSession()
                if refreshed {
                    let me: MeResponse = try await APIClient.shared.request("/api/app/me")
                    return LocalUser(
                        appleUserId: me.user.appleUserId,
                        displayName: me.user.displayName,
                        serverUserId: me.user.id,
                        email: me.user.email
                    )
                }
            }
        }
        throw APIClientError.unauthorized
    }

    func clearSession() {
        KeychainHelper.delete(for: AuthKeys.accessToken)
        KeychainHelper.delete(for: AuthKeys.refreshToken)
        KeychainHelper.delete(for: AuthKeys.serverUserId)
    }

    private func persistTokens(access: String, refresh: String) {
        KeychainHelper.save(access, for: AuthKeys.accessToken)
        KeychainHelper.save(refresh, for: AuthKeys.refreshToken)
    }
}
