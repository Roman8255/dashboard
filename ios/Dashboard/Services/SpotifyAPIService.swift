import Foundation
import UIKit

enum SpotifyAPIService {
  static func fetchCurrentPlayback(token: String) async throws -> SpotifyPlayback? {
    var request = URLRequest(url: URL(string: "https://api.spotify.com/v1/me/player")!)
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

    let (data, response) = try await URLSession.shared.data(for: request)
    guard let http = response as? HTTPURLResponse else { throw SpotifyAPIError.requestFailed }

    if http.statusCode == 204 { return nil }

    guard (200...299).contains(http.statusCode) else {
      if http.statusCode == 401 { throw SpotifyAPIError.notAuthorized }
      throw SpotifyAPIError.requestFailed
    }

    let decoded = try JSONDecoder().decode(PlayerResponse.self, from: data)
    guard let item = decoded.item else { return nil }

    let imageURL = item.album.images.first?.url
    let artwork = await loadImage(from: imageURL)

    return SpotifyPlayback(
      title: item.name,
      artist: item.artists.map(\.name).joined(separator: ", "),
      artwork: artwork,
      positionMs: decoded.progress_ms ?? 0,
      durationMs: item.duration_ms,
      isPlaying: decoded.is_playing
    )
  }

  static func playerCommand(token: String, path: String, method: String) async throws {
    var request = URLRequest(url: URL(string: "https://api.spotify.com/v1/me/player/\(path)")!)
    request.httpMethod = method
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

    let (_, response) = try await URLSession.shared.data(for: request)
    guard let http = response as? HTTPURLResponse else { throw SpotifyAPIError.requestFailed }

    if http.statusCode == 404 {
      throw SpotifyAPIError.noActiveDevice
    }
    guard (200...299).contains(http.statusCode) || http.statusCode == 204 else {
      throw SpotifyAPIError.requestFailed
    }
  }

  static func seek(token: String, positionMs: Int) async throws {
    var components = URLComponents(string: "https://api.spotify.com/v1/me/player/seek")!
    components.queryItems = [URLQueryItem(name: "position_ms", value: String(positionMs))]

    var request = URLRequest(url: components.url!)
    request.httpMethod = "PUT"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

    let (_, response) = try await URLSession.shared.data(for: request)
    guard let http = response as? HTTPURLResponse,
          (200...299).contains(http.statusCode) || http.statusCode == 204 else {
      throw SpotifyAPIError.requestFailed
    }
  }

  private static func loadImage(from url: URL?) async -> UIImage? {
    guard let url else { return nil }
    do {
      let (data, _) = try await URLSession.shared.data(from: url)
      return UIImage(data: data)
    } catch {
      return nil
    }
  }

  private struct PlayerResponse: Decodable {
    let is_playing: Bool
    let progress_ms: Int?
    let item: TrackItem?
  }

  private struct TrackItem: Decodable {
    let name: String
    let duration_ms: Int
    let artists: [Artist]
    let album: Album
  }

  private struct Artist: Decodable {
    let name: String
  }

  private struct Album: Decodable {
    let images: [ImageItem]
  }

  private struct ImageItem: Decodable {
    let url: URL
  }
}
