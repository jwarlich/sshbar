import Foundation
import Combine

final class ServerStore: ObservableObject {
    @Published var servers: [Server] {
        didSet { persist() }
    }

    private static let defaultsKey = "com.jasperwarlich.sshbar.servers"

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.defaultsKey),
           let decoded = try? JSONDecoder().decode([Server].self, from: data) {
            self.servers = decoded
        } else {
            self.servers = []
        }
    }

    var pinned: [Server] {
        servers.filter { $0.pinned }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var all: [Server] {
        servers.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func add(_ server: Server) {
        servers.append(server)
    }

    func update(_ server: Server) {
        guard let index = servers.firstIndex(where: { $0.id == server.id }) else { return }
        servers[index] = server
    }

    func delete(_ server: Server) {
        servers.removeAll { $0.id == server.id }
    }

    func togglePin(_ server: Server) {
        guard let index = servers.firstIndex(where: { $0.id == server.id }) else { return }
        servers[index].pinned.toggle()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(servers) else { return }
        UserDefaults.standard.set(data, forKey: Self.defaultsKey)
    }
}
