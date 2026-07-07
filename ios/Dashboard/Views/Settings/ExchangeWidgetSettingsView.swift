import SwiftUI

struct ExchangeWidgetSettingsView: View {
    @ObservedObject private var widgetPreferences = WidgetPreferencesStore.shared

    private let currencies = ["EUR", "USD", "GBP", "CZK", "CHF", "PLN"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Základná mena pre widget Kurzy mien.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(currencies, id: \.self) { code in
                    let isSelected = widgetPreferences.preferences.exchangeBaseCurrency == code
                    Button {
                        widgetPreferences.update { prefs in
                            prefs.exchangeBaseCurrency = code
                        }
                        Task { await ExchangeRateService.shared.refresh() }
                    } label: {
                        HStack {
                            Text(code)
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
        .navigationTitle("Kurzy mien")
        .navigationBarTitleDisplayMode(.inline)
    }
}
