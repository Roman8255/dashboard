import Foundation

enum AppConfig {
    #if DEBUG
    static let apiBaseURL = "http://127.0.0.1:9035"
    #else
    static let apiBaseURL = "https://romanbednarik.sk"
    #endif

    static let maxDashboards = 5
}
