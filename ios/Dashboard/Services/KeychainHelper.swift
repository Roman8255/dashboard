import Foundation
import Security

enum KeychainHelper {
    private static let service = "sk.romanbednarik.dashboard"

    static func save(_ value: String, for key: String) {
        guard let data = value.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    static func load(for key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        return value
    }

    static func delete(for key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }

    static func clearSession() {
        delete(for: AuthKeys.appleUserId)
        delete(for: AuthKeys.displayName)
        delete(for: AuthKeys.accessToken)
        delete(for: AuthKeys.refreshToken)
        delete(for: AuthKeys.serverUserId)
    }
}

enum AuthKeys {
    static let appleUserId = "apple_user_id"
    static let displayName = "display_name"
    static let accessToken = "access_token"
    static let refreshToken = "refresh_token"
    static let serverUserId = "server_user_id"
}
