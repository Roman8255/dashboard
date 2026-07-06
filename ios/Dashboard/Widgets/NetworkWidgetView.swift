import SwiftUI

struct NetworkWidgetView: View {
    let styleId: String
    @ObservedObject private var network = NetworkMonitorService.shared

    var body: some View {
        WidgetCard {
            Group {
                if styleId == "speed" {
                    speedView
                } else {
                    iconView
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            Task { await network.runManualSpeedTest() }
        }
        .task {
            await network.runSpeedTestIfNeeded(force: false)
        }
    }

    private var iconView: some View {
        VStack(spacing: 4) {
            Image(systemName: network.connectionType.iconName)
                .font(.title2)
                .foregroundStyle(network.connectionType == .offline ? Color.red : Color.accentColor)
            if network.isTestingSpeed {
                ProgressView().scaleEffect(0.8)
            } else if let speed = network.formattedSpeed() {
                Text(speed)
                    .font(.caption.bold().monospacedDigit())
                    .foregroundStyle(speedColor)
            } else {
                Text(network.connectionType.label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
    }

    private var speedView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: network.connectionType.iconName)
                    .foregroundStyle(Color.accentColor)
                Text(network.connectionType.label)
                    .font(.caption.bold())
                Spacer()
                if network.connectionType == .offline {
                    Text("Offline")
                        .font(.caption2.bold())
                        .foregroundStyle(.red)
                }
            }
            if network.isTestingSpeed {
                HStack(spacing: 8) {
                    ProgressView().scaleEffect(0.8)
                    Text("Meriam rýchlosť…")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else if let speed = network.formattedSpeed() {
                Text(speed)
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(speedColor)
                if let relative = network.relativeTestTime() {
                    Text(relative)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Klepnite pre test")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
    }

    private var speedColor: Color {
        guard let speed = network.lastSpeedMbps else { return .secondary }
        if speed > 25 { return .green }
        if speed > 5 { return .orange }
        return .red
    }
}
