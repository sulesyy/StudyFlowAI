import CryptoKit
import Foundation

enum AIContentCache {
    private static let storageKey = "StudyFlowCachedAIContent"
    private static let libraryKey = "StudyFlowSavedAIContent"

    struct SavedContent: Codable, Identifiable {
        let id: UUID
        let title: String
        let kind: String
        let text: String
        let savedAt: Date

        init(id: UUID = UUID(), title: String, kind: String, text: String, savedAt: Date = .now) {
            self.id = id
            self.title = title
            self.kind = kind
            self.text = text
            self.savedAt = savedAt
        }
    }

    private struct Entry: Codable {
        let text: String
        let savedAt: Date
    }

    static func response(for prompt: String, now: Date = .now) -> String? {
        let entries = load()
        guard let entry = entries[hash(prompt)], now.timeIntervalSince(entry.savedAt) < 30 * 24 * 60 * 60 else {
            return nil
        }
        return entry.text
    }

    static func save(_ text: String, for prompt: String, now: Date = .now) {
        var entries = load()
        entries[hash(prompt)] = Entry(text: text, savedAt: now)
        if entries.count > 60 {
            let newest = entries.sorted { $0.value.savedAt > $1.value.savedAt }.prefix(60)
            entries = Dictionary(uniqueKeysWithValues: newest.map { ($0.key, $0.value) })
        }
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    static func backupData() -> Data? { UserDefaults.standard.data(forKey: storageKey) }

    static func saveToLibrary(title: String, kind: String, text: String) {
        var records = savedContent()
        if let index = records.firstIndex(where: { $0.title == title && $0.kind == kind }) {
            records.remove(at: index)
        }
        records.insert(SavedContent(title: title, kind: kind, text: text), at: 0)
        persistLibrary(Array(records.prefix(60)))
    }

    static func savedContent() -> [SavedContent] {
        guard let data = UserDefaults.standard.data(forKey: libraryKey),
              let records = try? JSONDecoder().decode([SavedContent].self, from: data) else { return [] }
        return records.sorted { $0.savedAt > $1.savedAt }
    }

    static func deleteFromLibrary(id: UUID) {
        persistLibrary(savedContent().filter { $0.id != id })
    }

    static func libraryBackupData() -> Data? { UserDefaults.standard.data(forKey: libraryKey) }

    static func restoreLibrary(_ data: Data?) {
        if let data { UserDefaults.standard.set(data, forKey: libraryKey) }
        else { UserDefaults.standard.removeObject(forKey: libraryKey) }
    }

    static func restore(_ data: Data?) {
        if let data { UserDefaults.standard.set(data, forKey: storageKey) }
        else { UserDefaults.standard.removeObject(forKey: storageKey) }
    }

    private static func load() -> [String: Entry] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let entries = try? JSONDecoder().decode([String: Entry].self, from: data) else { return [:] }
        return entries
    }

    private static func persistLibrary(_ records: [SavedContent]) {
        guard let data = try? JSONEncoder().encode(records) else { return }
        UserDefaults.standard.set(data, forKey: libraryKey)
    }

    private static func hash(_ value: String) -> String {
        SHA256.hash(data: Data(value.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
