import SwiftUI

struct DashboardView: View {
    @ObservedObject private var store = DashboardStore.shared
    let onOpenSettings: () -> Void

    @State private var showCreateDashboard = false
    @State private var newDashboardName = ""

    var body: some View {
        ZStack(alignment: .top) {
            DashboardTheme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                dashboardPicker
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                DashboardCanvas(layout: store.layout)
                    .animation(.spring(response: 0.35, dampingFraction: 0.86), value: store.layout)
            }

            if store.layout.widgets.isEmpty {
                EmptyDashboardCTA {
                    HapticHelper.lightImpact()
                    onOpenSettings()
                }
            }
        }
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0.5) {
            HapticHelper.mediumImpact()
            onOpenSettings()
        }
        .toolbar(.hidden, for: .navigationBar)
        .confirmationDialog("Nový dashboard", isPresented: $showCreateDashboard, titleVisibility: .visible) {
            TextField("Názov", text: $newDashboardName)
            Button("Vytvoriť") {
                Task {
                    let name = newDashboardName.isEmpty ? "Dashboard" : newDashboardName
                    try? await store.createDashboard(name: name)
                    newDashboardName = ""
                }
            }
            Button("Zrušiť", role: .cancel) {}
        }
    }

    private var dashboardPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(store.dashboards) { dashboard in
                    Button {
                        HapticHelper.lightImpact()
                        store.selectDashboard(id: dashboard.id)
                    } label: {
                        HStack(spacing: 6) {
                            if dashboard.isShared {
                                Image(systemName: "person.2.fill")
                                    .font(.caption2)
                            }
                            Text(dashboard.name)
                                .font(.caption.bold())
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            store.activeDashboardId == dashboard.id
                                ? Color.accentColor.opacity(0.3)
                                : Color.white.opacity(0.1),
                            in: Capsule()
                        )
                    }
                    .buttonStyle(.plain)
                }

                if store.canCreateDashboard {
                    Button {
                        showCreateDashboard = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.caption.bold())
                            .padding(10)
                            .background(Color.white.opacity(0.1), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        DashboardView(onOpenSettings: {})
    }
}
