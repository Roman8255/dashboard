import Foundation
import Network

enum NetworkConnectionType: Equatable {
    case wifi
    case cellular
    case offline

    var iconName: String {
        switch self {
        case .wifi: return "wifi"
        case .cellular: return "antenna.radiowaves.left.and.right"
        case .offline: return "wifi.slash"
        }
    }

    var label: String {
        switch self {
        case .wifi: return "Wi-Fi"
        case .cellular: return "Mobilné dáta"
        case .offline: return "Offline"
        }
    }
}

@MainActor
final class NetworkMonitorService: ObservableObject {
    static let shared = NetworkMonitorService()

    @Published private(set) var connectionType: NetworkConnectionType = .offline
    @Published private(set) var lastSpeedMbps: Double?
    @Published private(set) var lastSpeedTestAt: Date?
    @Published private(set) var isTestingSpeed = false

    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "sk.romanbednarik.dashboard.network-monitor")
    private var hourlyTimer: Timer?
    private var lastManualTestAt: Date?

    private let speedTestInterval: TimeInterval = 3600
    private let manualTestThrottle: TimeInterval = 30
    private let speedTestURL = URL(string: "https://speed.cloudflare.com/__down?bytes=1000000")!
    private let defaults = UserDefaults.standard

    private init() {
        loadCachedSpeed()
        startMonitoring()
    }

    func startHourlyTimer() {
        hourlyTimer?.invalidate()
        hourlyTimer = Timer.scheduledTimer(withTimeInterval: speedTestInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.runSpeedTestIfNeeded(force: false)
            }
        }
    }

    func stopHourlyTimer() {
        hourlyTimer?.invalidate()
        hourlyTimer = nil
    }

    func onForeground() async {
        await runSpeedTestIfNeeded(force: false)
    }

    func runSpeedTestIfNeeded(force: Bool) async {
        guard connectionType != .offline else { return }
        if !force,
           let lastSpeedTestAt,
           Date().timeIntervalSince(lastSpeedTestAt) < speedTestInterval {
            return
        }
        await runSpeedTest()
    }

    func runManualSpeedTest() async {
        if let lastManualTestAt,
           Date().timeIntervalSince(lastManualTestAt) < manualTestThrottle {
            return
        }
        lastManualTestAt = Date()
        await runSpeedTest()
    }

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                guard let self else { return }
                if path.status == .satisfied {
                    if path.usesInterfaceType(.wifi) {
                        self.connectionType = .wifi
                    } else if path.usesInterfaceType(.cellular) {
                        self.connectionType = .cellular
                    } else {
                        self.connectionType = .wifi
                    }
                } else {
                    self.connectionType = .offline
                }
            }
        }
        monitor.start(queue: monitorQueue)
    }

    private func runSpeedTest() async {
        guard !isTestingSpeed, connectionType != .offline else { return }
        isTestingSpeed = true
        defer { isTestingSpeed = false }

        let start = Date()
        do {
            let (data, response) = try await URLSession.shared.data(from: speedTestURL)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { return }
            let duration = Date().timeIntervalSince(start)
            guard duration > 0 else { return }
            let megabits = Double(data.count) * 8.0 / duration / 1_000_000.0
            lastSpeedMbps = megabits
            lastSpeedTestAt = Date()
            saveCachedSpeed()
        } catch {
            // Keep previous result on failure.
        }
    }

    private func loadCachedSpeed() {
        lastSpeedMbps = defaults.object(forKey: "network_last_speed_mbps") as? Double
        lastSpeedTestAt = defaults.object(forKey: "network_last_speed_test_at") as? Date
    }

    private func saveCachedSpeed() {
        defaults.set(lastSpeedMbps, forKey: "network_last_speed_mbps")
        defaults.set(lastSpeedTestAt, forKey: "network_last_speed_test_at")
    }

    func speedColor() -> String {
        guard let speed = lastSpeedMbps else { return "secondary" }
        if speed > 25 { return "green" }
        if speed > 5 { return "orange" }
        return "red"
    }

    func relativeTestTime() -> String? {
        guard let lastSpeedTestAt else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "sk")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: lastSpeedTestAt, relativeTo: Date())
    }
}

extension NetworkMonitorService {
    func formattedSpeed() -> String? {
        guard let lastSpeedMbps else { return nil }
        return String(format: "%.1f Mbps", lastSpeedMbps)
    }
}
