import Foundation
internal import AppKit
import CoreGraphics
import Combine

final class ClipboardHistoryService: ObservableObject {

    static let shared = ClipboardHistoryService()

    @Published private(set) var items: [ClipboardItem]

    private let storage = ClipboardStorage()
    private let hotkeyCenter = ClipboardHotkeyCenter.shared
    private let fileStore = ClipboardFileStore.shared

    private var monitorTimer: Timer?
    private var lastChangeCount: Int
    private let historyLimit = 50

    private init() {
        let stored = storage.load()
        self.items = stored
        self.lastChangeCount = NSPasteboard.general.changeCount
        configureHotkeys()
        startMonitoring()
    }

    deinit {
        monitorTimer?.invalidate()
        monitorTimer = nil
    }

    func paste(_ item: ClipboardItem) {
        promoteOrInsert(item)
        writeToPasteboard(item)
        storage.save(items)
        simulatePasteCommand()
    }

    func setHotkey(_ hotkey: ClipboardHotkey?, for item: ClipboardItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }

        var updatedItems = items
        updatedItems[index].hotkey = hotkey
        items = updatedItems
        storage.save(items)

        if let hotkey {
            hotkeyCenter.register(hotkey, for: item.id)
        } else {
            hotkeyCenter.unregister(itemId: item.id)
        }
    }

    func remove(_ item: ClipboardItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        hotkeyCenter.unregister(itemId: item.id)
        items.remove(at: index)
        storage.save(items)
        fileStore.removeFiles(for: item.id)
    }

    func clearAll() {
        for item in items {
            hotkeyCenter.unregister(itemId: item.id)
            fileStore.removeFiles(for: item.id)
        }

        items.removeAll()
        storage.save(items)
    }

    private func startMonitoring() {
        monitorTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [weak self] _ in
            self?.pollPasteboard()
        }

        if let monitorTimer {
            RunLoop.main.add(monitorTimer, forMode: .common)
        }
    }

    private func pollPasteboard() {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }

        lastChangeCount = pasteboard.changeCount

        guard var item = ClipboardItem(pasteboard: pasteboard) else { return }

        if let text = item.primaryString,
           text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           item.representations.count == 1 {
            return
        }

        if let first = items.first, first.payloads == item.payloads {
            return
        }

        item.hotkey = nil
        item = fileStore.prepareItem(item)
        items.insert(item, at: 0)
        trimHistoryIfNeeded()
        storage.save(items)
    }

    private func writeToPasteboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        let pbItems = item.payloads.map { payload -> NSPasteboardItem in
            let pbItem = NSPasteboardItem()
            payload.representations.forEach { $0.apply(to: pbItem) }
            return pbItem
        }

        guard !pbItems.isEmpty else { return }

        pasteboard.writeObjects(pbItems)
        lastChangeCount = pasteboard.changeCount
    }

    private func promoteOrInsert(_ item: ClipboardItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            guard index != 0 else { return }

            var current = items
            let moved = current.remove(at: index)
            current.insert(moved, at: 0)
            items = current
        } else {
            items.insert(item, at: 0)
            trimHistoryIfNeeded()
        }
    }

    private func simulatePasteCommand() {
        guard let source = CGEventSource(stateID: .hidSystemState) else { return }

        // Отправляем искусственное нажатие ⌘V, чтобы вставить текст в текущее окно.
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true)
        keyDown?.flags = .maskCommand

        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false)
        keyUp?.flags = .maskCommand

        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }

    private func configureHotkeys() {
        hotkeyCenter.setHandlers(onActivate: { [weak self] itemId in
            DispatchQueue.main.async {
                self?.handleHotkeyActivation(for: itemId)
            }
        }, onReplace: { [weak self] itemId in
            DispatchQueue.main.async {
                self?.clearHotkey(for: itemId)
            }
        })

        restoreHotkeys()
    }

    private func restoreHotkeys() {
        for item in items {
            guard let hotkey = item.hotkey else { continue }
            hotkeyCenter.register(hotkey, for: item.id)
        }
    }

    private func handleHotkeyActivation(for itemId: UUID) {
        guard let item = items.first(where: { $0.id == itemId }) else { return }
        paste(item)
    }

    private func clearHotkey(for itemId: UUID) {
        guard let index = items.firstIndex(where: { $0.id == itemId }) else { return }

        var updatedItems = items
        updatedItems[index].hotkey = nil
        items = updatedItems
        storage.save(items)
    }

    private func trimHistoryIfNeeded() {
        guard items.count > historyLimit else { return }

        let preserved = Array(items.prefix(historyLimit))
        let removed = items.dropFirst(historyLimit)

        for item in removed {
            hotkeyCenter.unregister(itemId: item.id)
            fileStore.removeFiles(for: item.id)
        }

        items = preserved
    }
}
