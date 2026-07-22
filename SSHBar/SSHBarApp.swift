import SwiftUI

@main
struct SSHBarApp: App {
    @StateObject private var store = ServerStore()

    var body: some Scene {
        MenuBarExtra {
            MenuContent()
                .environmentObject(store)
        } label: {
            Text("🔌 ssh")
        }
        .menuBarExtraStyle(.menu)

        Window("Add Server", id: WindowID.addServer) {
            ServerFormView(store: store, editingServer: nil)
        }
        .defaultSize(width: 480, height: 480)
        .windowResizability(.contentSize)

        WindowGroup(id: WindowID.editServer, for: UUID.self) { $serverID in
            if let serverID, let server = store.servers.first(where: { $0.id == serverID }) {
                ServerFormView(store: store, editingServer: server)
            }
        }
        .defaultSize(width: 480, height: 480)
        .windowResizability(.contentSize)

        Window("Preferences", id: WindowID.preferences) {
            PreferencesView()
        }
        .defaultSize(width: 420, height: 260)
        .windowResizability(.contentSize)
    }
}

enum WindowID {
    static let addServer = "add-server"
    static let editServer = "edit-server"
    static let preferences = "preferences"
}
