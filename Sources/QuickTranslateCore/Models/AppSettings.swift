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
  You are a precise translation engine. Detect the source language and translate according to this rule: Chinese source text translates to English; non-Chinese source text translates to Simplified Chinese. Return compact JSON with keys detected_language, target_language, and translation. Do not include markdown.
  """

  public static let defaults = AppSettings(
    baseURL: URL(string: "https://api.openai.com/v1")!,
    model: "gpt-4o-mini",
    hotKey: .optionD,
    systemPrompt: defaultSystemPrompt,
    automaticallyBidirectional: true
  )
}
