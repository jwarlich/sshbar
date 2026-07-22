# SSHBar

A macOS menu bar app for quick SSH connections. Add servers with one or more
users, pin your favorites, and connect with a click — SSHBar opens your
default terminal app and runs `ssh` with the right host, port, user, and key.

## Requirements

- macOS 13.0+
- Xcode 15+

## Building

The Xcode project is generated from `project.yml` with
[XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
brew install xcodegen
xcodegen generate
open SSHBar.xcodeproj
```

Then build and run (`⌘R`) in Xcode, or from the command line:

```bash
xcodebuild -project SSHBar.xcodeproj -scheme SSHBar -configuration Debug build
```

## Features

- Menu bar only — no Dock icon, no Cmd-Tab entry (`LSUIElement`)
- Pinned and alphabetical "All Servers" sections
- Per-server multiple users, each with an optional identity file
- Pick which terminal app to connect through in Preferences (Terminal, iTerm2, Warp, and other common terminals)
- Servers persist locally via `UserDefaults`

## License

MIT — see [LICENSE](LICENSE).
