import SwiftUI

struct DashboardView: View {
    @ObservedObject private var store = DashboardStore.shared
    let onOpenSettings: () -> Void

    var body: some View {
        ZStack {
            DashboardTheme.background
                .ignoresSafeArea()

            DashboardCanvas(layout: store.layout)
                .animation(.spring(response: 0.35, dampingFraction: 0.86), value: store.layout)

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
    }
}

#Preview {
    NavigationStack {
        DashboardView(onOpenSettings: {})
    }
}
