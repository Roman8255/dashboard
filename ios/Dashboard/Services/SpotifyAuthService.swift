import AuthenticationServices
import CryptoKit
import Foundation
import UIKit

@MainActor
final class SpotifyAuthService: NSObject, ObservableObject {
  static let shared = SpotifyAuthService()

  @Published private(set) var isAuthorized = false
  @Published private(set) var errorMessage: String?

  private var authSession: ASWebAuthenticationSession?
  private var codeVerifier: String?

  private enum KeychainKey {
    static let accessToken = "spotify_access_token"
    static let refreshToken = "spotify_refresh_token"
    static let expiresAt = "spotify_expires_at"
  }

  private override init() {
    super.init()
    isAuthorized = loadAccessToken() != nil
  }

  func startLogin() {
    guard SpotifyConfig.isConfigured else {
      errorMessage = "Nastavte Spotify Client ID v SpotifyConfig.swift"
      return
    }

    errorMessage = nil
    let verifier = Self.makeCodeVerifier()
    codeVerifier = verifier
    let challenge = Self.makeChallenge(from: verifier)

    var components = URLComponents(string: "https://accounts.spotify.com/authorize")!
    components.queryItems = [
      URLQueryItem(name: "client_id", value: SpotifyConfig.clientID),
      URLQueryItem(name: "response_type", value: "code"),
      URLQueryItem(name: "redirect_uri", value: SpotifyConfig.redirectURI),
      URLQueryItem(name: "code_challenge_method", value: "S256"),
      URLQueryItem(name: "code_challenge", value: challenge),
      URLQueryItem(name: "scope", value: SpotifyConfig.scopes),
    ]

    guard let url = components.url else { return }

    authSession = ASWebAuthenticationSession(
      url: url,
      callbackURLScheme: SpotifyConfig.callbackScheme
    ) { [weak self] callbackURL, error in
      Task { @MainActor in
        if let error, (error as NSError).code != ASWebAuthenticationSessionError.canceledLogin.rawValue {
          self?.errorMessage = error.localizedDescription
        }
        if let callbackURL {
          await self?.handleCallback(url: callbackURL)
        }
      }
    }
    authSession?.presentationContextProvider = self
    authSession?.prefersEphemeralWebBrowserSession = false
    authSession?.start()
  }

  func handleCallback(url: URL) async {
    guard let verifier = codeVerifier else { return }
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
          let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
      errorMessage = "Spotify prihlásenie zlyhalo"
      return
    }

    do {
      try await exchangeCode(code, verifier: verifier)
      isAuthorized = true
      errorMessage = nil
      await SpotifyService.shared.refreshPlayback()
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func validAccessToken() async throws -> String {
    if let token = loadAccessToken(), !isExpired() {
      return token
    }
    return try await refreshAccessToken()
  }

  func signOut() {
    KeychainHelper.delete(for: KeychainKey.accessToken)
    KeychainHelper.delete(for: KeychainKey.refreshToken)
    KeychainHelper.delete(for: KeychainKey.expiresAt)
    isAuthorized = false
    SpotifyService.shared.clearPlayback()
  }

  private func exchangeCode(_ code: String, verifier: String) async throws {
    let body = [
      "grant_type": "authorization_code",
      "code": code,
      "redirect_uri": SpotifyConfig.redirectURI,
      "client_id": SpotifyConfig.clientID,
      "code_verifier": verifier,
    ]
    let response: TokenResponse = try await postForm(
      url: URL(string: "https://accounts.spotify.com/api/token")!,
      body: body
    )
    saveTokens(response)
  }

  private func refreshAccessToken() async throws -> String {
    guard let refreshToken = KeychainHelper.load(for: KeychainKey.refreshToken) else {
      isAuthorized = false
      throw SpotifyAPIError.notAuthorized
    }

    let body = [
      "grant_type": "refresh_token",
      "refresh_token": refreshToken,
      "client_id": SpotifyConfig.clientID,
    ]
    let response: TokenResponse = try await postForm(
      url: URL(string: "https://accounts.spotify.com/api/token")!,
      body: body
    )
    saveTokens(response, keepRefreshToken: refreshToken)
    isAuthorized = true
    guard let token = loadAccessToken() else {
      throw SpotifyAPIError.notAuthorized
    }
    return token
  }

  private func saveTokens(_ response: TokenResponse, keepRefreshToken: String? = nil) {
    KeychainHelper.save(response.access_token, for: KeychainKey.accessToken)
    if let refresh = response.refresh_token ?? keepRefreshToken {
      KeychainHelper.save(refresh, for: KeychainKey.refreshToken)
    }
    let expiresAt = Date().addingTimeInterval(TimeInterval(response.expires_in))
    KeychainHelper.save(String(expiresAt.timeIntervalSince1970), for: KeychainKey.expiresAt)
  }

  private func loadAccessToken() -> String? {
    KeychainHelper.load(for: KeychainKey.accessToken)
  }

  private func isExpired() -> Bool {
    guard let raw = KeychainHelper.load(for: KeychainKey.expiresAt),
          let interval = TimeInterval(raw) else {
      return true
    }
    return Date().timeIntervalSince1970 >= interval - 60
  }

  private func postForm<T: Decodable>(url: URL, body: [String: String]) async throws -> T {
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    request.httpBody = body
      .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }
      .joined(separator: "&")
      .data(using: .utf8)

    let (data, response) = try await URLSession.shared.data(for: request)
    guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
      throw SpotifyAPIError.requestFailed
    }
    return try JSONDecoder().decode(T.self, from: data)
  }

  private static func makeCodeVerifier() -> String {
    var bytes = [UInt8](repeating: 0, count: 32)
    _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
    return Data(bytes)
      .base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
  }

  private static func makeChallenge(from verifier: String) -> String {
    let hash = SHA256.hash(data: Data(verifier.utf8))
    return Data(hash)
      .base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
  }

  private struct TokenResponse: Decodable {
    let access_token: String
    let token_type: String
    let expires_in: Int
    let refresh_token: String?
    let scope: String?
  }
}

extension SpotifyAuthService: ASWebAuthenticationPresentationContextProviding {
  nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    let scene = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first { $0.activationState == .foregroundActive }
    return scene?.keyWindow ?? ASPresentationAnchor()
  }
}

enum SpotifyAPIError: LocalizedError {
  case notAuthorized
  case requestFailed
  case noActiveDevice

  var errorDescription: String? {
    switch self {
    case .notAuthorized: return "Nie ste prihlásený do Spotify"
    case .requestFailed: return "Spotify požiadavka zlyhala"
    case .noActiveDevice: return "Spustite Spotify na tomto zariadení"
    }
  }
}
