import Foundation

enum SpotifyConfig {
  /// Vytvor app na https://developer.spotify.com/dashboard
  /// Redirect URI: dashboard://spotify-callback
  static let clientID = "4e3b7c90759c44f79c08865af873cbc1"
  static let redirectURI = "dashboard://spotify-callback"
  static let callbackScheme = "dashboard"

  static let scopes = [
    "user-read-playback-state",
    "user-modify-playback-state",
    "user-read-currently-playing",
  ].joined(separator: " ")

  static var isConfigured: Bool {
    !clientID.isEmpty && clientID != "YOUR_SPOTIFY_CLIENT_ID"
  }
}
