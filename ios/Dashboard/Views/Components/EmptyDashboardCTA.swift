import SwiftUI

struct EmptyDashboardCTA: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 14) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.accentColor, Color.accentColor.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Pridajte svoj prvý widget")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("Podržte obrazovku alebo klepnite sem")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(28)
            .glassCard(cornerRadius: 24)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        EmptyDashboardCTA {}
    }
}
