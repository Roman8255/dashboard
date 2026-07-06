import CoreGraphics
import Foundation

enum GridLayoutEngine {
    static func cells(for widget: WidgetInstance) -> Set<GridCell> {
        var result = Set<GridCell>()
        for row in widget.row..<(widget.row + widget.rowSpan) {
            for column in widget.column..<(widget.column + widget.columnSpan) {
                result.insert(GridCell(column: column, row: row))
            }
        }
        return result
    }

    static func frame(for widget: WidgetInstance, metrics: GridMetrics) -> CGRect {
        let originX = GridMetrics.horizontalPadding + CGFloat(widget.column) * metrics.cellStride
        let originY = GridMetrics.verticalPadding + CGFloat(widget.row) * metrics.cellStride
        let width = CGFloat(widget.columnSpan) * metrics.cellSize + CGFloat(max(0, widget.columnSpan - 1)) * metrics.spacing
        let height = CGFloat(widget.rowSpan) * metrics.cellSize + CGFloat(max(0, widget.rowSpan - 1)) * metrics.spacing
        return CGRect(x: originX, y: originY, width: width, height: height)
    }

    static func snapOrigin(
        for widget: WidgetInstance,
        at cell: GridCell,
        metrics: GridMetrics
    ) -> (column: Int, row: Int) {
        let column = min(max(0, cell.column), metrics.columns - widget.columnSpan)
        let row = min(max(0, cell.row), metrics.rows - widget.rowSpan)
        return (column, row)
    }

    static func overlappingWidget(
        for candidate: WidgetInstance,
        in widgets: [WidgetInstance],
        excluding id: UUID? = nil
    ) -> WidgetInstance? {
        let candidateCells = cells(for: candidate)
        return widgets.first { other in
            guard other.id != id else { return false }
            return !cells(for: other).isDisjoint(with: candidateCells)
        }
    }

    static func cellAt(point: CGPoint, metrics: GridMetrics) -> GridCell? {
        let localX = point.x - GridMetrics.horizontalPadding
        let localY = point.y - GridMetrics.verticalPadding
        guard localX >= 0, localY >= 0 else { return nil }

        let column = Int(localX / metrics.cellStride)
        let row = Int(localY / metrics.cellStride)
        guard column >= 0, column < metrics.columns, row >= 0, row < metrics.rows else { return nil }
        return GridCell(column: column, row: row)
    }

    static func canPlace(
        _ widget: WidgetInstance,
        in widgets: [WidgetInstance],
        metrics: GridMetrics,
        excluding id: UUID? = nil
    ) -> Bool {
        guard widget.column >= 0, widget.row >= 0,
              widget.column + widget.columnSpan <= metrics.columns,
              widget.row + widget.rowSpan <= metrics.rows else {
            return false
        }

        let targetCells = cells(for: widget)
        for other in widgets where other.id != id {
            if !cells(for: other).isDisjoint(with: targetCells) {
                return false
            }
        }
        return true
    }

    static func firstFreeRect(
        columnSpan: Int,
        rowSpan: Int,
        widgets: [WidgetInstance],
        metrics: GridMetrics
    ) -> (column: Int, row: Int)? {
        for row in 0..<metrics.rows {
            for column in 0..<metrics.columns {
                let candidate = WidgetInstance(
                    typeId: "temp",
                    styleId: "temp",
                    column: column,
                    row: row,
                    columnSpan: columnSpan,
                    rowSpan: rowSpan
                )
                if canPlace(candidate, in: widgets, metrics: metrics) {
                    return (column, row)
                }
            }
        }
        return nil
    }

    static func snappedDelta(_ translation: CGFloat, cellStride: CGFloat) -> Int {
        Int((translation / cellStride).rounded())
    }

    static func resized(
        from start: WidgetInstance,
        handle: ResizeHandle,
        deltaColumn: Int,
        deltaRow: Int,
        metrics: GridMetrics,
        minColumnSpan: Int = 1,
        minRowSpan: Int = 1
    ) -> WidgetInstance? {
        var widget = start
        let minColumns = max(1, minColumnSpan)
        let minRows = max(1, minRowSpan)

        switch handle {
        case .bottomRight:
            widget.columnSpan = max(minColumns, start.columnSpan + deltaColumn)
            widget.rowSpan = max(minRows, start.rowSpan + deltaRow)
        case .bottomLeft:
            let newColumn = start.column + deltaColumn
            widget.column = max(0, min(newColumn, start.column + start.columnSpan - minColumns))
            widget.columnSpan = start.column + start.columnSpan - widget.column
            widget.rowSpan = max(minRows, start.rowSpan + deltaRow)
        case .topRight:
            widget.columnSpan = max(minColumns, start.columnSpan + deltaColumn)
            let newRow = start.row + deltaRow
            widget.row = max(0, min(newRow, start.row + start.rowSpan - minRows))
            widget.rowSpan = start.row + start.rowSpan - widget.row
        case .topLeft:
            let newColumn = start.column + deltaColumn
            let newRow = start.row + deltaRow
            widget.column = max(0, min(newColumn, start.column + start.columnSpan - minColumns))
            widget.row = max(0, min(newRow, start.row + start.rowSpan - minRows))
            widget.columnSpan = start.column + start.columnSpan - widget.column
            widget.rowSpan = start.row + start.rowSpan - widget.row
        case .right:
            widget.columnSpan = max(minColumns, start.columnSpan + deltaColumn)
        case .left:
            let newColumn = start.column + deltaColumn
            widget.column = max(0, min(newColumn, start.column + start.columnSpan - minColumns))
            widget.columnSpan = start.column + start.columnSpan - widget.column
        case .bottom:
            widget.rowSpan = max(minRows, start.rowSpan + deltaRow)
        case .top:
            let newRow = start.row + deltaRow
            widget.row = max(0, min(newRow, start.row + start.rowSpan - minRows))
            widget.rowSpan = start.row + start.rowSpan - widget.row
        }

        widget.columnSpan = max(minColumns, min(widget.columnSpan, metrics.columns - widget.column))
        widget.rowSpan = max(minRows, min(widget.rowSpan, metrics.rows - widget.row))

        guard widget.column >= 0, widget.row >= 0,
              widget.column + widget.columnSpan <= metrics.columns,
              widget.row + widget.rowSpan <= metrics.rows else {
            return nil
        }
        return widget
    }
}
