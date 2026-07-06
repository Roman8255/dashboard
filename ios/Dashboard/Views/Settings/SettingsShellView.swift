import SwiftUI

enum SettingsTab: Hashable {
    case settings
    case profile
    case friends
}

struct SettingsShellView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: SettingsTab = .settings

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch selectedTab {
                case .settings:
                    SettingsTabView()
                case .profile:
                    ProfileTabView()
                case .friends:
                    FriendsTabView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider().opacity(0.25)

            HStack {
                tabButton(.settings, title: "Nastavenia", icon: "gearshape.fill")
                tabButton(.profile, title: "Profil", icon: "person.fill")
                tabButton(.friends, title: "Priatelia", icon: "person.2.fill")
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            .padding(.bottom, 12)
            .background(.ultraThinMaterial)
        }
        .dashboardBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func tabButton(_ tab: SettingsTab, title: String, icon: String) -> some View {
        Button {
            HapticHelper.lightImpact()
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.body)
                Text(title)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .foregroundStyle(selectedTab == tab ? Color.accentColor : .secondary)
        }
        .buttonStyle(.plain)
    }
}
