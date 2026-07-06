import SwiftUI

struct PomodoroWidgetView: View {
    let widgetId: UUID
    let styleId: String
    @ObservedObject private var pomodoro = PomodoroService.shared

    private var state: PomodoroState {
        pomodoro.state(for: widgetId)
    }

    var body: some View {
        WidgetCard {
            if styleId == "session" {
                sessionView
            } else {
                compactView
            }
        }
    }

    private var compactView: some View {
        VStack(spacing: 8) {
            Text(state.phaseLabel)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Text(state.formattedTime)
                .font(.title2.bold().monospacedDigit())
            Button {
                HapticHelper.lightImpact()
                pomodoro.toggle(widgetId: widgetId)
            } label: {
                Image(systemName: state.isRunning ? "pause.fill" : "play.fill")
                    .font(.title3)
            }
            .buttonStyle(.plain)
        }
        .padding(8)
    }

    private var sessionView: some View {
        VStack(spacing: 10) {
            HStack {
                Text(state.phaseLabel)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(state.completedCycles) cyklov")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Text(state.formattedTime)
                .font(.largeTitle.bold().monospacedDigit())
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            HStack(spacing: 16) {
                Button {
                    HapticHelper.lightImpact()
                    pomodoro.toggle(widgetId: widgetId)
                } label: {
                    Image(systemName: state.isRunning ? "pause.circle.fill" : "play.circle.fill")
                        .font(.title)
                }
                .buttonStyle(.plain)

                if state.phase == .shortBreak {
                    Button("Preskočiť") {
                        pomodoro.skipBreak(widgetId: widgetId)
                    }
                    .font(.caption.bold())
                }

                Button {
                    pomodoro.reset(widgetId: widgetId)
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.caption.bold())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
    }
}
