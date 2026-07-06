import CoreLocation
import Foundation
import WeatherKit

struct WeatherSnapshot: Equatable {
    let temperature: String
    let symbolName: String
    let condition: String
    let high: String
    let low: String
}

@MainActor
final class DashboardWeatherService: ObservableObject {
    static let shared = DashboardWeatherService()

    @Published private(set) var snapshot: WeatherSnapshot?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var needsLocationPermission = false

    private let weatherKit = WeatherKit.WeatherService.shared
    private var lastFetch: Date?
    private let cacheInterval: TimeInterval = 600

    private init() {}

    func refreshIfNeeded() async {
        if let lastFetch, Date().timeIntervalSince(lastFetch) < cacheInterval, snapshot != nil {
            return
        }
        await refresh()
    }

    func refresh() async {
        isLoading = snapshot == nil
        errorMessage = nil
        needsLocationPermission = false
        defer { isLoading = false }

        do {
            let location = try await LocationManager.shared.fetchLocation()

            if let weatherKitSnapshot = await fetchFromWeatherKit(location: location) {
                snapshot = weatherKitSnapshot
                lastFetch = Date()
                return
            }

            snapshot = try await OpenMeteoService.fetch(location: location)
            lastFetch = Date()
        } catch let error as LocationError {
            needsLocationPermission = error == .denied
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Počasie nedostupné"
        }
    }

    private func fetchFromWeatherKit(location: CLLocation) async -> WeatherSnapshot? {
        do {
            let weather = try await weatherKit.weather(for: location)
            let current = weather.currentWeather
            let today = weather.dailyForecast.first

            return WeatherSnapshot(
                temperature: current.temperature.formatted(.measurement(width: .narrow, usage: .weather)),
                symbolName: current.symbolName,
                condition: current.condition.description,
                high: today?.highTemperature.formatted(.measurement(width: .narrow, usage: .weather)) ?? "—",
                low: today?.lowTemperature.formatted(.measurement(width: .narrow, usage: .weather)) ?? "—"
            )
        } catch {
            return nil
        }
    }
}
