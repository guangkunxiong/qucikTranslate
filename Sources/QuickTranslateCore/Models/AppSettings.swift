import Foundation

public struct AppSettings: Codable, Equatable, Sendable {
  public var baseURL: URL
  public var model: String
  public var hotKey: HotKey
  public var systemPrompt: String
  public var automaticallyBidirectional: Bool
  public var displayedLanguages: [String]

  public init(
    baseURL: URL,
    model: String,
    hotKey: HotKey,
    systemPrompt: String,
    automaticallyBidirectional: Bool,
    displayedLanguages: [String] = AppSettings.defaultDisplayedLanguages
  ) {
    self.baseURL = baseURL
    self.model = model
    self.hotKey = hotKey
    self.systemPrompt = systemPrompt
    self.automaticallyBidirectional = automaticallyBidirectional
    self.displayedLanguages = AppSettings.normalizedLanguages(displayedLanguages)
  }

  public static let defaultSystemPrompt = """
  你是一个精准的翻译引擎。请先识别原文语言，然后按以下规则翻译：中文原文翻译成英文；非中文原文翻译成简体中文。请只返回紧凑 JSON，包含 detected_language、target_language、translation 三个字段；detected_language 和 target_language 使用简体中文语言名称，不要返回 Markdown。
  """

  public static let defaultDisplayedLanguages = [
    "中文",
    "英文",
    "日语",
    "韩语",
    "泰语",
    "法语",
    "德语",
    "西班牙语"
  ]

  public static let availableLanguages = [
    "中文",
    "英文",
    "日语",
    "韩语",
    "泰语",
    "法语",
    "德语",
    "西班牙语",
    "俄语",
    "葡萄牙语",
    "意大利语",
    "阿拉伯语",
    "越南语",
    "印尼语",
    "马来语",
    "印地语"
  ]

  public static let defaults = AppSettings(
    baseURL: URL(string: "https://api.openai.com/v1")!,
    model: "gpt-4o-mini",
    hotKey: .optionD,
    systemPrompt: defaultSystemPrompt,
    automaticallyBidirectional: true,
    displayedLanguages: defaultDisplayedLanguages
  )

  private enum CodingKeys: String, CodingKey {
    case baseURL
    case model
    case hotKey
    case systemPrompt
    case automaticallyBidirectional
    case displayedLanguages
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.baseURL = try container.decode(URL.self, forKey: .baseURL)
    self.model = try container.decode(String.self, forKey: .model)
    self.hotKey = try container.decode(HotKey.self, forKey: .hotKey)
    self.systemPrompt = try container.decode(String.self, forKey: .systemPrompt)
    self.automaticallyBidirectional = try container.decode(Bool.self, forKey: .automaticallyBidirectional)
    self.displayedLanguages = AppSettings.normalizedLanguages(
      try container.decodeIfPresent([String].self, forKey: .displayedLanguages) ?? AppSettings.defaultDisplayedLanguages
    )
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(baseURL, forKey: .baseURL)
    try container.encode(model, forKey: .model)
    try container.encode(hotKey, forKey: .hotKey)
    try container.encode(systemPrompt, forKey: .systemPrompt)
    try container.encode(automaticallyBidirectional, forKey: .automaticallyBidirectional)
    try container.encode(displayedLanguages, forKey: .displayedLanguages)
  }

  private static func normalizedLanguages(_ languages: [String]) -> [String] {
    var seen = Set<String>()
    let normalized = languages.compactMap { language -> String? in
      let value = language.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !value.isEmpty, !seen.contains(value) else {
        return nil
      }
      seen.insert(value)
      return value
    }

    return normalized.isEmpty ? defaultDisplayedLanguages : normalized
  }
}
