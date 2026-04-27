import Foundation

public struct SpeechUtteranceRequest: Equatable, Sendable {
  public var text: String
  public var languageHint: String?

  public init(text: String, languageHint: String? = nil) {
    self.text = text
    self.languageHint = languageHint
  }

  public var normalizedText: String {
    text.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  public var voiceLanguageCode: String? {
    if hintLooksChinese {
      return "zh-CN"
    }

    if hintLooksEnglish {
      return "en-US"
    }

    if containsChinese(normalizedText) {
      return "zh-CN"
    }

    if containsLatinLetters(normalizedText) {
      return "en-US"
    }

    return nil
  }

  private var normalizedHint: String {
    (languageHint ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
  }

  private var hintLooksChinese: Bool {
    if normalizedHint.contains("非中文") {
      return false
    }

    return normalizedHint.contains("中文")
      || normalizedHint.contains("chinese")
      || normalizedHint.contains("zh")
  }

  private var hintLooksEnglish: Bool {
    normalizedHint.contains("英文")
      || normalizedHint.contains("english")
      || normalizedHint == "en"
      || normalizedHint.hasPrefix("en-")
  }

  private func containsChinese(_ text: String) -> Bool {
    text.unicodeScalars.contains { scalar in
      switch scalar.value {
      case 0x4E00...0x9FFF, 0x3400...0x4DBF, 0x20000...0x2A6DF, 0x2A700...0x2B73F:
        true
      default:
        false
      }
    }
  }

  private func containsLatinLetters(_ text: String) -> Bool {
    text.unicodeScalars.contains { scalar in
      (65...90).contains(scalar.value) || (97...122).contains(scalar.value)
    }
  }
}
