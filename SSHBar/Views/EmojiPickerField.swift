import SwiftUI
import AppKit

/// A single-character "field" that shows the current emoji and opens the
/// system emoji & symbols picker on click. A SwiftUI Button sits on top to
/// reliably capture the click; an invisible NSTextField underneath is what
/// actually receives focus and text insertion from the picker (and from
/// direct typing), with no visible cursor or focus ring since it's never
/// rendered — the Button's Text is what's shown.
struct EmojiPickerField: View {
    @Binding var text: String
    @State private var pickerRequest = 0

    var body: some View {
        ZStack {
            HiddenEmojiTextField(text: $text, pickerRequest: pickerRequest)
                .opacity(0)

            Button {
                pickerRequest += 1
            } label: {
                Text(text.isEmpty ? "🖥️" : text)
                    .font(.system(size: 22))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}

private struct HiddenEmojiTextField: NSViewRepresentable {
    @Binding var text: String
    var pickerRequest: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeNSView(context: Context) -> NSTextField {
        let field = NSTextField(string: text)
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.alignment = .center
        field.delegate = context.coordinator
        return field
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }

        guard context.coordinator.lastHandledRequest != pickerRequest else { return }
        context.coordinator.lastHandledRequest = pickerRequest

        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            nsView.window?.makeFirstResponder(nsView)
            let length = (nsView.stringValue as NSString).length
            nsView.currentEditor()?.selectedRange = NSRange(location: 0, length: length)
            NSApp.orderFrontCharacterPalette(nsView)
        }
    }

    final class Coordinator: NSObject, NSTextFieldDelegate {
        let text: Binding<String>
        var lastHandledRequest = 0

        init(text: Binding<String>) {
            self.text = text
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let field = notification.object as? NSTextField else { return }
            let lastCharacter = field.stringValue.last.map(String.init) ?? ""
            if field.stringValue != lastCharacter {
                field.stringValue = lastCharacter
            }
            text.wrappedValue = lastCharacter
        }
    }
}
