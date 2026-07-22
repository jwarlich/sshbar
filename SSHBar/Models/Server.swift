import Foundation

struct ServerUser: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String = ""
    var identityFile: String = ""
    var isDefault: Bool = false
}

struct Server: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var emoji: String = "🖥️"
    var name: String = ""
    var host: String = ""
    var port: String = "22"
    var identityFile: String = ""
    var pinned: Bool = false
    var users: [ServerUser] = []

    var primaryUser: ServerUser? {
        users.first(where: { $0.isDefault }) ?? users.first
    }

    var displayLabel: String {
        "\(emoji) \(name)"
    }

    func sshTarget(as user: ServerUser?) -> String {
        var parts: [String] = []
        if let user, !user.name.isEmpty {
            parts.append("\(user.name)@\(host)")
        } else {
            parts.append(host)
        }
        if !port.isEmpty && port != "22" {
            parts.append("-p \(port)")
        }
        let key = (user?.identityFile.isEmpty == false) ? user!.identityFile : identityFile
        if !key.isEmpty {
            parts.append("-i \(shellQuote(key))")
        }
        return parts.joined(separator: " ")
    }

    private func shellQuote(_ value: String) -> String {
        "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
