import SwiftUI

struct ExchangeWidgetView: View {
    let styleId: String
    @ObservedObject private var exchange = ExchangeRateService.shared

    var body: some View {
        WidgetCard {
            Group {
                if exchange.isLoading {
                    ProgressView().tint(.accentColor).padding(8)
                } else if let first = exchange.entries.first, styleId == "compact" {
                    compactView(first)
                } else if !exchange.entries.isEmpty {
                    boardView
                } else {
                    errorView
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            Task { await exchange.refresh() }
        }
        .task { await exchange.refreshIfNeeded() }
    }

    private func compactView(_ entry: ExchangeRateEntry) -> some View {
        VStack(spacing: 4) {
            Text("\(exchange.baseCurrency)/\(entry.code)")
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
            Text(String(format: "%.3f", entry.rate))
                .font(.title3.bold().monospacedDigit())
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            directionIcon(entry.changeDirection)
        }
        .padding(8)
    }

    private var boardView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Kurzy · \(exchange.baseCurrency)")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            ForEach(exchange.entries) { entry in
                HStack {
                    Text(entry.code)
                        .font(.caption.bold())
                        .frame(width: 36, alignment: .leading)
                    Text(String(format: "%.3f", entry.rate))
                        .font(.caption.monospacedDigit())
                    Spacer()
                    directionIcon(entry.changeDirection)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
    }

    private var errorView: some View {
        VStack(spacing: 6) {
            Image(systemName: "coloncurrencysign.circle")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(exchange.errorMessage ?? "Klepnite pre obnovenie")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(8)
    }

    @ViewBuilder
    private func directionIcon(_ direction: ExchangeRateEntry.ChangeDirection) -> some View {
        switch direction {
        case .up:
            Image(systemName: "arrow.up.right")
                .font(.caption2.bold())
                .foregroundStyle(.green)
        case .down:
            Image(systemName: "arrow.down.right")
                .font(.caption2.bold())
                .foregroundStyle(.red)
        case .flat:
            Image(systemName: "minus")
                .font(.caption2.bold())
                .foregroundStyle(.secondary)
        case .unknown:
            EmptyView()
        }
    }
}
