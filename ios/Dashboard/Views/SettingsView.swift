import SwiftUI

/// Legacy entry point — settings UI lives in `SettingsShellView` / `SettingsTabView`.
struct SettingsView: View {
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            SettingsTabView(navigationPath: $navigationPath)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState.shared)
}
