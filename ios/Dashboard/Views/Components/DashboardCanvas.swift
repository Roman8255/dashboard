import SwiftUI

struct DashboardCanvas: View {
    let layout: DashboardLayout

    var body: some View {
        GeometryReader { geo in
            let metrics = GridMetrics.compute(in: geo.size)
            ZStack(alignment: .topLeading) {
                ForEach(layout.widgets) { widget in
                    let frame = GridLayoutEngine.frame(for: widget, metrics: metrics)
                    WidgetRenderer(widget: widget)
                        .frame(width: frame.width, height: frame.height)
                        .position(x: frame.midX, y: frame.midY)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

#Preview {
    DashboardCanvas(
        layout: DashboardLayout(widgets: [
            WidgetInstance(typeId: "clock", styleId: "minimal", column: 0, row: 0, columnSpan: 2, rowSpan: 2)
        ])
    )
    .background(Color.black)
}
