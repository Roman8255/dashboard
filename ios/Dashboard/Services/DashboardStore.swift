import Foundation

@MainActor
final class DashboardStore: ObservableObject {
    static let shared = DashboardStore()

    @Published private(set) var dashboards: [CloudDashboard] = []
    @Published private(set) var activeDashboardId: String?
    @Published private(set) var layout: DashboardLayout = .empty
    @Published private(set) var isLoading = false
    @Published private(set) var isReadOnly = false
    @Published var syncError: String?

    private let defaults = UserDefaults.standard
    private var currentUserId: String?
    private var saveTask: Task<Void, Never>?

    private init() {}

    var activeDashboard: CloudDashboard? {
        guard let activeDashboardId else { return nil }
        return dashboards.first { $0.id == activeDashboardId }
    }

    var ownedDashboards: [CloudDashboard] {
        dashboards.filter { !$0.isShared }
    }

    var canCreateDashboard: Bool {
        ownedDashboards.count < AppConfig.maxDashboards
    }

    func reset() {
        dashboards = []
        activeDashboardId = nil
        layout = .empty
        currentUserId = nil
        isReadOnly = false
    }

    func load(for user: LocalUser) async {
        currentUserId = user.appleUserId
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await DashboardSyncService.shared.fetchDashboards()
            var all = result.owned + result.shared
            all.sort { lhs, rhs in
                if lhs.isShared != rhs.isShared { return !lhs.isShared }
                return lhs.sortOrder < rhs.sortOrder
            }
            dashboards = all

            if dashboards.isEmpty, canCreateDashboard {
                let created = try await DashboardSyncService.shared.createDashboard(name: "Môj dashboard")
                dashboards = [created]
            }

            let savedActive = defaults.string(forKey: activeDashboardKey(for: user.appleUserId))
            if let savedActive, dashboards.contains(where: { $0.id == savedActive }) {
                selectDashboard(id: savedActive, persist: false)
            } else if let first = dashboards.first {
                selectDashboard(id: first.id, persist: true)
            } else {
                layout = .empty
            }
            syncError = nil
        } catch {
            loadLocalCache(for: user.appleUserId)
            syncError = error.localizedDescription
        }
    }

    func selectDashboard(id: String, persist: Bool = true) {
        guard let dashboard = dashboards.first(where: { $0.id == id }) else { return }
        activeDashboardId = id
        layout = normalizeLayout(dashboard.layout)
        isReadOnly = dashboard.isReadOnly
        if persist, let userId = currentUserId {
            defaults.set(id, forKey: activeDashboardKey(for: userId))
        }
        cacheLayout()
    }

    func createDashboard(name: String) async throws {
        guard canCreateDashboard else { return }
        let created = try await DashboardSyncService.shared.createDashboard(name: name)
        dashboards.append(created)
        selectDashboard(id: created.id)
    }

    func renameActiveDashboard(_ name: String) async throws {
        guard let id = activeDashboardId, !isReadOnly else { return }
        let updated = try await DashboardSyncService.shared.updateDashboard(id: id, name: name, layout: nil)
        replaceDashboard(updated)
    }

    func deleteDashboard(id: String) async throws {
        try await DashboardSyncService.shared.deleteDashboard(id: id)
        dashboards.removeAll { $0.id == id }
        if activeDashboardId == id {
            if let next = dashboards.first {
                selectDashboard(id: next.id)
            } else if canCreateDashboard {
                try await createDashboard(name: "Môj dashboard")
            } else {
                activeDashboardId = nil
                layout = .empty
            }
        }
    }

    private func normalizeLayout(_ source: DashboardLayout) -> DashboardLayout {
        var widgets = source.widgets.map { WidgetRegistry.widgetFittingMinimums($0) }
        var normalized: [WidgetInstance] = []

        for var widget in widgets {
            if GridLayoutEngine.canPlace(widget, in: normalized, metrics: editorMetricsForNormalization()) {
                normalized.append(widget)
                continue
            }

            widget.columnSpan = min(widget.columnSpan, GridMetrics.columns)
            widget.column = min(widget.column, GridMetrics.columns - widget.columnSpan)
            if GridLayoutEngine.canPlace(widget, in: normalized, metrics: editorMetricsForNormalization()) {
                normalized.append(widget)
            }
        }

        return DashboardLayout(widgets: normalized)
    }

    private func editorMetricsForNormalization() -> GridMetrics {
        GridMetrics.computeEditor(from: 390, rows: 20)
    }

    func save() {
        guard !isReadOnly, let id = activeDashboardId else { return }
        cacheLayout()
        if let index = dashboards.firstIndex(where: { $0.id == id }) {
            dashboards[index].layout = layout
        }

        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            do {
                let updated = try await DashboardSyncService.shared.updateDashboard(
                    id: id,
                    name: nil,
                    layout: layout
                )
                replaceDashboard(updated)
                syncError = nil
            } catch {
                syncError = error.localizedDescription
            }
        }
    }

    @discardableResult
    func addWidget(
        typeId: String,
        styleId: String,
        column: Int,
        row: Int,
        metrics: GridMetrics,
        config: [String: String] = [:]
    ) -> Bool {
        let spec = WidgetRegistry.sizeSpec(typeId: typeId, styleId: styleId)
        return addWidget(
            typeId: typeId,
            styleId: styleId,
            column: column,
            row: row,
            columnSpan: spec.defaultColumnSpan,
            rowSpan: spec.defaultRowSpan,
            metrics: metrics,
            config: config
        )
    }

    @discardableResult
    func addWidget(
        typeId: String,
        styleId: String,
        column: Int,
        row: Int,
        columnSpan: Int,
        rowSpan: Int,
        metrics: GridMetrics,
        config: [String: String] = [:]
    ) -> Bool {
        guard !isReadOnly else { return false }
        let spec = WidgetRegistry.sizeSpec(typeId: typeId, styleId: styleId)
        let widget = WidgetInstance(
            typeId: typeId,
            styleId: styleId,
            column: column,
            row: row,
            columnSpan: max(columnSpan, spec.minColumnSpan),
            rowSpan: max(rowSpan, spec.minRowSpan),
            config: config
        )
        guard GridLayoutEngine.canPlace(widget, in: layout.widgets, metrics: metrics) else {
            return false
        }
        var updated = layout
        updated.widgets.append(widget)
        layout = updated
        save()
        return true
    }

    func removeWidget(id: UUID) {
        guard !isReadOnly else { return }
        var updated = layout
        updated.widgets.removeAll { $0.id == id }
        layout = updated
        save()
    }

    @discardableResult
    func moveWidget(id: UUID, to column: Int, row: Int, metrics: GridMetrics) -> Bool {
        guard !isReadOnly else { return false }
        guard let index = layout.widgets.firstIndex(where: { $0.id == id }) else { return false }
        var widget = layout.widgets[index]
        widget.column = column
        widget.row = row
        guard GridLayoutEngine.canPlace(widget, in: layout.widgets, metrics: metrics, excluding: id) else {
            return false
        }
        var updated = layout
        updated.widgets[index] = widget
        layout = updated
        save()
        return true
    }

    @discardableResult
    func moveOrSwapWidget(id: UUID, to column: Int, row: Int, metrics: GridMetrics) -> Bool {
        guard !isReadOnly else { return false }
        guard let index = layout.widgets.firstIndex(where: { $0.id == id }) else { return false }

        var moving = layout.widgets[index]
        moving.column = column
        moving.row = row

        if GridLayoutEngine.canPlace(moving, in: layout.widgets, metrics: metrics, excluding: id) {
            return moveWidget(id: id, to: column, row: row, metrics: metrics)
        }

        if let blocker = GridLayoutEngine.overlappingWidget(for: moving, in: layout.widgets, excluding: id),
           let blockerIndex = layout.widgets.firstIndex(where: { $0.id == blocker.id }) {
            var updated = layout
            let originColumn = updated.widgets[index].column
            let originRow = updated.widgets[index].row

            updated.widgets[index].column = updated.widgets[blockerIndex].column
            updated.widgets[index].row = updated.widgets[blockerIndex].row
            updated.widgets[blockerIndex].column = originColumn
            updated.widgets[blockerIndex].row = originRow

            guard GridLayoutEngine.canPlace(updated.widgets[index], in: updated.widgets, metrics: metrics, excluding: updated.widgets[index].id),
                  GridLayoutEngine.canPlace(updated.widgets[blockerIndex], in: updated.widgets, metrics: metrics, excluding: updated.widgets[blockerIndex].id) else {
                return false
            }

            layout = updated
            save()
            return true
        }

        return false
    }

    @discardableResult
    func resizeWidget(id: UUID, to widget: WidgetInstance, metrics: GridMetrics) -> Bool {
        guard !isReadOnly else { return false }
        guard layout.widgets.contains(where: { $0.id == id }) else { return false }
        var resized = WidgetRegistry.widgetFittingMinimums(widget)
        guard GridLayoutEngine.canPlace(resized, in: layout.widgets, metrics: metrics, excluding: id) else {
            return false
        }
        var updated = layout
        guard let index = updated.widgets.firstIndex(where: { $0.id == id }) else { return false }
        updated.widgets[index] = resized
        layout = updated
        save()
        return true
    }

    func widget(at column: Int, row: Int) -> WidgetInstance? {
        layout.widgets.first { widget in
            column >= widget.column && column < widget.column + widget.columnSpan &&
            row >= widget.row && row < widget.row + widget.rowSpan
        }
    }

    func hasSpace(for columnSpan: Int, rowSpan: Int, metrics: GridMetrics) -> Bool {
        GridLayoutEngine.firstFreeRect(
            columnSpan: columnSpan,
            rowSpan: rowSpan,
            widgets: layout.widgets,
            metrics: metrics
        ) != nil
    }

    private func replaceDashboard(_ dashboard: CloudDashboard) {
        if let index = dashboards.firstIndex(where: { $0.id == dashboard.id }) {
            dashboards[index] = dashboard
        }
    }

    private func cacheLayout() {
        guard let userId = currentUserId, let id = activeDashboardId else { return }
        let key = layoutCacheKey(userId: userId, dashboardId: id)
        if let data = try? JSONEncoder().encode(layout) {
            defaults.set(data, forKey: key)
        }
    }

    private func loadLocalCache(for userId: String) {
        let active = defaults.string(forKey: activeDashboardKey(for: userId))
        if let active,
           let data = defaults.data(forKey: layoutCacheKey(userId: userId, dashboardId: active)),
           let decoded = try? JSONDecoder().decode(DashboardLayout.self, from: data) {
            activeDashboardId = active
            layout = normalizeLayout(decoded)
        } else {
            layout = .empty
        }
    }

    private func activeDashboardKey(for userId: String) -> String {
        "active_dashboard_\(userId)"
    }

    private func layoutCacheKey(userId: String, dashboardId: String) -> String {
        "dashboard_layout_\(userId)_\(dashboardId)"
    }
}
