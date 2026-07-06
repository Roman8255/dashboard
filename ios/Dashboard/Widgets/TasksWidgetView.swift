import SwiftUI

struct TasksWidgetView: View {
    let styleId: String
    @ObservedObject private var tasks = TasksService.shared

    var body: some View {
        WidgetCard {
            Group {
                if tasks.isLoading {
                    loadingView
                } else if tasks.needsPermission {
                    permissionView
                } else if tasks.items.filter({ !$0.isCompleted }).isEmpty {
                    emptyView
                } else if styleId == "list" {
                    listView
                } else {
                    compactView
                }
            }
        }
        .task { await tasks.refreshIfNeeded() }
    }

    private var loadingView: some View {
        VStack(spacing: 8) {
            ProgressView().tint(.accentColor)
            Text("Načítavam úlohy…")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(8)
    }

    private var permissionView: some View {
        VStack(spacing: 8) {
            Image(systemName: "checklist")
                .font(.title2)
                .foregroundStyle(.orange)
            Text("Povoliť pripomienky")
                .font(.caption2.bold())
            Button("Otvoriť Nastavenia") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(.caption2.bold())
        }
        .padding(8)
    }

    private var emptyView: some View {
        VStack(spacing: 6) {
            Image(systemName: "checkmark.circle")
                .font(.title2)
                .foregroundStyle(.green)
            Text("Všetko hotové")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(8)
    }

    private var compactView: some View {
        let openItems = tasks.items.filter { !$0.isCompleted }
        let next = openItems.first
        return VStack(alignment: .leading, spacing: 6) {
            Text("\(openItems.count) otvorených")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            if let next {
                Text(next.title)
                    .font(.subheadline.bold())
                    .lineLimit(2)
                if let dueDate = next.dueDate {
                    Text(dueLabel(dueDate))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
    }

    private var listView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Úlohy")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            ForEach(tasks.items.filter { !$0.isCompleted }.prefix(6)) { item in
                Button {
                    Task { await tasks.toggleCompletion(for: item) }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.caption)
                            .foregroundStyle(item.isCompleted ? .green : .secondary)
                        Text(item.title)
                            .font(.caption.bold())
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
    }

    private func dueLabel(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "sk")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
