import Foundation

struct GridCell: Hashable, Codable {
    let column: Int
    let row: Int
}

struct WidgetInstance: Identifiable, Codable, Equatable {
    let id: UUID
    let typeId: String
    let styleId: String
    var column: Int
    var row: Int
    var columnSpan: Int
    var rowSpan: Int
    var config: [String: String]

    init(
        id: UUID = UUID(),
        typeId: String,
        styleId: String,
        column: Int,
        row: Int,
        columnSpan: Int = 1,
        rowSpan: Int = 1,
        config: [String: String] = [:]
    ) {
        self.id = id
        self.typeId = typeId
        self.styleId = styleId
        self.column = column
        self.row = row
        self.columnSpan = max(1, columnSpan)
        self.rowSpan = max(1, rowSpan)
        self.config = config
    }

    enum CodingKeys: String, CodingKey {
        case id, typeId, styleId, column, row, columnSpan, rowSpan, config, slotIndex
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        typeId = try container.decode(String.self, forKey: .typeId)
        styleId = try container.decode(String.self, forKey: .styleId)

        if let column = try? container.decode(Int.self, forKey: .column),
           let row = try? container.decode(Int.self, forKey: .row) {
            self.column = column
            self.row = row
            self.columnSpan = max(1, try container.decodeIfPresent(Int.self, forKey: .columnSpan) ?? 1)
            self.rowSpan = max(1, try container.decodeIfPresent(Int.self, forKey: .rowSpan) ?? 1)
            self.config = try container.decodeIfPresent([String: String].self, forKey: .config) ?? [:]
        } else if let slotIndex = try? container.decode(Int.self, forKey: .slotIndex) {
            column = slotIndex % GridMetrics.columns
            row = slotIndex / GridMetrics.columns
            columnSpan = 1
            rowSpan = 1
            config = [:]
        } else {
            column = 0
            row = 0
            columnSpan = 1
            rowSpan = 1
            config = [:]
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(typeId, forKey: .typeId)
        try container.encode(styleId, forKey: .styleId)
        try container.encode(column, forKey: .column)
        try container.encode(row, forKey: .row)
        try container.encode(columnSpan, forKey: .columnSpan)
        try container.encode(rowSpan, forKey: .rowSpan)
        if !config.isEmpty {
            try container.encode(config, forKey: .config)
        }
    }
}

struct DashboardLayout: Codable, Equatable {
    var widgets: [WidgetInstance]

    static let empty = DashboardLayout(widgets: [])
}

struct WidgetStyleDefinition: Identifiable, Hashable {
    let styleId: String
    let name: String
    let minColumnSpan: Int
    let minRowSpan: Int
    let defaultColumnSpan: Int
    let defaultRowSpan: Int

    var id: String { styleId }

    init(
        styleId: String,
        name: String,
        minColumnSpan: Int = 1,
        minRowSpan: Int = 1,
        defaultColumnSpan: Int? = nil,
        defaultRowSpan: Int? = nil
    ) {
        self.styleId = styleId
        self.name = name
        self.minColumnSpan = max(1, minColumnSpan)
        self.minRowSpan = max(1, minRowSpan)
        self.defaultColumnSpan = max(self.minColumnSpan, defaultColumnSpan ?? self.minColumnSpan)
        self.defaultRowSpan = max(self.minRowSpan, defaultRowSpan ?? self.minRowSpan)
    }
}

struct WidgetSizeSpec: Hashable {
    let minColumnSpan: Int
    let minRowSpan: Int
    let defaultColumnSpan: Int
    let defaultRowSpan: Int

    static let unit = WidgetSizeSpec(minColumnSpan: 1, minRowSpan: 1, defaultColumnSpan: 1, defaultRowSpan: 1)
}

struct WidgetTypeDefinition: Identifiable, Hashable {
    let typeId: String
    let name: String
    let icon: String
    let styles: [WidgetStyleDefinition]

    var id: String { typeId }

    func sizeSpec(for styleId: String) -> WidgetSizeSpec {
        guard let style = styles.first(where: { $0.styleId == styleId }) ?? styles.first else {
            return .unit
        }
        return WidgetSizeSpec(
            minColumnSpan: style.minColumnSpan,
            minRowSpan: style.minRowSpan,
            defaultColumnSpan: style.defaultColumnSpan,
            defaultRowSpan: style.defaultRowSpan
        )
    }

    var primarySizeSpec: WidgetSizeSpec {
        sizeSpec(for: styles.first?.styleId ?? "default")
    }
}

enum DashboardGridMode {
    case display
    case edit
}

enum ResizeHandle: CaseIterable, Hashable {
    case topLeft, top, topRight, right, bottomRight, bottom, bottomLeft, left

    var isCorner: Bool {
        switch self {
        case .topLeft, .topRight, .bottomRight, .bottomLeft: return true
        default: return false
        }
    }
}

struct GridMetrics: Equatable {
    let columns: Int
    let rows: Int
    let cellSize: CGFloat
    let spacing: CGFloat
    let totalSlots: Int

    static let columns = 4
    static let spacing: CGFloat = 10
    static let horizontalPadding: CGFloat = 16
    static let verticalPadding: CGFloat = 16

    var cellStride: CGFloat { cellSize + spacing }

    static func compute(in size: CGSize) -> GridMetrics {
        let columns = Self.columns
        let spacing = Self.spacing
        let horizontalPadding = Self.horizontalPadding
        let verticalPadding = Self.verticalPadding

        let availableWidth = size.width - horizontalPadding * 2 - spacing * CGFloat(columns - 1)
        let cellSize = max(0, availableWidth / CGFloat(columns))
        let rowStride = cellSize + spacing
        let availableHeight = size.height - verticalPadding * 2
        let rows = max(1, Int((availableHeight + spacing) / rowStride))

        return GridMetrics(
            columns: columns,
            rows: rows,
            cellSize: cellSize,
            spacing: spacing,
            totalSlots: columns * rows
        )
    }

    static func computeEditor(from width: CGFloat, rows: Int = 10) -> GridMetrics {
        let columns = Self.columns
        let spacing = Self.spacing
        let horizontalPadding = Self.horizontalPadding
        let availableWidth = width - horizontalPadding * 2 - spacing * CGFloat(columns - 1)
        let cellSize = max(0, availableWidth / CGFloat(columns))
        return GridMetrics(
            columns: columns,
            rows: rows,
            cellSize: cellSize,
            spacing: spacing,
            totalSlots: columns * rows
        )
    }

    func canvasHeight() -> CGFloat {
        CGFloat(rows) * cellSize + CGFloat(max(0, rows - 1)) * spacing + Self.verticalPadding * 2
    }
}
