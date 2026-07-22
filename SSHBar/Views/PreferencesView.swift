import SwiftUI
import AppKit

struct PreferencesView: View {
    @State private var selectedTerminal: URL?
    private let availableTerminals = TerminalPreference.availableTerminalApps()

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    terminalSection
                }
                .padding(20)
            }

            Divider()
            footer
        }
        .frame(width: 460, height: 320)
        .background(.background)
        .onAppear {
            selectedTerminal = TerminalPreference.overrideAppURL()
                ?? availableTerminals.first { TerminalPreference.bundleID(for: $0) == "com.apple.Terminal" }
                ?? availableTerminals.first
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 12) {
            Text("⚙️")
                .font(.system(size: 28))
            VStack(alignment: .leading, spacing: 2) {
                Text("Preferences")
                    .font(.title3.bold())
                Text("Choose how SSHBar opens connections")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    // MARK: - Terminal section

    private var terminalSection: some View {
        FormSection(title: "Terminal") {
            FormField(label: "Application") {
                if availableTerminals.isEmpty {
                    Text("No supported terminal apps found.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                } else {
                    Picker("", selection: $selectedTerminal) {
                        ForEach(availableTerminals, id: \.self) { url in
                            Label {
                                Text(TerminalPreference.displayName(for: url))
                            } icon: {
                                Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 16, height: 16)
                            }
                            .tag(Optional(url))
                        }
                    }
                    .labelsHidden()
                    .fixedSize()
                    .onChange(of: selectedTerminal, perform: { newValue in
                        if let newValue {
                            TerminalPreference.setOverride(newValue)
                        }
                    })
                }
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Spacer()
            Button("Close") { dismissWindow() }
                .keyboardShortcut(.defaultAction)
        }
        .padding(16)
    }

    private func dismissWindow() {
        NSApp.keyWindow?.close()
    }
}
