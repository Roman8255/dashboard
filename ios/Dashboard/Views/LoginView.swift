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
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 96, height: 96)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .shadow(color: .black.opacity(0.3), radius: 12, y: 6)

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
