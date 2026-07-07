import SwiftUI

struct MainView: View {
    @EnvironmentObject var appState: AppState
    @State private var showSettings = false

    var body: some View {
        DashboardView {
            HapticHelper.mediumImpact()
            showSettings = true
        }
        .fullScreenCover(isPresented: $showSettings) {
            SettingsShellView()
                .environmentObject(appState)
        }
    }
}

#Preview {
    MainView()
        .environmentObject(AppState.shared)
}
