import SwiftUI

struct GlassBackground: View {
    var cornerRadius: CGFloat = 20
    var elevated: Bool = false

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        DashboardTheme.surfaceHighlight.opacity(elevated ? 1.2 : 1),
                        DashboardTheme.surface
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(DashboardTheme.border, lineWidth: 0.5)
            }
            .shadow(color: DashboardTheme.shadow.opacity(elevated ? 0.5 : 0.25), radius: elevated ? 10 : 6, y: 3)
    }
}

struct GlassCanvasBackground: View {
    let metrics: GridMetrics
    var showGrid: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.02))
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(DashboardTheme.border.opacity(0.6), lineWidth: 0.5)
                }

            if showGrid {
                Canvas { context, _ in
                    for row in 0..<metrics.rows {
                        for column in 0..<metrics.columns {
                            let rect = GridLayoutEngine.frame(
                                for: WidgetInstance(typeId: "", styleId: "", column: column, row: row),
                                metrics: metrics
                            )
                            let path = RoundedRectangle(cornerRadius: 10, style: .continuous).path(in: rect)
                            context.stroke(
                                path,
                                with: .color(DashboardTheme.gridLine),
                                style: StrokeStyle(lineWidth: 0.5, dash: [3, 5])
                            )
                        }
                    }
                }
            }
        }
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 18, elevated: Bool = false) -> some View {
        background(GlassBackground(cornerRadius: cornerRadius, elevated: elevated))
    }

    func dashboardBackground() -> some View {
        background {
            DashboardTheme.background.ignoresSafeArea()
        }
    }
}
