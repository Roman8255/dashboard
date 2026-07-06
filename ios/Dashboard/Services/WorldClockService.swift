import Foundation

struct WorldClockEntry: Identifiable, Equatable {
    let id: String
    let cityName: String
    let timeZone: TimeZone
}

@MainActor
final class WorldClockService: ObservableObject {
    static let shared = WorldClockService()

    @Published private(set) var entries: [WorldClockEntry] = []

    private init() {
        reload()
    }

    func reload() {
        let cities = WidgetPreferencesStore.shared.preferences.worldClockCities
        entries = cities.compactMap { identifier in
            guard let timeZone = TimeZone(identifier: identifier) else { return nil }
            return WorldClockEntry(
                id: identifier,
                cityName: WorldClockCityCatalog.name(for: identifier),
                timeZone: timeZone
            )
        }
    }

    func isBusinessHours(for entry: WorldClockEntry, at date: Date = Date()) -> Bool {
        var calendar = Calendar.current
        calendar.timeZone = entry.timeZone
        let hour = calendar.component(.hour, from: date)
        return (9..<17).contains(hour)
    }

    func offsetDescription(for entry: WorldClockEntry, relativeTo local: TimeZone = .current) -> String {
        let now = Date()
        let localOffset = local.secondsFromGMT(for: now)
        let remoteOffset = entry.timeZone.secondsFromGMT(for: now)
        let diffHours = (remoteOffset - localOffset) / 3600
        if diffHours == 0 { return "rovnaký čas" }
        return diffHours > 0 ? "+\(diffHours) h" : "\(diffHours) h"
    }
}
