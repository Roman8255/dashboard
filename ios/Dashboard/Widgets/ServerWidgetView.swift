import SwiftUI

struct ServerWidgetView: View {
    let widget: WidgetInstance

    @State private var metrics: ServerMetricsSnapshot?
    @State private var serverName = "Server"
    @State private var hostname: String?
    @State private var online = false
    @State private var isLoading = true
    @State private var loadFailed = false

    private var serverId: String? { widget.config["serverId"] }

    var body: some View {
        WidgetCard {
            Group {
                if serverId == nil {
                    unconfiguredView
                } else if isLoading {
                    loadingView
                } else if widget.styleId == "detailed" {
                    detailedView
                } else {
                    compactView
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            Task { await refresh() }
        }
        .task(id: serverId) {
            await refresh()
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30_000_000_000)
                await refresh()
            }
        }
    }

    private var unconfiguredView: some View {
        VStack(spacing: 6) {
            Image(systemName: "server.rack")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Nastavte server")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(8)
    }

    private var loadingView: some View {
        VStack(spacing: 8) {
            ProgressView()
                .tint(.accentColor)
            Text("Načítavam…")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(8)
    }

    private var compactView: some View {
        HStack(spacing: 10) {
            Image(systemName: "server.rack")
                .font(.title3)
                .foregroundStyle(online ? Color.accentColor : Color.red.opacity(0.8))

            VStack(alignment: .leading, spacing: 4) {
                Text(serverName)
                    .font(.caption.bold())
                    .lineLimit(1)
                HStack(spacing: 10) {
                    compactMetricLabel("CPU", average: metrics?.cpuPercent, maximum: metrics?.cpuPercentMax)
                    compactMetricLabel("RAM", average: metrics?.ramPercent, maximum: metrics?.ramPercentMax)
                }
            }

            Spacer(minLength: 0)

            statusDot
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
    }

    private var detailedView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "server.rack")
                    .foregroundStyle(Color.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(serverName)
                        .font(.caption.bold())
                        .lineLimit(1)
                    if let hostname, !hostname.isEmpty {
                        Text(hostname)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                Text(online ? "Online" : "Offline")
                    .font(.caption2.bold())
                    .foregroundStyle(online ? .green : .red)
            }

            if online, metrics != nil {
                VStack(spacing: 8) {
                    metricBar(title: "CPU", average: metrics?.cpuPercent, maximum: metrics?.cpuPercentMax)
                    metricBar(title: "RAM", average: metrics?.ramPercent, maximum: metrics?.ramPercentMax)
                    metricBar(title: "Disk", average: metrics?.diskUsedPercent, maximum: metrics?.diskUsedPercentMax)
                }

                loadRow
            } else if online {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Čakám na dáta od agenta")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text(loadFailed ? "Nepodarilo sa načítať stav" : "Agent neodpovedá")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
    }

    private var loadRow: some View {
        HStack {
            Text("Load")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer()
            Text(formatted(metrics?.loadAvg))
                .font(.caption.bold().monospacedDigit())
            if let maxLoad = metrics?.loadAvgMax, let avg = metrics?.loadAvg, maxLoad > avg + 0.05 {
                Text("max \(formatted(maxLoad))")
                    .font(.caption2.bold().monospacedDigit())
                    .foregroundStyle(.red)
            }
        }
    }

    private var statusDot: some View {
        Circle()
            .fill(online ? Color.green : Color.red)
            .frame(width: 8, height: 8)
    }

    private func compactMetricLabel(_ title: String, average: Double?, maximum: Double?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            HStack(spacing: 3) {
                Text("\(formatted(average))%")
                    .font(.caption.monospacedDigit().bold())
                if let maximum, let average, maximum > average + 0.5 {
                    Text("|\(formatted(maximum))")
                        .font(.caption2.monospacedDigit().bold())
                        .foregroundStyle(.red)
                }
            }
        }
    }

    private func metricBar(title: String, average: Double?, maximum: Double?) -> some View {
        let avg = min(average ?? 0, 100)
        let maxVal = min(maximum ?? average ?? 0, 100)

        return VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(formatted(average))%")
                    .font(.caption.bold().monospacedDigit())
                if let maximum, maximum > (average ?? 0) + 0.5 {
                    Text("max \(formatted(maximum))%")
                        .font(.caption2.bold().monospacedDigit())
                        .foregroundStyle(.red)
                }
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                    Capsule()
                        .fill(barColor(for: average))
                        .frame(width: geo.size.width * CGFloat(avg / 100))
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: 2, height: 11)
                        .offset(x: max(0, geo.size.width * CGFloat(maxVal / 100) - 1))
                }
            }
            .frame(height: 8)
        }
    }

    private func formatted(_ value: Double?) -> String {
        guard let value else { return "—" }
        return String(format: "%.0f", value)
    }

    private func barColor(for value: Double?) -> Color {
        guard let value else { return .secondary }
        if value >= 85 { return .red }
        if value >= 65 { return .orange }
        return .green
    }

    private func refresh() async {
        guard let serverId else {
            isLoading = false
            return
        }

        if metrics == nil {
            isLoading = true
        }
        loadFailed = false

        do {
            let response = try await ServerMonitoringService.shared.fetchMetrics(serverId: serverId)
            serverName = response.server.name
            hostname = response.server.hostname
            online = response.server.online
            metrics = response.latest
            loadFailed = false
        } catch {
            online = false
            loadFailed = true
        }

        isLoading = false
    }
}
