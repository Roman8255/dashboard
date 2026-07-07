import Foundation

struct ServerAgent: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let hostname: String?
    let online: Bool
    let lastSeenAt: String?
}

struct ServerMetricsSnapshot: Codable, Equatable {
    let cpuPercent: Double
    let cpuPercentMax: Double?
    let memUsedMb: Double
    let memTotalMb: Double
    let memUsedPercent: Double?
    let memUsedPercentMax: Double?
    let diskUsedPercent: Double
    let diskUsedPercentMax: Double?
    let loadAvg: Double
    let loadAvgMax: Double?
    let reportedAt: String

    var ramPercent: Double? {
        if let memUsedPercent { return memUsedPercent }
        guard memTotalMb > 0 else { return nil }
        return (memUsedMb / memTotalMb) * 100
    }

    var ramPercentMax: Double? {
        if let memUsedPercentMax { return memUsedPercentMax }
        return ramPercent
    }
}

struct CreateServerResponse: Decodable {
    let server: ServerAgent
    let token: String
    let installCommand: String
    let stopCommand: String
}

struct ServerMetricsResponse: Decodable {
    let server: ServerAgent
    let latest: ServerMetricsSnapshot?
    let history: [ServerMetricsSnapshot]
}

struct ServerConnectionTestResult: Equatable {
    let online: Bool
    let hostname: String?
    let hasMetrics: Bool
    let message: String
}

@MainActor
final class ServerMonitoringService: ObservableObject {
    static let shared = ServerMonitoringService()

    @Published private(set) var servers: [ServerAgent] = []
    @Published var errorMessage: String?

    private init() {}

    func refresh() async {
        do {
            struct Response: Decodable { let servers: [ServerAgent] }
            let response: Response = try await APIClient.shared.request("/api/app/servers")
            servers = response.servers
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createServer(name: String) async throws -> CreateServerResponse {
        struct Body: Encodable { let name: String }
        let response: CreateServerResponse = try await APIClient.shared.request(
            "/api/app/servers",
            method: "POST",
            body: Body(name: name)
        )
        ServerAgentCredentialStore.save(token: response.token, for: response.server.id)
        await refresh()
        return response
    }

    func deleteServer(id: String) async throws {
        _ = try await APIClient.shared.send("/api/app/servers/\(id)", method: "DELETE")
        ServerAgentCredentialStore.delete(for: id)
        await refresh()
    }

    func fetchMetrics(serverId: String) async throws -> ServerMetricsResponse {
        try await APIClient.shared.request("/api/app/servers/\(serverId)")
    }

    func testConnection(serverId: String) async -> ServerConnectionTestResult {
        do {
            let response = try await fetchMetrics(serverId: serverId)
            await refresh()

            if response.server.online {
                if response.latest != nil {
                    let host = response.server.hostname ?? "server"
                    return ServerConnectionTestResult(
                        online: true,
                        hostname: response.server.hostname,
                        hasMetrics: true,
                        message: "\(host) je online a posiela dáta."
                    )
                }
                return ServerConnectionTestResult(
                    online: true,
                    hostname: response.server.hostname,
                    hasMetrics: false,
                    message: "Agent je online, ale zatiaľ neposlal metriky."
                )
            }

            return ServerConnectionTestResult(
                online: false,
                hostname: response.server.hostname,
                hasMetrics: false,
                message: "Server je offline — agent neodpovedá."
            )
        } catch {
            return ServerConnectionTestResult(
                online: false,
                hostname: nil,
                hasMetrics: false,
                message: error.localizedDescription
            )
        }
    }
}
