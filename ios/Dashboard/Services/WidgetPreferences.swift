import Foundation

struct WidgetPreferences: Codable, Equatable {
    var worldClockCities: [String]
    var favoriteContactIDs: [String]
    var exchangeBaseCurrency: String

    static let defaultCities = ["Europe/Bratislava", "Europe/London", "America/New_York"]

    static let `default` = WidgetPreferences(
        worldClockCities: defaultCities,
        favoriteContactIDs: [],
        exchangeBaseCurrency: "EUR"
    )
}

@MainActor
final class WidgetPreferencesStore: ObservableObject {
    static let shared = WidgetPreferencesStore()

    @Published private(set) var preferences: WidgetPreferences = .default

    private let defaults = UserDefaults.standard
    private var userId: String?

    private init() {}

    func load(for user: LocalUser) {
        userId = user.appleUserId
        let key = storageKey(for: user.appleUserId)
        guard let data = defaults.data(forKey: key),
              let decoded = try? JSONDecoder().decode(WidgetPreferences.self, from: data) else {
            preferences = .default
            return
        }
        preferences = decoded
    }

    func reset() {
        userId = nil
        preferences = .default
    }

    func update(_ transform: (inout WidgetPreferences) -> Void) {
        var updated = preferences
        transform(&updated)
        updated.worldClockCities = Array(updated.worldClockCities.prefix(3))
        updated.favoriteContactIDs = Array(updated.favoriteContactIDs.prefix(4))
        preferences = updated
        save()
    }

    private func save() {
        guard let userId else { return }
        let key = storageKey(for: userId)
        guard let data = try? JSONEncoder().encode(preferences) else { return }
        defaults.set(data, forKey: key)
    }

    private func storageKey(for userId: String) -> String {
        "widget_preferences_\(userId)"
    }
}

enum WorldClockCityCatalog {
    static let options: [(id: String, name: String)] = [
        ("Europe/Bratislava", "Bratislava"),
        ("Europe/Prague", "Praha"),
        ("Europe/London", "Londýn"),
        ("Europe/Berlin", "Berlín"),
        ("Europe/Paris", "Paríž"),
        ("America/New_York", "New York"),
        ("America/Los_Angeles", "Los Angeles"),
        ("Asia/Tokyo", "Tokyo"),
        ("Asia/Dubai", "Dubaj"),
        ("Asia/Singapore", "Singapur")
    ]

    static func name(for identifier: String) -> String {
        options.first { $0.id == identifier }?.name ?? identifier.split(separator: "/").last.map(String.init) ?? identifier
    }
}
