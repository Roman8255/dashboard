import Foundation
import MediaPlayer
import UIKit

struct SpotifyPlayback: Equatable {
  let title: String
  let artist: String
  let artwork: UIImage?
  let positionMs: Int
  let durationMs: Int
  let isPlaying: Bool

  var positionSeconds: Double { Double(positionMs) / 1000 }
  var durationSeconds: Double { max(Double(durationMs) / 1000, 1) }
}

@MainActor
final class SpotifyService: ObservableObject {
  static let shared = SpotifyService()

  @Published private(set) var playback: SpotifyPlayback?
  @Published private(set) var isAuthorized = false
  @Published private(set) var isLoading = false
  @Published private(set) var statusMessage: String?

  private var pollTimer: Timer?
  private var progressTimer: Timer?
  private var lastSyncDate = Date()
  private var lastKnownPositionMs = 0
  private var lastKnownIsPlaying = false
  private var hasLoadedOnce = false

  private init() {
    isAuthorized = SpotifyAuthService.shared.isAuthorized
    startTimers()
  }

  func clearPlayback() {
    playback = nil
    statusMessage = nil
  }

  func connectIfNeeded() {
    isAuthorized = SpotifyAuthService.shared.isAuthorized
    if isAuthorized {
      Task { await refreshPlayback() }
    }
  }

  func refreshPlayback(showLoading: Bool = false) async {
    isAuthorized = SpotifyAuthService.shared.isAuthorized
    guard SpotifyAuthService.shared.isAuthorized else {
      refreshFromSystemNowPlaying()
      hasLoadedOnce = true
      return
    }

    if showLoading && !hasLoadedOnce {
      isLoading = true
    }

    defer {
      isLoading = false
      hasLoadedOnce = true
    }

    do {
      let token = try await SpotifyAuthService.shared.validAccessToken()
      if let apiPlayback = try await SpotifyAPIService.fetchCurrentPlayback(token: token) {
        lastKnownPositionMs = apiPlayback.positionMs
        lastKnownIsPlaying = apiPlayback.isPlaying
        lastSyncDate = Date()
        playback = apiPlayback
        statusMessage = nil
        return
      }

      // API says nothing is playing — stay idle, don't fall back to stale system info.
      playback = nil
      lastKnownIsPlaying = false
      statusMessage = nil
      return
    } catch {
      statusMessage = error.localizedDescription
    }

    refreshFromSystemNowPlaying()
  }

  func togglePlayPause() async {
    guard let playback else { return }
    if playback.isPlaying {
      await pause()
    } else {
      await resume()
    }
  }

  func pause() async {
    await sendPlayerCommand(path: "pause")
  }

  func resume() async {
    await sendPlayerCommand(path: "play")
  }

  func skipNext() async {
    await sendPlayerCommand(path: "next", method: "POST")
  }

  func skipPrevious() async {
    await sendPlayerCommand(path: "previous", method: "POST")
  }

  func seek(to positionMs: Int) async {
    guard SpotifyAuthService.shared.isAuthorized else { return }
    do {
      let token = try await SpotifyAuthService.shared.validAccessToken()
      try await SpotifyAPIService.seek(token: token, positionMs: positionMs)
      lastKnownPositionMs = positionMs
      lastSyncDate = Date()
      if let current = playback {
        playback = SpotifyPlayback(
          title: current.title,
          artist: current.artist,
          artwork: current.artwork,
          positionMs: positionMs,
          durationMs: current.durationMs,
          isPlaying: current.isPlaying
        )
      }
      await refreshPlayback()
    } catch {
      statusMessage = error.localizedDescription
    }
  }

  func openSpotifyApp() {
    if let url = URL(string: "spotify://"), UIApplication.shared.canOpenURL(url) {
      UIApplication.shared.open(url)
    } else if let web = URL(string: "https://open.spotify.com") {
      UIApplication.shared.open(web)
    }
  }

  private func sendPlayerCommand(path: String, method: String = "PUT") async {
    guard SpotifyAuthService.shared.isAuthorized else {
      SpotifyAuthService.shared.startLogin()
      return
    }
    do {
      let token = try await SpotifyAuthService.shared.validAccessToken()
      try await SpotifyAPIService.playerCommand(token: token, path: path, method: method)
      HapticHelper.lightImpact()
      try? await Task.sleep(nanoseconds: 250_000_000)
      await refreshPlayback()
    } catch {
      statusMessage = error.localizedDescription
      HapticHelper.warning()
    }
  }

  private func refreshFromSystemNowPlaying() {
    let center = MPNowPlayingInfoCenter.default()
    guard let info = center.nowPlayingInfo else {
      playback = nil
      lastKnownIsPlaying = false
      return
    }

    let title = (info[MPMediaItemPropertyTitle] as? String) ?? "Neznáma skladba"
    let artist = (info[MPMediaItemPropertyArtist] as? String) ?? "Neznámy interpret"
    let artwork = (info[MPMediaItemPropertyArtwork] as? MPMediaItemArtwork)?
      .image(at: CGSize(width: 300, height: 300))
    let duration = (info[MPMediaItemPropertyPlaybackDuration] as? Double) ?? 0
    let elapsed = (info[MPNowPlayingInfoPropertyElapsedPlaybackTime] as? Double) ?? 0
    let rate = (info[MPNowPlayingInfoPropertyPlaybackRate] as? Double) ?? 0

    lastKnownPositionMs = Int(elapsed * 1000)
    lastKnownIsPlaying = rate > 0
    lastSyncDate = Date()

    playback = SpotifyPlayback(
      title: title,
      artist: artist,
      artwork: artwork,
      positionMs: lastKnownPositionMs,
      durationMs: Int(duration * 1000),
      isPlaying: lastKnownIsPlaying
    )
  }

  private func startTimers() {
    pollTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
      Task { @MainActor in
        await self?.refreshPlayback()
      }
    }

    progressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
      Task { @MainActor in
        self?.tickProgress()
      }
    }
  }

  private func tickProgress() {
    guard lastKnownIsPlaying, var current = playback else { return }
    let elapsed = Date().timeIntervalSince(lastSyncDate)
    let projected = lastKnownPositionMs + Int(elapsed * 1000)
    let capped = min(projected, current.durationMs)
    guard capped != current.positionMs else { return }

    current = SpotifyPlayback(
      title: current.title,
      artist: current.artist,
      artwork: current.artwork,
      positionMs: capped,
      durationMs: current.durationMs,
      isPlaying: current.isPlaying
    )
    playback = current
  }
}
