import EventKit
import Foundation

struct TaskItem: Identifiable, Equatable {
    let id: String
    let title: String
    let dueDate: Date?
    let isCompleted: Bool
    let priority: Int
}

@MainActor
final class TasksService: ObservableObject {
    static let shared = TasksService()

    @Published private(set) var items: [TaskItem] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isAuthorized = false
    @Published private(set) var needsPermission = false
    @Published private(set) var errorMessage: String?

    private let store = EKEventStore()
    private var lastFetch: Date?
    private let cacheInterval: TimeInterval = 120

    private init() {
        NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: store,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in await self?.refresh(force: true) }
        }
    }

    var openCount: Int {
        items.filter { !$0.isCompleted }.count
    }

    func refreshIfNeeded() async {
        if let lastFetch, Date().timeIntervalSince(lastFetch) < cacheInterval, !items.isEmpty {
            return
        }
        await refresh(force: false)
    }

    func refresh(force: Bool) async {
        if !force, let lastFetch, Date().timeIntervalSince(lastFetch) < cacheInterval, !items.isEmpty {
            return
        }

        isLoading = items.isEmpty
        errorMessage = nil
        defer { isLoading = false }

        let granted = await requestAccessIfNeeded()
        isAuthorized = granted
        needsPermission = !granted
        guard granted else {
            errorMessage = "Prístup k pripomienkam je potrebný."
            return
        }

        items = await fetchReminders()
        lastFetch = Date()
    }

    func toggleCompletion(for item: TaskItem) async {
        guard let reminder = store.calendarItem(withIdentifier: item.id) as? EKReminder else { return }
        reminder.isCompleted.toggle()
        do {
            try store.save(reminder, commit: true)
            await refresh(force: true)
        } catch {
            errorMessage = "Nepodarilo sa aktualizovať úlohu."
        }
    }

    private func requestAccessIfNeeded() async -> Bool {
        let status = EKEventStore.authorizationStatus(for: .reminder)
        switch status {
        case .authorized, .fullAccess:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                store.requestFullAccessToReminders { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
        default:
            return false
        }
    }

    private func fetchReminders() async -> [TaskItem] {
        let predicate = store.predicateForReminders(in: nil)
        let reminders = await withCheckedContinuation { (continuation: CheckedContinuation<[EKReminder], Never>) in
            store.fetchReminders(matching: predicate) { result in
                continuation.resume(returning: result ?? [])
            }
        }

        return reminders
            .sorted { lhs, rhs in
                if lhs.isCompleted != rhs.isCompleted { return !lhs.isCompleted }
                let lhsDate = lhs.dueDateComponents?.date ?? .distantFuture
                let rhsDate = rhs.dueDateComponents?.date ?? .distantFuture
                return lhsDate < rhsDate
            }
            .prefix(12)
            .map { reminder in
                TaskItem(
                    id: reminder.calendarItemIdentifier,
                    title: reminder.title ?? "Bez názvu",
                    dueDate: reminder.dueDateComponents?.date,
                    isCompleted: reminder.isCompleted,
                    priority: reminder.priority
                )
            }
    }
}
