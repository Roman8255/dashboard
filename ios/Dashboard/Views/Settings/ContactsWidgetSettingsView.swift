import SwiftUI

struct ContactsWidgetSettingsView: View {
    @ObservedObject private var widgetPreferences = WidgetPreferencesStore.shared
    @State private var showContactPicker = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Vyberte až 4 kontakty pre widget Kontakty.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("\(widgetPreferences.preferences.favoriteContactIDs.count) vybraných")
                    .font(.subheadline.bold())

                Button("Vybrať kontakty") {
                    showContactPicker = true
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
        .navigationTitle("Kontakty")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showContactPicker) {
            ContactPickerView { ids in
                widgetPreferences.update { prefs in
                    prefs.favoriteContactIDs = Array(ids.prefix(4))
                }
                Task { await ContactsService.shared.refresh() }
            }
        }
    }
}
