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
    let inferredLanguage = TranslationDraft.inferredSourceLanguage(for: sourceText)

    self.id = id
    self.sourceText = sourceText
    self.detectedLanguage = detectedLanguage ?? inferredLanguage
    self.targetLanguage = targetLanguage ?? TranslationDraft.defaultTargetLanguage(for: inferredLanguage)
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

  public static func inferredSourceLanguage(for sourceText: String) -> String {
    let scalars = sourceText.unicodeScalars

    if scalars.contains(where: isJapaneseScalar) {
      return "日语"
    }

    if scalars.contains(where: isKoreanScalar) {
      return "韩语"
    }

    if scalars.contains(where: isThaiScalar) {
      return "泰语"
    }

    if scalars.contains(where: isChineseScalar) {
      return "中文"
    }

    return "英文"
  }

  public static func defaultTargetLanguage(for sourceLanguage: String) -> String {
    sourceLanguage == "中文" ? "英文" : "中文"
  }

  private static func isChineseScalar(_ scalar: UnicodeScalar) -> Bool {
    switch scalar.value {
    case 0x4E00...0x9FFF, 0x3400...0x4DBF, 0x20000...0x2A6DF, 0x2A700...0x2B73F:
      true
    default:
      false
    }
  }

  private static func isJapaneseScalar(_ scalar: UnicodeScalar) -> Bool {
    switch scalar.value {
    case 0x3040...0x309F, 0x30A0...0x30FF:
      true
    default:
      false
    }
  }

  private static func isKoreanScalar(_ scalar: UnicodeScalar) -> Bool {
    switch scalar.value {
    case 0xAC00...0xD7AF, 0x1100...0x11FF, 0x3130...0x318F:
      true
    default:
      false
    }
  }

  private static func isThaiScalar(_ scalar: UnicodeScalar) -> Bool {
    switch scalar.value {
    case 0x0E00...0x0E7F:
      true
    default:
      false
    }
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
