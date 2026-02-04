import Foundation
internal import AppKit

final class ClipboardStorage {

    private let defaults = UserDefaults.standard
    private let currentKey = "clipboard.history.v2"
    private let legacyKey = "clipboard.history.v1"

    func load() -> [ClipboardItem] {
        if let data = defaults.data(forKey: currentKey) {
            do {
                return try JSONDecoder().decode([ClipboardItem].self, from: data)
            } catch {
                return []
            }
        }

        guard let legacyData = defaults.data(forKey: legacyKey) else { return [] }
        do {
            let legacyItems = try JSONDecoder().decode([LegacyClipboardItem].self, from: legacyData)
            let converted = legacyItems.compactMap { $0.modernItem() }
            save(converted)
            defaults.removeObject(forKey: legacyKey)
            return converted
        } catch {
            return []
        }
    }

    func save(_ items: [ClipboardItem]) {
        do {
            let data = try JSONEncoder().encode(items)
            defaults.set(data, forKey: currentKey)
        } catch { }
    }
}

private struct LegacyClipboardItem: Codable {
    let id: UUID
    let content: String
    let capturedAt: Date
    let hotkey: ClipboardHotkey?

    func modernItem() -> ClipboardItem? {
        guard let data = content.data(using: .utf8) else { return nil }
        let representation = ClipboardRepresentation(typeIdentifier: NSPasteboard.PasteboardType.string.rawValue,
                                                     data: data)
        return ClipboardItem(id: id,
                             capturedAt: capturedAt,
                             hotkey: hotkey,
                             payloads: [ClipboardPayload(representations: [representation])])
    }
}
