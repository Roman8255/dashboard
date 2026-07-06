import SwiftUI

struct ProfileTabView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject private var spotifyAuth = SpotifyAuthService.shared
    @State private var showSignOutConfirm = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                profileSection
                spotifySection
                appInfoSection
            }
            .padding()
        }
        .confirmationDialog("Odhlásiť sa?", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
            Button("Odhlásiť sa", role: .destructive) {
                appState.signOut()
            }
            Button("Zrušiť", role: .cancel) {}
        }
    }

    private var profileSection: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.accentColor.opacity(0.8), Color.accentColor.opacity(0.35)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)
                Image(systemName: "person.fill")
                    .font(.title)
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(appState.currentUser?.displayName ?? "Používateľ")
                    .font(.title2.bold())
                if let email = appState.currentUser?.email {
                    Text(email)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text("Apple ID · Cloud sync")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
        }
        .padding()
        .glassCard()
    }

    private var spotifySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Spotify", systemImage: "music.note")
                .font(.headline)

            HStack {
                Text(spotifyAuth.isAuthorized ? "Pripojené" : "Nepripojené")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            if spotifyAuth.isAuthorized {
                Button("Odpojiť Spotify", role: .destructive) {
                    spotifyAuth.signOut()
                }
                .font(.caption.bold())
            } else {
                Button {
                    spotifyAuth.startLogin()
                } label: {
                    Text("Pripojiť Spotify")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(!SpotifyConfig.isConfigured)
            }
        }
        .padding()
        .glassCard(cornerRadius: 16)
    }

    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Aplikácia", systemImage: "info.circle")
                .font(.headline)

            settingsRow(title: "Verzia", value: "2.0.0")
            settingsRow(title: "Nastavenia na home", value: "Podržte obrazovku")

            Button(role: .destructive) {
                showSignOutConfirm = true
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Odhlásiť sa")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .glassCard(cornerRadius: 16)
            }
            .buttonStyle(.plain)
        }
    }

    private func settingsRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
                .font(.subheadline)
        }
        .padding()
        .glassCard(cornerRadius: 16)
    }
}
