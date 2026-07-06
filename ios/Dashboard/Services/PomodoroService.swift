import Foundation

enum PomodoroPhase: Equatable {
    case idle
    case focus
    case shortBreak
}

struct PomodoroState: Equatable {
    var phase: PomodoroPhase = .idle
    var remainingSeconds: Int = 25 * 60
    var completedCycles: Int = 0
    var isRunning: Bool = false

    static let focusDuration = 25 * 60
    static let breakDuration = 5 * 60
}

@MainActor
final class PomodoroService: ObservableObject {
    static let shared = PomodoroService()

    @Published private var states: [UUID: PomodoroState] = [:]

    private var timers: [UUID: Timer] = [:]

    private init() {}

    func state(for widgetId: UUID) -> PomodoroState {
        states[widgetId] ?? PomodoroState()
    }

    func toggle(widgetId: UUID) {
        var current = state(for: widgetId)
        if current.phase == .idle {
            current.phase = .focus
            current.remainingSeconds = PomodoroState.focusDuration
        }
        current.isRunning.toggle()
        states[widgetId] = current
        if current.isRunning {
            startTimer(for: widgetId)
        } else {
            stopTimer(for: widgetId)
        }
    }

    func skipBreak(widgetId: UUID) {
        var current = state(for: widgetId)
        current.phase = .focus
        current.remainingSeconds = PomodoroState.focusDuration
        current.isRunning = false
        states[widgetId] = current
        stopTimer(for: widgetId)
    }

    func reset(widgetId: UUID) {
        stopTimer(for: widgetId)
        states[widgetId] = PomodoroState()
    }

    private func startTimer(for widgetId: UUID) {
        stopTimer(for: widgetId)
        let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick(widgetId: widgetId)
            }
        }
        timers[widgetId] = timer
    }

    private func stopTimer(for widgetId: UUID) {
        timers[widgetId]?.invalidate()
        timers[widgetId] = nil
    }

    private func tick(widgetId: UUID) {
        var current = state(for: widgetId)
        guard current.isRunning, current.remainingSeconds > 0 else { return }

        current.remainingSeconds -= 1
        if current.remainingSeconds == 0 {
            switch current.phase {
            case .focus:
                current.completedCycles += 1
                current.phase = .shortBreak
                current.remainingSeconds = PomodoroState.breakDuration
                HapticHelper.success()
            case .shortBreak:
                current.phase = .focus
                current.remainingSeconds = PomodoroState.focusDuration
                HapticHelper.lightImpact()
            case .idle:
                break
            }
        }
        states[widgetId] = current
    }
}

extension PomodoroState {
    var formattedTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var phaseLabel: String {
        switch phase {
        case .idle: return "Pripravený"
        case .focus: return "Focus"
        case .shortBreak: return "Prestávka"
        }
    }
}
