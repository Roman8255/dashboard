import SwiftUI

struct ContactsWidgetView: View {
    let styleId: String
    @ObservedObject private var contactsService = ContactsService.shared
    @ObservedObject private var preferences = WidgetPreferencesStore.shared

    var body: some View {
        WidgetCard {
            Group {
                if contactsService.isLoading {
                    ProgressView().tint(.accentColor).padding(8)
                } else if contactsService.needsPermission {
                    permissionView
                } else if contactsService.contacts.isEmpty {
                    emptyView
                } else if styleId == "grid" {
                    gridView
                } else {
                    rowView
                }
            }
        }
        .onChange(of: preferences.preferences.favoriteContactIDs) { _, _ in
            Task { await contactsService.refresh() }
        }
        .task { await contactsService.refreshIfNeeded() }
    }

    private var permissionView: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.title2)
                .foregroundStyle(.orange)
            Text("Povoliť kontakty")
                .font(.caption2.bold())
        }
        .padding(8)
    }

    private var emptyView: some View {
        VStack(spacing: 6) {
            Image(systemName: "person.2")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Vyberte v Nastaveniach")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(8)
    }

    private var rowView: some View {
        HStack(spacing: 10) {
            ForEach(contactsService.contacts.prefix(2)) { contact in
                contactButton(contact)
            }
        }
        .padding(8)
    }

    private var gridView: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(contactsService.contacts.prefix(4)) { contact in
                contactButton(contact)
            }
        }
        .padding(8)
    }

    private func contactButton(_ contact: ContactEntry) -> some View {
        Button {
            HapticHelper.lightImpact()
            contactsService.call(contact)
        } label: {
            VStack(spacing: 6) {
                contactAvatar(contact)
                Text(contact.name)
                    .font(.caption2.bold())
                    .lineLimit(1)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5).onEnded { _ in
                HapticHelper.mediumImpact()
                contactsService.message(contact)
            }
        )
    }

    @ViewBuilder
    private func contactAvatar(_ contact: ContactEntry) -> some View {
        if let data = contact.thumbnailData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 36, height: 36)
                .clipShape(Circle())
        } else {
            ZStack {
                Circle().fill(Color.accentColor.opacity(0.25))
                Text(contact.name.prefix(1).uppercased())
                    .font(.caption.bold())
            }
            .frame(width: 36, height: 36)
        }
    }
}
