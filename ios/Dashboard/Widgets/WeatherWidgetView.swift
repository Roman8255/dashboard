import SwiftUI

struct WeatherWidgetView: View {
    let styleId: String
    @ObservedObject private var weather = DashboardWeatherService.shared
    @ObservedObject private var locationManager = LocationManager.shared

    var body: some View {
        WidgetCard {
            Group {
                if let snapshot = weather.snapshot {
                    if styleId == "detailed" {
                        detailedView(snapshot)
                    } else {
                        compactView(snapshot)
                    }
                } else if weather.isLoading {
                    VStack(spacing: 8) {
                        ProgressView()
                            .tint(.orange)
                        Text("Načítavam počasie…")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(8)
                } else {
                    errorView
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            Task { await weather.refresh() }
        }
        .task {
            locationManager.requestPermissionIfNeeded()
            await weather.refreshIfNeeded()
        }
        .onChange(of: locationManager.authorizationStatus) { _, status in
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                Task { await weather.refresh() }
            }
        }
    }

    private var errorView: some View {
        VStack(spacing: 8) {
            Image(systemName: weather.needsLocationPermission ? "location.slash" : "cloud.sun")
                .font(.title2)
                .foregroundStyle(.orange.opacity(0.8))

            Text(weather.errorMessage ?? "Klepnite pre obnovenie")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if weather.needsLocationPermission {
                Button("Otvoriť Nastavenia") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.caption2.bold())
            }
        }
        .padding(8)
    }

    private func compactView(_ snapshot: WeatherSnapshot) -> some View {
        VStack(spacing: 4) {
            Image(systemName: snapshot.symbolName)
                .font(.title)
                .symbolRenderingMode(.multicolor)
            Text(snapshot.temperature)
                .font(.title3.bold())
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .padding(8)
    }

    private func detailedView(_ snapshot: WeatherSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: snapshot.symbolName)
                    .font(.title2)
                    .symbolRenderingMode(.multicolor)
                Text(snapshot.temperature)
                    .font(.title3.bold())
            }
            Text(snapshot.condition)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            Spacer(minLength: 0)
            HStack {
                Label(snapshot.high, systemImage: "arrow.up")
                Label(snapshot.low, systemImage: "arrow.down")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
    }
}
