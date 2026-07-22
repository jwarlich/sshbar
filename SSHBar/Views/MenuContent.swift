import SwiftUI
import AppKit

struct MenuContent: View {
    @EnvironmentObject var store: ServerStore
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Group {
            if !store.pinned.isEmpty {
                Section("Pinned") {
                    ForEach(store.pinned) { server in
                        ServerMenuEntry(server: server)
                    }
                }
                Divider()
            }

            Menu("All Servers (\(store.all.count))") {
                if store.all.isEmpty {
                    Text("No servers yet")
                } else {
                    ForEach(store.all) { server in
                        ServerMenuEntry(server: server)
                    }
                }
            }

            Menu("Manage") {
                if store.all.isEmpty {
                    Text("No servers to manage")
                } else {
                    ForEach(store.all) { server in
                        Menu(server.displayLabel) {
                            Button(server.pinned ? "Unpin" : "Pin") {
                                store.togglePin(server)
                            }
                            Button("Edit...") {
                                openServerWindow(id: WindowID.editServer, value: server.id)
                            }
                            Button("Delete") {
                                store.delete(server)
                            }
                        }
                    }
                }
            }

            Divider()

            Button("Add Server...") {
                openServerWindow(id: WindowID.addServer)
            }
            .keyboardShortcut("n", modifiers: [.command])

            Button("Preferences...") {
                openServerWindow(id: WindowID.preferences)
            }
            .keyboardShortcut(",", modifiers: [.command])

            Divider()

            Button("Quit SSHBar") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: [.command])
        }
    }

    private func openServerWindow(id: String) {
        NSApp.activate(ignoringOtherApps: true)
        openWindow(id: id)
    }

    private func openServerWindow(id: String, value: UUID) {
        NSApp.activate(ignoringOtherApps: true)
        openWindow(id: id, value: value)
    }
}

private struct ServerMenuEntry: View {
    @EnvironmentObject var store: ServerStore
    let server: Server

    var body: some View {
        if server.users.count > 1 {
            Menu(server.displayLabel) {
                ForEach(server.users) { user in
                    Button(user.name.isEmpty ? "(no user)" : user.name) {
                        Connector.connect(to: server, as: user)
                    }
                }
            }
        } else {
            Button(server.displayLabel) {
                Connector.connect(to: server, as: server.primaryUser)
            }
        }
    }
}
