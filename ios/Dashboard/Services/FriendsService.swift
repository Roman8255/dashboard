import Foundation

struct FriendSummary: Identifiable, Codable, Equatable {
    let friendshipId: String
    let id: String
    var displayName: String
    var email: String?
}

struct FriendsResponse: Codable {
    let friends: [FriendSummary]
    let incoming: [FriendSummary]
    let outgoing: [FriendSummary]
}

@MainActor
final class FriendsService: ObservableObject {
    static let shared = FriendsService()

    @Published private(set) var friends: [FriendSummary] = []
    @Published private(set) var incoming: [FriendSummary] = []
    @Published private(set) var outgoing: [FriendSummary] = []
    @Published var errorMessage: String?

    private init() {}

    func refresh() async {
        do {
            let response: FriendsResponse = try await APIClient.shared.request("/api/app/friends")
            friends = response.friends
            incoming = response.incoming
            outgoing = response.outgoing
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func sendRequest(email: String) async throws {
        struct Body: Encodable { let email: String }
        _ = try await APIClient.shared.send(
            "/api/app/friends",
            method: "POST",
            body: Body(email: email)
        )
        await refresh()
    }

    func acceptRequest(friendshipId: String) async throws {
        _ = try await APIClient.shared.send(
            "/api/app/friends/\(friendshipId)",
            method: "POST"
        )
        await refresh()
    }

    func removeFriendship(friendshipId: String) async throws {
        _ = try await APIClient.shared.send(
            "/api/app/friends/\(friendshipId)",
            method: "DELETE"
        )
        await refresh()
    }

    func shareDashboard(dashboardId: String, friendId: String, permission: String) async throws {
        struct Body: Encodable {
            let friendId: String
            let permission: String
        }
        _ = try await APIClient.shared.send(
            "/api/app/dashboards/\(dashboardId)/share",
            method: "POST",
            body: Body(friendId: friendId, permission: permission)
        )
    }
}
