import SwiftUI

enum AppRoute: Hashable {
    case settings
}

struct MainView: View {
    @EnvironmentObject var appState: AppState
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            DashboardView {
                HapticHelper.mediumImpact()
                navigationPath.append(AppRoute.settings)
            }
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .settings:
                    SettingsShellView()
                        .environmentObject(appState)
                }
            }
        }
    }
}

#Preview {
    MainView()
        .environmentObject(AppState.shared)
}
