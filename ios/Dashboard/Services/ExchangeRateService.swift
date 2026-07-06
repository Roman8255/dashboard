import Foundation

struct ExchangeRateEntry: Identifiable, Equatable {
    let code: String
    let rate: Double
    let changeDirection: ChangeDirection

    var id: String { code }

    enum ChangeDirection: Equatable {
        case up, down, flat, unknown
    }
}

@MainActor
final class ExchangeRateService: ObservableObject {
    static let shared = ExchangeRateService()

    @Published private(set) var entries: [ExchangeRateEntry] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var lastUpdated: Date?

    private let targetCurrencies = ["USD", "GBP", "CZK", "CHF"]
    private var lastFetch: Date?
    private let cacheInterval: TimeInterval = 3600

    private init() {}

    var baseCurrency: String {
        WidgetPreferencesStore.shared.preferences.exchangeBaseCurrency
    }

    func refreshIfNeeded() async {
        if let lastFetch, Date().timeIntervalSince(lastFetch) < cacheInterval, !entries.isEmpty {
            return
        }
        await refresh()
    }

    func refresh() async {
        isLoading = entries.isEmpty
        errorMessage = nil
        defer { isLoading = false }

        let base = baseCurrency
        let todayURL = URL(string: "https://api.frankfurter.app/latest?from=\(base)&to=\(targetCurrencies.joined(separator: ","))")!
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let yesterdayString = formatter.string(from: yesterday)
        let yesterdayURL = URL(string: "https://api.frankfurter.app/\(yesterdayString)?from=\(base)&to=\(targetCurrencies.joined(separator: ","))")!

        do {
            async let todayData = fetchRates(from: todayURL)
            async let yesterdayData = fetchRates(from: yesterdayURL)
            let (todayRates, yesterdayRates) = try await (todayData, yesterdayData)

            entries = targetCurrencies.compactMap { code in
                guard let rate = todayRates[code] else { return nil }
                let direction: ExchangeRateEntry.ChangeDirection
                if let previous = yesterdayRates[code] {
                    if rate > previous { direction = .up }
                    else if rate < previous { direction = .down }
                    else { direction = .flat }
                } else {
                    direction = .unknown
                }
                return ExchangeRateEntry(code: code, rate: rate, changeDirection: direction)
            }
            lastFetch = Date()
            lastUpdated = Date()
        } catch {
            errorMessage = "Kurzy nedostupné"
        }
    }

    private func fetchRates(from url: URL) async throws -> [String: Double] {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let decoded = try JSONDecoder().decode(FrankfurterResponse.self, from: data)
        return decoded.rates
    }
}

private struct FrankfurterResponse: Decodable {
    let rates: [String: Double]
}
