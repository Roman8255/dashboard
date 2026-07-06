import EventKit
import Foundation
import SwiftUI

struct AgendaItem: Identifiable, Equatable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let calendarTitle: String
    let calendarColor: Color
}

@MainActor
final class AgendaService: ObservableObject {
    static let shared = AgendaService()

    @Published private(set) var items: [AgendaItem] = []
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
            errorMessage = "Prístup ku kalendáru je potrebný."
            return
        }

        items = fetchUpcomingEvents()
        lastFetch = Date()
    }

    private func requestAccessIfNeeded() async -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .authorized, .fullAccess:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                store.requestFullAccessToEvents { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
        default:
            return false
        }
    }

    private func fetchUpcomingEvents() -> [AgendaItem] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        guard let end = calendar.date(byAdding: .day, value: 2, to: start) else { return [] }

        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        let events = store.events(matching: predicate)
            .filter { !$0.isAllDay || calendar.isDateInToday($0.startDate) || calendar.isDateInTomorrow($0.startDate) }
            .sorted { $0.startDate < $1.startDate }

        return events.prefix(8).map { event in
            AgendaItem(
                id: event.eventIdentifier ?? UUID().uuidString,
                title: event.title ?? "Bez názvu",
                startDate: event.startDate,
                endDate: event.endDate,
                isAllDay: event.isAllDay,
                calendarTitle: event.calendar.title,
                calendarColor: Color(cgColor: event.calendar.cgColor)
            )
        }
    }
}

extension AgendaItem {
    var countdownText: String? {
        let now = Date()
        guard startDate > now else { return nil }
        let minutes = Int(startDate.timeIntervalSince(now) / 60)
        if minutes < 60 {
            return "o \(minutes) min"
        }
        let hours = minutes / 60
        return "o \(hours) h"
    }
}
