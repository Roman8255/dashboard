import SwiftUI

struct FriendsTabView: View {
    @ObservedObject private var friendsService = FriendsService.shared
    @ObservedObject private var store = DashboardStore.shared

    @State private var inviteEmail = ""
    @State private var alertMessage: String?
    @State private var shareDashboard: CloudDashboard?
    @State private var selectedFriendId: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                inviteSection
                if !friendsService.incoming.isEmpty {
                    requestsSection
                }
                friendsSection
                shareSection
            }
            .padding()
        }
        .task { await friendsService.refresh() }
        .alert("Priatelia", isPresented: Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
        .sheet(item: $shareDashboard) { dashboard in
            ShareDashboardSheet(
                dashboard: dashboard,
                friends: friendsService.friends,
                onShare: { friendId, permission in
                    Task {
                        do {
                            try await friendsService.shareDashboard(
                                dashboardId: dashboard.id,
                                friendId: friendId,
                                permission: permission
                            )
                            alertMessage = "Dashboard zdieľaný"
                        } catch {
                            alertMessage = error.localizedDescription
                        }
                    }
                }
            )
        }
    }

    private var inviteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Pridať priateľa", systemImage: "person.badge.plus")
                .font(.headline)

            HStack {
                TextField("Email priateľa", text: $inviteEmail)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .padding(12)
                    .glassCard(cornerRadius: 12)

                Button("Poslať") {
                    Task {
                        do {
                            try await friendsService.sendRequest(email: inviteEmail.trimmingCharacters(in: .whitespaces))
                            inviteEmail = ""
                            alertMessage = "Žiadosť odoslaná"
                        } catch {
                            alertMessage = error.localizedDescription
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(inviteEmail.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private var requestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Žiadosti", systemImage: "tray.fill")
                .font(.headline)

            ForEach(friendsService.incoming) { request in
                HStack {
                    VStack(alignment: .leading) {
                        Text(request.displayName)
                            .font(.subheadline.bold())
                        if let email = request.email {
                            Text(email)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Button("Prijať") {
                        Task {
                            do {
                                try await friendsService.acceptRequest(friendshipId: request.friendshipId)
                            } catch {
                                alertMessage = error.localizedDescription
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .glassCard(cornerRadius: 14)
            }
        }
    }

    private var friendsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Moji priatelia", systemImage: "person.2.fill")
                .font(.headline)

            if friendsService.friends.isEmpty {
                Text("Zatiaľ žiadni priatelia")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(friendsService.friends) { friend in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(friend.displayName)
                                .font(.subheadline.bold())
                            if let email = friend.email {
                                Text(email)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Button(role: .destructive) {
                            Task {
                                try? await friendsService.removeFriendship(friendshipId: friend.friendshipId)
                            }
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                    .padding()
                    .glassCard(cornerRadius: 14)
                }
            }
        }
    }

    private var shareSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Zdieľať dashboard", systemImage: "square.and.arrow.up")
                .font(.headline)

            Text("Vyberte vlastný dashboard na zdieľanie s priateľmi.")
                .font(.caption)
                .foregroundStyle(.secondary)

            ForEach(store.ownedDashboards) { dashboard in
                Button {
                    shareDashboard = dashboard
                } label: {
                    HStack {
                        Text(dashboard.name)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .glassCard(cornerRadius: 14)
                }
                .buttonStyle(.plain)
                .disabled(friendsService.friends.isEmpty)
            }
        }
    }
}