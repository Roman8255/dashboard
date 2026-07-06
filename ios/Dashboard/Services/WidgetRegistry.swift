import Foundation

enum WidgetRegistry {
    static let allTypes: [WidgetTypeDefinition] = [
        WidgetTypeDefinition(
            typeId: "clock",
            name: "Hodiny",
            icon: "clock.fill",
            styles: [
                WidgetStyleDefinition(
                    styleId: "minimal",
                    name: "Minimal",
                    minColumnSpan: 1,
                    minRowSpan: 1,
                    defaultColumnSpan: 2,
                    defaultRowSpan: 1
                ),
                WidgetStyleDefinition(
                    styleId: "analog",
                    name: "Analógové",
                    minColumnSpan: 2,
                    minRowSpan: 2,
                    defaultColumnSpan: 2,
                    defaultRowSpan: 2
                ),
                WidgetStyleDefinition(
                    styleId: "digital",
                    name: "Digitálne",
                    minColumnSpan: 2,
                    minRowSpan: 1,
                    defaultColumnSpan: 2,
                    defaultRowSpan: 1
                )
            ]
        ),
        WidgetTypeDefinition(
            typeId: "weather",
            name: "Počasie",
            icon: "cloud.sun.fill",
            styles: [
                WidgetStyleDefinition(
                    styleId: "compact",
                    name: "Kompaktné",
                    minColumnSpan: 1,
                    minRowSpan: 1,
                    defaultColumnSpan: 1,
                    defaultRowSpan: 1
                ),
                WidgetStyleDefinition(
                    styleId: "detailed",
                    name: "Detailné",
                    minColumnSpan: 2,
                    minRowSpan: 2,
                    defaultColumnSpan: 2,
                    defaultRowSpan: 2
                )
            ]
        ),
        WidgetTypeDefinition(
            typeId: "spotify",
            name: "Spotify",
            icon: "music.note",
            styles: [
                WidgetStyleDefinition(
                    styleId: "nowPlaying",
                    name: "Prehrávač",
                    minColumnSpan: 3,
                    minRowSpan: 2,
                    defaultColumnSpan: 3,
                    defaultRowSpan: 2
                ),
                WidgetStyleDefinition(
                    styleId: "albumArt",
                    name: "Obal + ovládanie",
                    minColumnSpan: 2,
                    minRowSpan: 2,
                    defaultColumnSpan: 2,
                    defaultRowSpan: 3
                )
            ]
        ),
        WidgetTypeDefinition(
            typeId: "photos",
            name: "Fotky",
            icon: "photo.fill",
            styles: [
                WidgetStyleDefinition(
                    styleId: "single",
                    name: "Jedna fotka",
                    minColumnSpan: 2,
                    minRowSpan: 2,
                    defaultColumnSpan: 2,
                    defaultRowSpan: 2
                ),
                WidgetStyleDefinition(
                    styleId: "collage",
                    name: "Koláž",
                    minColumnSpan: 2,
                    minRowSpan: 2,
                    defaultColumnSpan: 2,
                    defaultRowSpan: 2
                )
            ]
        ),
        WidgetTypeDefinition(
            typeId: "albums",
            name: "Albumy",
            icon: "rectangle.stack.fill",
            styles: [
                WidgetStyleDefinition(
                    styleId: "grid",
                    name: "Mriežka",
                    minColumnSpan: 2,
                    minRowSpan: 2,
                    defaultColumnSpan: 2,
                    defaultRowSpan: 2
                ),
                WidgetStyleDefinition(
                    styleId: "cover",
                    name: "Obal",
                    minColumnSpan: 2,
                    minRowSpan: 2,
                    defaultColumnSpan: 2,
                    defaultRowSpan: 2
                )
            ]
        ),
        WidgetTypeDefinition(
            typeId: "agenda",
            name: "Plán dňa",
            icon: "calendar",
            styles: [
                WidgetStyleDefinition(
                    styleId: "next",
                    name: "Ďalšia schôdzka",
                    minColumnSpan: 1,
                    minRowSpan: 2,
                    defaultColumnSpan: 1,
                    defaultRowSpan: 2
                ),
                WidgetStyleDefinition(
                    styleId: "list",
                    name: "Zoznam",
                    minColumnSpan: 2,
                    minRowSpan: 2,
                    defaultColumnSpan: 2,
                    defaultRowSpan: 2
                )
            ]
        ),
        WidgetTypeDefinition(
            typeId: "tasks",
            name: "Úlohy",
            icon: "checklist",
            styles: [
                WidgetStyleDefinition(
                    styleId: "compact",
                    name: "Kompaktné",
                    minColumnSpan: 1,
                    minRowSpan: 2,
                    defaultColumnSpan: 1,
                    defaultRowSpan: 2
                ),
                WidgetStyleDefinition(
                    styleId: "list",
                    name: "Zoznam",
                    minColumnSpan: 2,
                    minRowSpan: 2,
                    defaultColumnSpan: 2,
                    defaultRowSpan: 2
                )
            ]
        ),
        WidgetTypeDefinition(
            typeId: "worldClock",
            name: "Svetové hodiny",
            icon: "globe",
            styles: [
                WidgetStyleDefinition(
                    styleId: "dual",
                    name: "Dvojica",
                    minColumnSpan: 1,
                    minRowSpan: 2,
                    defaultColumnSpan: 1,
                    defaultRowSpan: 2
                ),
                WidgetStyleDefinition(
                    styleId: "triple",
                    name: "Trojica",
                    minColumnSpan: 2,
                    minRowSpan: 2,
                    defaultColumnSpan: 2,
                    defaultRowSpan: 2
                )
            ]
        ),
        WidgetTypeDefinition(
            typeId: "exchange",
            name: "Kurzy mien",
            icon: "coloncurrencysign.circle",
            styles: [
                WidgetStyleDefinition(
                    styleId: "compact",
                    name: "Kompaktné",
                    minColumnSpan: 1,
                    minRowSpan: 1,
                    defaultColumnSpan: 1,
                    defaultRowSpan: 1
                ),
                WidgetStyleDefinition(
                    styleId: "board",
                    name: "Prehľad",
                    minColumnSpan: 2,
                    minRowSpan: 2,
                    defaultColumnSpan: 2,
                    defaultRowSpan: 2
                )
            ]
        ),
        WidgetTypeDefinition(
            typeId: "contacts",
            name: "Kontakty",
            icon: "person.2.fill",
            styles: [
                WidgetStyleDefinition(
                    styleId: "row",
                    name: "Riadok",
                    minColumnSpan: 2,
                    minRowSpan: 1,
                    defaultColumnSpan: 2,
                    defaultRowSpan: 1
                ),
                WidgetStyleDefinition(
                    styleId: "grid",
                    name: "Mriežka",
                    minColumnSpan: 2,
                    minRowSpan: 2,
                    defaultColumnSpan: 2,
                    defaultRowSpan: 2
                )
            ]
        ),
        WidgetTypeDefinition(
            typeId: "pomodoro",
            name: "Pomodoro",
            icon: "timer",
            styles: [
                WidgetStyleDefinition(
                    styleId: "compact",
                    name: "Kompaktné",
                    minColumnSpan: 1,
                    minRowSpan: 2,
                    defaultColumnSpan: 1,
                    defaultRowSpan: 2
                ),
                WidgetStyleDefinition(
                    styleId: "session",
                    name: "Session",
                    minColumnSpan: 2,
                    minRowSpan: 2,
                    defaultColumnSpan: 2,
                    defaultRowSpan: 2
                )
            ]
        ),
        WidgetTypeDefinition(
            typeId: "network",
            name: "Sieť",
            icon: "wifi",
            styles: [
                WidgetStyleDefinition(
                    styleId: "icon",
                    name: "Ikona",
                    minColumnSpan: 1,
                    minRowSpan: 1,
                    defaultColumnSpan: 1,
                    defaultRowSpan: 1
                ),
                WidgetStyleDefinition(
                    styleId: "speed",
                    name: "Rýchlosť",
                    minColumnSpan: 2,
                    minRowSpan: 1,
                    defaultColumnSpan: 2,
                    defaultRowSpan: 1
                )
            ]
        ),
        WidgetTypeDefinition(
            typeId: "server",
            name: "Server",
            icon: "server.rack",
            styles: [
                WidgetStyleDefinition(
                    styleId: "compact",
                    name: "Kompaktný",
                    minColumnSpan: 2,
                    minRowSpan: 1,
                    defaultColumnSpan: 2,
                    defaultRowSpan: 1
                ),
                WidgetStyleDefinition(
                    styleId: "detailed",
                    name: "Detailný",
                    minColumnSpan: 2,
                    minRowSpan: 2,
                    defaultColumnSpan: 2,
                    defaultRowSpan: 2
                )
            ]
        )
    ]

    static func type(for typeId: String) -> WidgetTypeDefinition? {
        allTypes.first { $0.typeId == typeId }
    }

    static func sizeSpec(typeId: String, styleId: String) -> WidgetSizeSpec {
        type(for: typeId)?.sizeSpec(for: styleId) ?? .unit
    }

    static func styleName(typeId: String, styleId: String) -> String {
        guard let type = type(for: typeId),
              let style = type.styles.first(where: { $0.styleId == styleId }) else {
            return styleId
        }
        return style.name
    }

    static func widgetFittingMinimums(_ widget: WidgetInstance) -> WidgetInstance {
        let spec = sizeSpec(typeId: widget.typeId, styleId: widget.styleId)
        var updated = widget
        updated.columnSpan = max(updated.columnSpan, spec.minColumnSpan)
        updated.rowSpan = max(updated.rowSpan, spec.minRowSpan)
        updated.columnSpan = min(updated.columnSpan, GridMetrics.columns)
        updated.column = min(updated.column, GridMetrics.columns - updated.columnSpan)
        return updated
    }
}
