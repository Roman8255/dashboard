import SwiftUI

struct EditableDashboardCanvas: View {
    @ObservedObject var store: DashboardStore
    let metrics: GridMetrics
    var onDelete: ((WidgetInstance) -> Void)?

    @State private var selectedId: UUID?
    @State private var dragSession: DragSession?
    @State private var resizePreview: WidgetInstance?
    @State private var activeResize: ResizeSession?

    private struct DragSession {
        let widgetId: UUID
        let startColumn: Int
        let startRow: Int
        var translation: CGSize
        var targetColumn: Int
        var targetRow: Int
    }

    private struct ResizeSession {
        let id: UUID
        let handle: ResizeHandle
        let start: WidgetInstance
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            GlassCanvasBackground(metrics: metrics, showGrid: true)

            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    if dragSession == nil {
                        selectedId = nil
                    }
                }
                .dropDestination(for: WidgetDragPayload.self) { items, location in
                    guard let payload = items.first else { return false }
                    return handleDrop(payload: payload, at: location)
                }

            if let dragSession {
                let ghost = ghostWidget(for: dragSession)
                let ghostFrame = GridLayoutEngine.frame(for: ghost, metrics: metrics)
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.accentColor.opacity(0.55), lineWidth: 1.5)
                    .background {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.accentColor.opacity(0.08))
                    }
                    .frame(width: ghostFrame.width, height: ghostFrame.height)
                    .position(x: ghostFrame.midX, y: ghostFrame.midY)
                    .allowsHitTesting(false)
            }

            ForEach(sortedWidgets) { widget in
                widgetLayer(for: widget)
            }
        }
        .coordinateSpace(name: "editorCanvas")
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .animation(dragSession == nil && resizePreview == nil ? .spring(response: 0.32, dampingFraction: 0.86) : nil, value: store.layout)
    }

    @ViewBuilder
    private func widgetLayer(for widget: WidgetInstance) -> some View {
        let isDragging = dragSession?.widgetId == widget.id
        let displayWidget = displayWidget(for: widget)
        let baseWidget = isDragging ? widget : displayWidget
        let frame = GridLayoutEngine.frame(for: baseWidget, metrics: metrics)
        let isSelected = selectedId == widget.id
        let dragOffset = isDragging ? (dragSession?.translation ?? .zero) : .zero

        ZStack(alignment: .topLeading) {
            WidgetRenderer(widget: displayWidget)
                .overlay {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.accentColor.opacity(0.7), lineWidth: 1.5)
                    }
                }

            if isSelected, !isDragging {
                resizeHandles(for: widget, frame: frame)
            }
        }
        .frame(width: frame.width, height: frame.height)
        .position(x: frame.midX, y: frame.midY)
        .offset(dragOffset)
        .opacity(isDragging ? 0.92 : 1)
        .scaleEffect(isDragging ? 1.02 : 1)
        .zIndex(isDragging || isSelected ? 10 : 1)
        .gesture(moveGesture(for: widget, baseFrame: frame))
        .simultaneousGesture(
            TapGesture().onEnded {
                guard dragSession == nil else { return }
                HapticHelper.lightImpact()
                selectedId = widget.id
            }
        )
        .contextMenu {
            Button(role: .destructive) {
                onDelete?(widget)
                if selectedId == widget.id { selectedId = nil }
            } label: {
                Label("Odstrániť", systemImage: "trash")
            }
        }
    }

    private var sortedWidgets: [WidgetInstance] {
        store.layout.widgets.sorted { lhs, rhs in
            if lhs.row == rhs.row { return lhs.column < rhs.column }
            return lhs.row < rhs.row
        }
    }

    private func displayWidget(for widget: WidgetInstance) -> WidgetInstance {
        if let resizePreview, resizePreview.id == widget.id {
            return resizePreview
        }
        return widget
    }

    private func ghostWidget(for session: DragSession) -> WidgetInstance {
        guard let original = store.layout.widgets.first(where: { $0.id == session.widgetId }) else {
            return WidgetInstance(typeId: "", styleId: "", column: 0, row: 0)
        }
        return WidgetInstance(
            id: original.id,
            typeId: original.typeId,
            styleId: original.styleId,
            column: session.targetColumn,
            row: session.targetRow,
            columnSpan: original.columnSpan,
            rowSpan: original.rowSpan
        )
    }

    private func moveGesture(for widget: WidgetInstance, baseFrame: CGRect) -> some Gesture {
        DragGesture(minimumDistance: 6, coordinateSpace: .named("editorCanvas"))
            .onChanged { value in
                selectedId = widget.id
                dragSession = dragSession ?? DragSession(
                    widgetId: widget.id,
                    startColumn: widget.column,
                    startRow: widget.row,
                    translation: .zero,
                    targetColumn: widget.column,
                    targetRow: widget.row
                )

                guard var session = dragSession, session.widgetId == widget.id else { return }

                session.translation = value.translation

                let center = CGPoint(
                    x: baseFrame.midX + value.translation.width,
                    y: baseFrame.midY + value.translation.height
                )

                if let cell = GridLayoutEngine.cellAt(point: center, metrics: metrics) {
                    let snapped = GridLayoutEngine.snapOrigin(for: widget, at: cell, metrics: metrics)
                    session.targetColumn = snapped.column
                    session.targetRow = snapped.row
                }

                dragSession = session
            }
            .onEnded { _ in
                defer { dragSession = nil }
                guard let session = dragSession else { return }

                let unchanged = session.targetColumn == session.startColumn && session.targetRow == session.startRow
                if unchanged {
                    return
                }

                let moved = store.moveOrSwapWidget(
                    id: widget.id,
                    to: session.targetColumn,
                    row: session.targetRow,
                    metrics: metrics
                )

                if moved {
                    HapticHelper.lightImpact()
                } else {
                    HapticHelper.warning()
                }
            }
    }

    @ViewBuilder
    private func resizeHandles(for widget: WidgetInstance, frame: CGRect) -> some View {
        ForEach(ResizeHandle.allCases, id: \.self) { handle in
            resizeHandleDot(handle: handle)
                .position(handlePosition(for: handle, in: frame))
                .highPriorityGesture(resizeGesture(for: widget, handle: handle))
        }
    }

    private func resizeHandleDot(handle: ResizeHandle) -> some View {
        Circle()
            .fill(Color.accentColor.opacity(0.9))
            .frame(width: handle.isCorner ? 12 : 9, height: handle.isCorner ? 12 : 9)
            .overlay {
                Circle().strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
            }
    }

    private func handlePosition(for handle: ResizeHandle, in frame: CGRect) -> CGPoint {
        switch handle {
        case .topLeft: return CGPoint(x: 0, y: 0)
        case .top: return CGPoint(x: frame.width / 2, y: 0)
        case .topRight: return CGPoint(x: frame.width, y: 0)
        case .right: return CGPoint(x: frame.width, y: frame.height / 2)
        case .bottomRight: return CGPoint(x: frame.width, y: frame.height)
        case .bottom: return CGPoint(x: frame.width / 2, y: frame.height)
        case .bottomLeft: return CGPoint(x: 0, y: frame.height)
        case .left: return CGPoint(x: 0, y: frame.height / 2)
        }
    }

    private func resizeGesture(for widget: WidgetInstance, handle: ResizeHandle) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named("editorCanvas"))
            .onChanged { value in
                if activeResize == nil {
                    activeResize = ResizeSession(id: widget.id, handle: handle, start: widget)
                }
                guard let session = activeResize, session.id == widget.id else { return }

                let deltaCol = GridLayoutEngine.snappedDelta(value.translation.width, cellStride: metrics.cellStride)
                let deltaRow = GridLayoutEngine.snappedDelta(value.translation.height, cellStride: metrics.cellStride)
                let sizeSpec = WidgetRegistry.sizeSpec(typeId: widget.typeId, styleId: widget.styleId)

                if let resized = GridLayoutEngine.resized(
                    from: session.start,
                    handle: handle,
                    deltaColumn: deltaCol,
                    deltaRow: deltaRow,
                    metrics: metrics,
                    minColumnSpan: sizeSpec.minColumnSpan,
                    minRowSpan: sizeSpec.minRowSpan
                ), GridLayoutEngine.canPlace(resized, in: store.layout.widgets, metrics: metrics, excluding: widget.id) {
                    resizePreview = resized
                }
            }
            .onEnded { _ in
                defer {
                    activeResize = nil
                    resizePreview = nil
                }
                guard let resizePreview else { return }
                HapticHelper.success()
                store.resizeWidget(id: widget.id, to: resizePreview, metrics: metrics)
            }
    }

    private func handleDrop(payload: WidgetDragPayload, at location: CGPoint) -> Bool {
        guard let cell = GridLayoutEngine.cellAt(point: location, metrics: metrics) else { return false }
        let spec = WidgetRegistry.sizeSpec(typeId: payload.typeId, styleId: payload.styleId)
        let placeholder = WidgetInstance(
            typeId: payload.typeId,
            styleId: payload.styleId,
            column: cell.column,
            row: cell.row,
            columnSpan: spec.defaultColumnSpan,
            rowSpan: spec.defaultRowSpan
        )
        let snapped = GridLayoutEngine.snapOrigin(for: placeholder, at: cell, metrics: metrics)
        let added = store.addWidget(
            typeId: payload.typeId,
            styleId: payload.styleId,
            column: snapped.column,
            row: snapped.row,
            metrics: metrics
        )
        if added { HapticHelper.success() } else { HapticHelper.warning() }
        return added
    }
}
