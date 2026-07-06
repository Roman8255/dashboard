import SwiftUI

@main
struct DashboardApp: App {
    @StateObject private var appState = AppState.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onOpenURL { url in
                    Task {
                        await SpotifyAuthService.shared.handleCallback(url: url)
                    }
                }
                .task {
                    SpotifyService.shared.connectIfNeeded()
                    NetworkMonitorService.shared.startHourlyTimer()
                }
                .onChange(of: scenePhase) { _, phase in
                    switch phase {
                    case .active:
                        NetworkMonitorService.shared.startHourlyTimer()
                        Task { await NetworkMonitorService.shared.onForeground() }
                    case .background:
                        NetworkMonitorService.shared.stopHourlyTimer()
                    default:
                        break
                    }
                }
        }
    }
}
