import Foundation

public struct AppSettings: Codable, Equatable, Sendable {
  public var baseURL: URL
  public var model: String
  public var hotKey: HotKey
  public var systemPrompt: String
  public var automaticallyBidirectional: Bool

  public init(
    baseURL: URL,
    model: String,
    hotKey: HotKey,
    systemPrompt: String,
    automaticallyBidirectional: Bool
  ) {
    self.baseURL = baseURL
    self.model = model
    self.hotKey = hotKey
    self.systemPrompt = systemPrompt
    self.automaticallyBidirectional = automaticallyBidirectional
  }

  public static let defaultSystemPrompt = """
  你是一个精准的翻译引擎。请先识别原文语言，然后按以下规则翻译：中文原文翻译成英文；非中文原文翻译成简体中文。请只返回紧凑 JSON，包含 detected_language、target_language、translation 三个字段；detected_language 和 target_language 使用简体中文语言名称，不要返回 Markdown。
  """

  public static let defaults = AppSettings(
    baseURL: URL(string: "https://api.openai.com/v1")!,
    model: "gpt-4o-mini",
    hotKey: .optionD,
    systemPrompt: defaultSystemPrompt,
    automaticallyBidirectional: true
  )
}
