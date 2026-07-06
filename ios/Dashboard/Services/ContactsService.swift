import Contacts
import Foundation
import UIKit

struct ContactEntry: Identifiable, Equatable {
    let id: String
    let name: String
    let phoneNumber: String
    let thumbnailData: Data?
}

@MainActor
final class ContactsService: ObservableObject {
    static let shared = ContactsService()

    @Published private(set) var contacts: [ContactEntry] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isAuthorized = false
    @Published private(set) var needsPermission = false
    @Published private(set) var errorMessage: String?

    private let store = CNContactStore()

    private init() {}

    func refreshIfNeeded() async {
        await refresh()
    }

    func refresh() async {
        isLoading = contacts.isEmpty
        errorMessage = nil
        defer { isLoading = false }

        let granted = await requestAccessIfNeeded()
        isAuthorized = granted
        needsPermission = !granted
        guard granted else {
            contacts = []
            errorMessage = "Prístup ku kontaktom je potrebný."
            return
        }

        contacts = fetchFavoriteContacts()
    }

    func call(_ contact: ContactEntry) {
        guard let url = URL(string: "tel://\(contact.phoneNumber.filter { $0.isNumber || $0 == "+" })") else { return }
        UIApplication.shared.open(url)
    }

    func message(_ contact: ContactEntry) {
        guard let url = URL(string: "sms://\(contact.phoneNumber.filter { $0.isNumber || $0 == "+" })") else { return }
        UIApplication.shared.open(url)
    }

    private func requestAccessIfNeeded() async -> Bool {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        switch status {
        case .authorized, .limited:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                store.requestAccess(for: .contacts) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
        default:
            return false
        }
    }

    private func fetchFavoriteContacts() -> [ContactEntry] {
        let ids = WidgetPreferencesStore.shared.preferences.favoriteContactIDs
        guard !ids.isEmpty else { return [] }

        let keys: [CNKeyDescriptor] = [
            CNContactIdentifierKey as CNKeyDescriptor,
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactThumbnailImageDataKey as CNKeyDescriptor
        ]

        return ids.compactMap { id -> ContactEntry? in
            guard let contact = try? store.unifiedContact(withIdentifier: id, keysToFetch: keys),
                  let phone = contact.phoneNumbers.first?.value.stringValue else { return nil }
            let name = [contact.givenName, contact.familyName]
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            return ContactEntry(
                id: contact.identifier,
                name: name.isEmpty ? phone : name,
                phoneNumber: phone,
                thumbnailData: contact.thumbnailImageData
            )
        }
    }
}
