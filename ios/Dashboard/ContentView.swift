import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if appState.isRestoringSession {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Načítavam…")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if appState.isAuthenticated {
                MainView()
            } else {
                LoginView()
            }
        }
        .task {
            await appState.restoreSession()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState.shared)
}
