import ContactsUI
import SwiftUI

struct ContactPickerView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let onSelect: ([String]) -> Void

    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        picker.predicateForEnablingContact = NSPredicate(format: "phoneNumbers.@count > 0")
        return picker
    }

    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onSelect: onSelect, dismiss: dismiss)
    }

    final class Coordinator: NSObject, CNContactPickerDelegate {
        let onSelect: ([String]) -> Void
        let dismiss: DismissAction

        init(onSelect: @escaping ([String]) -> Void, dismiss: DismissAction) {
            self.onSelect = onSelect
            self.dismiss = dismiss
        }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
            let ids = contacts.map(\.identifier)
            onSelect(ids)
            dismiss()
        }

        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            dismiss()
        }
    }
}
