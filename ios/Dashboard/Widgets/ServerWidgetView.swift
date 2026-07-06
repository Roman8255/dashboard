import SwiftUI

struct ServerWidgetView: View {
    let widget: WidgetInstance

    @State private var metrics: ServerMetricsSnapshot?
    @State private var serverName = "Server"
    @State private var online = false

    private var serverId: String? { widget.config["serverId"] }

    var body: some View {
        Group {
            if serverId == nil {
                placeholder
            } else if widget.styleId == "detailed" {
                detailedView
            } else {
                compactView
            }
        }
        .task(id: serverId) {
            await refresh()
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30_000_000_000)
                await refresh()
            }
        }
    }

    private var placeholder: some View {
        VStack(spacing: 8) {
            Image(systemName: "server.rack")
                .font(.title2)
            Text("Vyberte server v nastaveniach")
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var compactView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(serverName)
                    .font(.caption.bold())
                    .lineLimit(1)
                HStack(spacing: 12) {
                    metricLabel("CPU", value: metrics?.cpuPercent, suffix: "%")
                    metricLabel("RAM", value: ramPercent, suffix: "%")
                }
            }
            Spacer()
            Circle()
                .fill(online ? Color.green : Color.red)
                .frame(width: 8, height: 8)
        }
        .padding(12)
    }

    private var detailedView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(serverName)
                    .font(.subheadline.bold())
                Spacer()
                Text(online ? "Online" : "Offline")
                    .font(.caption2.bold())
                    .foregroundStyle(online ? .green : .red)
            }
            HStack {
                metricBlock(title: "CPU", value: formatted(metrics?.cpuPercent), suffix: "%")
                metricBlock(title: "RAM", value: formatted(ramPercent), suffix: "%")
            }
            HStack {
                metricBlock(title: "Disk", value: formatted(metrics?.diskUsedPercent), suffix: "%")
                metricBlock(title: "Load", value: formatted(metrics?.loadAvg), suffix: "")
            }
        }
        .padding(12)
    }

    private func metricLabel(_ title: String, value: Double?, suffix: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("\(formatted(value))\(suffix)")
                .font(.caption.monospacedDigit().bold())
        }
    }

    private func metricBlock(title: String, value: String, suffix: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text("\(value)\(suffix)")
                .font(.headline.monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var ramPercent: Double? {
        guard let metrics else { return nil }
        guard metrics.memTotalMb > 0 else { return nil }
        return (metrics.memUsedMb / metrics.memTotalMb) * 100
    }

    private func formatted(_ value: Double?) -> String {
        guard let value else { return "—" }
        return String(format: "%.0f", value)
    }

    private func refresh() async {
        guard let serverId else { return }
        do {
            let response = try await ServerMonitoringService.shared.fetchMetrics(serverId: serverId)
            serverName = response.server.name
            online = response.server.online
            metrics = response.latest
        } catch {
            online = false
        }
    }
}
