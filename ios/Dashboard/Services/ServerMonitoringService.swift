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
    let memUsedMb: Double
    let memTotalMb: Double
    let diskUsedPercent: Double
    let loadAvg: Double
    let reportedAt: String
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
        await refresh()
        return response
    }

    func deleteServer(id: String) async throws {
        _ = try await APIClient.shared.send("/api/app/servers/\(id)", method: "DELETE")
        await refresh()
    }

    func fetchMetrics(serverId: String) async throws -> ServerMetricsResponse {
        try await APIClient.shared.request("/api/app/servers/\(serverId)")
    }
}
