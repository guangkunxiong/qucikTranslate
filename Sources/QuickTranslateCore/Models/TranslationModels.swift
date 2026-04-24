import Foundation

public struct TranslationResult: Codable, Equatable, Identifiable, Sendable {
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
    timestamp: Date = Date()
  ) {
    self.id = id
    self.originalText = originalText
    self.translatedText = translatedText
    self.detectedLanguage = detectedLanguage
    self.targetLanguage = targetLanguage
    self.model = model
    self.timestamp = timestamp
  }
}

struct ChatCompletionRequest: Encodable {
  let model: String
  let messages: [ChatMessage]
  let temperature: Double
}

struct ChatMessage: Codable {
  let role: String
  let content: String
}

struct ChatCompletionResponse: Decodable {
  let choices: [Choice]

  struct Choice: Decodable {
    let message: ChatMessage
  }
}
