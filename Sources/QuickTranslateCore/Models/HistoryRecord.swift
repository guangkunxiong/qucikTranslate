import Foundation

public struct HistoryRecord: Codable, Equatable, Identifiable, Sendable {
  public var id: UUID
  public var originalText: String
  public var translatedText: String
  public var detectedLanguage: String
  public var targetLanguage: String
  public var model: String
  public var timestamp: Date

  public init(
    id: UUID = UUID(),
    originalText: String,
    translatedText: String,
    detectedLanguage: String,
    targetLanguage: String,
    model: String,
    timestamp: Date
  ) {
    self.id = id
    self.originalText = originalText
    self.translatedText = translatedText
    self.detectedLanguage = detectedLanguage
    self.targetLanguage = targetLanguage
    self.model = model
    self.timestamp = timestamp
  }

  public init(result: TranslationResult) {
    self.init(
      originalText: result.originalText,
      translatedText: result.translatedText,
      detectedLanguage: result.detectedLanguage,
      targetLanguage: result.targetLanguage,
      model: result.model,
      timestamp: result.timestamp
    )
  }
}
