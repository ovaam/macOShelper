import SwiftUI
import Carbon
internal import AppKit
import QuartzCore

struct HotkeyAssignmentView: View {

    let item: ClipboardItem
    let onSetHotkey: (ClipboardHotkey) -> Void
    let onClearHotkey: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var recordedHotkey: ClipboardHotkey?
    @State private var message: String = "Нажмите нужную комбинацию клавиш…"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Назначить сочетание клавиш")
                    .font(Font.custom("HSESans-Bold", size: 18))
                    .foregroundColor(.mainTextApp)

                Text("После назначения вы сможете вставлять «\(item.preview)» из любого приложения.")
                    .font(Font.custom("HSESans-Regular", size: 13))
                    .foregroundColor(.secondaryTextApp)
                    .lineLimit(2)
            }

            HotkeyCaptureField(hotkey: $recordedHotkey, message: $message)
                .frame(height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            Text(message)
                .font(Font.custom("HSESans-Regular", size: 12))
                .foregroundColor(.secondaryTextApp)

            if let recordedHotkey {
                HStack {
                    Text("Выбранное сочетание:")
                        .font(Font.custom("HSESans-SemiBold", size: 14))
                        .foregroundColor(.secondaryTextApp)

                    Text(recordedHotkey.display)
                        .font(Font.custom("HSESans-Bold", size: 14))
                        .foregroundColor(.mainTextApp)
                }
            }

            Spacer()

            HStack {
                if item.hotkey != nil {
                    Button("Удалить сочетание") {
                        onClearHotkey()
                        dismiss()
                    }
                    .applySecondaryButton()
                }

                Spacer()

                Button("Отмена") {
                    dismiss()
                }
                .applySecondaryButton()

                Button("Сохранить") {
                    guard let recordedHotkey else { return }
                    onSetHotkey(recordedHotkey)
                    dismiss()
                }
                .applyPrimaryButton()
                .disabled(recordedHotkey == nil)
            }
        }
        .padding(20)
        .frame(width: 420, height: 260)
        .background(Color.blackApp)
        .onAppear {
            recordedHotkey = item.hotkey
            if let hotkey = item.hotkey {
                message = "Нажмите новое сочетание или сохраните текущее."
                recordedHotkey = hotkey
            }
        }
    }
}

// MARK: – Hotkey capture field

private struct HotkeyCaptureField: NSViewRepresentable {

    @Binding var hotkey: ClipboardHotkey?
    @Binding var message: String

    func makeNSView(context: Context) -> HotkeyRecorderView {
        let view = HotkeyRecorderView()
        view.onCapture = { hotkey in
            self.hotkey = hotkey
            self.message = "Сочетание готово, нажмите «Сохранить»."
        }
        view.onInvalidCombination = {
            self.hotkey = nil
            self.message = "Добавьте хотя бы один модификатор (⌘, ⌥, ⌃, ⇧)."
        }
        view.onClear = {
            self.hotkey = nil
            self.message = "Сочетание очищено. Нажмите новую комбинацию."
        }
        return view
    }

    func updateNSView(_ nsView: HotkeyRecorderView, context: Context) { }
}

private final class HotkeyRecorderView: NSView {

    var onCapture: ((ClipboardHotkey) -> Void)?
    var onInvalidCombination: (() -> Void)?
    var onClear: (() -> Void)?

    private let backgroundLayer = CALayer()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        backgroundLayer.backgroundColor = NSColor.darkGray.withAlphaComponent(0.35).cgColor
        backgroundLayer.cornerRadius = 10
        layer?.addSublayer(backgroundLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        backgroundLayer.frame = bounds
    }

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 16, weight: .semibold),
            .foregroundColor: NSColor.white.withAlphaComponent(0.85),
            .paragraphStyle: paragraph
        ]

        let text = "Нажмите новое сочетание клавиш"
        let size = text.size(withAttributes: attrs)
        let rect = NSRect(x: bounds.midX - size.width / 2,
                          y: bounds.midY - size.height / 2,
                          width: size.width,
                          height: size.height)

        text.draw(in: rect, withAttributes: attrs)
    }

    override func keyDown(with event: NSEvent) {
        interpret(event: event)
    }

    override func flagsChanged(with event: NSEvent) {
        // Игнорируем чистые модификаторы
    }

    private func interpret(event: NSEvent) {
        let rawFlags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let flags = rawFlags.subtracting(.capsLock)

        if event.keyCode == UInt16(kVK_Escape) {
            onClear?()
            return
        }

        guard flags.contains(.command) ||
                flags.contains(.option) ||
                flags.contains(.control) ||
                flags.contains(.shift) else {
            onInvalidCombination?()
            return
        }

        guard let characters = event.charactersIgnoringModifiers, !characters.isEmpty else {
            onInvalidCombination?()
            return
        }

        let keyCode = event.keyCode
        let carbonModifiers = carbonFlags(from: flags)
        let displayString = display(for: keyCode, characters: characters, flags: flags)

        let hotkey = ClipboardHotkey(keyCode: UInt32(keyCode),
                                     carbonModifiers: carbonModifiers,
                                     display: displayString)
        onCapture?(hotkey)
    }

    private func carbonFlags(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var carbon: UInt32 = 0
        if flags.contains(.command) { carbon |= UInt32(cmdKey) }
        if flags.contains(.option)  { carbon |= UInt32(optionKey) }
        if flags.contains(.control) { carbon |= UInt32(controlKey) }
        if flags.contains(.shift)   { carbon |= UInt32(shiftKey) }
        return carbon
    }

    private func display(for keyCode: UInt16, characters: String, flags: NSEvent.ModifierFlags) -> String {
        var components: [String] = []
        if flags.contains(.command) { components.append("⌘") }
        if flags.contains(.option)  { components.append("⌥") }
        if flags.contains(.control) { components.append("⌃") }
        if flags.contains(.shift)   { components.append("⇧") }
        components.append(symbol(for: keyCode, characters: characters))
        return components.joined(separator: " ")
    }

    private func symbol(for keyCode: UInt16, characters: String) -> String {
        switch keyCode {
        case UInt16(kVK_Return): return "↩︎"
        case UInt16(kVK_Space): return "Space"
        case UInt16(kVK_Delete): return "⌫"
        case UInt16(kVK_Tab): return "⇥"
        case UInt16(kVK_Escape): return "Esc"
        case UInt16(kVK_LeftArrow): return "←"
        case UInt16(kVK_RightArrow): return "→"
        case UInt16(kVK_UpArrow): return "↑"
        case UInt16(kVK_DownArrow): return "↓"
        case UInt16(kVK_Help): return "Help"
        default:
            if characters.count == 1 {
                return characters.uppercased()
            }
            return characters
        }
    }
}
