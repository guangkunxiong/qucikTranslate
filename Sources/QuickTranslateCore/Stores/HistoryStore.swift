import Combine
import Foundation

public final class HistoryStore: ObservableObject {
  private let directoryURL: URL
  private var fileURL: URL {
    directoryURL.appendingPathComponent("history.json")
  }

  @Published public private(set) var records: [HistoryRecord]

  public init(directoryURL: URL? = nil) {
    self.directoryURL = directoryURL ?? Self.defaultDirectoryURL()
    self.records = []
    load()
  }

  @discardableResult
  public func add(_ result: TranslationResult) throws -> HistoryRecord {
    let record = HistoryRecord(result: result)
    records.insert(record, at: 0)
    try save()
    return record
  }

  public func delete(_ id: UUID) throws {
    records.removeAll { $0.id == id }
    try save()
  }

  public func search(_ query: String) -> [HistoryRecord] {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      return records
    }

    let needle = trimmed.lowercased()
    return records.filter { record in
      record.originalText.lowercased().contains(needle)
        || record.translatedText.lowercased().contains(needle)
        || record.detectedLanguage.lowercased().contains(needle)
        || record.targetLanguage.lowercased().contains(needle)
        || record.model.lowercased().contains(needle)
    }
  }

  private func load() {
    guard
      let data = try? Data(contentsOf: fileURL),
      let decoded = try? JSONDecoder().decode([HistoryRecord].self, from: data)
    else {
      records = []
      return
    }

    records = decoded
  }

  private func save() throws {
    try FileManager.default.createDirectory(
      at: directoryURL,
      withIntermediateDirectories: true
    )

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(records)
    try data.write(to: fileURL, options: [.atomic])
  }

  private static func defaultDirectoryURL() -> URL {
    let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
      ?? FileManager.default.temporaryDirectory
    return base.appendingPathComponent("QuickTranslate", isDirectory: true)
  }
}
