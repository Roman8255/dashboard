import SwiftUI

/// Legacy entry point — settings UI lives in `SettingsShellView` / `SettingsTabView`.
struct SettingsView: View {
    var body: some View {
        SettingsTabView()
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState.shared)
}
