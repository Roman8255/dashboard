import SwiftUI

struct ServerManagementView: View {
    @ObservedObject private var service = ServerMonitoringService.shared

    @State private var newServerName = ""
    @State private var createdResponse: CreateServerResponse?
    @State private var alertMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Monitorovanie servera", systemImage: "server.rack")
                .font(.headline)

            Text("Pridajte server a spustite vygenerovaný príkaz na Linuxe.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack {
                TextField("Názov servera", text: $newServerName)
                    .padding(12)
                    .glassCard(cornerRadius: 12)
                Button("Pridať") {
                    Task { await createServer() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(newServerName.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            if let createdResponse {
                commandBlock(title: "Inštalácia", command: createdResponse.installCommand)
                commandBlock(title: "Zastavenie", command: createdResponse.stopCommand)
            }

            ForEach(service.servers) { server in
                HStack {
                    Circle()
                        .fill(server.online ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    VStack(alignment: .leading) {
                        Text(server.name)
                            .font(.subheadline.bold())
                        Text(server.hostname ?? "Čaká na prvé dáta")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button(role: .destructive) {
                        Task {
                            try? await service.deleteServer(id: server.id)
                        }
                    } label: {
                        Image(systemName: "trash")
                    }
                }
                .padding()
                .glassCard(cornerRadius: 14)
            }
        }
        .task { await service.refresh() }
        .alert("Server", isPresented: Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private func commandBlock(title: String, command: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.bold())
            Text(command)
                .font(.caption2.monospaced())
                .textSelection(.enabled)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.25), in: RoundedRectangle(cornerRadius: 10))
            Button("Kopírovať") {
                UIPasteboard.general.string = command
                alertMessage = "Príkaz skopírovaný"
            }
            .font(.caption.bold())
        }
        .padding()
        .glassCard(cornerRadius: 14)
    }

    private func createServer() async {
        do {
            let response = try await service.createServer(
                name: newServerName.trimmingCharacters(in: .whitespaces)
            )
            createdResponse = response
            newServerName = ""
        } catch {
            alertMessage = error.localizedDescription
        }
    }
}
