import Foundation

struct CloudDashboard: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var layout: DashboardLayout
    var isShared: Bool
    var permission: String
    var ownerName: String?
    var sortOrder: Int
    var updatedAt: Date?

    var canEdit: Bool { !isShared || permission == "edit" }

    var isReadOnly: Bool {
        isShared && permission == "view"
    }
}

@MainActor
final class DashboardSyncService {
    static let shared = DashboardSyncService()

    private init() {}

    struct DashboardListResponse: Decodable {
        let owned: [RemoteDashboard]
        let shared: [RemoteDashboard]
        let maxDashboards: Int
    }

    struct RemoteDashboard: Decodable {
        let id: String
        let name: String
        let layout: DashboardLayout
        let sortOrder: Int
        let updatedAt: String
        let isShared: Bool?
        let permission: String?
        let ownerName: String?
    }

    struct DashboardResponse: Decodable {
        let dashboard: RemoteDashboard
    }

    struct CreateDashboardResponse: Decodable {
        let dashboard: RemoteDashboard
    }

    func fetchDashboards() async throws -> (owned: [CloudDashboard], shared: [CloudDashboard]) {
        let response: DashboardListResponse = try await APIClient.shared.request("/api/app/dashboards")
        return (
            owned: response.owned.map(mapDashboard(shared: false)),
            shared: response.shared.map(mapDashboard(shared: true))
        )
    }

    func createDashboard(name: String) async throws -> CloudDashboard {
        struct Body: Encodable { let name: String }
        let response: CreateDashboardResponse = try await APIClient.shared.request(
            "/api/app/dashboards",
            method: "POST",
            body: Body(name: name)
        )
        return mapDashboard(shared: false)(response.dashboard)
    }

    func updateDashboard(id: String, name: String?, layout: DashboardLayout?) async throws -> CloudDashboard {
        struct Body: Encodable {
            let name: String?
            let layout: DashboardLayout?
        }
        let response: DashboardResponse = try await APIClient.shared.request(
            "/api/app/dashboards/\(id)",
            method: "PUT",
            body: Body(name: name, layout: layout)
        )
        return mapDashboard(shared: false)(response.dashboard)
    }

    func deleteDashboard(id: String) async throws {
        _ = try await APIClient.shared.send(
            "/api/app/dashboards/\(id)",
            method: "DELETE"
        )
    }

    private func mapDashboard(shared: Bool) -> (RemoteDashboard) -> CloudDashboard {
        { remote in
            CloudDashboard(
                id: remote.id,
                name: remote.name,
                layout: remote.layout,
                isShared: remote.isShared ?? shared,
                permission: remote.permission ?? "edit",
                ownerName: remote.ownerName,
                sortOrder: remote.sortOrder,
                updatedAt: ISO8601DateFormatter().date(from: remote.updatedAt)
            )
        }
    }
}
