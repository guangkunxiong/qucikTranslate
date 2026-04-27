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

public struct TranslationDraft: Equatable, Identifiable, Sendable {
  public var id: UUID
  public var sourceText: String
  public var detectedLanguage: String
  public var targetLanguage: String

  public init(
    id: UUID = UUID(),
    sourceText: String,
    detectedLanguage: String? = nil,
    targetLanguage: String? = nil
  ) {
    let containsChinese = sourceText.unicodeScalars.contains { scalar in
      switch scalar.value {
      case 0x4E00...0x9FFF, 0x3400...0x4DBF, 0x20000...0x2A6DF, 0x2A700...0x2B73F:
        true
      default:
        false
      }
    }

    self.id = id
    self.sourceText = sourceText
    self.detectedLanguage = detectedLanguage ?? (containsChinese ? "中文" : "非中文")
    self.targetLanguage = targetLanguage ?? (containsChinese ? "英文" : "简体中文")
  }

  public func replacingSourceText(_ sourceText: String) -> TranslationDraft {
    TranslationDraft(id: id, sourceText: sourceText)
  }

  public static func fromEditableSource(_ sourceText: String, basedOn draft: TranslationDraft? = nil) -> TranslationDraft {
    let trimmedText = sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let draft else {
      return TranslationDraft(sourceText: trimmedText)
    }

    return draft.replacingSourceText(trimmedText)
  }

  public static func fromCapturedSelection(_ sourceText: String) -> TranslationDraft {
    TranslationDraft(sourceText: sourceText.trimmingCharacters(in: .whitespacesAndNewlines))
  }
}

struct ChatCompletionRequest: Encodable {
  let model: String
  let messages: [ChatMessage]
  let temperature: Double
  let stream: Bool?
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
