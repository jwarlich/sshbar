import AppKit

enum TerminalPreference {
    private static let bookmarkKey = "com.jasperwarlich.sshbar.terminalOverrideBookmark"

    /// Well-known macOS terminal emulators. Filtering to this list (rather
    /// than everything LaunchServices says can open a script file) keeps the
    /// picker free of unrelated apps like TextEdit or Xcode that also claim
    /// to be able to "open" a .command file.
    private static let knownTerminalBundleIDs: [String] = [
        "com.apple.Terminal",
        "com.googlecode.iterm2",
        "dev.warp.Warp-Stable",
        "dev.warp.Warp-Preview",
        "dev.warp.Warp-Dev",
        "co.zeit.hyper",
        "io.alacritty",
        "org.alacritty",
        "net.kovidgoyal.kitty",
        "com.github.wez.wezterm",
        "com.mitchellh.ghostty",
        "org.tabby",
    ]

    static func availableTerminalApps() -> [URL] {
        knownTerminalBundleIDs
            .compactMap { NSWorkspace.shared.urlForApplication(withBundleIdentifier: $0) }
            .sorted {
                displayName(for: $0).localizedCaseInsensitiveCompare(displayName(for: $1)) == .orderedAscending
            }
    }

    static func displayName(for url: URL) -> String {
        FileManager.default.displayName(atPath: url.path)
    }

    static func bundleID(for url: URL) -> String? {
        Bundle(url: url)?.bundleIdentifier
    }

    static func detectedDefaultTerminal() -> URL? {
        let probe = FileManager.default.temporaryDirectory
            .appendingPathComponent("sshbar-probe.command")
        return NSWorkspace.shared.urlForApplication(toOpen: probe)
    }

    static func overrideAppURL() -> URL? {
        guard let bookmarkData = UserDefaults.standard.data(forKey: bookmarkKey) else {
            return nil
        }
        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: bookmarkData,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else {
            return nil
        }
        return url
    }

    static func setOverride(_ url: URL) {
        guard let bookmarkData = try? url.bookmarkData(
            options: [.withSecurityScope],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) else {
            return
        }
        UserDefaults.standard.set(bookmarkData, forKey: bookmarkKey)
    }

}
