import Foundation

struct LocalUser: Equatable {
    let appleUserId: String
    let displayName: String
    let serverUserId: String?
    let email: String?

    init(appleUserId: String, displayName: String, serverUserId: String? = nil, email: String? = nil) {
        self.appleUserId = appleUserId
        self.displayName = displayName
        self.serverUserId = serverUserId
        self.email = email
    }
}
