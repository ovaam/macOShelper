import Foundation
internal import AppKit

final class ClipboardFileStore {

    static let shared = ClipboardFileStore()

    private let baseURL: URL
    private let fileManager = FileManager.default

    private init() {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let dir = appSupport.appendingPathComponent("MacDuckClipboard", isDirectory: true)
        baseURL = dir
        try? fileManager.createDirectory(at: baseURL, withIntermediateDirectories: true)
    }

    func prepareItem(_ item: ClipboardItem) -> ClipboardItem {
        guard item.payloads.contains(where: { payload in
            payload.representations.contains { $0.pasteboardType == .fileURL }
        }) else {
            return item
        }

        removeFiles(for: item.id)

        var updatedPayloads: [ClipboardPayload] = []

        for payload in item.payloads {
            var updatedRepresentations: [ClipboardRepresentation] = []
            for representation in payload.representations {
                if representation.pasteboardType == .fileURL,
                   let sourceURL = representation.fileURL,
                   let storedURL = copyFile(at: sourceURL, for: item.id),
                   let data = storedURL.absoluteString.data(using: .utf8) {
                    updatedRepresentations.append(ClipboardRepresentation(typeIdentifier: representation.typeIdentifier, data: data))
                } else {
                    updatedRepresentations.append(representation)
                }
            }
            updatedPayloads.append(ClipboardPayload(representations: updatedRepresentations))
        }

        return ClipboardItem(id: item.id,
                             capturedAt: item.capturedAt,
                             hotkey: item.hotkey,
                             payloads: updatedPayloads)
    }

    func removeFiles(for itemId: UUID) {
        let dir = directory(for: itemId)
        try? fileManager.removeItem(at: dir)
    }

    private func copyFile(at url: URL, for itemId: UUID) -> URL? {
        var accessed = false
        if url.startAccessingSecurityScopedResource() {
            accessed = true
        }
        defer {
            if accessed {
                url.stopAccessingSecurityScopedResource()
            }
        }

        guard fileManager.fileExists(atPath: url.path) else { return nil }

        let destinationDir = directory(for: itemId)
        do {
            try fileManager.createDirectory(at: destinationDir, withIntermediateDirectories: true)
        } catch { }

        let destinationURL = destinationDir.appendingPathComponent(UUID().uuidString + "_" + url.lastPathComponent)

        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(at: url, to: destinationURL)
            return destinationURL
        } catch {
            return nil
        }
    }

    private func directory(for itemId: UUID) -> URL {
        baseURL.appendingPathComponent(itemId.uuidString, isDirectory: true)
    }
}
