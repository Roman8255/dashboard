import SwiftUI

struct WorldClockSettingsView: View {
    @ObservedObject private var widgetPreferences = WidgetPreferencesStore.shared
    @State private var alertMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Vyberte až 3 mestá pre widget Svetové hodiny.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(WorldClockCityCatalog.options, id: \.id) { city in
                    let isSelected = widgetPreferences.preferences.worldClockCities.contains(city.id)
                    Button {
                        toggleCity(city.id)
                    } label: {
                        HStack {
                            Text(city.name)
                                .foregroundStyle(.primary)
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .font(.subheadline)
                        .padding()
                        .glassCard(cornerRadius: 12)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle("Svetové hodiny")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Svetové hodiny", isPresented: Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private func toggleCity(_ cityId: String) {
        widgetPreferences.update { prefs in
            if let index = prefs.worldClockCities.firstIndex(of: cityId) {
                prefs.worldClockCities.remove(at: index)
            } else if prefs.worldClockCities.count < 3 {
                prefs.worldClockCities.append(cityId)
            } else {
                alertMessage = "Maximálne 3 mestá pre svetové hodiny."
            }
        }
        WorldClockService.shared.reload()
    }
}
