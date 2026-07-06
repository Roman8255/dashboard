import SwiftUI

struct AgendaWidgetView: View {
    let styleId: String
    @ObservedObject private var agenda = AgendaService.shared

    var body: some View {
        WidgetCard {
            Group {
                if agenda.isLoading {
                    loadingView
                } else if agenda.needsPermission {
                    permissionView
                } else if agenda.items.isEmpty {
                    emptyView
                } else if styleId == "list" {
                    listView
                } else {
                    nextView
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            openCalendarApp()
        }
        .onLongPressGesture {
            Task { await agenda.refresh(force: true) }
        }
        .task { await agenda.refreshIfNeeded() }
    }

    private var loadingView: some View {
        VStack(spacing: 8) {
            ProgressView().tint(.accentColor)
            Text("Načítavam plán…")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(8)
    }

    private var permissionView: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.title2)
                .foregroundStyle(.orange)
            Text("Povoliť kalendár")
                .font(.caption2.bold())
            openSettingsButton
        }
        .padding(8)
    }

    private var emptyView: some View {
        VStack(spacing: 6) {
            Image(systemName: "calendar")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Dnes nič naplánované")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(8)
    }

    private var nextView: some View {
        let item = agenda.items.first!
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle().fill(item.calendarColor).frame(width: 8, height: 8)
                Text("Ďalej")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                if let countdown = item.countdownText {
                    Text(countdown)
                        .font(.caption2.bold())
                        .foregroundStyle(Color.accentColor)
                }
            }
            Text(item.title)
                .font(.subheadline.bold())
                .lineLimit(2)
            Text(timeLabel(for: item))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
    }

    private var listView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Plán dňa")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            ForEach(agenda.items.prefix(5)) { item in
                HStack(spacing: 8) {
                    Circle().fill(item.calendarColor).frame(width: 6, height: 6)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(item.title)
                            .font(.caption.bold())
                            .lineLimit(1)
                        Text(timeLabel(for: item))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
    }

    private var openSettingsButton: some View {
        Button("Otvoriť Nastavenia") {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }
        .font(.caption2.bold())
    }

    private func timeLabel(for item: AgendaItem) -> String {
        if item.isAllDay { return "Celý deň" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "sk")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: item.startDate)
    }

    private func openCalendarApp() {
        if let url = URL(string: "calshow://") {
            UIApplication.shared.open(url)
        }
    }
}
