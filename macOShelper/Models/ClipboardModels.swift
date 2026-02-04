import Foundation
internal import AppKit
import UniformTypeIdentifiers

struct ClipboardItem: Identifiable, Codable, Equatable {
    let id: UUID
    let capturedAt: Date
    var hotkey: ClipboardHotkey?
    let payloads: [ClipboardPayload]

    init(id: UUID = UUID(),
         capturedAt: Date = Date(),
         hotkey: ClipboardHotkey? = nil,
         payloads: [ClipboardPayload]) {
        self.id = id
        self.capturedAt = capturedAt
        self.hotkey = hotkey
        self.payloads = payloads
    }

    var preview: String {
        if let string = primaryString {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                return "Пустая строка"
            }
            return trimmed
        }

        if let fileNames = fileNameList {
            return fileNames
        }

        if let imageDescription {
            return imageDescription
        }

        if let type = representations.first?.displayName {
            return type
        }

        return "Неизвестное содержимое"
    }

    var isEmptyPreview: Bool {
        preview.isEmpty
    }

    var primaryString: String? {
        for representation in allRepresentations {
            if let string = representation.stringValue {
                return string
            }
        }
        return nil
    }

    var fileNameList: String? {
        let urls = allRepresentations.compactMap { $0.fileURL }
        guard !urls.isEmpty else { return nil }
        let names = urls.map { $0.lastPathComponent }
        let displayed = names.prefix(3).joined(separator: ", ")
        let suffix = urls.count > 3 ? " + ещё \(urls.count - 3)" : ""
        if urls.count == 1 {
            return "Файл: \(displayed)\(suffix)"
        } else {
            return "Файлы (\(urls.count)): \(displayed)\(suffix)"
        }
    }

    var imageDescription: String? {
        guard let image = allRepresentations.first(where: { $0.isImage })?.imageValue else { return nil }
        let size = image.size
        return "Изображение \(Int(size.width))×\(Int(size.height))"
    }

    var representations: [ClipboardRepresentation] {
        payloads.first?.representations ?? []
    }

    var allRepresentations: [ClipboardRepresentation] {
        payloads.flatMap { $0.representations }
    }

    var previewImage: NSImage? {
        allRepresentations.first(where: { $0.isImage })?.imageValue
    }
}

struct ClipboardHotkey: Codable, Equatable {
    let keyCode: UInt32
    let carbonModifiers: UInt32
    let display: String

    static func == (lhs: ClipboardHotkey, rhs: ClipboardHotkey) -> Bool {
        lhs.keyCode == rhs.keyCode && lhs.carbonModifiers == rhs.carbonModifiers
    }
}

struct ClipboardRepresentation: Codable, Equatable {
    let typeIdentifier: String
    private let payload: Data

    init(typeIdentifier: String, data: Data) {
        self.typeIdentifier = typeIdentifier
        self.payload = data
    }

    var data: Data {
        payload
    }

    var pasteboardType: NSPasteboard.PasteboardType {
        NSPasteboard.PasteboardType(typeIdentifier)
    }

    var displayName: String {
        if let type = UTType(typeIdentifier) {
            return type.localizedDescription ?? type.identifier
        }
        return typeIdentifier
    }

    var stringValue: String? {
        let type = pasteboardType
        if type == .string || type.rawValue == "public.utf8-plain-text" {
            return String(data: payload, encoding: .utf8)
        }

        if type.rawValue == "public.utf16-external-plain-text" {
            return String(data: payload, encoding: .utf16)
        }

        if type.rawValue == "public.rtf" {
            return NSAttributedString(rtf: payload, documentAttributes: nil)?.string
        }

        if type == .html {
            return String(data: payload, encoding: .utf8)
        }

        return nil
    }

    var isImage: Bool {
        let type = pasteboardType
        return type == .tiff ||
               type == .png ||
               type.rawValue == UTType.jpeg.identifier ||
               type.rawValue == UTType.bmp.identifier
    }

    var imageValue: NSImage? {
        NSImage(data: payload)
    }

    var fileURL: URL? {
        // Определяем файл ТОЛЬКО для представлений с типом .fileURL,
        // иначе текст/изображения могут ошибочно распознаваться как файл.
        guard pasteboardType == .fileURL else { return nil }

        // На практике пейстборд кладёт либо строку вида file:///..., либо dataRepresentation.
        if let urlString = String(data: payload, encoding: .utf8),
           let url = URL(string: urlString) {
            return url
        }
        return URL(dataRepresentation: payload, relativeTo: nil)
    }

    func apply(to pasteboardItem: NSPasteboardItem) {
        pasteboardItem.setData(payload, forType: pasteboardType)
    }
}

struct ClipboardPayload: Codable, Equatable {
    let representations: [ClipboardRepresentation]
}

extension ClipboardItem {
    init?(pasteboard: NSPasteboard) {
        guard let items = pasteboard.pasteboardItems, !items.isEmpty else { return nil }

        let payloads: [ClipboardPayload] = items.compactMap { pbItem in
            let reps: [ClipboardRepresentation] = pbItem.types.compactMap { type in
                guard let data = pbItem.data(forType: type) else { return nil }
                if data.count > 5_000_000 { return nil }
                return ClipboardRepresentation(typeIdentifier: type.rawValue, data: data)
            }
            return reps.isEmpty ? nil : ClipboardPayload(representations: reps)
        }

        guard !payloads.isEmpty else { return nil }

        self.init(capturedAt: Date(), payloads: payloads)
    }
}
