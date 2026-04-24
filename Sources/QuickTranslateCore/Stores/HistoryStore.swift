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

  public func clear() throws {
    records.removeAll()
    try save()
  }

  public func search(_ query: String, hidingSystemPrompts systemPrompts: [String] = []) -> [HistoryRecord] {
    let visibleRecords = recordsExcludingSystemPrompts(systemPrompts)
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      return visibleRecords
    }

    let needle = trimmed.lowercased()
    return visibleRecords.filter { record in
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

  private func recordsExcludingSystemPrompts(_ systemPrompts: [String]) -> [HistoryRecord] {
    let hiddenPrompts = Set(
      systemPrompts
        .map(Self.normalizedPrompt)
        .filter { !$0.isEmpty }
    )

    guard !hiddenPrompts.isEmpty else {
      return records
    }

    return records.filter { record in
      !hiddenPrompts.contains(Self.normalizedPrompt(record.originalText))
    }
  }

  private static func normalizedPrompt(_ text: String) -> String {
    text
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .split(whereSeparator: \.isWhitespace)
      .joined(separator: " ")
  }
}
