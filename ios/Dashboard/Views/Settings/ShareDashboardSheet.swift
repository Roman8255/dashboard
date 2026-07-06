import SwiftUI

struct ShareDashboardSheet: View {
    let dashboard: CloudDashboard
    let friends: [FriendSummary]
    let onShare: (String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedFriendId: String?
    @State private var permission = "view"

    var body: some View {
        NavigationStack {
            Form {
                Section("Dashboard") {
                    Text(dashboard.name)
                }
                Section("Priateľ") {
                    Picker("Používateľ", selection: $selectedFriendId) {
                        Text("Vyberte").tag(Optional<String>.none)
                        ForEach(friends) { friend in
                            Text(friend.displayName).tag(Optional(friend.id))
                        }
                    }
                }
                Section("Oprávnenie") {
                    Picker("Prístup", selection: $permission) {
                        Text("Len čítanie").tag("view")
                        Text("Úpravy").tag("edit")
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Zdieľať")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Zrušiť") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Zdieľať") {
                        if let selectedFriendId {
                            onShare(selectedFriendId, permission)
                            dismiss()
                        }
                    }
                    .disabled(selectedFriendId == nil)
                }
            }
        }
        .onAppear {
            selectedFriendId = friends.first?.id
        }
    }
}
