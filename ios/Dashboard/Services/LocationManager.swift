import CoreLocation
import Foundation

enum LocationError: LocalizedError, Equatable {
    case denied
    case unavailable
    case timedOut

    var errorDescription: String? {
        switch self {
        case .denied: return "Povoliť polohu v Nastaveniach"
        case .unavailable: return "Poloha nedostupná"
        case .timedOut: return "Čakanie na polohu vypršalo"
        }
    }
}

@MainActor
final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()

    @Published private(set) var location: CLLocation?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined

    private let manager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        authorizationStatus = manager.authorizationStatus
    }

    func requestPermissionIfNeeded() {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }

    func fetchLocation() async throws -> CLLocation {
        if let location, abs(location.timestamp.timeIntervalSinceNow) < 600 {
            return location
        }

        switch manager.authorizationStatus {
        case .denied, .restricted:
            throw LocationError.denied
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        default:
            break
        }

        return try await withCheckedThrowingContinuation { continuation in
            locationContinuation?.resume(throwing: LocationError.unavailable)
            locationContinuation = continuation
            manager.requestLocation()

            Task {
                try? await Task.sleep(nanoseconds: 12_000_000_000)
                guard let pending = self.locationContinuation else { return }
                self.locationContinuation = nil
                pending.resume(throwing: LocationError.timedOut)
            }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
                if locationContinuation != nil {
                    manager.requestLocation()
                }
            } else if manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted {
                locationContinuation?.resume(throwing: LocationError.denied)
                locationContinuation = nil
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        Task { @MainActor in
            location = latest
            locationContinuation?.resume(returning: latest)
            locationContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            if let clError = error as? CLError, clError.code == .denied {
                locationContinuation?.resume(throwing: LocationError.denied)
            } else {
                locationContinuation?.resume(throwing: error)
            }
            locationContinuation = nil
        }
    }
}
