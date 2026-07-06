import AuthenticationServices
import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var authService = AuthService.shared

    var body: some View {
        ZStack {
            DashboardTheme.background
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 12) {
                    Image(systemName: "square.grid.3x3.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(Color.accentColor)

                    Text("Dashboard")
                        .font(.largeTitle.bold())

                    Text("Tvoj personalizovaný domovský\npanel s widgetmi")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    Task {
                        await authService.handleAuthorization(result)
                    }
                }
                .signInWithAppleButtonStyle(.white)
                .frame(height: 50)
                .padding(.horizontal, 40)

                if authService.isLoading {
                    ProgressView()
                }

                if let error = authService.errorMessage ?? appState.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()
                    .frame(height: 40)
            }
            .padding()
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AppState.shared)
}
