import Foundation

public enum TranslationResponseParser {
  private struct StructuredTranslation: Decodable {
    let detectedLanguage: String?
    let targetLanguage: String?
    let translation: String?
    let translatedText: String?

    enum CodingKeys: String, CodingKey {
      case detectedLanguage = "detected_language"
      case targetLanguage = "target_language"
      case translation
      case translatedText = "translated_text"
    }
  }

  public static func parseAssistantContent(
    _ content: String,
    sourceText: String,
    model: String,
    timestamp: Date = Date()
  ) -> TranslationResult {
    let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
    let jsonText = extractJSONObject(from: trimmed)

    if
      let data = jsonText.data(using: .utf8),
      let structured = try? JSONDecoder().decode(StructuredTranslation.self, from: data),
      let translated = structured.translation ?? structured.translatedText,
      !translated.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    {
      return TranslationResult(
        originalText: sourceText,
        translatedText: translated,
        detectedLanguage: structured.detectedLanguage ?? "Unknown",
        targetLanguage: structured.targetLanguage ?? "Auto",
        model: model,
        timestamp: timestamp
      )
    }

    return TranslationResult(
      originalText: sourceText,
      translatedText: trimmed,
      detectedLanguage: "Unknown",
      targetLanguage: "Auto",
      model: model,
      timestamp: timestamp
    )
  }

  private static func extractJSONObject(from content: String) -> String {
    var text = content

    if text.hasPrefix("```") {
      text = text
        .replacingOccurrences(of: "```json", with: "")
        .replacingOccurrences(of: "```JSON", with: "")
        .replacingOccurrences(of: "```", with: "")
        .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    guard
      let start = text.firstIndex(of: "{"),
      let end = text.lastIndex(of: "}"),
      start <= end
    else {
      return text
    }

    return String(text[start...end])
  }
}
