import Foundation

enum AppConfig {
    #if DEBUG
    static let apiBaseURL = "http://127.0.0.1:9035"
    #else
    static let apiBaseURL = "https://romanbednarik.com"
    #endif

    /// Public API URL used in agent install commands on remote Linux servers.
    static let agentApiBaseURL = "https://romanbednarik.com"
    static let agentRepoURL = "https://raw.githubusercontent.com/Roman8255/dashboard-server-agent/main"

    static let maxDashboards = 5
}
