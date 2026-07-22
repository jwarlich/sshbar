import SwiftUI
import AppKit

struct ServerFormView: View {
    @ObservedObject var store: ServerStore
    let editingServer: Server?

    @State private var emoji: String
    @State private var name: String
    @State private var host: String
    @State private var port: String
    @State private var identityFile: String
    @State private var pinned: Bool
    @State private var users: [ServerUser]

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !host.trimmingCharacters(in: .whitespaces).isEmpty
    }

    init(store: ServerStore, editingServer: Server?) {
        self.store = store
        self.editingServer = editingServer
        let server = editingServer ?? Server()
        _emoji = State(initialValue: server.emoji)
        _name = State(initialValue: server.name)
        _host = State(initialValue: server.host)
        _port = State(initialValue: server.port)
        _identityFile = State(initialValue: server.identityFile)
        _pinned = State(initialValue: server.pinned)
        _users = State(initialValue: server.users)
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    serverSection
                    usersSection
                }
                .padding(20)
            }

            Divider()
            footer
        }
        .frame(width: 520, height: 600)
        .background(.background)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            Text(emoji.isEmpty ? "🖥️" : emoji)
                .font(.system(size: 28))
            VStack(alignment: .leading, spacing: 2) {
                Text(editingServer == nil ? "Add Server" : "Edit Server")
                    .font(.title3.bold())
                Text(host.isEmpty ? "No host set yet" : host)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    // MARK: - Server section

    private var serverSection: some View {
        FormSection(title: "Server") {
            HStack(alignment: .top, spacing: 12) {
                EmojiField(emoji: $emoji)
                FormField(label: "Name") {
                    TextField("web-prod-1", text: $name)
                        .textFieldStyle(.roundedBorder)
                }
            }

            HStack(spacing: 12) {
                FormField(label: "Host") {
                    TextField("192.168.1.10 or example.com", text: $host)
                        .textFieldStyle(.roundedBorder)
                }
                FormField(label: "Port", width: 70) {
                    TextField("22", text: $port)
                        .textFieldStyle(.roundedBorder)
                }
            }

            FormField(label: "Default Identity File") {
                HStack(spacing: 8) {
                    TextField("optional — e.g. ~/.ssh/id_ed25519", text: $identityFile)
                        .textFieldStyle(.roundedBorder)
                    Button("Choose...") {
                        chooseIdentityFile { identityFile = $0 }
                    }
                }
            }

            Toggle("Pin to top of menu", isOn: $pinned)
                .toggleStyle(.switch)
                .padding(.top, 4)
        }
    }

    // MARK: - Users section

    private var usersSection: some View {
        FormSection(
            title: "Users",
            trailing: {
                Button {
                    withAnimation(.snappy) {
                        users.append(ServerUser(isDefault: users.isEmpty))
                    }
                } label: {
                    Label("Add User", systemImage: "plus")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        ) {
            if users.isEmpty {
                Text("No users added — connections will use the host directly.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 8) {
                    ForEach($users) { $user in
                        UserRow(
                            user: $user,
                            onSetDefault: { setDefaultUser(user.id) },
                            onDelete: { withAnimation(.snappy) { users.removeAll { $0.id == user.id } } },
                            onChooseIdentity: { chooseIdentityFile { user.identityFile = $0 } }
                        )
                    }
                }
            }
        }
    }

    private func setDefaultUser(_ id: UUID) {
        for index in users.indices {
            users[index].isDefault = (users[index].id == id)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Spacer()
            Button("Cancel") { dismissWindow() }
                .keyboardShortcut(.cancelAction)
            Button("Save") { save() }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
        }
        .padding(16)
    }

    private func dismissWindow() {
        NSApp.keyWindow?.close()
    }

    private func save() {
        var server = editingServer ?? Server()
        server.emoji = emoji.isEmpty ? "🖥️" : emoji
        server.name = name
        server.host = host
        server.port = port.isEmpty ? "22" : port
        server.identityFile = identityFile
        server.pinned = pinned
        server.users = users

        if editingServer != nil {
            store.update(server)
        } else {
            store.add(server)
        }
        dismissWindow()
    }

    private func chooseIdentityFile(_ completion: @escaping (String) -> Void) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".ssh")
        if panel.runModal() == .OK, let url = panel.url {
            completion(url.path)
        }
    }
}

// MARK: - Reusable building blocks

private struct EmojiField: View {
    @Binding var emoji: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Emoji")
                .font(.caption)
                .foregroundStyle(.secondary)
            EmojiPickerField(text: $emoji)
                .frame(width: 44, height: 32)
                .background(RoundedRectangle(cornerRadius: 8).fill(.background))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(.separator))
                .help("Click to pick an emoji")
        }
    }
}

private struct UserRow: View {
    @Binding var user: ServerUser
    let onSetDefault: () -> Void
    let onDelete: () -> Void
    let onChooseIdentity: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onSetDefault) {
                Image(systemName: user.isDefault ? "star.fill" : "star")
                    .foregroundStyle(user.isDefault ? .yellow : .secondary)
            }
            .buttonStyle(.plain)
            .help("Default user for this server")

            TextField("Username", text: $user.name)
                .textFieldStyle(.roundedBorder)

            TextField("Identity file (optional)", text: $user.identityFile)
                .textFieldStyle(.roundedBorder)

            Button("Choose...", action: onChooseIdentity)

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill(.background))
    }
}
