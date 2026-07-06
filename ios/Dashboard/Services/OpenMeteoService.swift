import CoreLocation
import Foundation

enum OpenMeteoService {
    static func fetch(location: CLLocation) async throws -> WeatherSnapshot {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude

        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(lat)),
            URLQueryItem(name: "longitude", value: String(lon)),
            URLQueryItem(name: "current", value: "temperature_2m,weather_code"),
            URLQueryItem(name: "daily", value: "temperature_2m_max,temperature_2m_min"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: "1"),
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(ForecastResponse.self, from: data)
        let code = decoded.current.weather_code
        let unit = decoded.current_units.temperature_2m

        return WeatherSnapshot(
            temperature: format(decoded.current.temperature_2m, unit: unit),
            symbolName: symbol(for: code),
            condition: description(for: code),
            high: format(decoded.daily.temperature_2m_max.first ?? decoded.current.temperature_2m, unit: unit),
            low: format(decoded.daily.temperature_2m_min.first ?? decoded.current.temperature_2m, unit: unit)
        )
    }

    private static func format(_ value: Double, unit: String) -> String {
        let rounded = Int(value.rounded())
        if unit == "°C" {
            return "\(rounded)°"
        }
        return "\(rounded)\(unit)"
    }

    private static func symbol(for code: Int) -> String {
        switch code {
        case 0: return "sun.max.fill"
        case 1, 2: return "cloud.sun.fill"
        case 3: return "cloud.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51, 53, 55, 56, 57: return "cloud.drizzle.fill"
        case 61, 63, 65, 66, 67, 80, 81, 82: return "cloud.rain.fill"
        case 71, 73, 75, 77, 85, 86: return "cloud.snow.fill"
        case 95, 96, 99: return "cloud.bolt.rain.fill"
        default: return "cloud.sun.fill"
        }
    }

    private static func description(for code: Int) -> String {
        switch code {
        case 0: return "Jasno"
        case 1, 2: return "Polojasno"
        case 3: return "Zamračené"
        case 45, 48: return "Hmla"
        case 51, 53, 55: return "Mrholenie"
        case 61, 63, 65: return "Dážď"
        case 71, 73, 75: return "Sneženie"
        case 80, 81, 82: return "Prehánky"
        case 95, 96, 99: return "Búrka"
        default: return "Počasie"
        }
    }

    private struct ForecastResponse: Decodable {
        let current: Current
        let current_units: Units
        let daily: Daily
    }

    private struct Current: Decodable {
        let temperature_2m: Double
        let weather_code: Int
    }

    private struct Units: Decodable {
        let temperature_2m: String
    }

    private struct Daily: Decodable {
        let temperature_2m_max: [Double]
        let temperature_2m_min: [Double]
    }
}
