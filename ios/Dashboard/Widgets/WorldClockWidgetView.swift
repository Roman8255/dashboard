import SwiftUI

struct WorldClockWidgetView: View {
    let styleId: String
    @ObservedObject private var worldClock = WorldClockService.shared
    @ObservedObject private var preferences = WidgetPreferencesStore.shared

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            WidgetCard {
                if worldClock.entries.isEmpty {
                    emptyView
                } else if styleId == "triple" {
                    tripleView(date: context.date)
                } else {
                    dualView(date: context.date)
                }
            }
        }
        .onChange(of: preferences.preferences.worldClockCities) { _, _ in
            worldClock.reload()
        }
        .onAppear { worldClock.reload() }
    }

    private var emptyView: some View {
        VStack(spacing: 6) {
            Image(systemName: "globe")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Nastavte mestá")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(8)
    }

    private func dualView(date: Date) -> some View {
        let local = TimeZone.current
        let remote = worldClock.entries.first
        return HStack(spacing: 12) {
            clockColumn(title: "Tu", timeZone: local, date: date, showBusiness: false)
            if let remote {
                Divider().opacity(0.3)
                clockColumn(
                    title: remote.cityName,
                    timeZone: remote.timeZone,
                    date: date,
                    showBusiness: true,
                    entry: remote
                )
            }
        }
        .padding(8)
    }

    private func tripleView(date: Date) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(worldClock.entries.prefix(3)) { entry in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.cityName)
                            .font(.caption.bold())
                        Text(worldClock.offsetDescription(for: entry))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(timeString(for: date, in: entry.timeZone))
                        .font(.headline.monospacedDigit())
                    Circle()
                        .fill(worldClock.isBusinessHours(for: entry, at: date) ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
    }

    private func clockColumn(
        title: String,
        timeZone: TimeZone,
        date: Date,
        showBusiness: Bool,
        entry: WorldClockEntry? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Text(timeString(for: date, in: timeZone))
                .font(.title3.bold().monospacedDigit())
            if showBusiness, let entry {
                HStack(spacing: 4) {
                    Circle()
                        .fill(worldClock.isBusinessHours(for: entry, at: date) ? Color.green : Color.orange)
                        .frame(width: 6, height: 6)
                    Text(worldClock.isBusinessHours(for: entry, at: date) ? "Prac. čas" : "Mimo")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func timeString(for date: Date, in timeZone: TimeZone) -> String {
        var formatter = DateFormatter()
        formatter.locale = Locale(identifier: "sk")
        formatter.timeZone = timeZone
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
