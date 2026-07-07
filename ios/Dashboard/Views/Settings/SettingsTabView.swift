import SwiftUI

struct SettingsTabView: View {
    @ObservedObject private var store = DashboardStore.shared

    @Binding var navigationPath: NavigationPath
    @State private var pendingType: WidgetTypeDefinition?
    @State private var pendingServerId: String?
    @State private var showStylePicker = false
    @State private var widgetToDelete: WidgetInstance?
    @State private var alertMessage: String?
    @State private var newDashboardName = ""
    @State private var showCreateDashboard = false
    @State private var editorMetrics = GridMetrics.computeEditor(from: 390)
    @ObservedObject private var widgetPreferences = WidgetPreferencesStore.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                cloudDashboardSection
                if store.isReadOnly {
                    Text("Tento dashboard je zdieľaný len na čítanie.")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 4)
                }
                dashboardSection
                gallerySection
                widgetPreferencesSection
                ServerManagementView(navigationPath: $navigationPath)
            }
            .padding()
        }
        .confirmationDialog("Vyberte štýl", isPresented: $showStylePicker, titleVisibility: .visible) {
            if let pendingType {
                ForEach(pendingType.styles) { style in
                    Button(style.name) {
                        if pendingType.typeId == "server" {
                            addServerWidget(type: pendingType, style: style)
                        } else {
                            addWidgetFromGallery(type: pendingType, style: style)
                        }
                    }
                }
            }
            Button("Zrušiť", role: .cancel) {
                pendingType = nil
                pendingServerId = nil
            }
        }
        .confirmationDialog("Nový dashboard", isPresented: $showCreateDashboard, titleVisibility: .visible) {
            TextField("Názov", text: $newDashboardName)
            Button("Vytvoriť") {
                Task {
                    do {
                        try await store.createDashboard(name: newDashboardName.isEmpty ? "Dashboard" : newDashboardName)
                        newDashboardName = ""
                    } catch {
                        alertMessage = error.localizedDescription
                    }
                }
            }
            Button("Zrušiť", role: .cancel) {}
        }
        .alert("Dashboard", isPresented: Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
        .confirmationDialog("Odstrániť widget?", isPresented: Binding(
            get: { widgetToDelete != nil },
            set: { if !$0 { widgetToDelete = nil } }
        ), titleVisibility: .visible) {
            Button("Odstrániť", role: .destructive) {
                if let widget = widgetToDelete {
                    removeWidget(widget)
                }
                widgetToDelete = nil
            }
            Button("Zrušiť", role: .cancel) {
                widgetToDelete = nil
            }
        }
    }

    private var cloudDashboardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Cloud dashboardy", systemImage: "icloud.fill")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(store.dashboards) { dashboard in
                        Button {
                            store.selectDashboard(id: dashboard.id)
                        } label: {
                            Text(dashboard.name)
                                .font(.caption.bold())
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    store.activeDashboardId == dashboard.id
                                        ? Color.accentColor.opacity(0.25)
                                        : Color.white.opacity(0.08),
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
                                .padding(10)
                                .background(Color.white.opacity(0.08), in: Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Text("\(store.ownedDashboards.count)/\(AppConfig.maxDashboards) vlastných dashboardov")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var dashboardSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Úprava dashboardu", systemImage: "square.grid.3x3.fill")
                .font(.headline)

            Text("Ťahajte widgety pre presun. Rohy a strany pre zmenu veľkosti.")
                .font(.caption)
                .foregroundStyle(.secondary)

            GeometryReader { geo in
                let metrics = GridMetrics.computeEditor(from: geo.size.width)
                EditableDashboardCanvas(
                    store: store,
                    metrics: metrics,
                    onDelete: { widgetToDelete = $0 }
                )
                .onAppear { editorMetrics = metrics }
                .onChange(of: geo.size.width) { _, width in
                    editorMetrics = GridMetrics.computeEditor(from: width)
                }
            }
            .frame(height: editorMetrics.canvasHeight())
            .opacity(store.isReadOnly ? 0.6 : 1)
            .allowsHitTesting(!store.isReadOnly)
        }
    }

    private var gallerySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Galéria widgetov", systemImage: "plus.rectangle.on.rectangle.fill")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                ForEach(WidgetRegistry.allTypes) { type in
                    galleryCard(for: type)
                }
            }
        }
    }

    private var widgetPreferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Nastavenia widgetov", systemImage: "slider.horizontal.3")
                .font(.headline)

            NavigationLink(value: WidgetSettingsRoute.worldClock) {
                SettingsMenuRow(
                    title: "Svetové hodiny",
                    subtitle: worldClockSubtitle,
                    icon: "globe"
                )
            }
            .buttonStyle(.plain)

            NavigationLink(value: WidgetSettingsRoute.contacts) {
                SettingsMenuRow(
                    title: "Kontakty",
                    subtitle: "\(widgetPreferences.preferences.favoriteContactIDs.count) vybraných",
                    icon: "person.2.fill"
                )
            }
            .buttonStyle(.plain)

            NavigationLink(value: WidgetSettingsRoute.exchange) {
                SettingsMenuRow(
                    title: "Kurzy mien",
                    subtitle: "Základná mena: \(widgetPreferences.preferences.exchangeBaseCurrency)",
                    icon: "coloncurrencysign.circle"
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var worldClockSubtitle: String {
        let names = widgetPreferences.preferences.worldClockCities
            .map { WorldClockCityCatalog.name(for: $0) }
        return names.isEmpty ? "Žiadne mestá" : names.joined(separator: ", ")
    }

    private func galleryCard(for type: WidgetTypeDefinition) -> some View {
        let style = type.styles.first
        let spec = type.primarySizeSpec
        let payload = WidgetDragPayload(
            typeId: type.typeId,
            styleId: style?.styleId ?? "default"
        )

        return Button {
            if type.typeId == "server" {
                if ServerMonitoringService.shared.servers.isEmpty {
                    alertMessage = "Najprv pridajte server v sekcii Monitorovanie servera."
                } else if ServerMonitoringService.shared.servers.count == 1 {
                    pendingServerId = ServerMonitoringService.shared.servers[0].id
                    pendingType = type
                    showStylePicker = true
                } else {
                    pendingType = type
                    showServerPicker(for: type)
                }
            } else {
                pendingType = type
                showStylePicker = true
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: type.icon)
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                    Spacer()
                    Text("\(spec.defaultColumnSpan)×\(spec.defaultRowSpan)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                Text(type.name)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
            }
            .padding(14)
            .glassCard(cornerRadius: 18)
        }
        .buttonStyle(.plain)
        .disabled(store.isReadOnly)
        .draggable(payload) {
            Text(type.name)
                .padding()
                .glassCard(cornerRadius: 16)
        }
    }

    private func showServerPicker(for type: WidgetTypeDefinition) {
        pendingServerId = ServerMonitoringService.shared.servers.first?.id
        pendingType = type
        showStylePicker = true
    }

    private func addWidgetFromGallery(type: WidgetTypeDefinition, style: WidgetStyleDefinition) {
        let spec = type.sizeSpec(for: style.styleId)
        guard let position = GridLayoutEngine.firstFreeRect(
            columnSpan: spec.defaultColumnSpan,
            rowSpan: spec.defaultRowSpan,
            widgets: store.layout.widgets,
            metrics: editorMetrics
        ) else {
            alertMessage = "Na dashboarde nie je voľné miesto."
            return
        }
        if store.addWidget(
            typeId: type.typeId,
            styleId: style.styleId,
            column: position.column,
            row: position.row,
            columnSpan: spec.defaultColumnSpan,
            rowSpan: spec.defaultRowSpan,
            metrics: editorMetrics
        ) {
            HapticHelper.success()
        }
        pendingType = nil
    }

    private func addServerWidget(type: WidgetTypeDefinition, style: WidgetStyleDefinition) {
        guard let serverId = pendingServerId else { return }
        let spec = type.sizeSpec(for: style.styleId)
        guard let position = GridLayoutEngine.firstFreeRect(
            columnSpan: spec.defaultColumnSpan,
            rowSpan: spec.defaultRowSpan,
            widgets: store.layout.widgets,
            metrics: editorMetrics
        ) else {
            alertMessage = "Na dashboarde nie je voľné miesto."
            return
        }
        if store.addWidget(
            typeId: type.typeId,
            styleId: style.styleId,
            column: position.column,
            row: position.row,
            columnSpan: spec.defaultColumnSpan,
            rowSpan: spec.defaultRowSpan,
            metrics: editorMetrics,
            config: ["serverId": serverId]
        ) {
            HapticHelper.success()
        }
        pendingType = nil
        pendingServerId = nil
    }

    private func removeWidget(_ widget: WidgetInstance) {
        HapticHelper.lightImpact()
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
            store.removeWidget(id: widget.id)
        }
    }
}
