import Foundation

enum ServerAgentCredentialStore {
    private static func key(for serverId: String) -> String {
        "server_agent_token_\(serverId)"
    }

    static func save(token: String, for serverId: String) {
        KeychainHelper.save(token, for: key(for: serverId))
    }

    static func load(for serverId: String) -> String? {
        KeychainHelper.load(for: key(for: serverId))
    }

    static func delete(for serverId: String) {
        KeychainHelper.delete(for: key(for: serverId))
    }
}

enum ServerAgentCommands {
    static func installCommand(token: String) -> String {
        "curl -fsSL \(AppConfig.agentRepoURL)/install.sh | sudo bash -s -- --token=\(token) --api=\(AppConfig.agentApiBaseURL)"
    }

    static func stopCommand(token: String) -> String {
        "curl -fsSL \(AppConfig.agentRepoURL)/uninstall.sh | sudo bash -s -- --token=\(token)"
    }
}
