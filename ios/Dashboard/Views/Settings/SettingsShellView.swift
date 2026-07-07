import SwiftUI

enum SettingsTab: Hashable {
    case settings
    case profile
    case friends
}

struct SettingsShellView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: SettingsTab = .settings
    @State private var settingsPath = NavigationPath()

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack(path: $settingsPath) {
                SettingsTabView(navigationPath: $settingsPath)
                    .navigationTitle("Nastavenia")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Zavrieť") { dismiss() }
                        }
                    }
                    .navigationDestination(for: WidgetSettingsRoute.self) { route in
                        switch route {
                        case .server(let id):
                            ServerDetailView(serverId: id)
                        case .worldClock:
                            WorldClockSettingsView()
                        case .contacts:
                            ContactsWidgetSettingsView()
                        case .exchange:
                            ExchangeWidgetSettingsView()
                        }
                    }
            }
            .tabItem {
                Label("Nastavenia", systemImage: "gearshape.fill")
            }
            .tag(SettingsTab.settings)

            NavigationStack {
                ProfileTabView()
                    .navigationTitle("Profil")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Zavrieť") { dismiss() }
                        }
                    }
            }
            .tabItem {
                Label("Profil", systemImage: "person.fill")
            }
            .tag(SettingsTab.profile)

            NavigationStack {
                FriendsTabView()
                    .navigationTitle("Priatelia")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Zavrieť") { dismiss() }
                        }
                    }
            }
            .tabItem {
                Label("Priatelia", systemImage: "person.2.fill")
            }
            .tag(SettingsTab.friends)
        }
        .tint(Color.accentColor)
        .dashboardBackground()
    }
}
