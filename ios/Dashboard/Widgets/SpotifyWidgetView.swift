import SwiftUI

struct SpotifyWidgetView: View {
  let styleId: String
  @ObservedObject private var spotify = SpotifyService.shared
  @ObservedObject private var auth = SpotifyAuthService.shared

  @State private var isScrubbing = false
  @State private var scrubValue: Double = 0

  var body: some View {
    WidgetCard {
      Group {
        if !auth.isAuthorized {
          connectView
        } else if let playback = spotify.playback {
          if styleId == "albumArt" {
            albumArtLayout(playback)
          } else {
            playerLayout(playback)
          }
        } else if spotify.isLoading {
          ProgressView()
            .tint(.green)
        } else {
          idleView
        }
      }
      .clipped()
    }
    .onAppear {
      spotify.connectIfNeeded()
      Task { await spotify.refreshPlayback(showLoading: true) }
    }
  }

  // MARK: - Layouts

  private func playerLayout(_ playback: SpotifyPlayback) -> some View {
    GeometryReader { geo in
      let compact = geo.size.width < 210

      VStack(spacing: compact ? 6 : 8) {
        if compact {
          VStack(spacing: 6) {
            artworkView(playback.artwork, size: min(geo.size.width - 20, 72))
            trackInfo(playback, centered: true)
            transportControls(playback, spacing: 18)
          }
        } else {
          HStack(alignment: .center, spacing: 10) {
            artworkView(playback.artwork, size: 56)
            VStack(alignment: .leading, spacing: 6) {
              trackInfo(playback, centered: false)
              transportControls(playback, spacing: 14)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
          }
        }

        scrubber(playback)
      }
      .padding(compact ? 8 : 10)
      .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
    }
  }

  private func trackInfo(_ playback: SpotifyPlayback, centered: Bool) -> some View {
    VStack(alignment: centered ? .center : .leading, spacing: 4) {
      Text(playback.title)
        .font(.caption.bold())
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .multilineTextAlignment(centered ? .center : .leading)

      Text(playback.artist)
        .font(.caption2)
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .multilineTextAlignment(centered ? .center : .leading)
    }
    .frame(maxWidth: .infinity, alignment: centered ? .center : .leading)
  }

  private func transportControls(_ playback: SpotifyPlayback, spacing: CGFloat) -> some View {
    HStack(spacing: spacing) {
      controlButton(icon: "backward.fill", size: 14) {
        Task { await spotify.skipPrevious() }
      }
      controlButton(
        icon: playback.isPlaying ? "pause.fill" : "play.fill",
        size: 18,
        prominent: true
      ) {
        Task { await spotify.togglePlayPause() }
      }
      controlButton(icon: "forward.fill", size: 14) {
        Task { await spotify.skipNext() }
      }
    }
  }

  private func scrubber(_ playback: SpotifyPlayback) -> some View {
    VStack(spacing: 4) {
      Slider(
        value: scrubBinding(current: playback),
        in: 0...max(playback.durationSeconds, 1)
      ) { editing in
        isScrubbing = editing
        if !editing {
          Task {
            await spotify.seek(to: Int(scrubValue * 1000))
          }
        }
      }
      .tint(.green)

      HStack {
        Text(formatTime(isScrubbing ? scrubValue : playback.positionSeconds))
        Spacer()
        Text(formatTime(playback.durationSeconds))
      }
      .font(.caption2.monospacedDigit())
      .foregroundStyle(.secondary)
    }
  }

  private func albumArtLayout(_ playback: SpotifyPlayback) -> some View {
    ZStack(alignment: .bottom) {
      Group {
        if let image = playback.artwork {
          Image(uiImage: image)
            .resizable()
            .scaledToFill()
        } else {
          LinearGradient(
            colors: [Color.green.opacity(0.5), Color.black.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        }
      }

      LinearGradient(colors: [.clear, .black.opacity(0.85)], startPoint: .center, endPoint: .bottom)

      VStack(spacing: 6) {
        Text(playback.title)
          .font(.caption.bold())
          .lineLimit(1)
        Text(playback.artist)
          .font(.caption2)
          .foregroundStyle(.white.opacity(0.8))
          .lineLimit(1)

        HStack(spacing: 20) {
          controlButton(icon: "backward.fill", size: 12, light: true) {
            Task { await spotify.skipPrevious() }
          }
          controlButton(
            icon: playback.isPlaying ? "pause.fill" : "play.fill",
            size: 16,
            prominent: true,
            light: true
          ) {
            Task { await spotify.togglePlayPause() }
          }
          controlButton(icon: "forward.fill", size: 12, light: true) {
            Task { await spotify.skipNext() }
          }
        }

        Slider(
          value: scrubBinding(current: playback),
          in: 0...playback.durationSeconds
        ) { editing in
          isScrubbing = editing
          if !editing {
            Task { await spotify.seek(to: Int(scrubValue * 1000)) }
          }
        }
        .tint(.green)
      }
      .padding(8)
    }
  }

  // MARK: - States

  private var connectView: some View {
    VStack(spacing: 8) {
      Image(systemName: "music.note.list")
        .font(.title2)
        .foregroundStyle(.green)
      Text("Pripojiť Spotify")
        .font(.caption.bold())
      Text("Pre ovládanie a prehrávanie")
        .font(.caption2)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
      Button("Prihlásiť sa") {
        auth.startLogin()
      }
      .font(.caption.bold())
      .buttonStyle(.borderedProminent)
      .tint(.green)
    }
    .padding(10)
  }

  private var idleView: some View {
    VStack(spacing: 8) {
      Image(systemName: "music.note")
        .font(.title2)
        .foregroundStyle(.green)
      Text("Spotify")
        .font(.caption.bold())
      Text(spotify.statusMessage ?? "Spustite hudbu v Spotify")
        .font(.caption2)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
      Button("Otvoriť Spotify") {
        spotify.openSpotifyApp()
      }
      .font(.caption2.bold())
    }
    .padding(10)
  }

  // MARK: - Components

  private func artworkView(_ image: UIImage?, size: CGFloat) -> some View {
    Group {
      if let image {
        Image(uiImage: image)
          .resizable()
          .scaledToFill()
      } else {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
          .fill(Color.green.opacity(0.25))
          .overlay {
            Image(systemName: "music.note")
              .foregroundStyle(.green)
          }
      }
    }
    .frame(width: size, height: size)
    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
  }

  private func controlButton(
    icon: String,
    size: CGFloat,
    prominent: Bool = false,
    light: Bool = false,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      Image(systemName: icon)
        .font(.system(size: size, weight: .bold))
        .foregroundStyle(light ? .white : .primary)
        .frame(width: prominent ? 32 : 26, height: prominent ? 32 : 26)
        .background {
          if prominent {
            Circle()
              .fill(.green.opacity(light ? 0.9 : 0.85))
              .shadow(color: .green.opacity(0.35), radius: 6, y: 2)
          }
        }
    }
    .buttonStyle(.plain)
  }

  private func scrubBinding(current: SpotifyPlayback) -> Binding<Double> {
    Binding(
      get: { isScrubbing ? scrubValue : current.positionSeconds },
      set: { newValue in
        scrubValue = newValue
      }
    )
  }

  private func formatTime(_ seconds: Double) -> String {
    let total = max(0, Int(seconds))
    let minutes = total / 60
    let secs = total % 60
    return String(format: "%d:%02d", minutes, secs)
  }
}
