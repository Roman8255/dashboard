import SwiftUI

struct ServerDetailView: View {
    let serverId: String

    @ObservedObject private var service = ServerMonitoringService.shared
    @State private var alertMessage: String?
    @State private var isTesting = false
    @State private var testResult: ServerConnectionTestResult?

    private var server: ServerAgent? {
        service.servers.first { $0.id == serverId }
    }

    private var token: String? {
        ServerAgentCredentialStore.load(for: serverId)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                statusSection
                testSection

                if let token {
                    AgentCommandBlock(
                        title: "Inštalácia",
                        command: ServerAgentCommands.installCommand(token: token),
                        onCopied: { alertMessage = "Príkaz skopírovaný" }
                    )
                    AgentCommandBlock(
                        title: "Zastavenie",
                        command: ServerAgentCommands.stopCommand(token: token),
                        onCopied: { alertMessage = "Príkaz skopírovaný" }
                    )
                } else {
                    missingTokenSection
                }
            }
            .padding()
        }
        .navigationTitle(server?.name ?? "Server")
        .navigationBarTitleDisplayMode(.inline)
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

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill((server?.online ?? false) ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                Text(server?.online == true ? "Online" : "Offline")
                    .font(.subheadline.bold())
            }
            if let hostname = server?.hostname, !hostname.isEmpty {
                Label(hostname, systemImage: "network")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Čaká na prvé dáta od agenta")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassCard(cornerRadius: 14)
    }

    private var testSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Test pripojenia")
                .font(.subheadline.bold())
            Text("Okamžite overí, či agent na serveri odpovedá.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                Task { await runTest() }
            } label: {
                HStack {
                    if isTesting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                    }
                    Text(isTesting ? "Testujem…" : "Otestovať teraz")
                        .font(.subheadline.bold())
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isTesting)

            if let testResult {
                Text(testResult.message)
                    .font(.caption)
                    .foregroundStyle(testResult.online ? .green : .orange)
                    .padding(.top, 4)
            }
        }
        .padding()
        .glassCard(cornerRadius: 14)
    }

    private var missingTokenSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Príkazy nie sú dostupné")
                .font(.subheadline.bold())
            Text("Token pre tento server nie je uložený v zariadení. Pridajte server znova alebo použite token z pôvodnej inštalácie.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .glassCard(cornerRadius: 14)
    }

    private func runTest() async {
        isTesting = true
        testResult = nil
        let result = await service.testConnection(serverId: serverId)
        testResult = result
        isTesting = false
        if result.online {
            HapticHelper.success()
        } else {
            HapticHelper.lightImpact()
        }
    }
}
