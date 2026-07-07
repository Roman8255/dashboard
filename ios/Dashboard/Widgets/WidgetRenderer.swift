import SwiftUI

struct WidgetRenderer: View {
    let widget: WidgetInstance
    var compact: Bool = false

    var body: some View {
        switch widget.typeId {
        case "clock":
            ClockWidgetView(styleId: widget.styleId)
        case "weather":
            WeatherWidgetView(styleId: widget.styleId)
        case "spotify":
            SpotifyWidgetView(styleId: widget.styleId)
        case "photos":
            PhotosWidgetView(styleId: widget.styleId)
        case "albums":
            AlbumsWidgetView(styleId: widget.styleId)
        case "agenda":
            AgendaWidgetView(styleId: widget.styleId)
        case "tasks":
            TasksWidgetView(styleId: widget.styleId)
        case "worldClock":
            WorldClockWidgetView(styleId: widget.styleId)
        case "exchange":
            ExchangeWidgetView(styleId: widget.styleId)
        case "contacts":
            ContactsWidgetView(styleId: widget.styleId)
        case "pomodoro":
            PomodoroWidgetView(widgetId: widget.id, styleId: widget.styleId)
        case "network":
            NetworkWidgetView(styleId: widget.styleId)
        case "server":
            ServerWidgetView(widget: widget)
        default:
            PlaceholderWidgetView(typeId: widget.typeId, styleId: widget.styleId)
        }
    }
}
