import Foundation

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    @Published var isAuthenticated = false
    @Published var isRestoringSession = true
    @Published var currentUser: LocalUser?
    @Published var errorMessage: String?

    private init() {}

    func restoreSession() async {
        isRestoringSession = true
        defer { isRestoringSession = false }

        guard let appleUserId = KeychainHelper.load(for: AuthKeys.appleUserId) else {
            isAuthenticated = false
            return
        }

        let isValid = await AuthService.shared.checkCredentialState(for: appleUserId)
        guard isValid else {
            signOut()
            return
        }

        let displayName = KeychainHelper.load(for: AuthKeys.displayName) ?? "Používateľ"

        do {
            let user = try await BackendAuthService.shared.restoreBackendSession(
                displayName: displayName,
                appleUserId: appleUserId
            )
            currentUser = user
            isAuthenticated = true
            errorMessage = nil
            await DashboardStore.shared.load(for: user)
            WidgetPreferencesStore.shared.load(for: user)
        } catch {
            signOut()
        }
    }

    func setAuthenticated(user: LocalUser) async {
        currentUser = user
        isAuthenticated = true
        errorMessage = nil
        await DashboardStore.shared.load(for: user)
        WidgetPreferencesStore.shared.load(for: user)
    }

    func signOut() {
        BackendAuthService.shared.clearSession()
        KeychainHelper.clearSession()
        currentUser = nil
        isAuthenticated = false
        errorMessage = nil
        DashboardStore.shared.reset()
        WidgetPreferencesStore.shared.reset()
    }
}
