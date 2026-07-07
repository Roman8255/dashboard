import SwiftUI

struct ServerManagementView: View {
    @ObservedObject private var service = ServerMonitoringService.shared

    @Binding var navigationPath: NavigationPath

    @State private var newServerName = ""
    @State private var alertMessage: String?
    @State private var testingServerId: String?
    @State private var testResults: [String: ServerConnectionTestResult] = [:]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Monitorovanie servera", systemImage: "server.rack")
                .font(.headline)

            Text("Pridajte server a v detaile nájdete príkazy na inštaláciu agenta.")
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

            ForEach(service.servers) { server in
                serverRow(server)
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

    private func serverRow(_ server: ServerAgent) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Circle()
                    .fill(server.online ? Color.green : Color.red)
                    .frame(width: 8, height: 8)

                NavigationLink(value: WidgetSettingsRoute.server(server.id)) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(server.name)
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                        Text(server.hostname ?? "Čaká na prvé dáta")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    Task { await testServer(server) }
                } label: {
                    if testingServerId == server.id {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(testingServerId != nil)

                Button(role: .destructive) {
                    Task {
                        try? await service.deleteServer(id: server.id)
                        testResults[server.id] = nil
                    }
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
            }

            if let result = testResults[server.id] {
                Text(result.message)
                    .font(.caption2)
                    .foregroundStyle(result.online ? .green : .orange)
            }
        }
        .padding()
        .glassCard(cornerRadius: 14)
    }

    private func createServer() async {
        do {
            let response = try await service.createServer(
                name: newServerName.trimmingCharacters(in: .whitespaces)
            )
            newServerName = ""
            navigationPath.append(WidgetSettingsRoute.server(response.server.id))
        } catch {
            alertMessage = error.localizedDescription
        }
    }

    private func testServer(_ server: ServerAgent) async {
        testingServerId = server.id
        let result = await service.testConnection(serverId: server.id)
        testResults[server.id] = result
        testingServerId = nil
        if result.online {
            HapticHelper.success()
        } else {
            HapticHelper.lightImpact()
        }
    }
}
