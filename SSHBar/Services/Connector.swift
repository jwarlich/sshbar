import AppKit
import Foundation

enum Connector {
    static func connect(to server: Server, as user: ServerUser?) {
        let sshCommand = "ssh \(server.sshTarget(as: user))"

        let overrideURL = TerminalPreference.overrideAppURL()
        let accessedScope = overrideURL?.startAccessingSecurityScopedResource() ?? false
        defer { if accessedScope { overrideURL?.stopAccessingSecurityScopedResource() } }

        let effectiveURL = overrideURL ?? TerminalPreference.detectedDefaultTerminal()
        let bundleID = effectiveURL.flatMap { Bundle(url: $0)?.bundleIdentifier }

        switch bundleID {
        case "com.apple.Terminal":
            if runInTerminalApp(sshCommand: sshCommand) { return }
        case "com.googlecode.iterm2":
            if runInITerm(sshCommand: sshCommand) { return }
        case .some(let id) where id.hasPrefix("dev.warp.Warp"):
            if runInWarp(sshCommand: sshCommand, title: server.name) { return }
        default:
            break
        }

        openViaCommandFile(sshCommand: sshCommand, title: server.name, terminalURL: overrideURL)
    }

    // MARK: - Terminal.app / iTerm2 (scriptable — no temp file needed)

    private static func runInTerminalApp(sshCommand: String) -> Bool {
        let script = """
        tell application "Terminal"
            activate
            do script "\(appleScriptEscaped(sshCommand))"
        end tell
        """
        return runAppleScript(script)
    }

    private static func runInITerm(sshCommand: String) -> Bool {
        let script = """
        tell application "iTerm2"
            activate
            if (count of windows) = 0 then
                create window with default profile
            end if
            tell current window
                create tab with default profile command "\(appleScriptEscaped(sshCommand))"
            end tell
        end tell
        """
        return runAppleScript(script)
    }

    private static func runAppleScript(_ source: String) -> Bool {
        guard let appleScript = NSAppleScript(source: source) else { return false }
        var errorInfo: NSDictionary?
        appleScript.executeAndReturnError(&errorInfo)
        if let errorInfo {
            print("SSHBar: AppleScript automation failed: \(errorInfo)")
            return false
        }
        return true
    }

    private static func appleScriptEscaped(_ value: String) -> String {
        value.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }

    // MARK: - Warp (Tab Configs — opens as a new tab in the focused window)

    private static func runInWarp(sshCommand: String, title: String) -> Bool {
        guard writeWarpTabConfig(sshCommand: sshCommand, title: title),
              let url = URL(string: "warp://tab_config/sshbar-connect") else {
            return false
        }
        NSWorkspace.shared.open(url)
        return true
    }

    private static func writeWarpTabConfig(sshCommand: String, title: String) -> Bool {
        let directory = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".warp/tab_configs", isDirectory: true)
        guard (try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)) != nil else {
            return false
        }

        let toml = """
        name = "sshbar-connect"
        title = "\(tomlEscaped(title))"

        [[panes]]
        id = "main"
        type = "terminal"
        directory = "\(tomlEscaped(NSHomeDirectory()))"
        commands = ["\(tomlEscaped(sshCommand))"]
        """

        let fileURL = directory.appendingPathComponent("sshbar-connect.toml")
        return (try? toml.write(to: fileURL, atomically: true, encoding: .utf8)) != nil
    }

    private static func tomlEscaped(_ value: String) -> String {
        value.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }

    // MARK: - Fallback: generic .command file (any other terminal)

    private static func openViaCommandFile(sshCommand: String, title: String, terminalURL: URL?) {
        let scriptURL = writeCommandFile(sshCommand: sshCommand, title: title)

        if let terminalURL {
            let config = NSWorkspace.OpenConfiguration()
            NSWorkspace.shared.open([scriptURL], withApplicationAt: terminalURL, configuration: config) { _, error in
                if let error {
                    NSWorkspace.shared.open(scriptURL)
                    print("SSHBar: failed to open with override terminal: \(error)")
                }
            }
        } else {
            NSWorkspace.shared.open(scriptURL)
        }
    }

    private static func writeCommandFile(sshCommand: String, title: String) -> URL {
        let script = """
        #!/bin/zsh -i
        clear
        printf '\\033]0;%s\\007' "\(title)"
        \(sshCommand)
        """

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("SSHBar", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let fileName = "connect-\(UUID().uuidString).command"
        let fileURL = directory.appendingPathComponent(fileName)

        try? script.write(to: fileURL, atomically: true, encoding: .utf8)
        try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: fileURL.path)

        return fileURL
    }
}
