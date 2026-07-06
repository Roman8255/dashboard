import SwiftUI

enum DashboardTheme {
    static let background = LinearGradient(
        colors: [
            Color(red: 0.04, green: 0.05, blue: 0.09),
            Color(red: 0.08, green: 0.07, blue: 0.14),
            Color(red: 0.05, green: 0.06, blue: 0.10)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let surface = Color.white.opacity(0.045)
    static let surfaceHighlight = Color.white.opacity(0.08)
    static let border = Color.white.opacity(0.09)
    static let borderStrong = Color.white.opacity(0.16)
    static let gridLine = Color.white.opacity(0.05)
    static let shadow = Color.black.opacity(0.35)
}
